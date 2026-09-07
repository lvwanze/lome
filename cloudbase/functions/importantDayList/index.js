// 重要日列表 GET /api/v1/important-day/list
const { db, getParams, getAuthUser, inCoupleScope } = require('./common');

exports.main = async (event) => {
  const params = getParams(event);

  const { userId, error } = await getAuthUser(event);
  if (error) return error;

  try {
    const res = await db.collection('important_days').limit(1000).get();

    const list = res.data
      .filter((d) => inCoupleScope(d, userId))
      .sort((a, b) => (a.date < b.date ? -1 : a.date > b.date ? 1 : 0))
      .map((d) => ({
        importantDayId: d._id,
        name: d.name,
        date: d.date,
        type: d.type || 'custom',
        remark: d.remark || '',
        authorId: d.authorId,
        createTime: d.createTime,
      }));

    return {
      code: 0,
      message: 'success',
      data: { list },
    };
  } catch (e) {
    console.error('获取重要日列表失败:', e);
    return { code: 500, message: '服务器内部错误', data: null };
  }
};
