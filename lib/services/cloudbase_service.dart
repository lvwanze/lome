import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env.dart'; // 导入环境配置文件

class CloudBaseService {
  static final CloudBaseService _instance = CloudBaseService._internal();
  factory CloudBaseService() => _instance;
  CloudBaseService._internal();

  // 从环境配置读取，移除硬编码明文
  String get envId => EnvConfig.cloudEnvId;
  String get baseUrl => EnvConfig.cloudBaseUrl;

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