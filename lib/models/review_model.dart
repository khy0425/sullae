import 'package:cloud_firestore/cloud_firestore.dart';

/// 게임 후기 모델
///
/// 2단계 수집 시스템:
/// 1. 게임 직후 (30초 후기) - 감정 캡처
/// 2. 다음 날 푸시 (상세 후기) - 데이터 수집
class GameReview {
  final String id;
  final String meetingId;
  final String odId;
  final String nickname;

  // 1단계: 즉시 후기 (게임 종료 직후)
  final OverallFeeling feeling;         // 전체 느낌
  final String? quickNote;              // 한 줄 메모 (선택)
  final DateTime? quickReviewAt;        // 즉시 후기 작성 시간

  // 2단계: 상세 후기 (다음 날)
  final IntensityFeedback? intensityFeedback;   // 체력 난이도 피드백
  final AgeGroupFeedback? ageGroupFeedback;     // 연령대 분위기 피드백
  final WillReturnFeedback? willReturn;         // 재참가 의향
  final String? detailedNote;                   // 자유 한마디 (선택)
  final DateTime? detailedReviewAt;             // 상세 후기 작성 시간

  final DateTime createdAt;

  GameReview({
    required this.id,
    required this.meetingId,
    required this.odId,
    required this.nickname,
    required this.feeling,
    this.quickNote,
    this.quickReviewAt,
    this.intensityFeedback,
    this.ageGroupFeedback,
    this.willReturn,
    this.detailedNote,
    this.detailedReviewAt,
    required this.createdAt,
  });

