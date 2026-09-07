// 更新规划 PUT /api/v1/plan/update（仅创建者可修改；完成状态请走 planToggle）
const { db, getParams, getAuthUser, firstDoc, isValidDate } = require('./common');

exports.main = async (event) => {
  const params = getParams(event);

  const { userId, error } = await getAuthUser(event);
  if (error) return error;

  const { planId, date, title, content, images } = params;
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
      return { code: 403, message: '无权修改该规划', data: null };
    }

    const update = {};
    if (date !== undefined) {
      if (!isValidDate(date)) {
        return { code: 400, message: '日期格式错误，应为 YYYY-MM-DD', data: null };
      }
      update.date = date;
    }
    if (title !== undefined) update.title = title;
    if (content !== undefined) update.content = content;
    if (images !== undefined) {
      if (!Array.isArray(images) || images.length > 4) {
        return { code: 400, message: '图片最多4张', data: null };
      }
      update.images = images;
    }
    update.updateTime = Date.now();

    await db.collection('plans').doc(planId).update(update);

    return {
      code: 0,
      message: '规划更新成功',
      data: { planId },
    };
  } catch (e) {
    console.error('更新规划失败:', e);
    return { code: 500, message: '服务器内部错误', data: null };
  }
};
