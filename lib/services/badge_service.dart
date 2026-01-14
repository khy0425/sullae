import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/badge_model.dart';
import '../models/user_model.dart';
import '../models/meeting_model.dart';
import 'notification_service.dart';

/// 배지 서비스
/// - 배지 획득 조건 체크
/// - 배지 부여
/// - 배지 알림
class BadgeService {
  static final BadgeService _instance = BadgeService._internal();
  factory BadgeService() => _instance;
  BadgeService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _badgesRef => _firestore.collection('user_badges');

  /// 사용자 배지 조회
  Future<UserBadges> getUserBadges(String userId) async {
    final doc = await _badgesRef.doc(userId).get();
    if (!doc.exists) return UserBadges(badges: []);
    return UserBadges.fromFirestore(doc);
  }

  /// 사용자 배지 스트림
  Stream<UserBadges> getUserBadgesStream(String userId) {
    return _badgesRef.doc(userId).snapshots().map((doc) {
      if (!doc.exists) return UserBadges(badges: []);
      return UserBadges.fromFirestore(doc);
    });
  }

  /// 배지 부여
  Future<bool> awardBadge(String userId, BadgeType type) async {
    try {
      final currentBadges = await getUserBadges(userId);

      // 이미 획득한 배지인지 확인
      if (currentBadges.hasBadge(type)) return false;

      final newBadge = UserBadge(
        type: type,
        earnedAt: DateTime.now(),
        isNew: true,
      );

      await _badgesRef.doc(userId).set({
        'badges': FieldValue.arrayUnion([newBadge.toMap()]),
        'lastUpdated': Timestamp.now(),
      }, SetOptions(merge: true));

      // 배지 획득 알림
      final info = BadgeDefinitions.get(type);
      if (info != null) {
        await NotificationService().showLocalNotification(
          title: '${info.emoji} 새 배지 획득!',
          body: '${info.name} 배지를 획득했습니다!',
        );
      }

      if (kDebugMode) print('Badge awarded: $type to $userId');
      return true;
    } catch (e) {
      if (kDebugMode) print('Error awarding badge: $e');
      return false;
    }
  }

  /// 새 배지 확인 표시 제거
  Future<void> markBadgesAsSeen(String userId) async {
    final currentBadges = await getUserBadges(userId);
    final updatedBadges = currentBadges.badges.map((badge) {
      return UserBadge(
        type: badge.type,
        earnedAt: badge.earnedAt,
        isNew: false,
      );
    }).toList();

    await _badgesRef.doc(userId).set({
      'badges': updatedBadges.map((b) => b.toMap()).toList(),
      'lastUpdated': Timestamp.now(),
    });
  }

  /// 게임 참여 후 배지 체크
  Future<List<BadgeType>> checkGameBadges(UserModel user) async {
    final earnedBadges = <BadgeType>[];
    final totalGames = user.gamesPlayed;

    // 참여 횟수 배지
    if (totalGames >= 1) {
      if (await awardBadge(user.uid, BadgeType.firstGame)) {
        earnedBadges.add(BadgeType.firstGame);
      }
    }
    if (totalGames >= 5) {
      if (await awardBadge(user.uid, BadgeType.games5)) {
        earnedBadges.add(BadgeType.games5);
      }
    }
    if (totalGames >= 10) {
      if (await awardBadge(user.uid, BadgeType.games10)) {
        earnedBadges.add(BadgeType.games10);
      }
    }
    if (totalGames >= 25) {
      if (await awardBadge(user.uid, BadgeType.games25)) {
        earnedBadges.add(BadgeType.games25);
      }
    }
    if (totalGames >= 50) {
      if (await awardBadge(user.uid, BadgeType.games50)) {
        earnedBadges.add(BadgeType.games50);
      }
    }
    if (totalGames >= 100) {
      if (await awardBadge(user.uid, BadgeType.games100)) {
        earnedBadges.add(BadgeType.games100);
      }
    }

    return earnedBadges;
  }

  /// 호스팅 후 배지 체크
  Future<List<BadgeType>> checkHostBadges(UserModel user) async {
    final earnedBadges = <BadgeType>[];
    final hostedGames = user.gamesHosted;

    if (hostedGames >= 1) {
      if (await awardBadge(user.uid, BadgeType.firstHost)) {
        earnedBadges.add(BadgeType.firstHost);
      }
    }
    if (hostedGames >= 5) {
      if (await awardBadge(user.uid, BadgeType.host5)) {
        earnedBadges.add(BadgeType.host5);
      }
    }
    if (hostedGames >= 10) {
      if (await awardBadge(user.uid, BadgeType.host10)) {
        earnedBadges.add(BadgeType.host10);
      }
    }
    if (hostedGames >= 25) {
      if (await awardBadge(user.uid, BadgeType.host25)) {
        earnedBadges.add(BadgeType.host25);
      }
    }

    return earnedBadges;
  }

