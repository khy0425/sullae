import 'dart:ui';
import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

/// 다양한 스타일의 카드를 일관되게 사용할 수 있는 시스템
enum AppCardVariant {
  content,   // 기본 콘텐츠 카드
  highlight, // 강조 카드 (그라데이션)
  glass,     // 유리 카드 (Glassmorphism)
  outline,   // 아웃라인 카드
  flat,      // 플랫 카드 (그림자 없음)
  team,      // 팀 카드 (게임용)
}

class AppCard extends StatelessWidget {
  final Widget child;
  final AppCardVariant variant;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderWidth;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double? elevation;
  final List<Color>? gradientColors;
  final double blurAmount;

  const AppCard({
    super.key,
    required this.child,
    this.variant = AppCardVariant.content,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.padding,
    this.margin,
    this.onTap,
    this.elevation,
    this.gradientColors,
    this.blurAmount = 10,
  });

  /// 기본 콘텐츠 카드
  factory AppCard.content({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
  }) {
    return AppCard(
      variant: AppCardVariant.content,
      padding: padding,
      margin: margin,
      onTap: onTap,
      child: child,
    );
  }

  /// 강조 카드 (그라데이션 배경)
  factory AppCard.highlight({
    required Widget child,
    List<Color>? gradientColors,
    EdgeInsetsGeometry? padding,
    VoidCallback? onTap,
  }) {
    return AppCard(
      variant: AppCardVariant.highlight,
      gradientColors: gradientColors ?? [AppColors.primary, AppColors.primaryDark],
      padding: padding,
      onTap: onTap,
      child: child,
    );
  }

  /// 유리 카드 (Glassmorphism)
  factory AppCard.glass({
    required Widget child,
    double blurAmount = 10,
    EdgeInsetsGeometry? padding,
    VoidCallback? onTap,
  }) {
    return AppCard(
      variant: AppCardVariant.glass,
      blurAmount: blurAmount,
      padding: padding,
      onTap: onTap,
      child: child,
    );
  }

  /// 아웃라인 카드
  factory AppCard.outline({
    required Widget child,
    Color? borderColor,
    EdgeInsetsGeometry? padding,
    VoidCallback? onTap,
  }) {
    return AppCard(
      variant: AppCardVariant.outline,
      borderColor: borderColor,
      padding: padding,
      onTap: onTap,
      child: child,
    );
  }

  /// 플랫 카드 (그림자 없음)
  factory AppCard.flat({
    required Widget child,
    Color? backgroundColor,
    EdgeInsetsGeometry? padding,
    VoidCallback? onTap,
  }) {
    return AppCard(
      variant: AppCardVariant.flat,
      backgroundColor: backgroundColor,
      padding: padding,
      onTap: onTap,
      child: child,
    );
  }

  /// 팀 카드 (게임용)
  factory AppCard.team({
    required Widget child,
    required Color teamColor,
    EdgeInsetsGeometry? padding,
    VoidCallback? onTap,
  }) {
    return AppCard(
      variant: AppCardVariant.team,
      backgroundColor: teamColor.withValues(alpha: 0.1),
      borderColor: teamColor.withValues(alpha: 0.3),
      padding: padding,
      onTap: onTap,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? AppDimens.cardPaddingAll;
    final effectiveBorderRadius = borderRadius ?? AppDimens.cardBorderRadius;

    Widget cardContent = Padding(
      padding: effectivePadding,
      child: child,
    );

    switch (variant) {
      case AppCardVariant.content:
        return _buildContentCard(cardContent, effectiveBorderRadius);
      case AppCardVariant.highlight:
        return _buildHighlightCard(cardContent, effectiveBorderRadius);
      case AppCardVariant.glass:
        return _buildGlassCard(cardContent, effectiveBorderRadius);
      case AppCardVariant.outline:
        return _buildOutlineCard(cardContent, effectiveBorderRadius);
      case AppCardVariant.flat:
        return _buildFlatCard(cardContent, effectiveBorderRadius);
      case AppCardVariant.team:
        return _buildTeamCard(cardContent, effectiveBorderRadius);
    }
  }

  Widget _buildContentCard(Widget content, BorderRadius radius) {
    return Container(
      margin: margin,
      child: Material(
        color: backgroundColor ?? AppColors.surface,
        elevation: elevation ?? AppDimens.elevationS,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: content,
        ),
      ),
    );
  }

  Widget _buildHighlightCard(Widget content, BorderRadius radius) {
    final colors = gradientColors ?? [AppColors.primary, AppColors.primaryDark];

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: content,
        ),
      ),
    );
  }

  Widget _buildGlassCard(Widget content, BorderRadius radius) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: radius,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: radius,
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutlineCard(Widget content, BorderRadius radius) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.transparent,
        borderRadius: radius,
        border: Border.all(
          color: borderColor ?? AppColors.divider,
          width: borderWidth ?? 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: content,
        ),
      ),
    );
  }

  Widget _buildFlatCard(Widget content, BorderRadius radius) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.background,
        borderRadius: radius,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: content,
        ),
      ),
    );
  }

  Widget _buildTeamCard(Widget content, BorderRadius radius) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: radius,
        border: Border.all(
          color: borderColor ?? AppColors.divider,
          width: borderWidth ?? 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: content,
        ),
      ),
    );
  }
}
