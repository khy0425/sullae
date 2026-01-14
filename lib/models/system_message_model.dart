/// 시스템 메시지 모델
///
/// 시스템이 자동 발송하는 알림만 처리
/// 사용자 간 소통은 QuickMessage로만
class SystemMessage {
  final String id;
  final String meetingId;
  final String senderId;
  final String senderNickname;
  final String message;
  final DateTime timestamp;
  final SystemMessageType type;

  SystemMessage({
    required this.id,
    required this.meetingId,
    required this.senderId,
    required this.senderNickname,
    required this.message,
    required this.timestamp,
    this.type = SystemMessageType.system,
  });

  factory SystemMessage.fromRealtimeDB(String id, Map<dynamic, dynamic> data) {
    return SystemMessage(
      id: id,
      meetingId: data['meetingId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderNickname: data['senderNickname'] ?? '',
      message: data['message'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp'] ?? 0),
      type: SystemMessageType.values[data['type'] ?? 0],
    );
  }

  Map<String, dynamic> toRealtimeDB() {
    return {
      'meetingId': meetingId,
      'senderId': senderId,
      'senderNickname': senderNickname,
      'message': message,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'type': type.index,
    };
  }
}

/// 시스템 메시지 타입 (자유 채팅 없음)
enum SystemMessageType {
  system, // 시스템 메시지 (입장, 퇴장 등)
  game,   // 게임 관련 (라운드 시작, 종료 등)
  // text 타입 의도적 제거 - 자유 채팅 없음
  // 사용자 간 소통은 QuickMessage로만
}

/// 하위 호환성을 위한 별칭 (deprecated)
@Deprecated('Use SystemMessage instead')
typedef ChatMessage = SystemMessage;

@Deprecated('Use SystemMessageType instead')
typedef MessageType = SystemMessageType;
