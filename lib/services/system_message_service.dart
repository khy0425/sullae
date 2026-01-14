import 'package:firebase_database/firebase_database.dart';
import '../models/system_message_model.dart';

/// 시스템 메시지 서비스
///
/// 역할: 시스템 알림만 담당 (입장/퇴장/게임 시작 등)
///
/// 의도적으로 하지 않는 것:
/// - 자유 텍스트 입력
/// - 메시지 히스토리 스크롤
/// - 답장/멘션/이모지 리액션
///
/// 사용자 간 소통은 QuickMessageService로만 처리
/// @see QuickMessageService
class SystemMessageService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  DatabaseReference _messagesRef(String meetingId) =>
      _database.ref('meetings/$meetingId/system_messages');

  // 시스템 메시지 전송 (내부용)
  Future<void> _sendMessage(SystemMessage message) async {
    final newRef = _messagesRef(message.meetingId).push();
    await newRef.set(message.toRealtimeDB());
  }

  // 시스템 메시지 전송
  Future<void> sendSystemMessage(String meetingId, String message) async {
    final systemMessage = SystemMessage(
      id: '',
      meetingId: meetingId,
      senderId: 'system',
      senderNickname: '시스템',
      message: message,
      timestamp: DateTime.now(),
      type: SystemMessageType.system,
    );
    await _sendMessage(systemMessage);
  }

  // 시스템 메시지 스트림 (실시간)
  Stream<List<SystemMessage>> getMessages(String meetingId, {int limit = 50}) {
    return _messagesRef(meetingId)
        .orderByChild('timestamp')
        .limitToLast(limit)
        .onValue
        .map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];

      final messages = <SystemMessage>[];
      if (data is Map) {
        data.forEach((key, value) {
          if (value is Map) {
            messages.add(SystemMessage.fromRealtimeDB(key.toString(), value));
          }
        });
      }

      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    });
  }

  // 메시지 초기화 (모임 종료 시)
  Future<void> clearMessages(String meetingId) async {
    await _messagesRef(meetingId).remove();
  }

  // ============== 시스템 이벤트 메시지 ==============

  // 입장 메시지
  Future<void> sendJoinMessage(String meetingId, String nickname) async {
    await sendSystemMessage(meetingId, '$nickname님이 입장하셨습니다.');
  }

  // 퇴장 메시지
  Future<void> sendLeaveMessage(String meetingId, String nickname) async {
    await sendSystemMessage(meetingId, '$nickname님이 퇴장하셨습니다.');
  }

  // 게임 시작 메시지
  Future<void> sendGameStartMessage(String meetingId) async {
    final gameMessage = SystemMessage(
      id: '',
      meetingId: meetingId,
      senderId: 'system',
      senderNickname: '시스템',
      message: '🎮 게임이 시작되었습니다!',
      timestamp: DateTime.now(),
      type: SystemMessageType.game,
    );
    await _sendMessage(gameMessage);
  }

  // 게임 종료 메시지
  Future<void> sendGameEndMessage(String meetingId) async {
    final gameMessage = SystemMessage(
      id: '',
      meetingId: meetingId,
      senderId: 'system',
      senderNickname: '시스템',
      message: '🏁 게임이 종료되었습니다!',
      timestamp: DateTime.now(),
      type: SystemMessageType.game,
    );
    await _sendMessage(gameMessage);
  }

  // 라운드 시작 메시지
  Future<void> sendRoundStartMessage(String meetingId, int round) async {
    final gameMessage = SystemMessage(
      id: '',
      meetingId: meetingId,
      senderId: 'system',
      senderNickname: '시스템',
      message: '🔄 라운드 $round 시작!',
      timestamp: DateTime.now(),
      type: SystemMessageType.game,
    );
    await _sendMessage(gameMessage);
  }

  // 방장 위임 메시지
  Future<void> sendHostTransferMessage(String meetingId, String oldHost, String newHost) async {
    await sendSystemMessage(meetingId, '👑 $oldHost님이 $newHost님에게 방장을 위임했습니다.');
  }
}
