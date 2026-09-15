class Message {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String content;
  final List<String> images;
  final String? emotionTag;
  final bool isRead;
  final int createTime;
  final bool hasReply;
  final String? replyId;
  final String? replyContent;
  final String? replyAuthorId;
  final String? replyAuthorName;

  Message({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.content,
    this.images = const [],
    this.emotionTag,
    required this.isRead,
    required this.createTime,
    this.hasReply = false,
    this.replyId,
    this.replyContent,
    this.replyAuthorId,
    this.replyAuthorName,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? json['_id'] ?? '',
      authorId: json['authorId'] ?? '',
      authorName: json['authorName'] ?? '',
      authorAvatar: json['authorAvatar'],
      content: json['content'] ?? '',
      images: (json['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
      emotionTag: json['emotionTag'],
      isRead: json['isRead'] ?? false,
      createTime: json['createTime'] ?? 0,
      hasReply: json['hasReply'] ?? false,
      replyId: json['replyId'],
      replyContent: json['replyContent'],
      replyAuthorId: json['replyAuthorId'],
      replyAuthorName: json['replyAuthorName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      '_id': id,
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'content': content,
      'images': images,
      'emotionTag': emotionTag,
      'isRead': isRead,
      'createTime': createTime,
      'hasReply': hasReply,
      'replyId': replyId,
      'replyContent': replyContent,
      'replyAuthorId': replyAuthorId,
      'replyAuthorName': replyAuthorName,
    };
  }

  // ✅ 新增：copyWith 方法，用于局部更新
  Message copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? content,
    List<String>? images,
    String? emotionTag,
    bool? isRead,
    int? createTime,
    bool? hasReply,
    String? replyId,
    String? replyContent,
    String? replyAuthorId,
    String? replyAuthorName,
  }) {
    return Message(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      content: content ?? this.content,
      images: images ?? this.images,
      emotionTag: emotionTag ?? this.emotionTag,
      isRead: isRead ?? this.isRead,
      createTime: createTime ?? this.createTime,
      hasReply: hasReply ?? this.hasReply,
      replyId: replyId ?? this.replyId,
      replyContent: replyContent ?? this.replyContent,
      replyAuthorId: replyAuthorId ?? this.replyAuthorId,
      replyAuthorName: replyAuthorName ?? this.replyAuthorName,
    );
  }
}