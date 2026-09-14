const cloudbase = require('@cloudbase/node-sdk');
const jwt = require('jsonwebtoken');

const app = cloudbase.init({
  env: process.env.ENV_ID
});
const db = app.database();
const usersCollection = db.collection('users');

function getUserIdFromToken(token) {
  const decoded = jwt.verify(token, process.env.JWT_SECRET);
  return decoded.userId;
}

// 兼容不同 SDK 版本的 doc().get() 返回结构（对象或数组）
function firstDoc(res) {
  if (!res || !res.data) return null;
  return Array.isArray(res.data) ? res.data[0] : res.data;
}

exports.main = async (event, context) => {
  // 从请求头获取token（HTTP网关会把header传进来）
  const token = (event.headers && event.headers.authorization)
    ? event.headers.authorization.replace('Bearer ', '')
    : event.token;

  if (!token) {
    return { code: 4001, message: "未登录" };
  }

  try {
    const userId = getUserIdFromToken(token);

    // 用 _id 查询用户
    const userQuery = await usersCollection.doc(userId).get();
    const user = firstDoc(userQuery);

    if (!user) {
      return { code: 4002, message: "用户不存在" };
    }

    // 如果已绑定，查询伴侣昵称
    let partnerNickname = '';
    if (user.partnerId) {
      const partnerQuery = await usersCollection.doc(user.partnerId).get();
      const partner = firstDoc(partnerQuery);
      partnerNickname = partner && partner.nickname ? partner.nickname : '';
    }

    return {
      code: 0,
      message: "获取成功",
      data: {
        userId: userId,
        phone: user.phone,
        nickname: user.nickname,
        isBound: !!user.partnerId,
        partnerId: user.partnerId || null,
        partnerNickname: partnerNickname
      }
    };

  } catch (error) {
    if (error.name === 'JsonWebTokenError' || error.name === 'TokenExpiredError') {
      return { code: 4001, message: "Token无效或已过期" };
    }
    console.error('获取用户信息失败:', error);
    return { code: 500, message: "服务器内部错误" };
  }
};
