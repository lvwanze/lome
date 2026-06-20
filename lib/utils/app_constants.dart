/// 全局常量配置
/// 集中管理接口地址、接口路径、本地存储 Key
class AppConstants {
  AppConstants._();

  // ========== Base URL ==========
  // 【重要】先用占位符，等后端部署后替换成真实地址（任务六 Step 1）
  static const String baseUrl = 'https://api.lome-app.com';

  // ========== 接口路径 ==========
  // 注意：接口文档中路径格式不统一（有的带 /api/v1，有的不带），
  // 这里按文档要求全部统一为 /api/v1/xxx。
  static const String sendCodeEndpoint = '/api/v1/auth/code'; // 接口1 发送验证码
  static const String loginEndpoint = '/api/v1/auth/login'; // 接口2 登录
  static const String userInfoEndpoint = '/api/v1/user/me'; // 接口3 获取我的信息
  static const String generateBindCodeEndpoint =
      '/api/v1/bind/generate'; // 接口4 生成绑定码
  static const String useBindCodeEndpoint = '/api/v1/bind/use'; // 接口5 使用绑定码
  static const String unbindEndpoint = '/api/v1/bind/unbind'; // 接口6 解除绑定

  // ========== 本地存储 Key ==========
  static const String tokenKey = 'lome_token';
  static const String userKey = 'lome_user';
}
