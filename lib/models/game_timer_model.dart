import 'package:cloud_firestore/cloud_firestore.dart';

/// 게임 타이머 모델
///
/// 게임 진행 시간을 관리하고 진동 알림을 설정
class GameTimer {
  final String id;
  final String meetingId;
  final int totalSeconds;          // 전체 시간 (초)
  final int remainingSeconds;      // 남은 시간 (초)
  final TimerStatus status;        // 타이머 상태
  final DateTime? startedAt;       // 시작 시간
  final DateTime? pausedAt;        // 일시정지 시간
  final List<TimerAlert> alerts;   // 알림 설정

  GameTimer({
    required this.id,
    required this.meetingId,
    required this.totalSeconds,
    required this.remainingSeconds,
    this.status = TimerStatus.ready,
    this.startedAt,
    this.pausedAt,
    this.alerts = const [],
  });

  factory GameTimer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GameTimer(
      id: doc.id,
      meetingId: data['meetingId'] ?? '',
      totalSeconds: data['totalSeconds'] ?? 600,
      remainingSeconds: data['remainingSeconds'] ?? 600,
      status: TimerStatus.values[data['status'] ?? 0],
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      pausedAt: (data['pausedAt'] as Timestamp?)?.toDate(),
      alerts: (data['alerts'] as List<dynamic>?)
              ?.map((a) => TimerAlert.fromMap(a))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'meetingId': meetingId,
      'totalSeconds': totalSeconds,
      'remainingSeconds': remainingSeconds,
      'status': status.index,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'pausedAt': pausedAt != null ? Timestamp.fromDate(pausedAt!) : null,
      'alerts': alerts.map((a) => a.toMap()).toList(),
    };
  }

  GameTimer copyWith({
    int? remainingSeconds,
    TimerStatus? status,
    DateTime? startedAt,
    DateTime? pausedAt,
    List<TimerAlert>? alerts,
  }) {
    return GameTimer(
      id: id,
      meetingId: meetingId,
      totalSeconds: totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      pausedAt: pausedAt ?? this.pausedAt,
      alerts: alerts ?? this.alerts,
    );
  }

  /// 분:초 형식으로 변환
  String get formattedTime {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// 진행률 (0.0 ~ 1.0)
  double get progress =>
      totalSeconds > 0 ? (totalSeconds - remainingSeconds) / totalSeconds : 0;

  /// 남은 진행률 (0.0 ~ 1.0)
  double get remainingProgress =>
      totalSeconds > 0 ? remainingSeconds / totalSeconds : 1;

  /// 실행 중인지 여부
  bool get isRunning => status == TimerStatus.running;

  /// 종료되었는지 여부
  bool get isFinished => status == TimerStatus.finished;

  /// 기본 타이머 생성 (10분)
  static GameTimer createDefault(String meetingId) {
    return GameTimer(
      id: '',
      meetingId: meetingId,
      totalSeconds: 600, // 10분
      remainingSeconds: 600,
      alerts: TimerAlert.defaultAlerts,
    );
  }

  /// 커스텀 타이머 생성
  static GameTimer createCustom(
    String meetingId,
    int minutes, {
    List<TimerAlert>? alerts,
  }) {
    final seconds = minutes * 60;
    return GameTimer(
      id: '',
      meetingId: meetingId,
      totalSeconds: seconds,
      remainingSeconds: seconds,
      alerts: alerts ?? TimerAlert.createDefaultAlerts(minutes),
    );
  }
}

/// 타이머 상태
enum TimerStatus {
  ready,    // 준비됨 (시작 전)
  running,  // 실행 중
  paused,   // 일시정지
  finished, // 종료
}

/// 타이머 알림 설정
///
/// 특정 시점에 진동으로 알림
class TimerAlert {
  final int secondsRemaining;      // 남은 시간 (초)
  final AlertType type;            // 알림 타입
  final bool triggered;            // 이미 발생했는지

  TimerAlert({
    required this.secondsRemaining,
    required this.type,
    this.triggered = false,
  });

  Map<String, dynamic> toMap() => {
        'secondsRemaining': secondsRemaining,
        'type': type.index,
        'triggered': triggered,
      };

  factory TimerAlert.fromMap(Map<String, dynamic> data) {
    return TimerAlert(
      secondsRemaining: data['secondsRemaining'] ?? 0,
      type: AlertType.values[data['type'] ?? 0],
      triggered: data['triggered'] ?? false,
    );
  }

