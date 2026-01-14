import 'meeting_model.dart';

/// 30초 룰 카드
///
/// 분쟁을 줄이는 핵심 4가지 정보만 담은 간결한 설명 카드
/// - 승리 조건: 뭘 해야 이기는지
/// - 아웃 조건: 언제 잡히는지
/// - 부활 방법: 잡힌 사람 어떻게 되는지
/// - 금지 구역: 어디까지 갈 수 있는지
class RuleCard {
  final String winCondition;      // 승리 조건 (필수)
  final String outCondition;      // 아웃 조건 (필수)
  final String reviveMethod;      // 부활/구출 방법 (필수)
  final String? boundaryNote;     // 금지 구역 (선택)

  RuleCard({
    required this.winCondition,
    required this.outCondition,
    required this.reviveMethod,
    this.boundaryNote,
  });

  Map<String, dynamic> toMap() => {
        'winCondition': winCondition,
        'outCondition': outCondition,
        'reviveMethod': reviveMethod,
        'boundaryNote': boundaryNote,
      };

  factory RuleCard.fromMap(Map<String, dynamic> data) {
    return RuleCard(
      winCondition: data['winCondition'] ?? '',
      outCondition: data['outCondition'] ?? '',
      reviveMethod: data['reviveMethod'] ?? '',
      boundaryNote: data['boundaryNote'],
    );
  }

  /// 게임 타입별 기본 룰 카드
  static RuleCard getDefault(GameType gameType) {
    switch (gameType) {
      case GameType.copsAndRobbers:
        return RuleCard(
          winCondition: '경찰: 모든 도둑 체포\n도둑: 시간 내 1명 이상 생존',
          outCondition: '경찰에게 터치당하면 감옥으로',
          reviveMethod: '다른 도둑이 감옥의 도둑을 터치하면 탈옥',
        );

      case GameType.freezeTag:
        return RuleCard(
          winCondition: '술래: 모두 얼리기\n도망자: 시간 내 1명 이상 생존',
          outCondition: '술래에게 터치당하면 그 자리에서 얼음',
          reviveMethod: '다른 도망자가 터치하면 해동',
        );

      case GameType.hideAndSeek:
        return RuleCard(
          winCondition: '술래: 모두 찾기\n숨는이: 끝까지 발견되지 않기',
          outCondition: '술래가 이름을 외치면 발견',
          reviveMethod: '발견되면 술래와 함께 다른 사람 찾기',
        );

      case GameType.captureFlag:
        return RuleCard(
          winCondition: '상대 깃발을 자기 진영으로 가져오면 득점',
          outCondition: '상대 진영에서 태그당하면 자기 진영으로 복귀',
          reviveMethod: '자기 진영 도착 시 즉시 부활',
        );

      case GameType.custom:
        return RuleCard(
          winCondition: '호스트가 설정',
          outCondition: '호스트가 설정',
          reviveMethod: '호스트가 설정',
        );
    }
  }
}

/// 선택형 로컬 룰 옵션
///
/// 체크박스로 ON/OFF 가능한 사전 정의 옵션
/// 자유 입력을 최소화하여 혼란 방지
class LocalRuleOption {
  final String id;
  final String label;         // 표시 텍스트
  final String description;   // 상세 설명
  final bool defaultValue;    // 기본값
  final bool enabled;         // 현재 활성화 여부

