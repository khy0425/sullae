import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../utils/input_sanitizer.dart';

/// 모임 후기 서비스 (축소 버전)
/// - 모임 완료 후 간단 후기만
/// - 이미지 없음 (비용 절감)
/// - 댓글 없음 (비용 절감)
class ReviewService {
  static final ReviewService _instance = ReviewService._internal();
  factory ReviewService() => _instance;
  ReviewService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 후기 작성 (모임 완료 후 1회만)
  Future<bool> createReview({
    required String meetingId,
    required String odId,
    required String authorName,
    required String gameType,
    required int rating, // 1-5
    required String content,
  }) async {
    try {
      // 이미 작성했는지 확인
      final existing = await _firestore
          .collection('reviews')
          .where('meetingId', isEqualTo: meetingId)
          .where('authorId', isEqualTo: odId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        if (kDebugMode) print('Already reviewed this meeting');
        return false;
      }

      // 입력값 보안 처리
      final sanitizedName = InputSanitizer.sanitizeName(authorName);
      final sanitizedContent = InputSanitizer.sanitizeAll(content);

      await _firestore.collection('reviews').add({
        'meetingId': meetingId,
        'authorId': odId,
        'authorName': sanitizedName,
        'gameType': gameType,
        'rating': rating.clamp(1, 5), // 평점 범위 제한
        'content': sanitizedContent,
        'likeCount': 0,
        'createdAt': Timestamp.now(),
      });

      if (kDebugMode) print('Review created');
      return true;
    } catch (e) {
      if (kDebugMode) print('Error creating review: $e');
      return false;
    }
  }

  /// 최근 후기 목록 (캐싱 활용을 위해 단순 쿼리)
  Future<List<MeetingReview>> getRecentReviews({int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => MeetingReview.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error getting reviews: $e');
      return [];
    }
  }

  /// 게임별 후기
  Future<List<MeetingReview>> getReviewsByGame(String gameType, {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('gameType', isEqualTo: gameType)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => MeetingReview.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error getting reviews by game: $e');
      return [];
    }
  }

  /// 내 후기 목록
  Future<List<MeetingReview>> getMyReviews(String odId, {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('authorId', isEqualTo: odId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => MeetingReview.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error getting my reviews: $e');
      return [];
    }
  }

  /// 좋아요 토글
  Future<bool> toggleLike(String reviewId, String odId) async {
    try {
      final likeRef = _firestore
          .collection('reviews')
          .doc(reviewId)
          .collection('likes')
          .doc(odId);

      final likeDoc = await likeRef.get();

      if (likeDoc.exists) {
        await likeRef.delete();
        await _firestore.collection('reviews').doc(reviewId).update({
          'likeCount': FieldValue.increment(-1),
        });
        return false;
      } else {
        await likeRef.set({'createdAt': Timestamp.now()});
        await _firestore.collection('reviews').doc(reviewId).update({
          'likeCount': FieldValue.increment(1),
        });
        return true;
      }
    } catch (e) {
      if (kDebugMode) print('Error toggling like: $e');
      return false;
    }
  }

  /// 좋아요 여부 확인
  Future<bool> isLiked(String reviewId, String odId) async {
    try {
      final doc = await _firestore
          .collection('reviews')
          .doc(reviewId)
          .collection('likes')
          .doc(odId)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// 후기 작성 가능 여부 (모임 완료 후에만)
  Future<bool> canWriteReview(String meetingId, String odId) async {
    try {
      // 모임이 완료되었는지 확인
      final meetingDoc = await _firestore.collection('meetings').doc(meetingId).get();
      if (!meetingDoc.exists) return false;

      final status = meetingDoc.data()?['status'];
      if (status != 'completed') return false;

      // 참여자인지 확인
      final participants = List<String>.from(meetingDoc.data()?['participantIds'] ?? []);
      if (!participants.contains(odId)) return false;

      // 이미 작성했는지 확인
      final existing = await _firestore
          .collection('reviews')
          .where('meetingId', isEqualTo: meetingId)
          .where('authorId', isEqualTo: odId)
          .limit(1)
          .get();

      return existing.docs.isEmpty;
    } catch (e) {
      return false;
    }
  }

  /// 게임별 평균 평점
  Future<double> getAverageRating(String gameType) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('gameType', isEqualTo: gameType)
          .limit(100)
          .get();

      if (snapshot.docs.isEmpty) return 0;

      final total = snapshot.docs.fold<int>(
        0,
        (sum, doc) => sum + (doc.data()['rating'] as int? ?? 0),
      );

      return total / snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }
}

/// 모임 후기
class MeetingReview {
  final String id;
  final String meetingId;
  final String authorId;
  final String authorName;
  final String gameType;
  final int rating;
  final String content;
  final int likeCount;
  final DateTime createdAt;

  MeetingReview({
    required this.id,
    required this.meetingId,
    required this.authorId,
    required this.authorName,
    required this.gameType,
    required this.rating,
    required this.content,
    required this.likeCount,
    required this.createdAt,
  });

  factory MeetingReview.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MeetingReview(
      id: doc.id,
      meetingId: data['meetingId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '익명',
      gameType: data['gameType'] ?? '',
      rating: data['rating'] ?? 0,
      content: data['content'] ?? '',
      likeCount: data['likeCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  String get gameTypeName {
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

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${createdAt.month}/${createdAt.day}';
  }
}
