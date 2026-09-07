// 创建记录 POST /api/v1/record/create
const { db, getParams, getAuthUser, isValidDate } = require('./common');

exports.main = async (event) => {
  const params = getParams(event);

  const { userId, partnerId, error } = await getAuthUser(event);
  if (error) return error;

  const { date, title, content, images, mood } = params;
  if (!isValidDate(date)) {
    return { code: 400, message: '日期不能为空', data: null };
  }

  const imageList = Array.isArray(images) ? images.slice(0, 4) : [];
  const moodValue = typeof mood === 'string' && mood ? mood : 'happy';
  const now = Date.now();

  try {
    const res = await db.collection('records').add({
      date,
      title: title || '',
      content: content || '',
      images: imageList,
      mood: moodValue,
      authorId: userId,
      partnerId: partnerId,
      createTime: now,
      updateTime: now,
    });

    return {
      code: 0,
      message: '记录创建成功',
      data: { recordId: res.id },
    };
  } catch (e) {
    console.error('创建记录失败:', e);
    return { code: 500, message: '服务器内部错误', data: null };
  }
};
