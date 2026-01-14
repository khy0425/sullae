import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ad_service.dart';

/// 광고 상태 관리 Provider
///
/// 핵심 원칙:
/// - 게임 로직은 광고의 존재를 모른다
/// - 광고는 이벤트를 구독하여 스스로 타이밍을 결정한다
/// - 광고 금지 구간을 명확히 정의하고 준수한다
/// - ⚠️ 광고 실패는 스킵한다 (앱 흐름을 막지 않음)
///
/// 광고 금지 구간:
/// - 타이머 진행 중
/// - 라운드 진행 중
/// - 역할 선택/팀 배정 화면
///
/// 광고 허용 구간:
/// - 모임 생성 완료 후
/// - 게임 종료 후
/// - 모임 퇴장 시
/// - 앱 시작 시 (스플래시 후)
///
/// 광고 실패 처리 원칙:
/// - 로드 실패 → 그냥 스킵
/// - show 실패 → 그냥 스킵
/// - 절대 retry loop 금지
/// - 광고는 "보너스"이지 앱 흐름의 필수 단계가 아님
class AdProvider with ChangeNotifier {
  final AdService _adService = AdService();

  // 광고 금지 상태
  bool _isInForbiddenZone = false;
  AdForbiddenReason? _forbiddenReason;

  // 대기 중인 광고
  bool _hasPendingAd = false;

  // 배너 광고 상태
  bool _isBannerVisible = true;

  // 세션 기반 광고 카운트 (로컬 저장)
  static const String _actionCountKey = 'ad_action_count';
  static const int _actionsBeforeAd = 3;
  int _actionCount = 0;

  // Getters
  bool get isInForbiddenZone => _isInForbiddenZone;
  AdForbiddenReason? get forbiddenReason => _forbiddenReason;
  bool get isBannerVisible => _isBannerVisible && !_isInForbiddenZone;

  /// 광고 시스템 초기화
  Future<void> initialize() async {
    await _adService.initialize();
    await _loadActionCount();
  }

  /// 액션 카운트 로드 (앱 재시작 시에도 유지)
  Future<void> _loadActionCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _actionCount = prefs.getInt(_actionCountKey) ?? 0;
      if (kDebugMode) {
        print('AdProvider: Loaded action count: $_actionCount');
      }
    } catch (e) {
      // 로드 실패해도 앱 흐름에 영향 없음
      _actionCount = 0;
    }
  }

  /// 액션 카운트 저장
  Future<void> _saveActionCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_actionCountKey, _actionCount);
    } catch (e) {
      // 저장 실패해도 앱 흐름에 영향 없음
    }
  }

  // ============== 광고 금지 구간 관리 ==============

  /// 금지 구간 진입
  void enterForbiddenZone(AdForbiddenReason reason) {
    _isInForbiddenZone = true;
    _forbiddenReason = reason;
    notifyListeners();
  }

  /// 금지 구간 퇴장
  void exitForbiddenZone() {
    _isInForbiddenZone = false;
    _forbiddenReason = null;
    notifyListeners();

    // 대기 중인 광고가 있으면 표시
    if (_hasPendingAd) {
      _showPendingAd();
    }
  }

  // ============== 이벤트 핸들러 (게임 로직에서 호출하지 않음) ==============

  /// 게임 시작됨 - 금지 구간 진입
  void onGameStarted() {
    enterForbiddenZone(AdForbiddenReason.gameInProgress);
  }

  /// 게임 종료됨 - 광고 표시
  Future<void> onGameEnded() async {
    exitForbiddenZone();
    await _showInterstitialAd();
  }

  /// 역할 선택 화면 진입
  void onRoleSelectionStarted() {
    enterForbiddenZone(AdForbiddenReason.roleSelection);
  }

  /// 팀 배정 화면 진입
  void onTeamAssignmentStarted() {
    enterForbiddenZone(AdForbiddenReason.teamAssignment);
  }

  /// 모임 생성 완료
  Future<void> onMeetingCreated() async {
    await _recordActionAndMaybeShowAd();
  }

  /// 모임 참여 완료
  Future<void> onMeetingJoined() async {
    await _recordActionAndMaybeShowAd();
  }

  /// 모임 퇴장
  Future<void> onMeetingLeft() async {
    if (_isInForbiddenZone) {
      // 게임 중 강제 퇴장이면 금지 구간 해제
      exitForbiddenZone();
    }
    await _recordActionAndMaybeShowAd();
  }

  // ============== 광고 표시 로직 ==============

  /// 액션 카운트 증가 및 조건 충족 시 광고 표시
  Future<void> _recordActionAndMaybeShowAd() async {
    if (_isInForbiddenZone) return;

    _actionCount++;
    await _saveActionCount();

    if (_actionCount >= _actionsBeforeAd) {
      _actionCount = 0;
      await _saveActionCount();
      await _showInterstitialAd();
    }
  }

  Future<void> _showInterstitialAd() async {
    if (_isInForbiddenZone) {
      _hasPendingAd = true;
      return;
    }

    // 광고 실패해도 앱 흐름에 영향 없음 - 그냥 스킵
    try {
      await _adService.showInterstitialAd();
    } catch (e) {
      if (kDebugMode) {
        print('AdProvider: Interstitial ad failed, skipping: $e');
      }
      // 실패해도 retry 없이 그냥 진행
    }
    _hasPendingAd = false;
  }

  Future<void> _showPendingAd() async {
    if (!_hasPendingAd || _isInForbiddenZone) return;

    // 광고 실패해도 앱 흐름에 영향 없음
    try {
      await _adService.showInterstitialAd();
    } catch (e) {
      if (kDebugMode) {
        print('AdProvider: Pending ad failed, skipping: $e');
      }
    }
    _hasPendingAd = false;
  }

  // ============== 배너 광고 관리 ==============

  /// 배너 광고 숨기기 (특정 화면에서)
  void hideBanner() {
    _isBannerVisible = false;
    notifyListeners();
  }

  /// 배너 광고 표시
  void showBanner() {
    _isBannerVisible = true;
    notifyListeners();
  }

  // ============== 리소스 정리 ==============

  void reset() {
    _isInForbiddenZone = false;
    _forbiddenReason = null;
    _hasPendingAd = false;
    _isBannerVisible = true;
    notifyListeners();
  }
}

/// 광고 금지 사유
enum AdForbiddenReason {
  gameInProgress,  // 게임 진행 중 (타이머/라운드)
  roleSelection,   // 역할 선택 중
  teamAssignment,  // 팀 배정 중
}
