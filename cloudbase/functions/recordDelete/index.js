// 删除记录 POST /api/v1/record/delete（仅创建者可删除）
const { db, getParams, getAuthUser, firstDoc } = require('./common');

exports.main = async (event) => {
  const params = getParams(event);

  const { userId, error } = await getAuthUser(event);
  if (error) return error;

  const { recordId } = params;
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
      return { code: 403, message: '无权删除该记录', data: null };
    }

    await db.collection('records').doc(recordId).remove();

    return {
      code: 0,
      message: '记录删除成功',
      data: { recordId },
    };
  } catch (e) {
    console.error('删除记录失败:', e);
    return { code: 500, message: '服务器内部错误', data: null };
  }
};
