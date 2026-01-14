import 'package:flutter/material.dart';
import '../models/quick_message_model.dart';
import '../services/quick_message_service.dart';

/// 퀵 메시지 위젯 (모임 상세에서 사용)
class QuickMessageWidget extends StatefulWidget {
  final String meetingId;
  final String userId;
  final String userNickname;
  final bool isHost;

  const QuickMessageWidget({
    super.key,
    required this.meetingId,
    required this.userId,
    required this.userNickname,
    this.isHost = false,
  });

  @override
  State<QuickMessageWidget> createState() => _QuickMessageWidgetState();
}

class _QuickMessageWidgetState extends State<QuickMessageWidget> {
  final QuickMessageService _messageService = QuickMessageService();
  bool _isSending = false;

  List<QuickMessageDef> get _availableMessages =>
      widget.isHost ? QuickMessageDef.forHost : QuickMessageDef.forParticipant;

  Future<void> _sendMessage(QuickMessageType type) async {
    if (_isSending) return;

    setState(() => _isSending = true);

    try {
      await _messageService.sendMessage(
        meetingId: widget.meetingId,
        senderId: widget.userId,
        senderNickname: widget.userNickname,
        type: type,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${QuickMessageDef.fromType(type)?.fullText ?? ""} 전송됨'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('메시지 전송 실패'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 헤더
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.flash_on, color: Color(0xFFFF6B35), size: 20),
              const SizedBox(width: 8),
              const Text(
                '퀵 메시지',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_isSending)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),

        // 메시지 버튼들
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _availableMessages.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final msg = _availableMessages[index];
              return _QuickMessageButton(
                message: msg,
                onTap: () => _sendMessage(msg.type),
                enabled: !_isSending,
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // 최근 메시지
        _RecentMessages(meetingId: widget.meetingId),
      ],
    );
  }
}

/// 퀵 메시지 버튼
class _QuickMessageButton extends StatelessWidget {
  final QuickMessageDef message;
  final VoidCallback onTap;
  final bool enabled;

