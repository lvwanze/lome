exports.main = async (event, context) => {
  const { phone, code } = event;
  
  // 验证码校验（开发阶段固定为 666666）
  if (code !== '666666') {
    return {
      success: false,
      message: '验证码错误'
    };
  }
  
  // 生成用户ID（简化版）
  const userId = `user_${phone}`;
  
  return {
    success: true,
    message: '登录成功',
    userId: userId,
    phone: phone
  };
};