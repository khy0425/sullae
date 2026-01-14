import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/meeting_model.dart';
import '../services/analytics_service.dart';
import '../services/geolocation_service.dart';
import '../services/meeting_service.dart';
import '../services/notification_service.dart';
import '../services/system_message_service.dart';

/// 시간대 필터
enum TimeFilter {
  all,      // 전체
  today,    // 오늘
  tomorrow, // 내일
  thisWeek, // 이번 주
}

/// 연령대 필터
enum AgeGroupFilter {
  all,      // 전체
  teens,    // 10대
  twenties, // 20대
  thirties, // 30대
  fortyPlus,// 40대 이상
}

class MeetingProvider with ChangeNotifier {
  final MeetingService _meetingService = MeetingService();
  final SystemMessageService _systemMessageService = SystemMessageService();
  final NotificationService _notificationService = NotificationService();
  final GeolocationService _geolocationService = GeolocationService();

  List<MeetingModel> _meetings = [];
  List<MeetingModel> _myMeetings = [];
  MeetingModel? _currentMeeting;
  bool _isLoading = false;
  String? _error;

  // 필터 상태
  GameType? _selectedGameType;
  String _searchQuery = '';
  TimeFilter _timeFilter = TimeFilter.all;
  bool _showRecruitingOnly = true; // 기본: 모집중만
  Region _selectedRegion = Region.all;
  AgeGroupFilter _ageGroupFilter = AgeGroupFilter.all;
  GroupSize? _selectedGroupSize;
  Difficulty? _selectedDifficulty;

  // 위치 기반 필터 상태
  Position? _userPosition;
  DistanceRange? _distanceFilter;
  bool _sortByDistance = false;
  Map<String, double> _meetingDistances = {}; // meetingId -> distanceKm

  // 페이지네이션 상태
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _usePagination = true; // 페이지네이션 모드 사용 여부

  StreamSubscription? _meetingsSubscription;
  StreamSubscription? _myMeetingsSubscription;
  StreamSubscription? _currentMeetingSubscription;

  List<MeetingModel> get meetings => _meetings;
  List<MeetingModel> get myMeetings => _myMeetings;
  MeetingModel? get currentMeeting => _currentMeeting;
  bool get isLoading => _isLoading;
  String? get error => _error;
  GameType? get selectedGameType => _selectedGameType;
  String get searchQuery => _searchQuery;
  TimeFilter get timeFilter => _timeFilter;
  bool get showRecruitingOnly => _showRecruitingOnly;
  Region get selectedRegion => _selectedRegion;
  AgeGroupFilter get ageGroupFilter => _ageGroupFilter;
  GroupSize? get selectedGroupSize => _selectedGroupSize;
  Difficulty? get selectedDifficulty => _selectedDifficulty;

  // 페이지네이션 Getters
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  bool get canLoadMore => _hasMore && !_isLoadingMore && !_isLoading;

  // 위치 기반 Getters
  Position? get userPosition => _userPosition;
  DistanceRange? get distanceFilter => _distanceFilter;
  bool get sortByDistance => _sortByDistance;
  bool get hasUserLocation => _userPosition != null;

  /// 모임의 거리 정보 가져오기 (km)
  double? getDistanceForMeeting(String meetingId) => _meetingDistances[meetingId];

  /// 거리 표시 문자열 (예: "1.2km", "500m")
  String getDistanceText(String meetingId) {
    final distance = _meetingDistances[meetingId];
    if (distance == null) return '';
    if (distance < 1) {
      return '${(distance * 1000).round()}m';
    }
    return '${distance.toStringAsFixed(1)}km';
  }

