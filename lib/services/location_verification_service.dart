import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// 위치 기반 참석 확인 서비스
/// - 모임 장소 근처에 있는지 확인
/// - 체크인 시스템
/// - 유령 참가자 방지
class LocationVerificationService {
  static final LocationVerificationService _instance = LocationVerificationService._internal();
  factory LocationVerificationService() => _instance;
  LocationVerificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 체크인 허용 반경 (미터) - 대략적 위치 사용으로 여유있게 설정
  static const double checkInRadiusMeters = 1000; // 1km 이내

  /// 게임 중 최대 허용 거리 (미터)
  static const double maxGameDistanceMeters = 3000; // 3km 이내

  /// 체크인 유효 시간 (모임 시작 전/후)
  static const Duration checkInWindowBefore = Duration(minutes: 30);
  static const Duration checkInWindowAfter = Duration(minutes: 15);

  /// 노쇼 의심 시간 (게임 시작 후 이 시간이 지나면 위치 확인)
  static const Duration noShowCheckDelay = Duration(minutes: 30);

  /// 두 좌표 사이의 거리 계산 (Haversine 공식)
  double calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    const double earthRadius = 6371000; // 미터

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degree) => degree * pi / 180;

  /// 체크인 가능 여부 확인
  CheckInResult canCheckIn({
    required double userLat,
    required double userLon,
    required double meetingLat,
    required double meetingLon,
    required DateTime meetingTime,
  }) {
    final now = DateTime.now();
    final distance = calculateDistance(userLat, userLon, meetingLat, meetingLon);

    // 시간 체크
    final windowStart = meetingTime.subtract(checkInWindowBefore);
    final windowEnd = meetingTime.add(checkInWindowAfter);

    if (now.isBefore(windowStart)) {
      final remaining = windowStart.difference(now);
      return CheckInResult.tooEarly(remaining);
    }

    if (now.isAfter(windowEnd)) {
      return CheckInResult.tooLate();
    }

    // 거리 체크
    if (distance > checkInRadiusMeters) {
      return CheckInResult.tooFar(distance.round());
    }

    return CheckInResult.success(distance.round());
  }

  /// 체크인 수행
  Future<bool> checkIn({
    required String meetingId,
    required String odId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _firestore
          .collection('meetings')
          .doc(meetingId)
          .collection('check_ins')
          .doc(odId)
          .set({
        'userId': odId,
        'latitude': latitude,
        'longitude': longitude,
        'checkedInAt': Timestamp.now(),
        'isVerified': true,
      });

      if (kDebugMode) print('Check-in successful: $odId at $meetingId');
      return true;
    } catch (e) {
      if (kDebugMode) print('Check-in failed: $e');
      return false;
    }
  }

  /// 체크인 여부 확인
  Future<bool> hasCheckedIn(String meetingId, String odId) async {
    final doc = await _firestore
        .collection('meetings')
        .doc(meetingId)
        .collection('check_ins')
        .doc(odId)
        .get();

    return doc.exists;
  }

  /// 체크인한 참가자 목록 조회
  Future<List<CheckInInfo>> getCheckedInParticipants(String meetingId) async {
    final snapshot = await _firestore
        .collection('meetings')
        .doc(meetingId)
        .collection('check_ins')
        .get();

    return snapshot.docs.map((doc) => CheckInInfo.fromFirestore(doc)).toList();
  }

  /// 체크인한 참가자 수 조회
  Future<int> getCheckedInCount(String meetingId) async {
    final snapshot = await _firestore
        .collection('meetings')
        .doc(meetingId)
        .collection('check_ins')
        .get();

    return snapshot.docs.length;
  }

  /// 실시간 체크인 스트림
  Stream<List<CheckInInfo>> getCheckInStream(String meetingId) {
    return _firestore
        .collection('meetings')
        .doc(meetingId)
        .collection('check_ins')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => CheckInInfo.fromFirestore(doc)).toList());
  }

  /// 위치 업데이트 (게임 중)
  Future<void> updateLocation({
    required String meetingId,
    required String odId,
    required double latitude,
    required double longitude,
  }) async {
    await _firestore
        .collection('meetings')
        .doc(meetingId)
        .collection('locations')
        .doc(odId)
        .set({
      'userId': odId,
      'latitude': latitude,
      'longitude': longitude,
      'updatedAt': Timestamp.now(),
    });
  }

  /// 참가자들의 실시간 위치 스트림
  Stream<List<ParticipantLocation>> getParticipantLocationsStream(String meetingId) {
    return _firestore
        .collection('meetings')
        .doc(meetingId)
        .collection('locations')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ParticipantLocation.fromFirestore(doc)).toList());
  }

  /// 게임 영역 이탈 확인
  bool isOutOfBounds({
    required double userLat,
    required double userLon,
    required double centerLat,
    required double centerLon,
    double? customRadius,
  }) {
    final distance = calculateDistance(userLat, userLon, centerLat, centerLon);
    return distance > (customRadius ?? maxGameDistanceMeters);
  }

  /// 노쇼 의심 여부 확인
  /// 게임 시작 후 일정 시간이 지났는데 모임 장소에서 멀리 있으면 의심
  NoShowCheckResult checkNoShow({
    double? userLat,
    double? userLon,
    required double meetingLat,
    required double meetingLon,
    required DateTime meetingTime,
    required bool hasCheckedIn,
  }) {
    final now = DateTime.now();
    final checkTime = meetingTime.add(noShowCheckDelay);

    // 아직 확인 시간이 안됨
    if (now.isBefore(checkTime)) {
      return NoShowCheckResult.tooEarly();
    }

    // 이미 체크인함 - OK
    if (hasCheckedIn) {
      return NoShowCheckResult.checkedIn();
    }

    // 위치 정보 없음 - 위치 없으면 그냥 패스
    if (userLat == null || userLon == null) {
      return NoShowCheckResult.noLocation();
    }

    // 거리 확인
    final distance = calculateDistance(userLat, userLon, meetingLat, meetingLon);

    if (distance > maxGameDistanceMeters) {
      return NoShowCheckResult.suspected(distance.round());
    }

    return NoShowCheckResult.nearBy(distance.round());
  }

  /// 참가자들의 노쇼 의심 목록 조회
  Future<List<NoShowSuspect>> getNoShowSuspects({
    required String meetingId,
    required List<String> participantIds,
    required double meetingLat,
    required double meetingLon,
    required DateTime meetingTime,
  }) async {
    final suspects = <NoShowSuspect>[];
    final checkIns = await getCheckedInParticipants(meetingId);
    final checkedInIds = checkIns.map((c) => c.odId).toSet();

    // 체크인 안한 참가자들만 확인
    final notCheckedIn = participantIds.where((id) => !checkedInIds.contains(id));

    for (final odId in notCheckedIn) {
      // 해당 사용자의 마지막 위치 조회 (있으면)
      final locationDoc = await _firestore
          .collection('meetings')
          .doc(meetingId)
          .collection('locations')
          .doc(odId)
          .get();

      double? userLat;
      double? userLon;

      if (locationDoc.exists) {
        final data = locationDoc.data();
        userLat = data?['latitude']?.toDouble();
        userLon = data?['longitude']?.toDouble();
      }

      final result = checkNoShow(
        userLat: userLat,
        userLon: userLon,
        meetingLat: meetingLat,
        meetingLon: meetingLon,
        meetingTime: meetingTime,
        hasCheckedIn: false,
      );

      if (result.isSuspected) {
        suspects.add(NoShowSuspect(
          odId: odId,
          distanceMeters: result.distanceMeters,
          lastLocationTime: locationDoc.exists
              ? (locationDoc.data()?['updatedAt'] as Timestamp?)?.toDate()
              : null,
        ));
      }
    }

    return suspects;
  }

  /// 근접 기반 팀 배치 제안
  /// 체크인한 참가자들의 위치를 기반으로 균형 잡힌 팀 구성
  Future<TeamAssignment> suggestTeamAssignment({
    required String meetingId,
    required int teamCount,
  }) async {
    final checkIns = await getCheckedInParticipants(meetingId);

    if (checkIns.isEmpty) {
      return TeamAssignment(teams: [], unassigned: []);
    }

    // 위치 기반 클러스터링으로 팀 배치
    final teams = List.generate(teamCount, (_) => <String>[]);
    final shuffled = List.from(checkIns)..shuffle();

    // 간단한 라운드 로빈 배치 (실제로는 더 정교한 알고리즘 사용 가능)
    for (var i = 0; i < shuffled.length; i++) {
      teams[i % teamCount].add(shuffled[i].odId);
    }

    return TeamAssignment(
      teams: teams,
      unassigned: [],
    );
  }
}

