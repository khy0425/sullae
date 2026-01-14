import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// 모임 기록 및 통계 서비스
class MeetingHistoryService {
  static final MeetingHistoryService _instance = MeetingHistoryService._internal();
  factory MeetingHistoryService() => _instance;
  MeetingHistoryService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 사용자의 모임 통계 조회
  Future<UserMeetingStats> getUserStats(String userId) async {
    try {
      // 호스트로 생성한 모임
      final hostedMeetings = await _firestore
          .collection('meetings')
          .where('hostId', isEqualTo: userId)
          .get();

      // 참여한 모임
      final participatedMeetings = await _firestore
          .collection('meetings')
          .where('participantIds', arrayContains: userId)
          .get();

      // 완료된 모임만 필터링
      final completedHosted = hostedMeetings.docs
          .where((doc) => doc.data()['status'] == 'completed')
          .length;

      final completedParticipated = participatedMeetings.docs
          .where((doc) => doc.data()['status'] == 'completed')
          .length;

      // 게임 유형별 통계
      final gameTypeCount = <String, int>{};
      for (final doc in participatedMeetings.docs) {
        final gameType = doc.data()['gameType'] as String? ?? 'unknown';
        gameTypeCount[gameType] = (gameTypeCount[gameType] ?? 0) + 1;
      }

      // 가장 많이 한 게임
      String? favoriteGame;
      int maxCount = 0;
      gameTypeCount.forEach((game, count) {
        if (count > maxCount) {
          maxCount = count;
          favoriteGame = game;
        }
      });

      // 연속 참여 기록 계산
      final streakDays = await _calculateStreak(userId);

      return UserMeetingStats(
        totalHosted: hostedMeetings.docs.length,
        totalParticipated: participatedMeetings.docs.length,
        completedHosted: completedHosted,
        completedParticipated: completedParticipated,
        gameTypeStats: gameTypeCount,
        favoriteGameType: favoriteGame,
        currentStreakDays: streakDays,
      );
    } catch (e) {
      if (kDebugMode) print('Error getting user stats: $e');
      return UserMeetingStats.empty();
    }
  }

  /// 연속 참여 일수 계산
  Future<int> _calculateStreak(String userId) async {
    try {
      final meetings = await _firestore
          .collection('meetings')
          .where('participantIds', arrayContains: userId)
          .where('status', isEqualTo: 'completed')
          .orderBy('meetingTime', descending: true)
          .limit(30)
          .get();

      if (meetings.docs.isEmpty) return 0;

      int streak = 0;
      DateTime? lastDate;

      for (final doc in meetings.docs) {
        final meetingTime = (doc.data()['meetingTime'] as Timestamp).toDate();
        final meetingDate = DateTime(meetingTime.year, meetingTime.month, meetingTime.day);

        if (lastDate == null) {
          // 오늘 또는 어제 모임이 있어야 streak 시작
          final today = DateTime.now();
          final todayDate = DateTime(today.year, today.month, today.day);
          final diff = todayDate.difference(meetingDate).inDays;

          if (diff <= 1) {
            streak = 1;
            lastDate = meetingDate;
          } else {
            break;
          }
        } else {
          final diff = lastDate.difference(meetingDate).inDays;
          if (diff == 1) {
            streak++;
            lastDate = meetingDate;
          } else if (diff == 0) {
            // 같은 날 여러 모임
            continue;
          } else {
            break;
          }
        }
      }

      return streak;
    } catch (e) {
      return 0;
    }
  }

  /// 최근 모임 기록 조회
  Future<List<MeetingHistoryItem>> getRecentMeetings({
    required String userId,
    int limit = 20,
  }) async {
    try {
      final meetings = await _firestore
          .collection('meetings')
          .where('participantIds', arrayContains: userId)
          .orderBy('meetingTime', descending: true)
          .limit(limit)
          .get();

      return meetings.docs
          .map((doc) => MeetingHistoryItem.fromFirestore(doc, userId))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error getting recent meetings: $e');
      return [];
    }
  }

  /// 월별 모임 통계
  Future<Map<String, int>> getMonthlyStats({
    required String userId,
    int months = 6,
  }) async {
    try {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month - months + 1, 1);

      final meetings = await _firestore
          .collection('meetings')
          .where('participantIds', arrayContains: userId)
          .where('meetingTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .get();

      final monthlyStats = <String, int>{};

      for (final doc in meetings.docs) {
        final meetingTime = (doc.data()['meetingTime'] as Timestamp).toDate();
        final key = '${meetingTime.year}-${meetingTime.month.toString().padLeft(2, '0')}';
        monthlyStats[key] = (monthlyStats[key] ?? 0) + 1;
      }

      return monthlyStats;
    } catch (e) {
      if (kDebugMode) print('Error getting monthly stats: $e');
      return {};
    }
  }

