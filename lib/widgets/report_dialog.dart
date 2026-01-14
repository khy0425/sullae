import 'package:flutter/material.dart';
import '../services/report_service.dart';

/// 신고 다이얼로그
class ReportDialog extends StatefulWidget {
  final String reporterId;
  final String reportedUserId;
  final String reportedUserName;
  final String meetingId;
  final VoidCallback? onReported;

  const ReportDialog({
    super.key,
    required this.reporterId,
    required this.reportedUserId,
    required this.reportedUserName,
    required this.meetingId,
    this.onReported,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String reporterId,
    required String reportedUserId,
    required String reportedUserName,
    required String meetingId,
    VoidCallback? onReported,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ReportDialog(
        reporterId: reporterId,
        reportedUserId: reportedUserId,
        reportedUserName: reportedUserName,
        meetingId: meetingId,
        onReported: onReported,
      ),
    );
  }

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final ReportService _reportService = ReportService();
  ReportReason? _selectedReason;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('신고 사유를 선택해주세요')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await _reportService.reportUser(
      reporterId: widget.reporterId,
      reportedUserId: widget.reportedUserId,
      meetingId: widget.meetingId,
      reason: _selectedReason!,
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
    );

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (success) {
        widget.onReported?.call();
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('신고가 접수되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('이미 이 모임에서 해당 사용자를 신고했습니다'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.flag, color: Colors.red[400]),
          const SizedBox(width: 8),
          const Text('사용자 신고'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.reportedUserName}님을 신고하시겠습니까?',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              '신고 사유',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            RadioGroup<ReportReason>(
              groupValue: _selectedReason,
              onChanged: (value) => setState(() => _selectedReason = value),
              child: Column(
                children: ReportReason.values.map((reason) => Row(
                  children: [
                    Radio<ReportReason>(value: reason),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedReason = reason),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(reason.label, style: const TextStyle(fontSize: 14)),
                        ),
                      ),
                    ),
                  ],
                )).toList(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: '상세 내용 (선택)',
                hintText: '추가 설명이 있다면 적어주세요',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
              maxLength: 200,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '허위 신고는 제재 대상이 될 수 있습니다',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[400],
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('신고하기'),
        ),
      ],
    );
  }
}

/// 차단 확인 다이얼로그
class BlockUserDialog extends StatefulWidget {
  final String userId;
  final String targetUserId;
  final String targetUserName;
  final VoidCallback? onBlocked;

  const BlockUserDialog({
    super.key,
    required this.userId,
    required this.targetUserId,
    required this.targetUserName,
    this.onBlocked,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String userId,
    required String targetUserId,
    required String targetUserName,
    VoidCallback? onBlocked,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => BlockUserDialog(
        userId: userId,
        targetUserId: targetUserId,
        targetUserName: targetUserName,
        onBlocked: onBlocked,
      ),
    );
  }

  @override
  State<BlockUserDialog> createState() => _BlockUserDialogState();
}

class _BlockUserDialogState extends State<BlockUserDialog> {
  final ReportService _reportService = ReportService();
  bool _isBlocking = false;

  Future<void> _blockUser() async {
    setState(() => _isBlocking = true);

    final success = await _reportService.blockUser(
      widget.userId,
      widget.targetUserId,
    );

    setState(() => _isBlocking = false);

    if (mounted) {
      if (success) {
        widget.onBlocked?.call();
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.targetUserName}님을 차단했습니다'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('차단에 실패했습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.block, color: Colors.red[400]),
          const SizedBox(width: 8),
          const Text('사용자 차단'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.targetUserName}님을 차단하시겠습니까?'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '차단하면:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                _buildBlockEffect('상대방의 모임을 볼 수 없습니다'),
                _buildBlockEffect('내 모임에 상대방이 참여할 수 없습니다'),
                _buildBlockEffect('상대방에게 알림이 가지 않습니다'),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isBlocking ? null : () => Navigator.pop(context, false),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: _isBlocking ? null : _blockUser,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[400],
            foregroundColor: Colors.white,
          ),
          child: _isBlocking
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('차단하기'),
        ),
      ],
    );
  }

  Widget _buildBlockEffect(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 6, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}

/// 사용자 신고/차단 메뉴 버튼
class UserReportMenuButton extends StatelessWidget {
  final String currentUserId;
  final String targetUserId;
  final String targetUserName;
  final String? meetingId;

  const UserReportMenuButton({
    super.key,
    required this.currentUserId,
    required this.targetUserId,
    required this.targetUserName,
    this.meetingId,
  });

  @override
  Widget build(BuildContext context) {
    // 자기 자신은 신고/차단 불가
    if (currentUserId == targetUserId) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) async {
        switch (value) {
          case 'report':
            if (meetingId != null) {
              await ReportDialog.show(
                context: context,
                reporterId: currentUserId,
                reportedUserId: targetUserId,
                reportedUserName: targetUserName,
                meetingId: meetingId!,
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('모임 내에서만 신고할 수 있습니다')),
              );
            }
            break;
          case 'block':
            await BlockUserDialog.show(
              context: context,
              userId: currentUserId,
              targetUserId: targetUserId,
              targetUserName: targetUserName,
            );
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'report',
          child: Row(
            children: [
              Icon(Icons.flag_outlined, color: Colors.orange[700], size: 20),
              const SizedBox(width: 12),
              const Text('신고하기'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'block',
          child: Row(
            children: [
              Icon(Icons.block, color: Colors.red[400], size: 20),
              const SizedBox(width: 12),
              const Text('차단하기'),
            ],
          ),
        ),
      ],
    );
  }
}
