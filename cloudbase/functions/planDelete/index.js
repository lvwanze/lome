// 删除规划 POST /api/v1/plan/delete（仅创建者可删除）
const { db, getParams, getAuthUser, firstDoc } = require('./common');

exports.main = async (event) => {
  const params = getParams(event);

  const { userId, error } = await getAuthUser(event);
  if (error) return error;

  const { planId } = params;
  if (!planId) {
    return { code: 400, message: '规划ID不能为空', data: null };
  }

  try {
    const res = await db.collection('plans').doc(planId).get();
    const plan = firstDoc(res);
    if (!plan) {
      return { code: 404, message: '规划不存在', data: null };
    }
    if (plan.authorId !== userId) {
      return { code: 403, message: '无权删除该规划', data: null };
    }

    await db.collection('plans').doc(planId).remove();

    return {
      code: 0,
      message: '规划删除成功',
      data: { planId },
    };
  } catch (e) {
    console.error('删除规划失败:', e);
    return { code: 500, message: '服务器内部错误', data: null };
  }
};
