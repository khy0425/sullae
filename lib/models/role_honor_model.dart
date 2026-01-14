import 'package:cloud_firestore/cloud_firestore.dart';

/// 역할 명예 시스템
///
/// 경찰 기피 현상 해결을 위한 가벼운 인정 시스템
/// - 과한 보상 ❌ (포인트, 레벨)
/// - 사회적 인정 ⭕ (MVP 투표, 지원자 표시)
class RoleHonor {
  final String meetingId;
  final String odId;
  final String nickname;
  final HonorType type;
  final int voteCount;          // MVP 투표 받은 수
  final DateTime awardedAt;

  RoleHonor({
    required this.meetingId,
    required this.odId,
    required this.nickname,
    required this.type,
    this.voteCount = 0,
    required this.awardedAt,
  });

  factory RoleHonor.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RoleHonor(
      meetingId: data['meetingId'] ?? '',
      odId: data['odId'] ?? '',
      nickname: data['nickname'] ?? '',
      type: HonorType.values[data['type'] ?? 0],
      voteCount: data['voteCount'] ?? 0,
      awardedAt: (data['awardedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'meetingId': meetingId,
      'odId': odId,
      'nickname': nickname,
      'type': type.index,
      'voteCount': voteCount,
      'awardedAt': Timestamp.fromDate(awardedAt),
    };
  }
}

/// 명예 타입
enum HonorType {
  mvp,              // 오늘의 MVP (투표)
  firstVolunteer,   // 먼저 손든 사람
  spiritAward,      // 정신력상 (힘든 역할 연속)
}

extension HonorTypeExtension on HonorType {
  String get emoji {
    switch (this) {
      case HonorType.mvp:
        return '🏅';
      case HonorType.firstVolunteer:
        return '🙋';
      case HonorType.spiritAward:
        return '💪';
    }
  }

  String get label {
    switch (this) {
      case HonorType.mvp:
        return '오늘의 MVP';
      case HonorType.firstVolunteer:
        return '용감한 지원자';
      case HonorType.spiritAward:
        return '정신력상';
    }
  }

  String get description {
    switch (this) {
      case HonorType.mvp:
        return '가장 재밌게 플레이한 사람';
      case HonorType.firstVolunteer:
        return '힘든 역할에 먼저 손든 사람';
      case HonorType.spiritAward:
        return '힘든 역할을 연속으로 맡은 사람';
    }
  }
}

/// MVP 투표
class MvpVote {
  final String voterId;       // 투표한 사람
  final String candidateId;   // 투표받은 사람
  final String meetingId;
  final DateTime votedAt;

  MvpVote({
    required this.voterId,
    required this.candidateId,
    required this.meetingId,
    required this.votedAt,
  });

  Map<String, dynamic> toMap() => {
        'voterId': voterId,
        'candidateId': candidateId,
        'meetingId': meetingId,
        'votedAt': votedAt.toIso8601String(),
      };

  factory MvpVote.fromMap(Map<String, dynamic> data) {
    return MvpVote(
      voterId: data['voterId'] ?? '',
      candidateId: data['candidateId'] ?? '',
      meetingId: data['meetingId'] ?? '',
      votedAt: DateTime.parse(data['votedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// 역할 로테이션 제안
///
/// "경찰 2라운드 연속 → 도둑 전환?" 같은 자동 제안
class RoleRotationSuggestion {
  final String odId;
  final String nickname;
  final String currentRole;     // 현재 역할
  final String suggestedRole;   // 제안 역할
  final int consecutiveRounds;  // 연속 라운드 수
  final String reason;          // 제안 이유

  RoleRotationSuggestion({
    required this.odId,
    required this.nickname,
    required this.currentRole,
    required this.suggestedRole,
    required this.consecutiveRounds,
    required this.reason,
  });

  /// 기본 제안 생성
  static RoleRotationSuggestion? checkAndSuggest({
    required String odId,
    required String nickname,
    required String currentRole,
    required int consecutiveRounds,
    required String alternativeRole,
  }) {
    // 2라운드 연속이면 제안
    if (consecutiveRounds >= 2) {
      return RoleRotationSuggestion(
        odId: odId,
        nickname: nickname,
        currentRole: currentRole,
        suggestedRole: alternativeRole,
        consecutiveRounds: consecutiveRounds,
        reason: '$currentRole $consecutiveRounds라운드 연속! $alternativeRole으로 바꿔볼까요?',
      );
    }
    return null;
  }
}

/// 경찰 지원자 기록
///
/// 먼저 손 든 사람 표시용
class VolunteerRecord {
  final String odId;
  final String nickname;
  final String role;            // 지원한 역할
  final int roundNumber;        // 라운드 번호
  final DateTime volunteeredAt;
  final bool wasFirst;          // 첫 번째 지원자였는지

  VolunteerRecord({
    required this.odId,
    required this.nickname,
    required this.role,
    required this.roundNumber,
    required this.volunteeredAt,
    this.wasFirst = false,
  });

  Map<String, dynamic> toMap() => {
        'odId': odId,
        'nickname': nickname,
        'role': role,
        'roundNumber': roundNumber,
        'volunteeredAt': volunteeredAt.toIso8601String(),
        'wasFirst': wasFirst,
      };

  factory VolunteerRecord.fromMap(Map<String, dynamic> data) {
    return VolunteerRecord(
      odId: data['odId'] ?? '',
      nickname: data['nickname'] ?? '',
      role: data['role'] ?? '',
      roundNumber: data['roundNumber'] ?? 0,
      volunteeredAt: DateTime.parse(data['volunteeredAt'] ?? DateTime.now().toIso8601String()),
      wasFirst: data['wasFirst'] ?? false,
    );
  }
}
