import 'dart:convert';
import 'package:http/http.dart' as http;
// 如果 env.dart 存在则导入，否则用本地配置兜底
import '../config/env.dart' if (dart.library.html) '../config/env.dart';

class CloudBaseService {
  static final CloudBaseService _instance = CloudBaseService._internal();
  factory CloudBaseService() => _instance;
  CloudBaseService._internal();

  // 环境ID（硬编码兜底，避免 EnvConfig 不存在时报错）
  static const String _defaultEnvId = 'love-app1-0g8yva6l11e713ef';
  static const String _defaultBaseUrl =
      'https://love-app1-0g8yva6l11e713ef-1418513210.ap-shanghai.app.tcloudbase.com';

  // 优先从环境配置读取，如果 EnvConfig 不存在则使用硬编码值
  String get envId {
    try {
      return EnvConfig.cloudEnvId;
    } catch (_) {
      return _defaultEnvId;
    }
  }

  String get baseUrl {
    try {
      return EnvConfig.cloudBaseUrl;
    } catch (_) {
      return _defaultBaseUrl;
    }
  }

  /// 调用云函数
  Future<Map<String, dynamic>> callFunction(
    String name,
    Map<String, dynamic> data,
  ) async {
    final url = '$baseUrl/$name';

    print('📡 调用云函数: $url');
    print('📦 请求参数: $data');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      print('✅ 响应状态: ${response.statusCode}');
      print('📄 响应内容: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ 云函数调用错误: $e');
      return {
        'success': false,
        'message': '网络错误: $e',
      };
    }
  }

  /// 发送验证码（便捷方法）
  Future<bool> sendSmsCode(String phone) async {
    final result = await callFunction('sendSms', {'phone': phone});
    return result['success'] == true;
  }

  /// 登录（便捷方法）
  Future<Map<String, dynamic>> login(String phone, String code) async {
    return await callFunction('login', {
      'phone': phone,
      'code': code,
    });
  }
}