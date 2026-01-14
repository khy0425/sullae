import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

/// 로그인 설정 저장 서비스
class LoginPreferenceService {
  static const String _lastProviderKey = 'last_login_provider';
  static const String _lastLoginTimeKey = 'last_login_time';

  static LoginPreferenceService? _instance;
  SharedPreferences? _prefs;

  LoginPreferenceService._();

  static Future<LoginPreferenceService> getInstance() async {
    if (_instance == null) {
      _instance = LoginPreferenceService._();
      _instance!._prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  /// 마지막 로그인 프로바이더 저장
  Future<void> saveLastProvider(LoginProvider provider) async {
    await _prefs?.setString(_lastProviderKey, provider.name);
    await _prefs?.setInt(_lastLoginTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// 마지막 로그인 프로바이더 가져오기
  LoginProvider? getLastProvider() {
    final providerName = _prefs?.getString(_lastProviderKey);
    if (providerName == null) return null;

    try {
      return LoginProvider.values.firstWhere((p) => p.name == providerName);
    } catch (_) {
      return null;
    }
  }

  /// 마지막 로그인 시간 가져오기
  DateTime? getLastLoginTime() {
    final timestamp = _prefs?.getInt(_lastLoginTimeKey);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// 로그인 정보 삭제 (로그아웃 시)
  Future<void> clearLastProvider() async {
    await _prefs?.remove(_lastProviderKey);
    await _prefs?.remove(_lastLoginTimeKey);
  }
}
