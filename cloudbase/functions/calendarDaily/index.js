// 获取日详情 GET /api/v1/calendar/daily
const {
  db,
  getParams,
  getAuthUser,
  isValidDate,
  inCoupleScope,
  authorScope,
  fillImageUrls,
} = require('./common');

exports.main = async (event) => {
  const params = getParams(event);

  const { userId, partnerId, error } = await getAuthUser(event);
  if (error) return error;

  const { date } = params;
  if (!isValidDate(date)) {
    return { code: 400, message: '日期参数格式错误，应为 YYYY-MM-DD', data: null };
  }

  try {
    // 可见性条件下推到数据库：authorId 属于「我」或「我当前的伴侣」。
    // 不能只靠取回后再 filter —— 那样每次请求都会把别人的数据拉进函数内存。
    const scope = authorScope(userId, partnerId);

    const [recordsRes, plansRes, importantRes] = await Promise.all([
      db.collection('records')
        .where({ date, authorId: scope })
        .orderBy('createTime', 'desc')
        .limit(1000)
        .get(),
      db.collection('plans')
        .where({ date, authorId: scope })
        .orderBy('createTime', 'asc')
        .limit(1000)
        .get(),
      db.collection('important_days').where({ date, authorId: scope }).limit(100).get(),
    ]);

    // 纵深防御：数据库条件已保证，这里再按同一规则过滤一次
    const records = recordsRes.data.filter((d) => inCoupleScope(d, userId, partnerId));
    const plans = plansRes.data.filter((d) => inCoupleScope(d, userId, partnerId));
    const importantDay = importantRes.data.find((d) => inCoupleScope(d, userId, partnerId));

    // 记录和规划的图片都要换临时链接（早先漏了 plans）
    await fillImageUrls(records);
    await fillImageUrls(plans);

    return {
      code: 0,
      message: 'success',
      data: {
        date,
        records: records.map((r) => ({
          recordId: r._id,
          date: r.date,
          title: r.title || '',
          content: r.content || '',
          images: r.images || [],
          mood: r.mood || 'happy',
          authorId: r.authorId,
          createTime: r.createTime,
          updateTime: r.updateTime,
        })),
        plans: plans.map((p) => ({
          planId: p._id,
          date: p.date,
          title: p.title || '',
          content: p.content || '',
          images: p.images || [],
          completed: !!p.completed,
          completedBy: p.completedBy || null,
          completedTime: p.completedTime || null,
          authorId: p.authorId,
          createTime: p.createTime,
          updateTime: p.updateTime,
        })),
        importantDay: importantDay
          ? {
              importantDayId: importantDay._id,
              name: importantDay.name,
              date: importantDay.date,
              type: importantDay.type || 'custom',
              remark: importantDay.remark || '',
              createTime: importantDay.createTime,
            }
          : null,
      },
    };
  } catch (e) {
    console.error('获取日详情失败:', e);
    return { code: 500, message: '服务器内部错误', data: null };
  }
};
