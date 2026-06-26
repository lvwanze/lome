/// 统一API响应模型
/// 所有接口返回格式：{ code, message, data }
class ApiResponse<T> {
  final int code; // 0 表示成功，非0表示失败
  final String message;
  final T? data;

  ApiResponse({
    required this.code,
    required this.message,
    this.data,
  });

  /// 从JSON创建响应对象
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    return ApiResponse<T>(
      code: json['code'] ?? -1,
      message: json['message'] ?? '未知错误',
      data: json['data'] != null ? fromJsonT(json['data']) : null,
    );
  }

  /// 判断是否成功（code == 0）
  bool get isSuccess => code == 0;
}
