// 删除重要日 POST /api/v1/important-day/delete（仅创建者可删除）
const { db, getParams, getAuthUser, firstDoc } = require('./common');

exports.main = async (event) => {
  const params = getParams(event);

  const { userId, error } = await getAuthUser(event);
  if (error) return error;

  const { importantDayId } = params;
  if (!importantDayId) {
    return { code: 400, message: '重要日ID不能为空', data: null };
  }

  try {
    const res = await db.collection('important_days').doc(importantDayId).get();
    const importantDay = firstDoc(res);
    if (!importantDay) {
      return { code: 404, message: '重要日不存在', data: null };
    }
    if (importantDay.authorId !== userId) {
      return { code: 403, message: '无权删除该重要日', data: null };
    }

    await db.collection('important_days').doc(importantDayId).remove();

    return {
      code: 0,
      message: '重要日删除成功',
      data: { importantDayId },
    };
  } catch (e) {
    console.error('删除重要日失败:', e);
    return { code: 500, message: '服务器内部错误', data: null };
  }
};
