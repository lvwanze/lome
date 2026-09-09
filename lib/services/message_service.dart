import 'package:lome/services/api_service.dart';

class MessageService {
  static const String _basePath = '/api/v1/messages';

  /// 获取留言列表
  static Future<Map<String, dynamic>> getList({
    required String type,
    int pageSize = 20,
    int? cursor,
  }) async {
    final query = {
      'type': type,
      'pageSize': pageSize.toString(),
    };
    if (cursor != null) {
      query['cursor'] = cursor.toString();
    }
    return await ApiService.get(
      '$_basePath/list',
      query: query,
    );
  }

  /// 获取留言详情
  static Future<Map<String, dynamic>> getDetail(String messageId) async {
    return await ApiService.get(
      '$_basePath/detail',
      query: {'messageId': messageId},
    );
  }

  /// 批量已读
  static Future<Map<String, dynamic>> markAllRead() async {
    return await ApiService.put('$_basePath/read');
  }

  /// 删除留言
  static Future<Map<String, dynamic>> delete(String messageId) async {
    return await ApiService.post(
      '$_basePath/delete',
      body: {'messageId': messageId},
    );
  }

  /// 回应留言
  static Future<Map<String, dynamic>> reply({
    required String messageId,
    required String content,
  }) async {
    return await ApiService.post(
      '$_basePath/reply',
      body: {
        'messageId': messageId,
        'content': content,
      },
    );
  }

  /// 发布留言
  static Future<Map<String, dynamic>> create({
    required String content,
    List<String>? images,
    String? emotionTag,
  }) async {
    return await ApiService.post(
      '$_basePath/create',
      body: {
        'content': content,
        'images': images ?? [],
        'emotionTag': emotionTag,
      },
    );
  }

  /// 编辑留言  ← 新增
  static Future<Map<String, dynamic>> update({
    required String messageId,
    required String content,
    List<String>? images,
    String? emotionTag,
  }) async {
    return await ApiService.post(
      '$_basePath/update',
      body: {
        'messageId': messageId,
        'content': content,
        'images': images ?? [],
        'emotionTag': emotionTag,
      },
    );
  }
}