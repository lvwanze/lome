// 删除回应 DELETE /api/v1/messages/{id}/reply（仅回应者）
const { db, getParams, getAuthUser, firstDoc } = require('./common');

exports.main = async (event) => {
  const params = getParams(event);

  const { userId, error } = await getAuthUser(event);
  if (error) return error;

  const messageId = params.messageId || params.id;
  if (!messageId) {
    return { code: 400, message: '缺少留言ID', data: null };
  }

  try {
    const res = await db.collection('messages').doc(String(messageId)).get();
    const doc = firstDoc(res);
    if (!doc) {
      return { code: 4005, message: '留言不存在', data: null };
    }
    if (!doc.replyAuthorId || !doc.replyTime) {
      return { code: 4005, message: '该留言暂无回应', data: null };
    }
    // 仅回应者可删除自己的回应
    if (doc.replyAuthorId !== userId) {
      return { code: 4006, message: '仅回应者可删除自己的回应', data: null };
    }

    await db.collection('messages').doc(String(messageId)).update({
      replyContent: '',
      replyAuthorId: '',
      replyTime: null,
    });

    return { code: 0, message: 'success', data: null };
  } catch (e) {
    console.error('删除回应失败:', e);
    return { code: 500, message: '服务器内部错误', data: null };
  }
};