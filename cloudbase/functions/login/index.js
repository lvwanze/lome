const cloudbase = require('@cloudbase/node-sdk');
const jwt = require('jsonwebtoken');

const app = cloudbase.init({
  env: process.env.ENV_ID
});
const db = app.database();
const usersCollection = db.collection('users');

function generateToken(userId) {
  return jwt.sign(
    { userId: userId },
    process.env.JWT_SECRET || 'your-secret-key',
    { expiresIn: '7d' }
  );
}

function generateNickname() {
  return '用户' + String(Math.floor(1000 + Math.random() * 9000));
}

exports.main = async (event) => {
  // 兼容多种参数传入方式
  const params = event.body ? JSON.parse(event.body) : event;
  // CLI 调用时参数在 event 根上，HTTP 调用时在 body 里
  const phone = params.phone || event.phone;
  const code = params.code || event.code;

  console.log('登录请求:', { phone, code });

  const codeStr = String(code || '').trim();
  if (codeStr !== '666666') {
    return { code: 2001, message: '验证码错误，请重新输入' };
  }

  const userQuery = await usersCollection.where({ phone: phone }).get();
  let user = userQuery.data[0];
  let userId = user?._id;

  if (!user) {
    const newUser = {
      phone: phone,
      nickname: generateNickname(),
      createTime: Date.now(),
      isBound: false,
      partnerId: null
    };
    const addResult = await usersCollection.add(newUser);
    userId = addResult.id;
    user = { ...newUser, _id: userId };
    console.log('新用户注册:', userId);
  }

  const token = generateToken(userId);

  return {
    code: 0,
    message: '登录成功',
    data: {
      userId: userId,
      phone: user.phone,
      nickname: user.nickname,
      token: token,
      isBound: user.isBound || false
    }
  };
};