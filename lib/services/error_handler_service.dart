import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// 앱 전역 에러 처리 서비스
///
/// - 에러 로깅
/// - 사용자 친화적 메시지 변환
/// - 에러 리포팅 (선택적)
class ErrorHandlerService {
  static final ErrorHandlerService _instance = ErrorHandlerService._internal();
  factory ErrorHandlerService() => _instance;
  ErrorHandlerService._internal();

  /// 에러를 처리하고 사용자 친화적 메시지 반환
  String handleError(dynamic error, {String? context}) {
    // 디버그 로깅
    _logError(error, context: context);

    // 에러 타입별 사용자 메시지 변환
    final message = _getUserFriendlyMessage(error);

    return message;
  }

  /// 에러 로깅
  void _logError(dynamic error, {String? context}) {
    final timestamp = DateTime.now().toIso8601String();
    final contextInfo = context != null ? ' [$context]' : '';

    if (kDebugMode) {
      print('[$timestamp]$contextInfo Error: $error');
      if (error is Error) {
        print('Stack trace: ${error.stackTrace}');
      }
    }

    // TODO: 프로덕션에서는 Firebase Crashlytics나 Sentry로 전송
    // FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }

  /// 사용자 친화적 메시지로 변환
  String _getUserFriendlyMessage(dynamic error) {
    // Firebase Auth 에러
    if (error is FirebaseAuthException) {
      return _handleFirebaseAuthError(error);
    }

    // Firestore 에러
    if (error is FirebaseException) {
      return _handleFirebaseError(error);
    }

    // 타임아웃 에러
    if (error is TimeoutException) {
      return '요청 시간이 초과되었습니다. 다시 시도해 주세요.';
    }

    // 네트워크 에러
    if (_isNetworkError(error)) {
      return '네트워크 연결을 확인해 주세요.';
    }

    // MeetingLimitException 등 커스텀 에러
    if (error.toString().contains('최대') && error.toString().contains('개까지만')) {
      return error.toString();
    }

    // 기타 에러
    if (error is Exception || error is Error) {
      final message = error.toString();

      // 이미 사용자 친화적인 메시지인 경우
      if (_isUserFriendlyMessage(message)) {
        return message.replaceFirst('Exception: ', '');
      }
    }

    // 기본 메시지
    return '오류가 발생했습니다. 잠시 후 다시 시도해 주세요.';
  }

  /// Firebase Auth 에러 처리
  String _handleFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return '등록되지 않은 계정입니다.';
      case 'wrong-password':
        return '비밀번호가 올바르지 않습니다.';
      case 'email-already-in-use':
        return '이미 사용 중인 이메일입니다.';
      case 'weak-password':
        return '비밀번호가 너무 짧습니다. 6자 이상 입력해 주세요.';
      case 'invalid-email':
        return '올바른 이메일 형식이 아닙니다.';
      case 'user-disabled':
        return '이 계정은 비활성화되었습니다.';
      case 'too-many-requests':
        return '너무 많은 요청이 발생했습니다. 잠시 후 다시 시도해 주세요.';
      case 'operation-not-allowed':
        return '이 로그인 방식은 현재 사용할 수 없습니다.';
      case 'account-exists-with-different-credential':
        return '다른 로그인 방식으로 이미 가입된 이메일입니다.';
      case 'invalid-credential':
        return '인증 정보가 유효하지 않습니다.';
      case 'network-request-failed':
        return '네트워크 연결을 확인해 주세요.';
      case 'requires-recent-login':
        return '보안을 위해 다시 로그인해 주세요.';
      default:
        return '로그인 중 오류가 발생했습니다.';
    }
  }

  /// Firebase 일반 에러 처리
  String _handleFirebaseError(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return '권한이 없습니다.';
      case 'unavailable':
        return '서버에 연결할 수 없습니다. 잠시 후 다시 시도해 주세요.';
      case 'cancelled':
        return '요청이 취소되었습니다.';
      case 'deadline-exceeded':
        return '요청 시간이 초과되었습니다.';
      case 'not-found':
        return '요청한 데이터를 찾을 수 없습니다.';
      case 'already-exists':
        return '이미 존재하는 데이터입니다.';
      case 'resource-exhausted':
        return '요청 한도를 초과했습니다. 잠시 후 다시 시도해 주세요.';
      case 'failed-precondition':
        return '요청을 처리할 수 없는 상태입니다.';
      case 'aborted':
        return '작업이 중단되었습니다.';
      case 'out-of-range':
        return '유효하지 않은 값입니다.';
      case 'unimplemented':
        return '지원되지 않는 기능입니다.';
      case 'internal':
        return '내부 오류가 발생했습니다.';
      case 'data-loss':
        return '데이터 오류가 발생했습니다.';
      case 'unauthenticated':
        return '로그인이 필요합니다.';
      default:
        return '오류가 발생했습니다.';
    }
  }

  /// 네트워크 에러인지 확인
  bool _isNetworkError(dynamic error) {
    final message = error.toString().toLowerCase();
    return message.contains('network') ||
           message.contains('connection') ||
           message.contains('socket') ||
           message.contains('host') ||
           message.contains('timeout');
  }

  /// 이미 사용자 친화적인 메시지인지 확인
  bool _isUserFriendlyMessage(String message) {
    // 한글이 포함되어 있으면 사용자 친화적인 메시지로 간주
    return RegExp(r'[가-힣]').hasMatch(message);
  }
}

