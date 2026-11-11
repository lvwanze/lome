import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://love-app1-0g8yva6l11e713ef-1418513210.ap-shanghai.app.tcloudbase.com';

  static Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    print('【GET请求】URL: $uri');
    final response = await http.get(
      uri,
      headers: await _buildHeaders(),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final url = Uri.parse('$baseUrl$path');
    final headers = await _buildHeaders();

    print('【POST请求】URL: $url');
    print('【POST请求】Headers: $headers');
    print('【POST请求】Body: $body');

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 10));

      print('【POST响应】状态码: ${response.statusCode}');
      print('【POST响应】内容: ${response.body}');
      return _handleResponse(response);
    } catch (e) {
      print('【POST异常】$e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final url = Uri.parse('$baseUrl$path');
    final headers = await _buildHeaders();

    print('【PUT请求】URL: $url');
    print('【PUT请求】Body: $body');

    try {
      final response = await http.put(
        url,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 10));

      print('【PUT响应】状态码: ${response.statusCode}');
      print('【PUT响应】内容: ${response.body}');
      return _handleResponse(response);
    } catch (e) {
      print('【PUT异常】$e');
      rethrow;
    }
  }

  static Future<Map<String, String>> _buildHeaders() async {
    // ============ 临时硬编码 Token（联调完成后删除） ============
    const testToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiIzMDExNTQ2YzZhM2UyMmU5MDAwYTMwYzY1MWQ5YjM2NiIsImlhdCI6MTc4Njk2NzIyNSwiZXhwIjoxNzg3NTcyMDI1fQ.UMPrC2aggMNjPbwzwuQUEO2HQ4cWVqAR04nBkYEVlvQ';
    print('【硬编码Token】$testToken'); 
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $testToken',
    };
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    print('【API响应】状态码: ${response.statusCode}');
    print('【API响应】内容: ${response.body}');
    final body = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      throw Exception('API Error: ${response.statusCode}, ${body['message'] ?? 'Unknown error'}');
    }
  }
}