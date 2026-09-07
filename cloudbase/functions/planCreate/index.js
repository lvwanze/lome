// 创建规划 POST /api/v1/plan/create
const { db, getParams, getAuthUser, isValidDate } = require('./common');

exports.main = async (event) => {
  const params = getParams(event);

  const { userId, partnerId, error } = await getAuthUser(event);
  if (error) return error;

  const { date, title, content, images } = params;
  if (!isValidDate(date)) {
    return { code: 400, message: '日期不能为空', data: null };
  }

  const imageList = Array.isArray(images) ? images.slice(0, 4) : [];
  const now = Date.now();

  try {
    const res = await db.collection('plans').add({
      date,
      title: title || '',
      content: content || '',
      images: imageList,
      completed: false,
      completedBy: null,
      completedTime: null,
      authorId: userId,
      partnerId: partnerId,
      createTime: now,
      updateTime: now,
    });

    return {
      code: 0,
      message: '规划创建成功',
      data: { planId: res.id },
    };
  } catch (e) {
    console.error('创建规划失败:', e);
    return { code: 500, message: '服务器内部错误', data: null };
  }
};
