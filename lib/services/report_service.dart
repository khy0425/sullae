import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// 신고/차단 서비스
/// - 불량 사용자 신고
/// - 사용자 차단
/// - 신고 누적 시 자동 제재
class ReportService {
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 자동 제재 기준 (신고 횟수)
  static const int autoSuspendThreshold = 5;

  /// 신고 접수
  Future<bool> reportUser({
    required String reporterId,
    required String reportedUserId,
    required String meetingId,
    required ReportReason reason,
    String? description,
  }) async {
    try {
      // 이미 같은 모임에서 신고했는지 확인
      final existing = await _firestore
          .collection('reports')
          .where('reporterId', isEqualTo: reporterId)
          .where('reportedUserId', isEqualTo: reportedUserId)
          .where('meetingId', isEqualTo: meetingId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        if (kDebugMode) print('Already reported this user in this meeting');
        return false;
      }

      // 신고 저장
      await _firestore.collection('reports').add({
        'reporterId': reporterId,
        'reportedUserId': reportedUserId,
        'meetingId': meetingId,
        'reason': reason.name,
        'description': description,
        'status': ReportStatus.pending.name,
        'createdAt': Timestamp.now(),
      });

      // 신고 횟수 확인 및 자동 제재
      await _checkAutoSuspend(reportedUserId);

      if (kDebugMode) print('Report submitted: $reportedUserId');
      return true;
    } catch (e) {
      if (kDebugMode) print('Error reporting user: $e');
      return false;
    }
  }

  /// 신고 횟수 확인 및 자동 제재
  Future<void> _checkAutoSuspend(String odId) async {
    final reports = await _firestore
        .collection('reports')
        .where('reportedUserId', isEqualTo: odId)
        .where('status', isEqualTo: ReportStatus.pending.name)
        .get();

    if (reports.docs.length >= autoSuspendThreshold) {
      // 자동 제재 적용
      await _firestore.collection('users').doc(odId).update({
        'isSuspended': true,
        'suspendedAt': Timestamp.now(),
        'suspendReason': '다수의 신고 접수',
      });

      if (kDebugMode) print('User auto-suspended: $odId');
    }
  }

  /// 사용자 차단
  Future<bool> blockUser(String odId, String blockedUserId) async {
    try {
      await _firestore
          .collection('users')
          .doc(odId)
          .collection('blocked_users')
          .doc(blockedUserId)
          .set({
        'blockedAt': Timestamp.now(),
      });

      if (kDebugMode) print('User blocked: $blockedUserId');
      return true;
    } catch (e) {
      if (kDebugMode) print('Error blocking user: $e');
      return false;
    }
  }

  /// 차단 해제
  Future<bool> unblockUser(String odId, String blockedUserId) async {
    try {
      await _firestore
          .collection('users')
          .doc(odId)
          .collection('blocked_users')
          .doc(blockedUserId)
          .delete();

      return true;
    } catch (e) {
      if (kDebugMode) print('Error unblocking user: $e');
      return false;
    }
  }

  /// 차단 여부 확인
  Future<bool> isBlocked(String odId, String targetUserId) async {
    final doc = await _firestore
        .collection('users')
        .doc(odId)
        .collection('blocked_users')
        .doc(targetUserId)
        .get();

    return doc.exists;
  }

  /// 차단 목록 조회
  Future<List<String>> getBlockedUsers(String odId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(odId)
        .collection('blocked_users')
        .get();

    return snapshot.docs.map((doc) => doc.id).toList();
  }

  /// 사용자 제재 여부 확인
  Future<bool> isSuspended(String odId) async {
    final doc = await _firestore.collection('users').doc(odId).get();
    return doc.data()?['isSuspended'] ?? false;
  }

  /// 내 신고 내역 조회
  Future<List<ReportRecord>> getMyReports(String odId) async {
    final snapshot = await _firestore
        .collection('reports')
        .where('reporterId', isEqualTo: odId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();

    return snapshot.docs.map((doc) => ReportRecord.fromFirestore(doc)).toList();
  }
}

/// 신고 사유
enum ReportReason {
  noShow,           // 노쇼 (나타나지 않음)
  harassment,       // 괴롭힘/불쾌한 행동
  inappropriateChat,// 부적절한 채팅
  spam,             // 스팸/도배
  fakeProfile,      // 허위 프로필
  violence,         // 폭력적 행동
  other,            // 기타
}

extension ReportReasonExtension on ReportReason {
  String get label {
    switch (this) {
      case ReportReason.noShow:
        return '노쇼 (나타나지 않음)';
      case ReportReason.harassment:
        return '괴롭힘/불쾌한 행동';
      case ReportReason.inappropriateChat:
        return '부적절한 채팅';
      case ReportReason.spam:
        return '스팸/도배';
      case ReportReason.fakeProfile:
        return '허위 프로필';
      case ReportReason.violence:
        return '폭력적 행동';
      case ReportReason.other:
        return '기타';
    }
  }
}

/// 신고 상태
enum ReportStatus {
  pending,    // 검토 대기
  reviewed,   // 검토 완료
  dismissed,  // 기각
  actioned,   // 조치 완료
}

/// 신고 기록
class ReportRecord {
  final String id;
  final String reporterId;
  final String reportedUserId;
  final String meetingId;
  final ReportReason reason;
  final String? description;
  final ReportStatus status;
  final DateTime createdAt;

  ReportRecord({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    required this.meetingId,
    required this.reason,
    this.description,
    required this.status,
    required this.createdAt,
  });

  factory ReportRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReportRecord(
      id: doc.id,
      reporterId: data['reporterId'] ?? '',
      reportedUserId: data['reportedUserId'] ?? '',
      meetingId: data['meetingId'] ?? '',
      reason: ReportReason.values.firstWhere(
        (r) => r.name == data['reason'],
        orElse: () => ReportReason.other,
      ),
      description: data['description'],
      status: ReportStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => ReportStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
