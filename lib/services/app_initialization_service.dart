import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import '../firebase_options.dart';
import 'ad_service.dart';
import 'config_service.dart';
import 'notification_service.dart';

/// 앱 초기화 서비스
///
/// 스플래시 화면이 먼저 표시된 후 백그라운드에서 초기화 진행
class AppInitializationService {
  static final AppInitializationService _instance =
      AppInitializationService._internal();
  factory AppInitializationService() => _instance;
  AppInitializationService._internal();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// 앱 초기화 (스플래시 화면 표시 후 호출)
  Future<void> initialize() async {
    if (_initialized) return;

    // 1. Firebase 초기화 (필수)
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Crashlytics 초기화
      // 디버그 모드에서는 크래시 수집 비활성화
      await FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(!kDebugMode);
    } catch (e) {
      // 이미 초기화된 경우 무시
    }

    // 2. Remote Config, AdMob, 알림 병렬 초기화
    final configService = ConfigService();
    await Future.wait([
      configService.initialize(),
      AdService().initialize(),
      NotificationService().initialize(),
    ]);

    // 3. 카카오 SDK 초기화
    KakaoSdk.init(nativeAppKey: configService.kakaoNativeKey);

    _initialized = true;
  }
}
