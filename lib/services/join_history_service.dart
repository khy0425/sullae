import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 참가 기록 서비스
/// - 최근 사용한 참가 코드 저장
/// - 즐겨찾기 호스트 관리
/// - 로컬 저장소 사용
class JoinHistoryService {
  static final JoinHistoryService _instance = JoinHistoryService._internal();
  factory JoinHistoryService() => _instance;
  JoinHistoryService._internal();

  static const String _recentCodesKey = 'recent_join_codes';
  static const String _favoriteHostsKey = 'favorite_hosts';
  static const String _joinHistoryKey = 'join_history';
  static const int _maxRecentCodes = 5;
  static const int _maxHistory = 20;

  /// 최근 사용한 참가 코드 저장
  Future<void> saveRecentCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final codes = await getRecentCodes();

    // 중복 제거 후 맨 앞에 추가
    codes.remove(code.toUpperCase());
    codes.insert(0, code.toUpperCase());

    // 최대 개수 유지
    while (codes.length > _maxRecentCodes) {
      codes.removeLast();
    }

    await prefs.setStringList(_recentCodesKey, codes);
  }

  /// 최근 사용한 참가 코드 목록
  Future<List<String>> getRecentCodes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentCodesKey) ?? [];
  }

  /// 최근 코드 삭제
  Future<void> removeRecentCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final codes = await getRecentCodes();
    codes.remove(code.toUpperCase());
    await prefs.setStringList(_recentCodesKey, codes);
  }

  /// 즐겨찾기 호스트 추가
  Future<void> addFavoriteHost(FavoriteHost host) async {
    final prefs = await SharedPreferences.getInstance();
    final hosts = await getFavoriteHosts();

    // 이미 있으면 업데이트
    hosts.removeWhere((h) => h.hostId == host.hostId);
    hosts.insert(0, host);

    final jsonList = hosts.map((h) => h.toJson()).toList();
    await prefs.setString(_favoriteHostsKey, jsonEncode(jsonList));
  }

  /// 즐겨찾기 호스트 제거
  Future<void> removeFavoriteHost(String hostId) async {
    final prefs = await SharedPreferences.getInstance();
    final hosts = await getFavoriteHosts();

    hosts.removeWhere((h) => h.hostId == hostId);

    final jsonList = hosts.map((h) => h.toJson()).toList();
    await prefs.setString(_favoriteHostsKey, jsonEncode(jsonList));
  }

  /// 즐겨찾기 호스트 목록
  Future<List<FavoriteHost>> getFavoriteHosts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_favoriteHostsKey);

    if (jsonString == null || jsonString.isEmpty) return [];

    try {
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList
          .map((json) => FavoriteHost.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// 즐겨찾기 여부 확인
  Future<bool> isFavoriteHost(String hostId) async {
    final hosts = await getFavoriteHosts();
    return hosts.any((h) => h.hostId == hostId);
  }

  /// 참가 기록 저장
  Future<void> saveJoinHistory(JoinHistoryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getJoinHistory();

    // 같은 모임 제거 후 맨 앞에 추가
    history.removeWhere((h) => h.meetingId == item.meetingId);
    history.insert(0, item);

    // 최대 개수 유지
    while (history.length > _maxHistory) {
      history.removeLast();
    }

    final jsonList = history.map((h) => h.toJson()).toList();
    await prefs.setString(_joinHistoryKey, jsonEncode(jsonList));
  }

  /// 참가 기록 목록
  Future<List<JoinHistoryItem>> getJoinHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_joinHistoryKey);

    if (jsonString == null || jsonString.isEmpty) return [];

    try {
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList
          .map((json) => JoinHistoryItem.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// 모든 기록 삭제
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentCodesKey);
    await prefs.remove(_favoriteHostsKey);
    await prefs.remove(_joinHistoryKey);
  }
}

/// 즐겨찾기 호스트
class FavoriteHost {
  final String hostId;
  final String nickname;
  final DateTime addedAt;
  final double? rating;

  FavoriteHost({
    required this.hostId,
    required this.nickname,
    required this.addedAt,
    this.rating,
  });

  factory FavoriteHost.fromJson(Map<String, dynamic> json) {
    return FavoriteHost(
      hostId: json['hostId'] ?? '',
      nickname: json['nickname'] ?? '',
      addedAt: DateTime.tryParse(json['addedAt'] ?? '') ?? DateTime.now(),
      rating: json['rating']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hostId': hostId,
      'nickname': nickname,
      'addedAt': addedAt.toIso8601String(),
      'rating': rating,
    };
  }
}

/// 참가 기록 항목
class JoinHistoryItem {
  final String meetingId;
  final String title;
  final String hostNickname;
  final String gameTypeName;
  final DateTime meetingTime;
  final DateTime joinedAt;
  final String joinCode;

  JoinHistoryItem({
    required this.meetingId,
    required this.title,
    required this.hostNickname,
    required this.gameTypeName,
    required this.meetingTime,
    required this.joinedAt,
    required this.joinCode,
  });

  factory JoinHistoryItem.fromJson(Map<String, dynamic> json) {
    return JoinHistoryItem(
      meetingId: json['meetingId'] ?? '',
      title: json['title'] ?? '',
      hostNickname: json['hostNickname'] ?? '',
      gameTypeName: json['gameTypeName'] ?? '',
      meetingTime: DateTime.tryParse(json['meetingTime'] ?? '') ?? DateTime.now(),
      joinedAt: DateTime.tryParse(json['joinedAt'] ?? '') ?? DateTime.now(),
      joinCode: json['joinCode'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'meetingId': meetingId,
      'title': title,
      'hostNickname': hostNickname,
      'gameTypeName': gameTypeName,
      'meetingTime': meetingTime.toIso8601String(),
      'joinedAt': joinedAt.toIso8601String(),
      'joinCode': joinCode,
    };
  }
}