  const _QuickMessageButton({
    required this.message,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.emoji,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 6),
              Text(
                message.text,
                style: TextStyle(
                  fontSize: 13,
                  color: enabled ? Colors.grey[800] : Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 최근 메시지 목록
class _RecentMessages extends StatelessWidget {
  final String meetingId;

  const _RecentMessages({required this.meetingId});

  @override
  Widget build(BuildContext context) {
    final messageService = QuickMessageService();

    return StreamBuilder<List<QuickMessage>>(
      stream: messageService.getRecentMessages(meetingId, limit: 5),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '아직 메시지가 없어요',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          );
        }

        final messages = snapshot.data!;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: messages.map((msg) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Text(
                      msg.definition?.emoji ?? '',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      msg.senderNickname,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        msg.definition?.text ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    Text(
                      _formatTime(msg.sentAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return '방금';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${time.month}/${time.day}';
  }
}

/// 퀵 메시지 전송 바텀 시트
class QuickMessageBottomSheet extends StatelessWidget {
  final String meetingId;
  final String userId;
  final String userNickname;
  final bool isHost;

  const QuickMessageBottomSheet({
    super.key,
    required this.meetingId,
    required this.userId,
    required this.userNickname,
    this.isHost = false,
  });

  static Future<void> show({
    required BuildContext context,
    required String meetingId,
    required String userId,
    required String userNickname,
    bool isHost = false,
  }) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => QuickMessageBottomSheet(
        meetingId: meetingId,
        userId: userId,
        userNickname: userNickname,
        isHost: isHost,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = isHost
        ? QuickMessageDef.forHost
        : QuickMessageDef.forParticipant;

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '퀵 메시지 보내기',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '정해진 메시지로 빠르게 소통하세요',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),

              // 메시지 그리드
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: messages.where((m) => m.type != QuickMessageType.customAnnounce).map((msg) {
                  return _QuickMessageTile(
                    message: msg,
                    onTap: () async {
                      final service = QuickMessageService();
                      await service.sendMessage(
                        meetingId: meetingId,
                        senderId: userId,
                        senderNickname: userNickname,
                        type: msg.type,
                      );

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${msg.fullText} 전송됨'),
                            duration: const Duration(seconds: 1),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                  );
                }).toList(),
              ),

              // 호스트 전용 커스텀 공지 버튼
              if (isHost) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                _CustomAnnouncementTile(
                  meetingId: meetingId,
                  hostId: userId,
                  hostNickname: userNickname,
                ),
              ],

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// 퀵 메시지 타일 (바텀시트용)
class _QuickMessageTile extends StatelessWidget {
  final QuickMessageDef message;
  final VoidCallback onTap;

  const _QuickMessageTile({
    required this.message,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: message.hostOnly ? Colors.blue.withAlpha(20) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: message.hostOnly
              ? Border.all(color: Colors.blue.withAlpha(50))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.emoji,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Text(
              message.text,
              style: TextStyle(
                fontSize: 14,
                color: message.hostOnly ? Colors.blue[700] : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 참가자 상태 요약 위젯
class ParticipantStatusWidget extends StatelessWidget {
  final String meetingId;
  final List<String> participantIds;

  const ParticipantStatusWidget({
    super.key,
    required this.meetingId,
    required this.participantIds,
  });

  @override
  Widget build(BuildContext context) {
    final messageService = QuickMessageService();

    return StreamBuilder<int>(
      stream: messageService.getArrivedCount(meetingId),
      builder: (context, snapshot) {
        final arrivedCount = snapshot.data ?? 0;
        final totalCount = participantIds.length;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 18, color: Colors.green),
              const SizedBox(width: 6),
              Text(
                '$arrivedCount/$totalCount 도착',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 커스텀 공지 타일 (방장 전용)
class _CustomAnnouncementTile extends StatelessWidget {
  final String meetingId;
  final String hostId;
  final String hostNickname;

  const _CustomAnnouncementTile({
    required this.meetingId,
    required this.hostId,
    required this.hostNickname,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showCustomAnnouncementDialog(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.orange.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withAlpha(50)),
        ),
        child: Row(
          children: [
            const Text('📢', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '커스텀 공지 작성',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange[800],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '장소 변경, 날씨 상황 등을 직접 입력하세요',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit, size: 20, color: Colors.orange[700]),
          ],
        ),
      ),
    );
  }

  void _showCustomAnnouncementDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => _CustomAnnouncementDialog(
        meetingId: meetingId,
        hostId: hostId,
        hostNickname: hostNickname,
        onSuccess: () {
          Navigator.pop(dialogContext); // 다이얼로그 닫기
          Navigator.pop(context); // 바텀시트 닫기
        },
      ),
    );
  }
}

/// 커스텀 공지 입력 다이얼로그
class _CustomAnnouncementDialog extends StatefulWidget {
  final String meetingId;
  final String hostId;
  final String hostNickname;
  final VoidCallback onSuccess;

  const _CustomAnnouncementDialog({
    required this.meetingId,
    required this.hostId,
    required this.hostNickname,
    required this.onSuccess,
  });

  @override
  State<_CustomAnnouncementDialog> createState() => _CustomAnnouncementDialogState();
}

class _CustomAnnouncementDialogState extends State<_CustomAnnouncementDialog> {
  final TextEditingController _controller = TextEditingController();
  final QuickMessageService _service = QuickMessageService();
  bool _isSending = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_isSending) return;

    setState(() {
      _isSending = true;
      _error = null;
    });

    final errorMsg = await _service.sendCustomAnnouncement(
      meetingId: widget.meetingId,
      hostId: widget.hostId,
      hostNickname: widget.hostNickname,
      text: _controller.text,
    );

    if (!mounted) return;

    if (errorMsg != null) {
      setState(() {
        _isSending = false;
        _error = errorMsg;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📢 공지가 전송되었습니다'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      widget.onSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textLength = _controller.text.length;
    final isValidLength = textLength >= QuickMessage.customMinLength &&
        textLength <= QuickMessage.customMaxLength;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Text('📢', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          const Text('공지 작성'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '참가자들에게 중요한 정보를 알려주세요',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _controller,
            maxLength: QuickMessage.customMaxLength,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: '예: 비가 와서 10분 대기합니다',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              counterText: '$textLength/${QuickMessage.customMaxLength}',
            ),
            onChanged: (_) => setState(() {}),
          ),

          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ],

          const SizedBox(height: 8),
          Text(
            '• 최소 ${QuickMessage.customMinLength}자 이상 입력\n• 1분에 1번만 전송 가능\n• 전송 후 수정 불가',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSending ? null : () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: (_isSending || !isValidLength) ? null : _send,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: _isSending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('전송'),
        ),
      ],
    );
  }
}
