import 'package:cloud_firestore/cloud_firestore.dart';

/// 호스트 평가 항목
enum RatingCategory {
  punctuality,    // 시간 약속
  organization,   // 진행 능력
  friendliness,   // 친절도
  fairness,       // 공정성
}

extension RatingCategoryExtension on RatingCategory {
  String get label {
    switch (this) {
      case RatingCategory.punctuality:
        return '시간 약속';
      case RatingCategory.organization:
        return '진행 능력';
      case RatingCategory.friendliness:
        return '친절도';
      case RatingCategory.fairness:
        return '공정성';
    }
  }

  String get emoji {
    switch (this) {
      case RatingCategory.punctuality:
        return '⏰';
      case RatingCategory.organization:
        return '📋';
      case RatingCategory.friendliness:
        return '😊';
      case RatingCategory.fairness:
        return '⚖️';
    }
  }

  String get description {
    switch (this) {
      case RatingCategory.punctuality:
        return '시간을 잘 지켰나요?';
      case RatingCategory.organization:
        return '게임 진행이 매끄러웠나요?';
      case RatingCategory.friendliness:
        return '친절하게 대해주었나요?';
      case RatingCategory.fairness:
        return '공정하게 진행했나요?';
    }
  }
}

/// 개별 평가
class HostReview {
  final String id;
  final String meetingId;
  final String hostId;
  final String reviewerId;
  final String reviewerNickname;
  final Map<RatingCategory, int> ratings;  // 각 항목별 1-5점
  final String? comment;
  final DateTime createdAt;

  HostReview({
    required this.id,
    required this.meetingId,
    required this.hostId,
    required this.reviewerId,
    required this.reviewerNickname,
    required this.ratings,
    this.comment,
    required this.createdAt,
  });

  factory HostReview.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final ratingsMap = <RatingCategory, int>{};

    final ratingsData = data['ratings'] as Map<String, dynamic>?;
    if (ratingsData != null) {
      for (final category in RatingCategory.values) {
        ratingsMap[category] = ratingsData[category.name] ?? 3;
      }
    }

    return HostReview(
      id: doc.id,
      meetingId: data['meetingId'] ?? '',
      hostId: data['hostId'] ?? '',
      reviewerId: data['reviewerId'] ?? '',
      reviewerNickname: data['reviewerNickname'] ?? '',
      ratings: ratingsMap,
      comment: data['comment'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    final ratingsData = <String, int>{};
    for (final entry in ratings.entries) {
      ratingsData[entry.key.name] = entry.value;
    }

    return {
      'meetingId': meetingId,
      'hostId': hostId,
      'reviewerId': reviewerId,
      'reviewerNickname': reviewerNickname,
      'ratings': ratingsData,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// 평균 점수
  double get averageRating {
    if (ratings.isEmpty) return 0;
    final sum = ratings.values.fold<int>(0, (sum, rating) => sum + rating);
    return sum / ratings.length;
  }
}

/// 호스트 평점 요약
class HostRatingSummary {
  final String hostId;
  final int totalReviews;
  final double overallRating;
  final Map<RatingCategory, double> categoryRatings;
  final DateTime? lastReviewAt;

  HostRatingSummary({
    required this.hostId,
    required this.totalReviews,
    required this.overallRating,
    required this.categoryRatings,
    this.lastReviewAt,
  });

  factory HostRatingSummary.empty(String hostId) {
    return HostRatingSummary(
      hostId: hostId,
      totalReviews: 0,
      overallRating: 0,
      categoryRatings: {},
    );
  }

  factory HostRatingSummary.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return HostRatingSummary.empty(doc.id);

    final categoryRatings = <RatingCategory, double>{};
    final categoryData = data['categoryRatings'] as Map<String, dynamic>?;
    if (categoryData != null) {
      for (final category in RatingCategory.values) {
        categoryRatings[category] = (categoryData[category.name] ?? 0).toDouble();
      }
    }

    return HostRatingSummary(
      hostId: doc.id,
      totalReviews: data['totalReviews'] ?? 0,
      overallRating: (data['overallRating'] ?? 0).toDouble(),
      categoryRatings: categoryRatings,
      lastReviewAt: (data['lastReviewAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    final categoryData = <String, double>{};
    for (final entry in categoryRatings.entries) {
      categoryData[entry.key.name] = entry.value;
    }

    return {
      'totalReviews': totalReviews,
      'overallRating': overallRating,
      'categoryRatings': categoryData,
      'lastReviewAt': lastReviewAt != null ? Timestamp.fromDate(lastReviewAt!) : null,
    };
  }

  /// 호스트 등급
  HostTier get tier {
    if (totalReviews < 3) return HostTier.newHost;
    if (overallRating >= 4.5) return HostTier.legendary;
    if (overallRating >= 4.0) return HostTier.excellent;
    if (overallRating >= 3.5) return HostTier.good;
    if (overallRating >= 3.0) return HostTier.average;
    return HostTier.beginner;
  }
}

/// 호스트 등급
enum HostTier {
  newHost,    // 신규 (리뷰 3개 미만)
  beginner,   // 초보
  average,    // 보통
  good,       // 좋음
  excellent,  // 우수
  legendary,  // 레전드
}

extension HostTierExtension on HostTier {
  String get label {
    switch (this) {
      case HostTier.newHost:
        return '신규';
      case HostTier.beginner:
        return '초보';
      case HostTier.average:
        return '보통';
      case HostTier.good:
        return '좋음';
      case HostTier.excellent:
        return '우수';
      case HostTier.legendary:
        return '레전드';
    }
  }

  String get emoji {
    switch (this) {
      case HostTier.newHost:
        return '🌱';
      case HostTier.beginner:
        return '🌿';
      case HostTier.average:
        return '🌳';
      case HostTier.good:
        return '⭐';
      case HostTier.excellent:
        return '🌟';
      case HostTier.legendary:
        return '👑';
    }
  }

  String get colorHex {
    switch (this) {
      case HostTier.newHost:
        return '#9E9E9E';
      case HostTier.beginner:
        return '#8BC34A';
      case HostTier.average:
        return '#4CAF50';
      case HostTier.good:
        return '#2196F3';
      case HostTier.excellent:
        return '#9C27B0';
      case HostTier.legendary:
        return '#FF9800';
    }
  }
}
