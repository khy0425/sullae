import 'package:flutter/material.dart';
import '../../models/badge_model.dart';
import '../../services/badge_service.dart';

/// 내 배지 화면
class MyBadgesScreen extends StatefulWidget {
  final String odId;

  const MyBadgesScreen({super.key, required this.odId});

  @override
  State<MyBadgesScreen> createState() => _MyBadgesScreenState();
}

class _MyBadgesScreenState extends State<MyBadgesScreen> {
  final BadgeService _badgeService = BadgeService();

  @override
  void initState() {
    super.initState();
    // 새 배지 표시 제거
    _badgeService.markBadgesAsSeen(widget.odId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 배지'),
      ),
      body: StreamBuilder<UserBadges>(
        stream: _badgeService.getUserBadgesStream(widget.odId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userBadges = snapshot.data ?? UserBadges(badges: []);
          final earnedTypes = userBadges.badges.map((b) => b.type).toSet();

          return CustomScrollView(
            slivers: [
              // 통계 헤더
              SliverToBoxAdapter(
                child: _buildStatsHeader(userBadges),
              ),
              // 배지 그리드
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final badgeType = BadgeType.values[index];
                      final info = BadgeDefinitions.get(badgeType);
                      if (info == null) return const SizedBox();

                      final isEarned = earnedTypes.contains(badgeType);
                      final userBadge = isEarned
                          ? userBadges.badges.firstWhere((b) => b.type == badgeType)
                          : null;

                      return _BadgeCard(
                        info: info,
                        isEarned: isEarned,
                        earnedAt: userBadge?.earnedAt,
                        isNew: userBadge?.isNew ?? false,
                      );
                    },
                    childCount: BadgeType.values.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsHeader(UserBadges userBadges) {
    final totalBadges = BadgeType.values.length;
    final earnedCount = userBadges.totalCount;
    final progress = earnedCount / totalBadges;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFFF8F65)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$earnedCount',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                ' / $totalBadges',
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '획득한 배지',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white30,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toInt()}% 달성',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

/// 배지 카드
class _BadgeCard extends StatelessWidget {
  final BadgeInfo info;
  final bool isEarned;
  final DateTime? earnedAt;
  final bool isNew;

  const _BadgeCard({
    required this.info,
    required this.isEarned,
    this.earnedAt,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showBadgeDetail(context),
      child: Container(
        decoration: BoxDecoration(
          color: isEarned ? Colors.white : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEarned ? _getRarityColor(info.rarity) : Colors.grey[300]!,
            width: isEarned ? 2 : 1,
          ),
          boxShadow: isEarned
              ? [
                  BoxShadow(
                    color: _getRarityColor(info.rarity).withAlpha(50),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isEarned ? info.emoji : '❓',
                    style: TextStyle(
                      fontSize: 32,
                      color: isEarned ? null : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isEarned ? info.name : '???',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isEarned ? Colors.black87 : Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isNew)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showBadgeDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isEarned
                    ? _getRarityColor(info.rarity).withAlpha(30)
                    : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Text(
                isEarned ? info.emoji : '❓',
                style: const TextStyle(fontSize: 48),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isEarned ? info.name : '???',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getRarityColor(info.rarity).withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                info.rarity.label,
                style: TextStyle(
                  fontSize: 12,
                  color: _getRarityColor(info.rarity),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              info.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (isEarned && earnedAt != null) ...[
              const SizedBox(height: 16),
              Text(
                '${earnedAt!.year}.${earnedAt!.month}.${earnedAt!.day} 획득',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Color _getRarityColor(BadgeRarity rarity) {
    switch (rarity) {
      case BadgeRarity.common:
        return Colors.grey;
      case BadgeRarity.uncommon:
        return Colors.green;
      case BadgeRarity.rare:
        return Colors.blue;
      case BadgeRarity.epic:
        return Colors.purple;
      case BadgeRarity.legendary:
        return Colors.orange;
    }
  }
}
