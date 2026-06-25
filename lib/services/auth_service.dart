import 'package:shared_preferences/shared_preferences.dart';
import 'cloudbase_service.dart';

class AuthService {
  // 单例模式
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final CloudBaseService _cloudbase = CloudBaseService();

  /// 保存登录信息到本地缓存
  Future<void> saveLoginInfo(String phone, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_phone', phone);
    await prefs.setString('user_id', userId);
    await prefs.setBool('is_logged_in', true);
  }

  /// 检查用户登录状态
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  /// 获取本地存储的用户手机号
  Future<String?> getUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_phone');
  }

  /// 获取本地存储的用户ID
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  /// 清除本地登录信息，退出登录
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    // 可选：同时清除云开发登录态
    // await _cloudbase.logout();
  }

  /// 【兼容倒计时按钮】发送验证码（别名，匹配页面 sendCode 调用）
  Future<void> sendCode(String phone) async {
    final bool sendSuccess = await sendSmsCode(phone);
    if (!sendSuccess) {
      // 发送失败抛出异常，让页面catch捕获弹窗提示
      throw Exception('验证码发送失败，请稍后重试');
    }
  }

  /// 底层发送短信验证码接口
  Future<bool> sendSmsCode(String phone) async {
    try {
      return await _cloudbase.sendSmsCode(phone);
    } catch (e) {
      print('发送验证码异常：$e');
      return false;
    }
  }

  /// 短信验证码登录
  Future<Map<String, dynamic>> login(String phone, String code) async {
    try {
      final result = await _cloudbase.login(phone, code);
      print('AuthService login result: $result');
      if (result['success'] == true) {
        await saveLoginInfo(phone, result['userId'] ?? phone);
      }
      return result;
    } catch (e) {
      print('登录接口异常：$e');
      return {
        'success': false,
        'msg': e.toString().replaceFirst('Exception: ', '')
      };
    }
  }
}