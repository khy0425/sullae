import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'dart:async';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import 'age_selection_screen.dart';

/// 닉네임 입력 화면
///
/// 30초 회원가입 2단계:
/// 게임에서 불릴 이름 입력 (2~10자)
class NicknameScreen extends StatefulWidget {
  final String provider;

  const NicknameScreen({
    super.key,
    required this.provider,
  });

  @override
  State<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends State<NicknameScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _authService = AuthService();

  NicknameValidationResult? _validationResult;
  bool _isChecking = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onNicknameChanged(String value) {
    final localResult = NicknameValidator.validate(value);

    setState(() {
      _validationResult = localResult;
    });

    if (localResult == NicknameValidationResult.valid) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        _checkDuplicate(value);
      });
    }
  }

  Future<void> _checkDuplicate(String nickname) async {
    setState(() => _isChecking = true);

    final result = await _authService.validateNickname(nickname);

    if (mounted && _controller.text.trim() == nickname) {
      setState(() {
        _validationResult = result;
        _isChecking = false;
      });
    }
  }

  void _onNext() {
    if (_validationResult != NicknameValidationResult.valid) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AgeSelectionScreen(
          provider: widget.provider,
          nickname: _controller.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isValid = _validationResult == NicknameValidationResult.valid;
    final hasError = _validationResult != null &&
        _validationResult != NicknameValidationResult.valid &&
        _validationResult != NicknameValidationResult.empty;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.nicknameSetup),
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
                l10n.nicknameGuide,
                style: AppTextStyles.titleMedium(context),
              ),
              const SizedBox(height: AppDimens.paddingS),
              Text(
                l10n.nicknameFormat,
                style: AppTextStyles.bodySmall(context),
              ),

              const SizedBox(height: AppDimens.paddingXL),

              // 닉네임 입력 필드
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: _onNicknameChanged,
                maxLength: NicknameValidator.maxLength,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _onNext(),
                style: AppTextStyles.bodyLarge(context),
                decoration: InputDecoration(
                  hintText: l10n.enterNickname,
                  counterText: '',
                  prefixIcon: const Icon(Icons.person_outline),
                  suffixIcon: _buildSuffixIcon(),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppDimens.buttonBorderRadius,
                    borderSide: BorderSide(
                      color: hasError
                          ? AppColors.error
                          : isValid
                              ? AppColors.success
                              : AppColors.border,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppDimens.buttonBorderRadius,
                    borderSide: BorderSide(
                      color: hasError
                          ? AppColors.error
                          : isValid
                              ? AppColors.success
                              : AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppDimens.paddingS),

              // 에러/성공 메시지
              SizedBox(
                height: 20,
                child: _buildValidationMessage(context, l10n),
              ),

              const Spacer(),

              // 다음 버튼
              ElevatedButton(
                onPressed: isValid && !_isChecking ? _onNext : null,
                child: Text(
                  l10n.next,
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

  Widget? _buildSuffixIcon() {
    if (_isChecking) {
      return Padding(
        padding: AppDimens.paddingAll(AppDimens.paddingM),
        child: SizedBox(
          width: AppDimens.iconM,
          height: AppDimens.iconM,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_validationResult == NicknameValidationResult.valid) {
      return Icon(
        Icons.check_circle,
        color: AppColors.success,
        size: AppDimens.iconM,
      );
    }

    if (_validationResult != null &&
        _validationResult != NicknameValidationResult.empty) {
      return Icon(
        Icons.error,
        color: AppColors.error,
        size: AppDimens.iconM,
      );
    }

    return null;
  }

  Widget _buildValidationMessage(BuildContext context, AppLocalizations l10n) {
    if (_isChecking) {
      return Text(
        l10n.checkingDuplicate,
        style: AppTextStyles.bodySmall(context),
      );
    }

    if (_validationResult == NicknameValidationResult.valid) {
      return Text(
        l10n.nicknameAvailable,
        style: AppTextStyles.success(context).copyWith(fontSize: 13),
      );
    }

    if (_validationResult != null &&
        _validationResult != NicknameValidationResult.empty) {
      return Text(
        _getValidationErrorMessage(l10n),
        style: AppTextStyles.error(context).copyWith(fontSize: 13),
      );
    }

    return const SizedBox.shrink();
  }

  String _getValidationErrorMessage(AppLocalizations l10n) {
    switch (_validationResult) {
      case NicknameValidationResult.tooShort:
        return l10n.nicknameTooShort;
      case NicknameValidationResult.tooLong:
        return l10n.nicknameTooLong;
      case NicknameValidationResult.invalidCharacters:
        return l10n.nicknameInvalid;
      case NicknameValidationResult.duplicated:
      case NicknameValidationResult.forbidden:
        return l10n.nicknameRequired;
      default:
        return l10n.nicknameRequired;
    }
  }
}
