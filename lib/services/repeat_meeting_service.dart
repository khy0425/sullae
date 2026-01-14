import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// 반복 모임 서비스
/// - 정기 모임 생성
/// - 반복 패턴 관리
/// - 자동 모임 생성
class RepeatMeetingService {
  static final RepeatMeetingService _instance = RepeatMeetingService._internal();
  factory RepeatMeetingService() => _instance;
  RepeatMeetingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 반복 모임 템플릿 생성
  Future<String?> createRepeatTemplate({
    required String hostId,
    required String title,
    required String gameType,
    required int maxParticipants,
    required RepeatPattern pattern,
    required MeetingTime meetingTime,
    required int durationMinutes,
    String? locationName,
    double? latitude,
    double? longitude,
    String? description,
  }) async {
    try {
      final docRef = await _firestore.collection('repeat_templates').add({
        'hostId': hostId,
        'title': title,
        'gameType': gameType,
        'maxParticipants': maxParticipants,
        'pattern': pattern.toJson(),
        'meetingTimeHour': meetingTime.hour,
        'meetingTimeMinute': meetingTime.minute,
        'durationMinutes': durationMinutes,
        'locationName': locationName,
        'latitude': latitude,
        'longitude': longitude,
        'description': description,
        'isActive': true,
        'createdAt': Timestamp.now(),
        'nextMeetingDate': Timestamp.fromDate(_calculateNextMeetingDate(pattern, meetingTime)),
      });

      if (kDebugMode) print('Created repeat template: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      if (kDebugMode) print('Error creating repeat template: $e');
      return null;
    }
  }

  /// 다음 모임 날짜 계산
  DateTime _calculateNextMeetingDate(RepeatPattern pattern, MeetingTime time) {
    final now = DateTime.now();
    DateTime nextDate;

    switch (pattern.type) {
      case RepeatType.daily:
        nextDate = DateTime(now.year, now.month, now.day, time.hour, time.minute);
        if (nextDate.isBefore(now)) {
          nextDate = nextDate.add(const Duration(days: 1));
        }
        break;

      case RepeatType.weekly:
        // 이번 주 해당 요일 찾기
        final targetWeekday = pattern.weekdays?.first ?? now.weekday;
        int daysUntil = targetWeekday - now.weekday;
        if (daysUntil < 0) daysUntil += 7;

        nextDate = DateTime(now.year, now.month, now.day + daysUntil, time.hour, time.minute);
        if (nextDate.isBefore(now)) {
          nextDate = nextDate.add(const Duration(days: 7));
        }
        break;

      case RepeatType.biweekly:
        final targetWeekday = pattern.weekdays?.first ?? now.weekday;
        int daysUntil = targetWeekday - now.weekday;
        if (daysUntil < 0) daysUntil += 7;

        nextDate = DateTime(now.year, now.month, now.day + daysUntil, time.hour, time.minute);
        if (nextDate.isBefore(now)) {
          nextDate = nextDate.add(const Duration(days: 14));
        }
        break;

      case RepeatType.monthly:
        final targetDay = pattern.monthDay ?? now.day;
        nextDate = DateTime(now.year, now.month, targetDay, time.hour, time.minute);
        if (nextDate.isBefore(now)) {
          nextDate = DateTime(now.year, now.month + 1, targetDay, time.hour, time.minute);
        }
        break;
    }

    return nextDate;
  }

  /// 사용자의 반복 모임 템플릿 목록 조회
  Future<List<RepeatTemplate>> getMyTemplates(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('repeat_templates')
          .where('hostId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => RepeatTemplate.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error getting templates: $e');
      return [];
    }
  }

