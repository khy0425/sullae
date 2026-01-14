import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Firebase Analytics 서비스
/// 사용자 행동 및 앱 사용 패턴 분석
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  /// 사용자 ID 설정 (로그인 시)
  Future<void> setUserId(String? userId) async {
    await _analytics.setUserId(id: userId);
    if (kDebugMode) print('Analytics: setUserId($userId)');
  }

  /// 사용자 속성 설정
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  // ==================== 인증 이벤트 ====================

  /// 회원가입 완료
  Future<void> logSignUp({required String method}) async {
    await _analytics.logSignUp(signUpMethod: method);
    if (kDebugMode) print('Analytics: sign_up($method)');
  }

  /// 로그인
  Future<void> logLogin({required String method}) async {
    await _analytics.logLogin(loginMethod: method);
    if (kDebugMode) print('Analytics: login($method)');
  }

  /// 로그아웃
  Future<void> logLogout() async {
    await _analytics.logEvent(name: 'logout');
    await setUserId(null);
    if (kDebugMode) print('Analytics: logout');
  }

  // ==================== 모임 이벤트 ====================

  /// 모임 생성
  Future<void> logMeetingCreated({
    required String meetingId,
    required String gameType,
    required String region,
    required int maxParticipants,
  }) async {
    await _analytics.logEvent(
      name: 'meeting_created',
      parameters: {
        'meeting_id': meetingId,
        'game_type': gameType,
        'region': region,
        'max_participants': maxParticipants,
      },
    );
    if (kDebugMode) print('Analytics: meeting_created($gameType, $region)');
  }

  /// 모임 참가
  Future<void> logMeetingJoined({
    required String meetingId,
    required String gameType,
  }) async {
    await _analytics.logEvent(
      name: 'meeting_joined',
      parameters: {
        'meeting_id': meetingId,
        'game_type': gameType,
      },
    );
    if (kDebugMode) print('Analytics: meeting_joined($meetingId)');
  }

  /// 모임 퇴장
  Future<void> logMeetingLeft({required String meetingId}) async {
    await _analytics.logEvent(
      name: 'meeting_left',
      parameters: {'meeting_id': meetingId},
    );
    if (kDebugMode) print('Analytics: meeting_left($meetingId)');
  }

  /// 모임 상세 조회
  Future<void> logMeetingViewed({
    required String meetingId,
    required String gameType,
  }) async {
    await _analytics.logEvent(
      name: 'meeting_viewed',
      parameters: {
        'meeting_id': meetingId,
        'game_type': gameType,
      },
    );
  }

  // ==================== 게임 이벤트 ====================

  /// 게임 시작
  Future<void> logGameStarted({
    required String gameId,
    required String gameType,
    required int participantCount,
  }) async {
    await _analytics.logEvent(
      name: 'game_started',
      parameters: {
        'game_id': gameId,
        'game_type': gameType,
        'participant_count': participantCount,
      },
    );
    if (kDebugMode) print('Analytics: game_started($gameType)');
  }

  /// 게임 종료
  Future<void> logGameEnded({
    required String gameId,
    required String gameType,
    required int durationSeconds,
  }) async {
    await _analytics.logEvent(
      name: 'game_ended',
      parameters: {
        'game_id': gameId,
        'game_type': gameType,
        'duration_seconds': durationSeconds,
      },
    );
    if (kDebugMode) print('Analytics: game_ended($gameType, ${durationSeconds}s)');
  }

  // ==================== 소셜 이벤트 ====================

  /// 퀵메시지 전송
  Future<void> logQuickMessageSent({required String messageType}) async {
    await _analytics.logEvent(
      name: 'quick_message_sent',
      parameters: {'message_type': messageType},
    );
  }

  /// 외부 채팅 링크 클릭
  Future<void> logExternalChatOpened() async {
    await _analytics.logEvent(name: 'external_chat_opened');
  }

  /// 디스코드 링크 클릭
  Future<void> logDiscordOpened() async {
    await _analytics.logEvent(name: 'discord_opened');
  }

  // ==================== 수익화 이벤트 ====================

  /// 광고 노출
  Future<void> logAdImpression({required String adType}) async {
    await _analytics.logEvent(
      name: 'ad_impression',
      parameters: {'ad_type': adType},
    );
  }

  /// 후원 시도
  Future<void> logDonationAttempt({required String amount}) async {
    await _analytics.logEvent(
      name: 'donation_attempt',
      parameters: {'amount': amount},
    );
  }

  /// 후원 완료
  Future<void> logDonationComplete({required String amount}) async {
    await _analytics.logEvent(
      name: 'donation_complete',
      parameters: {'amount': amount},
    );
    if (kDebugMode) print('Analytics: donation_complete($amount)');
  }

  // ==================== 필터/검색 이벤트 ====================

  /// 지역 필터 사용
  Future<void> logRegionFilterUsed({required String region}) async {
    await _analytics.logEvent(
      name: 'region_filter_used',
      parameters: {'region': region},
    );
  }

  /// 게임 타입 필터 사용
  Future<void> logGameTypeFilterUsed({required String gameType}) async {
    await _analytics.logEvent(
      name: 'game_type_filter_used',
      parameters: {'game_type': gameType},
    );
  }

  // ==================== 화면 이벤트 ====================

  /// 화면 조회
  Future<void> logScreenView({required String screenName}) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  // ==================== 커스텀 이벤트 ====================

  /// 일반 이벤트 로깅
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    await _analytics.logEvent(name: name, parameters: parameters);
    if (kDebugMode) print('Analytics: $name($parameters)');
  }
}
