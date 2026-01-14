import 'package:cloud_firestore/cloud_firestore.dart';

enum GameType {
  copsAndRobbers, // 경찰과 도둑
  freezeTag,      // 얼음땡
  hideAndSeek,    // 숨바꼭질
  captureFlag,    // 깃발뺏기
  custom,         // 커스텀
}

enum MeetingStatus {
  recruiting,  // 모집중
  full,        // 모집완료
  inProgress,  // 진행중
  finished,    // 종료
  cancelled,   // 취소됨
}

/// 모집 인원 규모
enum GroupSize {
  small,   // 소규모 (4-8명)
  medium,  // 중규모 (9-15명)
  large,   // 대규모 (16명+)
}

/// 난이도/분위기
enum Difficulty {
  casual,      // 가볍게
  competitive, // 진지하게
  beginner,    // 초보 환영
}

/// 광역시/도
enum Province {
  all,          // 전체
  seoul,        // 서울
  gyeonggi,     // 경기
  incheon,      // 인천
  busan,        // 부산
  daegu,        // 대구
  daejeon,      // 대전
  gwangju,      // 광주
  ulsan,        // 울산
  sejong,       // 세종
  gangwon,      // 강원
  chungbuk,     // 충북
  chungnam,     // 충남
  jeonbuk,      // 전북
  jeonnam,      // 전남
  gyeongbuk,    // 경북
  gyeongnam,    // 경남
  jeju,         // 제주
}

/// 서울 세부 지역
enum SeoulDistrict {
  all,          // 전체
  gangnam,      // 강남구
  gangdong,     // 강동구
  gangbuk,      // 강북구
  gangseo,      // 강서구
  gwanak,       // 관악구
  gwangjin,     // 광진구
  guro,         // 구로구
  geumcheon,    // 금천구
  nowon,        // 노원구
  dobong,       // 도봉구
  dongdaemun,   // 동대문구
  dongjak,      // 동작구
  mapo,         // 마포구
  seodaemun,    // 서대문구
  seocho,       // 서초구
  seongdong,    // 성동구
  seongbuk,     // 성북구
  songpa,       // 송파구
  yangcheon,    // 양천구
  yeongdeungpo, // 영등포구
  yongsan,      // 용산구
  eunpyeong,    // 은평구
  jongno,       // 종로구
  jung,         // 중구
  jungnang,     // 중랑구
}

/// 경기 세부 지역
enum GyeonggiDistrict {
  all,          // 전체
  suwon,        // 수원
  seongnam,     // 성남
  goyang,       // 고양
  yongin,       // 용인
  bucheon,      // 부천
  ansan,        // 안산
  anyang,       // 안양
  namyangju,    // 남양주
  hwaseong,     // 화성
  uijeongbu,    // 의정부
  siheung,      // 시흥
  gimpo,        // 김포
  gwangmyeong,  // 광명
  hanam,        // 하남
  gunpo,        // 군포
  icheon,       // 이천
  osan,         // 오산
  paju,         // 파주
  pyeongtaek,   // 평택
  other,        // 기타
}

/// 지역 (통합)
class Region {
  final Province province;
  final dynamic district; // SeoulDistrict, GyeonggiDistrict, or null

  const Region({
    required this.province,
    this.district,
  });

  static const all = Region(province: Province.all);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Region &&
        other.province == province &&
        other.district == district;
  }

  @override
  int get hashCode => province.hashCode ^ district.hashCode;

  String toStorageString() {
    if (district == null) {
      return province.name;
    }
    if (district is SeoulDistrict) {
      return 'seoul:${(district as SeoulDistrict).name}';
    }
    if (district is GyeonggiDistrict) {
      return 'gyeonggi:${(district as GyeonggiDistrict).name}';
    }
    return province.name;
  }

  static Region fromStorageString(String? str) {
    if (str == null || str.isEmpty) return Region.all;

    if (str.startsWith('seoul:')) {
      final districtName = str.substring(6);
      final district = SeoulDistrict.values.firstWhere(
        (d) => d.name == districtName,
        orElse: () => SeoulDistrict.all,
      );
      return Region(province: Province.seoul, district: district);
    }
    if (str.startsWith('gyeonggi:')) {
      final districtName = str.substring(9);
      final district = GyeonggiDistrict.values.firstWhere(
        (d) => d.name == districtName,
        orElse: () => GyeonggiDistrict.all,
      );
      return Region(province: Province.gyeonggi, district: district);
    }

    final province = Province.values.firstWhere(
      (p) => p.name == str,
      orElse: () => Province.all,
    );
    return Region(province: province);
  }
}

class MeetingModel {
  final String id;
  final String title;
  final String description;
  final String hostId;
  final String hostNickname;
  final GameType gameType;

  // 장소 정보
  final String location;           // 장소명 (예: "한강공원 여의도지구")
  final String? locationDetail;    // 상세 위치 (예: "2번 출구 앞 잔디밭")
  final double? latitude;          // 위도
  final double? longitude;         // 경도

  final DateTime meetingTime;
  final int maxParticipants;
  final int currentParticipants;
  final List<String> participantIds;
  final MeetingStatus status;
  final DateTime createdAt;
  final Map<String, dynamic>? gameSettings;

  // 빠른 참가 시스템
  final String joinCode;           // 6자리 참가 코드
  final String? joinLink;          // 딥링크 URL

  // 공지 기능
  final String? announcement;      // 호스트 공지사항
  final DateTime? announcementAt;  // 공지 시간

  // 필터용 필드
  final Region region;             // 지역
  final Difficulty difficulty;     // 난이도/분위기
  final List<String> targetAgeGroups;  // 희망 연령대 (복수 선택 가능, 빈 리스트 = 상관없음)

