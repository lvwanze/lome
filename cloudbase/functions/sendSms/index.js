exports.main = async (event, context) => {
  const { phone } = event;
  
  // 开发测试阶段，固定验证码为 666666
  const code = '666666';
  
  console.log(`发送验证码到: ${phone}, 验证码: ${code}`);
  
  // TODO: 接入真实短信服务商
  
  return {
    success: true,
    code: code
  };
};