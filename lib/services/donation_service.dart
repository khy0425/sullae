import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 개발자 응원 (커피 한 잔 사주기) 서비스
///
/// 설계 철학:
/// - 설정 화면에만 존재 (UX 방해 없음)
/// - 첫 게임 종료 시 한 번만 토스트로 안내
/// - 실패해도 앱 흐름에 영향 없음
/// - 기능과 연결되지 않음 (순수 응원)
///
/// 이 기능의 목적:
/// - 수익 최대화 ❌
/// - "진짜 팬" 존재 확인 ⭕
/// - 감정적 연결 ⭕
class DonationService {
  static final DonationService _instance = DonationService._internal();
  factory DonationService() => _instance;
  DonationService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;

  // 상품 ID
  static const String coffeeProductId = 'coffee_donation';

  // 첫 게임 종료 후 안내 표시 여부
  static const String _hasShownHintKey = 'donation_hint_shown';

  bool _isAvailable = false;
  ProductDetails? _coffeeProduct;

  /// IAP 초기화
  Future<void> initialize() async {
    try {
      _isAvailable = await _iap.isAvailable();
      if (!_isAvailable) {
        if (kDebugMode) {
          print('DonationService: IAP not available');
        }
        return;
      }

      // 상품 정보 로드
      final response = await _iap.queryProductDetails({coffeeProductId});
      if (response.productDetails.isNotEmpty) {
        _coffeeProduct = response.productDetails.first;
        if (kDebugMode) {
          print('DonationService: Product loaded - ${_coffeeProduct?.price}');
        }
      }
    } catch (e) {
      // 초기화 실패해도 앱 흐름에 영향 없음
      if (kDebugMode) {
        print('DonationService: Init failed - $e');
      }
    }
  }

  /// 커피 한 잔 사주기 가능 여부
  bool get isAvailable => _isAvailable && _coffeeProduct != null;

  /// 커피 가격 문자열
  String get coffeePrice => _coffeeProduct?.price ?? (Platform.isIOS ? '\$0.99' : '₩1,000');

  /// 커피 구매
  Future<bool> buyCoffee() async {
    if (!isAvailable || _coffeeProduct == null) {
      return false;
    }

    try {
      final purchaseParam = PurchaseParam(productDetails: _coffeeProduct!);
      final result = await _iap.buyConsumable(purchaseParam: purchaseParam);
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('DonationService: Purchase failed - $e');
      }
      return false;
    }
  }

  /// 첫 게임 종료 후 안내 표시 여부 확인
  Future<bool> shouldShowHint() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return !(prefs.getBool(_hasShownHintKey) ?? false);
    } catch (e) {
      return false;
    }
  }

  /// 안내 표시 완료 기록
  Future<void> markHintShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasShownHintKey, true);
    } catch (e) {
      // 실패해도 무시
    }
  }
}
