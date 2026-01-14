import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  bool _isInitialized = false;
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;

  // 전면 광고 노출 카운터 (모임 참여/나가기 횟수)
  int _actionCount = 0;
  static const int _actionsBeforeAd = 3; // 3번 액션마다 광고

  /// AdMob 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    await MobileAds.instance.initialize();

    // 테스트 기기 등록 (디버그 모드에서만)
    if (kDebugMode) {
      MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          testDeviceIds: [
            '7A34AD87B8B2CBE7A1BFF956F5D4F752', // 실제 테스트 기기
          ],
        ),
      );
    }

    _isInitialized = true;

    // 전면 광고 미리 로드
    _loadInterstitialAd();

    if (kDebugMode) {
      print('AdMob initialized');
    }
  }

  /// 배너 광고 ID
  String get bannerAdUnitId {
    if (Platform.isAndroid) {
      // 술래 앱 배너 광고 ID
      return 'ca-app-pub-1075071967728463/2688982671';
    } else if (Platform.isIOS) {
      // iOS는 아직 미등록 - 테스트 ID 사용
      return 'ca-app-pub-3940256099942544/2934735716';
    }
    throw UnsupportedError('Unsupported platform');
  }

  /// 전면 광고 ID
  String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      // 술래 앱 전면 광고 ID
      return 'ca-app-pub-1075071967728463/5903121768';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910'; // 테스트 ID
    }
    throw UnsupportedError('Unsupported platform');
  }

  /// 배너 광고 로드
  BannerAd createBannerAd({
    required void Function(Ad) onAdLoaded,
    required void Function(Ad, LoadAdError) onAdFailedToLoad,
  }) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
        onAdOpened: (ad) {
          if (kDebugMode) print('Banner ad opened');
        },
        onAdClosed: (ad) {
          if (kDebugMode) print('Banner ad closed');
        },
      ),
    );
  }

  /// 전면 광고 로드
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          if (kDebugMode) print('Interstitial ad loaded');

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isInterstitialAdReady = false;
              _loadInterstitialAd(); // 다음 광고 미리 로드
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _isInterstitialAdReady = false;
              _loadInterstitialAd();
              if (kDebugMode) print('Interstitial ad failed to show: $error');
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isInterstitialAdReady = false;
          if (kDebugMode) print('Interstitial ad failed to load: $error');
          // 5초 후 재시도
          Future.delayed(const Duration(seconds: 5), _loadInterstitialAd);
        },
      ),
    );
  }

  /// 전면 광고 표시 (준비되어 있으면)
  Future<bool> showInterstitialAd() async {
    if (_isInterstitialAdReady && _interstitialAd != null) {
      await _interstitialAd!.show();
      return true;
    }
    return false;
  }

  /// 액션 카운트 증가 및 조건 충족 시 광고 표시
  /// 모임 참여, 모임 나가기, 모임 생성 완료 시 호출
  Future<void> recordActionAndMaybeShowAd() async {
    _actionCount++;
    if (_actionCount >= _actionsBeforeAd) {
      _actionCount = 0;
      await showInterstitialAd();
    }
  }

  /// 특정 시점에 강제로 광고 표시 (게임 종료 후 등)
  Future<void> showAdOnGameEnd() async {
    await showInterstitialAd();
  }

  /// 광고 리소스 해제
  void dispose() {
    _interstitialAd?.dispose();
  }
}