  LocalRuleOption({
    required this.id,
    required this.label,
    required this.description,
    this.defaultValue = false,
    this.enabled = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'description': description,
        'defaultValue': defaultValue,
        'enabled': enabled,
      };

  factory LocalRuleOption.fromMap(Map<String, dynamic> data) {
    return LocalRuleOption(
      id: data['id'] ?? '',
      label: data['label'] ?? '',
      description: data['description'] ?? '',
      defaultValue: data['defaultValue'] ?? false,
      enabled: data['enabled'] ?? false,
    );
  }

  LocalRuleOption copyWith({bool? enabled}) {
    return LocalRuleOption(
      id: id,
      label: label,
      description: description,
      defaultValue: defaultValue,
      enabled: enabled ?? this.enabled,
    );
  }
}

/// 게임별 선택형 로컬 룰 옵션 모음
class LocalRuleOptions {
  /// 경찰과 도둑 옵션
  static List<LocalRuleOption> get copsAndRobbers => [
    LocalRuleOption(
      id: 'allow_jailbreak',
      label: '탈옥 허용',
      description: '다른 도둑이 감옥의 도둑을 구출할 수 있음',
      defaultValue: true,
    ),
    LocalRuleOption(
      id: 'safe_zone',
      label: '안전구역 있음',
      description: '지정된 안전구역에서는 잡히지 않음',
      defaultValue: false,
    ),
    LocalRuleOption(
      id: 'cop_rotation',
      label: '경찰 교대',
      description: '라운드마다 경찰/도둑 역할 교대',
      defaultValue: false,
    ),
    LocalRuleOption(
      id: 'tag_back_immunity',
      label: '역태그 방지',
      description: '탈옥 직후 5초간 다시 잡히지 않음',
      defaultValue: true,
    ),
  ];

  /// 얼음땡 옵션
  static List<LocalRuleOption> get freezeTag => [
    LocalRuleOption(
      id: 'self_unfreeze',
      label: '자가 해동',
      description: '10초 후 스스로 해동 가능',
      defaultValue: false,
    ),
    LocalRuleOption(
      id: 'crawl_unfreeze',
      label: '가랑이 통과 해동',
      description: '터치 대신 가랑이 사이로 통과해야 해동',
      defaultValue: false,
    ),
    LocalRuleOption(
      id: 'seeker_rotation',
      label: '술래 교대',
      description: '첫 번째로 얼린 사람이 다음 술래',
      defaultValue: false,
    ),
  ];

  /// 숨바꼭질 옵션
  static List<LocalRuleOption> get hideAndSeek => [
    LocalRuleOption(
      id: 'found_helps_seek',
      label: '발견자 협력',
      description: '발견된 사람도 함께 찾기',
      defaultValue: true,
    ),
    LocalRuleOption(
      id: 'move_allowed',
      label: '이동 허용',
      description: '숨은 후에도 위치 변경 가능',
      defaultValue: false,
    ),
    LocalRuleOption(
      id: 'seeker_walk_only',
      label: '술래 걷기만',
      description: '술래는 뛰지 못하고 걷기만 가능',
      defaultValue: false,
    ),
  ];

  /// 깃발뺏기 옵션
  static List<LocalRuleOption> get captureFlag => [
    LocalRuleOption(
      id: 'jail_exists',
      label: '감옥 있음',
      description: '태그당하면 감옥으로 (동료 구출 가능)',
      defaultValue: false,
    ),
    LocalRuleOption(
      id: 'throw_allowed',
      label: '깃발 던지기',
      description: '깃발을 동료에게 던져서 전달 가능',
      defaultValue: false,
    ),
    LocalRuleOption(
      id: 'multi_flag',
      label: '다중 깃발',
      description: '한 사람이 여러 깃발 보유 가능',
      defaultValue: false,
    ),
  ];

  /// 게임 타입별 옵션 가져오기
  static List<LocalRuleOption> getOptions(GameType gameType) {
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

/// 자유 입력 로컬 룰 (최대 3개, 각 30자)
class CustomLocalRule {
  final String text;
  final DateTime createdAt;

  CustomLocalRule({
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CustomLocalRule.fromMap(Map<String, dynamic> data) {
    return CustomLocalRule(
      text: data['text'] ?? '',
      createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// 최대 글자수
  static const int maxLength = 30;

  /// 최대 개수
  static const int maxCount = 3;

  /// 유효성 검사
  static bool isValid(String text) {
    return text.isNotEmpty && text.length <= maxLength;
  }
}
