import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import '../models/meeting_model.dart';

/// 초대 메시지 톤
enum InviteTone {
  casual,      // 친구 모으기 (편하게)
  enthusiastic, // 동네 모집 (활기차게)
}

/// 공유 채널
enum ShareChannel {
  kakaoTalk,   // 카카오톡 (친구에게 직접)
  openChat,    // 오픈채팅 (동네 모집)
  instagram,   // 인스타그램 스토리
  community,   // 커뮤니티 (에브리타임, 당근 등)
}

/// 공유 서비스
/// - 카카오톡 공유
/// - QR 코드 생성
/// - 딥링크 생성
/// - 톤별 초대 메시지 생성
class ShareService {
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();

  /// 앱 스킴
  static const String appScheme = 'sullae';

  /// 모임 초대 딥링크 생성
  String generateInviteLink(MeetingModel meeting) {
    // 딥링크 형식: sullae://join?code=ABC123
    return '$appScheme://join?code=${meeting.joinCode}';
  }

  /// 모임 공유 메시지 생성
  String generateShareMessage(MeetingModel meeting) {
    final gameTypeName = meeting.gameTypeName;
    final dateStr = _formatDate(meeting.meetingTime);
    final timeStr = _formatTime(meeting.meetingTime);

    return '''
[술래] $gameTypeName 모임 초대

${meeting.title}

$dateStr $timeStr
${meeting.location}

참가코드: ${meeting.joinCode}
인원: ${meeting.currentParticipants}/${meeting.maxParticipants}명

앱에서 참가코드를 입력하세요!
''';
  }

  /// 간단한 공유 텍스트 생성
  String generateSimpleShareText(MeetingModel meeting) {
    return '${meeting.title} 모임에 참여하세요! 참가코드: ${meeting.joinCode}';
  }

  /// 톤별 초대 메시지 생성
  /// 외부 채팅방으로 사람을 모을 때 사용
  String generateInviteMessage({
    required MeetingModel meeting,
    required InviteTone tone,
    String? customChatLink,
  }) {
    final gameTypeName = meeting.gameTypeName;
    final dateStr = _formatDate(meeting.meetingTime);
    final timeStr = _formatTime(meeting.meetingTime);
    final chatLink = customChatLink ?? meeting.externalChatLink;

    switch (tone) {
      case InviteTone.casual:
        // 친구들 모으기용 (편하고 가벼운 톤)
        return '''
$dateStr $timeStr에 ${meeting.location}에서 $gameTypeName 할 사람~?

${meeting.title}

${meeting.currentParticipants}/${meeting.maxParticipants}명 모집 중!
${chatLink != null ? '\n참여하려면 여기로 👉 $chatLink' : ''}
참가코드: ${meeting.joinCode}
''';

      case InviteTone.enthusiastic:
        // 동네 모집용 (활기차고 모집 느낌)
        return '''
🏃 $gameTypeName 같이 하실 분!

${meeting.title}

$dateStr $timeStr
${meeting.location}

${meeting.currentParticipants}명 모집 완료 / 최대 ${meeting.maxParticipants}명
${chatLink != null ? '\n채팅방: $chatLink' : ''}

참가코드: ${meeting.joinCode}
술래 앱에서 만나요!
''';
    }
  }

  /// 채널별 추천 메시지 가져오기
  /// 각 채널에 맞는 톤을 추천
  InviteTone getRecommendedTone(ShareChannel channel) {
    switch (channel) {
      case ShareChannel.kakaoTalk:
      case ShareChannel.instagram:
        return InviteTone.casual;
      case ShareChannel.openChat:
      case ShareChannel.community:
        return InviteTone.enthusiastic;
    }
  }

  /// 채널 이름 가져오기
  String getChannelName(ShareChannel channel) {
    switch (channel) {
      case ShareChannel.kakaoTalk:
        return '카카오톡';
      case ShareChannel.openChat:
        return '오픈채팅';
      case ShareChannel.instagram:
        return '인스타그램';
      case ShareChannel.community:
        return '커뮤니티';
    }
  }

  /// 채널 아이콘 가져오기
  IconData getChannelIcon(ShareChannel channel) {
    switch (channel) {
      case ShareChannel.kakaoTalk:
        return Icons.chat_bubble;
      case ShareChannel.openChat:
        return Icons.forum;
      case ShareChannel.instagram:
        return Icons.camera_alt;
      case ShareChannel.community:
        return Icons.groups;
    }
  }

  /// 날짜 포맷
  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(dt.year, dt.month, dt.day);
    final diff = targetDate.difference(today).inDays;

    if (diff == 0) return '오늘';
    if (diff == 1) return '내일';
    if (diff == 2) return '모레';

    return '${dt.month}월 ${dt.day}일';
  }

  /// 시간 포맷
  String _formatTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute;
    final period = hour < 12 ? '오전' : '오후';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    if (minute == 0) {
      return '$period $displayHour시';
    }
    return '$period $displayHour시 $minute분';
  }
}

/// QR 코드 생성 위젯
class QRCodeWidget extends StatelessWidget {
  final String data;
  final double size;
  final Color foregroundColor;
  final Color backgroundColor;

  const QRCodeWidget({
    super.key,
    required this.data,
    this.size = 200,
    this.foregroundColor = Colors.black,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    // 간단한 QR 코드 스타일 표시 (실제 QR 생성을 위해 qr_flutter 패키지 필요)
    // 여기서는 참가 코드를 중앙에 크게 표시하는 방식으로 구현
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: foregroundColor.withAlpha(50), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_2,
            size: size * 0.4,
            color: foregroundColor.withAlpha(200),
          ),
          const SizedBox(height: 16),
          Text(
            data,
            style: TextStyle(
              fontSize: size * 0.15,
              fontWeight: FontWeight.bold,
              color: foregroundColor,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '참가코드',
            style: TextStyle(
              fontSize: size * 0.06,
              color: foregroundColor.withAlpha(150),
            ),
          ),
        ],
      ),
    );
  }
}

/// 공유 카드 위젯 (캡처용)
class ShareCard extends StatelessWidget {
  final MeetingModel meeting;
  final GlobalKey repaintBoundaryKey;

  const ShareCard({
    super.key,
    required this.meeting,
    required this.repaintBoundaryKey,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: repaintBoundaryKey,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFF6B35),
              const Color(0xFFFF8C5A),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 로고
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Text('👀', style: TextStyle(fontSize: 32)),
            ),
            const SizedBox(height: 16),

            // 앱 이름
            Text(
              '술래',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              meeting.gameTypeName,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withAlpha(200),
              ),
            ),
            const SizedBox(height: 24),

            // 모임 정보
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    meeting.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.access_time, _formatDateTime(meeting.meetingTime)),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.location_on, meeting.location),
                  const SizedBox(height: 16),

                  // 참가 코드
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35).withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '참가코드',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          meeting.joinCode,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF6B35),
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Text(
              '앱에서 참가코드를 입력하세요',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withAlpha(200),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour < 12 ? '오전' : '오후';
    return '${dt.month}/${dt.day} $period $hour:${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// 위젯을 이미지로 캡처
Future<Uint8List?> captureWidget(GlobalKey key) async {
  try {
    final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;

    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData?.buffer.asUint8List();
  } catch (e) {
    if (kDebugMode) print('Error capturing widget: $e');
    return null;
  }
}
