// 更新记录 PUT /api/v1/record/update（仅创建者可修改）
const { db, getParams, getAuthUser, firstDoc, isValidDate } = require('./common');

exports.main = async (event) => {
  const params = getParams(event);

  const { userId, error } = await getAuthUser(event);
  if (error) return error;

  const { recordId, date, title, content, images, mood } = params;
  if (!recordId) {
    return { code: 400, message: '记录ID不能为空', data: null };
  }

  try {
    const res = await db.collection('records').doc(recordId).get();
    const record = firstDoc(res);
    if (!record) {
      return { code: 404, message: '记录不存在', data: null };
    }
    if (record.authorId !== userId) {
      return { code: 403, message: '无权修改该记录', data: null };
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
    if (mood !== undefined) update.mood = mood;
    update.updateTime = Date.now();

    await db.collection('records').doc(recordId).update(update);

    return {
      code: 0,
      message: '记录更新成功',
      data: { recordId },
    };
  } catch (e) {
    console.error('更新记录失败:', e);
    return { code: 500, message: '服务器内部错误', data: null };
  }
};
