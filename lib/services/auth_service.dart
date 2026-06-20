// 本文件在「假数据阶段」用 print 输出调试日志（如 `【假数据】...`），
// 供任务五验证时在控制台核对，故整文件忽略 avoid_print 提示。
// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/api_response.dart';
import '../utils/app_constants.dart';

/// 认证服务 - 单例模式
///
/// 对外提供 8 个方法（详见文件底部），李卓与组长直接调用即可。
/// 当前为【假数据阶段】：每个方法直接返回模拟数据，UI 可完整跑通流程。
/// 后端部署后，按任务六将「假数据」段注释掉、把「真实接口」段取消注释即可。
class AuthService {
  // ============ 单例 ============
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // ============ 本地存储 ============
  SharedPreferences? _prefs;

  /// 初始化（在 main.dart 中调用一次）
  static Future<AuthService> init() async {
    final prefs = await SharedPreferences.getInstance();
    _instance._prefs = prefs;
    return _instance;
  }

  // ============ Getter ============
  String? get token => _prefs?.getString(AppConstants.tokenKey);

  // ============ 私有方法 ============
  Future<void> _saveToken(String token) async {
    await _prefs?.setString(AppConstants.tokenKey, token);
  }

  Future<void> _saveUser(User user) async {
    await _prefs?.setString(AppConstants.userKey, jsonEncode(user.toJson()));
  }

  /// 获取请求头（含Token）
  Map<String, String> _getHeaders({bool needAuth = true}) {
    final headers = {'Content-Type': 'application/json'};
    if (needAuth && token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }
  /// 统一请求方法（真实接口使用）
  // 假数据阶段仅被注释中的真实接口代码引用，故先忽略 unused 警告（任务六启用后移除此行）
  // ignore: unused_element
  Future<ApiResponse<T>> _request<T>(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    required T Function(dynamic) fromJsonT,
    bool needAuth = true,
  }) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
      final headers = _getHeaders(needAuth: needAuth);

      http.Response response;
      if (method == 'GET') {
        response = await http.get(url, headers: headers);
      } else {
        response = await http.post(
          url,
          headers: headers,
          body: jsonEncode(body),
        );
      }

      // 处理HTTP 401
      if (response.statusCode == 401) {
        await logout();
        throw Exception('登录已过期，请重新登录');
      }

      // 处理HTTP 500等
      if (response.statusCode >= 500) {
        throw Exception('服务器开小差了，请稍后再试');
      }

