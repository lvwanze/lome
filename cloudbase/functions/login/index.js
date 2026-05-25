exports.main = async (event, context) => {
  const { phone, code } = event;
  
  console.log('收到手机号:', phone);
  console.log('收到验证码:', code);
  
  // 跳过验证码验证，任何验证码都成功
  return {
    success: true,
    message: '登录成功',
    userId: `user_${phone}`,
    phone: phone
  };
};