const cloudbase = require('@cloudbase/node-sdk');
const jwt = require('jsonwebtoken');

const app = cloudbase.init({ env: process.env.ENV_ID });
const db = app.database();

const interactionMap = {
  'hug': '抱抱 🤗',
  'kiss': '贴贴 😘',
  'cheers': '干杯 🥂',
};

exports.main = async (event, context) => {
  const token = (event.headers && event.headers.authorization)
    ? event.headers.authorization.replace('Bearer ', '')
    : event.token;

  if (!token) {
    return { code: 4001, message: "未登录" };
  }

  let type = event.type;
  if (!type && event.body) {
    try {
      const body = typeof event.body === 'string' ? JSON.parse(event.body) : event.body;
      type = body.type;
    } catch (e) {
      console.error('解析 body 失败:', e);
    }
  }

  if (!type) {
    return { code: 4002, message: "缺少互动类型" };
  }

  const validTypes = ['hug', 'kiss', 'cheers'];
  if (!validTypes.includes(type)) {
    return { code: 4003, message: "无效的互动类型" };
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const userId = decoded.userId;

    const userQuery = await db.collection('users').doc(userId).get();
    const user = userQuery.data;

    if (!user) {
      return { code: 4002, message: "用户不存在" };
    }

    return {
      code: 0,
      message: `${interactionMap[type] || type} 已发送 💕`,
      data: null
    };

  } catch (error) {
    if (error.name === 'JsonWebTokenError' || error.name === 'TokenExpiredError') {
      return { code: 4001, message: "Token无效或已过期" };
    }
    console.error('发送互动失败:', error);
    return { code: 500, message: "服务器内部错误" };
  }
};