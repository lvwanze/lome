// 获取留言详情 GET /api/v1/messages/{id}
const { db, getParams, getAuthUser, firstDoc, inCoupleScope } = require('./common');

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
    // 仅关系双方可见
    if (!inCoupleScope(doc, userId)) {
      return { code: 4006, message: '无权查看该留言', data: null };
    }

    // 接收方查看详情时自动标记已读（单条兜底，批量已读由 messageRead 负责）
    if (doc.authorId !== userId && !doc.isRead) {
      const now = Date.now();
      await db.collection('messages').doc(String(messageId)).update({
        isRead: true,
        readTime: now,
      });
      doc.isRead = true;
      doc.readTime = now;
    }

    const [authorRes, replierRes] = await Promise.all([
      db.collection('users').doc(doc.authorId).get(),
      doc.replyAuthorId ? db.collection('users').doc(doc.replyAuthorId).get() : Promise.resolve(null),
    ]);
    const author = firstDoc(authorRes);
    const replier = replierRes ? firstDoc(replierRes) : null;

    const data = {
      id: doc._id,
      authorId: doc.authorId,
      authorName: author ? author.nickname || '' : '',
      authorAvatar: author ? author.avatarUrl || '' : '',
      content: doc.content || '',
      contentType: doc.contentType,
      images: doc.images || [],
      emotionTag: doc.emotionTag || '',
      isRead: !!doc.isRead,
      readTime: doc.readTime || null,
      createTime: doc.createTime,
      updateTime: doc.updateTime,
      reply:
        doc.replyContent && doc.replyTime
          ? {
              content: doc.replyContent,
              authorId: doc.replyAuthorId,
              authorName: replier ? replier.nickname || '' : '',
              createTime: doc.replyTime,
            }
          : null,
    };

    return { code: 0, message: 'success', data };
  } catch (e) {
    console.error('获取留言详情失败:', e);
    return { code: 500, message: '服务器内部错误', data: null };
  }
};
