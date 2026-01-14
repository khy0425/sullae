import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meeting_model.dart';

enum TeamType {
  cops,     // 경찰
  robbers,  // 도둑
  seekers,  // 술래
  hiders,   // 숨는 사람
  teamA,    // A팀
  teamB,    // B팀
}

/// 역할 희망 선택 (게임별로 다른 의미)
/// - 경찰과 도둑: cops / robbers
/// - 얼음땡/숨바꼭질: seekers / hiders
/// - 깃발뺏기/커스텀: teamA / teamB
enum RolePreference {
  none,      // 상관없음 (랜덤 배치)
  role1,     // 첫번째 역할 (경찰/술래/A팀)
  role2,     // 두번째 역할 (도둑/도망자/B팀)
}

/// 팀 균형 상태
enum TeamBalanceStatus {
  balanced,       // 균형 (동률 또는 1명 차이)
  unbalanced,     // 불균형 (조정 필요)
  needsManual,    // 수동 조정 필요 (참가자끼리 협의)
}

/// 팀 균형 결과
class TeamBalanceResult {
  final TeamBalanceStatus status;
  final int role1Count;      // 역할1 희망 인원
  final int role2Count;      // 역할2 희망 인원
  final int noneCount;       // 상관없음 인원
  final int role1Target;     // 역할1 목표 인원
  final int role2Target;     // 역할2 목표 인원
  final int excessRole1;     // 역할1 초과 인원 (음수면 부족)
  final int excessRole2;     // 역할2 초과 인원 (음수면 부족)
  final String message;      // 상태 메시지

  TeamBalanceResult({
    required this.status,
    required this.role1Count,
    required this.role2Count,
    required this.noneCount,
    required this.role1Target,
    required this.role2Target,
    required this.excessRole1,
    required this.excessRole2,
    required this.message,
  });

  /// 자동 배정 가능 여부 (항상 true - 불균형해도 강제 시작 가능)
  bool get canAutoAssign => true;

  /// 균형 상태인지 여부
  bool get isBalanced => status == TeamBalanceStatus.balanced;

  /// 수동 조정이 권장되는지 여부
  bool get needsAdjustment => status == TeamBalanceStatus.needsManual;
}

/// 희망 정보가 포함된 참가자
class ParticipantWithPreference {
  final String odId;
  final String nickname;
  final RolePreference preference;

  ParticipantWithPreference({
    required this.odId,
    required this.nickname,
    this.preference = RolePreference.none,
  });

  Map<String, dynamic> toMap() => {
    'odId': odId,
    'nickname': nickname,
    'preference': preference.index,
  };

  factory ParticipantWithPreference.fromMap(Map<String, dynamic> data) {
    return ParticipantWithPreference(
      odId: data['odId'] ?? '',
      nickname: data['nickname'] ?? '',
      preference: RolePreference.values[data['preference'] ?? 0],
    );
  }

  /// 희망 역할 복사본 생성 (역할 변경용)
  ParticipantWithPreference copyWith({RolePreference? preference}) {
    return ParticipantWithPreference(
      odId: odId,
      nickname: nickname,
      preference: preference ?? this.preference,
    );
  }
}

class TeamAssignment {
  final String odId;
  final String odNickname;
  final TeamType team;

  TeamAssignment({
    required this.odId,
    required this.odNickname,
    required this.team,
  });

  Map<String, dynamic> toMap() => {
        'userId': odId,
        'userNickname': odNickname,
        'team': team.index,
      };

  factory TeamAssignment.fromMap(Map<String, dynamic> data) {
    return TeamAssignment(
      odId: data['userId'] ?? '',
      odNickname: data['userNickname'] ?? '',
      team: TeamType.values[data['team'] ?? 0],
    );
  }
}

class GameSession {
  final String id;
  final String meetingId;
  final GameType gameType;
  final List<TeamAssignment> teams;
  final DateTime startTime;
  final int durationMinutes;
  final bool isActive;
  final int round;

  GameSession({
    required this.id,
    required this.meetingId,
    required this.gameType,
    required this.teams,
    required this.startTime,
    required this.durationMinutes,
    this.isActive = true,
    this.round = 1,
  });

