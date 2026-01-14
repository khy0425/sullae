import 'package:flutter/material.dart';
import '../../services/review_service.dart';

/// 모임 후기 화면 (간소화 버전)
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final ReviewService _reviewService = ReviewService();
  List<MeetingReview> _reviews = [];
  bool _isLoading = true;
  String? _selectedGame;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);

    final reviews = _selectedGame != null
        ? await _reviewService.getReviewsByGame(_selectedGame!)
        : await _reviewService.getRecentReviews();

    if (mounted) {
      setState(() {
        _reviews = reviews;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('모임 후기'),
      ),
      body: Column(
        children: [
          // 게임 필터
          _buildGameFilter(),
          // 후기 목록
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _reviews.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadReviews,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: _reviews.length,
                          itemBuilder: (context, index) {
                            return ReviewCard(review: _reviews[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildFilterChip(null, '전체'),
          const SizedBox(width: 8),
          _buildFilterChip('policeAndThief', '경찰과 도둑'),
          const SizedBox(width: 8),
          _buildFilterChip('freeze', '얼음땡'),
          const SizedBox(width: 8),
          _buildFilterChip('hideAndSeek', '숨바꼭질'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String? gameType, String label) {
    final isSelected = _selectedGame == gameType;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedGame = gameType);
        _loadReviews();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF6B35) : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '아직 후기가 없어요',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            '모임에 참여하고 후기를 남겨보세요!',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

/// 후기 카드
class ReviewCard extends StatelessWidget {
  final MeetingReview review;

  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey[200],
                  child: Text(
                    review.authorName.isNotEmpty ? review.authorName[0] : '?',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.authorName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        review.timeAgo,
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getGameColor(review.gameType).withAlpha(30),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    review.gameTypeName,
                    style: TextStyle(
                      fontSize: 11,
                      color: _getGameColor(review.gameType),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 별점
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < review.rating ? Icons.star : Icons.star_border,
                  size: 18,
                  color: Colors.amber,
                );
              }),
            ),
            const SizedBox(height: 10),

            // 내용
            Text(
              review.content,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 12),

            // 좋아요
            Row(
              children: [
                Icon(Icons.favorite_border, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  '${review.likeCount}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
}

/// 후기 작성 다이얼로그
class WriteReviewDialog extends StatefulWidget {
  final String meetingId;
  final String gameType;
  final String odId;
  final String authorName;

  const WriteReviewDialog({
    super.key,
    required this.meetingId,
    required this.gameType,
    required this.odId,
    required this.authorName,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String meetingId,
    required String gameType,
    required String odId,
    required String authorName,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => WriteReviewDialog(
        meetingId: meetingId,
        gameType: gameType,
        odId: odId,
        authorName: authorName,
      ),
    );
  }

  @override
  State<WriteReviewDialog> createState() => _WriteReviewDialogState();
}

class _WriteReviewDialogState extends State<WriteReviewDialog> {
  final ReviewService _reviewService = ReviewService();
  final TextEditingController _contentController = TextEditingController();
  int _rating = 5;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('후기 내용을 입력해주세요')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await _reviewService.createReview(
      meetingId: widget.meetingId,
      odId: widget.odId,
      authorName: widget.authorName,
      gameType: widget.gameType,
      rating: _rating,
      content: _contentController.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('후기가 등록되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('이미 후기를 작성했습니다'),
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
      title: const Text('모임 후기'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('이 모임은 어떠셨나요?'),
            const SizedBox(height: 16),

            // 별점
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => setState(() => _rating = index + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      size: 36,
                      color: Colors.amber,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            // 내용
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                hintText: '후기를 작성해주세요 (최소 10자)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 4,
              maxLength: 200,
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
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B35),
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
              : const Text('등록'),
        ),
      ],
    );
  }
}