  /// 필터 적용된 모임 목록
  List<MeetingModel> get filteredMeetings {
    var result = _meetings.toList();

    // 1. 모집중 필터
    if (_showRecruitingOnly) {
      result = result.where((m) => m.status == MeetingStatus.recruiting).toList();
    }

    // 2. 게임 타입 필터
    if (_selectedGameType != null) {
      result = result.where((m) => m.gameType == _selectedGameType).toList();
    }

    // 3. 시간대 필터
    final now = DateTime.now();
    switch (_timeFilter) {
      case TimeFilter.today:
        result = result.where((m) =>
            m.meetingTime.year == now.year &&
            m.meetingTime.month == now.month &&
            m.meetingTime.day == now.day).toList();
        break;
      case TimeFilter.tomorrow:
        final tomorrow = now.add(const Duration(days: 1));
        result = result.where((m) =>
            m.meetingTime.year == tomorrow.year &&
            m.meetingTime.month == tomorrow.month &&
            m.meetingTime.day == tomorrow.day).toList();
        break;
      case TimeFilter.thisWeek:
        final weekEnd = now.add(Duration(days: 7 - now.weekday));
        result = result.where((m) =>
            m.meetingTime.isAfter(now.subtract(const Duration(days: 1))) &&
            m.meetingTime.isBefore(weekEnd.add(const Duration(days: 1)))).toList();
        break;
      case TimeFilter.all:
        break;
    }

    // 4. 검색어 필터
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((m) =>
          m.title.toLowerCase().contains(query) ||
          m.location.toLowerCase().contains(query) ||
          m.hostNickname.toLowerCase().contains(query) ||
          m.description.toLowerCase().contains(query)).toList();
    }

    // 5. 지역 필터
    if (_selectedRegion.province != Province.all) {
      result = result.where((m) {
        // 같은 광역시/도인지 확인
        if (m.region.province != _selectedRegion.province) return false;
        // 세부 지역이 지정되지 않았으면 광역시/도만 일치하면 OK
        if (_selectedRegion.district == null) return true;
        // 세부 지역까지 일치하는지 확인
        return m.region.district == _selectedRegion.district;
      }).toList();
    }

    // 6. 연령대 필터
    if (_ageGroupFilter != AgeGroupFilter.all) {
      result = result.where((m) {
        if (m.targetAgeGroups.isEmpty) return true; // 상관없음은 모두 포함
        switch (_ageGroupFilter) {
          case AgeGroupFilter.teens:
            return m.targetAgeGroups.isEmpty || m.targetAgeGroups.contains('10s');
          case AgeGroupFilter.twenties:
            return m.targetAgeGroups.isEmpty || m.targetAgeGroups.contains('20s');
          case AgeGroupFilter.thirties:
            return m.targetAgeGroups.isEmpty || m.targetAgeGroups.contains('30s');
          case AgeGroupFilter.fortyPlus:
            return m.targetAgeGroups.isEmpty || m.targetAgeGroups.contains('40s+');
          case AgeGroupFilter.all:
            return true;
        }
      }).toList();
    }

    // 7. 인원 규모 필터
    if (_selectedGroupSize != null) {
      result = result.where((m) => m.groupSize == _selectedGroupSize).toList();
    }

    // 8. 난이도/분위기 필터
    if (_selectedDifficulty != null) {
      result = result.where((m) => m.difficulty == _selectedDifficulty).toList();
    }

    // 9. 거리 필터 (위치 정보가 있을 때만)
    if (_distanceFilter != null && _userPosition != null) {
      final maxKm = _distanceFilter!.maxKm;
      if (maxKm != null) {
        result = result.where((m) {
          final distance = _meetingDistances[m.id];
          return distance != null && distance <= maxKm;
        }).toList();
      }
    }

    // 정렬: 거리순 또는 시간순
    if (_sortByDistance && _userPosition != null) {
      // 거리순 정렬 (가까운 곳 먼저)
      result.sort((a, b) {
        final distA = _meetingDistances[a.id] ?? double.infinity;
        final distB = _meetingDistances[b.id] ?? double.infinity;
        return distA.compareTo(distB);
      });
    } else {
      // 시간순 정렬 (가까운 시간 먼저)
      result.sort((a, b) => a.meetingTime.compareTo(b.meetingTime));
    }

