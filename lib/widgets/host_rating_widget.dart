import 'package:flutter/material.dart';
import '../models/host_rating_model.dart';

/// 호스트 평점 표시 위젯 (간단)
class HostRatingBadge extends StatelessWidget {
  final HostRatingSummary rating;
  final double size;

  const HostRatingBadge({
    super.key,
    required this.rating,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    final tier = rating.tier;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _parseColor(tier.colorHex).withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tier.emoji, style: TextStyle(fontSize: size)),
          const SizedBox(width: 4),
          if (rating.totalReviews >= 3) ...[
            Icon(
              Icons.star,
              size: size,
              color: Colors.amber,
            ),
            const SizedBox(width: 2),
            Text(
              rating.overallRating.toStringAsFixed(1),
              style: TextStyle(
                fontSize: size - 2,
                fontWeight: FontWeight.bold,
                color: _parseColor(tier.colorHex),
              ),
            ),
          ] else ...[
            Text(
              tier.label,
              style: TextStyle(
                fontSize: size - 2,
                fontWeight: FontWeight.w500,
                color: _parseColor(tier.colorHex),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    return Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
  }
}

/// 호스트 평점 카드 (상세)
class HostRatingCard extends StatelessWidget {
  final HostRatingSummary rating;
  final VoidCallback? onViewReviews;

  const HostRatingCard({
    super.key,
    required this.rating,
    this.onViewReviews,
  });

  @override
  Widget build(BuildContext context) {
    final tier = rating.tier;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _parseColor(tier.colorHex).withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(tier.emoji, style: const TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tier.label,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _parseColor(tier.colorHex),
                        ),
                      ),
                      if (rating.totalReviews >= 3)
                        Row(
                          children: [
                            ...List.generate(5, (index) {
                              final filled = index < rating.overallRating.round();
                              return Icon(
                                filled ? Icons.star : Icons.star_border,
                                size: 16,
                                color: Colors.amber,
                              );
                            }),
                            const SizedBox(width: 4),
                            Text(
                              '${rating.overallRating.toStringAsFixed(1)} (${rating.totalReviews})',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          '리뷰 ${rating.totalReviews}개',
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
            if (rating.categoryRatings.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              ...rating.categoryRatings.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildCategoryRating(entry.key, entry.value),
                );
              }),
            ],
            if (onViewReviews != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: onViewReviews,
                  child: const Text('리뷰 보기'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRating(RatingCategory category, double value) {
    return Row(
      children: [
        Text(category.emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            category.label,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        SizedBox(
          width: 100,
          child: LinearProgressIndicator(
            value: value / 5,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              value >= 4
                  ? Colors.green
                  : value >= 3
                      ? Colors.orange
                      : Colors.red,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Color _parseColor(String hex) {
    return Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
  }
}

/// 호스트 평가 입력 다이얼로그
class HostReviewDialog extends StatefulWidget {
  final String hostNickname;
  final void Function(Map<RatingCategory, int> ratings, String? comment) onSubmit;

  const HostReviewDialog({
    super.key,
    required this.hostNickname,
    required this.onSubmit,
  });

  @override
  State<HostReviewDialog> createState() => _HostReviewDialogState();
}

class _HostReviewDialogState extends State<HostReviewDialog> {
  final Map<RatingCategory, int> _ratings = {};
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    for (final category in RatingCategory.values) {
      _ratings[category] = 3; // 기본값
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        '${widget.hostNickname}님 평가',
        textAlign: TextAlign.center,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...RatingCategory.values.map((category) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(category.emoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            category.description,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _ratings[category] = starValue;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              starValue <= (_ratings[category] ?? 0)
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 32,
                              color: Colors.amber,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: '한줄 평가 (선택)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLength: 100,
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSubmit(
              _ratings,
              _commentController.text.isEmpty ? null : _commentController.text,
            );
            Navigator.pop(context);
          },
          child: const Text('평가하기'),
        ),
      ],
    );
  }
}