      final jsonData = jsonDecode(response.body);
      return ApiResponse<T>.fromJson(jsonData, fromJsonT);
    } catch (e) {
      print('【网络请求失败】$endpoint: $e');
      rethrow;
    }
  }
  // ============================================================
  // ============ 以下是8个对外公开的方法 ============
  // ============================================================

  // ---------- 4.1 发送验证码 ----------
  /// 用途：李卓在登录页点击"获取验证码"时调用
  /// 接口：POST /api/v1/auth/code
  Future<void> sendCode(String phone) async {
    // ========== 假数据阶段 ==========
    print('【假数据】向 $phone 发送验证码成功');
    await Future.delayed(const Duration(seconds: 1));
    return;
    // ========== 假数据结束 ==========

    /* ========== 真实接口（等后端部署后取消注释） ==========
    final response = await _request<dynamic>(
      'POST',
      AppConstants.sendCodeEndpoint,
      body: {'phone': phone},
      fromJsonT: (data) => data,
      needAuth: false,
    );
    if (!response.isSuccess) {
      throw Exception(_getErrorMessage(response.code, response.message));
    }
    ========== 真实接口结束 ========== */
  }

  // ---------- 4.2 登录 ----------
  /// 用途：李卓点击"登录"按钮时调用
  /// 接口：POST /api/v1/auth/login
  /// 返回：User对象（登录成功后自动保存Token和User）
  Future<User> login(String phone, String code) async {
    // ========== 假数据阶段 ==========
    print('【假数据】手机号 $phone 登录成功');
    await Future.delayed(const Duration(seconds: 1));
    final fakeUser = User(
      userId: 'fake_user_001',
      phone: phone,
      nickname: '用户1008',
      isBound: false,
      partnerId: null,
      partnerNickname: null,
    );
    await _saveToken('fake_token_123456');
    await _saveUser(fakeUser);
    return fakeUser;
    // ========== 假数据结束 ==========

    /* ========== 真实接口（等后端部署后取消注释） ==========
    final response = await _request<Map<String, dynamic>>(
      'POST',
      AppConstants.loginEndpoint,
      body: {'phone': phone, 'code': code},
      fromJsonT: (data) => data as Map<String, dynamic>,
      needAuth: false,
    );
    if (!response.isSuccess) {
      throw Exception(_getErrorMessage(response.code, response.message));
    }
    final data = response.data!;
    await _saveToken(data['token'] as String);
    final user = User(
      userId: data['userId'] ?? '',
      phone: data['phone'] ?? '',
      nickname: data['nickname'] ?? '用户',
      isBound: data['isBound'] ?? false,
      partnerId: data['partnerId'],
      partnerNickname: data['partnerNickname'],
    );
    await _saveUser(user);
    return user;
    ========== 真实接口结束 ========== */
  }
  // ---------- 4.3 获取用户信息 ----------
  /// 用途：组长进入首页、下拉刷新时调用
  /// 接口：GET /api/v1/user/me
  Future<User> getUserInfo() async {
    // ========== 假数据阶段 ==========
    print('【假数据】获取用户信息成功');
    await Future.delayed(const Duration(milliseconds: 500));
    return await getCurrentUser() ??
        User(
          userId: 'fake_user_001',
          phone: '13800138000',
          nickname: '用户1008',
          isBound: false,
        );
    // ========== 假数据结束 ==========

    /* ========== 真实接口（等后端部署后取消注释） ==========
    final response = await _request<Map<String, dynamic>>(
      'GET',
      AppConstants.userInfoEndpoint,
      fromJsonT: (data) => data as Map<String, dynamic>,
      needAuth: true,
    );
    if (!response.isSuccess) {
      throw Exception(_getErrorMessage(response.code, response.message));
    }
    final data = response.data!;
    final user = User(
      userId: data['userId'] ?? '',
      phone: data['phone'] ?? '',
      nickname: data['nickname'] ?? '用户',
      isBound: data['isBound'] ?? false,
      partnerId: data['partnerId'],
      partnerNickname: data['partnerNickname'],
    );
    await _saveUser(user);
    return user;
    ========== 真实接口结束 ========== */
  }

  // ---------- 4.4 生成绑定码 ----------
  /// 用途：组长进入绑定页时调用
  /// 接口：POST /api/v1/bind/generate
  /// 返回：绑定码
  Future<String> generateBindCode() async {
    // ========== 假数据阶段 ==========
    print('【假数据】生成绑定码成功');
    await Future.delayed(const Duration(seconds: 1));
    return 'LOVE-ABCD-1234';
    // ========== 假数据结束 ==========

    /* ========== 真实接口（等后端部署后取消注释） ==========
    final response = await _request<Map<String, dynamic>>(
      'POST',
      AppConstants.generateBindCodeEndpoint,
      fromJsonT: (data) => data as Map<String, dynamic>,
      needAuth: true,
    );
    if (!response.isSuccess) {
      throw Exception(_getErrorMessage(response.code, response.message));
    }
    return response.data!['bindCode'] as String;
    ========== 真实接口结束 ========== */
  }
  // ---------- 4.5 使用绑定码 ----------
  /// 用途：组长点击"确认绑定"时调用
  /// 接口：POST /api/v1/bind/use
  /// 返回：伴侣信息（partnerId, partnerNickname），同时自动刷新本地用户信息
  Future<Map<String, String>> useBindCode(String code) async {
    // ========== 假数据阶段 ==========
    print('【假数据】使用绑定码 $code 成功');
    await Future.delayed(const Duration(seconds: 1));
    final currentUser = await getCurrentUser();
    if (currentUser != null) {
      final updatedUser = User(
        userId: currentUser.userId,
        phone: currentUser.phone,
        nickname: currentUser.nickname,
        isBound: true,
        partnerId: 'partner_001',
        partnerNickname: '我的伴侣',
      );
      await _saveUser(updatedUser);
    }
    return {'partnerId': 'partner_001', 'partnerNickname': '我的伴侣'};
    // ========== 假数据结束 ==========

    /* ========== 真实接口（等后端部署后取消注释） ==========
    final response = await _request<Map<String, dynamic>>(
      'POST',
      AppConstants.useBindCodeEndpoint,
      body: {'bindCode': code},
      fromJsonT: (data) => data as Map<String, dynamic>,
      needAuth: true,
    );
    if (!response.isSuccess) {
      throw Exception(_getErrorMessage(response.code, response.message));
    }
    final data = response.data!;
    await getUserInfo(); // 绑定成功后刷新本地用户信息
    return {
      'partnerId': data['partnerId'] as String,
      'partnerNickname': data['partnerNickname'] as String,
    };
    ========== 真实接口结束 ========== */
  }

  // ---------- 4.6 解除绑定 ----------
  /// 用途：组长点击"解除绑定"时调用
  /// 接口：POST /api/v1/bind/unbind
  Future<void> unbind() async {
    // ========== 假数据阶段 ==========
    print('【假数据】解除绑定成功');
    await Future.delayed(const Duration(seconds: 1));
    final currentUser = await getCurrentUser();
    if (currentUser != null) {
      final updatedUser = User(
        userId: currentUser.userId,
        phone: currentUser.phone,
        nickname: currentUser.nickname,
        isBound: false,
        partnerId: null,
        partnerNickname: null,
      );
      await _saveUser(updatedUser);
    }
    return;
    // ========== 假数据结束 ==========

    /* ========== 真实接口（等后端部署后取消注释） ==========
    final response = await _request<dynamic>(
      'POST',
      AppConstants.unbindEndpoint,
      fromJsonT: (data) => data,
      needAuth: true,
    );
    if (!response.isSuccess) {
      throw Exception(_getErrorMessage(response.code, response.message));
    }
    await getUserInfo(); // 解绑成功后刷新本地用户信息
    ========== 真实接口结束 ========== */
  }
  // ---------- 4.7 退出登录 ----------
  /// 用途：李卓或组长点击退出登录时调用
  Future<void> logout() async {
    await _prefs?.remove(AppConstants.tokenKey);
    await _prefs?.remove(AppConstants.userKey);
    print('【操作】已退出登录');
  }

  // ---------- 4.8 检查登录状态 ----------
  /// 用途：App启动时、路由守卫中判断是否登录
  bool isLoggedIn() {
    final token = _prefs?.getString(AppConstants.tokenKey);
    return token != null && token.isNotEmpty;
  }

  // ---------- 辅助方法 ----------
  /// 获取当前保存的用户信息（从本地读取）
  Future<User?> getCurrentUser() async {
    final userJson = _prefs?.getString(AppConstants.userKey);
    if (userJson == null) return null;
    try {
      return User.fromJson(jsonDecode(userJson));
    } catch (e) {
      return null;
    }
  }

  /// 错误码翻译（任务三：错误码映射表）
  // 假数据阶段仅被注释中的真实接口代码引用，故先忽略 unused 警告（任务六启用后移除此行）
  // ignore: unused_element
  String _getErrorMessage(int code, String defaultMessage) {
    switch (code) {
      // 100x: 验证码相关
      case 1001:
        return '请输入正确的手机号';
      case 1002:
        return '验证码发送太频繁，请稍后再试';
      case 1003:
        return '验证码发送失败，请重试';
      // 200x: 验证码验证
      case 2001:
        return '验证码错误，请重新输入';
      case 2002:
        return '验证码已过期，请重新获取';
      // 400x: Token相关
      case 4001:
        return '登录已过期，请重新登录';
      // 500x: 绑定码生成
      case 5001:
        return '您已绑定伴侣，不能重复生成';
      // 600x: 绑定码使用
      case 6001:
        return '绑定码不存在，请检查是否输入正确';
      case 6002:
        return '绑定码已过期，请让对方重新生成';
      case 6003:
        return '不能绑定自己哦';
      case 6004:
        return '对方已绑定他人';
      // 700x: 解绑
      case 7001:
        return '您尚未绑定伴侣';
      // 通用 HTTP / 网络
      case 401:
        return '登录已过期，请重新登录';
      case 404:
        return '接口不存在，请联系客服';
      case 500:
        return '服务器开小差了，请稍后再试';
      case -1:
        return '网络异常，请检查网络连接';
      default:
        return defaultMessage.isNotEmpty ? defaultMessage : '操作失败，请稍后重试';
    }
  }
}
