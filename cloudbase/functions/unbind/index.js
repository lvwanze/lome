const cloudbase = require('@cloudbase/node-sdk');
const jwt = require('jsonwebtoken');

const app = cloudbase.init({ env: process.env.ENV_ID });
const db = app.database();
const usersCollection = db.collection('users');

exports.main = async (event, context) => {
  const token = event.headers?.authorization?.replace('Bearer ', '') || event.token;

  if (!token) {
    return { code: 4001, message: "未登录" };
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const userId = decoded.userId;

    const userQuery = await usersCollection.doc(userId).get();
    const user = userQuery.data;

    if (!user) {
      return { code: 4002, message: "用户不存在" };
    }

    if (!user.partnerId) {
      return { code: 7001, message: "您尚未绑定伴侣" };
    }

    const partnerId = user.partnerId;

    await usersCollection.doc(userId).update({
      partnerId: null,
      isBound: false
    });

    await usersCollection.doc(partnerId).update({
      partnerId: null,
      isBound: false
    });

    return {
      code: 0,
      message: "已解除绑定"
    };

  } catch (error) {
    if (error.name === 'JsonWebTokenError' || error.name === 'TokenExpiredError') {
      return { code: 4001, message: "Token无效或已过期" };
    }
    console.error('解除绑定失败:', error);
    return { code: 500, message: "服务器内部错误" };
  }
};