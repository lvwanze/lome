const cloudbase = require('@cloudbase/node-sdk');
const jwt = require('jsonwebtoken');

const app = cloudbase.init({ env: process.env.ENV_ID });
const db = app.database();
const usersCollection = db.collection('users');
const bindCodesCollection = db.collection('bindCodes');

exports.main = async (event, context) => {
  const { bindCode } = event;
  const token = event.headers?.authorization?.replace('Bearer ', '') || event.token;

  if (!token) {
    return { code: 4001, message: "未登录" };
  }

  if (!bindCode) {
    return { code: 6001, message: "请提供绑定码" };
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const userId = decoded.userId;

    // 检查当前用户是否已绑定
    const currentUserQuery = await usersCollection.doc(userId).get();
    const currentUser = currentUserQuery.data;

    if (!currentUser) {
      return { code: 4002, message: "用户不存在" };
    }

    if (currentUser.partnerId) {
      return { code: 5001, message: "您已绑定伴侣" };
    }

    // 查询绑定码
    const codeQuery = await bindCodesCollection
      .where({ code: bindCode, used: false })
      .limit(1)
      .get();

    const codeData = codeQuery.data[0];

    if (!codeData) {
      return { code: 6001, message: "绑定码不存在，请检查是否输入正确" };
    }

    if (Date.now() > codeData.expireTime) {
      return { code: 6002, message: "绑定码已过期，请让对方重新生成" };
    }

    if (codeData.userId === userId) {
      return { code: 6003, message: "不能绑定自己哦" };
    }

    // 检查对方是否已绑定
    const partnerQuery = await usersCollection.doc(codeData.userId).get();
    const partner = partnerQuery.data;

    if (!partner) {
      return { code: 4002, message: "对方用户不存在" };
    }

    if (partner.partnerId) {
      return { code: 6004, message: "对方已绑定他人" };
    }

    // 双向绑定
    await usersCollection.doc(userId).update({
      partnerId: codeData.userId,
      isBound: true
    });

    await usersCollection.doc(codeData.userId).update({
      partnerId: userId,
      isBound: true
    });

    // 标记绑定码已使用
    await bindCodesCollection.doc(codeData._id).update({
      used: true,
      usedBy: userId,
      usedTime: Date.now()
    });

    return {
      code: 0,
      message: "绑定成功",
      data: {
        partnerId: codeData.userId,
        partnerNickname: partner.nickname
      }
    };

  } catch (error) {
    if (error.name === 'JsonWebTokenError' || error.name === 'TokenExpiredError') {
      return { code: 4001, message: "Token无效或已过期" };
    }
    console.error('绑定失败:', error);
    return { code: 500, message: "服务器内部错误" };
  }
};