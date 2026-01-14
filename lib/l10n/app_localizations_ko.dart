// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => '술래';

  @override
  String get appTagline => '함께 뛰어놀자!';

  @override
  String get navExplore => '둘러보기';

  @override
  String get navMyMeetings => '내 모임';

  @override
  String get navProfile => '프로필';

  @override
  String get createMeeting => '모임 만들기';

  @override
  String get gameType => '게임 종류';

  @override
  String get meetingTitle => '모임 제목';

  @override
  String get meetingTitleHint => '예: 한강공원에서 경찰과 도둑!';

  @override
  String get meetingTitleRequired => '모임 제목을 입력해주세요';

  @override
  String get meetingDescription => '모임 설명';

  @override
  String get meetingDescriptionHint => '어떤 모임인지 설명해주세요';

  @override
  String get location => '장소';

  @override
  String get locationHint => '예: 여의도 한강공원';

  @override
  String get locationRequired => '장소를 입력해주세요';

  @override
  String get locationDetail => '상세 위치 (선택)';

  @override
  String get locationDetailHint => '예: 물빛무대 앞';

  @override
  String get dateTime => '일시';

  @override
  String get maxParticipants => '모집 인원';

  @override
  String participantsUnit(int count) {
    return '$count명';
  }

  @override
  String get createMeetingFailed => '모임 생성에 실패했습니다';

  @override
  String get gameCopsAndRobbers => '경찰과 도둑';

  @override
  String get gameFreezeTag => '얼음땡';

  @override
  String get gameHideAndSeek => '숨바꼭질';

  @override
  String get gameCaptureFlag => '깃발뺏기';

  @override
  String get gameCustom => '커스텀';

  @override
  String get filterAll => '전체';

  @override
  String get noRecruitingMeetings => '모집중인 모임이 없습니다';

  @override
  String get createNewMeeting => '새로운 모임을 만들어보세요!';

  @override
  String get noJoinedMeetings => '참여한 모임이 없습니다';

  @override
  String gamesPlayedCount(int count) {
    return '게임 $count회 참여';
  }

  @override
  String get statParticipation => '참여';

  @override
  String get statHosting => '호스팅';

  @override
  String get statMvp => 'MVP';

  @override
  String get changeNickname => '닉네임 변경';

  @override
  String get newNickname => '새 닉네임';

  @override
  String get notificationSettings => '알림 설정';

  @override
  String get help => '도움말';

  @override
  String get logout => '로그아웃';

  @override
  String get cancel => '취소';

  @override
  String get change => '변경';

  @override
  String get ok => '확인';

  @override
  String get no => '아니오';

  @override
  String get complete => '완료';

  @override
  String get later => '나중에';

  @override
  String get loginWithKakao => '카카오로 시작하기';

  @override
  String get loginWithGoogle => 'Google로 시작하기';

  @override
  String get loginWithApple => 'Apple로 시작하기';

  @override
  String get termsNotice => '시작하면 서비스 이용약관 및 개인정보 처리방침에\n동의하는 것으로 간주됩니다.';

  @override
  String get nicknameSetup => '닉네임 설정';

  @override
  String get enterNickname => '닉네임을 입력하세요';

  @override
  String get nicknameGuide => '게임에서 불릴 이름을\n정해주세요';

  @override
  String get nicknameHint => '2~10자, 한글/영문/숫자';

  @override
  String get nicknameFormat => '한글, 영문, 숫자 2~10자';

  @override
  String get nicknameRequired => '닉네임을 입력해주세요';

  @override
  String get nicknameTooShort => '2자 이상 입력해주세요';

  @override
  String get nicknameTooLong => '10자 이하로 입력해주세요';

  @override
  String get nicknameInvalid => '한글, 영문, 숫자만 사용할 수 있어요';

  @override
  String get checkingDuplicate => '중복 확인 중...';

  @override
  String get nicknameAvailable => '사용 가능한 닉네임이에요!';

  @override
  String get startGame => '게임 시작!';

  @override
  String get selectAgeGroup => '연령대 선택';

  @override
  String get ageGuide => '연령대를 알려주세요';

  @override
  String get ageGroupOptional => '선택 사항이에요. 모임 추천에 활용됩니다.';

  @override
  String get ageMatchingHelp => '비슷한 연령대끼리 매칭에 도움이 돼요\n(선택하지 않아도 괜찮아요)';

  @override
  String get ageGroup10s => '10대';

  @override
  String get ageGroup20s => '20대';

  @override
  String get ageGroup30s => '30대';

  @override
  String get ageGroup40sPlus => '40대 이상';

  @override
  String get skip => '건너뛰기';

  @override
  String get next => '다음';

  @override
  String get startPrivately => '비공개로 시작하기';

  @override
  String get signupFailed => '회원가입에 실패했어요. 다시 시도해주세요.';

  @override
  String get gameTime => '게임 시간';

  @override
  String minutesUnit(int count) {
    return '$count분';
  }

  @override
  String get teamAssignment => '팀 배정';

  @override
  String get shuffleTeamHint => '셔플 버튼을 눌러 팀을 배정하세요';

  @override
  String get startGameButton => '게임 시작';

  @override
  String get remainingTime => '남은 시간';

  @override
  String get shuffleTeam => '팀 섞기';

  @override
  String get endGame => '게임 종료';

  @override
  String get gameEndTitle => '게임 종료!';

  @override
  String get endGameConfirmTitle => '게임을 종료할까요?';

  @override
  String get endGameConfirmMessage => '진행 중인 게임을 종료합니다.';

  @override
  String get mvpVoteConfirm => 'MVP 투표를 시작하시겠습니까?';

  @override
  String get pause => '일시정지';

  @override
  String get resume => '재개';

  @override
  String get paused => '일시정지';

  @override
  String get tapToPause => '탭하여 일시정지';

  @override
  String get tapToResume => '탭하여 재개';

  @override
  String get mvpVoteButton => 'MVP 투표';

  @override
  String get mvpVoteCreated => 'MVP 투표가 생성되었습니다!';

  @override
  String get roleCops => '경찰';

  @override
  String get roleRobbers => '도둑';

  @override
  String get roleSeeker => '술래';

  @override
  String get roleRunner => '도망자';

  @override
  String get roleHider => '숨는이';

  @override
  String get roleTeamA => 'A팀';

  @override
  String get roleTeamB => 'B팀';

  @override
  String get meetingChat => '채팅';

  @override
  String get meetingInfo => '정보';

  @override
  String get meetingParticipants => '참가자';

  @override
  String get meetingHost => '방장';

  @override
  String get meetingStatus => '상태';

  @override
  String get meetingStatusRecruiting => '모집중';

  @override
  String get meetingStatusInProgress => '진행중';

  @override
  String get meetingStatusFinished => '종료';

  @override
  String get joinMeeting => '참여하기';

  @override
  String get leaveMeeting => '나가기';

  @override
  String get cancelMeeting => '모임 취소';

  @override
  String get cancelMeetingConfirm => '정말 모임을 취소하시겠습니까?';

  @override
  String get cancelMeetingButton => '취소하기';

  @override
  String get startMeeting => '게임 시작하기';

  @override
  String get joinedMeeting => '모임에 참여했습니다!';

  @override
  String get noMessages => '아직 메시지가 없습니다';

  @override
  String get quickMessageArrived => '지금 도착했어요';

  @override
  String get quickMessageLate5 => '5분 늦어요';

  @override
  String get quickMessageLate10 => '10분 늦어요';

  @override
  String get quickMessageReady => '게임 시작 가능해요';

  @override
  String get quickMessageOnMyWay => '가고 있어요';

  @override
  String get quickMessageCantMake => '오늘 못 갈 것 같아요';

  @override
  String get quickMessageWhereAreYou => '어디쯤이세요?';

  @override
  String get quickMessageStartSoon => '곧 시작해요';

  @override
  String get enterMessage => '메시지를 입력하세요...';

  @override
  String get send => '전송';

  @override
  String get systemSender => '시스템';

  @override
  String get meetingCreated => '모임이 생성되었습니다.';

  @override
  String get meetingCancelled => '모임이 취소되었습니다.';

  @override
  String get gameStarted => '게임이 시작되었습니다!';

  @override
  String userJoined(String nickname) {
    return '$nickname님이 참가했습니다.';
  }

  @override
  String userLeft(String nickname) {
    return '$nickname님이 나갔습니다.';
  }

  @override
  String get phaseRoleConfirm => '역할 확인';

  @override
  String get phaseRoleConfirmCopsDesc => '경찰/도둑 역할을 확인하세요';

  @override
  String get phaseRoleConfirmSeekerDesc => '술래/도망자 역할을 확인하세요';

  @override
  String get phaseRoleConfirmHiderDesc => '술래/숨는이 역할을 확인하세요';

  @override
  String get phasePrisonConfirm => '감옥 위치 확인';

  @override
  String get phasePrisonConfirmDesc => '감옥 위치를 모두가 확인합니다';

  @override
  String get phaseThiefHide => '도둑 숨기';

  @override
  String get phaseThiefHideDesc => '도둑이 먼저 흩어집니다';

  @override
  String get phasePursuit => '추격 시작';

  @override
  String get phasePursuitDesc => '경찰이 도둑을 잡으러 갑니다';

  @override
  String get phaseGameEnd => '게임 종료';

  @override
  String get phaseGameEndCopsDesc => '타이머 종료 또는 전원 체포 시';

  @override
  String get phaseGameEndFreezeDesc => '타이머 종료 또는 전원 얼음 시';

  @override
  String get phaseGameEndHideDesc => '타이머 종료 또는 전원 발견 시';

  @override
  String get phaseGameEndFlagDesc => '목표 점수 달성 또는 타이머 종료';

  @override
  String get phasePrep => '준비';

  @override
  String get phasePrepDesc => '도망자가 흩어집니다';

  @override
  String get phaseGameStart => '게임 시작';

  @override
  String get phaseGameStartFreezeDesc => '술래가 \"얼음땡!\" 외치고 시작';

  @override
  String get phaseHide => '숨기';

  @override
  String get phaseHideDesc => '술래가 눈 감고 세는 동안 숨기';

  @override
  String get phaseFindStart => '찾기 시작';

  @override
  String get phaseFindStartDesc => '술래가 숨은 사람을 찾습니다';

  @override
  String get phaseTeamConfirm => '팀 확인';

  @override
  String get phaseTeamConfirmDesc => 'A팀/B팀 진영을 확인하세요';

  @override
  String get phaseFlagPlace => '깃발 배치';

  @override
  String get phaseFlagPlaceDesc => '각 팀 진영에 깃발을 배치합니다';

  @override
  String get phaseFlagStart => '상대 깃발을 가져오세요!';

  @override
  String get preferenceNone => '상관없음';

  @override
  String preferenceRole1(String role) {
    return '$role 희망';
  }

  @override
  String get teamBalanced => '팀이 균형잡혀 있습니다. 바로 시작할 수 있어요!';

  @override
  String get teamNoneWillBeRandom => '상관없음 인원이 랜덤 배치됩니다.';

  @override
  String teamExcess(String role, int count, String otherRole) {
    return '$role 희망자가 $count명 초과입니다. $count명이 랜덤으로 $otherRole이 됩니다.';
  }

  @override
  String teamNeedsAdjust(String role, int count) {
    return '$role 희망자가 $count명 초과입니다. 협의 후 조정하거나 그대로 시작할 수 있어요.';
  }

  @override
  String get teamUnbalanced => '팀 구성이 불균형합니다. 조정하거나 그대로 시작할 수 있어요.';

  @override
  String get localRulePrisonLocation => '감옥 위치';

  @override
  String get localRulePrisonLocationDesc => '잡힌 도둑이 대기하는 장소';

  @override
  String get localRuleJailBreak => '탈옥 허용';

  @override
  String get localRuleJailBreakDesc => '동료 도둑이 감옥 터치로 구출 가능';

  @override
  String get localRuleBoundary => '경계 설정';

  @override
  String get localRuleBoundaryDesc => '게임 영역 제한';

  @override
  String get localRuleSafeZone => '안전지대 금지';

  @override
  String get localRuleSafeZoneDesc => '안전지대 없이 진행';

  @override
  String get localRuleTagMethod => '터치 방식';

  @override
  String get localRuleTagMethodDesc => '양손 터치/한손 터치/어깨 터치';

  @override
  String get localRuleFreezeRelease => '얼음 해제';

  @override
  String get localRuleFreezeReleaseDesc => '동료가 터치하면 해제';

  @override
  String get localRuleSeekerCount => '술래 수 조정';

  @override
  String get localRuleSeekerCountDesc => '인원에 따라 술래 수 조절';

  @override
  String get localRuleHidingTime => '숨는 시간';

  @override
  String get localRuleHidingTimeDesc => '술래가 세는 시간 (예: 30초)';

  @override
  String get localRuleHintAllowed => '힌트 허용';

  @override
  String get localRuleHintAllowedDesc => '숨은 사람이 소리로 힌트 가능';

  @override
  String get localRuleFlagReturn => '깃발 반환';

  @override
  String get localRuleFlagReturnDesc => '터치당하면 깃발 제자리 반환';

  @override
  String get localRuleTeamTag => '팀 터치';

  @override
  String get localRuleTeamTagDesc => '상대 진영에서 터치당하면 감옥';

  @override
  String get joinWithCode => '코드로 참가';

  @override
  String get enterJoinCode => '참가 코드 입력';

  @override
  String get joinCodeHint => '6자리 코드';

  @override
  String get joinCodeInvalid => '6자리 코드를 입력해주세요';

  @override
  String get joinCodeNotFound => '모임을 찾을 수 없습니다';

  @override
  String get join => '참가';

  @override
  String get search => '검색';

  @override
  String get searchMeetings => '모임 검색...';

  @override
  String get filterTimeAll => '전체';

  @override
  String get filterTimeToday => '오늘';

  @override
  String get filterTimeTomorrow => '내일';

  @override
  String get filterTimeThisWeek => '이번 주';

  @override
  String get showRecruitingOnly => '모집중만';

  @override
  String get showAll => '전체 보기';

  @override
  String activeFilters(int count) {
    return '필터 $count개 적용중';
  }

  @override
  String get clearFilters => '필터 초기화';

  @override
  String get filterTitle => '필터';

  @override
  String get applyFilters => '적용하기';

  @override
  String get resetFilters => '초기화';

  @override
  String get filterRegion => '지역';

  @override
  String get regionAll => '전체';

  @override
  String get regionSeoul => '서울';

  @override
  String get regionGyeonggi => '경기';

  @override
  String get regionIncheon => '인천';

  @override
  String get regionBusan => '부산';

  @override
  String get regionDaegu => '대구';

  @override
  String get regionDaejeon => '대전';

  @override
  String get regionGwangju => '광주';

  @override
  String get regionUlsan => '울산';

  @override
  String get regionSejong => '세종';

  @override
  String get regionGangwon => '강원';

  @override
  String get regionChungbuk => '충북';

  @override
  String get regionChungnam => '충남';

  @override
  String get regionJeonbuk => '전북';

  @override
  String get regionJeonnam => '전남';

  @override
  String get regionGyeongbuk => '경북';

  @override
  String get regionGyeongnam => '경남';

  @override
  String get regionJeju => '제주';

  @override
  String get filterAgeGroup => '희망 연령대';

  @override
  String get ageGroupAll => '상관없음';

  @override
  String get ageGroupTeens => '10대';

  @override
  String get ageGroupTwenties => '20대';

  @override
  String get ageGroupThirties => '30대';

  @override
  String get ageGroupFortyPlus => '40대 이상';

  @override
  String get filterGroupSize => '모집 인원';

  @override
  String get groupSizeSmall => '소규모 (4-8명)';

  @override
  String get groupSizeMedium => '중규모 (9-15명)';

  @override
  String get groupSizeLarge => '대규모 (16명+)';

  @override
  String get filterDifficulty => '분위기';

  @override
  String get difficultyCasual => '가볍게';

  @override
  String get difficultyCompetitive => '진지하게';

  @override
  String get difficultyBeginner => '초보 환영';

  @override
  String get moreFilters => '상세 필터';

  @override
  String get buyCoffee => '커피 한 잔 사주기';

  @override
  String get buyCoffeeDescription => '개발자를 응원할 수 있어요';

  @override
  String get buyCoffeeButton => '응원하기';

  @override
  String get donationMessage =>
      '이 앱이 도움이 되었다면 선택적으로 응원할 수 있어요.\n광고 없는 버전이나 추가 기능과는 무관해요.';

  @override
  String get donationThanks => '감사합니다! 더 좋은 앱을 만들게요 ☕';

  @override
  String get donationFailed => '구매에 실패했어요. 나중에 다시 시도해주세요.';

  @override
  String get donationHint => '설정에서 \'커피 한 잔 사주기\'로 개발자를 응원할 수 있어요 ☕';

  @override
  String get shareMeeting => '모임 공유하기';

  @override
  String get gatherPeople => '사람 모으기';

  @override
  String get gatherPeopleDesc => '초대 메시지를 만들어 공유하세요';

  @override
  String get whereToShare => '어디서 공유할까요?';

  @override
  String get messageStyle => '메시지 스타일';

  @override
  String get toneCasual => '편하게';

  @override
  String get toneCasualDesc => '친구들에게';

  @override
  String get toneEnthusiastic => '활기차게';

  @override
  String get toneEnthusiasticDesc => '동네 모집';

  @override
  String get chatLinkOptional => '채팅방 링크 (선택)';

  @override
  String get chatLinkHint => '오픈채팅 링크를 넣으면 메시지에 포함됩니다';

  @override
  String get preview => '미리보기';

  @override
  String get copyMessage => '메시지 복사하기';

  @override
  String get messageCopied => '초대 메시지가 복사되었습니다';

  @override
  String get copyAndPasteHint => '복사 후 카카오톡이나 SNS에 붙여넣기 하세요';

  @override
  String get joinCode => '참가코드';

  @override
  String get joinCodeCopied => '참가코드가 복사되었습니다';

  @override
  String get copyCode => '코드 복사';

  @override
  String get qrCode => 'QR 코드';

  @override
  String get showToFriends => '친구에게 이 화면을 보여주세요';

  @override
  String get externalChatLink => '외부 채팅방 링크';

  @override
  String get externalChatLinkHint => '카카오 오픈채팅 등 외부 채팅방 URL';

  @override
  String get goToChatroom => '채팅방 바로가기';

  @override
  String get channelKakao => '카카오톡';

  @override
  String get channelOpenChat => '오픈채팅';

  @override
  String get channelInstagram => '인스타그램';

  @override
  String get channelCommunity => '커뮤니티';
}