/// 체크인 결과
class CheckInResult {
  final CheckInStatus status;
  final String message;
  final int? distanceMeters;
  final Duration? remainingTime;

  CheckInResult._({
    required this.status,
    required this.message,
    this.distanceMeters,
    this.remainingTime,
  });

  factory CheckInResult.success(int distance) => CheckInResult._(
    status: CheckInStatus.success,
    message: '체크인 완료! ($distance m)',
    distanceMeters: distance,
  );

  factory CheckInResult.tooFar(int distance) => CheckInResult._(
    status: CheckInStatus.tooFar,
    message: '모임 장소에서 너무 멀어요 (${distance}m)\n${LocationVerificationService.checkInRadiusMeters.toInt()}m 이내로 이동해주세요',
    distanceMeters: distance,
  );

  factory CheckInResult.tooEarly(Duration remaining) => CheckInResult._(
    status: CheckInStatus.tooEarly,
    message: '아직 체크인 시간이 아니에요\n${_formatDuration(remaining)} 후에 다시 시도해주세요',
    remainingTime: remaining,
  );

  factory CheckInResult.tooLate() => CheckInResult._(
    status: CheckInStatus.tooLate,
    message: '체크인 시간이 지났습니다',
  );

  factory CheckInResult.locationDisabled() => CheckInResult._(
    status: CheckInStatus.locationDisabled,
    message: '위치 권한을 허용해주세요',
  );

