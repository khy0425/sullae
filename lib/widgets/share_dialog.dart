import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/meeting_model.dart';
import '../services/share_service.dart';

/// 공유 다이얼로그
class ShareMeetingDialog extends StatelessWidget {
  final MeetingModel meeting;

  const ShareMeetingDialog({
    super.key,
    required this.meeting,
  });

  @override
  Widget build(BuildContext context) {
    final shareService = ShareService();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '모임 공유하기',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // 참가 코드 표시
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withAlpha(25),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    '참가코드',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    meeting.joinCode,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6B35),
                      letterSpacing: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 공유 버튼들
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ShareButton(
                  icon: Icons.copy,
                  label: '코드 복사',
                  color: Colors.grey[700]!,
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: meeting.joinCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('참가코드가 복사되었습니다'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                _ShareButton(
                  icon: Icons.people_outline,
                  label: '사람 모으기',
                  color: const Color(0xFFFF6B35),
                  onTap: () {
                    Navigator.pop(context);
                    _showGatherPeopleSheet(context, meeting, shareService);
                  },
                ),
                _ShareButton(
                  icon: Icons.qr_code,
                  label: 'QR 코드',
                  color: Colors.blue,
                  onTap: () {
                    _showQRDialog(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 외부 채팅방 링크 표시 (있을 경우)
            if (meeting.externalChatLink != null) ...[
              const Divider(),
              const SizedBox(height: 8),
              _ExternalChatLinkRow(
                link: meeting.externalChatLink!,
                onTap: () => _launchUrl(meeting.externalChatLink!),
              ),
              const SizedBox(height: 8),
            ],

            // 닫기 버튼
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('닫기'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showGatherPeopleSheet(
    BuildContext context,
    MeetingModel meeting,
    ShareService shareService,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => GatherPeopleSheet(
        meeting: meeting,
        shareService: shareService,
      ),
    );
  }

  void _showQRDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '참가 코드',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              QRCodeWidget(
                data: meeting.joinCode,
                size: 200,
              ),
              const SizedBox(height: 16),
              Text(
                '친구에게 이 화면을 보여주세요',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('닫기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 외부 채팅방 링크 표시 행
class _ExternalChatLinkRow extends StatelessWidget {
  final String link;
  final VoidCallback onTap;

  const _ExternalChatLinkRow({
    required this.link,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.chat_bubble_outline, color: Colors.blue, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '채팅방 바로가기',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    link,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

/// 사람 모으기 바텀시트
class GatherPeopleSheet extends StatefulWidget {
  final MeetingModel meeting;
  final ShareService shareService;

  const GatherPeopleSheet({
    super.key,
    required this.meeting,
    required this.shareService,
  });

  @override
  State<GatherPeopleSheet> createState() => _GatherPeopleSheetState();
}

class _GatherPeopleSheetState extends State<GatherPeopleSheet> {
  ShareChannel _selectedChannel = ShareChannel.kakaoTalk;
  late InviteTone _selectedTone;
  final TextEditingController _chatLinkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedTone = widget.shareService.getRecommendedTone(_selectedChannel);
    if (widget.meeting.externalChatLink != null) {
      _chatLinkController.text = widget.meeting.externalChatLink!;
    }
  }

  @override
  void dispose() {
    _chatLinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.shareService.generateInviteMessage(
      meeting: widget.meeting,
      tone: _selectedTone,
      customChatLink: _chatLinkController.text.isNotEmpty ? _chatLinkController.text : null,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 핸들
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 제목
                const Text(
                  '사람 모으기',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '초대 메시지를 만들어 공유하세요',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),

                // 채널 선택
                const Text(
                  '어디서 공유할까요?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ShareChannel.values.map((channel) {
                    final isSelected = _selectedChannel == channel;
                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.shareService.getChannelIcon(channel),
                            size: 18,
                            color: isSelected ? Colors.white : Colors.grey[700],
                          ),
                          const SizedBox(width: 6),
                          Text(widget.shareService.getChannelName(channel)),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedChannel = channel;
                            _selectedTone = widget.shareService.getRecommendedTone(channel);
                          });
                        }
                      },
                      selectedColor: const Color(0xFFFF6B35),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // 톤 선택
                const Text(
                  '메시지 스타일',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ToneButton(
                        label: '편하게',
                        description: '친구들에게',
                        isSelected: _selectedTone == InviteTone.casual,
                        onTap: () => setState(() => _selectedTone = InviteTone.casual),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ToneButton(
                        label: '활기차게',
                        description: '동네 모집',
                        isSelected: _selectedTone == InviteTone.enthusiastic,
                        onTap: () => setState(() => _selectedTone = InviteTone.enthusiastic),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 채팅방 링크 입력
                const Text(
                  '채팅방 링크 (선택)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '오픈채팅 링크를 넣으면 메시지에 포함됩니다',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _chatLinkController,
                  decoration: InputDecoration(
                    hintText: 'https://open.kakao.com/...',
                    prefixIcon: const Icon(Icons.link),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 24),

                // 미리보기
                const Text(
                  '미리보기',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 복사 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: message));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('초대 메시지가 복사되었습니다'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('메시지 복사하기'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 안내 문구
                Center(
                  child: Text(
                    '복사 후 카카오톡이나 SNS에 붙여넣기 하세요',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 톤 선택 버튼
class _ToneButton extends StatelessWidget {
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToneButton({
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF6B35).withAlpha(25) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF6B35) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? const Color(0xFFFF6B35) : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 공유 버튼
class _ShareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
