import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/meeting_model.dart';
import 'error_handler_service.dart';

class MeetingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 사용자당 최대 활성 모임 생성 개수
  static const int maxActiveMeetingsPerUser = 3;

  CollectionReference get _meetingsRef => _firestore.collection('meetings');

  // 사용자의 활성 모임 개수 조회
  Future<int> getActiveHostedMeetingsCount(String userId) async {
    final snapshot = await _meetingsRef
        .where('hostId', isEqualTo: userId)
        .where('status', whereIn: [
          MeetingStatus.recruiting.index,
          MeetingStatus.full.index,
          MeetingStatus.inProgress.index,
        ])
        .get();
    return snapshot.docs.length;
  }

  // 모임 생성 가능 여부 확인
  Future<bool> canCreateMeeting(String userId) async {
    final count = await getActiveHostedMeetingsCount(userId);
    return count < maxActiveMeetingsPerUser;
  }

  // 모임 생성
  Future<String> createMeeting(MeetingModel meeting) async {
    // 생성 제한 확인
    final canCreate = await canCreateMeeting(meeting.hostId);
    if (!canCreate) {
      throw MeetingLimitException(
        '모임은 최대 $maxActiveMeetingsPerUser개까지만 생성할 수 있습니다.',
      );
    }

    final docRef = await _meetingsRef.add(meeting.toFirestore());
    return docRef.id;
  }

  // 모임 조회 (단건)
  Future<MeetingModel?> getMeeting(String meetingId) async {
    final doc = await _meetingsRef.doc(meetingId).get();
    if (doc.exists) {
      return MeetingModel.fromFirestore(doc);
    }
    return null;
  }

  /// 페이지 크기 (한 번에 로드할 모임 수)
  static const int pageSize = 20;

  // 모든 모임 목록 (실시간) - 클라이언트에서 필터링
  // 기존 방식 유지 (호환성)
  Stream<List<MeetingModel>> getRecruitingMeetings() {
    // 복합 인덱스 없이 모든 모임을 가져와서 클라이언트에서 필터링
    return _meetingsRef
        .limit(200) // 최근 200개까지
        .snapshots()
        .map((snapshot) {
          final meetings = snapshot.docs
              .map((doc) => MeetingModel.fromFirestore(doc))
              .toList();
          // 클라이언트에서 시간순 정렬
          meetings.sort((a, b) => a.meetingTime.compareTo(b.meetingTime));
          return meetings;
        });
  }

  // ============== 페이지네이션 API ==============

  /// 첫 페이지 로드 (모집중인 모임, 시간순)
  Future<PaginatedResult<MeetingModel>> getFirstPage({
    int limit = pageSize,
  }) async {
    final now = DateTime.now();

    final query = _meetingsRef
        .where('status', isEqualTo: MeetingStatus.recruiting.index)
        .where('meetingTime', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('meetingTime')
        .limit(limit);

    final snapshot = await query.get();
    final meetings = snapshot.docs
        .map((doc) => MeetingModel.fromFirestore(doc))
        .toList();

    final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
    final hasMore = snapshot.docs.length >= limit;

    return PaginatedResult(
      items: meetings,
      lastDocument: lastDoc,
      hasMore: hasMore,
    );
  }

  /// 다음 페이지 로드
  Future<PaginatedResult<MeetingModel>> getNextPage({
    required DocumentSnapshot lastDocument,
    int limit = pageSize,
  }) async {
    final now = DateTime.now();

    final query = _meetingsRef
        .where('status', isEqualTo: MeetingStatus.recruiting.index)
        .where('meetingTime', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('meetingTime')
        .startAfterDocument(lastDocument)
        .limit(limit);

    final snapshot = await query.get();
    final meetings = snapshot.docs
        .map((doc) => MeetingModel.fromFirestore(doc))
        .toList();

    final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
    final hasMore = snapshot.docs.length >= limit;

    return PaginatedResult(
      items: meetings,
      lastDocument: lastDoc,
      hasMore: hasMore,
    );
  }

  /// 첫 페이지 실시간 스트림 (초기 로딩용)
  Stream<PaginatedResult<MeetingModel>> getFirstPageStream({
    int limit = pageSize,
  }) {
    final now = DateTime.now();

    return _meetingsRef
        .where('status', isEqualTo: MeetingStatus.recruiting.index)
        .where('meetingTime', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('meetingTime')
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final meetings = snapshot.docs
              .map((doc) => MeetingModel.fromFirestore(doc))
              .toList();

          final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
          final hasMore = snapshot.docs.length >= limit;

          return PaginatedResult(
            items: meetings,
            lastDocument: lastDoc,
            hasMore: hasMore,
          );
        });
  }

  // 게임 타입별 모임 목록
  Stream<List<MeetingModel>> getMeetingsByGameType(GameType gameType) {
    return _meetingsRef
        .where('gameType', isEqualTo: gameType.index)
        .where('status', isEqualTo: MeetingStatus.recruiting.index)
        .orderBy('meetingTime', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MeetingModel.fromFirestore(doc))
            .toList());
  }

  // 내가 참여한 모임 목록
  Stream<List<MeetingModel>> getMyMeetings(String userId) {
    return _meetingsRef
        .where('participantIds', arrayContains: userId)
        .orderBy('meetingTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MeetingModel.fromFirestore(doc))
            .toList());
  }

  // ============== 위치 기반 검색 ==============

  /// 내 위치에서 가까운 모임 목록 (거리순 정렬)
  /// [userLat], [userLon]: 사용자 현재 위치
  /// [maxDistanceKm]: 최대 검색 거리 (km)
  Future<List<MeetingWithDistance>> getNearbyMeetings({
    required double userLat,
    required double userLon,
    double maxDistanceKm = 10.0,
    int limit = 50,
  }) async {
    final now = DateTime.now();

    // 모집중인 모임만 가져옴
    final snapshot = await _meetingsRef
        .where('status', isEqualTo: MeetingStatus.recruiting.index)
        .where('meetingTime', isGreaterThan: Timestamp.fromDate(now))
        .limit(limit)
        .get();

    final meetingsWithDistance = <MeetingWithDistance>[];

    for (final doc in snapshot.docs) {
      final meeting = MeetingModel.fromFirestore(doc);

      // 위치 정보가 없는 모임은 제외
      if (meeting.latitude == null || meeting.longitude == null) continue;

      // 거리 계산 (미터 단위)
      final distanceMeters = Geolocator.distanceBetween(
        userLat,
        userLon,
        meeting.latitude!,
        meeting.longitude!,
      );

      final distanceKm = distanceMeters / 1000;

      // 최대 거리 내의 모임만 추가
      if (distanceKm <= maxDistanceKm) {
        meetingsWithDistance.add(MeetingWithDistance(
          meeting: meeting,
          distanceKm: distanceKm,
        ));
      }
    }

    // 거리순 정렬
    meetingsWithDistance.sort((a, b) => a.distanceKm!.compareTo(b.distanceKm!));

    return meetingsWithDistance;
  }

  /// 모임 목록에 거리 정보 추가 (클라이언트 측 필터링용)
  List<MeetingWithDistance> addDistanceToMeetings({
    required List<MeetingModel> meetings,
    required double userLat,
    required double userLon,
  }) {
    final result = <MeetingWithDistance>[];

    for (final meeting in meetings) {
      double? distanceKm;

      if (meeting.latitude != null && meeting.longitude != null) {
        final distanceMeters = Geolocator.distanceBetween(
          userLat,
          userLon,
          meeting.latitude!,
          meeting.longitude!,
        );
        distanceKm = distanceMeters / 1000;
      }

      result.add(MeetingWithDistance(
        meeting: meeting,
        distanceKm: distanceKm,
      ));
    }

    return result;
  }

  /// 거리 범위로 필터링
  List<MeetingWithDistance> filterByDistance({
    required List<MeetingWithDistance> meetings,
    required double maxDistanceKm,
  }) {
    return meetings
        .where((m) => m.distanceKm != null && m.distanceKm! <= maxDistanceKm)
        .toList();
  }

  // 모임 참여
  Future<bool> joinMeeting(String meetingId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final meetingDoc = await transaction.get(_meetingsRef.doc(meetingId));

        if (!meetingDoc.exists) {
          throw Exception('모임을 찾을 수 없습니다.');
        }

        final meeting = MeetingModel.fromFirestore(meetingDoc);

        if (meeting.participantIds.contains(userId)) {
          throw Exception('이미 참여한 모임입니다.');
        }

        if (meeting.currentParticipants >= meeting.maxParticipants) {
          throw Exception('모임 인원이 꽉 찼습니다.');
        }

        final newParticipants = [...meeting.participantIds, userId];
        final newCount = meeting.currentParticipants + 1;
        final newStatus = newCount >= meeting.maxParticipants
            ? MeetingStatus.full.index
            : MeetingStatus.recruiting.index;

        transaction.update(_meetingsRef.doc(meetingId), {
          'participantIds': newParticipants,
          'currentParticipants': newCount,
          'status': newStatus,
        });
      });
      return true;
    } catch (e) {
      final message = ErrorHandlerService().handleError(e, context: 'joinMeeting');
      if (kDebugMode) print('Join meeting error: $message');
      return false;
    }
  }

  // 모임 나가기
  Future<bool> leaveMeeting(String meetingId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final meetingDoc = await transaction.get(_meetingsRef.doc(meetingId));

        if (!meetingDoc.exists) {
          throw Exception('모임을 찾을 수 없습니다.');
        }

        final meeting = MeetingModel.fromFirestore(meetingDoc);

        if (!meeting.participantIds.contains(userId)) {
          throw Exception('참여하지 않은 모임입니다.');
        }

        if (meeting.hostId == userId) {
          throw Exception('방장은 나갈 수 없습니다. 모임을 취소하세요.');
        }

        final newParticipants = meeting.participantIds.where((id) => id != userId).toList();
        final newCount = meeting.currentParticipants - 1;

        transaction.update(_meetingsRef.doc(meetingId), {
          'participantIds': newParticipants,
          'currentParticipants': newCount,
          'status': MeetingStatus.recruiting.index,
        });
      });
      return true;
    } catch (e) {
      final message = ErrorHandlerService().handleError(e, context: 'leaveMeeting');
      if (kDebugMode) print('Leave meeting error: $message');
      return false;
    }
  }

  // 모임 상태 업데이트
  Future<void> updateMeetingStatus(String meetingId, MeetingStatus status) async {
    await _meetingsRef.doc(meetingId).update({
      'status': status.index,
    });
  }

  /// 모임 정보 수정 (방장만 가능)
  Future<bool> updateMeetingDetails({
    required String meetingId,
    required String hostId,
    String? title,
    String? description,
    String? location,
    String? locationDetail,
    DateTime? meetingTime,
    int? maxParticipants,
  }) async {
    try {
      final meeting = await getMeeting(meetingId);
      if (meeting == null || meeting.hostId != hostId) {
        return false;
      }

      // 모집중 상태에서만 수정 가능
      if (meeting.status != MeetingStatus.recruiting) {
        return false;
      }

      final updates = <String, dynamic>{};
      if (title != null && title.trim().isNotEmpty) {
        updates['title'] = title.trim();
      }
      if (description != null) {
        updates['description'] = description.trim();
      }
      if (location != null && location.trim().isNotEmpty) {
        updates['location'] = location.trim();
      }
      if (locationDetail != null) {
        updates['locationDetail'] = locationDetail.trim().isEmpty ? null : locationDetail.trim();
      }
      if (meetingTime != null) {
        updates['meetingTime'] = Timestamp.fromDate(meetingTime);
      }
      if (maxParticipants != null && maxParticipants >= meeting.currentParticipants) {
        updates['maxParticipants'] = maxParticipants;
      }

      if (updates.isEmpty) return false;

      await _meetingsRef.doc(meetingId).update(updates);
      return true;
    } catch (e) {
      if (kDebugMode) print('Update meeting error: $e');
      return false;
    }
  }

  // 모임 취소
  Future<void> cancelMeeting(String meetingId, String hostId) async {
    final meeting = await getMeeting(meetingId);
    if (meeting != null && meeting.hostId == hostId) {
      await updateMeetingStatus(meetingId, MeetingStatus.cancelled);
    }
  }

  // 모임 삭제 (방장만 가능)
  Future<bool> deleteMeeting(String meetingId, String hostId) async {
    final meeting = await getMeeting(meetingId);
    if (meeting == null || meeting.hostId != hostId) {
      return false;
    }

    // 모집중이거나 취소된 모임만 삭제 가능
    if (meeting.status != MeetingStatus.recruiting &&
        meeting.status != MeetingStatus.cancelled &&
        meeting.status != MeetingStatus.finished) {
      return false;
    }

    await _meetingsRef.doc(meetingId).delete();
    return true;
  }

  // 방장 위임
  Future<bool> transferHost(String meetingId, String currentHostId, String newHostId) async {
    try {
      final meeting = await getMeeting(meetingId);
      if (meeting == null || meeting.hostId != currentHostId) {
        return false;
      }

      // 새 방장이 참가자인지 확인
      if (!meeting.participantIds.contains(newHostId)) {
        return false;
      }

      await _meetingsRef.doc(meetingId).update({
        'hostId': newHostId,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ============== 방장 자동 위임 시스템 ==============

  /// 방장 미응답 시 자동 위임 (3분 기준)
  /// 게임 중 방장이 앱을 닫거나 이탈한 경우 호출
  ///
  /// 위임 우선순위:
  /// 1. 가장 먼저 참가한 사용자
  /// 2. 참가자가 없으면 모임 취소
  Future<AutoTransferResult> autoTransferHostIfNeeded(
    String meetingId,
    String currentHostId,
    DateTime lastHostActivity,
  ) async {
    final now = DateTime.now();
    final inactiveThreshold = const Duration(minutes: 3);

    // 3분 이내면 아직 유효
    if (now.difference(lastHostActivity) < inactiveThreshold) {
      return AutoTransferResult.notNeeded();
    }

    try {
      final meeting = await getMeeting(meetingId);
      if (meeting == null) {
        return AutoTransferResult.meetingNotFound();
      }

      // 방장이 변경됐으면 (이미 다른 곳에서 위임됨) 무시
      if (meeting.hostId != currentHostId) {
        return AutoTransferResult.alreadyTransferred();
      }

      // 다른 참가자 찾기 (방장 제외)
      final otherParticipants = meeting.participantIds
          .where((id) => id != currentHostId)
          .toList();

      if (otherParticipants.isEmpty) {
        // 참가자 없으면 모임 취소
        await cancelMeeting(meetingId, currentHostId);
        return AutoTransferResult.meetingCancelled();
      }

      // 첫 번째 참가자에게 위임 (가장 먼저 참가한 사용자)
      final newHostId = otherParticipants.first;
      final success = await transferHost(meetingId, currentHostId, newHostId);

      if (success) {
        return AutoTransferResult.transferred(newHostId);
      } else {
        return AutoTransferResult.failed();
      }
    } catch (e) {
      return AutoTransferResult.failed();
    }
  }

  /// 방장 활동 시간 업데이트 (heartbeat)
  Future<void> updateHostActivity(String meetingId) async {
    await _meetingsRef.doc(meetingId).update({
      'hostLastActiveAt': FieldValue.serverTimestamp(),
    });
  }

  // 단일 모임 실시간 스트림
  Stream<MeetingModel?> getMeetingStream(String meetingId) {
    return _meetingsRef.doc(meetingId).snapshots().map((doc) {
      if (doc.exists) {
        return MeetingModel.fromFirestore(doc);
      }
      return null;
    });
  }

  // ============== 빠른 참가 시스템 ==============

  /// 참가 코드로 모임 찾기
  Future<MeetingModel?> getMeetingByJoinCode(String joinCode) async {
    final normalizedCode = joinCode.toUpperCase().trim();
    final snapshot = await _meetingsRef
        .where('joinCode', isEqualTo: normalizedCode)
        .where('status', whereIn: [
          MeetingStatus.recruiting.index,
          MeetingStatus.full.index,
        ])
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return MeetingModel.fromFirestore(snapshot.docs.first);
  }

  /// 참가 코드로 바로 참가
  Future<JoinResult> joinByCode(String joinCode, String userId, String nickname) async {
    try {
      final meeting = await getMeetingByJoinCode(joinCode);

      if (meeting == null) {
        return JoinResult.notFound();
      }

      if (meeting.participantIds.contains(userId)) {
        return JoinResult.alreadyJoined(meeting);
      }

      if (meeting.currentParticipants >= meeting.maxParticipants) {
        return JoinResult.full(meeting);
      }

      final success = await joinMeeting(meeting.id, userId);
      if (success) {
        final updated = await getMeeting(meeting.id);
        return JoinResult.success(updated!);
      }

      return JoinResult.error('참가에 실패했습니다.');
    } catch (e) {
      return JoinResult.error(e.toString());
    }
  }

  /// 참가 코드 중복 확인
  Future<bool> isJoinCodeAvailable(String joinCode) async {
    final meeting = await getMeetingByJoinCode(joinCode);
    return meeting == null;
  }

  /// 유니크한 참가 코드 생성
  Future<String> generateUniqueJoinCode() async {
    String code;
    bool isAvailable;
    int attempts = 0;

    do {
      code = MeetingModel.generateJoinCode();
      isAvailable = await isJoinCodeAvailable(code);
      attempts++;
    } while (!isAvailable && attempts < 10);

    return code;
  }

  // ============== 공지 기능 ==============

  /// 공지사항 업데이트
  Future<void> updateAnnouncement(String meetingId, String hostId, String announcement) async {
    final meeting = await getMeeting(meetingId);
    if (meeting != null && meeting.hostId == hostId) {
      await _meetingsRef.doc(meetingId).update({
        'announcement': announcement,
        'announcementAt': Timestamp.now(),
      });
    }
  }

  /// 공지사항 삭제
  Future<void> clearAnnouncement(String meetingId, String hostId) async {
    final meeting = await getMeeting(meetingId);
    if (meeting != null && meeting.hostId == hostId) {
      await _meetingsRef.doc(meetingId).update({
        'announcement': null,
        'announcementAt': null,
      });
    }
  }

  // ============== 게임 시작/종료 ==============

  /// 게임 시작 (호스트만)
  Future<bool> startGame(String meetingId, String hostId) async {
    final meeting = await getMeeting(meetingId);
    if (meeting == null || meeting.hostId != hostId) return false;

    await updateMeetingStatus(meetingId, MeetingStatus.inProgress);
    return true;
  }

  /// 게임 종료
  Future<void> endGame(String meetingId, String hostId) async {
    final meeting = await getMeeting(meetingId);
    if (meeting != null && meeting.hostId == hostId) {
      await updateMeetingStatus(meetingId, MeetingStatus.finished);
    }
  }
}

/// 참가 결과
class JoinResult {
  final bool success;
  final MeetingModel? meeting;
  final String? errorMessage;
  final JoinResultType type;

  JoinResult._({
    required this.success,
    this.meeting,
    this.errorMessage,
    required this.type,
  });

  factory JoinResult.success(MeetingModel meeting) => JoinResult._(
    success: true,
    meeting: meeting,
    type: JoinResultType.success,
  );

  factory JoinResult.notFound() => JoinResult._(
    success: false,
    errorMessage: '참가 코드를 찾을 수 없습니다.',
    type: JoinResultType.notFound,
  );

  factory JoinResult.alreadyJoined(MeetingModel meeting) => JoinResult._(
    success: true,
    meeting: meeting,
    type: JoinResultType.alreadyJoined,
  );

  factory JoinResult.full(MeetingModel meeting) => JoinResult._(
    success: false,
    meeting: meeting,
    errorMessage: '모임 인원이 가득 찼습니다.',
    type: JoinResultType.full,
  );

  factory JoinResult.error(String message) => JoinResult._(
    success: false,
    errorMessage: message,
    type: JoinResultType.error,
  );
}

enum JoinResultType {
  success,
  notFound,
  alreadyJoined,
  full,
  error,
}

/// 모임 생성 제한 예외
class MeetingLimitException implements Exception {
  final String message;
  MeetingLimitException(this.message);

  @override
  String toString() => message;
}

/// 방장 자동 위임 결과
class AutoTransferResult {
  final AutoTransferStatus status;
  final String? newHostId;

  AutoTransferResult._(this.status, [this.newHostId]);

  factory AutoTransferResult.notNeeded() =>
      AutoTransferResult._(AutoTransferStatus.notNeeded);

  factory AutoTransferResult.meetingNotFound() =>
      AutoTransferResult._(AutoTransferStatus.meetingNotFound);

  factory AutoTransferResult.alreadyTransferred() =>
      AutoTransferResult._(AutoTransferStatus.alreadyTransferred);

  factory AutoTransferResult.meetingCancelled() =>
      AutoTransferResult._(AutoTransferStatus.meetingCancelled);

  factory AutoTransferResult.transferred(String newHostId) =>
      AutoTransferResult._(AutoTransferStatus.transferred, newHostId);

  factory AutoTransferResult.failed() =>
      AutoTransferResult._(AutoTransferStatus.failed);

  bool get isTransferred => status == AutoTransferStatus.transferred;
}

enum AutoTransferStatus {
  notNeeded,        // 아직 3분 안 됨
  meetingNotFound,  // 모임 없음
  alreadyTransferred, // 이미 다른 곳에서 위임됨
  meetingCancelled, // 참가자 없어서 취소
  transferred,      // 성공적으로 위임
  failed,           // 위임 실패
}

/// 페이지네이션 결과
class PaginatedResult<T> {
  final List<T> items;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  const PaginatedResult({
    required this.items,
    this.lastDocument,
    required this.hasMore,
  });

  /// 빈 결과
  factory PaginatedResult.empty() => PaginatedResult(
    items: [],
    lastDocument: null,
    hasMore: false,
  );

  /// 결과가 비어있는지
  bool get isEmpty => items.isEmpty;

  /// 결과 개수
  int get length => items.length;
}

/// 거리 정보가 포함된 모임
class MeetingWithDistance {
  final MeetingModel meeting;
  final double? distanceKm;

  const MeetingWithDistance({
    required this.meeting,
    this.distanceKm,
  });

  /// 거리 표시 문자열 (예: "1.2km", "500m")
  String get distanceText {
    if (distanceKm == null) return '';
    if (distanceKm! < 1) {
      return '${(distanceKm! * 1000).round()}m';
    }
    return '${distanceKm!.toStringAsFixed(1)}km';
  }

  /// 거리 범위 (필터용)
  DistanceRange get distanceRange {
    if (distanceKm == null) return DistanceRange.unknown;
    if (distanceKm! <= 1) return DistanceRange.within1km;
    if (distanceKm! <= 3) return DistanceRange.within3km;
    if (distanceKm! <= 5) return DistanceRange.within5km;
    if (distanceKm! <= 10) return DistanceRange.within10km;
    return DistanceRange.over10km;
  }
}

/// 거리 범위 필터
enum DistanceRange {
  within1km,   // 1km 이내
  within3km,   // 3km 이내
  within5km,   // 5km 이내
  within10km,  // 10km 이내
  over10km,    // 10km 초과
  unknown,     // 위치 정보 없음
}

extension DistanceRangeExtension on DistanceRange {
  String get label {
    switch (this) {
      case DistanceRange.within1km:
        return '1km 이내';
      case DistanceRange.within3km:
        return '3km 이내';
      case DistanceRange.within5km:
        return '5km 이내';
      case DistanceRange.within10km:
        return '10km 이내';
      case DistanceRange.over10km:
        return '10km 초과';
      case DistanceRange.unknown:
        return '거리 미상';
    }
  }

  double? get maxKm {
    switch (this) {
      case DistanceRange.within1km:
        return 1.0;
      case DistanceRange.within3km:
        return 3.0;
      case DistanceRange.within5km:
        return 5.0;
      case DistanceRange.within10km:
        return 10.0;
      case DistanceRange.over10km:
      case DistanceRange.unknown:
        return null;
    }
  }
}
