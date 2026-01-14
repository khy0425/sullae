import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/login_preference_service.dart';

/// 인증 Provider
///
/// 30초 회원가입 철학:
/// 1. 소셜 로그인 (원터치)
/// 2. 닉네임 입력 (2~10자)
/// 3. 연령대 선택 (선택)
/// 4. 완료!
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _firebaseUser;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _error;

  // 회원가입 진행 상태
  bool _isNewUser = false;
  LoginProvider? _pendingProvider;

  // 초기화 상태 (자동 로그인 확인 완료 여부)
  bool _isInitialized = false;

  // 마지막 로그인 프로바이더 (로그인 화면에서 표시용)
  LoginProvider? _lastLoginProvider;
  LoginPreferenceService? _loginPrefService;

  // 로그아웃 진행 중 플래그 (무한루프 방지)
  bool _isSigningOut = false;

  // Getters
  User? get firebaseUser => _firebaseUser;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isLoggedIn => _firebaseUser != null && _userModel != null;
  bool get needsProfile => _firebaseUser != null && _userModel == null;
  bool get isNewUser => _isNewUser;
  LoginProvider? get pendingProvider => _pendingProvider;
  LoginProvider? get lastLoginProvider => _lastLoginProvider;
  String? get error => _error;
  String get userId => _firebaseUser?.uid ?? '';
  String get nickname => _userModel?.nickname ?? '익명';

  AuthProvider() {
    _init();
  }

  void _init() async {
    final startTime = DateTime.now();
    const minSplashDuration = Duration(milliseconds: 800); // 빠른 시작을 위해 0.8초로 단축

    // 로그인 설정 서비스 초기화 (병렬로 시작)
    LoginPreferenceService.getInstance().then((service) {
      _loginPrefService = service;
      _lastLoginProvider = service.getLastProvider();
      notifyListeners();
    });

    // Firebase Auth 상태 리스닝 즉시 시작
    _authService.authStateChanges.listen((user) async {
      // 로그아웃 진행 중이면 무시 (무한루프 방지)
      if (_isSigningOut) return;

      _firebaseUser = user;
      if (user != null) {
        try {
          _userModel = await _authService.getUserProfile(user.uid);
          // 프로필이 없거나 닉네임이 비어있으면 신규 사용자로 간주
          // (카카오 로그인 중간에 이탈한 경우 처리)
          _isNewUser = _userModel == null || _userModel!.nickname.isEmpty;
          if (_isNewUser) {
            _userModel = null; // 불완전한 프로필은 null로 처리
          }
        } catch (e) {
          // Firestore 에러 시 로그아웃 처리
          _userModel = null;
          _isNewUser = false;
          _firebaseUser = null;
          // 삭제된 계정이면 로그아웃 (무한루프 방지 플래그 사용)
          _isSigningOut = true;
          await _authService.signOut();
          _isSigningOut = false;
        }
      } else {
        _userModel = null;
        _isNewUser = false;
      }

      // 최소 스플래시 시간 보장
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed < minSplashDuration) {
        await Future.delayed(minSplashDuration - elapsed);
      }

      _isInitialized = true;
      notifyListeners();
    });
  }

  // ============== 소셜 로그인 ==============

  /// Google 로그인
  Future<AuthResult> signInWithGoogle() async {
    _setLoading(true);
    _clearError();
    _pendingProvider = LoginProvider.google;

    final result = await _authService.signInWithGoogle();

    if (result.success) {
      // 프로필을 먼저 로드해서 닉네임이 있는지 확인
      _userModel = await _authService.getCurrentUserProfile();

      // 프로필이 있지만 닉네임이 비어있으면 회원가입 중단으로 판단
      // → 불완전한 프로필 삭제 후 신규 사용자로 처리
      if (_userModel != null && _userModel!.nickname.isEmpty) {
        await _authService.deleteIncompleteProfile();
        _userModel = null;
      }

      // 프로필이 없으면 신규 사용자로 처리
      _isNewUser = _userModel == null;

      if (!_isNewUser) {
        // 기존 사용자: Analytics 로그인 이벤트
        AnalyticsService().logLogin(method: 'google');
        AnalyticsService().setUserId(_firebaseUser?.uid);
      }
      // 마지막 로그인 프로바이더 저장
      await _loginPrefService?.saveLastProvider(LoginProvider.google);
      _lastLoginProvider = LoginProvider.google;
      notifyListeners(); // 로그인 상태 변경 알림
    } else if (!result.cancelled) {
      _setError(result.errorMessage ?? '로그인에 실패했습니다.');
    }

    _setLoading(false);
    return result;
  }

  /// Kakao 로그인
  Future<AuthResult> signInWithKakao() async {
    _setLoading(true);
    _clearError();
    _pendingProvider = LoginProvider.kakao;

    final result = await _authService.signInWithKakao();

    if (result.success) {
      // 프로필을 먼저 로드해서 닉네임이 있는지 확인
      _userModel = await _authService.getCurrentUserProfile();

      // 프로필이 있지만 닉네임이 비어있으면 회원가입 중단으로 판단
      // → 불완전한 프로필 삭제 후 신규 사용자로 처리
      if (_userModel != null && _userModel!.nickname.isEmpty) {
        await _authService.deleteIncompleteProfile();
        _userModel = null;
      }

      // 프로필이 없으면 신규 사용자로 처리
      _isNewUser = _userModel == null;

      if (!_isNewUser) {
        // 기존 사용자: Analytics 로그인 이벤트
        AnalyticsService().logLogin(method: 'kakao');
        AnalyticsService().setUserId(_firebaseUser?.uid);
      }
      // 마지막 로그인 프로바이더 저장
      await _loginPrefService?.saveLastProvider(LoginProvider.kakao);
      _lastLoginProvider = LoginProvider.kakao;
      notifyListeners(); // 로그인 상태 변경 알림
    } else if (!result.cancelled) {
      _setError(result.errorMessage ?? '로그인에 실패했습니다.');
    }

    _setLoading(false);
    return result;
  }

  /// Apple 로그인
  Future<AuthResult> signInWithApple() async {
    _setLoading(true);
    _clearError();
    _pendingProvider = LoginProvider.apple;

    final result = await _authService.signInWithApple();

    if (result.success) {
      _isNewUser = result.isNewUser;
      if (!result.isNewUser) {
        _userModel = await _authService.getCurrentUserProfile();
        // Analytics: 로그인 이벤트
        AnalyticsService().logLogin(method: 'apple');
        AnalyticsService().setUserId(_firebaseUser?.uid);
      }
      // 마지막 로그인 프로바이더 저장
      await _loginPrefService?.saveLastProvider(LoginProvider.apple);
      _lastLoginProvider = LoginProvider.apple;
    } else if (!result.cancelled) {
      _setError(result.errorMessage ?? '로그인에 실패했습니다.');
    }

    _setLoading(false);
    return result;
  }

  // ============== 회원가입 완료 ==============

  /// 프로필 생성 (회원가입 마지막 단계)
  Future<bool> completeSignup({
    required String nickname,
    AgeRange? ageRange,
  }) async {
    if (_pendingProvider == null) {
      _setError('로그인 정보가 없습니다.');
      return false;
    }

    _setLoading(true);
    _clearError();

    final success = await _authService.createUserProfile(
      nickname: nickname,
      ageRange: ageRange,
      loginProvider: _pendingProvider!,
    );

    if (success) {
      _userModel = await _authService.getCurrentUserProfile();
      _isNewUser = false;
      // Analytics: 회원가입 이벤트
      AnalyticsService().logSignUp(method: _pendingProvider?.name ?? 'unknown');
      AnalyticsService().setUserId(_firebaseUser?.uid);
      _pendingProvider = null;
    } else {
      _setError('프로필 생성에 실패했습니다.');
    }

    _setLoading(false);
    notifyListeners();
    return success;
  }

  // ============== 닉네임 ==============

  /// 닉네임 유효성 + 중복 검사
  Future<NicknameValidationResult> validateNickname(String nickname) async {
    return await _authService.validateNickname(nickname);
  }

  /// 닉네임 변경
  Future<bool> updateNickname(String newNickname) async {
    if (_firebaseUser == null) return false;

    _setLoading(true);
    _clearError();

    try {
      final validation = await _authService.validateNickname(newNickname);
      if (!validation.isValid) {
        _setError(validation.errorMessage);
        _setLoading(false);
        return false;
      }

      await _authService.updateNickname(_firebaseUser!.uid, newNickname);
      _userModel = _userModel?.copyWith(nickname: newNickname);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // ============== 프로필 ==============

  /// 연령대 변경
  Future<bool> updateAgeRange(AgeRange? ageRange) async {
    _setLoading(true);

    final success = await _authService.updateUserProfile(ageRange: ageRange);

    if (success) {
      _userModel = _userModel?.copyWith(ageRange: ageRange);
    }

    _setLoading(false);
    notifyListeners();
    return success;
  }

  // ============== 로그아웃 / 탈퇴 ==============

  /// 로그아웃
  Future<void> signOut() async {
    // Analytics: 로그아웃 이벤트
    AnalyticsService().logLogout();
    await _authService.signOut();
    _userModel = null;
    _isNewUser = false;
    _pendingProvider = null;
    notifyListeners();
  }

  /// 계정 삭제
  Future<bool> deleteAccount() async {
    _setLoading(true);

    final success = await _authService.deleteAccount();

    if (success) {
      _userModel = null;
      _isNewUser = false;
      _pendingProvider = null;
    }

    _setLoading(false);
    notifyListeners();
    return success;
  }

  // ============== 레거시 (기존 호환) ==============

  /// 익명 로그인 (기존 호환)
  Future<bool> signInAnonymously(String nickname) async {
    _setLoading(true);
    _clearError();

    try {
      final credential = await _authService.signInAnonymously();
      if (credential?.user != null) {
        await _authService.createUserProfileLegacy(
            credential!.user!.uid, nickname);
        _userModel = await _authService.getUserProfile(credential.user!.uid);
        _setLoading(false);
        return true;
      }
      _setError('로그인에 실패했습니다.');
      _setLoading(false);
      return false;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// 이메일 회원가입 (기존 호환)
  Future<bool> signUpWithEmail(
      String email, String password, String nickname) async {
    _setLoading(true);
    _clearError();

    try {
      final isAvailable = await _authService.isNicknameAvailable(nickname);
      if (!isAvailable) {
        _setError('이미 사용 중인 닉네임입니다.');
        _setLoading(false);
        return false;
      }

      await _authService.signUpWithEmail(email, password, nickname);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// 이메일 로그인 (기존 호환)
  Future<bool> signInWithEmail(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.signInWithEmail(email, password);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // ============== 내부 함수 ==============

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  /// 에러 클리어 (외부에서 호출 가능)
  void clearError() {
    _clearError();
    notifyListeners();
  }
}
