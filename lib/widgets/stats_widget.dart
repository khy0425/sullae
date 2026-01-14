import 'package:flutter/material.dart';
import '../services/meeting_history_service.dart';

/// 사용자 통계 카드
class UserStatsCard extends StatelessWidget {
  final UserMeetingStats stats;

  const UserStatsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  '나의 활동',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.group,
                    label: '참여한 모임',
                    value: '${stats.totalParticipated}회',
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.star,
                    label: '호스트',
                    value: '${stats.totalHosted}회',
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.local_fire_department,
                    label: '연속',
                    value: '${stats.currentStreakDays}일',
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            if (stats.favoriteGameType != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.favorite, color: Colors.purple, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '가장 좋아하는 게임: ${_getGameTypeName(stats.favoriteGameType!)}',
                      style: const TextStyle(
                        color: Colors.purple,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getGameTypeName(String gameType) {
    switch (gameType) {
      case 'policeAndThief':
        return '경찰과 도둑';
      case 'freeze':
        return '얼음땡';
      case 'hideAndSeek':
        return '숨바꼭질';
      default:
        return gameType;
    }
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

/// 모임 기록 리스트
class MeetingHistoryList extends StatelessWidget {
  final List<MeetingHistoryItem> meetings;
  final void Function(MeetingHistoryItem)? onTap;

  const MeetingHistoryList({
    super.key,
    required this.meetings,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (meetings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '아직 모임 기록이 없습니다',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: meetings.length,
      itemBuilder: (context, index) {
        final meeting = meetings[index];
        return _MeetingHistoryTile(
          meeting: meeting,
          onTap: onTap != null ? () => onTap!(meeting) : null,
        );
      },
    );
  }
}

class _MeetingHistoryTile extends StatelessWidget {
  final MeetingHistoryItem meeting;
  final VoidCallback? onTap;

  const _MeetingHistoryTile({
    required this.meeting,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _getGameColor(meeting.gameType).withAlpha(30),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getGameIcon(meeting.gameType),
            color: _getGameColor(meeting.gameType),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                meeting.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (meeting.wasHost)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '호스트',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 12, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  _formatDate(meeting.meetingTime),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 12),
                Icon(Icons.people, size: 12, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  '${meeting.participantCount}명',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            if (meeting.locationName != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.location_on, size: 12, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      meeting.locationName!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: _buildStatusBadge(meeting),
      ),
    );
  }

  Widget _buildStatusBadge(MeetingHistoryItem meeting) {
    Color color;
    String text;

    if (meeting.isCompleted) {
      color = Colors.green;
      text = '완료';
    } else if (meeting.isCancelled) {
      color = Colors.red;
      text = '취소';
    } else if (meeting.isUpcoming) {
      color = Colors.blue;
      text = '예정';
    } else {
      color = Colors.grey;
      text = '종료';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  IconData _getGameIcon(String gameType) {
    switch (gameType) {
      case 'policeAndThief':
        return Icons.local_police;
      case 'freeze':
        return Icons.ac_unit;
      case 'hideAndSeek':
        return Icons.visibility_off;
      default:
        return Icons.sports_esports;
    }
  }

  Color _getGameColor(String gameType) {
    switch (gameType) {
      case 'policeAndThief':
        return Colors.blue;
      case 'freeze':
        return Colors.cyan;
      case 'hideAndSeek':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '오늘 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return '어제';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}일 전';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}

/// 자주 함께한 친구 위젯
class FrequentFriendsWidget extends StatelessWidget {
  final List<FrequentFriend> friends;
  final void Function(FrequentFriend)? onTap;

  const FrequentFriendsWidget({
    super.key,
    required this.friends,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: Colors.green[700]),
                const SizedBox(width: 8),
                const Text(
                  '자주 함께한 친구',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  final friend = friends[index];
                  return GestureDetector(
                    onTap: onTap != null ? () => onTap!(friend) : null,
                    child: Container(
                      width: 70,
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.grey[200],
                                backgroundImage: friend.photoUrl != null
                                    ? NetworkImage(friend.photoUrl!)
                                    : null,
                                child: friend.photoUrl == null
                                    ? Text(
                                        friend.displayName.isNotEmpty
                                            ? friend.displayName[0]
                                            : '?',
                                        style: const TextStyle(fontSize: 20),
                                      )
                                    : null,
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${friend.meetingCount}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            friend.displayName,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 연속 참여 배지
class StreakBadge extends StatelessWidget {
  final int streakDays;

  const StreakBadge({super.key, required this.streakDays});

  @override
  Widget build(BuildContext context) {
    if (streakDays == 0) {
      return const SizedBox.shrink();
    }

    Color badgeColor;
    IconData icon;

    if (streakDays >= 30) {
      badgeColor = Colors.purple;
      icon = Icons.whatshot;
    } else if (streakDays >= 14) {
      badgeColor = Colors.orange;
      icon = Icons.local_fire_department;
    } else if (streakDays >= 7) {
      badgeColor = Colors.red;
      icon = Icons.local_fire_department;
    } else {
      badgeColor = Colors.amber;
      icon = Icons.local_fire_department;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            badgeColor.withAlpha(200),
            badgeColor,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withAlpha(100),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            '$streakDays일 연속',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
