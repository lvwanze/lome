const cloudbase = require('@cloudbase/node-sdk');
const jwt = require('jsonwebtoken');

const app = cloudbase.init({ env: process.env.ENV_ID });
const db = app.database();

// 兼容不同 SDK 版本的 doc().get() 返回结构（对象或数组）
function firstDoc(res) {
  if (!res || !res.data) return null;
  return Array.isArray(res.data) ? res.data[0] : res.data;
}

function generateBindCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let code = '';
  for (let i = 0; i < 6; i++) {
    code += chars[Math.floor(Math.random() * chars.length)];
  }
  return code;
}

exports.main = async (event, context) => {
  const token = event.headers?.authorization?.replace('Bearer ', '') || event.token;

  if (!token) {
    return { code: 4001, message: "未登录" };
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const userId = decoded.userId;

    // 检查用户是否已绑定
    const userQuery = await db.collection('users').doc(userId).get();
    const user = firstDoc(userQuery);

    if (!user) {
      return { code: 4002, message: "用户不存在" };
    }

    if (user.partnerId) {
      return { code: 5001, message: "您已绑定伴侣，不能重复生成" };
    }

    const bindCode = generateBindCode();
    const expireTime = Date.now() + 600000;

    await db.collection('bindCodes').add({
      code: bindCode,
      userId: userId,
      expireTime: expireTime,
      used: false,
      createTime: Date.now()
    });

    return {
      code: 0,
      message: "绑定码生成成功",
      data: {
        bindCode: bindCode,
        expireTime: 600   // ✅ 数字类型，不是字符串
      }
    };

  } catch (error) {
    if (error.name === 'JsonWebTokenError' || error.name === 'TokenExpiredError') {
      return { code: 4001, message: "Token无效或已过期" };
    }
    console.error('生成绑定码失败:', error);
    return { code: 500, message: "服务器内部错误" };
  }
};