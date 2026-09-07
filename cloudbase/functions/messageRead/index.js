// 批量已读 PUT /api/v1/messages/read（进入留言板页面时静默调用）
const { db, getParams, getAuthUser } = require('./common');

exports.main = async (event) => {
  const { userId, partnerId, error } = await getAuthUser(event);
  if (error) return error;
  if (!partnerId) {
    return { code: 4006, message: '尚未绑定伴侣', data: null };
  }

  try {
    // 批量标记所有伴侣留言为已读
    const now = Date.now();
    const res = await db.collection('messages')
      .where({ authorId: partnerId, partnerId: userId, isRead: false })
      .update({ isRead: true, readTime: now });

    // 兼容不同 SDK 版本的返回结构
    const markedCount = (res && res.stats && res.stats.updated) || (res && res.updated) || 0;

    return { code: 0, message: 'success', data: { markedCount } };
  } catch (e) {
    console.error('标记已读失败:', e);
    return { code: 500, message: '服务器内部错误', data: null };
  }
};