  /// 반복 모임 템플릿 비활성화
  Future<bool> deactivateTemplate(String templateId) async {
    try {
      await _firestore.collection('repeat_templates').doc(templateId).update({
        'isActive': false,
        'deactivatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      if (kDebugMode) print('Error deactivating template: $e');
      return false;
    }
  }

  /// 템플릿에서 모임 생성 (수동)
  Future<String?> createMeetingFromTemplate(String templateId) async {
    try {
      final templateDoc = await _firestore
          .collection('repeat_templates')
          .doc(templateId)
          .get();

      if (!templateDoc.exists) return null;

      final data = templateDoc.data()!;
      final pattern = RepeatPattern.fromJson(data['pattern']);
      final meetingTime = MeetingTime(
        hour: data['meetingTimeHour'],
        minute: data['meetingTimeMinute'],
      );

      final nextDate = _calculateNextMeetingDate(pattern, meetingTime);

      // 모임 생성
      final meetingRef = await _firestore.collection('meetings').add({
        'hostId': data['hostId'],
        'title': data['title'],
        'gameType': data['gameType'],
        'maxParticipants': data['maxParticipants'],
        'meetingTime': Timestamp.fromDate(nextDate),
        'durationMinutes': data['durationMinutes'],
        'locationName': data['locationName'],
        'latitude': data['latitude'],
        'longitude': data['longitude'],
        'description': data['description'],
        'status': 'waiting',
        'participantIds': [data['hostId']],
        'repeatTemplateId': templateId,
        'createdAt': Timestamp.now(),
      });

      // 다음 모임 날짜 업데이트
      final nextNextDate = _calculateNextMeetingAfter(pattern, meetingTime, nextDate);
      await _firestore.collection('repeat_templates').doc(templateId).update({
        'nextMeetingDate': Timestamp.fromDate(nextNextDate),
        'lastCreatedMeetingId': meetingRef.id,
      });

      return meetingRef.id;
    } catch (e) {
      if (kDebugMode) print('Error creating meeting from template: $e');
      return null;
    }
  }

  /// 특정 날짜 이후의 다음 모임 날짜 계산
  DateTime _calculateNextMeetingAfter(RepeatPattern pattern, MeetingTime time, DateTime afterDate) {
    DateTime nextDate;
    final baseDate = afterDate.add(const Duration(days: 1));

    switch (pattern.type) {
      case RepeatType.daily:
        nextDate = DateTime(baseDate.year, baseDate.month, baseDate.day, time.hour, time.minute);
        break;

      case RepeatType.weekly:
        nextDate = afterDate.add(const Duration(days: 7));
        break;

      case RepeatType.biweekly:
        nextDate = afterDate.add(const Duration(days: 14));
        break;

      case RepeatType.monthly:
        nextDate = DateTime(afterDate.year, afterDate.month + 1, afterDate.day, time.hour, time.minute);
        break;
    }

    return nextDate;
  }

  /// 다가오는 반복 모임 목록
  Future<List<UpcomingRepeatMeeting>> getUpcomingRepeatMeetings({
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('repeat_templates')
          .where('isActive', isEqualTo: true)
          .orderBy('nextMeetingDate')
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return UpcomingRepeatMeeting(
          templateId: doc.id,
          title: data['title'] ?? '',
          gameType: data['gameType'] ?? '',
          nextMeetingDate: (data['nextMeetingDate'] as Timestamp).toDate(),
          hostId: data['hostId'] ?? '',
          locationName: data['locationName'],
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) print('Error getting upcoming repeat meetings: $e');
      return [];
    }
  }

  /// 모임 복제 (이전 모임 설정 그대로)
  Future<String?> duplicateMeeting(String meetingId) async {
    try {
      final meetingDoc = await _firestore.collection('meetings').doc(meetingId).get();
      if (!meetingDoc.exists) return null;

      final data = meetingDoc.data()!;

      // 새 모임 시간 (7일 후 같은 시간)
      final originalTime = (data['meetingTime'] as Timestamp).toDate();
      final newTime = originalTime.add(const Duration(days: 7));

      final newMeetingRef = await _firestore.collection('meetings').add({
        'hostId': data['hostId'],
        'title': data['title'],
        'gameType': data['gameType'],
        'maxParticipants': data['maxParticipants'],
        'meetingTime': Timestamp.fromDate(newTime),
        'durationMinutes': data['durationMinutes'],
        'locationName': data['locationName'],
        'latitude': data['latitude'],
        'longitude': data['longitude'],
        'description': data['description'],
        'status': 'waiting',
        'participantIds': [data['hostId']],
        'duplicatedFrom': meetingId,
        'createdAt': Timestamp.now(),
      });

      if (kDebugMode) print('Duplicated meeting: ${newMeetingRef.id}');
      return newMeetingRef.id;
    } catch (e) {
      if (kDebugMode) print('Error duplicating meeting: $e');
      return null;
    }
  }
}

/// 모임 시간 (hour, minute 저장용)
class MeetingTime {
  final int hour;
  final int minute;

  const MeetingTime({required this.hour, required this.minute});

  /// Flutter TimeOfDay로 변환
  String get formatted => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

/// 반복 패턴
class RepeatPattern {
  final RepeatType type;
  final List<int>? weekdays; // 1-7 (월-일)
  final int? monthDay; // 1-31

  RepeatPattern({
    required this.type,
    this.weekdays,
    this.monthDay,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'weekdays': weekdays,
    'monthDay': monthDay,
  };

  factory RepeatPattern.fromJson(Map<String, dynamic> json) {
    return RepeatPattern(
      type: RepeatType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => RepeatType.weekly,
      ),
      weekdays: json['weekdays'] != null
          ? List<int>.from(json['weekdays'])
          : null,
      monthDay: json['monthDay'],
    );
  }

  String get displayName {
    switch (type) {
      case RepeatType.daily:
        return '매일';
      case RepeatType.weekly:
        if (weekdays != null && weekdays!.isNotEmpty) {
          return '매주 ${_weekdayNames(weekdays!)}';
        }
        return '매주';
      case RepeatType.biweekly:
        return '격주';
      case RepeatType.monthly:
        if (monthDay != null) {
          return '매월 $monthDay일';
        }
        return '매월';
    }
  }

  String _weekdayNames(List<int> days) {
    const names = ['', '월', '화', '수', '목', '금', '토', '일'];
    return days.map((d) => names[d]).join(', ');
  }
}

/// 반복 유형
enum RepeatType {
  daily,      // 매일
  weekly,     // 매주
  biweekly,   // 격주
  monthly,    // 매월
}

/// 반복 모임 템플릿
class RepeatTemplate {
  final String id;
  final String hostId;
  final String title;
  final String gameType;
  final int maxParticipants;
  final RepeatPattern pattern;
  final MeetingTime meetingTime;
  final int durationMinutes;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final String? description;
  final DateTime nextMeetingDate;
  final bool isActive;

  RepeatTemplate({
    required this.id,
    required this.hostId,
    required this.title,
    required this.gameType,
    required this.maxParticipants,
    required this.pattern,
    required this.meetingTime,
    required this.durationMinutes,
    this.locationName,
    this.latitude,
    this.longitude,
    this.description,
    required this.nextMeetingDate,
    required this.isActive,
  });

  factory RepeatTemplate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RepeatTemplate(
      id: doc.id,
      hostId: data['hostId'] ?? '',
      title: data['title'] ?? '',
      gameType: data['gameType'] ?? '',
      maxParticipants: data['maxParticipants'] ?? 10,
      pattern: RepeatPattern.fromJson(data['pattern'] ?? {'type': 'weekly'}),
      meetingTime: MeetingTime(
        hour: data['meetingTimeHour'] ?? 14,
        minute: data['meetingTimeMinute'] ?? 0,
      ),
      durationMinutes: data['durationMinutes'] ?? 60,
      locationName: data['locationName'],
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      description: data['description'],
      nextMeetingDate: (data['nextMeetingDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }
}

/// 다가오는 반복 모임
class UpcomingRepeatMeeting {
  final String templateId;
  final String title;
  final String gameType;
  final DateTime nextMeetingDate;
  final String hostId;
  final String? locationName;

  UpcomingRepeatMeeting({
    required this.templateId,
    required this.title,
    required this.gameType,
    required this.nextMeetingDate,
    required this.hostId,
    this.locationName,
  });
}
