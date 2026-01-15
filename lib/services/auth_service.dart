import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../models/user_model.dart';

/// 인증 서비스
///
/// 30초 회원가입 철학:
/// 1. 소셜 로그인 (원터치)
/// 2. 닉네임 입력 (2~10자)
/// 3. 연령대 선택 (선택)
/// 4. 완료!
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 컬렉션 참조
  CollectionReference get _usersRef => _firestore.collection('users');

  // ============== 현재 유저 ==============

  /// 현재 로그인된 Firebase User
  User? get currentUser => _auth.currentUser;

  /// 로그인 상태 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 현재 유저 프로필 가져오기
  Future<UserModel?> getCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final doc = await _usersRef.doc(user.uid).get();
    if (!doc.exists) return null;

    return UserModel.fromFirestore(doc);
  }

  /// 유저 프로필 조회
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  /// 유저 프로필 스트림
  Stream<UserModel?> userProfileStream(String uid) {
    return _usersRef.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  // ============== 소셜 로그인 ==============

  /// Google 로그인
  Future<AuthResult> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        return AuthResult.cancelled();
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        return AuthResult.error('로그인에 실패했습니다.');
      }

      final isNewUser = await checkNewUser(user.uid);

      return AuthResult.success(
        uid: user.uid,
        email: user.email,
        photoUrl: user.photoURL,
        isNewUser: isNewUser,
        provider: LoginProvider.google,
      );
    } catch (e) {
      return AuthResult.error('Google 로그인 실패: $e');
    }
  }

  /// Kakao 로그인
  /// 카카오 로그인 후 Firebase 익명 계정과 연동
  Future<AuthResult> signInWithKakao() async {
    try {
      // 카카오톡 설치 여부에 따라 로그인 방식 선택
      if (await kakao.isKakaoTalkInstalled()) {
        try {
          await kakao.UserApi.instance.loginWithKakaoTalk();
        } catch (e) {
          // 카카오톡 로그인 실패시 웹으로 fallback
          await kakao.UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        await kakao.UserApi.instance.loginWithKakaoAccount();
      }

      // 카카오 사용자 정보 가져오기
      final kakaoUser = await kakao.UserApi.instance.me();
      final kakaoId = kakaoUser.id.toString();
      final kakaoNickname = kakaoUser.kakaoAccount?.profile?.nickname;

      // 카카오 ID로 기존 사용자 확인 (Firebase 로그인 전에!)
      final existingUser = await _findUserByKakaoId(kakaoId);

      if (existingUser != null) {
        // 기존 사용자: 기존 UID의 익명 계정으로 로그인 시도
        // Firebase Anonymous Auth는 매번 새 UID를 생성하므로,
        // 기존 사용자의 경우 Firestore 데이터만 사용

        // 이미 Firebase에 로그인된 상태일 수 있으므로 먼저 로그아웃
        if (_auth.currentUser != null && _auth.currentUser!.uid != existingUser.uid) {
          await _auth.signOut();
        }

        // 익명 로그인 (새 UID 생성됨)
        final userCredential = await _auth.signInAnonymously();
        final newUser = userCredential.user;

        if (newUser == null) {
          return AuthResult.error('로그인에 실패했습니다.');
        }

        // 기존 사용자 데이터를 새 UID로 마이그레이션
        if (newUser.uid != existingUser.uid) {
          final oldData = await _usersRef.doc(existingUser.uid).get();
          if (oldData.exists) {
            final data = oldData.data() as Map<String, dynamic>;
            data['migratedFrom'] = existingUser.uid;
            data['migratedAt'] = Timestamp.now();
            await _usersRef.doc(newUser.uid).set(data);
            // 이전 문서 삭제
            await _usersRef.doc(existingUser.uid).delete();
          }
        }

        return AuthResult.success(
          uid: newUser.uid,
          email: null,
          photoUrl: kakaoUser.kakaoAccount?.profile?.profileImageUrl,
          isNewUser: false, // 기존 사용자
          provider: LoginProvider.kakao,
        );
      } else {
        // 신규 사용자: 새 익명 계정 생성
        final userCredential = await _auth.signInAnonymously();
        final user = userCredential.user;

        if (user == null) {
          return AuthResult.error('로그인에 실패했습니다.');
        }

        // 카카오 ID 저장 (프로필은 나중에 생성)
        await _usersRef.doc(user.uid).set({
          'kakaoId': kakaoId,
          'kakaoNickname': kakaoNickname,
          'createdAt': Timestamp.now(),
        }, SetOptions(merge: true));

        return AuthResult.success(
          uid: user.uid,
          email: null,
          photoUrl: kakaoUser.kakaoAccount?.profile?.profileImageUrl,
          isNewUser: true, // 신규 사용자
          provider: LoginProvider.kakao,
        );
      }
    } on kakao.KakaoAuthException catch (e) {
      if (e.error == kakao.AuthErrorCause.accessDenied) {
        return AuthResult.cancelled();
      }
      return AuthResult.error('카카오 로그인 실패: ${e.message}');
    } catch (e) {
      return AuthResult.error('카카오 로그인 실패: $e');
    }
  }

  /// 카카오 ID로 기존 사용자 찾기
  Future<UserModel?> _findUserByKakaoId(String kakaoId) async {
    final query = await _usersRef
        .where('kakaoId', isEqualTo: kakaoId)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return UserModel.fromFirestore(query.docs.first);
  }

  /// Apple 로그인
  Future<AuthResult> signInWithApple() async {
    try {
      // iOS에서만 지원
      if (!Platform.isIOS) {
        return AuthResult.error('Apple 로그인은 iOS에서만 지원됩니다.');
      }

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);
      final user = userCredential.user;

      if (user == null) {
        return AuthResult.error('로그인에 실패했습니다.');
      }

      final isNewUser = await checkNewUser(user.uid);

      return AuthResult.success(
        uid: user.uid,
        email: user.email,
        photoUrl: user.photoURL,
        isNewUser: isNewUser,
        provider: LoginProvider.apple,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return AuthResult.cancelled();
      }
      return AuthResult.error('Apple 로그인 실패: ${e.message}');
    } catch (e) {
      return AuthResult.error('Apple 로그인 실패: $e');
    }
  }

  // ============== 회원가입 완료 ==============

  /// 프로필 생성 (회원가입 마지막 단계)
  /// merge: true를 사용하여 kakaoId 등 기존 데이터 보존
  Future<bool> createUserProfile({
    required String nickname,
    AgeRange? ageRange,
    required LoginProvider loginProvider,
  }) async {
    final user = currentUser;
    if (user == null) return false;

    try {
      final userModel = UserModel.createNew(
        uid: user.uid,
        nickname: nickname,
        email: user.email,
        photoUrl: user.photoURL,
        ageRange: ageRange,
        loginProvider: loginProvider,
      );

      // merge: true로 kakaoId 등 기존 데이터 보존
      await _usersRef.doc(user.uid).set(
        userModel.toFirestore(),
        SetOptions(merge: true),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 기존 방식 유지 (호환성)
  Future<void> createUserProfileLegacy(String uid, String nickname) async {
    final user = UserModel.createNew(
      uid: uid,
      nickname: nickname,
      loginProvider: LoginProvider.google,
    );

    await _usersRef.doc(uid).set(user.toFirestore());
  }

  /// 프로필 업데이트
  Future<bool> updateUserProfile({
    String? nickname,
    String? photoUrl,
    AgeRange? ageRange,
  }) async {
    final user = currentUser;
    if (user == null) return false;

    try {
      final updates = <String, dynamic>{
        'lastActiveAt': Timestamp.now(),
      };

      if (nickname != null) updates['nickname'] = nickname;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;
      if (ageRange != null) updates['ageRange'] = ageRange.index;

      await _usersRef.doc(user.uid).update(updates);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ============== 닉네임 ==============

  /// 닉네임 중복 확인
  Future<bool> isNicknameAvailable(String nickname) async {
    final trimmed = nickname.trim();

    // 로컬 유효성 검사
    final validation = NicknameValidator.validate(trimmed);
    if (!validation.isValid) return false;

    // 서버 중복 확인
    final query = await _usersRef
        .where('nickname', isEqualTo: trimmed)
        .limit(1)
        .get();

    return query.docs.isEmpty;
  }

  /// 닉네임 유효성 + 중복 검사
  Future<NicknameValidationResult> validateNickname(String nickname) async {
    final trimmed = nickname.trim();

    // 로컬 유효성 검사
    final localResult = NicknameValidator.validate(trimmed);
    if (!localResult.isValid) return localResult;

    // 서버 중복 확인
    final isAvailable = await isNicknameAvailable(trimmed);
    if (!isAvailable) return NicknameValidationResult.duplicated;

    return NicknameValidationResult.valid;
  }

  /// 닉네임 업데이트
  Future<void> updateNickname(String uid, String nickname) async {
    await _usersRef.doc(uid).update({
      'nickname': nickname,
      'lastActiveAt': Timestamp.now(),
    });
  }

  // ============== 로그아웃 / 탈퇴 ==============

  /// 로그아웃
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// 계정 삭제 (탈퇴)
  Future<bool> deleteAccount() async {
    final user = currentUser;
    if (user == null) return false;

    try {
      // Firestore 데이터 삭제
      await _usersRef.doc(user.uid).delete();

      // Firebase Auth 계정 삭제
      await user.delete();

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 불완전한 프로필 삭제 (회원가입 중단 시)
  /// 닉네임이 비어있는 불완전한 Firestore 프로필만 삭제
  /// Firebase Auth 계정은 유지 (신규 사용자로 다시 프로필 생성 가능)
  Future<bool> deleteIncompleteProfile() async {
    final user = currentUser;
    if (user == null) return false;

    try {
      // Firestore 프로필 데이터만 삭제 (Auth 계정은 유지)
      await _usersRef.doc(user.uid).delete();
      return true;
    } catch (e) {
      // 삭제 실패해도 계속 진행
      return false;
    }
  }

  // ============== 내부 함수 ==============

  /// 신규 유저 확인
  Future<bool> checkNewUser(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    return !doc.exists;
  }

  /// 활동 시간 업데이트
  Future<void> updateLastActive() async {
    final user = currentUser;
    if (user == null) return;

    await _usersRef.doc(user.uid).update({
      'lastActiveAt': Timestamp.now(),
    });
  }

  // ============== 게임 통계 업데이트 ==============

  /// 게임 참가 횟수 증가
  Future<void> incrementGamesPlayed() async {
    final user = currentUser;
    if (user == null) return;

    await _usersRef.doc(user.uid).update({
      'gamesPlayed': FieldValue.increment(1),
      'lastActiveAt': Timestamp.now(),
    });
  }

  /// 호스팅 횟수 증가
  Future<void> incrementGamesHosted() async {
    final user = currentUser;
    if (user == null) return;

    await _usersRef.doc(user.uid).update({
      'gamesHosted': FieldValue.increment(1),
      'lastActiveAt': Timestamp.now(),
    });
  }

  /// MVP 횟수 증가
  Future<void> incrementMvpCount() async {
    final user = currentUser;
    if (user == null) return;

    await _usersRef.doc(user.uid).update({
      'mvpCount': FieldValue.increment(1),
      'lastActiveAt': Timestamp.now(),
    });
  }

  /// 지원 횟수 증가
  Future<void> incrementVolunteerCount() async {
    final user = currentUser;
    if (user == null) return;

    await _usersRef.doc(user.uid).update({
      'volunteerCount': FieldValue.increment(1),
      'lastActiveAt': Timestamp.now(),
    });
  }

  // ============== 레거시 지원 ==============

  /// 익명 로그인 (기존 호환)
  Future<UserCredential?> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      // ignore: avoid_print
      print('Anonymous sign in error: $e');
      return null;
    }
  }

  /// 이메일/비밀번호 회원가입 (기존 호환)
  Future<UserCredential?> signUpWithEmail(
      String email, String password, String nickname) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await createUserProfileLegacy(credential.user!.uid, nickname);
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// 이메일/비밀번호 로그인 (기존 호환)
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return '비밀번호가 너무 약합니다.';
      case 'email-already-in-use':
        return '이미 사용 중인 이메일입니다.';
      case 'invalid-email':
        return '유효하지 않은 이메일 형식입니다.';
      case 'user-not-found':
        return '등록되지 않은 사용자입니다.';
      case 'wrong-password':
        return '비밀번호가 일치하지 않습니다.';
      default:
        return '인증 오류가 발생했습니다: ${e.message}';
    }
  }
}

// ============== 인증 결과 ==============

/// 소셜 로그인 결과
class AuthResult {
  final bool success;
  final bool cancelled;
  final String? uid;
  final String? email;
  final String? photoUrl;
  final bool isNewUser;
  final LoginProvider? provider;
  final String? errorMessage;

  AuthResult._({
    required this.success,
    this.cancelled = false,
    this.uid,
    this.email,
    this.photoUrl,
    this.isNewUser = false,
    this.provider,
    this.errorMessage,
  });

  factory AuthResult.success({
    required String uid,
    String? email,
    String? photoUrl,
    required bool isNewUser,
    required LoginProvider provider,
  }) {
    return AuthResult._(
      success: true,
      uid: uid,
      email: email,
      photoUrl: photoUrl,
      isNewUser: isNewUser,
      provider: provider,
    );
  }

  factory AuthResult.error(String message) {
    return AuthResult._(
      success: false,
      errorMessage: message,
    );
  }

  factory AuthResult.cancelled() {
    return AuthResult._(
      success: false,
      cancelled: true,
    );
  }
}
