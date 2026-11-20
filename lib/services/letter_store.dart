import 'slow_letter_api.dart';

enum LetterStage { inTransit, delivered, opened }

class Letter {
  const Letter({
    required this.id,
    required this.code,
    required this.title,
    required this.content,
    this.recipientLabel = '',
    this.images = const <String>[],
    required this.sentAt,
    required this.deliverAt,
    this.openedAt,
    this.fromMe = true,
    this.serverStage,
  });

  final String id;
  final String code;
  final String title;
  final String content;
  final String recipientLabel;
  final List<String> images;
  final DateTime sentAt;
  final DateTime deliverAt;
  final DateTime? openedAt;
  final bool fromMe;
  final LetterStage? serverStage;

  LetterStage get stage {
    if (serverStage == LetterStage.inTransit) return LetterStage.inTransit;
    if (openedAt != null) return LetterStage.opened;
    if (serverStage == LetterStage.delivered) return LetterStage.delivered;
    if (DateTime.now().isBefore(deliverAt)) return LetterStage.inTransit;
    return LetterStage.delivered;
  }

  Duration get remaining {
    final diff = deliverAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  Letter copyWith({
    String? id,
    String? code,
    String? title,
    String? content,
    String? recipientLabel,
    List<String>? images,
    DateTime? sentAt,
    DateTime? deliverAt,
    DateTime? openedAt,
    bool? fromMe,
  }) {
    return Letter(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      content: content ?? this.content,
      recipientLabel: recipientLabel ?? this.recipientLabel,
      images: images ?? this.images,
      sentAt: sentAt ?? this.sentAt,
      deliverAt: deliverAt ?? this.deliverAt,
      openedAt: openedAt ?? this.openedAt,
      fromMe: fromMe ?? this.fromMe,
      serverStage: serverStage,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'code': code,
      'title': title,
      'content': content,
      'recipientLabel': recipientLabel,
      'images': images,
      'sentAt': sentAt.millisecondsSinceEpoch,
      'deliverAt': deliverAt.millisecondsSinceEpoch,
      'openedAt': openedAt?.millisecondsSinceEpoch,
      'fromMe': fromMe,
    };
  }

  factory Letter.fromJson(Map<String, dynamic> json) {
    return Letter(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      recipientLabel: json['recipientLabel'] as String? ?? '',
      images:
          (json['images'] as List?)?.map((e) => e.toString()).toList() ??
          const <String>[],
      sentAt: DateTime.fromMillisecondsSinceEpoch(
        (json['sentAt'] as num?)?.toInt() ?? 0,
      ),
      deliverAt: DateTime.fromMillisecondsSinceEpoch(
        (json['deliverAt'] as num?)?.toInt() ?? 0,
      ),
      openedAt:
          (json['openedAt'] as num?) == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(
                (json['openedAt'] as num).toInt(),
              ),
      fromMe: json['fromMe'] as bool? ?? true,
    );
  }

  factory Letter.fromApiJson(Map<String, dynamic> json) {
    final openedAt = json['openedAt'];
    return Letter(
      id: json['letterId']?.toString() ?? '',
      code: json['letterNo']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: '',
      recipientLabel: json['recipientLabel']?.toString() ?? '',
      sentAt: DateTime.fromMillisecondsSinceEpoch(
        (json['createTime'] as num?)?.toInt() ?? 0,
      ),
      deliverAt: DateTime.fromMillisecondsSinceEpoch(
        (json['arriveTime'] as num?)?.toInt() ?? 0,
      ),
      openedAt:
          openedAt is num
              ? DateTime.fromMillisecondsSinceEpoch(openedAt.toInt())
              : null,
      fromMe: json['direction'] == 'sent',
      serverStage:
          json['stage'] == 'in_transit'
              ? LetterStage.inTransit
              : LetterStage.delivered,
    );
  }
}

class LetterStore {
  LetterStore._();

  static Future<List<Letter>> load() async {
    final results = await Future.wait([
      SlowLetterApi.instance.list(box: 'sent'),
      SlowLetterApi.instance.list(box: 'received'),
    ]);
    final letters =
        results.expand((items) => items).map(Letter.fromApiJson).toList()
          ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
    return letters;
  }

  static List<Letter> inTransitOf(
    List<Letter> letters, {
    required bool fromMe,
  }) {
    return letters
        .where((e) => e.fromMe == fromMe && e.stage == LetterStage.inTransit)
        .toList();
  }

  static List<Letter> historyOf(List<Letter> letters, {required bool fromMe}) {
    return letters
        .where((e) => e.fromMe == fromMe && e.stage != LetterStage.inTransit)
        .toList();
  }

  static Letter? latestReceived(List<Letter> letters) {
    final delivered =
        letters
            .where((e) => !e.fromMe && e.stage != LetterStage.inTransit)
            .toList()
          ..sort((a, b) => b.deliverAt.compareTo(a.deliverAt));
    return delivered.isEmpty ? null : delivered.first;
  }
}
