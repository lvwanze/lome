// 上传图片 POST /api/v1/upload/image
// 入参：{ fileName?: string, fileContent: base64 字符串（可带 data:image/xxx;base64, 前缀） }
// 返回：{ fileId, url }，url 为临时访问链接（过期后可通过 calendarDaily 重新换取）
const { app, getParams, getUserId } = require('./common');

// HTTP 访问服务请求体上限约 6MB，base64 膨胀约 33%，限制原图 3MB
const MAX_SIZE = 3 * 1024 * 1024;
const ALLOWED_EXT = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'];

exports.main = async (event) => {
  const params = getParams(event);

  const { userId, error } = getUserId(event);
  if (error) return error;

  const { fileName, fileContent } = params;
  if (typeof fileContent !== 'string' || !fileContent) {
    return { code: 400, message: '缺少图片内容', data: null };
  }

  // 解析 data:image/png;base64,xxx 前缀
  let mime = '';
  let base64 = fileContent;
  const match = fileContent.match(/^data:(image\/[\w.+-]+);base64,(.*)$/s);
  if (match) {
    mime = match[1];
    base64 = match[2];
  }

  // 优先用文件名后缀，其次用 MIME 类型推断
  let ext = '';
  if (typeof fileName === 'string' && fileName) {
    const nameExt = fileName.split('.').pop().toLowerCase();
    if (/^[a-z0-9]{1,5}$/.test(nameExt)) ext = nameExt;
  }
  if (!ext && mime) ext = mime.replace('image/', '').replace('jpeg', 'jpg');
  if (!ext) ext = 'jpg';

  if (!ALLOWED_EXT.includes(ext)) {
    return { code: 400, message: '不支持的图片格式', data: null };
  }

  let buffer;
  try {
    buffer = Buffer.from(base64, 'base64');
  } catch (e) {
    return { code: 400, message: '图片内容解析失败', data: null };
  }
  if (!buffer.length) {
    return { code: 400, message: '图片内容为空', data: null };
  }
  if (buffer.length > MAX_SIZE) {
    return { code: 400, message: '图片大小不能超过 3MB', data: null };
  }

  try {
    const cloudPath = `images/${userId}/${Date.now()}_${Math.floor(Math.random() * 10000)}.${ext}`;
    const uploadRes = await app.uploadFile({
      cloudPath,
      fileContent: buffer,
    });
    const fileId = uploadRes.fileID;

    // 生成临时访问链接（云存储为私有，前端无法直接用 fileID 渲染）
    let url = null;
    try {
      const tmpRes = await app.getTempFileURL({ fileList: [fileId] });
      const item = tmpRes.fileList && tmpRes.fileList[0];
      url = item ? item.tempFileURL : null;
    } catch (e) {
      console.warn('生成临时链接失败:', e.message);
    }

    return {
      code: 0,
      message: '上传成功',
      data: { fileId, url },
    };
  } catch (e) {
    console.error('上传图片失败:', e);
    return { code: 500, message: '上传失败', data: null };
  }
};
