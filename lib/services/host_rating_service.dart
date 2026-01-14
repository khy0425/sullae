import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/host_rating_model.dart';

/// 호스트 평점 서비스
class HostRatingService {
  static final HostRatingService _instance = HostRatingService._internal();
  factory HostRatingService() => _instance;
  HostRatingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _reviewsRef => _firestore.collection('host_reviews');
  CollectionReference get _summaryRef => _firestore.collection('host_ratings');

  /// 리뷰 작성
  Future<bool> submitReview({
    required String meetingId,
    required String hostId,
    required String reviewerId,
    required String reviewerNickname,
    required Map<RatingCategory, int> ratings,
    String? comment,
  }) async {
    try {
      // 이미 리뷰 작성했는지 확인
      final existing = await _reviewsRef
          .where('meetingId', isEqualTo: meetingId)
          .where('reviewerId', isEqualTo: reviewerId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        if (kDebugMode) print('Already reviewed this meeting');
        return false;
      }

      // 리뷰 저장
      final review = HostReview(
        id: '',
        meetingId: meetingId,
        hostId: hostId,
        reviewerId: reviewerId,
        reviewerNickname: reviewerNickname,
        ratings: ratings,
        comment: comment,
        createdAt: DateTime.now(),
      );

      await _reviewsRef.add(review.toFirestore());

      // 요약 업데이트
      await _updateRatingSummary(hostId);

      if (kDebugMode) print('Review submitted for host: $hostId');
      return true;
    } catch (e) {
      if (kDebugMode) print('Error submitting review: $e');
      return false;
    }
  }

  /// 평점 요약 업데이트
  Future<void> _updateRatingSummary(String hostId) async {
    // 모든 리뷰 가져오기
    final reviewsSnapshot = await _reviewsRef
        .where('hostId', isEqualTo: hostId)
        .get();

    if (reviewsSnapshot.docs.isEmpty) return;

    final reviews = reviewsSnapshot.docs
        .map((doc) => HostReview.fromFirestore(doc))
        .toList();

    // 카테고리별 평균 계산
    final categoryTotals = <RatingCategory, List<int>>{};
    for (final category in RatingCategory.values) {
      categoryTotals[category] = [];
    }

    for (final review in reviews) {
      for (final entry in review.ratings.entries) {
        categoryTotals[entry.key]!.add(entry.value);
      }
    }

    final categoryRatings = <RatingCategory, double>{};
    for (final entry in categoryTotals.entries) {
      if (entry.value.isNotEmpty) {
        final sum = entry.value.fold<int>(0, (sum, v) => sum + v);
        categoryRatings[entry.key] = sum / entry.value.length;
      }
    }

    // 전체 평균 계산
    final allRatings = reviews.map((r) => r.averageRating).toList();
    final overallRating = allRatings.fold<double>(0, (sum, r) => sum + r) / allRatings.length;

    // 요약 저장
    final summary = HostRatingSummary(
      hostId: hostId,
      totalReviews: reviews.length,
      overallRating: overallRating,
      categoryRatings: categoryRatings,
      lastReviewAt: reviews.map((r) => r.createdAt).reduce((a, b) => a.isAfter(b) ? a : b),
    );

    await _summaryRef.doc(hostId).set(summary.toFirestore());
  }

  /// 호스트 평점 요약 조회
  Future<HostRatingSummary> getHostRatingSummary(String hostId) async {
    final doc = await _summaryRef.doc(hostId).get();
    if (!doc.exists) return HostRatingSummary.empty(hostId);
    return HostRatingSummary.fromFirestore(doc);
  }

  /// 호스트 평점 요약 스트림
  Stream<HostRatingSummary> getHostRatingSummaryStream(String hostId) {
    return _summaryRef.doc(hostId).snapshots().map((doc) {
      if (!doc.exists) return HostRatingSummary.empty(hostId);
      return HostRatingSummary.fromFirestore(doc);
    });
  }

  /// 호스트 리뷰 목록 조회
  Future<List<HostReview>> getHostReviews(String hostId, {int limit = 10}) async {
    final snapshot = await _reviewsRef
        .where('hostId', isEqualTo: hostId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => HostReview.fromFirestore(doc)).toList();
  }

  /// 특정 모임에 대한 리뷰 작성 여부 확인
  Future<bool> hasReviewedMeeting(String meetingId, String reviewerId) async {
    final snapshot = await _reviewsRef
        .where('meetingId', isEqualTo: meetingId)
        .where('reviewerId', isEqualTo: reviewerId)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  /// 리뷰 작성 가능 여부 확인 (모임 종료 후 24시간 이내)
  bool canReview(DateTime meetingEndTime) {
    final now = DateTime.now();
    final deadline = meetingEndTime.add(const Duration(hours: 24));
    return now.isBefore(deadline);
  }
}
