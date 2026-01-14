import 'package:firebase_remote_config/firebase_remote_config.dart';

/// 앱 설정 서비스 (Firebase Remote Config)
///
/// API 키 등 민감한 정보를 안전하게 관리
class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  bool _initialized = false;

  // 기본값 (Remote Config 연결 실패 시 사용)
  static const Map<String, dynamic> _defaults = {
    'kakao_native_key': '',
    'kakao_rest_api_key': '',
    'app_min_version': '1.0.0',
    'maintenance_mode': false,
    'maintenance_message': '서버 점검 중입니다.',
  };

  /// Remote Config 초기화
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 빠른 앱 시작을 위해 타임아웃 단축
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 5),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      // 기본값 설정
      await _remoteConfig.setDefaults(_defaults.map(
        (key, value) => MapEntry(key, value.toString()),
      ));

      // 서버에서 값 가져오기 (타임아웃 내에 실패하면 캐시/기본값 사용)
      await _remoteConfig.fetchAndActivate().timeout(
        const Duration(seconds: 3),
        onTimeout: () => false,
      );
      _initialized = true;
    } catch (e) {
      // 실패해도 기본값으로 동작
      _initialized = true;
    }
  }

  /// 카카오 Native App Key
  String get kakaoNativeKey {
    final key = _remoteConfig.getString('kakao_native_key');
    return key.isNotEmpty ? key : '8bfb870bdbc61df9738f0ed46fb96ca6'; // fallback
  }

  /// 카카오 REST API Key (장소 검색용)
  String get kakaoRestApiKey {
    return _remoteConfig.getString('kakao_rest_api_key');
  }

  /// 앱 최소 버전
  String get appMinVersion {
    return _remoteConfig.getString('app_min_version');
  }

  /// 점검 모드 여부
  bool get isMaintenanceMode {
    return _remoteConfig.getBool('maintenance_mode');
  }

  /// 점검 메시지
  String get maintenanceMessage {
    return _remoteConfig.getString('maintenance_message');
  }

  /// 설정 새로고침
  Future<bool> refresh() async {
    try {
      final updated = await _remoteConfig.fetchAndActivate();
      return updated;
    } catch (e) {
      return false;
    }
  }
}