  factory GameReview.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GameReview(
      id: doc.id,
      meetingId: data['meetingId'] ?? '',
      odId: data['odId'] ?? '',
      nickname: data['nickname'] ?? '',
      feeling: OverallFeeling.values[data['feeling'] ?? 0],
      quickNote: data['quickNote'],
      quickReviewAt: (data['quickReviewAt'] as Timestamp?)?.toDate(),
      intensityFeedback: data['intensityFeedback'] != null
          ? IntensityFeedback.values[data['intensityFeedback']]
          : null,
      ageGroupFeedback: data['ageGroupFeedback'] != null
          ? AgeGroupFeedback.values[data['ageGroupFeedback']]
          : null,
      willReturn: data['willReturn'] != null
          ? WillReturnFeedback.values[data['willReturn']]
          : null,
      detailedNote: data['detailedNote'],
      detailedReviewAt: (data['detailedReviewAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'meetingId': meetingId,
      'odId': odId,
      'nickname': nickname,
      'feeling': feeling.index,
      'quickNote': quickNote,
      'quickReviewAt':
          quickReviewAt != null ? Timestamp.fromDate(quickReviewAt!) : null,
      'intensityFeedback': intensityFeedback?.index,
      'ageGroupFeedback': ageGroupFeedback?.index,
      'willReturn': willReturn?.index,
      'detailedNote': detailedNote,
      'detailedReviewAt':
          detailedReviewAt != null ? Timestamp.fromDate(detailedReviewAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// 상세 후기 작성 완료 여부
  bool get hasDetailedReview => detailedReviewAt != null;

  /// 긍정적 후기 여부
  bool get isPositive =>
      feeling == OverallFeeling.amazing || feeling == OverallFeeling.good;

  /// 재참가 의향 있음
  bool get willReturnYes => willReturn == WillReturnFeedback.definitely;

  GameReview copyWith({
    OverallFeeling? feeling,
    String? quickNote,
    DateTime? quickReviewAt,
    IntensityFeedback? intensityFeedback,
    AgeGroupFeedback? ageGroupFeedback,
    WillReturnFeedback? willReturn,
    String? detailedNote,
    DateTime? detailedReviewAt,
  }) {
    return GameReview(
      id: id,
      meetingId: meetingId,
      odId: odId,
      nickname: nickname,
      feeling: feeling ?? this.feeling,
      quickNote: quickNote ?? this.quickNote,
      quickReviewAt: quickReviewAt ?? this.quickReviewAt,
      intensityFeedback: intensityFeedback ?? this.intensityFeedback,
      ageGroupFeedback: ageGroupFeedback ?? this.ageGroupFeedback,
      willReturn: willReturn ?? this.willReturn,
      detailedNote: detailedNote ?? this.detailedNote,
      detailedReviewAt: detailedReviewAt ?? this.detailedReviewAt,
      createdAt: createdAt,
    );
  }
}

/// 전체 느낌 (1단계)
enum OverallFeeling {
  amazing,  // 😆 완전 재밌었어!
  good,     // 🙂 괜찮았어
  meh,      // 😐 별로였어
  tired,    // 😓 힘들었어
}

extension OverallFeelingExtension on OverallFeeling {
  String get emoji {
    switch (this) {
      case OverallFeeling.amazing:
        return '😆';
      case OverallFeeling.good:
        return '🙂';
      case OverallFeeling.meh:
        return '😐';
      case OverallFeeling.tired:
        return '😓';
    }
  }

  String get label {
    switch (this) {
      case OverallFeeling.amazing:
        return '완전 재밌었어!';
      case OverallFeeling.good:
        return '괜찮았어';
      case OverallFeeling.meh:
        return '별로였어';
      case OverallFeeling.tired:
        return '힘들었어';
    }
  }
}

/// 체력 난이도 피드백 (2단계)
enum IntensityFeedback {
  easy,     // 😌 쉬웠음
  moderate, // 🙂 적당
  hard,     // 🔥 힘들었음
}

extension IntensityFeedbackExtension on IntensityFeedback {
  String get emoji {
    switch (this) {
      case IntensityFeedback.easy:
        return '😌';
      case IntensityFeedback.moderate:
        return '🙂';
      case IntensityFeedback.hard:
        return '🔥';
    }
  }

  String get label {
    switch (this) {
      case IntensityFeedback.easy:
        return '쉬웠음';
      case IntensityFeedback.moderate:
        return '적당';
      case IntensityFeedback.hard:
        return '힘들었음';
    }
  }
}

/// 연령대 분위기 피드백 (2단계)
enum AgeGroupFeedback {
  younger,  // 👶 어린 편
  diverse,  // 👥 다양함
  similar,  // 🧓 비슷한 나이
}

extension AgeGroupFeedbackExtension on AgeGroupFeedback {
  String get emoji {
    switch (this) {
      case AgeGroupFeedback.younger:
        return '👶';
      case AgeGroupFeedback.diverse:
        return '👥';
      case AgeGroupFeedback.similar:
        return '🧑';
    }
  }

  String get label {
    switch (this) {
      case AgeGroupFeedback.younger:
        return '어린 편';
      case AgeGroupFeedback.diverse:
        return '다양함';
      case AgeGroupFeedback.similar:
        return '비슷한 나이';
    }
  }
}

/// 재참가 의향 (2단계)
enum WillReturnFeedback {
  definitely, // ✅ 당연 가야지
  maybe,      // 🤔 고민됨
  no,         // ❌ 안 갈 듯
}

extension WillReturnFeedbackExtension on WillReturnFeedback {
  String get emoji {
    switch (this) {
      case WillReturnFeedback.definitely:
        return '✅';
      case WillReturnFeedback.maybe:
        return '🤔';
      case WillReturnFeedback.no:
        return '❌';
    }
  }

  String get label {
    switch (this) {
      case WillReturnFeedback.definitely:
        return '당연 가야지';
      case WillReturnFeedback.maybe:
        return '고민됨';
      case WillReturnFeedback.no:
        return '안 갈 듯';
    }
  }
}

/// 후기 요청 상태
enum ReviewRequestStatus {
  pending,    // 아직 요청 안 함
  quick,      // 즉시 후기 요청됨
  detailed,   // 상세 후기 요청됨
  completed,  // 완료
}
