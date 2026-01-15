import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/meeting_model.dart';
import '../services/game_service.dart';
import '../services/system_message_service.dart';

/// 게임 진행 상태 관리 Provider
///
/// 역할:
/// - 라운드/타이머 상태 관리
/// - Realtime DB로 상태 동기화
/// - 진동 알림 타이밍 관리
/// - 백그라운드 복귀 시 타이머 보정
///
/// Source of Truth: Realtime DB의 startedAt (서버 타임스탬프)
/// - 클라이언트 시간 오차가 있어도 서버 기준으로 재계산
///
/// MeetingProvider와 분리하여 책임 명확화
class GameFlowProvider with ChangeNotifier {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final GameService _gameService = GameService();
  final SystemMessageService _systemMessageService = SystemMessageService();

  // 게임 상태
  GameFlowState _state = GameFlowState.idle;
  int _currentRound = 1;
  int _totalRounds = 3;
  int _remainingSeconds = 600; // 10분 기본
  int _totalDurationSeconds = 600; // 전체 게임 시간 (서버 기준 재계산용)
  Timer? _timer;
  String? _meetingId;
  String? _sessionId;

  // 팀 배정
  List<TeamAssignment>? _teamAssignments;
  List<ParticipantWithPreference> _participants = [];
  TeamBalanceResult? _balanceResult;

  // Realtime DB 구독
  StreamSubscription? _gameStateSubscription;

  // Getters
  GameFlowState get state => _state;
  int get currentRound => _currentRound;
  int get totalRounds => _totalRounds;
  int get remainingSeconds => _remainingSeconds;
  bool get isGameRunning => _state == GameFlowState.running;
  List<TeamAssignment>? get teamAssignments => _teamAssignments;
  List<ParticipantWithPreference> get participants => _participants;
  TeamBalanceResult? get balanceResult => _balanceResult;

  // 타이머 포맷
  String get formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// 게임 초기화
  void initGame({
    required String meetingId,
    required List<String> participantIds,
    required String hostNickname,
    required GameType gameType,
    int totalRounds = 3,
    int durationMinutes = 10,
  }) {
    _meetingId = meetingId;
    _totalRounds = totalRounds;
    _remainingSeconds = durationMinutes * 60;
    _currentRound = 1;
    _state = GameFlowState.roleSelection;

    // 참가자 초기화
    _participants = participantIds
        .asMap()
        .entries
        .map((e) => ParticipantWithPreference(
              odId: e.value,
              nickname: e.key == 0 ? hostNickname : '참가자 ${e.key + 1}',
              preference: RolePreference.none,
            ))
        .toList();

    _updateBalanceResult(gameType);
    _subscribeToGameState(meetingId);
    notifyListeners();
  }

  /// 역할 선호도 업데이트
  void updatePreference(String odId, RolePreference preference, GameType gameType) {
    final index = _participants.indexWhere((p) => p.odId == odId);
    if (index != -1) {
      _participants[index] = _participants[index].copyWith(preference: preference);
      _updateBalanceResult(gameType);
      notifyListeners();
    }
  }

  void _updateBalanceResult(GameType gameType) {
    _balanceResult = _gameService.checkTeamBalance(
      participants: _participants,
      gameType: gameType,
    );
  }

  /// 팀 배정 진행
  void proceedToTeamAssignment(GameType gameType) {
    _teamAssignments = _gameService.assignTeamsWithPreference(
      participants: _participants,
      gameType: gameType,
    );
    _state = GameFlowState.teamAssignment;
    notifyListeners();
  }

