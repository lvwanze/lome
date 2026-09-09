// 回应留言 POST /api/v1/messages/{id}/reply（仅接收方，每条留言仅保留一条回应，新回应覆盖旧回应）
const { db, getParams, getAuthUser, firstDoc } = require('./common');

const MAX_REPLY = 200; // 回应最多200字

exports.main = async (event) => {
  const params = getParams(event);

  const { userId, error } = await getAuthUser(event);
  if (error) return error;

  const messageId = params.messageId || params.id;
  if (!messageId) {
    return { code: 400, message: '缺少留言ID', data: null };
  }

  const content = typeof params.content === 'string' ? params.content.trim() : '';
  if (!content) {
    return { code: 4004, message: '回应内容不能为空', data: null };
  }
  if (content.length > MAX_REPLY) {
    return { code: 4004, message: `回应最多${MAX_REPLY}字`, data: null };
  }

  try {
    const res = await db.collection('messages').doc(String(messageId)).get();
    const doc = firstDoc(res);
    if (!doc) {
      return { code: 4005, message: '留言不存在', data: null };
    }
    // 只能回应对方发布的留言
    if (doc.authorId === userId) {
      return { code: 4006, message: '不能回应自己的留言', data: null };
    }
    if (doc.partnerId !== userId) {
      return { code: 4006, message: '无权回应该留言', data: null };
    }

    const now = Date.now();
    // 覆盖式回应：仅保留对方一条回应
    await db.collection('messages').doc(String(messageId)).update({
      replyContent: content,
      replyAuthorId: userId,
      replyTime: now,
    });

    return {
      code: 0,
      message: 'success',
      data: { replyId: String(messageId), replyContent: content, replyTime: now },
    };
  } catch (e) {
    console.error('回应留言失败:', e);
    return { code: 500, message: '服务器内部错误', data: null };
  }
};