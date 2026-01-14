import 'package:cloud_firestore/cloud_firestore.dart';

/// 배지 정의
enum BadgeType {
  // 참여 관련
  firstGame,        // 첫 게임 참여
  games5,           // 5회 참여
  games10,          // 10회 참여
  games25,          // 25회 참여
  games50,          // 50회 참여
  games100,         // 100회 참여

  // 호스팅 관련
  firstHost,        // 첫 모임 주최
  host5,            // 5회 주최
  host10,           // 10회 주최
  host25,           // 25회 주최

  // MVP 관련
  firstMvp,         // 첫 MVP
  mvp5,             // 5회 MVP
  mvp10,            // 10회 MVP

  // 특별 배지
  earlyBird,        // 얼리버드 (앱 출시 1개월 내 가입)
  socialButterfly,  // 소셜 버터플라이 (10명 이상 모임 참여)
  nightOwl,         // 야행성 (저녁 8시 이후 게임 5회)
  weekendWarrior,   // 주말 전사 (주말 게임 10회)
  allRounder,       // 올라운더 (모든 게임 타입 참여)
  loyalPlayer,      // 충성 플레이어 (30일 연속 접속)

  // 게임별 배지
  copsMaster,       // 경찰 마스터 (경찰 역할 20회)
  robberMaster,     // 도둑 마스터 (도둑 역할 20회)
  seekerMaster,     // 술래 마스터 (술래 역할 20회)
  hiderMaster,      // 숨기 마스터 (숨는 역할 20회)
}

/// 배지 정보
class BadgeInfo {
  final BadgeType type;
  final String name;
  final String description;
  final String emoji;
  final int requiredCount;
  final BadgeRarity rarity;

  const BadgeInfo({
    required this.type,
    required this.name,
    required this.description,
    required this.emoji,
    this.requiredCount = 1,
    this.rarity = BadgeRarity.common,
  });
}

/// 배지 희귀도
enum BadgeRarity {
  common,     // 일반
  uncommon,   // 고급
  rare,       // 희귀
  epic,       // 영웅
  legendary,  // 전설
}

extension BadgeRarityExtension on BadgeRarity {
  String get label {
    switch (this) {
      case BadgeRarity.common:
        return '일반';
      case BadgeRarity.uncommon:
        return '고급';
      case BadgeRarity.rare:
        return '희귀';
      case BadgeRarity.epic:
        return '영웅';
      case BadgeRarity.legendary:
        return '전설';
    }
  }

  String get colorHex {
    switch (this) {
      case BadgeRarity.common:
        return '#9E9E9E';  // 회색
      case BadgeRarity.uncommon:
        return '#4CAF50';  // 초록
      case BadgeRarity.rare:
        return '#2196F3';  // 파랑
      case BadgeRarity.epic:
        return '#9C27B0';  // 보라
      case BadgeRarity.legendary:
        return '#FF9800';  // 주황
    }
  }
}

