// 重要日列表 GET /api/v1/important-day/list
const { db, getParams, getAuthUser, inCoupleScope, authorScope } = require('./common');

exports.main = async (event) => {
  const params = getParams(event);

  const { userId, partnerId, error } = await getAuthUser(event);
  if (error) return error;

  try {
    // 可见性条件下推到数据库：authorId 属于「我」或「我当前的伴侣」
    const res = await db
      .collection('important_days')
      .where({ authorId: authorScope(userId, partnerId) })
      .limit(1000)
      .get();

    const list = res.data
      .filter((d) => inCoupleScope(d, userId, partnerId))
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
