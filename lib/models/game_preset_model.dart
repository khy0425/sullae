import 'package:cloud_firestore/cloud_firestore.dart';
import 'meeting_model.dart';

/// 게임 룰 프리셋
///
/// 커스텀 게임 룰을 저장하고 재사용할 수 있는 모델
/// 예: "우리 동네 경찰과 도둑 룰", "러닝용 깃발뺏기"
class GamePreset {
  final String id;
  final String name;
  final String? description;
  final String creatorId;
  final String creatorNickname;
  final GameType baseGameType;
  final Map<String, dynamic> rules;
  final bool isPublic;
  final int usageCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  GamePreset({
    required this.id,
    required this.name,
    this.description,
    required this.creatorId,
    required this.creatorNickname,
    required this.baseGameType,
    required this.rules,
    this.isPublic = false,
    this.usageCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  factory GamePreset.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GamePreset(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      creatorId: data['creatorId'] ?? '',
      creatorNickname: data['creatorNickname'] ?? '',
      baseGameType: GameType.values[data['baseGameType'] ?? 0],
      rules: Map<String, dynamic>.from(data['rules'] ?? {}),
      isPublic: data['isPublic'] ?? false,
      usageCount: data['usageCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'creatorId': creatorId,
      'creatorNickname': creatorNickname,
      'baseGameType': baseGameType.index,
      'rules': rules,
      'isPublic': isPublic,
      'usageCount': usageCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  GamePreset copyWith({
    String? name,
    String? description,
    GameType? baseGameType,
    Map<String, dynamic>? rules,
    bool? isPublic,
    int? usageCount,
  }) {
    return GamePreset(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      creatorId: creatorId,
      creatorNickname: creatorNickname,
      baseGameType: baseGameType ?? this.baseGameType,
      rules: rules ?? this.rules,
      isPublic: isPublic ?? this.isPublic,
      usageCount: usageCount ?? this.usageCount,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// 기본 프리셋 생성
  static GamePreset createDefault({
    required String creatorId,
    required String creatorNickname,
    required GameType gameType,
    required String name,
  }) {
    return GamePreset(
      id: '',
      name: name,
      creatorId: creatorId,
      creatorNickname: creatorNickname,
      baseGameType: gameType,
      rules: _getDefaultRules(gameType),
      createdAt: DateTime.now(),
    );
  }

  static Map<String, dynamic> _getDefaultRules(GameType gameType) {
    switch (gameType) {
      case GameType.copsAndRobbers:
        return CopsAndRobbersRules.defaultRules.toMap();
      case GameType.freezeTag:
        return FreezeTagRules.defaultRules.toMap();
      case GameType.hideAndSeek:
        return HideAndSeekRules.defaultRules.toMap();
      case GameType.captureFlag:
        return CaptureFlagRules.defaultRules.toMap();
      case GameType.custom:
        return {};
    }
  }
}

// ============== 게임별 룰 클래스 ==============

/// 경찰과 도둑 룰
class CopsAndRobbersRules {
  final int roundTimeMinutes;      // 라운드 시간 (분)
  final String? jailLocation;      // 감옥 위치
  final RescueMethod rescueMethod; // 구출 방법
  final double copRatio;           // 경찰 비율 (0.3 = 30%)
  final bool allowJailbreak;       // 탈옥 허용 여부

  CopsAndRobbersRules({
    this.roundTimeMinutes = 15,
    this.jailLocation,
    this.rescueMethod = RescueMethod.touch,
    this.copRatio = 0.5,
    this.allowJailbreak = true,
  });

  static CopsAndRobbersRules get defaultRules => CopsAndRobbersRules();

  Map<String, dynamic> toMap() => {
    'roundTimeMinutes': roundTimeMinutes,
    'jailLocation': jailLocation,
    'rescueMethod': rescueMethod.index,
    'copRatio': copRatio,
    'allowJailbreak': allowJailbreak,
  };

  factory CopsAndRobbersRules.fromMap(Map<String, dynamic> data) {
    return CopsAndRobbersRules(
      roundTimeMinutes: data['roundTimeMinutes'] ?? 15,
      jailLocation: data['jailLocation'],
      rescueMethod: RescueMethod.values[data['rescueMethod'] ?? 0],
      copRatio: (data['copRatio'] ?? 0.5).toDouble(),
      allowJailbreak: data['allowJailbreak'] ?? true,
    );
  }
}

enum RescueMethod {
  touch,    // 터치
  highFive, // 하이파이브
  crawl,    // 가랑이 사이로 통과
}

/// 얼음땡 룰
class FreezeTagRules {
  final int roundTimeMinutes;
  final int seekerCount;           // 술래 수
  final int unfreezeSeconds;       // 해동 시간 (초)
  final UnfreezeMethod unfreezeMethod;
  final bool canSelfUnfreeze;      // 자가 해동 가능

  FreezeTagRules({
    this.roundTimeMinutes = 10,
    this.seekerCount = 1,
    this.unfreezeSeconds = 3,
    this.unfreezeMethod = UnfreezeMethod.touch,
    this.canSelfUnfreeze = false,
  });

  static FreezeTagRules get defaultRules => FreezeTagRules();

  Map<String, dynamic> toMap() => {
    'roundTimeMinutes': roundTimeMinutes,
    'seekerCount': seekerCount,
    'unfreezeSeconds': unfreezeSeconds,
    'unfreezeMethod': unfreezeMethod.index,
    'canSelfUnfreeze': canSelfUnfreeze,
  };

  factory FreezeTagRules.fromMap(Map<String, dynamic> data) {
    return FreezeTagRules(
      roundTimeMinutes: data['roundTimeMinutes'] ?? 10,
      seekerCount: data['seekerCount'] ?? 1,
      unfreezeSeconds: data['unfreezeSeconds'] ?? 3,
      unfreezeMethod: UnfreezeMethod.values[data['unfreezeMethod'] ?? 0],
      canSelfUnfreeze: data['canSelfUnfreeze'] ?? false,
    );
  }
}

enum UnfreezeMethod {
  touch,     // 터치
  hold,      // 5초 터치
  crawl,     // 가랑이 통과
  highFive,  // 하이파이브
}

/// 숨바꼭질 룰
class HideAndSeekRules {
  final int roundTimeMinutes;
  final int seekerCount;
  final int hideTimeSeconds;       // 숨는 시간 (초)
  final bool seekerCanRun;         // 술래 뛰기 가능

  HideAndSeekRules({
    this.roundTimeMinutes = 15,
    this.seekerCount = 1,
    this.hideTimeSeconds = 60,
    this.seekerCanRun = true,
  });

  static HideAndSeekRules get defaultRules => HideAndSeekRules();

  Map<String, dynamic> toMap() => {
    'roundTimeMinutes': roundTimeMinutes,
    'seekerCount': seekerCount,
    'hideTimeSeconds': hideTimeSeconds,
    'seekerCanRun': seekerCanRun,
  };

  factory HideAndSeekRules.fromMap(Map<String, dynamic> data) {
    return HideAndSeekRules(
      roundTimeMinutes: data['roundTimeMinutes'] ?? 15,
      seekerCount: data['seekerCount'] ?? 1,
      hideTimeSeconds: data['hideTimeSeconds'] ?? 60,
      seekerCanRun: data['seekerCanRun'] ?? true,
    );
  }
}

/// 깃발뺏기 룰
class CaptureFlagRules {
  final int roundTimeMinutes;
  final int flagCount;             // 깃발 수
  final bool useGpsArea;           // GPS 영역 사용
  final bool canTagInOwnArea;      // 자기 진영에서 태그 가능

  CaptureFlagRules({
    this.roundTimeMinutes = 20,
    this.flagCount = 1,
    this.useGpsArea = false,
    this.canTagInOwnArea = false,
  });

  static CaptureFlagRules get defaultRules => CaptureFlagRules();

  Map<String, dynamic> toMap() => {
    'roundTimeMinutes': roundTimeMinutes,
    'flagCount': flagCount,
    'useGpsArea': useGpsArea,
    'canTagInOwnArea': canTagInOwnArea,
  };

  factory CaptureFlagRules.fromMap(Map<String, dynamic> data) {
    return CaptureFlagRules(
      roundTimeMinutes: data['roundTimeMinutes'] ?? 20,
      flagCount: data['flagCount'] ?? 1,
      useGpsArea: data['useGpsArea'] ?? false,
      canTagInOwnArea: data['canTagInOwnArea'] ?? false,
    );
  }
}
