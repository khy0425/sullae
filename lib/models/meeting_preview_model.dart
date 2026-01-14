import 'meeting_model.dart';

/// 모임 미리보기 카드
///
/// 참가 전 확인할 수 있는 정보
/// 기대와 현실의 갭을 줄이기 위한 요약 정보
class MeetingPreview {
  final String meetingId;
  final GameType gameType;
  final AgeGroup expectedAgeGroup;     // 예상 연령대
  final IntensityLevel intensity;       // 체력 강도
  final int currentParticipants;        // 현재 참가 인원
  final int maxParticipants;            // 목표 인원
  final int estimatedMinutes;           // 예상 시간 (분)
  final double? avgRating;              // 평균 평점 (이전 후기 기반)
  final int reviewCount;                // 후기 수

  MeetingPreview({
    required this.meetingId,
    required this.gameType,
    required this.expectedAgeGroup,
    required this.intensity,
    required this.currentParticipants,
    required this.maxParticipants,
    this.estimatedMinutes = 120,
    this.avgRating,
    this.reviewCount = 0,
  });

  Map<String, dynamic> toMap() => {
        'meetingId': meetingId,
        'gameType': gameType.index,
        'expectedAgeGroup': expectedAgeGroup.index,
        'intensity': intensity.index,
        'currentParticipants': currentParticipants,
        'maxParticipants': maxParticipants,
        'estimatedMinutes': estimatedMinutes,
        'avgRating': avgRating,
        'reviewCount': reviewCount,
      };

  factory MeetingPreview.fromMap(Map<String, dynamic> data) {
    return MeetingPreview(
      meetingId: data['meetingId'] ?? '',
      gameType: GameType.values[data['gameType'] ?? 0],
      expectedAgeGroup: AgeGroup.values[data['expectedAgeGroup'] ?? 0],
      intensity: IntensityLevel.values[data['intensity'] ?? 1],
      currentParticipants: data['currentParticipants'] ?? 0,
      maxParticipants: data['maxParticipants'] ?? 10,
      estimatedMinutes: data['estimatedMinutes'] ?? 120,
      avgRating: data['avgRating']?.toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
    );
  }

  /// 참가 인원 텍스트
  String get participantsText => '$currentParticipants / $maxParticipants명';

  /// 예상 시간 텍스트
  String get durationText {
    if (estimatedMinutes < 60) return '$estimatedMinutes분';
    final hours = estimatedMinutes ~/ 60;
    final mins = estimatedMinutes % 60;
    return mins > 0 ? '$hours시간 $mins분' : '$hours시간';
  }
}

/// 예상 연령대
enum AgeGroup {
  teens,      // 10대 다수
  twenties,   // 20대 다수
  thirties,   // 30대 다수
  mixed,      // 혼합
  unknown,    // 미정
}

extension AgeGroupExtension on AgeGroup {
  String get label {
    switch (this) {
      case AgeGroup.teens:
        return '10대 다수';
      case AgeGroup.twenties:
        return '20대 다수';
      case AgeGroup.thirties:
        return '30대 다수';
      case AgeGroup.mixed:
        return '다양한 연령대';
      case AgeGroup.unknown:
        return '연령대 미정';
    }
  }

  String get emoji {
    switch (this) {
      case AgeGroup.teens:
        return '🧒';
      case AgeGroup.twenties:
        return '👤';
      case AgeGroup.thirties:
        return '🧑';
      case AgeGroup.mixed:
        return '👥';
      case AgeGroup.unknown:
        return '❓';
    }
  }
}

/// 체력 강도
enum IntensityLevel {
  light,    // 😌 라이트 - 걷기 위주, 숨기 중심
  normal,   // 🙂 보통 - 적당히 뛰기
  intense,  // 🔥 빡셈 - 풀파워 추격전
}

extension IntensityLevelExtension on IntensityLevel {
  String get label {
    switch (this) {
      case IntensityLevel.light:
        return '라이트';
      case IntensityLevel.normal:
        return '보통';
      case IntensityLevel.intense:
        return '빡셈';
    }
  }

  String get emoji {
    switch (this) {
      case IntensityLevel.light:
        return '😌';
      case IntensityLevel.normal:
        return '🙂';
      case IntensityLevel.intense:
        return '🔥';
    }
  }

  String get description {
    switch (this) {
      case IntensityLevel.light:
        return '걷기 위주, 숨기 중심. 체력 걱정되는 분께 추천';
      case IntensityLevel.normal:
        return '적당히 뛰기. 일반 성인 기준';
      case IntensityLevel.intense:
        return '풀파워 추격전. 체력 자신 있는 분만';
    }
  }
}
