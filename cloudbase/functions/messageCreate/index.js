// 发布留言 POST /api/v1/messages
const { db, getParams, getAuthUser } = require('./common');

const MAX_CONTENT = 50; // 正文最多50字
const MAX_IMAGES = 2; // 图片最多2张
const MAX_EMOTION_TAG = 20;

// 校验发布内容：文字/图片至少一项，文字≤50字，图片≤2张
function validateContent(content, images) {
  const text = typeof content === 'string' ? content.trim() : '';
  const imageList = Array.isArray(images)
    ? images.filter((i) => typeof i === 'string' && i).slice(0, MAX_IMAGES)
    : [];

  if (!text && imageList.length === 0) {
    return { error: { code: 4004, message: '文字和图片至少填写一项', data: null } };
  }
  if (text.length > MAX_CONTENT) {
    return { error: { code: 4004, message: `文字最多${MAX_CONTENT}字`, data: null } };
  }
  return { text, imageList };
}

exports.main = async (event) => {
  const params = getParams(event);

  const { userId, partnerId, error } = await getAuthUser(event);
  if (error) return error;
  if (!partnerId) {
    return { code: 4006, message: '尚未绑定伴侣，无法发布留言', data: null };
  }

  const { error: valError, text, imageList } = validateContent(params.content, params.images);
  if (valError) return valError;

  const emotionTag =
    typeof params.emotionTag === 'string' ? params.emotionTag.trim().slice(0, MAX_EMOTION_TAG) : '';

  const now = Date.now();
  // 0:纯文本, 1:图文, 2:纯图片
  const contentType = text && imageList.length > 0 ? 1 : text ? 0 : 2;

  try {
    const res = await db.collection('messages').add({
      authorId: userId,
      partnerId: partnerId,
      content: text,
      contentType,
      images: imageList,
      emotionTag,
      isRead: false,
      readTime: null,
      replyContent: '',
      replyAuthorId: '',
      replyTime: null,
      createTime: now,
      updateTime: now,
    });

    return {
      code: 0,
      message: 'success',
      data: { messageId: res.id, createTime: now },
    };
  } catch (e) {
    console.error('发布留言失败:', e);
    return { code: 500, message: '服务器内部错误', data: null };
  }
};
