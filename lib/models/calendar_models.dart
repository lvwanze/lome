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
}

/// 单日日历数据
class CalendarDayData {
  final String date;
  final bool hasRecord;
  final bool hasPlan;
  final bool hasImportantDay;
  final int planPendingCount;
  final String? importantDayName;

  CalendarDayData({
    required this.date,
    required this.hasRecord,
    required this.hasPlan,
    required this.hasImportantDay,
    required this.planPendingCount,
    this.importantDayName,
  });

  factory CalendarDayData.fromJson(Map<String, dynamic> json) {
    return CalendarDayData(
      date: json['date'] ?? '',
      hasRecord: json['hasRecord'] ?? false,
      hasPlan: json['hasPlan'] ?? false,
      hasImportantDay: json['hasImportantDay'] ?? false,
      planPendingCount: json['planPendingCount'] ?? 0,
      importantDayName: json['importantDayName'],
    );
  }
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
    return ImportantDayData(
      importantDayId: json['importantDayId'] ?? '',
      name: json['name'] ?? '',
      date: json['date'] ?? '',
      repeatType: json['repeatType'] ?? 'once',
      icon: json['icon'] ?? 'star',
      createdBy: json['createdBy'] ?? '',
    );
  }
}