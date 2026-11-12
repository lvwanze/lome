import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum LetterStage { inTransit, delivered, opened }

class Letter {
  const Letter({
    required this.id,
    required this.code,
    required this.title,
    required this.content,
    this.images = const <String>[],
    required this.sentAt,
    required this.deliverAt,
    this.openedAt,
    this.fromMe = true,
  });

  final String id;
  final String code;
  final String title;
  final String content;
  final List<String> images;
  final DateTime sentAt;
  final DateTime deliverAt;
  final DateTime? openedAt;
  final bool fromMe;

  LetterStage get stage {
    if (openedAt != null) return LetterStage.opened;
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
      images: images ?? this.images,
      sentAt: sentAt ?? this.sentAt,
      deliverAt: deliverAt ?? this.deliverAt,
      openedAt: openedAt ?? this.openedAt,
      fromMe: fromMe ?? this.fromMe,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'code': code,
      'title': title,
      'content': content,
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
      images:
          (json['images'] as List?)?.map((e) => e.toString()).toList() ??
              const <String>[],
      sentAt: DateTime.fromMillisecondsSinceEpoch(
        (json['sentAt'] as num?)?.toInt() ?? 0,
      ),
      deliverAt: DateTime.fromMillisecondsSinceEpoch(
        (json['deliverAt'] as num?)?.toInt() ?? 0,
      ),
      openedAt: (json['openedAt'] as num?) == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              (json['openedAt'] as num).toInt(),
            ),
      fromMe: json['fromMe'] as bool? ?? true,
    );
  }
}

class LetterStore {
  LetterStore._();

  static const String _storageKey = 'lome_letters_v2';

  static Future<List<Letter>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        return decoded
            .map((e) => Letter.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
    final seeded = _seed();
    await save(seeded);
    return seeded;
  }

  static Future<void> save(List<Letter> letters) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(letters.map((e) => e.toJson()).toList()),
    );
  }

  static Future<List<Letter>> add(Letter letter) async {
    final letters = await load();
    final updated = <Letter>[letter, ...letters];
    await save(updated);
    return updated;
  }

  static Future<List<Letter>> markOpened(String id) async {
    final letters = await load();
    final updated = letters
        .map((e) => e.id == id ? e.copyWith(openedAt: DateTime.now()) : e)
        .toList();
    await save(updated);
    return updated;
  }

  static Future<List<Letter>> delete(String id) async {
    final letters = await load();
    final updated = letters.where((e) => e.id != id).toList();
    await save(updated);
    return updated;
  }

  static List<Letter> inTransitOf(List<Letter> letters, {required bool fromMe}) {
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
    final delivered = letters
        .where((e) => !e.fromMe && e.stage != LetterStage.inTransit)
        .toList()
      ..sort((a, b) => b.deliverAt.compareTo(a.deliverAt));
    if (delivered.isNotEmpty) return delivered.first;
    final incoming = letters.where((e) => !e.fromMe).toList()
      ..sort((a, b) => b.deliverAt.compareTo(a.deliverAt));
    return incoming.isEmpty ? null : incoming.first;
  }

  static List<Letter> _seed() {
    final now = DateTime.now();
    return <Letter>[
      Letter(
        id: 'letter-a1',
        code: 'A1',
        title: '寄往秋天的第一封信',
        content: '今天路过我们常去的那家小店，门口的桂花开了。'
            '忽然就想起你说过，秋天是最适合慢慢写信的季节。\n\n'
            '所以我把这些琐碎的、没什么分量的小事都写下来，'
            '等它慢慢走到你身边的时候，希望你也刚好在一个安静的午后。',
        sentAt: now.subtract(const Duration(days: 2, hours: 3)),
        deliverAt: now.add(const Duration(days: 1, hours: 5)),
      ),
      Letter(
        id: 'letter-a2',
        code: 'A2',
        title: '关于那场没看完的雨',
        content: '那天的雨下到一半就停了，我们都没舍得走。\n\n'
            '信封里夹了一片当时捡的叶子，现在已经脆了，但还是那天的颜色。',
        sentAt: now.subtract(const Duration(days: 12)),
        deliverAt: now.subtract(const Duration(hours: 6)),
      ),
      Letter(
        id: 'letter-a3',
        code: 'A3',
        title: '给很久以后的你',
        content: '写这封信的时候，我们才认识第三个月。\n\n'
            '不知道你读到这里的时候，我们是不是还像现在这样，会在睡前说一句晚安。',
        sentAt: now.subtract(const Duration(days: 45)),
        deliverAt: now.subtract(const Duration(days: 30)),
        openedAt: now.subtract(const Duration(days: 29)),
      ),
      Letter(
        id: 'letter-b1',
        code: 'B1',
        title: '你寄来的第一封信',
        content: '第一次试着写慢信，不知道什么时候你才会看到。\n\n'
            '先写一句：今天的天气很好，希望你也是。',
        sentAt: now.subtract(const Duration(days: 3, hours: 6)),
        deliverAt: now.add(const Duration(days: 2, hours: 8)),
        fromMe: false,
      ),
      Letter(
        id: 'letter-b2',
        code: 'B2',
        title: '写给你的第二封信',
        content: '上次的信你收到了吗？我又写了一封，'
            '总觉得有些话，要慢慢寄出去才说得清楚。',
        sentAt: now.subtract(const Duration(days: 9)),
        deliverAt: now.subtract(const Duration(days: 2)),
        fromMe: false,
      ),
    ];
  }
}