/// 모든 배지 정보
class BadgeDefinitions {
  static const Map<BadgeType, BadgeInfo> all = {
    // 참여 관련
    BadgeType.firstGame: BadgeInfo(
      type: BadgeType.firstGame,
      name: '첫 발걸음',
      description: '첫 번째 게임에 참여했습니다',
      emoji: '👟',
      rarity: BadgeRarity.common,
    ),
    BadgeType.games5: BadgeInfo(
      type: BadgeType.games5,
      name: '단골 플레이어',
      description: '5회 게임에 참여했습니다',
      emoji: '🎮',
      requiredCount: 5,
      rarity: BadgeRarity.common,
    ),
    BadgeType.games10: BadgeInfo(
      type: BadgeType.games10,
      name: '열정 플레이어',
      description: '10회 게임에 참여했습니다',
      emoji: '🔥',
      requiredCount: 10,
      rarity: BadgeRarity.uncommon,
    ),
    BadgeType.games25: BadgeInfo(
      type: BadgeType.games25,
      name: '베테랑',
      description: '25회 게임에 참여했습니다',
      emoji: '⭐',
      requiredCount: 25,
      rarity: BadgeRarity.rare,
    ),
    BadgeType.games50: BadgeInfo(
      type: BadgeType.games50,
      name: '프로 술래잡기러',
      description: '50회 게임에 참여했습니다',
      emoji: '🏆',
      requiredCount: 50,
      rarity: BadgeRarity.epic,
    ),
    BadgeType.games100: BadgeInfo(
      type: BadgeType.games100,
      name: '레전드',
      description: '100회 게임에 참여했습니다',
      emoji: '👑',
      requiredCount: 100,
      rarity: BadgeRarity.legendary,
    ),

    // 호스팅 관련
    BadgeType.firstHost: BadgeInfo(
      type: BadgeType.firstHost,
      name: '첫 주최',
      description: '첫 번째 모임을 주최했습니다',
      emoji: '🎉',
      rarity: BadgeRarity.common,
    ),
    BadgeType.host5: BadgeInfo(
      type: BadgeType.host5,
      name: '모임 리더',
      description: '5회 모임을 주최했습니다',
      emoji: '📢',
      requiredCount: 5,
      rarity: BadgeRarity.uncommon,
    ),
    BadgeType.host10: BadgeInfo(
      type: BadgeType.host10,
      name: '커뮤니티 빌더',
      description: '10회 모임을 주최했습니다',
      emoji: '🏗️',
      requiredCount: 10,
      rarity: BadgeRarity.rare,
    ),
    BadgeType.host25: BadgeInfo(
      type: BadgeType.host25,
      name: '술래 대장',
      description: '25회 모임을 주최했습니다',
      emoji: '🎖️',
      requiredCount: 25,
      rarity: BadgeRarity.epic,
    ),

    // MVP 관련
    BadgeType.firstMvp: BadgeInfo(
      type: BadgeType.firstMvp,
      name: '첫 MVP',
      description: '첫 번째 MVP를 획득했습니다',
      emoji: '🌟',
      rarity: BadgeRarity.common,
    ),
    BadgeType.mvp5: BadgeInfo(
      type: BadgeType.mvp5,
      name: 'MVP 헌터',
      description: '5회 MVP를 획득했습니다',
      emoji: '💫',
      requiredCount: 5,
      rarity: BadgeRarity.uncommon,
    ),
    BadgeType.mvp10: BadgeInfo(
      type: BadgeType.mvp10,
      name: 'MVP 마스터',
      description: '10회 MVP를 획득했습니다',
      emoji: '✨',
      requiredCount: 10,
      rarity: BadgeRarity.rare,
    ),

    // 특별 배지
    BadgeType.earlyBird: BadgeInfo(
      type: BadgeType.earlyBird,
      name: '얼리버드',
      description: '앱 출시 초기에 가입했습니다',
      emoji: '🐦',
      rarity: BadgeRarity.rare,
    ),
    BadgeType.socialButterfly: BadgeInfo(
      type: BadgeType.socialButterfly,
      name: '소셜 버터플라이',
      description: '10명 이상 모임에 참여했습니다',
      emoji: '🦋',
      rarity: BadgeRarity.uncommon,
    ),
    BadgeType.nightOwl: BadgeInfo(
      type: BadgeType.nightOwl,
      name: '야행성',
      description: '저녁 게임 5회 참여',
      emoji: '🦉',
      requiredCount: 5,
      rarity: BadgeRarity.uncommon,
    ),
    BadgeType.weekendWarrior: BadgeInfo(
      type: BadgeType.weekendWarrior,
      name: '주말 전사',
      description: '주말 게임 10회 참여',
      emoji: '⚔️',
      requiredCount: 10,
      rarity: BadgeRarity.rare,
    ),
    BadgeType.allRounder: BadgeInfo(
      type: BadgeType.allRounder,
      name: '올라운더',
      description: '모든 게임 타입을 경험했습니다',
      emoji: '🎯',
      rarity: BadgeRarity.rare,
    ),
    BadgeType.loyalPlayer: BadgeInfo(
      type: BadgeType.loyalPlayer,
      name: '충성 플레이어',
      description: '30일 연속 접속',
      emoji: '💎',
      requiredCount: 30,
      rarity: BadgeRarity.epic,
    ),

    // 게임별 배지
    BadgeType.copsMaster: BadgeInfo(
      type: BadgeType.copsMaster,
      name: '경찰 마스터',
      description: '경찰 역할 20회 수행',
      emoji: '👮',
      requiredCount: 20,
      rarity: BadgeRarity.rare,
    ),
    BadgeType.robberMaster: BadgeInfo(
      type: BadgeType.robberMaster,
      name: '도둑 마스터',
      description: '도둑 역할 20회 수행',
      emoji: '🦹',
      requiredCount: 20,
      rarity: BadgeRarity.rare,
    ),
    BadgeType.seekerMaster: BadgeInfo(
      type: BadgeType.seekerMaster,
      name: '술래 마스터',
      description: '술래 역할 20회 수행',
      emoji: '👁️',
      requiredCount: 20,
      rarity: BadgeRarity.rare,
    ),
    BadgeType.hiderMaster: BadgeInfo(
      type: BadgeType.hiderMaster,
      name: '은신 마스터',
      description: '숨는 역할 20회 수행',
      emoji: '🙈',
      requiredCount: 20,
      rarity: BadgeRarity.rare,
    ),
  };

  static BadgeInfo? get(BadgeType type) => all[type];
}

/// 사용자 배지
class UserBadge {
  final BadgeType type;
  final DateTime earnedAt;
  final bool isNew;  // 새로 획득한 배지 표시용

  UserBadge({
    required this.type,
    required this.earnedAt,
    this.isNew = false,
  });

  factory UserBadge.fromMap(Map<String, dynamic> data) {
    return UserBadge(
      type: BadgeType.values[data['type'] ?? 0],
      earnedAt: (data['earnedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isNew: data['isNew'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.index,
      'earnedAt': Timestamp.fromDate(earnedAt),
      'isNew': isNew,
    };
  }

  BadgeInfo? get info => BadgeDefinitions.get(type);
}

/// 사용자 배지 컬렉션
class UserBadges {
  final List<UserBadge> badges;

  UserBadges({required this.badges});

  factory UserBadges.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return UserBadges(badges: []);

    final badgesList = (data['badges'] as List<dynamic>?)
        ?.map((b) => UserBadge.fromMap(b as Map<String, dynamic>))
        .toList() ?? [];

    return UserBadges(badges: badgesList);
  }

  Map<String, dynamic> toFirestore() {
    return {
      'badges': badges.map((b) => b.toMap()).toList(),
    };
  }

  bool hasBadge(BadgeType type) {
    return badges.any((b) => b.type == type);
  }

  List<UserBadge> get newBadges => badges.where((b) => b.isNew).toList();

  int get totalCount => badges.length;

  /// 희귀도별 배지 개수
  Map<BadgeRarity, int> get countByRarity {
    final counts = <BadgeRarity, int>{};
    for (final badge in badges) {
      final info = badge.info;
      if (info != null) {
        counts[info.rarity] = (counts[info.rarity] ?? 0) + 1;
      }
    }
    return counts;
  }
}