  TimerAlert copyWith({bool? triggered}) {
    return TimerAlert(
      secondsRemaining: secondsRemaining,
      type: type,
      triggered: triggered ?? this.triggered,
    );
  }

  /// 알림 설명
  String get description {
    if (secondsRemaining == 0) return '게임 종료';

    final minutes = secondsRemaining ~/ 60;
    final seconds = secondsRemaining % 60;

    if (minutes > 0 && seconds == 0) {
      return '$minutes분 남음';
    } else if (minutes > 0) {
      return '$minutes분 $seconds초 남음';
    } else {
      return '$seconds초 남음';
    }
  }

  /// 기본 알림 설정 (10분 기준)
  ///
  /// 단순화된 4단계 알림:
  /// - 절반: 길게 1번
  /// - 1분 전: 짧게 1번
  /// - 종료: 길게 2번
  static List<TimerAlert> get defaultAlerts => [
        TimerAlert(secondsRemaining: 300, type: AlertType.halfTime),  // 5분 남음 (절반)
        TimerAlert(secondsRemaining: 60, type: AlertType.oneMinute),  // 1분 남음
        TimerAlert(secondsRemaining: 0, type: AlertType.finished),    // 종료
      ];

  /// 커스텀 시간에 맞는 알림 생성
  ///
  /// 모든 게임에서 동일한 패턴 사용
  static List<TimerAlert> createDefaultAlerts(int totalMinutes) {
    final alerts = <TimerAlert>[];

    // 절반 시점 알림 (1분 이상일 때만)
    final halfTimeSeconds = (totalMinutes * 60) ~/ 2;
    if (halfTimeSeconds > 60) {
      alerts.add(TimerAlert(secondsRemaining: halfTimeSeconds, type: AlertType.halfTime));
    }

    // 1분 전 (1분 이상일 때만)
    if (totalMinutes > 1) {
      alerts.add(TimerAlert(secondsRemaining: 60, type: AlertType.oneMinute));
    }

    // 종료
    alerts.add(TimerAlert(secondsRemaining: 0, type: AlertType.finished));

    return alerts;
  }
}

/// 알림 타입
///
/// 모든 게임에서 동일한 패턴 사용 (학습 비용 최소화)
/// 한 번 배우면 모든 게임에 적용 가능
enum AlertType {
  gameStart,      // 게임 시작
  halfTime,       // 절반
  oneMinute,      // 1분 전
  finished,       // 종료
  custom,         // 커스텀
}

/// 알림 타입별 진동 패턴
///
/// 통일된 진동 언어:
/// - 시작: 짧게 2번 ━ ━
/// - 절반: 길게 1번 ━━━
/// - 1분 전: 짧게 1번 ━
/// - 종료: 길게 2번 ━━━ ━━━
///
/// 원칙: 게임마다 다르게 하지 않는다
/// "진동 = 시간" 이라는 단일 개념
class VibrationPattern {
  /// 게임 시작: 짧게 2번 ━ ━
  static const gameStart = [200, 150, 200];

  /// 절반 지점: 길게 1번 ━━━
  static const halfTime = [500];

  /// 1분 전: 짧게 1번 ━
  static const oneMinute = [200];

  /// 게임 종료: 길게 2번 ━━━ ━━━
  static const finished = [500, 200, 500];

  /// 알림 타입에 맞는 진동 패턴 가져오기
  static List<int> getPattern(AlertType type) {
    switch (type) {
      case AlertType.gameStart:
        return gameStart;
      case AlertType.halfTime:
        return halfTime;
      case AlertType.oneMinute:
        return oneMinute;
      case AlertType.finished:
        return finished;
      case AlertType.custom:
        return [300]; // 기본값
    }
  }

  /// 알림 타입 설명
  static String getDescription(AlertType type) {
    switch (type) {
      case AlertType.gameStart:
        return '짧게 2번 (시작)';
      case AlertType.halfTime:
        return '길게 1번 (절반)';
      case AlertType.oneMinute:
        return '짧게 1번 (1분 전)';
      case AlertType.finished:
        return '길게 2번 (종료)';
      case AlertType.custom:
        return '커스텀 진동';
    }
  }

  /// 진동 가이드 텍스트 (사용자 안내용)
  static String get guideText => '''
📳 진동 알림 패턴

시작    →  짧게 2번  ━ ━
절반    →  길게 1번  ━━━
1분 전  →  짧게 1번  ━
종료    →  길게 2번  ━━━ ━━━

모든 게임에서 동일한 패턴이에요.
한 번 익히면 어떤 게임이든 적용됩니다!
''';
}