  factory CheckInResult.error(String error) => CheckInResult._(
    status: CheckInStatus.error,
    message: '오류: $error',
  );

  bool get isSuccess => status == CheckInStatus.success;

  static String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}시간 ${d.inMinutes % 60}분';
    }
    return '${d.inMinutes}분';
  }
}

enum CheckInStatus {
  success,
  tooFar,
  tooEarly,
  tooLate,
  locationDisabled,
  error,
}

/// 체크인 정보
class CheckInInfo {
  final String odId;
  final double latitude;
  final double longitude;
  final DateTime checkedInAt;
  final bool isVerified;

  CheckInInfo({
    required this.odId,
    required this.latitude,
    required this.longitude,
    required this.checkedInAt,
    required this.isVerified,
  });

  factory CheckInInfo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CheckInInfo(
      odId: data['userId'] ?? doc.id,
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      checkedInAt: (data['checkedInAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isVerified: data['isVerified'] ?? false,
    );
  }
}

/// 참가자 위치
class ParticipantLocation {
  final String odId;
  final double latitude;
  final double longitude;
  final DateTime updatedAt;

  ParticipantLocation({
    required this.odId,
    required this.latitude,
    required this.longitude,
    required this.updatedAt,
  });

  factory ParticipantLocation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ParticipantLocation(
      odId: data['userId'] ?? doc.id,
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// 팀 배치 결과
class TeamAssignment {
  final List<List<String>> teams;
  final List<String> unassigned;

  TeamAssignment({
    required this.teams,
    required this.unassigned,
  });

  int get teamCount => teams.length;

  List<String> getTeam(int index) => teams[index];

  bool isInTeam(String odId, int teamIndex) {
    if (teamIndex < 0 || teamIndex >= teams.length) return false;
    return teams[teamIndex].contains(odId);
  }

  int? getTeamIndex(String odId) {
    for (var i = 0; i < teams.length; i++) {
      if (teams[i].contains(odId)) return i;
    }
    return null;
  }
}

/// 노쇼 확인 결과
class NoShowCheckResult {
  final NoShowStatus status;
  final int? distanceMeters;

  NoShowCheckResult._({
    required this.status,
    this.distanceMeters,
  });

  factory NoShowCheckResult.tooEarly() => NoShowCheckResult._(
    status: NoShowStatus.tooEarly,
  );

  factory NoShowCheckResult.checkedIn() => NoShowCheckResult._(
    status: NoShowStatus.checkedIn,
  );

  factory NoShowCheckResult.noLocation() => NoShowCheckResult._(
    status: NoShowStatus.noLocation,
  );

  factory NoShowCheckResult.suspected(int distance) => NoShowCheckResult._(
    status: NoShowStatus.suspected,
    distanceMeters: distance,
  );

  factory NoShowCheckResult.nearBy(int distance) => NoShowCheckResult._(
    status: NoShowStatus.nearBy,
    distanceMeters: distance,
  );

  bool get isSuspected => status == NoShowStatus.suspected;
}

enum NoShowStatus {
  tooEarly,    // 아직 확인 시간 안됨
  checkedIn,   // 체크인 완료
  noLocation,  // 위치 정보 없음 (패스)
  suspected,   // 노쇼 의심 (멀리 있음)
  nearBy,      // 근처에 있음
}

/// 노쇼 의심자
class NoShowSuspect {
  final String odId;
  final int? distanceMeters;
  final DateTime? lastLocationTime;

  NoShowSuspect({
    required this.odId,
    this.distanceMeters,
    this.lastLocationTime,
  });

  String get warningMessage {
    if (distanceMeters == null) return '위치 확인 불가';
    final km = (distanceMeters! / 1000).toStringAsFixed(1);
    return '모임 장소에서 ${km}km 떨어져 있습니다';
  }
}
