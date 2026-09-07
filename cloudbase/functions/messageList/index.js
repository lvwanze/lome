// 获取留言列表 GET /api/v1/messages?type=mine|partner&pageSize=20&cursor=xxx
const { db, _, getParams, getAuthUser } = require('./common');

const DEFAULT_PAGE_SIZE = 20;
const MAX_PAGE_SIZE = 50;

// 组装列表项：补充昵称/头像 + hasReply
function buildItem(doc, userMap) {
  const author = userMap[doc.authorId] || {};
  return {
    id: doc._id,
    authorId: doc.authorId,
    authorName: author.nickname || '',
    authorAvatar: author.avatarUrl || '',
    content: doc.content || '',
    contentType: doc.contentType,
    images: doc.images || [],
    emotionTag: doc.emotionTag || '',
    isRead: !!doc.isRead,
    readTime: doc.readTime || null,
    createTime: doc.createTime,
    hasReply: !!(doc.replyContent && doc.replyTime),
  };
}

exports.main = async (event) => {
  const params = getParams(event);

  const { userId, partnerId, error } = await getAuthUser(event);
  if (error) return error;
  if (!partnerId) {
    return { code: 4006, message: '尚未绑定伴侣', data: null };
  }

  const type = params.type === 'partner' ? 'partner' : 'mine';
  const pageSize = Math.min(
    Math.max(parseInt(params.pageSize, 10) || DEFAULT_PAGE_SIZE, 1),
    MAX_PAGE_SIZE
  );
  // 游标分页：首次为当前时间，之后传上一页最后一条的 createTime
  const cursor = Number(params.cursor) > 0 ? Number(params.cursor) : Date.now();

  // 数据隔离：我的留言 authorId=自己；Ta的留言 authorId=伴侣
  const where =
    type === 'mine'
      ? { authorId: userId, partnerId: partnerId, createTime: _.lt(cursor) }
      : { authorId: partnerId, partnerId: userId, createTime: _.lt(cursor) };

  try {
    const [listRes, unreadRes, authorRes, partnerRes] = await Promise.all([
      db.collection('messages')
        .where(where)
        .orderBy('createTime', 'desc')
        .limit(pageSize)
        .get(),
      type === 'partner'
        ? db.collection('messages')
            .where({ authorId: partnerId, partnerId: userId, isRead: false })
            .count()
        : Promise.resolve(null),
      db.collection('users').doc(userId).get(),
      db.collection('users').doc(partnerId).get(),
    ]);

    const userMap = {};
    [authorRes, partnerRes].forEach((res) => {
      if (!res || !res.data) return;
      const user = Array.isArray(res.data) ? res.data[0] : res.data;
      if (user) {
        userMap[user._id] = { nickname: user.nickname || '', avatarUrl: user.avatarUrl || '' };
      }
    });

    const list = (listRes.data || []).map((d) => buildItem(d, userMap));
    const hasMore = list.length === pageSize;
    const nextCursor = hasMore && list.length > 0 ? list[list.length - 1].createTime : null;

    return {
      code: 0,
      message: 'success',
      data: {
        type,
        list,
        hasMore,
        nextCursor,
        // Ta的留言未读数量，供首页角标使用
        unreadCount: unreadRes && unreadRes.total ? unreadRes.total : 0,
      },
    };
  } catch (e) {
    console.error('获取留言列表失败:', e);
    return { code: 500, message: '服务器内部错误', data: null };
  }
};
