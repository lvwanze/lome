import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lome/utils/app_constants.dart';

class ApiService {
  static const String baseUrl = 'https://love-app1-0g8yva6l11e713ef-1418513210.ap-shanghai.app.tcloudbase.com';

  // ============ GET 请求 ============
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

  // ============ POST 请求 ============
  static Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final url = Uri.parse('$baseUrl$path');
    final headers = await _buildHeaders();

    print('【POST请求】URL: $url');
    print('【POST请求】Body 长度: ${body != null ? jsonEncode(body).length : 0}');

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 30));

      print('【POST响应】状态码: ${response.statusCode}');
      print('【POST响应】内容: ${response.body}');
      return _handleResponse(response);
    } catch (e) {
      print('【POST异常】$e');
      rethrow;
    }
  }

  // ============ PUT 请求 ============
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

  // ============ 图片上传上限 ============
  // 必须与服务端 uploadImage 的 MAX_SIZE 保持一致。
  // 网关对「文本类型」请求体限制 100KB，所以这里绝不能再用 JSON + base64：
  // base64 膨胀 33%，原图超过约 72KB 就会被网关以 EXCEED_MAX_PAYLOAD_SIZE 拒绝。
  // 改成原始二进制 body 后走「其他类型」档，实测服务端上限 4MB。
  static const int maxUploadBytes = 4 * 1024 * 1024;

  // ============ 图片上传（原始二进制方式） ============
  //
  // 返回 { fileId, url }。**入库请存 fileId**：url 是临时链接、会过期，
  // 读取时由 calendarDaily / messageList 等重新换取。
  static Future<Map<String, dynamic>> uploadImage({
    required Uint8List imageBytes,
    required String folder,
    String fileName = 'image.jpg',
    String mimeType = 'image/jpeg',
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/upload/image').replace(
        queryParameters: {'folder': folder, 'fileName': fileName},
      );
      final headers = await _buildHeaders();
      headers['Content-Type'] = mimeType; // 关键：不能是 application/json

      print('【图片上传】folder: $folder');
      print('【图片上传】图片大小: ${imageBytes.length ~/ 1024} KB');

      final response = await http
          .post(uri, headers: headers, body: imageBytes) // Uint8List → 原始字节
          .timeout(const Duration(seconds: 60));

      print('【图片上传】状态码: ${response.statusCode}');
      return _handleResponse(response);
    } catch (e) {
      print('【图片上传异常】$e');
      rethrow;
    }
  }

  // ============ 构建请求头 ============
  static Future<Map<String, String>> _buildHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    print('【Token】$token');
    final headers = {
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ============ 处理响应 ============
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