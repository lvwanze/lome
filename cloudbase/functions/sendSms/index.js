const cloudbase = require('@cloudbase/node-sdk');

const app = cloudbase.init({
  env: process.env.ENV_ID
});

exports.main = async (event) => {
  // 强制把 phone 转成字符串
  const phone = String(event.phone || '');

  console.log('收到手机号:', phone);

  // 直接返回成功，固定验证码 666666，不做任何校验
  return {
    code: 0,
    message: '验证码发送成功',
    data: { expireTime: 300 }
  };
};