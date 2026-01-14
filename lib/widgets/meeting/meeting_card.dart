import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/meeting_model.dart';
import '../../utils/app_theme.dart';

class MeetingCard extends StatelessWidget {
  final MeetingModel meeting;
  final VoidCallback? onTap;

  const MeetingCard({
    super.key,
    required this.meeting,
    this.onTap,
  });

  Color get _gameTypeColor {
    switch (meeting.gameType) {
      case GameType.copsAndRobbers:
        return AppColors.copsAndRobbers;
      case GameType.freezeTag:
        return AppColors.freezeTag;
      case GameType.hideAndSeek:
        return AppColors.hideAndSeek;
      case GameType.captureFlag:
        return AppColors.captureFlag;
      case GameType.custom:
        return AppColors.primary;
    }
  }

  IconData get _gameTypeIcon {
    switch (meeting.gameType) {
      case GameType.copsAndRobbers:
        return Icons.local_police;
      case GameType.freezeTag:
        return Icons.ac_unit;
      case GameType.hideAndSeek:
        return Icons.visibility_off;
      case GameType.captureFlag:
        return Icons.flag;
      case GameType.custom:
        return Icons.games;
    }
  }

  /// 접근성용 전체 설명 생성
  String _buildSemanticLabel() {
    final statusText = meeting.status == MeetingStatus.recruiting ? '모집중' :
                       meeting.status == MeetingStatus.full ? '마감' :
                       meeting.status == MeetingStatus.inProgress ? '진행중' :
                       meeting.status == MeetingStatus.finished ? '종료' : '취소';

    return '${meeting.gameTypeName} 모임. '
           '${meeting.title}. '
           '$statusText. '
           '장소: ${meeting.location}. '
           '시간: ${_formatDateTime(meeting.meetingTime)}. '
           '참가자: ${meeting.currentParticipants}명 중 ${meeting.maxParticipants}명. '
           '방장: ${meeting.hostNickname}. '
           '탭하여 상세보기';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _buildSemanticLabel(),
      button: true,
      enabled: onTap != null,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          excludeFromSemantics: true, // 부모 Semantics 사용
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with game type
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _gameTypeColor.withValues(alpha: 0.1),
              ),
              child: Row(
                children: [
                  Icon(_gameTypeIcon, color: _gameTypeColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    meeting.gameTypeName,
                    style: TextStyle(
                      color: _gameTypeColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  _StatusBadge(status: meeting.status),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meeting.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          meeting.location,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Time
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDateTime(meeting.meetingTime),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Participants
                  Row(
                    children: [
                      const Icon(
                        Icons.people_outline,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${meeting.currentParticipants}/${meeting.maxParticipants}명',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: meeting.currentParticipants / meeting.maxParticipants,
                          backgroundColor: AppColors.divider,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            meeting.currentParticipants >= meeting.maxParticipants
                                ? AppColors.success
                                : _gameTypeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Host
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: _gameTypeColor.withValues(alpha: 0.2),
                        child: Text(
                          meeting.hostNickname.isNotEmpty
                              ? meeting.hostNickname[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _gameTypeColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        meeting.hostNickname,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final meetingDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dateStr;
    if (meetingDate == today) {
      dateStr = '오늘';
    } else if (meetingDate == tomorrow) {
      dateStr = '내일';
    } else {
      dateStr = DateFormat('M/d (E)', 'ko_KR').format(dateTime);
    }

    return '$dateStr ${DateFormat('HH:mm').format(dateTime)}';
  }
}

class _StatusBadge extends StatelessWidget {
  final MeetingStatus status;

  const _StatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case MeetingStatus.recruiting:
        return AppColors.success;
      case MeetingStatus.full:
        return AppColors.warning;
      case MeetingStatus.inProgress:
        return AppColors.info;
      case MeetingStatus.finished:
        return AppColors.textSecondary;
      case MeetingStatus.cancelled:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status == MeetingStatus.recruiting ? '모집중' :
        status == MeetingStatus.full ? '마감' :
        status == MeetingStatus.inProgress ? '진행중' :
        status == MeetingStatus.finished ? '종료' : '취소',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }
}