/// 에러 처리 확장 (FutureOr)
extension ErrorHandlerExtension<T> on Future<T> {
  /// 에러를 자동으로 처리하고 null 반환
  Future<T?> handleError({String? context}) async {
    try {
      return await this;
    } catch (e) {
      ErrorHandlerService().handleError(e, context: context);
      return null;
    }
  }

  /// 에러를 처리하고 기본값 반환
  Future<T> handleErrorWithDefault(T defaultValue, {String? context}) async {
    try {
      return await this;
    } catch (e) {
      ErrorHandlerService().handleError(e, context: context);
      return defaultValue;
    }
  }
}

/// Result 타입 (성공/실패 명시)
class Result<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  const Result._({this.data, this.error, required this.isSuccess});

  factory Result.success(T data) => Result._(data: data, isSuccess: true);
  factory Result.failure(String error) => Result._(error: error, isSuccess: false);

  /// 성공 시 데이터 반환, 실패 시 null
  T? get value => isSuccess ? data : null;

  /// 결과에 따라 함수 실행
  R when<R>({
    required R Function(T data) success,
    required R Function(String error) failure,
  }) {
    if (isSuccess && data != null) {
      return success(data as T);
    } else {
      return failure(error ?? '알 수 없는 오류');
    }
  }
}

/// 앱 에러 타입
enum AppErrorType {
  network,      // 네트워크 에러
  auth,         // 인증 에러
  permission,   // 권한 에러
  validation,   // 유효성 검사 에러
  notFound,     // 데이터 없음
  server,       // 서버 에러
  unknown,      // 알 수 없는 에러
}

/// 앱 에러 클래스
class AppError implements Exception {
  final String message;
  final AppErrorType type;
  final dynamic originalError;

  const AppError({
    required this.message,
    required this.type,
    this.originalError,
  });

  @override
  String toString() => message;

  /// 에러 타입에 따른 아이콘 (UI 표시용)
  String get iconEmoji {
    switch (type) {
      case AppErrorType.network:
        return '📶';
      case AppErrorType.auth:
        return '🔐';
      case AppErrorType.permission:
        return '🚫';
      case AppErrorType.validation:
        return '⚠️';
      case AppErrorType.notFound:
        return '🔍';
      case AppErrorType.server:
        return '🔧';
      case AppErrorType.unknown:
        return '❓';
    }
  }
}