    return result;
  }

  /// 활성화된 필터 개수
  int get activeFilterCount {
    int count = 0;
    if (_selectedGameType != null) count++;
    if (_timeFilter != TimeFilter.all) count++;
    if (!_showRecruitingOnly) count++;
    if (_selectedRegion.province != Province.all) count++;
    if (_ageGroupFilter != AgeGroupFilter.all) count++;
    if (_selectedGroupSize != null) count++;
    if (_selectedDifficulty != null) count++;
    if (_distanceFilter != null) count++;
    return count;
  }

  /// 필터가 적용되어 있는지
  bool get hasActiveFilters => activeFilterCount > 0;

  // ============== 위치 기반 API ==============

  /// 현재 위치 업데이트 및 거리 계산
  Future<bool> updateUserLocation() async {
    final permissionResult = await _geolocationService.checkAndRequestPermission();

    if (!permissionResult.isGranted) {
      if (kDebugMode) print('Location permission not granted: $permissionResult');
      return false;
    }

    final position = await _geolocationService.getCurrentPosition();
    if (position == null) return false;

    _userPosition = position;
    _calculateDistances();
    notifyListeners();
    return true;
  }

  /// 모든 모임에 대해 거리 계산
  void _calculateDistances() {
    if (_userPosition == null) return;

    _meetingDistances.clear();

    for (final meeting in _meetings) {
      if (meeting.latitude != null && meeting.longitude != null) {
        final distanceMeters = Geolocator.distanceBetween(
          _userPosition!.latitude,
          _userPosition!.longitude,
          meeting.latitude!,
          meeting.longitude!,
        );
        _meetingDistances[meeting.id] = distanceMeters / 1000;
      }
    }
  }

  /// 거리 필터 설정
  void setDistanceFilter(DistanceRange? range) {
    _distanceFilter = range;
    notifyListeners();
  }

  /// 거리순 정렬 토글
  void setSortByDistance(bool value) {
    _sortByDistance = value;
    notifyListeners();
  }

  /// 위치 정보 초기화
  void clearUserLocation() {
    _userPosition = null;
    _meetingDistances.clear();
    _distanceFilter = null;
    _sortByDistance = false;
    notifyListeners();
  }

  /// 내 주변 모임 탐색 (거리순)
  Future<List<MeetingWithDistance>> getNearbyMeetings({
    double maxDistanceKm = 10.0,
  }) async {
    if (_userPosition == null) {
      final success = await updateUserLocation();
      if (!success) return [];
    }

    return _meetingService.getNearbyMeetings(
      userLat: _userPosition!.latitude,
      userLon: _userPosition!.longitude,
      maxDistanceKm: maxDistanceKm,
    );
  }

  // ============== 페이지네이션 API ==============

  /// 첫 페이지 로드 (무한 스크롤 시작)
  Future<void> loadFirstPage() async {
    if (_isLoading) return;

    _setLoading(true);
    _meetings = [];
    _lastDocument = null;
    _hasMore = true;
    _error = null;

    try {
      final result = await _meetingService.getFirstPage();
      _meetings = result.items;
      _lastDocument = result.lastDocument;
      _hasMore = result.hasMore;
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  /// 다음 페이지 로드 (무한 스크롤)
  Future<void> loadMoreMeetings() async {
    if (!canLoadMore || _lastDocument == null) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await _meetingService.getNextPage(
        lastDocument: _lastDocument!,
      );
      _meetings = [..._meetings, ...result.items];
      _lastDocument = result.lastDocument;
      _hasMore = result.hasMore;
      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _isLoadingMore = false;
      _setError(e.toString());
    }
  }

  /// 새로고침 (Pull to Refresh)
  Future<void> refreshMeetings() async {
    await loadFirstPage();
  }

  /// 첫 페이지 실시간 구독 (페이지네이션 + 실시간 업데이트)
  void subscribeToFirstPage() {
    _meetingsSubscription?.cancel();
    _meetings = [];
    _lastDocument = null;
    _hasMore = true;
    _usePagination = true;

    _meetingsSubscription = _meetingService.getFirstPageStream().listen(
      (result) {
        _meetings = result.items;
        _lastDocument = result.lastDocument;
        _hasMore = result.hasMore;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  // 모집중 모임 목록 구독 (기존 방식 - 호환성 유지)
  void subscribeToMeetings() {
    _meetingsSubscription?.cancel();
    _usePagination = false;
    _meetingsSubscription = _meetingService.getRecruitingMeetings().listen(
      (meetings) {
        _meetings = meetings;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  // 내 모임 목록 구독
  void subscribeToMyMeetings(String userId) {
    _myMeetingsSubscription?.cancel();
    _myMeetingsSubscription = _meetingService.getMyMeetings(userId).listen(
      (meetings) {
        _myMeetings = meetings;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  // 특정 모임 구독
  void subscribeToMeeting(String meetingId) {
    _currentMeetingSubscription?.cancel();
    _currentMeetingSubscription = _meetingService.getMeetingStream(meetingId).listen(
      (meeting) {
        _currentMeeting = meeting;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  // 게임 타입 필터 설정
  void setGameTypeFilter(GameType? gameType) {
    _selectedGameType = gameType;
    notifyListeners();
  }

  // 검색어 설정
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // 시간대 필터 설정
  void setTimeFilter(TimeFilter filter) {
    _timeFilter = filter;
    notifyListeners();
  }

  // 모집중만 보기 설정
  void setShowRecruitingOnly(bool value) {
    _showRecruitingOnly = value;
    notifyListeners();
  }

  // 지역 필터 설정
  void setRegionFilter(Region region) {
    _selectedRegion = region;
    notifyListeners();
  }

  // 연령대 필터 설정
  void setAgeGroupFilter(AgeGroupFilter ageGroup) {
    _ageGroupFilter = ageGroup;
    notifyListeners();
  }

  // 인원 규모 필터 설정
  void setGroupSizeFilter(GroupSize? size) {
    _selectedGroupSize = size;
    notifyListeners();
  }

  // 난이도 필터 설정
  void setDifficultyFilter(Difficulty? difficulty) {
    _selectedDifficulty = difficulty;
    notifyListeners();
  }

  // 모든 필터 초기화
  void clearAllFilters() {
    _selectedGameType = null;
    _searchQuery = '';
    _timeFilter = TimeFilter.all;
    _showRecruitingOnly = true;
    _selectedRegion = Region.all;
    _ageGroupFilter = AgeGroupFilter.all;
    _selectedGroupSize = null;
    _selectedDifficulty = null;
    notifyListeners();
  }

  /// 최대 생성 가능 모임 수
  int get maxActiveMeetings => MeetingService.maxActiveMeetingsPerUser;

  /// 모임 생성 가능 여부 확인
  Future<bool> canCreateMeeting(String userId) async {
    return await _meetingService.canCreateMeeting(userId);
  }

  /// 현재 활성 모임 개수 조회
  Future<int> getActiveHostedMeetingsCount(String userId) async {
    return await _meetingService.getActiveHostedMeetingsCount(userId);
  }

  // 모임 생성
  Future<String?> createMeeting({
    required String title,
    required String description,
    required String hostId,
    required String hostNickname,
    required GameType gameType,
    required String location,
    String? locationDetail,
    required DateTime meetingTime,
    required int maxParticipants,
    Region? region,
    Difficulty? difficulty,
    List<String>? targetAgeGroups,
    String? externalChatLink,
  }) async {
    _setLoading(true);

    try {
      final meeting = MeetingModel(
        id: '',
        title: title,
        description: description,
        hostId: hostId,
        hostNickname: hostNickname,
        gameType: gameType,
        location: location,
        locationDetail: locationDetail,
        meetingTime: meetingTime,
        maxParticipants: maxParticipants,
        currentParticipants: 1,
        participantIds: [hostId],
        status: MeetingStatus.recruiting,
        createdAt: DateTime.now(),
        joinCode: MeetingModel.generateJoinCode(),
        region: region ?? Region.all,
        difficulty: difficulty ?? Difficulty.casual,
        targetAgeGroups: targetAgeGroups ?? [],
        externalChatLink: externalChatLink,
      );

      final meetingId = await _meetingService.createMeeting(meeting);

      // Analytics: 모임 생성 이벤트
      AnalyticsService().logMeetingCreated(
        meetingId: meetingId,
        gameType: gameType.name,
        region: region?.toStorageString() ?? 'all',
        maxParticipants: maxParticipants,
      );

      // 시스템 메시지 전송 (실패해도 모임 생성은 완료) - 타임아웃 3초
      try {
        await Future.any([
          Future(() async {
            await _systemMessageService.sendSystemMessage(meetingId, '모임이 생성되었습니다.');
            await _systemMessageService.sendJoinMessage(meetingId, hostNickname);
          }),
          Future.delayed(const Duration(seconds: 3)),
        ]);
      } catch (_) {
        // 채팅 메시지 실패는 무시
      }

      // 모임 시작 30분 전 리마인더 예약
      _notificationService.scheduleMeetingReminder(
        meetingId: meetingId,
        title: title,
        meetingTime: meetingTime,
      );

      _setLoading(false);

      // 광고는 AdProvider가 이벤트를 구독하여 처리
      // 모임 로직은 광고의 존재를 모른다

      return meetingId;
    } on MeetingLimitException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return null;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return null;
    }
  }

  // 모임 참여
  Future<bool> joinMeeting(String meetingId, String userId, String nickname) async {
    _setLoading(true);

    try {
      // 참여 전 모임 정보 가져오기 (방장 알림용)
      final meeting = await _meetingService.getMeeting(meetingId);

      final success = await _meetingService.joinMeeting(meetingId, userId);
      if (success && meeting != null) {
        // Analytics: 모임 참가 이벤트
        AnalyticsService().logMeetingJoined(
          meetingId: meetingId,
          gameType: meeting.gameType.name,
        );

        await _systemMessageService.sendJoinMessage(meetingId, nickname);

        // 방장에게 새 참가자 알림 전송
        final notification = NotificationTemplates.newParticipant(
          nickname: nickname,
          meetingTitle: meeting.title,
        );
        _notificationService.sendNotificationToUser(
          userId: meeting.hostId,
          title: notification.title,
          body: notification.body,
          meetingId: meetingId,
          type: NotificationType.newParticipant,
        );

        // 참가자에게도 모임 시작 30분 전 리마인더 예약
        _notificationService.scheduleMeetingReminder(
          meetingId: meetingId,
          title: meeting.title,
          meetingTime: meeting.meetingTime,
        );
      }
      _setLoading(false);
      return success;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // 모임 나가기
  Future<bool> leaveMeeting(String meetingId, String userId, String nickname) async {
    _setLoading(true);

    try {
      final success = await _meetingService.leaveMeeting(meetingId, userId);
      if (success) {
        // Analytics: 모임 퇴장 이벤트
        AnalyticsService().logMeetingLeft(meetingId: meetingId);

        await _systemMessageService.sendLeaveMessage(meetingId, nickname);

        // 예약된 리마인더 취소
        _notificationService.cancelMeetingReminder(meetingId);
      }
      _setLoading(false);
      return success;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // 모임 상태 변경
  Future<void> updateStatus(String meetingId, MeetingStatus status) async {
    await _meetingService.updateMeetingStatus(meetingId, status);
  }

  /// 게임 시작 (방장만)
  Future<bool> startGame(String meetingId, String hostId) async {
    _setLoading(true);
    try {
      final meeting = await _meetingService.getMeeting(meetingId);
      final success = await _meetingService.startGame(meetingId, hostId);

      if (success && meeting != null) {
        // Analytics: 게임 시작 이벤트
        AnalyticsService().logGameStarted(
          gameId: meetingId,
          gameType: meeting.gameType.name,
          participantCount: meeting.currentParticipants,
        );

        // 참가자들에게 게임 시작 알림 전송
        final notification = NotificationTemplates.gameStarted(
          meetingTitle: meeting.title,
        );
        _notificationService.notifyMeetingParticipants(
          meetingId: meetingId,
          participantIds: meeting.participantIds,
          title: notification.title,
          body: notification.body,
          excludeUserId: hostId, // 방장 제외
        );
      }

      _setLoading(false);
      return success;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// 게임 종료 및 후기 요청 알림
  Future<void> endGame(String meetingId, String hostId, String hostNickname) async {
    _setLoading(true);
    try {
      final meeting = await _meetingService.getMeeting(meetingId);
      await _meetingService.endGame(meetingId, hostId);

      // 참가자들에게 후기 요청 알림 전송 (1분 후)
      if (meeting != null) {
        Future.delayed(const Duration(minutes: 1), () {
          final notification = NotificationTemplates.reviewRequest(
            meetingTitle: meeting.title,
            hostNickname: hostNickname,
          );
          _notificationService.notifyMeetingParticipants(
            meetingId: meetingId,
            participantIds: meeting.participantIds,
            title: notification.title,
            body: notification.body,
            excludeUserId: hostId, // 방장 제외
          );
        });
      }

      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // 모임 취소
  Future<void> cancelMeeting(String meetingId, String hostId) async {
    // 취소 전 모임 정보 가져오기 (참가자 알림용)
    final meeting = await _meetingService.getMeeting(meetingId);

    await _meetingService.cancelMeeting(meetingId, hostId);
    await _systemMessageService.sendSystemMessage(meetingId, '모임이 취소되었습니다.');

    // 참가자들에게 취소 알림 전송
    if (meeting != null) {
      final notification = NotificationTemplates.meetingCancelled(
        meetingTitle: meeting.title,
      );
      _notificationService.notifyMeetingParticipants(
        meetingId: meetingId,
        participantIds: meeting.participantIds,
        title: notification.title,
        body: notification.body,
        excludeUserId: hostId, // 방장 제외
      );
    }
  }

  // 모임 삭제
  Future<bool> deleteMeeting(String meetingId, String hostId) async {
    _setLoading(true);
    try {
      final success = await _meetingService.deleteMeeting(meetingId, hostId);
      _setLoading(false);
      return success;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // 방장 위임
  Future<bool> transferHost(String meetingId, String currentHostId, String newHostId, String newHostNickname) async {
    _setLoading(true);
    try {
      // 위임 전 모임 정보 가져오기
      final meeting = await _meetingService.getMeeting(meetingId);

      final success = await _meetingService.transferHost(meetingId, currentHostId, newHostId);
      if (success) {
        await _systemMessageService.sendHostTransferMessage(meetingId, currentHostId, newHostNickname);

        // 새 방장에게 알림 전송
        if (meeting != null) {
          final notification = NotificationTemplates.hostTransferred(
            meetingTitle: meeting.title,
          );
          _notificationService.sendNotificationToUser(
            userId: newHostId,
            title: notification.title,
            body: notification.body,
            meetingId: meetingId,
            type: NotificationType.hostTransfer,
          );
        }
      }
      _setLoading(false);
      return success;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // 참가 코드로 모임 찾기
  Future<MeetingModel?> findMeetingByCode(String code) async {
    return await _meetingService.getMeetingByJoinCode(code);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearCurrentMeeting() {
    _currentMeetingSubscription?.cancel();
    _currentMeeting = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _meetingsSubscription?.cancel();
    _myMeetingsSubscription?.cancel();
    _currentMeetingSubscription?.cancel();
    super.dispose();
  }
}
