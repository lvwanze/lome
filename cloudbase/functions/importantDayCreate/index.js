// 添加重要日 POST /api/v1/important-day/create
const { db, getParams, getAuthUser, isValidDate } = require('./common');

exports.main = async (event) => {
  const params = getParams(event);

  const { userId, partnerId, error } = await getAuthUser(event);
  if (error) return error;

  const { name, date, type, remark } = params;
  if (typeof name !== 'string' || !name.trim()) {
    return { code: 400, message: '重要日名称不能为空', data: null };
  }
  if (!isValidDate(date)) {
    return { code: 400, message: '日期格式错误，应为 YYYY-MM-DD', data: null };
  }

  try {
    const res = await db.collection('important_days').add({
      name: name.trim(),
      date,
      type: type || 'custom',
      remark: remark || '',
      authorId: userId,
      partnerId: partnerId,
      createTime: Date.now(),
    });

    return {
      code: 0,
      message: '重要日添加成功',
      data: { importantDayId: res.id },
    };
  } catch (e) {
    console.error('添加重要日失败:', e);
    return { code: 500, message: '服务器内部错误', data: null };
  }
};