  factory GameSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GameSession(
      id: doc.id,
      meetingId: data['meetingId'] ?? '',
      gameType: GameType.values[data['gameType'] ?? 0],
      teams: (data['teams'] as List<dynamic>?)
              ?.map((e) => TeamAssignment.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      startTime: (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      durationMinutes: data['durationMinutes'] ?? 10,
      isActive: data['isActive'] ?? true,
      round: data['round'] ?? 1,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'meetingId': meetingId,
        'gameType': gameType.index,
        'teams': teams.map((e) => e.toMap()).toList(),
        'startTime': Timestamp.fromDate(startTime),
        'durationMinutes': durationMinutes,
        'isActive': isActive,
        'round': round,
      };

  DateTime get endTime => startTime.add(Duration(minutes: durationMinutes));

  Duration get remainingTime {
    final remaining = endTime.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  List<TeamAssignment> getTeamMembers(TeamType type) =>
      teams.where((t) => t.team == type).toList();
}

class GameService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  CollectionReference get _sessionsRef => _firestore.collection('game_sessions');

  // 팀 랜덤 배정
  List<TeamAssignment> assignTeams({
    required List<Map<String, String>> participants, // [{id, nickname}]
    required GameType gameType,
    int? seekerCount,
  }) {
    final shuffled = List<Map<String, String>>.from(participants)..shuffle(_random);
    final assignments = <TeamAssignment>[];

    switch (gameType) {
      case GameType.copsAndRobbers:
        // 경찰 vs 도둑 (절반씩)
        final half = (shuffled.length / 2).ceil();
        for (int i = 0; i < shuffled.length; i++) {
          assignments.add(TeamAssignment(
            odId: shuffled[i]['id']!,
            odNickname: shuffled[i]['nickname']!,
            team: i < half ? TeamType.cops : TeamType.robbers,
          ));
        }
        break;

      case GameType.freezeTag:
      case GameType.hideAndSeek:
        // 술래 vs 나머지
        final seekers = seekerCount ?? 1;
        for (int i = 0; i < shuffled.length; i++) {
          assignments.add(TeamAssignment(
            odId: shuffled[i]['id']!,
            odNickname: shuffled[i]['nickname']!,
            team: i < seekers ? TeamType.seekers : TeamType.hiders,
          ));
        }
        break;

      case GameType.captureFlag:
        // A팀 vs B팀
        final half = (shuffled.length / 2).ceil();
        for (int i = 0; i < shuffled.length; i++) {
          assignments.add(TeamAssignment(
            odId: shuffled[i]['id']!,
            odNickname: shuffled[i]['nickname']!,
            team: i < half ? TeamType.teamA : TeamType.teamB,
          ));
        }
        break;

      case GameType.custom:
        // 커스텀은 A팀 vs B팀으로 기본 설정
        final half = (shuffled.length / 2).ceil();
        for (int i = 0; i < shuffled.length; i++) {
          assignments.add(TeamAssignment(
            odId: shuffled[i]['id']!,
            odNickname: shuffled[i]['nickname']!,
            team: i < half ? TeamType.teamA : TeamType.teamB,
          ));
        }
        break;
    }

    return assignments;
  }

  // 게임 세션 시작
  Future<String> startGameSession({
    required String meetingId,
    required GameType gameType,
    required List<TeamAssignment> teams,
    int durationMinutes = 10,
  }) async {
    final session = GameSession(
      id: '',
      meetingId: meetingId,
      gameType: gameType,
      teams: teams,
      startTime: DateTime.now(),
      durationMinutes: durationMinutes,
    );

    final docRef = await _sessionsRef.add(session.toFirestore());
    return docRef.id;
  }

  // 게임 세션 종료
  Future<void> endGameSession(String sessionId) async {
    await _sessionsRef.doc(sessionId).update({'isActive': false});
  }

  // 현재 활성 세션 조회
  Stream<GameSession?> getActiveSession(String meetingId) {
    return _sessionsRef
        .where('meetingId', isEqualTo: meetingId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return GameSession.fromFirestore(snapshot.docs.first);
    });
  }

  // 세션 스트림
  Stream<GameSession?> getSessionStream(String sessionId) {
    return _sessionsRef.doc(sessionId).snapshots().map((doc) {
      if (doc.exists) {
        return GameSession.fromFirestore(doc);
      }
      return null;
    });
  }

  // 다음 라운드 시작
  Future<void> startNextRound(String sessionId, List<TeamAssignment> newTeams) async {
    final doc = await _sessionsRef.doc(sessionId).get();
    if (doc.exists) {
      final session = GameSession.fromFirestore(doc);
      await _sessionsRef.doc(sessionId).update({
        'teams': newTeams.map((e) => e.toMap()).toList(),
        'startTime': Timestamp.now(),
        'round': session.round + 1,
      });
    }
  }

  // 팀 이름 가져오기
  String getTeamName(TeamType type, GameType gameType) {
    switch (gameType) {
      case GameType.copsAndRobbers:
        return type == TeamType.cops ? '경찰' : '도둑';
      case GameType.freezeTag:
        return type == TeamType.seekers ? '술래' : '도망자';
      case GameType.hideAndSeek:
        return type == TeamType.seekers ? '술래' : '숨는이';
      case GameType.captureFlag:
        return type == TeamType.teamA ? 'A팀' : 'B팀';
      case GameType.custom:
        return type == TeamType.teamA ? 'A팀' : 'B팀';
    }
  }

  // ============== 역할 선택 시스템 ==============

  /// 게임별 역할 옵션 가져오기
  /// 경찰과 도둑 → [경찰, 도둑]
  /// 얼음땡/숨바꼭질 → [술래, 도망자/숨는이]
  List<RoleOption> getRoleOptions(GameType gameType) {
    switch (gameType) {
      case GameType.copsAndRobbers:
        return [
          RoleOption(preference: RolePreference.role1, name: '경찰', teamType: TeamType.cops),
          RoleOption(preference: RolePreference.role2, name: '도둑', teamType: TeamType.robbers),
        ];
      case GameType.freezeTag:
        return [
          RoleOption(preference: RolePreference.role1, name: '술래', teamType: TeamType.seekers),
          RoleOption(preference: RolePreference.role2, name: '도망자', teamType: TeamType.hiders),
        ];
      case GameType.hideAndSeek:
        return [
          RoleOption(preference: RolePreference.role1, name: '술래', teamType: TeamType.seekers),
          RoleOption(preference: RolePreference.role2, name: '숨는이', teamType: TeamType.hiders),
        ];
      case GameType.captureFlag:
      case GameType.custom:
        return [
          RoleOption(preference: RolePreference.role1, name: 'A팀', teamType: TeamType.teamA),
          RoleOption(preference: RolePreference.role2, name: 'B팀', teamType: TeamType.teamB),
        ];
    }
  }

  /// 팀 균형 상태 확인
  TeamBalanceResult checkTeamBalance({
    required List<ParticipantWithPreference> participants,
    required GameType gameType,
    int? seekerCount,
  }) {
    final total = participants.length;
    final role1Count = participants.where((p) => p.preference == RolePreference.role1).length;
    final role2Count = participants.where((p) => p.preference == RolePreference.role2).length;
    final noneCount = participants.where((p) => p.preference == RolePreference.none).length;

    // 게임별 목표 인원 계산
    int role1Target;
    switch (gameType) {
      case GameType.freezeTag:
      case GameType.hideAndSeek:
        role1Target = seekerCount ?? 1;
        break;
      default:
        role1Target = (total / 2).ceil();
    }
    final role2Target = total - role1Target;

    final excessRole1 = role1Count - role1Target;
    final excessRole2 = role2Count - role2Target;

    final roles = getRoleOptions(gameType);
    final role1Name = roles[0].name;
    final role2Name = roles[1].name;

    // 균형 상태 판단
    TeamBalanceStatus status;
    String message;

    if (role1Count == role1Target && role2Count == role2Target) {
      // 완벽한 균형
      status = TeamBalanceStatus.balanced;
      message = '팀이 균형잡혀 있습니다. 바로 시작할 수 있어요!';
    } else if (noneCount > 0) {
      // 상관없음 인원으로 조정 가능
      final canBalance = (role1Count <= role1Target) && (role2Count <= role2Target);
      if (canBalance) {
        status = TeamBalanceStatus.balanced;
        message = '상관없음 인원이 랜덤 배치됩니다.';
      } else {
        status = TeamBalanceStatus.unbalanced;
        if (excessRole1 > 0) {
          message = '$role1Name 희망자가 $excessRole1명 초과입니다. $excessRole1명이 랜덤으로 $role2Name이 됩니다.';
        } else {
          message = '$role2Name 희망자가 $excessRole2명 초과입니다. $excessRole2명이 랜덤으로 $role1Name이 됩니다.';
        }
      }
    } else {
      // 상관없음이 없고 불균형 - 하지만 강제 시작 가능
      status = TeamBalanceStatus.needsManual;
      if (excessRole1 > 0) {
        message = '$role1Name 희망자가 $excessRole1명 초과입니다. 협의 후 조정하거나 그대로 시작할 수 있어요.';
      } else if (excessRole2 > 0) {
        message = '$role2Name 희망자가 $excessRole2명 초과입니다. 협의 후 조정하거나 그대로 시작할 수 있어요.';
      } else {
        message = '팀 구성이 불균형합니다. 조정하거나 그대로 시작할 수 있어요.';
      }
    }

    return TeamBalanceResult(
      status: status,
      role1Count: role1Count,
      role2Count: role2Count,
      noneCount: noneCount,
      role1Target: role1Target,
      role2Target: role2Target,
      excessRole1: excessRole1,
      excessRole2: excessRole2,
      message: message,
    );
  }

  /// 희망 기반 팀 배정
  ///
  /// 배정 로직:
  /// 1. 동률이면 그대로 배정
  /// 2. 상관없음 인원으로 부족한 팀 채우기
  /// 3. 초과 시 초과 인원 중 랜덤으로 반대팀 배정
  List<TeamAssignment> assignTeamsWithPreference({
    required List<ParticipantWithPreference> participants,
    required GameType gameType,
    int? seekerCount,
  }) {
    final assignments = <TeamAssignment>[];
    final roles = getRoleOptions(gameType);
    final role1Type = roles[0].teamType;
    final role2Type = roles[1].teamType;

    // 목표 인원 계산
    int role1Target;
    switch (gameType) {
      case GameType.freezeTag:
      case GameType.hideAndSeek:
        role1Target = seekerCount ?? 1;
        break;
      default:
        role1Target = (participants.length / 2).ceil();
    }
    final role2Target = participants.length - role1Target;

    // 희망별로 분류
    final role1Preferred = participants
        .where((p) => p.preference == RolePreference.role1)
        .toList()..shuffle(_random);
    final role2Preferred = participants
        .where((p) => p.preference == RolePreference.role2)
        .toList()..shuffle(_random);
    final noPreference = participants
        .where((p) => p.preference == RolePreference.none)
        .toList()..shuffle(_random);

    final role1Members = <ParticipantWithPreference>[];
    final role2Members = <ParticipantWithPreference>[];

    // role1 희망자 배정 (목표 인원까지)
    for (final p in role1Preferred) {
      if (role1Members.length < role1Target) {
        role1Members.add(p);
      } else {
        // 초과 인원은 none 풀로 (랜덤 배정 대상)
        noPreference.add(p);
      }
    }

    // role2 희망자 배정 (목표 인원까지)
    for (final p in role2Preferred) {
      if (role2Members.length < role2Target) {
        role2Members.add(p);
      } else {
        // 초과 인원은 none 풀로
        noPreference.add(p);
      }
    }

    // 상관없음 인원으로 나머지 채우기
    noPreference.shuffle(_random);
    for (final p in noPreference) {
      if (role1Members.length < role1Target) {
        role1Members.add(p);
      } else if (role2Members.length < role2Target) {
        role2Members.add(p);
      }
    }

    // TeamAssignment로 변환
    for (final p in role1Members) {
      assignments.add(TeamAssignment(
        odId: p.odId,
        odNickname: p.nickname,
        team: role1Type,
      ));
    }
    for (final p in role2Members) {
      assignments.add(TeamAssignment(
        odId: p.odId,
        odNickname: p.nickname,
        team: role2Type,
      ));
    }

    return assignments;
  }

  /// 역할 희망 이름 가져오기
  String getRolePreferenceName(RolePreference preference, GameType gameType) {
    if (preference == RolePreference.none) return '상관없음';
    final roles = getRoleOptions(gameType);
    return preference == RolePreference.role1
        ? '${roles[0].name} 희망'
        : '${roles[1].name} 희망';
  }

  /// 희망 통계 가져오기
  Map<RolePreference, int> getPreferenceStats(List<ParticipantWithPreference> participants) {
    return {
      RolePreference.none: participants.where((p) => p.preference == RolePreference.none).length,
      RolePreference.role1: participants.where((p) => p.preference == RolePreference.role1).length,
      RolePreference.role2: participants.where((p) => p.preference == RolePreference.role2).length,
    };
  }
}

/// 역할 옵션 정보
class RoleOption {
  final RolePreference preference;
  final String name;
  final TeamType teamType;

  RoleOption({
    required this.preference,
    required this.name,
    required this.teamType,
  });
}
