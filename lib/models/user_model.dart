import 'package:cloud_firestore/cloud_firestore.dart';

/// 술래 사용자 모델
///
/// 회원가입 철학:
/// - 30초 안에 완료
/// - 게임에 필요한 것만 (닉네임 필수)
/// - 나중에 추가 가능 (연령대, 프로필 등)
class UserModel {
  final String uid;
  final String nickname;              // 필수: 게임에서 불릴 이름 (2~10자)
  final String? email;                // 소셜 로그인에서 가져온 이메일
  final String? photoUrl;             // 프로필 이미지 (선택)
  final AgeRange? ageRange;           // 연령대 (선택)
  final LoginProvider loginProvider;  // 로그인 방식
  final int gamesPlayed;
  final int gamesHosted;              // 호스팅한 게임 수
  final int mvpCount;                 // MVP 받은 횟수
  final int volunteerCount;           // 먼저 지원한 횟수
  final DateTime createdAt;
  final DateTime lastActiveAt;

  // MVP Phase: roleStats 제거 - 핵심 지표만 유지
  // 역할별 통계는 v1.1+에서 Cloud Function 집계로 구현
  // final RoleStats roleStats;

  UserModel({
    required this.uid,
    required this.nickname,
    this.email,
    this.photoUrl,
    this.ageRange,
    this.loginProvider = LoginProvider.kakao,
    this.gamesPlayed = 0,
    this.gamesHosted = 0,
    this.mvpCount = 0,
    this.volunteerCount = 0,
    required this.createdAt,
    required this.lastActiveAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      nickname: data['nickname'] ?? '',
      email: data['email'],
      photoUrl: data['photoUrl'],
      ageRange: data['ageRange'] != null
          ? AgeRange.values[data['ageRange']]
          : null,
      loginProvider: LoginProvider.values[data['loginProvider'] ?? 0],
      gamesPlayed: data['gamesPlayed'] ?? 0,
      gamesHosted: data['gamesHosted'] ?? 0,
      mvpCount: data['mvpCount'] ?? 0,
      volunteerCount: data['volunteerCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActiveAt: (data['lastActiveAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      // roleStats 제거됨 - MVP 단순화
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nickname': nickname,
      'email': email,
      'photoUrl': photoUrl,
      'ageRange': ageRange?.index,
      'loginProvider': loginProvider.index,
      'gamesPlayed': gamesPlayed,
      'gamesHosted': gamesHosted,
      'mvpCount': mvpCount,
      'volunteerCount': volunteerCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActiveAt': Timestamp.fromDate(lastActiveAt),
      // roleStats 제거됨 - MVP 단순화
    };
  }

  UserModel copyWith({
    String? nickname,
    String? email,
    String? photoUrl,
    AgeRange? ageRange,
    int? gamesPlayed,
    int? gamesHosted,
    int? mvpCount,
    int? volunteerCount,
    DateTime? lastActiveAt,
  }) {
    return UserModel(
      uid: uid,
      nickname: nickname ?? this.nickname,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      ageRange: ageRange ?? this.ageRange,
      loginProvider: loginProvider,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      gamesHosted: gamesHosted ?? this.gamesHosted,
      mvpCount: mvpCount ?? this.mvpCount,
      volunteerCount: volunteerCount ?? this.volunteerCount,
      createdAt: createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  /// 신규 사용자 생성 (회원가입 시)
  static UserModel createNew({
    required String uid,
    required String nickname,
    String? email,
    String? photoUrl,
    AgeRange? ageRange,
    required LoginProvider loginProvider,
  }) {
    final now = DateTime.now();
    return UserModel(
      uid: uid,
      nickname: nickname,
      email: email,
      photoUrl: photoUrl,
      ageRange: ageRange,
      loginProvider: loginProvider,
      createdAt: now,
      lastActiveAt: now,
    );
  }

  /// 연령대 표시 텍스트
  String get ageRangeText => ageRange?.label ?? '비공개';

  /// 프로필 완성도 (%)
  int get profileCompleteness {
    int score = 50; // 닉네임은 필수라 기본 50%
    if (photoUrl != null) score += 25;
    if (ageRange != null && ageRange != AgeRange.private_) score += 25;
    return score;
  }

  /// 총 게임 수 (참여 + 호스팅)
  int get totalGames => gamesPlayed + gamesHosted;
}

// ============== 연령대 ==============

/// 연령대
enum AgeRange {
  teens,      // 10대
  twenties,   // 20대
  thirties,   // 30대 이상
  private_,   // 비공개
}

extension AgeRangeExtension on AgeRange {
  String get label {
    switch (this) {
      case AgeRange.teens:
        return '10대';
      case AgeRange.twenties:
        return '20대';
      case AgeRange.thirties:
        return '30대+';
      case AgeRange.private_:
        return '비공개';
    }
  }

  String get emoji {
    switch (this) {
      case AgeRange.teens:
        return '🧒';
      case AgeRange.twenties:
        return '🧑';
      case AgeRange.thirties:
        return '🧔';
      case AgeRange.private_:
        return '🔒';
    }
  }

  String get description {
    switch (this) {
      case AgeRange.teens:
        return '13~19세';
      case AgeRange.twenties:
        return '20~29세';
      case AgeRange.thirties:
        return '30세 이상';
      case AgeRange.private_:
        return '공개하지 않음';
    }
  }
}

// ============== 로그인 방식 ==============

/// 로그인 방식
enum LoginProvider {
  kakao,
  google,
  apple,
}

extension LoginProviderExtension on LoginProvider {
  String get label {
    switch (this) {
      case LoginProvider.kakao:
        return '카카오';
      case LoginProvider.google:
        return '구글';
      case LoginProvider.apple:
        return 'Apple';
    }
  }

  String get buttonText {
    switch (this) {
      case LoginProvider.kakao:
        return '카카오로 시작하기';
      case LoginProvider.google:
        return 'Google로 시작하기';
      case LoginProvider.apple:
        return 'Apple로 시작하기';
    }
  }
}

// ============== 닉네임 유효성 검사 ==============

/// 닉네임 유효성 검사
class NicknameValidator {
  static const int minLength = 2;
  static const int maxLength = 10;

  /// 금지 단어 목록
  static const List<String> forbiddenWords = [
    '관리자', 'admin', '운영자', '술래', 'sullae',
  ];

  /// 유효성 검사 결과
  static NicknameValidationResult validate(String nickname) {
    final trimmed = nickname.trim();

    // 길이 검사
    if (trimmed.isEmpty) {
      return NicknameValidationResult.empty;
    }
    if (trimmed.length < minLength) {
      return NicknameValidationResult.tooShort;
    }
    if (trimmed.length > maxLength) {
      return NicknameValidationResult.tooLong;
    }

    // 금지 단어 검사
    final lower = trimmed.toLowerCase();
    for (final word in forbiddenWords) {
      if (lower.contains(word.toLowerCase())) {
        return NicknameValidationResult.forbidden;
      }
    }

    // 특수문자 검사 (한글, 영문, 숫자만 허용)
    final validPattern = RegExp(r'^[가-힣a-zA-Z0-9]+$');
    if (!validPattern.hasMatch(trimmed)) {
      return NicknameValidationResult.invalidCharacters;
    }

    return NicknameValidationResult.valid;
  }
}

/// 닉네임 유효성 검사 결과
enum NicknameValidationResult {
  valid,
  empty,
  tooShort,
  tooLong,
  forbidden,
  invalidCharacters,
  duplicated,    // 중복 (서버 확인 후)
}

extension NicknameValidationResultExtension on NicknameValidationResult {
  bool get isValid => this == NicknameValidationResult.valid;

  String get errorMessage {
    switch (this) {
      case NicknameValidationResult.valid:
        return '';
      case NicknameValidationResult.empty:
        return '닉네임을 입력해주세요';
      case NicknameValidationResult.tooShort:
        return '닉네임은 ${NicknameValidator.minLength}자 이상이어야 해요';
      case NicknameValidationResult.tooLong:
        return '닉네임은 ${NicknameValidator.maxLength}자 이하여야 해요';
      case NicknameValidationResult.forbidden:
        return '사용할 수 없는 닉네임이에요';
      case NicknameValidationResult.invalidCharacters:
        return '한글, 영문, 숫자만 사용할 수 있어요';
      case NicknameValidationResult.duplicated:
        return '이미 사용 중인 닉네임이에요';
    }
  }
}

// ============== 역할별 플레이 통계 ==============

/// 역할별 플레이 횟수 통계
class RoleStats {
  final int copsCount;      // 경찰 역할 횟수
  final int robbersCount;   // 도둑 역할 횟수
  final int seekerCount;    // 술래 역할 횟수
  final int hiderCount;     // 숨는이/도망자 역할 횟수
  final int teamACount;     // A팀 역할 횟수
  final int teamBCount;     // B팀 역할 횟수

  RoleStats({
    this.copsCount = 0,
    this.robbersCount = 0,
    this.seekerCount = 0,
    this.hiderCount = 0,
    this.teamACount = 0,
    this.teamBCount = 0,
  });

  factory RoleStats.fromMap(Map<String, dynamic>? data) {
    if (data == null) return RoleStats();
    return RoleStats(
      copsCount: data['copsCount'] ?? 0,
      robbersCount: data['robbersCount'] ?? 0,
      seekerCount: data['seekerCount'] ?? 0,
      hiderCount: data['hiderCount'] ?? 0,
      teamACount: data['teamACount'] ?? 0,
      teamBCount: data['teamBCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'copsCount': copsCount,
      'robbersCount': robbersCount,
      'seekerCount': seekerCount,
      'hiderCount': hiderCount,
      'teamACount': teamACount,
      'teamBCount': teamBCount,
    };
  }

  RoleStats copyWith({
    int? copsCount,
    int? robbersCount,
    int? seekerCount,
    int? hiderCount,
    int? teamACount,
    int? teamBCount,
  }) {
    return RoleStats(
      copsCount: copsCount ?? this.copsCount,
      robbersCount: robbersCount ?? this.robbersCount,
      seekerCount: seekerCount ?? this.seekerCount,
      hiderCount: hiderCount ?? this.hiderCount,
      teamACount: teamACount ?? this.teamACount,
      teamBCount: teamBCount ?? this.teamBCount,
    );
  }

  /// 총 게임 수
  int get totalGames => copsCount + robbersCount + seekerCount + hiderCount + teamACount + teamBCount;

  /// 가장 많이 플레이한 역할
  String get favoriteRole {
    final roles = {
      '경찰': copsCount,
      '도둑': robbersCount,
      '술래': seekerCount,
      '도망자': hiderCount,
      'A팀': teamACount,
      'B팀': teamBCount,
    };

    if (totalGames == 0) return '없음';

    final sorted = roles.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  /// 역할 통계 리스트 (UI 표시용)
  List<RoleStatItem> get statItems {
    return [
      if (copsCount > 0) RoleStatItem(name: '경찰', count: copsCount, emoji: '👮'),
      if (robbersCount > 0) RoleStatItem(name: '도둑', count: robbersCount, emoji: '🦹'),
      if (seekerCount > 0) RoleStatItem(name: '술래', count: seekerCount, emoji: '👁️'),
      if (hiderCount > 0) RoleStatItem(name: '도망자', count: hiderCount, emoji: '🏃'),
      if (teamACount > 0) RoleStatItem(name: 'A팀', count: teamACount, emoji: '🔴'),
      if (teamBCount > 0) RoleStatItem(name: 'B팀', count: teamBCount, emoji: '🔵'),
    ];
  }
}

/// 역할 통계 아이템 (UI 표시용)
class RoleStatItem {
  final String name;
  final int count;
  final String emoji;

  RoleStatItem({
    required this.name,
    required this.count,
    required this.emoji,
  });
}
