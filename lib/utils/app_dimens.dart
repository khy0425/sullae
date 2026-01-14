import 'package:flutter/material.dart';

/// 술래 앱 전체에서 사용되는 통일된 간격 및 크기 시스템
///
/// 8의 배수 기반 간격 시스템
class AppDimens {
  AppDimens._();

  // ============== 패딩/마진 ==============

  /// 아주 작은 간격 (4px)
  static const double paddingXS = 4.0;

  /// 작은 간격 (8px)
  static const double paddingS = 8.0;

  /// 중간 간격 (16px) - 기본값
  static const double paddingM = 16.0;

  /// 큰 간격 (24px)
  static const double paddingL = 24.0;

  /// 아주 큰 간격 (32px)
  static const double paddingXL = 32.0;

  /// 화면 기본 수평 패딩 (20px)
  static const double screenPaddingH = 20.0;

  /// 화면 기본 수직 패딩 (16px)
  static const double screenPaddingV = 16.0;

  // ============== 둥근 모서리 ==============

  /// 작은 라운드 (8px)
  static const double radiusS = 8.0;

  /// 중간 라운드 (12px) - 카드 기본값
  static const double radiusM = 12.0;

  /// 큰 라운드 (16px)
  static const double radiusL = 16.0;

  /// 아주 큰 라운드 (24px)
  static const double radiusXL = 24.0;

  /// 완전 둥근 (999px) - 칩, 뱃지용
  static const double radiusFull = 999.0;

  // ============== 버튼 크기 ==============

  /// 작은 버튼 높이 (32px)
  static const double buttonHeightS = 32.0;

  /// 중간 버튼 높이 (44px)
  static const double buttonHeightM = 44.0;

  /// 큰 버튼 높이 (52px) - 기본값
  static const double buttonHeightL = 52.0;

  /// 아주 큰 버튼 높이 (60px)
  static const double buttonHeightXL = 60.0;

  // ============== 아이콘 크기 ==============

  /// 아주 작은 아이콘 (12px)
  static const double iconXS = 12.0;

  /// 작은 아이콘 (16px)
  static const double iconS = 16.0;

  /// 중간 아이콘 (24px) - 기본값
  static const double iconM = 24.0;

  /// 큰 아이콘 (32px)
  static const double iconL = 32.0;

  /// 아주 큰 아이콘 (48px)
  static const double iconXL = 48.0;

  /// 히어로 아이콘 (80px) - 로그인 화면 등
  static const double iconHero = 80.0;

  // ============== 카드/컨테이너 ==============

  /// 카드 기본 패딩 (16px)
  static const double cardPadding = 16.0;

  /// 카드 기본 마진 (8px)
  static const double cardMargin = 8.0;

  /// 카드 기본 높이 (최소값)
  static const double cardMinHeight = 80.0;

  /// 리스트 아이템 높이
  static const double listItemHeight = 56.0;

  /// 모임 카드 높이
  static const double meetingCardHeight = 180.0;

  // ============== 앱바/네비게이션 ==============

  /// 앱바 높이
  static const double appBarHeight = 56.0;

  /// 바텀 네비게이션 높이
  static const double bottomNavHeight = 60.0;

  /// 탭바 높이
  static const double tabBarHeight = 48.0;

  /// FAB 여유 공간
  static const double fabSpacing = 80.0;

  // ============== 그림자 ==============

  /// 작은 그림자
  static const double elevationS = 2.0;

  /// 중간 그림자
  static const double elevationM = 4.0;

  /// 큰 그림자
  static const double elevationL = 8.0;

  // ============== 게임 관련 ==============

  /// 타이머 높이
  static const double timerHeight = 200.0;

  /// 팀 카드 패딩
  static const double teamCardPadding = 12.0;

  /// 아바타 크기 (작음)
  static const double avatarS = 24.0;

  /// 아바타 크기 (중간)
  static const double avatarM = 40.0;

  /// 아바타 크기 (큼)
  static const double avatarL = 100.0;

  // ============== 헬퍼 메서드 ==============

  /// 기본 화면 패딩
  static EdgeInsets get screenPadding => const EdgeInsets.symmetric(
        horizontal: screenPaddingH,
        vertical: screenPaddingV,
      );

  /// 카드 기본 패딩
  static EdgeInsets get cardPaddingAll => const EdgeInsets.all(cardPadding);

  /// 수평 패딩
  static EdgeInsets paddingHorizontal(double value) =>
      EdgeInsets.symmetric(horizontal: value);

  /// 수직 패딩
  static EdgeInsets paddingVertical(double value) =>
      EdgeInsets.symmetric(vertical: value);

  /// 전방향 패딩
  static EdgeInsets paddingAll(double value) => EdgeInsets.all(value);

  /// 카드 BorderRadius
  static BorderRadius get cardBorderRadius =>
      const BorderRadius.all(Radius.circular(radiusL));

  /// 버튼 BorderRadius
  static BorderRadius get buttonBorderRadius =>
      const BorderRadius.all(Radius.circular(radiusM));

  /// 칩/뱃지 BorderRadius
  static BorderRadius get chipBorderRadius =>
      const BorderRadius.all(Radius.circular(radiusFull));

  /// 채팅 버블 BorderRadius
  static BorderRadius get chatBubbleBorderRadius =>
      const BorderRadius.all(Radius.circular(radiusL));
}
