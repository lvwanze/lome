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

  // ============ 图片上传 ============
  static Future<Map<String, dynamic>> uploadImage({
    required Uint8List imageBytes,
    required String folder,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/upload/image');
      final headers = await _buildHeaders();

      print('【图片上传】URL: $uri');
      print('【图片上传】Folder: $folder');

      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(headers);
      request.fields['folder'] = folder;
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: '${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

      final response = await request.send().timeout(const Duration(seconds: 30));
      final responseBody = await response.stream.bytesToString();

      print('【图片上传】状态码: ${response.statusCode}');
      print('【图片上传】响应: $responseBody');

      return jsonDecode(responseBody);
    } catch (e) {
      print('【图片上传异常】$e');
      rethrow;
    }
  }

  // ============ 构建请求头 ============
  static Future<Map<String, String>> _buildHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);  // 用常量，值为 'lome_token'
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