  /// MVP 획득 후 배지 체크
  Future<List<BadgeType>> checkMvpBadges(UserModel user) async {
    final earnedBadges = <BadgeType>[];
    final mvpCount = user.mvpCount;

    if (mvpCount >= 1) {
      if (await awardBadge(user.uid, BadgeType.firstMvp)) {
        earnedBadges.add(BadgeType.firstMvp);
      }
    }
    if (mvpCount >= 5) {
      if (await awardBadge(user.uid, BadgeType.mvp5)) {
        earnedBadges.add(BadgeType.mvp5);
      }
    }
    if (mvpCount >= 10) {
      if (await awardBadge(user.uid, BadgeType.mvp10)) {
        earnedBadges.add(BadgeType.mvp10);
      }
    }

    return earnedBadges;
  }

  /// 역할별 배지 체크
  /// MVP Phase: roleStats 제거로 비활성화
  /// v1.1+에서 Cloud Function 집계 후 활성화
  Future<List<BadgeType>> checkRoleBadges(UserModel user) async {
    // 역할 마스터 배지는 v1.1+에서 구현
    // roleStats가 제거되어 현재 체크 불가
    return [];
  }

  /// 대규모 모임 참여 배지 체크
  Future<bool> checkSocialButterflyBadge(String userId, MeetingModel meeting) async {
    if (meeting.maxParticipants >= 10) {
      return await awardBadge(userId, BadgeType.socialButterfly);
    }
    return false;
  }

  /// 얼리버드 배지 (앱 출시 초기 가입자)
  Future<bool> checkEarlyBirdBadge(String userId, DateTime createdAt) async {
    // 앱 출시일로부터 30일 이내 가입
    final launchDate = DateTime(2025, 1, 1); // 앱 출시일
    final earlyPeriod = launchDate.add(const Duration(days: 30));

    if (createdAt.isBefore(earlyPeriod)) {
      return await awardBadge(userId, BadgeType.earlyBird);
    }
    return false;
  }

  /// 야간 게임 배지 체크 (저녁 8시 이후)
  Future<void> checkNightOwlProgress(String userId, DateTime gameTime) async {
    if (gameTime.hour >= 20 || gameTime.hour < 4) {
      // 야간 게임 카운트 증가 및 체크
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final nightGames = (userDoc.data()?['nightGameCount'] ?? 0) + 1;

      await _firestore.collection('users').doc(userId).update({
        'nightGameCount': nightGames,
      });

      if (nightGames >= 5) {
        await awardBadge(userId, BadgeType.nightOwl);
      }
    }
  }

  /// 주말 게임 배지 체크
  Future<void> checkWeekendWarriorProgress(String userId, DateTime gameTime) async {
    if (gameTime.weekday == DateTime.saturday || gameTime.weekday == DateTime.sunday) {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final weekendGames = (userDoc.data()?['weekendGameCount'] ?? 0) + 1;

      await _firestore.collection('users').doc(userId).update({
        'weekendGameCount': weekendGames,
      });

      if (weekendGames >= 10) {
        await awardBadge(userId, BadgeType.weekendWarrior);
      }
    }
  }

  /// 올라운더 배지 체크 (모든 게임 타입 경험)
  Future<void> checkAllRounderBadge(String userId, GameType playedGameType) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final playedTypes = List<int>.from(userDoc.data()?['playedGameTypes'] ?? []);

    if (!playedTypes.contains(playedGameType.index)) {
      playedTypes.add(playedGameType.index);

      await _firestore.collection('users').doc(userId).update({
        'playedGameTypes': playedTypes,
      });

      // 기본 게임 타입 4개 모두 경험 (custom 제외)
      if (playedTypes.length >= 4) {
        await awardBadge(userId, BadgeType.allRounder);
      }
    }
  }

  /// 전체 배지 체크 (게임 종료 후 호출)
  Future<List<BadgeType>> checkAllBadgesAfterGame({
    required UserModel user,
    required MeetingModel meeting,
    required bool isHost,
    required bool isMvp,
  }) async {
    final earnedBadges = <BadgeType>[];

    // 기본 배지
    earnedBadges.addAll(await checkGameBadges(user));

    // 호스트 배지
    if (isHost) {
      earnedBadges.addAll(await checkHostBadges(user));
    }

    // MVP 배지
    if (isMvp) {
      earnedBadges.addAll(await checkMvpBadges(user));
    }

    // 역할 배지
    earnedBadges.addAll(await checkRoleBadges(user));

    // 특수 배지
    if (await checkSocialButterflyBadge(user.uid, meeting)) {
      earnedBadges.add(BadgeType.socialButterfly);
    }

    // 시간대별 배지
    await checkNightOwlProgress(user.uid, meeting.meetingTime);
    await checkWeekendWarriorProgress(user.uid, meeting.meetingTime);

    // 게임 타입 배지
    await checkAllRounderBadge(user.uid, meeting.gameType);

    return earnedBadges;
  }
}
