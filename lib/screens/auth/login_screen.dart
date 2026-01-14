import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import 'nickname_screen.dart';

/// 로그인 화면
///
/// 30초 회원가입 철학:
/// 소셜 로그인 버튼만 → 원터치로 시작
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String? _loadingProvider;

  Future<void> _signIn(String provider) async {
    setState(() {
      _isLoading = true;
      _loadingProvider = provider;
    });

    final authProvider = context.read<AuthProvider>();

    // 소셜 로그인 수행
    AuthResult result;
    switch (provider) {
      case 'google':
        result = await authProvider.signInWithGoogle();
        break;
      case 'apple':
        result = await authProvider.signInWithApple();
        break;
      case 'kakao':
      default:
        result = await authProvider.signInWithKakao();
        break;
    }

    if (!mounted) return;

    if (result.success) {
      // 신규 사용자면 닉네임 설정으로
      if (result.isNewUser) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => NicknameScreen(provider: provider),
          ),
        );
      }
      // 기존 사용자는 자동으로 홈으로 이동 (AuthProvider가 처리)
    } else if (result.cancelled) {
      // 취소된 경우 아무것도 하지 않음
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? '로그인에 실패했습니다.')),
      );
    }

    setState(() {
      _isLoading = false;
      _loadingProvider = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppDimens.screenPadding,
          child: Column(
            children: [
              const Spacer(flex: 2),

              // 로고 & 타이틀
              _buildHeader(context, l10n),

              const SizedBox(height: AppDimens.paddingXL),

              // 게임 타입 아이콘들
              _buildGameTypes(context, l10n),

              const Spacer(flex: 2),

              // 소셜 로그인 버튼들
              _buildSocialButtons(context, l10n),

              const SizedBox(height: AppDimens.paddingL),

              // 개인정보 동의 안내
              _buildTermsNotice(context, l10n),

              const SizedBox(height: AppDimens.paddingXL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        Icon(
          Icons.directions_run,
          size: AppDimens.iconXXL + 16,
          color: AppColors.primary,
        ),
        const SizedBox(height: AppDimens.paddingM),
        Text(
          l10n.appName,
          style: AppTextStyles.titleLarge(context).copyWith(
            fontSize: 32,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppDimens.paddingS),
        Text(
          l10n.appTagline,
          style: AppTextStyles.bodyLarge(context).copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildGameTypes(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _GameTypeChip(
              icon: GameIcons.police,
              label: l10n.gameCopsAndRobbers,
              color: AppColors.copsAndRobbers,
            ),
            const SizedBox(width: AppDimens.paddingM),
            _GameTypeChip(
              icon: GameIcons.freeze,
              label: l10n.gameFreezeTag,
              color: AppColors.freezeTag,
            ),
          ],
        ),
        const SizedBox(height: AppDimens.paddingM),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _GameTypeChip(
              icon: GameIcons.hider,
              label: l10n.gameHideAndSeek,
              color: AppColors.hideAndSeek,
            ),
            const SizedBox(width: AppDimens.paddingM),
            _GameTypeChip(
              icon: Icons.flag,
              label: l10n.gameCaptureFlag,
              color: AppColors.captureFlag,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButtons(BuildContext context, AppLocalizations l10n) {
    final lastProvider = context.watch<AuthProvider>().lastLoginProvider;

    return Column(
      children: [
        // 카카오 로그인
        _SocialLoginButton(
          onPressed: _isLoading ? null : () => _signIn('kakao'),
          svgAsset: 'assets/icons/kakao_logo.svg',
          label: l10n.loginWithKakao,
          backgroundColor: const Color(0xFFFEE500),
          textColor: const Color(0xFF191919),
          iconColor: const Color(0xFF000000),
          isLoading: _loadingProvider == 'kakao',
          isLastUsed: lastProvider == LoginProvider.kakao,
        ),
        const SizedBox(height: AppDimens.paddingM),

        // Google 로그인
        _SocialLoginButton(
          onPressed: _isLoading ? null : () => _signIn('google'),
          svgAsset: 'assets/icons/google_logo.svg',
          label: l10n.loginWithGoogle,
          backgroundColor: AppColors.surface,
          textColor: AppColors.textPrimary,
          borderColor: AppColors.border,
          isLoading: _loadingProvider == 'google',
          isLastUsed: lastProvider == LoginProvider.google,
        ),

        // Apple 로그인 - iOS 앱 출시 후 활성화 예정
        // const SizedBox(height: AppDimens.paddingM),
        // _SocialLoginButton(
        //   onPressed: _isLoading ? null : () => _signIn('apple'),
        //   svgAsset: 'assets/icons/apple_logo.svg',
        //   label: l10n.loginWithApple,
        //   backgroundColor: AppColors.textPrimary,
        //   textColor: AppColors.surface,
        //   isLoading: _loadingProvider == 'apple',
        //   isLastUsed: lastProvider == LoginProvider.apple,
        // ),
      ],
    );
  }

  Widget _buildTermsNotice(BuildContext context, AppLocalizations l10n) {
    return Text(
      l10n.termsNotice,
      style: AppTextStyles.bodySmall(context),
      textAlign: TextAlign.center,
    );
  }
}

/// 게임 타입 칩
class _GameTypeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _GameTypeChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimens.paddingM,
        vertical: AppDimens.paddingS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppDimens.chipBorderRadius,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppDimens.iconS, color: color),
          const SizedBox(width: AppDimens.paddingS),
          Text(
            label,
            style: AppTextStyles.label(context).copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// 소셜 로그인 버튼
class _SocialLoginButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String svgAsset;
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final Color? iconColor;
  final bool isLoading;
  final bool isLastUsed;

  const _SocialLoginButton({
    required this.onPressed,
    required this.svgAsset,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
    this.iconColor,
    this.isLoading = false,
    this.isLastUsed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          width: double.infinity,
          height: AppDimens.buttonHeightL,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              foregroundColor: textColor,
              elevation: isLastUsed ? 2 : 0,
              shape: RoundedRectangleBorder(
                borderRadius: AppDimens.buttonBorderRadius,
                side: isLastUsed
                    ? BorderSide(color: AppColors.primary, width: 2)
                    : borderColor != null
                        ? BorderSide(color: borderColor!)
                        : BorderSide.none,
              ),
            ),
            child: isLoading
                ? SizedBox(
                    height: AppDimens.iconM,
                    width: AppDimens.iconM,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: textColor,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: AppDimens.iconM,
                        height: AppDimens.iconM,
                        child: SvgPicture.asset(
                          svgAsset,
                          colorFilter: iconColor != null
                              ? ColorFilter.mode(iconColor!, BlendMode.srcIn)
                              : null,
                        ),
                      ),
                      const SizedBox(width: AppDimens.paddingM),
                      Text(
                        label,
                        style: AppTextStyles.labelLarge(context).copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        // 최근 사용 배지
        if (isLastUsed)
          Positioned(
            top: -8,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '최근 사용',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
