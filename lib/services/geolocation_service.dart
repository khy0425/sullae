import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// GPS 위치 서비스
class GeolocationService {
  static final GeolocationService _instance = GeolocationService._internal();
  factory GeolocationService() => _instance;
  GeolocationService._internal();

  /// 위치 권한 확인 및 요청
  Future<LocationPermissionResult> checkAndRequestPermission() async {
    // 위치 서비스 활성화 확인
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionResult.serviceDisabled;
    }

    // 권한 상태 확인
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationPermissionResult.denied;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationPermissionResult.deniedForever;
    }

    return LocationPermissionResult.granted;
  }

  /// 현재 위치 가져오기 (대략적인 위치 - 배터리 절약)
  Future<Position?> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.low, // 대략적인 위치만 필요
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      final permissionResult = await checkAndRequestPermission();

      if (permissionResult != LocationPermissionResult.granted) {
        if (kDebugMode) print('Location permission not granted: $permissionResult');
        return null;
      }

      // 먼저 마지막 알려진 위치 시도 (빠름)
      final lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        // 5분 이내 위치면 그대로 사용
        final age = DateTime.now().difference(lastPosition.timestamp);
        if (age.inMinutes < 5) {
          if (kDebugMode) print('Using cached position');
          return lastPosition;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: timeout,
        ),
      );

      if (kDebugMode) {
        print('Current position: ${position.latitude}, ${position.longitude}');
      }

      return position;
    } catch (e) {
      if (kDebugMode) print('Error getting position: $e');
      return null;
    }
  }

  /// 마지막 알려진 위치 가져오기 (빠름)
  Future<Position?> getLastKnownPosition() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      return position;
    } catch (e) {
      if (kDebugMode) print('Error getting last known position: $e');
      return null;
    }
  }

  /// 위치 스트림 (실시간 추적)
  Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10, // 10m 이동 시 업데이트
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    );
  }

  /// 두 위치 사이의 거리 계산 (미터)
  double distanceBetween(
    double startLat, double startLon,
    double endLat, double endLon,
  ) {
    return Geolocator.distanceBetween(startLat, startLon, endLat, endLon);
  }

  /// 설정 화면으로 이동 (권한 거부 시)
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// 앱 설정 화면으로 이동 (권한 영구 거부 시)
  Future<void> openAppSettings() async {
    await openAppSettings();
  }
}

/// 위치 권한 결과
enum LocationPermissionResult {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}

extension LocationPermissionResultExtension on LocationPermissionResult {
  bool get isGranted => this == LocationPermissionResult.granted;

  String get message {
    switch (this) {
      case LocationPermissionResult.granted:
        return '위치 권한이 허용되었습니다';
      case LocationPermissionResult.denied:
        return '위치 권한이 거부되었습니다. 체크인을 위해 권한을 허용해주세요.';
      case LocationPermissionResult.deniedForever:
        return '위치 권한이 영구 거부되었습니다. 설정에서 권한을 허용해주세요.';
      case LocationPermissionResult.serviceDisabled:
        return '위치 서비스가 비활성화되어 있습니다. 위치 서비스를 켜주세요.';
    }
  }
}
