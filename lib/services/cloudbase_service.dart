import 'dart:convert';
import 'package:http/http.dart' as http;

class CloudBaseService {
  static final CloudBaseService _instance = CloudBaseService._internal();
  factory CloudBaseService() => _instance;
  CloudBaseService._internal();

  // ⭐ 填写你的信息 ⭐
  static const String envId = 'love-app1-0g8yva6l11e713ef';
  static const String secretId = 'AKIDV0QeDorxLnAZ7WsKmDRbfX4UtGhz5xlN';

  static const String secretKey = 'b6PSShmdS8ct6GIAzoVDFLMNGB622JWc';
  
  // 获取 access_token
  Future<String?> getAccessToken() async {

    return envId;
  }
  
  /// 调用云函数（简化版）
  Future<Map<String, dynamic>> callFunction(
    String name,
    Map<String, dynamic> data,
  ) async {
    // 云函数调用 URL（需要开启匿名访问）
    final url = 'https://$envId.service.tcloudbase.com/$name';
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '网络错误: $e',
      };
    }
  }
}