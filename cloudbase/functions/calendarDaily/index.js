// 获取日详情 GET /api/v1/calendar/daily
const { app, db, getParams, getAuthUser, isValidDate, inCoupleScope } = require('./common');

// 把记录里的图片 fileID 换成临时访问 URL（云存储为私有，前端无法直接用 fileID 渲染）
async function fillImageUrls(records) {
  const fileIds = [];
  for (const r of records) {
    for (const img of r.images || []) {
      if (typeof img === 'string' && img.startsWith('cloud://')) fileIds.push(img);
    }
  }
  if (!fileIds.length) return;

  try {
    const tmp = await app.getTempFileURL({ fileList: fileIds });
    const urlMap = {};
    for (const item of tmp.fileList || []) {
      urlMap[item.fileID] = item.tempFileURL;
    }
    for (const r of records) {
      r.images = (r.images || []).map((img) => ({
        fileId: img,
        url: urlMap[img] || null,
      }));
    }
  } catch (e) {
    console.warn('生成图片临时链接失败:', e.message);
    // 失败时保留 fileID，前端可稍后重试
    for (const r of records) {
      r.images = (r.images || []).map((img) => ({ fileId: img, url: null }));
    }
  }
}

exports.main = async (event) => {
  const params = getParams(event);

  const { userId, error } = await getAuthUser(event);
  if (error) return error;

  const { date } = params;
  if (!isValidDate(date)) {
    return { code: 400, message: '日期参数格式错误，应为 YYYY-MM-DD', data: null };
  }

  try {
    const [recordsRes, plansRes, importantRes] = await Promise.all([
      db.collection('records')
        .where({ date })
        .orderBy('createTime', 'desc')
        .limit(1000)
        .get(),
      db.collection('plans')
        .where({ date })
        .orderBy('createTime', 'asc')
        .limit(1000)
        .get(),
      db.collection('important_days').limit(1000).get(),
    ]);

    const records = recordsRes.data.filter((d) => inCoupleScope(d, userId));
    const plans = plansRes.data.filter((d) => inCoupleScope(d, userId));
    const importantDay = importantRes.data.find(
      (d) => d.date === date && inCoupleScope(d, userId)
    );

    await fillImageUrls(records);

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
