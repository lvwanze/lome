import 'package:flutter/material.dart';

/// 日历数据模型

/// 月历概览响应
class MonthlyCalendarResponse {
  final String month;
  final int recordedDays;
  final List<CalendarDayData> days;

  MonthlyCalendarResponse({
    required this.month,
    required this.recordedDays,
    required this.days,
  });

  factory MonthlyCalendarResponse.fromJson(Map<String, dynamic> json) {
    return MonthlyCalendarResponse(
      month: json['month'] ?? '',
      recordedDays: json['recordedDays'] ?? 0,
      days: (json['days'] as List? ?? [])
          .map((e) => CalendarDayData.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'recordedDays': recordedDays,
      'days': days.map((e) => e.toJson()).toList(),
    };
  }
}

/// 单日日历数据
class CalendarDayData {
  final String date;
  final bool hasRecord;
  final bool hasPlan;
  final bool hasImportantDay;
  final int planPendingCount;
  final String? importantDayName;
  final String? importantDayId;

  CalendarDayData({
    required this.date,
    required this.hasRecord,
    required this.hasPlan,
    required this.hasImportantDay,
    required this.planPendingCount,
    this.importantDayName,
    this.importantDayId,
  });

  factory CalendarDayData.fromJson(Map<String, dynamic> json) {
    // 打印原始数据以便调试
    print('【CalendarDayData解析】原始JSON: $json');

    return CalendarDayData(
      date: json['date'] ?? '',
      hasRecord: json['hasRecord'] ?? false,
      hasPlan: json['hasPlan'] ?? false,
      hasImportantDay: json['hasImportantDay'] ?? false,
      planPendingCount: json['planPendingCount'] ?? 0,
      importantDayName: json['importantDayName'] ?? json['importantDayName'] ?? '',
      // 尝试从多个可能的字段获取ID
      importantDayId: json['importantDayId'] ??
                      json['important_day_id'] ??
                      json['id'] ??
                      json['importantDayId'].toString() ??
                      (json['importantDay'] is Map ? json['importantDay']['importantDayId'] : null) ??
                      (json['importantDay'] is Map ? json['importantDay']['id'] : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'hasRecord': hasRecord,
      'hasPlan': hasPlan,
      'hasImportantDay': hasImportantDay,
      'planPendingCount': planPendingCount,
      'importantDayName': importantDayName,
      'importantDayId': importantDayId,
    };
  }

  /// 便捷方法：是否有任何内容
  bool get hasAnyContent => hasRecord || hasPlan || hasImportantDay;

  /// 便捷方法：获取重要日显示名称
  String get displayImportantDayName => importantDayName ?? '重要日';
}

/// 日详情响应
class DailyDetailResponse {
  final String date;
  final List<RecordData> records;
  final List<PlanData> plans;
  final int planPendingCount;
  final ImportantDayData? importantDay;

  DailyDetailResponse({
    required this.date,
    required this.records,
    required this.plans,
    required this.planPendingCount,
    this.importantDay,
  });

