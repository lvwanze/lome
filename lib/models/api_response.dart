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
    // 安全解析code：同时支持int类型 和 字符串类型的数字
    final rawCode = json['code'] ?? -1;
    final int parseCode;
    if(rawCode is int){
      parseCode = rawCode;
    }else{
      // 后端返回字符串，转成int；解析失败默认-1
      parseCode = int.tryParse(rawCode.toString()) ?? -1;
    }

    return ApiResponse<T>(
      code: parseCode,
      message: json['message'] ?? '未知错误',
      data: json['data'] != null ? fromJsonT(json['data']) : null,
    );
  }

  /// 判断是否成功（code == 0）
  bool get isSuccess => code == 0;
}