  /// 게임 시작
  Future<void> startGame(GameType gameType) async {
    if (_meetingId == null || _teamAssignments == null) return;

    _state = GameFlowState.running;
    _sessionId = await _gameService.startGameSession(
      meetingId: _meetingId!,
      gameType: gameType,
      teams: _teamAssignments!,
      durationMinutes: _remainingSeconds ~/ 60,
    );

    // 전체 게임 시간 저장 (백그라운드 복귀 시 재계산용)
    _totalDurationSeconds = _remainingSeconds;

    // 시스템 메시지 전송
    await _systemMessageService.sendGameStartMessage(_meetingId!);
    await _systemMessageService.sendRoundStartMessage(_meetingId!, _currentRound);

    // Realtime DB에 게임 상태 저장 (startedAt 포함)
    await _syncGameState(isStart: true);

    // 타이머 시작
    _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        _checkVibrationTiming();
        _syncGameState(); // 1초마다 동기화 (다른 참가자도 보도록)
        notifyListeners();
      } else {
        _onTimerEnd();
      }
    });
  }

  /// 진동 알림 체크 (4가지 패턴)
  void _checkVibrationTiming() {
    final totalDuration = _totalRounds > 0 ? (_remainingSeconds + (_currentRound - 1) * 600) : 600;
    final halfPoint = totalDuration ~/ 2;

    // 절반 지점
    if (_remainingSeconds == halfPoint) {
      _vibrateLong();
    }
    // 1분 전
    else if (_remainingSeconds == 60) {
      _vibrateShort();
    }
  }

  void _vibrateShort() {
    HapticFeedback.lightImpact();
  }

  void _vibrateLong() {
    HapticFeedback.heavyImpact();
  }

  void _onTimerEnd() {
    _timer?.cancel();

    if (_currentRound < _totalRounds) {
      // 다음 라운드로
      _currentRound++;
      _remainingSeconds = 600; // 10분 리셋
      _systemMessageService.sendRoundStartMessage(_meetingId!, _currentRound);
      _startTimer();
    } else {
      // 게임 종료
      endGame();
    }
    notifyListeners();
  }

  /// 게임 종료
  Future<void> endGame() async {
    _timer?.cancel();
    _state = GameFlowState.finished;

    if (_sessionId != null) {
      _gameService.endGameSession(_sessionId!);
    }

    if (_meetingId != null) {
      await _systemMessageService.sendGameEndMessage(_meetingId!);
      await _clearGameState();
    }

    // 광고는 AdProvider가 이벤트를 구독하여 처리
    // 게임 로직은 광고의 존재를 모른다

    notifyListeners();
  }

  /// Realtime DB 동기화
  Future<void> _syncGameState({bool isStart = false}) async {
    if (_meetingId == null) return;

    final data = {
      'status': _state.name,
      'currentRound': _currentRound,
      'totalRounds': _totalRounds,
      'remainingSeconds': _remainingSeconds,
      'totalDurationSeconds': _totalDurationSeconds,
      'updatedAt': ServerValue.timestamp,
    };

    // 게임 시작 시에만 startedAt 설정 (서버 타임스탬프)
    if (isStart) {
      data['startedAt'] = ServerValue.timestamp;
    }

    await _database.ref('meetings/$_meetingId/game_state').update(data);
  }

  Future<void> _clearGameState() async {
    if (_meetingId == null) return;
    await _database.ref('meetings/$_meetingId/game_state').remove();
  }

  /// Realtime DB 구독 (다른 참가자 상태 동기화)
  void _subscribeToGameState(String meetingId) {
    _gameStateSubscription?.cancel();
    _gameStateSubscription = _database
        .ref('meetings/$meetingId/game_state')
        .onValue
        .listen((event) {
      final data = event.snapshot.value;
      if (data == null) return;
      if (data is! Map) return;

      // 다른 기기에서 업데이트된 상태 반영
      final remoteSeconds = data['remainingSeconds'] as int?;
      final remoteRound = data['currentRound'] as int?;

      if (remoteSeconds != null && remoteRound != null) {
        // 차이가 2초 이상이면 동기화 (네트워크 지연 고려)
        if ((_remainingSeconds - remoteSeconds).abs() > 2) {
          _remainingSeconds = remoteSeconds;
          _currentRound = remoteRound;
          notifyListeners();
        }
      }
    });
  }

  /// 백그라운드 복귀 시 타이머 동기화
  ///
  /// WidgetsBindingObserver.didChangeAppLifecycleState에서 호출
  /// AppLifecycleState.resumed일 때 사용
  ///
  /// 서버 타임스탬프(startedAt) 기준으로 남은 시간 재계산
  /// 클라이언트 시간 오차가 있어도 서버 기준으로 보정됨
  Future<void> onAppResumed() async {
    if (_meetingId == null || _state != GameFlowState.running) return;

    try {
      final snapshot = await _database
          .ref('meetings/$_meetingId/game_state')
          .get();

      final data = snapshot.value;
      if (data == null || data is! Map) return;

      final startedAt = data['startedAt'] as int?;
      final totalDuration = data['totalDurationSeconds'] as int?;

      if (startedAt == null || totalDuration == null) return;

      // 서버 시간 기준 경과 시간 계산
      final now = DateTime.now().millisecondsSinceEpoch;
      final elapsed = (now - startedAt) ~/ 1000;
      final newRemaining = max(0, totalDuration - elapsed);

      // 차이가 2초 이상이면 동기화
      if ((_remainingSeconds - newRemaining).abs() > 2) {
        _remainingSeconds = newRemaining;

        // 시간이 0이면 게임 종료 처리
        if (_remainingSeconds <= 0) {
          _onTimerEnd();
        } else {
          notifyListeners();
        }
      }
    } catch (e) {
      // 동기화 실패해도 앱 흐름에 영향 없음
      // 기존 로컬 타이머 계속 사용
    }
  }

  /// 리소스 정리
  void reset() {
    _timer?.cancel();
    _gameStateSubscription?.cancel();
    _state = GameFlowState.idle;
    _currentRound = 1;
    _remainingSeconds = 600;
    _totalDurationSeconds = 600;
    _teamAssignments = null;
    _participants = [];
    _meetingId = null;
    _sessionId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _gameStateSubscription?.cancel();
    super.dispose();
  }
}

/// 게임 진행 상태
enum GameFlowState {
  idle,           // 초기 상태
  roleSelection,  // 역할 선택 중
  teamAssignment, // 팀 배정 중
  running,        // 게임 진행 중
  finished,       // 게임 종료
}
