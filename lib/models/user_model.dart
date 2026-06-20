/// 用户模型
class User {
  final String userId;
  final String phone;
  final String nickname;
  final bool isBound;
  final String? partnerId;
  final String? partnerNickname;

  User({
    required this.userId,
    required this.phone,
    required this.nickname,
    required this.isBound,
    this.partnerId,
    this.partnerNickname,
  });

  /// 从JSON创建User
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] ?? '',
      phone: json['phone'] ?? '',
      nickname: json['nickname'] ?? '用户',
      isBound: json['isBound'] ?? false,
      partnerId: json['partnerId'],
      partnerNickname: json['partnerNickname'],
    );
  }

  /// 转成JSON（用于本地存储）
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'phone': phone,
      'nickname': nickname,
      'isBound': isBound,
      'partnerId': partnerId,
      'partnerNickname': partnerNickname,
    };
  }
}
