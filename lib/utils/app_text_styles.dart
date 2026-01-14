import 'package:flutter/material.dart';
import 'app_theme.dart';

/// 술래 앱 전체에서 사용되는 통일된 텍스트 스타일 시스템
///
/// 사용 예시:
/// ```dart
/// Text('모임 제목', style: AppTextStyles.titleLarge(context))
/// Text('설명', style: AppTextStyles.body(context))
/// ```
class AppTextStyles {
  AppTextStyles._();

  // ============== 제목 스타일 ==============

  /// 대형 제목 (24px, bold)
  /// 화면 타이틀, 주요 섹션 헤더
  static TextStyle titleLarge(BuildContext context) {
    return const TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
      height: 1.3,
    );
  }

  /// 중형 제목 (20px, bold)
  /// 카드 타이틀, 섹션 헤더
  static TextStyle titleMedium(BuildContext context) {
    return const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
      height: 1.3,
    );
  }

  /// 소형 제목 (16px, w600)
  /// 리스트 아이템 타이틀, 서브 헤더
  static TextStyle titleSmall(BuildContext context) {
    return const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      height: 1.4,
    );
  }

  // ============== 본문 스타일 ==============

  /// 대형 본문 (16px, normal)
  /// 주요 설명 텍스트
  static TextStyle bodyLarge(BuildContext context) {
    return const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: AppColors.textPrimary,
      height: 1.5,
    );
  }

  /// 중형 본문 (14px, normal) - 기본 본문
  /// 일반 텍스트, 설명
  static TextStyle body(BuildContext context) {
    return const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: AppColors.textPrimary,
      height: 1.5,
    );
  }

  /// 소형 본문 (13px, normal)
  /// 보조 설명, 힌트 텍스트
  static TextStyle bodySmall(BuildContext context) {
    return const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.normal,
      color: AppColors.textSecondary,
      height: 1.5,
    );
  }

  // ============== 레이블 스타일 ==============

  /// 대형 레이블 (14px, w500)
  /// 버튼 텍스트, 탭 라벨
  static TextStyle labelLarge(BuildContext context) {
    return const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary,
      height: 1.4,
    );
  }

  /// 중형 레이블 (12px, w500)
  /// 뱃지, 칩 텍스트
  static TextStyle label(BuildContext context) {
    return const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary,
      height: 1.3,
    );
  }

  /// 소형 레이블 (10px, w500)
  /// 작은 뱃지, 캡션
  static TextStyle labelSmall(BuildContext context) {
    return const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
      height: 1.3,
    );
  }

  // ============== 특수 스타일 ==============

  /// 강조 텍스트 (primary color)
  static TextStyle accent(BuildContext context, {double fontSize = 14}) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: AppColors.primary,
      height: 1.4,
    );
  }

  /// 성공 텍스트 (success color)
  static TextStyle success(BuildContext context, {double fontSize = 14}) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      color: AppColors.success,
      height: 1.4,
    );
  }

  /// 경고 텍스트 (warning color)
  static TextStyle warning(BuildContext context, {double fontSize = 14}) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      color: AppColors.warning,
      height: 1.4,
    );
  }

  /// 에러 텍스트 (error color)
  static TextStyle error(BuildContext context, {double fontSize = 14}) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      color: AppColors.error,
      height: 1.4,
    );
  }

  /// 카운터 숫자 (큰 숫자 표시용)
  static TextStyle counter(BuildContext context) {
    return const TextStyle(
      fontSize: 48,
      fontWeight: FontWeight.bold,
      color: AppColors.primary,
      height: 1.0,
    );
  }

  /// 타이머 숫자 (게임 시간용)
  static TextStyle timer(BuildContext context) {
    return const TextStyle(
      fontSize: 72,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      height: 1.0,
      fontFeatures: [FontFeature.tabularFigures()],
    );
  }

  /// 팀 이름 표시
  static TextStyle teamName(BuildContext context, Color teamColor) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: teamColor,
      height: 1.3,
    );
  }

  /// 투명도 적용된 본문 (70% opacity)
  static TextStyle bodyOpacity(BuildContext context) {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: AppColors.textPrimary.withValues(alpha: 0.7),
      height: 1.5,
    );
  }
}
