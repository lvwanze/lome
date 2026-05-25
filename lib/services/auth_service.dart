import 'package:shared_preferences/shared_preferences.dart';
import 'cloudbase_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final CloudBaseService _cloudbase = CloudBaseService();

  /// 保存登录信息
  Future<void> saveLoginInfo(String phone, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_phone', phone);
    await prefs.setString('user_id', userId);
    await prefs.setBool('is_logged_in', true);
  }

  /// 检查是否已登录
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  /// 获取当前用户手机号
  Future<String?> getUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_phone');
  }

  /// 退出登录
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// 发送验证码
  Future<bool> sendSmsCode(String phone) async {
    return await _cloudbase.sendSmsCode(phone);
  }

  /// 登录
  Future<Map<String, dynamic>> login(String phone, String code) async {
    final result = await _cloudbase.login(phone, code);
    print('AuthService login result: $result');  
    if (result['success'] == true) {
      await saveLoginInfo(phone, result['userId'] ?? phone);
    }
    return result;
  }
}