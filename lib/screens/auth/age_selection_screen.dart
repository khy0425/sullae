import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';

/// 연령대 선택 화면
///
/// 30초 회원가입 3단계 (선택):
/// 게임 매칭에 도움이 되는 연령대 정보
class AgeSelectionScreen extends StatefulWidget {
  final String provider;
  final String nickname;

  const AgeSelectionScreen({
    super.key,
    required this.provider,
    required this.nickname,
  });

  @override
  State<AgeSelectionScreen> createState() => _AgeSelectionScreenState();
}

class _AgeSelectionScreenState extends State<AgeSelectionScreen> {
  AgeRange? _selectedAge;
  bool _isLoading = false;

  Future<void> _complete() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);

    // AuthProvider를 통해 회원가입 완료 (상태 동기화)
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.completeSignup(
      nickname: widget.nickname,
      ageRange: _selectedAge,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      // AuthProvider.isLoggedIn이 true가 되므로 main.dart의 Consumer가
      // 자동으로 HomeScreen으로 이동시킴
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.nickname}님, 환영합니다!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.signupFailed),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.selectAgeGroup),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppDimens.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppDimens.paddingXL),

              // 안내 문구
              Text(
                l10n.ageGuide,
                style: AppTextStyles.titleMedium(context),
              ),
              const SizedBox(height: AppDimens.paddingS),
              Text(
                l10n.ageMatchingHelp,
                style: AppTextStyles.bodySmall(context),
              ),

              const SizedBox(height: AppDimens.paddingXL),

              // 연령대 선택 옵션들
              ...AgeRange.values.map((age) => _AgeOption(
                    age: age,
                    isSelected: _selectedAge == age,
                    l10n: l10n,
                    onTap: () {
                      setState(() {
                        _selectedAge = _selectedAge == age ? null : age;
                      });
                    },
                  )),

              const Spacer(),

              // 건너뛰기 버튼
              if (_selectedAge == null)
                TextButton(
                  onPressed: _isLoading ? null : _complete,
                  child: Text(
                    l10n.skip,
                    style: AppTextStyles.label(context).copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),

              const SizedBox(height: AppDimens.paddingS),

              // 완료 버튼
              ElevatedButton(
                onPressed: _isLoading ? null : _complete,
                child: _isLoading
                    ? SizedBox(
                        height: AppDimens.iconM,
                        width: AppDimens.iconM,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _selectedAge != null ? l10n.complete : l10n.startPrivately,
                        style: AppTextStyles.labelLarge(context).copyWith(
                          color: AppColors.textOnPrimary,
                        ),
                      ),
              ),

              const SizedBox(height: AppDimens.paddingXL),
            ],
          ),
        ),
      ),
    );
  }
}

/// 연령대 선택 옵션
class _AgeOption extends StatelessWidget {
  final AgeRange age;
  final bool isSelected;
  final VoidCallback onTap;
  final AppLocalizations l10n;

  const _AgeOption({
    required this.age,
    required this.isSelected,
    required this.onTap,
    required this.l10n,
  });

  String _getAgeLabel(AgeRange age) {
    switch (age) {
      case AgeRange.teens:
        return l10n.ageGroup10s;
      case AgeRange.twenties:
        return l10n.ageGroup20s;
      case AgeRange.thirties:
        return l10n.ageGroup30s;
      case AgeRange.private_:
        return l10n.later;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppDimens.paddingM),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppDimens.cardBorderRadius,
        child: Container(
          padding: AppDimens.paddingAll(AppDimens.paddingM),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.surfaceVariant,
            borderRadius: AppDimens.cardBorderRadius,
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // 이모지
              Text(
                age.emoji,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: AppDimens.paddingM),

              // 텍스트
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getAgeLabel(age),
                      style: AppTextStyles.titleSmall(context).copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.ageGroupOptional,
                      style: AppTextStyles.bodySmall(context),
                    ),
                  ],
                ),
              ),

              // 체크 아이콘
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: AppDimens.iconM,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
