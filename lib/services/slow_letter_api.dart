import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_constants.dart';

class SlowLetterApiException implements Exception {
  const SlowLetterApiException(this.message, {this.code});

  final String message;
  final int? code;

  @override
  String toString() => message;
}

class SlowLetterApi {
  SlowLetterApi({http.Client? client}) : _client = client ?? http.Client();

  static final SlowLetterApi instance = SlowLetterApi();
  final http.Client _client;

  Future<String> _token() async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString(AppConstants.tokenKey);
    if (token == null || token.isEmpty) {
      throw const SlowLetterApiException('登录状态已失效，请重新登录');
    }
    return token;
  }

  Future<Map<String, dynamic>> _jsonRequest(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final token = await _token();
    final baseUri = Uri.parse('${AppConstants.baseUrl}$path');
    final uri =
        query == null ? baseUri : baseUri.replace(queryParameters: query);
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json; charset=utf-8',
    };

    try {
      final response =
          method == 'GET'
              ? await _client.get(uri, headers: headers)
              : await _client.post(
                uri,
                headers: headers,
                body: jsonEncode(body),
              );
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const SlowLetterApiException('服务器返回格式无效');
      }
      final code = decoded['code'];
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          code != 0) {
        throw SlowLetterApiException(
          decoded['message']?.toString() ?? '慢信请求失败',
          code: code is int ? code : null,
        );
      }
      final data = decoded['data'];
      if (data is! Map<String, dynamic>) {
        throw const SlowLetterApiException('服务器未返回有效数据');
      }
      return data;
    } on SlowLetterApiException {
      rethrow;
    } on FormatException {
      throw const SlowLetterApiException('服务器返回内容无法解析');
    } catch (_) {
      throw const SlowLetterApiException('网络连接失败，请稍后重试');
    }
  }

  Future<Map<String, dynamic>> overview() =>
      _jsonRequest('GET', '/api/v1/letters/overview');

  Future<List<Map<String, dynamic>>> list({
    required String box,
    String stage = 'all',
    int limit = 50,
  }) async {
    final results = <Map<String, dynamic>>[];
    String? cursor;
    do {
      final data = await _jsonRequest(
        'GET',
        '/api/v1/letters/list',
        query: {
          'box': box,
          'stage': stage,
          'limit': '$limit',
          if (cursor != null) 'cursor': cursor,
        },
      );
      final items = data['items'];
      if (items is! List) {
        throw const SlowLetterApiException('信件列表格式无效');
      }
      results.addAll(items.whereType<Map<String, dynamic>>());
      final nextCursor = data['nextCursor']?.toString();
      if (data['hasMore'] == true &&
          nextCursor != null &&
          nextCursor.isNotEmpty &&
          nextCursor != cursor) {
        cursor = nextCursor;
      } else {
        cursor = null;
      }
    } while (cursor != null);
    return results;
  }

  Future<Map<String, dynamic>> send(Map<String, dynamic> body) =>
      _jsonRequest('POST', '/api/v1/letters/send', body: body);

  Future<Map<String, dynamic>> content(String letterId) => _jsonRequest(
    'POST',
    '/api/v1/letters/content',
    body: {'letterId': letterId},
  );

  Future<Map<String, dynamic>> acknowledgeRead({
    required String letterId,
    required String viewToken,
  }) => _jsonRequest(
    'POST',
    '/api/v1/letters/read',
    body: {'letterId': letterId, 'viewToken': viewToken},
  );

  Future<String> uploadAttachment({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final token = await _token();
    final uri = Uri.parse(
      '${AppConstants.baseUrl}/api/v1/letters/attachment/upload',
    );
    try {
      final response = await _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': mimeType,
        },
        body: bytes,
      );
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> ||
          response.statusCode < 200 ||
          response.statusCode >= 300 ||
          decoded['code'] != 0) {
        throw SlowLetterApiException(
          decoded is Map
              ? decoded['message']?.toString() ?? '图片上传失败'
              : '图片上传失败',
          code:
              decoded is Map && decoded['code'] is int
                  ? decoded['code'] as int
                  : null,
        );
      }
      final data = decoded['data'];
      final attachmentId =
          data is Map ? data['attachmentId']?.toString() : null;
      if (attachmentId == null || attachmentId.isEmpty) {
        throw const SlowLetterApiException('服务器未返回附件编号');
      }
      return attachmentId;
    } on SlowLetterApiException {
      rethrow;
    } on FormatException {
      throw const SlowLetterApiException('服务器返回内容无法解析');
    } catch (_) {
      throw const SlowLetterApiException('图片上传失败，请检查网络后重试');
    }
  }

  Future<Uint8List> attachment({
    required String letterId,
    required String attachmentId,
  }) async {
    final token = await _token();
    final uri = Uri.parse(
      '${AppConstants.baseUrl}/api/v1/letters/attachment/content',
    ).replace(
      queryParameters: {'letterId': letterId, 'attachmentId': attachmentId},
    );
    try {
      final response = await _client.get(
        uri,
        headers: {'Authorization': 'Bearer $token', 'Accept': 'image/*'},
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const SlowLetterApiException('图片暂时无法获取');
      }
      if (!(response.headers['content-type'] ?? '').startsWith('image/')) {
        throw const SlowLetterApiException('服务器返回的附件格式无效');
      }
      return response.bodyBytes;
    } on SlowLetterApiException {
      rethrow;
    } catch (_) {
      throw const SlowLetterApiException('图片暂时无法获取');
    }
  }
}
