import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quick_message_model.dart';

/// 퀵 메시지 서비스
///
/// 자유 채팅 대신 정해진 메시지만 주고받는 통제된 소통 시스템
class QuickMessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _messagesRef(String meetingId) =>
      _firestore.collection('meetings').doc(meetingId).collection('quick_messages');

  /// 퀵 메시지 전송
  Future<void> sendMessage({
    required String meetingId,
    required String senderId,
    required String senderNickname,
    required QuickMessageType type,
    String? customText,
  }) async {
    final message = QuickMessage(
      id: '',
      meetingId: meetingId,
      senderId: senderId,
      senderNickname: senderNickname,
      type: type,
      sentAt: DateTime.now(),
      customText: customText,
    );

    await _messagesRef(meetingId).add(message.toFirestore());
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
    final snapshot = await _messagesRef(meetingId)
        .where('senderId', isEqualTo: hostId)
        .where('type', isEqualTo: QuickMessageType.customAnnounce.index)
        .orderBy('sentAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return QuickMessage.fromFirestore(snapshot.docs.first);
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
