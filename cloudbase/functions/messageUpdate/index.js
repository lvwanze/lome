// 编辑留言 PUT /api/v1/messages/{id}（仅作者，编辑后重置已读状态）
const { db, getParams, getAuthUser, firstDoc } = require('./common');

const MAX_CONTENT = 50;
const MAX_IMAGES = 2;
const MAX_EMOTION_TAG = 20;

exports.main = async (event) => {
  const params = getParams(event);

  const { userId, error } = await getAuthUser(event);
  if (error) return error;

  const messageId = params.messageId || params.id;
  if (!messageId) {
    return { code: 400, message: '缺少留言ID', data: null };
  }

  const text = typeof params.content === 'string' ? params.content.trim() : '';
  const imageList = Array.isArray(params.images)
    ? params.images.filter((i) => typeof i === 'string' && i).slice(0, MAX_IMAGES)
    : [];

  if (!text && imageList.length === 0) {
    return { code: 4004, message: '文字和图片至少填写一项', data: null };
  }
  if (text.length > MAX_CONTENT) {
    return { code: 4004, message: `文字最多${MAX_CONTENT}字`, data: null };
  }

  try {
    const res = await db.collection('messages').doc(String(messageId)).get();
    const doc = firstDoc(res);
    if (!doc) {
      return { code: 4005, message: '留言不存在', data: null };
    }
    // 仅作者本人可编辑
    if (doc.authorId !== userId) {
      return { code: 4006, message: '仅作者可编辑自己的留言', data: null };
    }

    const emotionTag =
      typeof params.emotionTag === 'string' ? params.emotionTag.trim().slice(0, MAX_EMOTION_TAG) : '';
    const contentType = text && imageList.length > 0 ? 1 : text ? 0 : 2;

    await db.collection('messages').doc(String(messageId)).update({
      content: text,
      contentType,
      images: imageList,
      emotionTag,
      // 编辑后重置已读状态，接收方需重新确认
      isRead: false,
      readTime: null,
      updateTime: Date.now(),
    });

    return { code: 0, message: 'success', data: null };
  } catch (e) {
    console.error('编辑留言失败:', e);
    return { code: 500, message: '服务器内部错误', data: null };
  }
};