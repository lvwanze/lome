exports.main = async (event, context) => {
  const { phone } = event;
  
  console.log('收到手机号:', phone);
  
  // 开发测试阶段，固定验证码为 666666
  const code = '666666';
  
  return {
    success: true,
    code: code,
    message: '验证码发送成功'
  };
};