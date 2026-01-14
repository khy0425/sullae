import 'package:cloud_firestore/cloud_firestore.dart';
import 'meeting_model.dart';

/// 게임 가이드 (사용 설명서 + 로컬 룰)
///
/// 참가자들이 사전에 게임 진행 방식과 로컬 룰을 확인할 수 있음
/// 현장에서 직접 대화하거나 앱으로 미리 공유
class GameGuide {
  final String id;
  final String meetingId;
  final String hostId;

  // 기본 게임 설명 (자동 생성)
  final GameType gameType;

  // 로컬 룰 (커스텀)
  final List<String> localRules;      // 로컬 룰 목록
  final String? specialNote;           // 특별 주의사항

  // 준비물
  final List<String> requirements;     // 준비물 목록 ("편한 운동화", "물" 등)

  // 진행 순서
  final List<GamePhase> phases;        // 게임 진행 단계

  // 안전 수칙
  final List<String> safetyRules;      // 안전 수칙

  final DateTime createdAt;
  final DateTime? updatedAt;

  GameGuide({
    required this.id,
    required this.meetingId,
    required this.hostId,
    required this.gameType,
    this.localRules = const [],
    this.specialNote,
    this.requirements = const [],
    this.phases = const [],
    this.safetyRules = const [],
    required this.createdAt,
    this.updatedAt,
  });