  /// 함께한 친구 통계
  Future<List<FrequentFriend>> getFrequentFriends({
    required String userId,
    int limit = 10,
  }) async {
    try {
      final meetings = await _firestore
          .collection('meetings')
          .where('participantIds', arrayContains: userId)
          .where('status', isEqualTo: 'completed')
          .get();

      final friendCount = <String, int>{};

      for (final doc in meetings.docs) {
        final participants = List<String>.from(doc.data()['participantIds'] ?? []);
        for (final participantId in participants) {
          if (participantId != userId) {
            friendCount[participantId] = (friendCount[participantId] ?? 0) + 1;
          }
        }
      }

      // 정렬 및 상위 N명
      final sortedFriends = friendCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final topFriends = sortedFriends.take(limit).toList();

      // 사용자 정보 조회
      final result = <FrequentFriend>[];
      for (final entry in topFriends) {
        final userDoc = await _firestore.collection('users').doc(entry.key).get();
        final userData = userDoc.data();
        result.add(FrequentFriend(
          userId: entry.key,
          displayName: userData?['displayName'] ?? '알 수 없음',
          photoUrl: userData?['photoUrl'],
          meetingCount: entry.value,
        ));
      }

      return result;
    } catch (e) {
      if (kDebugMode) print('Error getting frequent friends: $e');
      return [];
    }
  }

  /// 모임 완료 기록 저장
  Future<void> recordMeetingCompletion({
    required String meetingId,
    required String odId,
    required MeetingRole role,
    int? gameScore,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(odId)
          .collection('meeting_history')
          .doc(meetingId)
          .set({
        'meetingId': meetingId,
        'role': role.name,
        'gameScore': gameScore,
        'completedAt': Timestamp.now(),
      });
    } catch (e) {
      if (kDebugMode) print('Error recording meeting completion: $e');
    }
  }
}

/// 사용자 모임 통계
class UserMeetingStats {
  final int totalHosted;
  final int totalParticipated;
  final int completedHosted;
  final int completedParticipated;
  final Map<String, int> gameTypeStats;
  final String? favoriteGameType;
  final int currentStreakDays;

  UserMeetingStats({
    required this.totalHosted,
    required this.totalParticipated,
    required this.completedHosted,
    required this.completedParticipated,
    required this.gameTypeStats,
    this.favoriteGameType,
    required this.currentStreakDays,
  });

  factory UserMeetingStats.empty() => UserMeetingStats(
    totalHosted: 0,
    totalParticipated: 0,
    completedHosted: 0,
    completedParticipated: 0,
    gameTypeStats: {},
    currentStreakDays: 0,
  );

  int get totalMeetings => totalHosted + totalParticipated;
  int get completedMeetings => completedHosted + completedParticipated;

  double get completionRate {
    if (totalMeetings == 0) return 0;
    return completedMeetings / totalMeetings;
  }
}

/// 모임 기록 아이템
class MeetingHistoryItem {
  final String meetingId;
  final String title;
  final String gameType;
  final DateTime meetingTime;
  final String status;
  final bool wasHost;
  final int participantCount;
  final String? locationName;

  MeetingHistoryItem({
    required this.meetingId,
    required this.title,
    required this.gameType,
    required this.meetingTime,
    required this.status,
    required this.wasHost,
    required this.participantCount,
    this.locationName,
  });

  factory MeetingHistoryItem.fromFirestore(DocumentSnapshot doc, String userId) {
    final data = doc.data() as Map<String, dynamic>;
    return MeetingHistoryItem(
      meetingId: doc.id,
      title: data['title'] ?? '',
      gameType: data['gameType'] ?? 'unknown',
      meetingTime: (data['meetingTime'] as Timestamp).toDate(),
      status: data['status'] ?? 'unknown',
      wasHost: data['hostId'] == userId,
      participantCount: (data['participantIds'] as List?)?.length ?? 0,
      locationName: data['locationName'],
    );
  }

  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isUpcoming => meetingTime.isAfter(DateTime.now());
}

/// 자주 함께한 친구
class FrequentFriend {
  final String odId;
  final String displayName;
  final String? photoUrl;
  final int meetingCount;

  FrequentFriend({
    required String userId,
    required this.displayName,
    this.photoUrl,
    required this.meetingCount,
  }) : odId = userId;

  String get userId => odId;
}

/// 모임에서의 역할
enum MeetingRole {
  host,
  participant,
  winner,
  loser,
}