  // 외부 채팅 링크 (카카오톡 오픈채팅 등)
  final String? externalChatLink;  // 외부 채팅 URL

  MeetingModel({
    required this.id,
    required this.title,
    required this.description,
    required this.hostId,
    required this.hostNickname,
    required this.gameType,
    required this.location,
    this.locationDetail,
    this.latitude,
    this.longitude,
    required this.meetingTime,
    required this.maxParticipants,
    required this.currentParticipants,
    required this.participantIds,
    required this.status,
    required this.createdAt,
    this.gameSettings,
    required this.joinCode,
    this.joinLink,
    this.announcement,
    this.announcementAt,
    this.region = Region.all,
    this.difficulty = Difficulty.casual,
    this.targetAgeGroups = const [],
    this.externalChatLink,
  });

  factory MeetingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MeetingModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      hostId: data['hostId'] ?? '',
      hostNickname: data['hostNickname'] ?? '',
      gameType: GameType.values[data['gameType'] ?? 0],
      location: data['location'] ?? '',
      locationDetail: data['locationDetail'],
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      meetingTime: (data['meetingTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      maxParticipants: data['maxParticipants'] ?? 10,
      currentParticipants: data['currentParticipants'] ?? 1,
      participantIds: List<String>.from(data['participantIds'] ?? []),
      status: MeetingStatus.values[data['status'] ?? 0],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      gameSettings: data['gameSettings'],
      joinCode: data['joinCode'] ?? '',
      joinLink: data['joinLink'],
      announcement: data['announcement'],
      announcementAt: (data['announcementAt'] as Timestamp?)?.toDate(),
      region: Region.fromStorageString(data['region']),
      difficulty: Difficulty.values[data['difficulty'] ?? 0],
      targetAgeGroups: List<String>.from(data['targetAgeGroups'] ?? []),
      externalChatLink: data['externalChatLink'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'hostId': hostId,
      'hostNickname': hostNickname,
      'gameType': gameType.index,
      'location': location,
      'locationDetail': locationDetail,
      'latitude': latitude,
      'longitude': longitude,
      'meetingTime': Timestamp.fromDate(meetingTime),
      'maxParticipants': maxParticipants,
      'currentParticipants': currentParticipants,
      'participantIds': participantIds,
      'status': status.index,
      'createdAt': Timestamp.fromDate(createdAt),
      'gameSettings': gameSettings,
      'joinCode': joinCode,
      'joinLink': joinLink,
      'announcement': announcement,
      'announcementAt': announcementAt != null ? Timestamp.fromDate(announcementAt!) : null,
      'region': region.toStorageString(),
      'difficulty': difficulty.index,
      'targetAgeGroups': targetAgeGroups,
      'externalChatLink': externalChatLink,
    };
  }

  /// 인원 규모 계산
  GroupSize get groupSize {
    if (maxParticipants <= 8) return GroupSize.small;
    if (maxParticipants <= 15) return GroupSize.medium;
    return GroupSize.large;
  }

  String get gameTypeName {
    switch (gameType) {
      case GameType.copsAndRobbers:
        return '경찰과 도둑';
      case GameType.freezeTag:
        return '얼음땡';
      case GameType.hideAndSeek:
        return '숨바꼭질';
      case GameType.captureFlag:
        return '깃발뺏기';
      case GameType.custom:
        return '커스텀';
    }
  }

  String get statusName {
    switch (status) {
      case MeetingStatus.recruiting:
        return '모집중';
      case MeetingStatus.full:
        return '모집완료';
      case MeetingStatus.inProgress:
        return '진행중';
      case MeetingStatus.finished:
        return '종료';
      case MeetingStatus.cancelled:
        return '취소됨';
    }
  }

  bool get isJoinable => status == MeetingStatus.recruiting && currentParticipants < maxParticipants;

  /// 위치 좌표가 있는지 확인
  bool get hasCoordinates => latitude != null && longitude != null;

  MeetingModel copyWith({
    String? title,
    String? description,
    GameType? gameType,
    String? location,
    String? locationDetail,
    double? latitude,
    double? longitude,
    DateTime? meetingTime,
    int? maxParticipants,
    int? currentParticipants,
    List<String>? participantIds,
    MeetingStatus? status,
    Map<String, dynamic>? gameSettings,
    String? joinCode,
    String? joinLink,
    String? announcement,
    DateTime? announcementAt,
    Region? region,
    Difficulty? difficulty,
    List<String>? targetAgeGroups,
    String? externalChatLink,
  }) {
    return MeetingModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      hostId: hostId,
      hostNickname: hostNickname,
      gameType: gameType ?? this.gameType,
      location: location ?? this.location,
      locationDetail: locationDetail ?? this.locationDetail,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      meetingTime: meetingTime ?? this.meetingTime,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      participantIds: participantIds ?? this.participantIds,
      status: status ?? this.status,
      createdAt: createdAt,
      gameSettings: gameSettings ?? this.gameSettings,
      joinCode: joinCode ?? this.joinCode,
      joinLink: joinLink ?? this.joinLink,
      announcement: announcement ?? this.announcement,
      announcementAt: announcementAt ?? this.announcementAt,
      region: region ?? this.region,
      difficulty: difficulty ?? this.difficulty,
      targetAgeGroups: targetAgeGroups ?? this.targetAgeGroups,
      externalChatLink: externalChatLink ?? this.externalChatLink,
    );
  }

  /// 6자리 참가 코드 생성
  static String generateJoinCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // 혼동 문자 제외 (0,O,1,I)
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(6, (i) => chars[(random + i * 7) % chars.length]).join();
  }
}
