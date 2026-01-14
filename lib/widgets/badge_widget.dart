import 'package:flutter/material.dart';
import '../models/badge_model.dart';

/// 배지 아이콘 위젯
class BadgeIcon extends StatelessWidget {
  final BadgeInfo badge;
  final double size;
  final bool showName;
  final bool isLocked;

  const BadgeIcon({
    super.key,
    required this.badge,
    this.size = 48,
    this.showName = false,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isLocked
                ? Colors.grey[300]
                : _parseColor(badge.rarity.colorHex).withAlpha(30),
            border: Border.all(
              color: isLocked
                  ? Colors.grey[400]!
                  : _parseColor(badge.rarity.colorHex),
              width: 2,
            ),
          ),
          child: Center(
            child: isLocked
                ? Icon(Icons.lock, size: size * 0.5, color: Colors.grey[500])
                : Text(
                    badge.emoji,
                    style: TextStyle(fontSize: size * 0.5),
                  ),
          ),
        ),
        if (showName) ...[
          const SizedBox(height: 4),
          Text(
            badge.name,
            style: TextStyle(
              fontSize: 12,
              color: isLocked ? Colors.grey[500] : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Color _parseColor(String hex) {
    return Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
  }
}

/// 배지 그리드 위젯
class BadgeGrid extends StatelessWidget {
  final UserBadges userBadges;
  final bool showLocked;
  final int crossAxisCount;

  const BadgeGrid({
    super.key,
    required this.userBadges,
    this.showLocked = true,
    this.crossAxisCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    final allBadgeTypes = showLocked
        ? BadgeType.values
        : userBadges.badges.map((b) => b.type).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: allBadgeTypes.length,
      itemBuilder: (context, index) {
        final type = allBadgeTypes[index];
        final info = BadgeDefinitions.get(type);
        final isEarned = userBadges.hasBadge(type);

        if (info == null) return const SizedBox();

        return GestureDetector(
          onTap: () => _showBadgeDetail(context, info, isEarned),
          child: BadgeIcon(
            badge: info,
            size: 56,
            showName: true,
            isLocked: !isEarned,
          ),
        );
      },
    );
  }

  void _showBadgeDetail(BuildContext context, BadgeInfo badge, bool isEarned) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BadgeIcon(
              badge: badge,
              size: 80,
              isLocked: !isEarned,
            ),
            const SizedBox(height: 16),
            Text(
              badge.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _parseColor(badge.rarity.colorHex).withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge.rarity.label,
                style: TextStyle(
                  fontSize: 12,
                  color: _parseColor(badge.rarity.colorHex),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              badge.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (!isEarned) ...[
              const SizedBox(height: 12),
              Text(
                '아직 획득하지 않았습니다',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    return Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
  }
}

/// 배지 요약 위젯 (프로필용)
class BadgeSummary extends StatelessWidget {
  final UserBadges userBadges;
  final int maxDisplay;

  const BadgeSummary({
    super.key,
    required this.userBadges,
    this.maxDisplay = 5,
  });

  @override
  Widget build(BuildContext context) {
    final recentBadges = userBadges.badges.take(maxDisplay).toList();
    final remaining = userBadges.badges.length - maxDisplay;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...recentBadges.map((badge) {
          final info = badge.info;
          if (info == null) return const SizedBox();
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _parseColor(info.rarity.colorHex).withAlpha(30),
              ),
              child: Center(
                child: Text(info.emoji, style: const TextStyle(fontSize: 16)),
              ),
            ),
          );
        }),
        if (remaining > 0)
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
            ),
            child: Center(
              child: Text(
                '+$remaining',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Color _parseColor(String hex) {
    return Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
  }
}

/// 새 배지 획득 알림 위젯
class NewBadgeDialog extends StatelessWidget {
  final List<BadgeType> newBadges;

  const NewBadgeDialog({
    super.key,
    required this.newBadges,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '🎉',
            style: TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 8),
          const Text(
            '새 배지 획득!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          ...newBadges.map((type) {
            final info = BadgeDefinitions.get(type);
            if (info == null) return const SizedBox();
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  BadgeIcon(badge: info, size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          info.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          info.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('확인'),
        ),
      ],
    );
  }
}
