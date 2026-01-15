import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/quick_message_model.dart';

/// 퀵 메시지 서비스
///
/// 자유 채팅 대신 정해진 메시지만 주고받는 통제된 소통 시스템
class QuickMessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _messagesRef(String meetingId) =>
      _firestore.collection('meetings').doc(meetingId).collection('quickMessages');

  /// 퀵 메시지 전송
  Future<void> sendMessage({
    required String meetingId,
    required String senderId,
    required String senderNickname,
    required QuickMessageType type,
    String? customText,
  }) async {
    debugPrint('[QuickMessage] 전송 시작: meetingId=$meetingId, senderId=$senderId, type=${type.name}');

    // 먼저 모임이 존재하고 사용자가 참가자인지 확인
    try {
      final meetingDoc = await _firestore.collection('meetings').doc(meetingId).get();
      if (!meetingDoc.exists) {
        debugPrint('[QuickMessage] 오류: 모임이 존재하지 않음');
        throw Exception('모임을 찾을 수 없습니다');
      }

      final meetingData = meetingDoc.data();
      final participantIds = List<String>.from(meetingData?['participantIds'] ?? []);
      if (!participantIds.contains(senderId)) {
        debugPrint('[QuickMessage] 오류: 사용자가 참가자 목록에 없음');
        debugPrint('[QuickMessage] participantIds: $participantIds');
        debugPrint('[QuickMessage] senderId: $senderId');
        throw Exception('모임 참가자만 메시지를 보낼 수 있습니다');
      }
    } catch (e) {
      debugPrint('[QuickMessage] 참가자 확인 실패: $e');
      rethrow;
    }

    final message = QuickMessage(
      id: '',
      meetingId: meetingId,
      senderId: senderId,
      senderNickname: senderNickname,
      type: type,
      sentAt: DateTime.now(),
      customText: customText,
    );

    final data = message.toFirestore();
    debugPrint('[QuickMessage] Firestore 데이터: $data');

    try {
      // 10초 타임아웃 추가
      final docRef = await _messagesRef(meetingId)
          .add(data)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('[QuickMessage] 타임아웃: 10초 초과');
              throw Exception('전송 시간이 초과되었습니다. 네트워크를 확인해주세요.');
            },
          );
      debugPrint('[QuickMessage] 전송 성공: docId=${docRef.id}');
    } catch (e, stack) {
      debugPrint('[QuickMessage] 전송 실패: $e');
      debugPrint('[QuickMessage] 스택: $stack');
      rethrow;
    }
  }

  /// 커스텀 공지 전송 (방장 전용, 쿨타임 적용)
  /// 반환값: 성공 시 null, 실패 시 에러 메시지
  Future<String?> sendCustomAnnouncement({
    required String meetingId,
    required String hostId,
    required String hostNickname,
    required String text,
  }) async {
    // 길이 검증
    final trimmed = text.trim();
    if (trimmed.length < QuickMessage.customMinLength) {
      return '공지는 ${QuickMessage.customMinLength}자 이상이어야 해요';
    }
    if (trimmed.length > QuickMessage.customMaxLength) {
      return '공지는 ${QuickMessage.customMaxLength}자 이하여야 해요';
    }

    // 쿨타임 체크
    final lastAnnounce = await _getLastCustomAnnouncement(meetingId, hostId);
    if (lastAnnounce != null) {
      final elapsed = DateTime.now().difference(lastAnnounce.sentAt);
      if (elapsed < QuickMessage.cooldownDuration) {
        final remaining = QuickMessage.cooldownDuration - elapsed;
        return '${remaining.inSeconds}초 후에 다시 공지할 수 있어요';
      }
    }

    // 전송
    await sendMessage(
      meetingId: meetingId,
      senderId: hostId,
      senderNickname: hostNickname,
      type: QuickMessageType.customAnnounce,
      customText: trimmed,
    );

    return null; // 성공
  }

  /// 마지막 커스텀 공지 조회
  Future<QuickMessage?> _getLastCustomAnnouncement(String meetingId, String hostId) async {
    try {
      final snapshot = await _messagesRef(meetingId)
          .where('senderId', isEqualTo: hostId)
          .where('type', isEqualTo: QuickMessageType.customAnnounce.index)
          .orderBy('sentAt', descending: true)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 5));

      if (snapshot.docs.isEmpty) return null;
      return QuickMessage.fromFirestore(snapshot.docs.first);
    } catch (e) {
      // 인덱스 미생성 등의 오류 시 쿨타임 체크 생략
      debugPrint('[QuickMessage] 마지막 공지 조회 실패 (쿨타임 체크 생략): $e');
      return null;
    }
  }

  /// 최근 메시지 스트림 (실시간)
  Stream<List<QuickMessage>> getRecentMessages(String meetingId, {int limit = 20}) {
    return _messagesRef(meetingId)
        .orderBy('sentAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => QuickMessage.fromFirestore(doc))
            .toList()
            .reversed  // 최신순 → 시간순
            .toList());
  }

  /// 마지막 메시지 가져오기
  Stream<QuickMessage?> getLastMessage(String meetingId) {
    return _messagesRef(meetingId)
        .orderBy('sentAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return QuickMessage.fromFirestore(snapshot.docs.first);
    });
  }

  /// 특정 유저의 마지막 상태 메시지
  Future<QuickMessage?> getUserLastStatus(String meetingId, String userId) async {
    final snapshot = await _messagesRef(meetingId)
        .where('senderId', isEqualTo: userId)
        .orderBy('sentAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return QuickMessage.fromFirestore(snapshot.docs.first);
  }

  /// 참가자별 마지막 상태 요약
  Future<Map<String, QuickMessage>> getParticipantsLastStatus(
    String meetingId,
    List<String> participantIds,
  ) async {
    final result = <String, QuickMessage>{};

    for (final id in participantIds) {
      final message = await getUserLastStatus(meetingId, id);
      if (message != null) {
        result[id] = message;
      }
    }

    return result;
  }

  /// 도착한 참가자 수
  Stream<int> getArrivedCount(String meetingId) {
    return _messagesRef(meetingId)
        .where('type', isEqualTo: QuickMessageType.arrived.index)
        .snapshots()
        .map((snapshot) {
      // 유니크한 senderId 수
      final senders = snapshot.docs.map((d) => d['senderId']).toSet();
      return senders.length;
    });
  }

  /// 오래된 메시지 정리 (모임 종료 후)
  Future<void> cleanupOldMessages(String meetingId) async {
    final messages = await _messagesRef(meetingId).get();
    final batch = _firestore.batch();
    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
