import 'package:cloud_firestore/cloud_firestore.dart';

/// 퀵 메시지 타입
enum QuickMessageType {
  // 참가자용
  arrived,      // 📍 지금 도착했어요
  late5,        // ⏰ 5분 늦어요
  late10,       // ⏰ 10분 늦어요
  onMyWay,      // 🚶 가고 있어요
  ready,        // ✅ 게임 시작 가능해요
  goingAhead,   // 🏃 먼저 가서 기다릴게요
  cantMake,     // 👋 오늘 못 갈 것 같아요
  locationCheck,// ❓ 위치 변경됐나요?

  // 호스트 전용
  whereAreYou,  // 📍 어디쯤이세요?
  startSoon,    // ⏳ 곧 시작해요

  // 호스트 공지 (긴급 상황)
  locationChanged,  // 📢 장소가 변경됐어요
  timeChanged,      // 📢 시간이 변경됐어요
  cancelled,        // ❌ 오늘 모임 취소
  waitingAtEntrance,// 🚪 입구에서 기다릴게요

  // 호스트 커스텀 공지 (40~60자 제한, 1분 쿨타임)
  customAnnounce,   // 📢 커스텀 공지
}

/// 퀵 메시지 정의
class QuickMessageDef {
  final QuickMessageType type;
  final String emoji;
  final String text;
  final bool hostOnly;  // 호스트만 사용 가능

  const QuickMessageDef({
    required this.type,
    required this.emoji,
    required this.text,
    this.hostOnly = false,
  });

  /// 모든 퀵 메시지 정의
  static const List<QuickMessageDef> all = [
    // 참가자용
    QuickMessageDef(type: QuickMessageType.arrived, emoji: '📍', text: '지금 도착했어요'),
    QuickMessageDef(type: QuickMessageType.onMyWay, emoji: '🚶', text: '가고 있어요'),
    QuickMessageDef(type: QuickMessageType.late5, emoji: '⏰', text: '5분 늦어요'),
    QuickMessageDef(type: QuickMessageType.late10, emoji: '⏰', text: '10분 늦어요'),
    QuickMessageDef(type: QuickMessageType.ready, emoji: '✅', text: '게임 시작 가능해요'),
    QuickMessageDef(type: QuickMessageType.goingAhead, emoji: '🏃', text: '먼저 가서 기다릴게요'),
    QuickMessageDef(type: QuickMessageType.cantMake, emoji: '👋', text: '오늘 못 갈 것 같아요'),
    QuickMessageDef(type: QuickMessageType.locationCheck, emoji: '❓', text: '위치 변경됐나요?'),

    // 호스트 전용
    QuickMessageDef(type: QuickMessageType.whereAreYou, emoji: '📍', text: '어디쯤이세요?', hostOnly: true),
    QuickMessageDef(type: QuickMessageType.startSoon, emoji: '⏳', text: '곧 시작해요', hostOnly: true),
    QuickMessageDef(type: QuickMessageType.waitingAtEntrance, emoji: '🚪', text: '입구에서 기다릴게요', hostOnly: true),

    // 호스트 공지 (긴급)
    QuickMessageDef(type: QuickMessageType.locationChanged, emoji: '📢', text: '장소가 변경됐어요', hostOnly: true),
    QuickMessageDef(type: QuickMessageType.timeChanged, emoji: '📢', text: '시간이 변경됐어요', hostOnly: true),
    QuickMessageDef(type: QuickMessageType.cancelled, emoji: '❌', text: '오늘 모임 취소', hostOnly: true),

    // 호스트 커스텀 공지 (customText 필드에 내용 저장)
    QuickMessageDef(type: QuickMessageType.customAnnounce, emoji: '📢', text: '공지', hostOnly: true),
  ];

  /// 일반 참가자용 메시지
  static List<QuickMessageDef> get forParticipant =>
      all.where((m) => !m.hostOnly).toList();

  /// 호스트용 메시지 (전체)
  static List<QuickMessageDef> get forHost => all;

  /// 타입으로 찾기
  static QuickMessageDef? fromType(QuickMessageType type) {
    try {
      return all.firstWhere((m) => m.type == type);
    } catch (_) {
      return null;
    }
  }

  /// 전체 텍스트 (이모지 포함)
  String get fullText => '$emoji $text';
}

/// 퀵 메시지 (전송된 메시지)
class QuickMessage {
  final String id;
  final String meetingId;
  final String senderId;
  final String senderNickname;
  final QuickMessageType type;
  final DateTime sentAt;
  final String? customText; // 커스텀 공지용 (40~60자)

  /// 커스텀 공지 제약 조건
  static const int customMinLength = 5;
  static const int customMaxLength = 60;
  static const Duration cooldownDuration = Duration(minutes: 1);

  QuickMessage({
    required this.id,
    required this.meetingId,
    required this.senderId,
    required this.senderNickname,
    required this.type,
    required this.sentAt,
    this.customText,
  });

  factory QuickMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QuickMessage(
      id: doc.id,
      meetingId: data['meetingId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderNickname: data['senderNickname'] ?? '',
      type: QuickMessageType.values[data['type'] ?? 0],
      sentAt: (data['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      customText: data['customText'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'meetingId': meetingId,
    'senderId': senderId,
    'senderNickname': senderNickname,
    'type': type.index,
    'sentAt': Timestamp.fromDate(sentAt),
    if (customText != null) 'customText': customText,
  };

  /// 메시지 정의 가져오기
  QuickMessageDef? get definition => QuickMessageDef.fromType(type);

  /// 표시용 텍스트
  String get displayText {
    // 커스텀 공지는 customText 표시
    if (type == QuickMessageType.customAnnounce && customText != null) {
      return '📢 $senderNickname: $customText';
    }

    final def = definition;
    if (def == null) return '';
    return '$senderNickname: ${def.fullText}';
  }

  /// 짧은 표시 (알림용)
  String get shortText {
    // 커스텀 공지는 앞부분만
    if (type == QuickMessageType.customAnnounce && customText != null) {
      final preview = customText!.length > 15
          ? '${customText!.substring(0, 15)}...'
          : customText!;
      return '📢 $preview';
    }

    final def = definition;
    if (def == null) return '';
    return '${def.emoji} $senderNickname';
  }

  /// 커스텀 공지인지 확인
  bool get isCustomAnnouncement => type == QuickMessageType.customAnnounce;
}
