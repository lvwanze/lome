// 切换规划完成状态 PUT /api/v1/plan/toggle（创建者与伴侣均可操作）
const { db, getParams, getAuthUser, firstDoc, inCoupleScope } = require('./common');

exports.main = async (event) => {
  const params = getParams(event);

  const { userId, error } = await getAuthUser(event);
  if (error) return error;

  const { planId, completed } = params;
  if (!planId) {
    return { code: 400, message: '规划ID不能为空', data: null };
  }
  if (typeof completed !== 'boolean') {
    return { code: 400, message: 'completed 必须为布尔值', data: null };
  }

  try {
    const res = await db.collection('plans').doc(planId).get();
    const plan = firstDoc(res);
    if (!plan) {
      return { code: 404, message: '规划不存在', data: null };
    }
    if (!inCoupleScope(plan, userId)) {
      return { code: 403, message: '无权操作该规划', data: null };
    }

    const now = Date.now();
    await db.collection('plans').doc(planId).update({
      completed,
      completedBy: completed ? userId : null,
      completedTime: completed ? now : null,
      updateTime: now,
    });

    return {
      code: 0,
      message: 'success',
      data: {
        planId,
        completed,
        completedBy: completed ? userId : null,
        completedTime: completed ? now : null,
      },
    };
  } catch (e) {
    console.error('切换规划完成状态失败:', e);
    return { code: 500, message: '服务器内部错误', data: null };
  }
};
