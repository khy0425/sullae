import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game_timer_model.dart';

/// 게임 타이머 서비스
///
/// 화면을 보지 않아도 진동으로 시간을 알 수 있는 타이머
class GameTimerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _timersRef => _firestore.collection('game_timers');

  // 로컬 타이머 관리
  Timer? _localTimer;
  final _timerController = StreamController<GameTimer>.broadcast();

  Stream<GameTimer> get localTimerStream => _timerController.stream;

  // ============== 타이머 CRUD ==============

  /// 타이머 생성
  Future<String> createTimer({
    required String meetingId,
    required int totalMinutes,
    List<TimerAlert>? customAlerts,
  }) async {
    final timer = GameTimer.createCustom(
      meetingId,
      totalMinutes,
      alerts: customAlerts,
    );

    final docRef = await _timersRef.add(timer.toFirestore());
    return docRef.id;
  }

  /// 타이머 조회
  Future<GameTimer?> getTimer(String timerId) async {
    final doc = await _timersRef.doc(timerId).get();
    if (doc.exists) {
      return GameTimer.fromFirestore(doc);
    }
    return null;
  }

  /// 모임별 타이머 조회
  Future<GameTimer?> getTimerByMeeting(String meetingId) async {
    final snapshot = await _timersRef
        .where('meetingId', isEqualTo: meetingId)
        .orderBy('startedAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return GameTimer.fromFirestore(snapshot.docs.first);
  }

  /// 타이머 스트림 (실시간)
  Stream<GameTimer?> getTimerStream(String meetingId) {
    return _timersRef
        .where('meetingId', isEqualTo: meetingId)
        .orderBy('startedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return GameTimer.fromFirestore(snapshot.docs.first);
    });
  }

  // ============== 타이머 제어 ==============

  /// 타이머 시작
  Future<void> startTimer(String timerId) async {
    final timer = await getTimer(timerId);
    if (timer == null || timer.status != TimerStatus.ready) return;

    await _timersRef.doc(timerId).update({
      'status': TimerStatus.running.index,
      'startedAt': Timestamp.now(),
    });
  }

  /// 타이머 일시정지
  Future<void> pauseTimer(String timerId) async {
    final timer = await getTimer(timerId);
    if (timer == null || timer.status != TimerStatus.running) return;

    // 실제 남은 시간 계산
    final elapsed = DateTime.now().difference(timer.startedAt!).inSeconds;
    final remaining = timer.remainingSeconds - elapsed;

    await _timersRef.doc(timerId).update({
      'status': TimerStatus.paused.index,
      'remainingSeconds': remaining > 0 ? remaining : 0,
      'pausedAt': Timestamp.now(),
    });
  }

  /// 타이머 재개
  Future<void> resumeTimer(String timerId) async {
    final timer = await getTimer(timerId);
    if (timer == null || timer.status != TimerStatus.paused) return;

    await _timersRef.doc(timerId).update({
      'status': TimerStatus.running.index,
      'startedAt': Timestamp.now(),
      'pausedAt': null,
    });
  }

  /// 타이머 종료
  Future<void> finishTimer(String timerId) async {
    await _timersRef.doc(timerId).update({
      'status': TimerStatus.finished.index,
      'remainingSeconds': 0,
    });
  }

  /// 타이머 리셋
  Future<void> resetTimer(String timerId) async {
    final timer = await getTimer(timerId);
    if (timer == null) return;

    // 알림 트리거 상태 초기화
    final resetAlerts = timer.alerts.map((a) => a.copyWith(triggered: false)).toList();

    await _timersRef.doc(timerId).update({
      'status': TimerStatus.ready.index,
      'remainingSeconds': timer.totalSeconds,
      'startedAt': null,
      'pausedAt': null,
      'alerts': resetAlerts.map((a) => a.toMap()).toList(),
    });
  }

  /// 남은 시간 업데이트 (Firestore 동기화)
  Future<void> updateRemainingTime(String timerId, int remainingSeconds) async {
    await _timersRef.doc(timerId).update({
      'remainingSeconds': remainingSeconds,
    });
  }

  // ============== 알림 처리 ==============

  /// 알림 트리거됨 표시
  Future<void> markAlertTriggered(String timerId, int alertIndex) async {
    final timer = await getTimer(timerId);
    if (timer == null || alertIndex >= timer.alerts.length) return;

    final updatedAlerts = List<TimerAlert>.from(timer.alerts);
    updatedAlerts[alertIndex] = updatedAlerts[alertIndex].copyWith(triggered: true);

    await _timersRef.doc(timerId).update({
      'alerts': updatedAlerts.map((a) => a.toMap()).toList(),
    });
  }

  /// 특정 시간에 발생할 알림 확인
  TimerAlert? checkForAlert(GameTimer timer, int remainingSeconds) {
    for (int i = 0; i < timer.alerts.length; i++) {
      final alert = timer.alerts[i];
      if (!alert.triggered && remainingSeconds <= alert.secondsRemaining) {
        // 알림 범위 내 (2초 오차 허용)
        if (remainingSeconds >= alert.secondsRemaining - 2) {
          return alert;
        }
      }
    }
    return null;
  }

  // ============== 로컬 타이머 (UI용) ==============

  /// 로컬 타이머 시작
  void startLocalTimer(GameTimer timer, {
    required Function(int remaining) onTick,
    required Function(TimerAlert alert) onAlert,
    required Function() onFinished,
  }) {
    stopLocalTimer();

    var remaining = timer.remainingSeconds;
    final alerts = List<TimerAlert>.from(timer.alerts);

    _localTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      remaining--;

      // 알림 체크
      for (int i = 0; i < alerts.length; i++) {
        if (!alerts[i].triggered && remaining <= alerts[i].secondsRemaining) {
          if (remaining >= alerts[i].secondsRemaining - 1) {
            alerts[i] = alerts[i].copyWith(triggered: true);
            onAlert(alerts[i]);
          }
        }
      }

      // 틱 콜백
      onTick(remaining);

      // 타이머 업데이트
      _timerController.add(timer.copyWith(
        remainingSeconds: remaining,
        alerts: alerts,
      ));

      // 종료 체크
      if (remaining <= 0) {
        t.cancel();
        onFinished();
      }
    });
  }

  /// 로컬 타이머 정지
  void stopLocalTimer() {
    _localTimer?.cancel();
    _localTimer = null;
  }

  /// 리소스 해제
  void dispose() {
    stopLocalTimer();
    _timerController.close();
  }

  // ============== 진동 알림 헬퍼 ==============

  /// 알림 진동 실행
  ///
  /// 실제 진동은 Flutter의 vibration 패키지 사용
  /// 이 메서드는 진동 패턴만 반환
  List<int> getVibrationPattern(AlertType alertType) {
    return VibrationPattern.getPattern(alertType);
  }

  /// 진동 가이드 텍스트 생성
  String getVibrationGuideText() {
    return VibrationPattern.guideText;
  }

  /// 특정 알림의 설명
  String getAlertDescription(TimerAlert alert) {
    final vibrationDesc = VibrationPattern.getDescription(alert.type);
    return '${alert.description} ($vibrationDesc)';
  }
}
