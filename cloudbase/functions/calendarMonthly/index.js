// 获取月历概览 GET /api/v1/calendar/monthly
const { db, _, getParams, getAuthUser, inCoupleScope, authorScope } = require('./common');

// 校验 month 格式 YYYY-MM
function parseMonth(month) {
  if (typeof month !== 'string' || !/^\d{4}-\d{2}$/.test(month)) return null;
  const [y, m] = month.split('-').map(Number);
  if (m < 1 || m > 12) return null;
  return { y, m };
}

exports.main = async (event) => {
  const params = getParams(event);

  const { userId, partnerId, error } = await getAuthUser(event);
  if (error) return error;

  const parsed = parseMonth(params.month);
  if (!parsed) {
    return { code: 400, message: '月份参数格式错误，应为 YYYY-MM', data: null };
  }

  const { y, m } = parsed;
  const month = `${y}-${String(m).padStart(2, '0')}`;
  // 当月天数：下月第 0 天即当月最后一天
  const daysInMonth = new Date(y, m, 0).getDate();
  const startDate = `${month}-01`;
  const endDate = `${month}-${String(daysInMonth).padStart(2, '0')}`;

  try {
    // 可见性条件下推到数据库：authorId 属于「我」或「我当前的伴侣」
    const scope = authorScope(userId, partnerId);
    const inMonth = _.gte(startDate).and(_.lte(endDate));

    const [recordsRes, plansRes, importantRes] = await Promise.all([
      db.collection('records').where({ date: inMonth, authorId: scope }).limit(1000).get(),
      db.collection('plans').where({ date: inMonth, authorId: scope }).limit(1000).get(),
      db.collection('important_days').where({ date: inMonth, authorId: scope }).limit(1000).get(),
    ]);

    // 纵深防御：只保留自己或伴侣创建的共享数据
    const records = recordsRes.data.filter((d) => inCoupleScope(d, userId, partnerId));
    const plans = plansRes.data.filter((d) => inCoupleScope(d, userId, partnerId));
    const importantDays = importantRes.data.filter((d) => inCoupleScope(d, userId, partnerId));

    const days = [];
    for (let d = 1; d <= daysInMonth; d++) {
      const dateStr = `${month}-${String(d).padStart(2, '0')}`;
      const dayRecords = records.filter((r) => r.date === dateStr);
      const dayPlans = plans.filter((p) => p.date === dateStr);
      const importantDay = importantDays.find((i) => i.date === dateStr);

      days.push({
        date: dateStr,
        hasRecord: dayRecords.length > 0,
        hasPlan: dayPlans.length > 0,
        hasImportantDay: !!importantDay,
        recordCount: dayRecords.length,
        planCount: dayPlans.length,
        planPendingCount: dayPlans.filter((p) => !p.completed).length,
        importantDayName: importantDay ? importantDay.name : null,
      });
    }

    return {
      code: 0,
      message: 'success',
      data: {
        month,
        recordedDays: records.length,
        days,
      },
    };
  } catch (e) {
    console.error('获取月历概览失败:', e);
    return { code: 500, message: '服务器内部错误', data: null };
  }
};