  factory GameGuide.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GameGuide(
      id: doc.id,
      meetingId: data['meetingId'] ?? '',
      hostId: data['hostId'] ?? '',
      gameType: GameType.values[data['gameType'] ?? 0],
      localRules: List<String>.from(data['localRules'] ?? []),
      specialNote: data['specialNote'],
      requirements: List<String>.from(data['requirements'] ?? []),
      phases: (data['phases'] as List<dynamic>?)
              ?.map((p) => GamePhase.fromMap(p))
              .toList() ??
          [],
      safetyRules: List<String>.from(data['safetyRules'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'meetingId': meetingId,
      'hostId': hostId,
      'gameType': gameType.index,
      'localRules': localRules,
      'specialNote': specialNote,
      'requirements': requirements,
      'phases': phases.map((p) => p.toMap()).toList(),
      'safetyRules': safetyRules,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  GameGuide copyWith({
    List<String>? localRules,
    String? specialNote,
    List<String>? requirements,
    List<GamePhase>? phases,
    List<String>? safetyRules,
  }) {
    return GameGuide(
      id: id,
      meetingId: meetingId,
      hostId: hostId,
      gameType: gameType,
      localRules: localRules ?? this.localRules,
      specialNote: specialNote ?? this.specialNote,
      requirements: requirements ?? this.requirements,
      phases: phases ?? this.phases,
      safetyRules: safetyRules ?? this.safetyRules,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// 게임 타입별 기본 설명 생성
  static String getDefaultDescription(GameType gameType) {
    switch (gameType) {
      case GameType.copsAndRobbers:
        return '''경찰과 도둑 게임 설명

[목표]
- 경찰: 모든 도둑을 감옥에 가두면 승리
- 도둑: 시간 내 잡히지 않으면 승리

[진행]
1. 도둑이 먼저 숨을 시간 (30초~1분)
2. 경찰이 출발하여 도둑 추격
3. 경찰이 도둑을 터치하면 감옥으로 이동
4. 다른 도둑이 감옥의 도둑을 터치하면 탈옥

[승리 조건]
- 경찰 승: 모든 도둑이 감옥에 있을 때
- 도둑 승: 타이머 종료 시 한 명이라도 자유로울 때''';

      case GameType.freezeTag:
        return '''얼음땡 게임 설명

[목표]
- 술래: 모든 도망자를 얼리면 승리
- 도망자: 시간 내 한 명이라도 살아남으면 승리

[진행]
1. 술래가 "얼음땡!" 외치면 게임 시작
2. 술래가 도망자를 터치하면 얼음 상태
3. 얼음 상태: 그 자리에서 움직일 수 없음
4. 다른 도망자가 터치하면 해동

[승리 조건]
- 술래 승: 모든 도망자가 얼음 상태일 때
- 도망자 승: 타이머 종료까지 버티면''';

      case GameType.hideAndSeek:
        return '''숨바꼭질 게임 설명

[목표]
- 술래: 모든 숨는이를 찾으면 승리
- 숨는이: 끝까지 발견되지 않으면 승리

[진행]
1. 술래가 눈을 감고 숫자를 셈 (보통 30~100)
2. 숨는이들은 그 사이에 숨기
3. 술래가 "다 숨었니~" 외치고 찾기 시작
4. 찾으면 그 사람 이름 외치기

[승리 조건]
- 술래 승: 모든 사람을 찾으면
- 숨는이 승: 마지막까지 발견되지 않으면''';

      case GameType.captureFlag:
        return '''깃발뺏기 게임 설명

[목표]
상대 팀 진영의 깃발을 자기 진영으로 가져오면 승리

[진행]
1. 각 팀 진영에 깃발 배치
2. 상대 진영에 들어가면 태그 당할 수 있음
3. 태그 당하면 자기 진영으로 돌아가 다시 시작
4. 깃발을 들고 자기 진영에 도착하면 득점

[승리 조건]
- 먼저 정해진 점수에 도달하거나
- 타이머 종료 시 점수가 높은 팀''';

      case GameType.custom:
        return '커스텀 게임입니다. 호스트가 설정한 룰을 확인하세요.';
    }
  }

  /// 기본 안전 수칙
  static List<String> get defaultSafetyRules => [
    '넘어지지 않도록 주의하세요',
    '차도 근처에서 뛰지 마세요',
    '다른 사람들과 부딪히지 않도록 주의하세요',
    '너무 멀리 가지 마세요',
    '위험한 곳에 숨지 마세요',
  ];

  /// 게임 타입별 기본 준비물
  static List<String> getDefaultRequirements(GameType gameType) {
    final common = ['편한 운동화', '물', '편한 복장'];

    switch (gameType) {
      case GameType.copsAndRobbers:
        return [...common, '팀 구분용 아이템 (색깔 모자/밴드)'];
      case GameType.freezeTag:
        return common;
      case GameType.hideAndSeek:
        return common;
      case GameType.captureFlag:
        return [...common, '깃발 2개 (또는 대체품)'];
      case GameType.custom:
        return common;
    }
  }
}

/// 게임 진행 단계
class GamePhase {
  final int order;          // 순서 (1, 2, 3...)
  final String title;       // 단계명 ("준비", "숨기", "찾기" 등)
  final String description; // 설명
  final int? durationSeconds; // 예상 시간 (초)

  GamePhase({
    required this.order,
    required this.title,
    required this.description,
    this.durationSeconds,
  });

  Map<String, dynamic> toMap() => {
        'order': order,
        'title': title,
        'description': description,
        'durationSeconds': durationSeconds,
      };

  factory GamePhase.fromMap(Map<String, dynamic> data) {
    return GamePhase(
      order: data['order'] ?? 0,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      durationSeconds: data['durationSeconds'],
    );
  }
}

/// 게임 타입별 기본 진행 단계
class DefaultGamePhases {
  static List<GamePhase> get copsAndRobbers => [
    GamePhase(order: 1, title: '역할 확인', description: '경찰/도둑 역할을 확인하세요', durationSeconds: 30),
    GamePhase(order: 2, title: '감옥 위치 확인', description: '감옥 위치를 모두가 확인합니다'),
    GamePhase(order: 3, title: '도둑 숨기', description: '도둑이 먼저 흩어집니다', durationSeconds: 60),
    GamePhase(order: 4, title: '추격 시작', description: '경찰이 도둑을 잡으러 갑니다'),
    GamePhase(order: 5, title: '게임 종료', description: '타이머 종료 또는 전원 체포 시'),
  ];

  static List<GamePhase> get freezeTag => [
    GamePhase(order: 1, title: '역할 확인', description: '술래/도망자 역할을 확인하세요', durationSeconds: 30),
    GamePhase(order: 2, title: '준비', description: '도망자가 흩어집니다', durationSeconds: 30),
    GamePhase(order: 3, title: '게임 시작', description: '술래가 "얼음땡!" 외치고 시작'),
    GamePhase(order: 4, title: '게임 종료', description: '타이머 종료 또는 전원 얼음 시'),
  ];

  static List<GamePhase> get hideAndSeek => [
    GamePhase(order: 1, title: '역할 확인', description: '술래/숨는이 역할을 확인하세요', durationSeconds: 30),
    GamePhase(order: 2, title: '숨기', description: '술래가 눈 감고 세는 동안 숨기', durationSeconds: 60),
    GamePhase(order: 3, title: '찾기 시작', description: '술래가 숨은 사람을 찾습니다'),
    GamePhase(order: 4, title: '게임 종료', description: '타이머 종료 또는 전원 발견 시'),
  ];

  static List<GamePhase> get captureFlag => [
    GamePhase(order: 1, title: '팀 확인', description: 'A팀/B팀 진영을 확인하세요', durationSeconds: 60),
    GamePhase(order: 2, title: '깃발 배치', description: '각 팀 진영에 깃발을 배치합니다'),
    GamePhase(order: 3, title: '게임 시작', description: '상대 깃발을 가져오세요!'),
    GamePhase(order: 4, title: '게임 종료', description: '목표 점수 달성 또는 타이머 종료'),
  ];

  static List<GamePhase> getPhases(GameType gameType) {
    switch (gameType) {
      case GameType.copsAndRobbers:
        return copsAndRobbers;
      case GameType.freezeTag:
        return freezeTag;
      case GameType.hideAndSeek:
        return hideAndSeek;
      case GameType.captureFlag:
        return captureFlag;
      case GameType.custom:
        return [];
    }
  }
}
