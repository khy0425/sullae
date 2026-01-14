import 'package:firebase_remote_config/firebase_remote_config.dart';

/// 입력값 보안 처리
/// - HTML/스크립트 태그 제거
/// - 위험한 문자 이스케이프
/// - 이모지는 허용
class InputSanitizer {
  static List<String>? _cachedBadWords;

  /// Remote Config에서 비속어 목록 가져오기
  static List<String> get _badWords {
    if (_cachedBadWords != null) return _cachedBadWords!;

    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      final words = remoteConfig.getString('bad_words');
      if (words.isNotEmpty) {
        _cachedBadWords = words.split(',').map((w) => w.trim()).toList();
        return _cachedBadWords!;
      }
    } catch (_) {}

    // 기본값 (Remote Config 실패 시)
    return _defaultBadWords;
  }

  static const List<String> _defaultBadWords = [
    '시발', '씨발', '개새끼', '병신', 'ㅅㅂ', 'ㅂㅅ',
  ];

  /// 캐시 초기화 (Remote Config 업데이트 시 호출)
  static void clearCache() {
    _cachedBadWords = null;
  }
  /// HTML 태그 및 스크립트 제거
  static String sanitize(String input) {
    if (input.isEmpty) return input;

    String result = input;

    // HTML 태그 제거 (이모지는 유지)
    result = result.replaceAll(RegExp(r'<[^>]*>'), '');

    // 스크립트 관련 키워드 제거
    result = result.replaceAll(RegExp(r'javascript:', caseSensitive: false), '');
    result = result.replaceAll(RegExp(r'on\w+\s*=', caseSensitive: false), '');

    // SQL 인젝션 방지 (Firestore는 NoSQL이라 덜 위험하지만 안전하게)
    result = result.replaceAll(RegExp(r'''['";]'''), '');

    // 연속 공백 정리
    result = result.replaceAll(RegExp(r'\s+'), ' ');

    // 앞뒤 공백 제거
    result = result.trim();

    return result;
  }

  /// 이름 sanitize (더 엄격)
  static String sanitizeName(String input) {
    if (input.isEmpty) return input;

    String result = sanitize(input);

    // 이름에서 특수문자 대부분 제거 (이모지, 한글, 영문, 숫자, 공백만 허용)
    result = result.replaceAll(
      RegExp(r'[^\p{L}\p{N}\p{Emoji}\s]', unicode: true),
      '',
    );

    // 최대 길이 제한
    if (result.length > 20) {
      result = result.substring(0, 20);
    }

    return result.trim();
  }

  /// 후기 내용 sanitize
  static String sanitizeReview(String input) {
    if (input.isEmpty) return input;

    String result = sanitize(input);

    // 최대 길이 제한
    if (result.length > 500) {
      result = result.substring(0, 500);
    }

    // 최소 길이 체크는 UI에서 처리

    return result;
  }

  /// URL 제거 (스팸 방지)
  static String removeUrls(String input) {
    return input.replaceAll(
      RegExp(r'https?://[^\s]+', caseSensitive: false),
      '[링크 제거됨]',
    );
  }

  /// 욕설/비속어 필터 (Remote Config에서 관리)
  static String filterProfanity(String input) {
    String result = input;
    for (final word in _badWords) {
      result = result.replaceAll(
        RegExp(word, caseSensitive: false),
        '*' * word.length,
      );
    }

    return result;
  }

  /// 전체 sanitize (후기용)
  static String sanitizeAll(String input) {
    String result = sanitize(input);
    result = removeUrls(result);
    result = filterProfanity(result);
    return result;
  }
}