  factory DailyDetailResponse.fromJson(Map<String, dynamic> json) {
    print('【DailyDetailResponse解析】原始JSON: $json');

    return DailyDetailResponse(
      date: json['date'] ?? '',
      records: (json['records'] as List? ?? [])
          .map((e) => RecordData.fromJson(e))
          .toList(),
      plans: (json['plans'] as List? ?? [])
          .map((e) => PlanData.fromJson(e))
          .toList(),
      planPendingCount: json['planPendingCount'] ?? 0,
      importantDay: json['importantDay'] != null
          ? ImportantDayData.fromJson(json['importantDay'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'records': records.map((e) => e.toJson()).toList(),
      'plans': plans.map((e) => e.toJson()).toList(),
      'planPendingCount': planPendingCount,
      'importantDay': importantDay?.toJson(),
    };
  }

  /// 便捷方法：是否有记录
  bool get hasRecords => records.isNotEmpty;

  /// 便捷方法：是否有规划
  bool get hasPlans => plans.isNotEmpty;

  /// 便捷方法：是否有重要日
  bool get hasImportantDay => importantDay != null;
}

/// 记录数据
class RecordData {
  final String recordId;
  final String content;
  final List<String> images;
  final String mood;
  final String authorId;
  final String authorNickname;
  final int createTime;

  RecordData({
    required this.recordId,
    required this.content,
    required this.images,
    required this.mood,
    required this.authorId,
    required this.authorNickname,
    required this.createTime,
  });

  factory RecordData.fromJson(Map<String, dynamic> json) {
    return RecordData(
      recordId: json['recordId'] ?? '',
      content: json['content'] ?? '',
      images: (json['images'] as List? ?? []).map((e) => e.toString()).toList(),
      mood: json['mood'] ?? 'happy',
      authorId: json['authorId'] ?? '',
      authorNickname: json['authorNickname'] ?? '',
      createTime: json['createTime'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recordId': recordId,
      'content': content,
      'images': images,
      'mood': mood,
      'authorId': authorId,
      'authorNickname': authorNickname,
      'createTime': createTime,
    };
  }

  /// 便捷方法：获取创建时间
  DateTime get createDateTime => DateTime.fromMillisecondsSinceEpoch(createTime);

  /// 便捷方法：是否有图片
  bool get hasImages => images.isNotEmpty;
}

/// 规划数据
class PlanData {
  final String planId;
  final String title;
  final bool completed;
  final String authorId;
  final String authorNickname;

  PlanData({
    required this.planId,
    required this.title,
    required this.completed,
    required this.authorId,
    required this.authorNickname,
  });

  factory PlanData.fromJson(Map<String, dynamic> json) {
    return PlanData(
      planId: json['planId'] ?? '',
      title: json['title'] ?? '',
      completed: json['completed'] ?? false,
      authorId: json['authorId'] ?? '',
      authorNickname: json['authorNickname'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'planId': planId,
      'title': title,
      'completed': completed,
      'authorId': authorId,
      'authorNickname': authorNickname,
    };
  }

  /// 便捷方法：获取完成状态文本
  String get statusText => completed ? '已完成' : '未完成';
}

/// 重要日数据
class ImportantDayData {
  final String importantDayId;
  final String name;
  final String date;
  final String repeatType;
  final String icon;
  final String createdBy;

  ImportantDayData({
    required this.importantDayId,
    required this.name,
    required this.date,
    required this.repeatType,
    required this.icon,
    required this.createdBy,
  });

  factory ImportantDayData.fromJson(Map<String, dynamic> json) {
    print('【ImportantDayData解析】原始JSON: $json');

    return ImportantDayData(
      importantDayId: json['importantDayId'] ??
                      json['important_day_id'] ??
                      json['id'] ??
                      '',
      name: json['name'] ?? '',
      date: json['date'] ?? '',
      repeatType: json['repeatType'] ?? 'once',
      icon: json['icon'] ?? 'star',
      createdBy: json['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'importantDayId': importantDayId,
      'name': name,
      'date': date,
      'repeatType': repeatType,
      'icon': icon,
      'createdBy': createdBy,
    };
  }

  /// 便捷方法：解析日期
  DateTime get dateTime {
    try {
      return DateTime.parse(date);
    } catch (e) {
      return DateTime.now();
    }
  }

  /// 便捷方法：获取重复类型文本
  String get repeatTypeText {
    switch (repeatType) {
      case 'yearly':
        return '每年';
      case 'monthly':
        return '每月';
      case 'weekly':
        return '每周';
      default:
        return '仅一次';
    }
  }

  /// 便捷方法：获取图标
  IconData get iconData {
    switch (icon) {
      case 'heart':
        return Icons.favorite;
      case 'cake':
        return Icons.cake;
      case 'flag':
        return Icons.flag;
      case 'gift':
        return Icons.card_giftcard;
      default:
        return Icons.star;
    }
  }
}