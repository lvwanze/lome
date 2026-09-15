// 上传图片 POST /api/v1/upload/image
//
// 【推荐入参】请求体直接是图片原始二进制，folder/fileName 放 query string：
//   POST /api/v1/upload/image?folder=calendar/records&fileName=xxx.jpg
//   Content-Type: image/jpeg
//   Body: <二进制>
// 【兼容入参】旧版 App 的 JSON base64：{ fileContent: 'data:image/jpeg;base64,...', folder }
//
// 为什么要改成二进制：网关对「文本类型」请求体限制 100KB，base64 再膨胀 33%，
// 原图只要超过约 72KB 就会被网关直接拒绝、根本进不到函数里
// （错误码 EXCEED_MAX_PAYLOAD_SIZE）。改用 image/* 后走「其他类型」档，
// 实测上限（2026-09-15）：
//   · 原始 body ≤ 4.5MB  网关放行
//   · 原始 body ≥ 5MB    网关返回 EXCEED_MAX_PAYLOAD_SIZE（6MB 事件上限 ÷ 1.33 base64 税）
//   · 4.3MB 以上偶发 FUNCTIONS_MEMORY_LIMIT_EXCEEDED，故业务上限取 4MB 留出余量
//
// 返回：{ fileId, url }。**数据库里应当存 fileId**，url 是临时链接、过期即失效，
// 读取时再由 calendarDaily / messageList 等换成新的临时链接。
const { app, getParams, getUserId } = require('./common');

const MAX_SIZE = 4 * 1024 * 1024; // 4MB
const MAX_SIZE_MB = Math.round(MAX_SIZE / 1024 / 1024);
const ALLOWED_EXT = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'];

// 业务目录白名单：防止任意路径写入
const ALLOWED_FOLDERS = {
  'calendar/records': true,
  'calendar/plans': true,
  'messages': true,
};

// 从 Content-Type 推断后缀
function extFromMime(mime) {
  const m = String(mime || '').match(/image\/([\w.+-]+)/i);
  if (!m) return '';
  const ext = m[1].toLowerCase() === 'jpeg' ? 'jpg' : m[1].toLowerCase();
  return ALLOWED_EXT.includes(ext) ? ext : '';
}

exports.main = async (event) => {
  const { userId, error } = getUserId(event);
  if (error) return error;

  const headers = event.headers || {};
  const contentType = String(headers['content-type'] || headers['Content-Type'] || '');
  const query = event.queryStringParameters || {};
  const params = getParams(event);
  const fileName = query.fileName || params.fileName;

  let buffer = null;
  let ext = '';

  if (event.isBase64Encoded === true && typeof event.body === 'string') {
    // 主路径：网关把非文本 body base64 后透传
    buffer = Buffer.from(event.body, 'base64');
    ext = extFromMime(contentType);
  } else if (typeof params.fileContent === 'string' && params.fileContent) {
    // 兼容路径：旧版 App 的 JSON base64（受 100KB 文本档限制，只能传小图）
    const match = params.fileContent.match(/^data:(image\/[\w.+-]+);base64,(.*)$/s);
    buffer = Buffer.from(match ? match[2] : params.fileContent, 'base64');
    ext = extFromMime(match ? match[1] : '');
  } else {
    // 形态不符合预期时打日志，便于判断网关到底怎么传的 body。
    // 不猜测 latin-1 解码 —— 猜错会静默存进一张损坏的图。
    console.error('上传入参无法识别:', {
      isBase64Encoded: event.isBase64Encoded,
      contentType,
      bodyType: typeof event.body,
      bodyLen: typeof event.body === 'string' ? event.body.length : -1,
    });
    return { code: 400, message: '缺少图片内容', data: null };
  }

  // 文件名后缀优先于 MIME 推断
  if (typeof fileName === 'string' && fileName) {
    const nameExt = fileName.split('.').pop().toLowerCase();
    if (/^[a-z0-9]{1,5}$/.test(nameExt) && ALLOWED_EXT.includes(nameExt)) ext = nameExt;
  }
  if (!ext) ext = 'jpg';

  if (!buffer || !buffer.length) {
    return { code: 400, message: '图片内容为空', data: null };
  }
  if (buffer.length > MAX_SIZE) {
    return { code: 400, message: `图片大小不能超过 ${MAX_SIZE_MB}MB`, data: null };
  }

  try {
    // 业务路径隔离：folder 必须在白名单内，并带上 userId 段，便于按用户管理文件
    const folder = typeof params.folder === 'string' ? params.folder.trim() : '';
    if (folder && !ALLOWED_FOLDERS[folder]) {
      return {
        code: 400,
        message: 'folder 仅支持 calendar/records、calendar/plans、messages',
        data: null,
      };
    }
    const baseDir = folder ? `${folder}/${userId}` : `images/${userId}`;

    const cloudPath = `${baseDir}/${Date.now()}_${Math.floor(Math.random() * 10000)}.${ext}`;
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
