import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// No description provided for @appName.
  ///
  /// In ko, this message translates to:
  /// **'술래'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In ko, this message translates to:
  /// **'함께 뛰어놀자!'**
  String get appTagline;

  /// No description provided for @navExplore.
  ///
  /// In ko, this message translates to:
  /// **'둘러보기'**
  String get navExplore;

  /// No description provided for @navMyMeetings.
  ///
  /// In ko, this message translates to:
  /// **'내 모임'**
  String get navMyMeetings;

  /// No description provided for @navProfile.
  ///
  /// In ko, this message translates to:
  /// **'프로필'**
  String get navProfile;

  /// No description provided for @createMeeting.
  ///
  /// In ko, this message translates to:
  /// **'모임 만들기'**
  String get createMeeting;

  /// No description provided for @gameType.
  ///
  /// In ko, this message translates to:
  /// **'게임 종류'**
  String get gameType;

  /// No description provided for @meetingTitle.
  ///
  /// In ko, this message translates to:
  /// **'모임 제목'**
  String get meetingTitle;

  /// No description provided for @meetingTitleHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 한강공원에서 경찰과 도둑!'**
  String get meetingTitleHint;

  /// No description provided for @meetingTitleRequired.
  ///
  /// In ko, this message translates to:
  /// **'모임 제목을 입력해주세요'**
  String get meetingTitleRequired;

  /// No description provided for @meetingDescription.
  ///
  /// In ko, this message translates to:
  /// **'모임 설명'**
  String get meetingDescription;

  /// No description provided for @meetingDescriptionHint.
  ///
  /// In ko, this message translates to:
  /// **'어떤 모임인지 설명해주세요'**
  String get meetingDescriptionHint;

  /// No description provided for @location.
  ///
  /// In ko, this message translates to:
  /// **'장소'**
  String get location;

  /// No description provided for @locationHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 여의도 한강공원'**
  String get locationHint;

  /// No description provided for @locationRequired.
  ///
  /// In ko, this message translates to:
  /// **'장소를 입력해주세요'**
  String get locationRequired;

  /// No description provided for @locationDetail.
  ///
  /// In ko, this message translates to:
  /// **'상세 위치 (선택)'**
  String get locationDetail;

  /// No description provided for @locationDetailHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 물빛무대 앞'**
  String get locationDetailHint;

  /// No description provided for @dateTime.
  ///
  /// In ko, this message translates to:
  /// **'일시'**
  String get dateTime;

  /// No description provided for @maxParticipants.
  ///
  /// In ko, this message translates to:
  /// **'모집 인원'**
  String get maxParticipants;

  /// No description provided for @participantsUnit.
  ///
  /// In ko, this message translates to:
  /// **'{count}명'**
  String participantsUnit(int count);

  /// No description provided for @createMeetingFailed.
  ///
  /// In ko, this message translates to:
  /// **'모임 생성에 실패했습니다'**
  String get createMeetingFailed;

  /// No description provided for @gameCopsAndRobbers.
  ///
  /// In ko, this message translates to:
  /// **'경찰과 도둑'**
  String get gameCopsAndRobbers;

  /// No description provided for @gameFreezeTag.
  ///
  /// In ko, this message translates to:
  /// **'얼음땡'**
  String get gameFreezeTag;

  /// No description provided for @gameHideAndSeek.
  ///
  /// In ko, this message translates to:
  /// **'숨바꼭질'**
  String get gameHideAndSeek;

  /// No description provided for @gameCaptureFlag.
  ///
  /// In ko, this message translates to:
  /// **'깃발뺏기'**
  String get gameCaptureFlag;

  /// No description provided for @gameCustom.
  ///
  /// In ko, this message translates to:
  /// **'커스텀'**
  String get gameCustom;

  /// No description provided for @filterAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get filterAll;

  /// No description provided for @noRecruitingMeetings.
  ///
  /// In ko, this message translates to:
  /// **'모집중인 모임이 없습니다'**
  String get noRecruitingMeetings;

  /// No description provided for @createNewMeeting.
  ///
  /// In ko, this message translates to:
  /// **'새로운 모임을 만들어보세요!'**
  String get createNewMeeting;

  /// No description provided for @noJoinedMeetings.
  ///
  /// In ko, this message translates to:
  /// **'참여한 모임이 없습니다'**
  String get noJoinedMeetings;

  /// No description provided for @gamesPlayedCount.
  ///
  /// In ko, this message translates to:
  /// **'게임 {count}회 참여'**
  String gamesPlayedCount(int count);

  /// No description provided for @statParticipation.
  ///
  /// In ko, this message translates to:
  /// **'참여'**
  String get statParticipation;

  /// No description provided for @statHosting.
  ///
  /// In ko, this message translates to:
  /// **'호스팅'**
  String get statHosting;

  /// No description provided for @statMvp.
  ///
  /// In ko, this message translates to:
  /// **'MVP'**
  String get statMvp;

  /// No description provided for @changeNickname.
  ///
  /// In ko, this message translates to:
  /// **'닉네임 변경'**
  String get changeNickname;

  /// No description provided for @newNickname.
  ///
  /// In ko, this message translates to:
  /// **'새 닉네임'**
  String get newNickname;

  /// No description provided for @notificationSettings.
  ///
  /// In ko, this message translates to:
  /// **'알림 설정'**
  String get notificationSettings;

  /// No description provided for @help.
  ///
  /// In ko, this message translates to:
  /// **'도움말'**
  String get help;

  /// No description provided for @logout.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get logout;

  /// No description provided for @cancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancel;

  /// No description provided for @change.
  ///
  /// In ko, this message translates to:
  /// **'변경'**
  String get change;

  /// No description provided for @ok.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get ok;

  /// No description provided for @no.
  ///
  /// In ko, this message translates to:
  /// **'아니오'**
  String get no;

  /// No description provided for @complete.
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get complete;

  /// No description provided for @later.
  ///
  /// In ko, this message translates to:
  /// **'나중에'**
  String get later;

  /// No description provided for @loginWithKakao.
  ///
  /// In ko, this message translates to:
  /// **'카카오로 시작하기'**
  String get loginWithKakao;

  /// No description provided for @loginWithGoogle.
  ///
  /// In ko, this message translates to:
  /// **'Google로 시작하기'**
  String get loginWithGoogle;

  /// No description provided for @loginWithApple.
  ///
  /// In ko, this message translates to:
  /// **'Apple로 시작하기'**
  String get loginWithApple;

  /// No description provided for @termsNotice.
  ///
  /// In ko, this message translates to:
  /// **'시작하면 서비스 이용약관 및 개인정보 처리방침에\n동의하는 것으로 간주됩니다.'**
  String get termsNotice;

  /// No description provided for @nicknameSetup.
  ///
  /// In ko, this message translates to:
  /// **'닉네임 설정'**
  String get nicknameSetup;

  /// No description provided for @enterNickname.
  ///
  /// In ko, this message translates to:
  /// **'닉네임을 입력하세요'**
  String get enterNickname;

  /// No description provided for @nicknameGuide.
  ///
  /// In ko, this message translates to:
  /// **'게임에서 불릴 이름을\n정해주세요'**
  String get nicknameGuide;

  /// No description provided for @nicknameHint.
  ///
  /// In ko, this message translates to:
  /// **'2~10자, 한글/영문/숫자'**
  String get nicknameHint;

  /// No description provided for @nicknameFormat.
  ///
  /// In ko, this message translates to:
  /// **'한글, 영문, 숫자 2~10자'**
  String get nicknameFormat;

  /// No description provided for @nicknameRequired.
  ///
  /// In ko, this message translates to:
  /// **'닉네임을 입력해주세요'**
  String get nicknameRequired;

  /// No description provided for @nicknameTooShort.
  ///
  /// In ko, this message translates to:
  /// **'2자 이상 입력해주세요'**
  String get nicknameTooShort;

  /// No description provided for @nicknameTooLong.
  ///
  /// In ko, this message translates to:
  /// **'10자 이하로 입력해주세요'**
  String get nicknameTooLong;

  /// No description provided for @nicknameInvalid.
  ///
  /// In ko, this message translates to:
  /// **'한글, 영문, 숫자만 사용할 수 있어요'**
  String get nicknameInvalid;

  /// No description provided for @checkingDuplicate.
  ///
  /// In ko, this message translates to:
  /// **'중복 확인 중...'**
  String get checkingDuplicate;

  /// No description provided for @nicknameAvailable.
  ///
  /// In ko, this message translates to:
  /// **'사용 가능한 닉네임이에요!'**
  String get nicknameAvailable;

  /// No description provided for @startGame.
  ///
  /// In ko, this message translates to:
  /// **'게임 시작!'**
  String get startGame;

  /// No description provided for @selectAgeGroup.
  ///
  /// In ko, this message translates to:
  /// **'연령대 선택'**
  String get selectAgeGroup;

  /// No description provided for @ageGuide.
  ///
  /// In ko, this message translates to:
  /// **'연령대를 알려주세요'**
  String get ageGuide;

  /// No description provided for @ageGroupOptional.
  ///
  /// In ko, this message translates to:
  /// **'선택 사항이에요. 모임 추천에 활용됩니다.'**
  String get ageGroupOptional;

  /// No description provided for @ageMatchingHelp.
  ///
  /// In ko, this message translates to:
  /// **'비슷한 연령대끼리 매칭에 도움이 돼요\n(선택하지 않아도 괜찮아요)'**
  String get ageMatchingHelp;

  /// No description provided for @ageGroup10s.
  ///
  /// In ko, this message translates to:
  /// **'10대'**
  String get ageGroup10s;

  /// No description provided for @ageGroup20s.
  ///
  /// In ko, this message translates to:
  /// **'20대'**
  String get ageGroup20s;

  /// No description provided for @ageGroup30s.
  ///
  /// In ko, this message translates to:
  /// **'30대'**
  String get ageGroup30s;

  /// No description provided for @ageGroup40sPlus.
  ///
  /// In ko, this message translates to:
  /// **'40대 이상'**
  String get ageGroup40sPlus;

  /// No description provided for @skip.
  ///
  /// In ko, this message translates to:
  /// **'건너뛰기'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In ko, this message translates to:
  /// **'다음'**
  String get next;

  /// No description provided for @startPrivately.
  ///
  /// In ko, this message translates to:
  /// **'비공개로 시작하기'**
  String get startPrivately;

  /// No description provided for @signupFailed.
  ///
  /// In ko, this message translates to:
  /// **'회원가입에 실패했어요. 다시 시도해주세요.'**
  String get signupFailed;

  /// No description provided for @gameTime.
  ///
  /// In ko, this message translates to:
  /// **'게임 시간'**
  String get gameTime;

  /// No description provided for @minutesUnit.
  ///
  /// In ko, this message translates to:
  /// **'{count}분'**
  String minutesUnit(int count);

  /// No description provided for @teamAssignment.
  ///
  /// In ko, this message translates to:
  /// **'팀 배정'**
  String get teamAssignment;

  /// No description provided for @shuffleTeamHint.
  ///
  /// In ko, this message translates to:
  /// **'셔플 버튼을 눌러 팀을 배정하세요'**
  String get shuffleTeamHint;

  /// No description provided for @startGameButton.
  ///
  /// In ko, this message translates to:
  /// **'게임 시작'**
  String get startGameButton;

  /// No description provided for @remainingTime.
  ///
  /// In ko, this message translates to:
  /// **'남은 시간'**
  String get remainingTime;

  /// No description provided for @shuffleTeam.
  ///
  /// In ko, this message translates to:
  /// **'팀 섞기'**
  String get shuffleTeam;

  /// No description provided for @endGame.
  ///
  /// In ko, this message translates to:
  /// **'게임 종료'**
  String get endGame;

  /// No description provided for @gameEndTitle.
  ///
  /// In ko, this message translates to:
  /// **'게임 종료!'**
  String get gameEndTitle;

  /// No description provided for @endGameConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'게임을 종료할까요?'**
  String get endGameConfirmTitle;

  /// No description provided for @endGameConfirmMessage.
  ///
  /// In ko, this message translates to:
  /// **'진행 중인 게임을 종료합니다.'**
  String get endGameConfirmMessage;

  /// No description provided for @mvpVoteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'MVP 투표를 시작하시겠습니까?'**
  String get mvpVoteConfirm;

  /// No description provided for @pause.
  ///
  /// In ko, this message translates to:
  /// **'일시정지'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In ko, this message translates to:
  /// **'재개'**
  String get resume;

  /// No description provided for @paused.
  ///
  /// In ko, this message translates to:
  /// **'일시정지'**
  String get paused;

  /// No description provided for @tapToPause.
  ///
  /// In ko, this message translates to:
  /// **'탭하여 일시정지'**
  String get tapToPause;

  /// No description provided for @tapToResume.
  ///
  /// In ko, this message translates to:
  /// **'탭하여 재개'**
  String get tapToResume;

  /// No description provided for @mvpVoteButton.
  ///
  /// In ko, this message translates to:
  /// **'MVP 투표'**
  String get mvpVoteButton;

  /// No description provided for @mvpVoteCreated.
  ///
  /// In ko, this message translates to:
  /// **'MVP 투표가 생성되었습니다!'**
  String get mvpVoteCreated;

  /// No description provided for @roleCops.
  ///
  /// In ko, this message translates to:
  /// **'경찰'**
  String get roleCops;

  /// No description provided for @roleRobbers.
  ///
  /// In ko, this message translates to:
  /// **'도둑'**
  String get roleRobbers;

  /// No description provided for @roleSeeker.
  ///
  /// In ko, this message translates to:
  /// **'술래'**
  String get roleSeeker;

  /// No description provided for @roleRunner.
  ///
  /// In ko, this message translates to:
  /// **'도망자'**
  String get roleRunner;

  /// No description provided for @roleHider.
  ///
  /// In ko, this message translates to:
  /// **'숨는이'**
  String get roleHider;

  /// No description provided for @roleTeamA.
  ///
  /// In ko, this message translates to:
  /// **'A팀'**
  String get roleTeamA;

  /// No description provided for @roleTeamB.
  ///
  /// In ko, this message translates to:
  /// **'B팀'**
  String get roleTeamB;

  /// No description provided for @meetingChat.
  ///
  /// In ko, this message translates to:
  /// **'채팅'**
  String get meetingChat;

  /// No description provided for @meetingInfo.
  ///
  /// In ko, this message translates to:
  /// **'정보'**
  String get meetingInfo;

  /// No description provided for @meetingParticipants.
  ///
  /// In ko, this message translates to:
  /// **'참가자'**
  String get meetingParticipants;

  /// No description provided for @meetingHost.
  ///
  /// In ko, this message translates to:
  /// **'방장'**
  String get meetingHost;

  /// No description provided for @meetingStatus.
  ///
  /// In ko, this message translates to:
  /// **'상태'**
  String get meetingStatus;

  /// No description provided for @meetingStatusRecruiting.
  ///
  /// In ko, this message translates to:
  /// **'모집중'**
  String get meetingStatusRecruiting;

  /// No description provided for @meetingStatusInProgress.
  ///
  /// In ko, this message translates to:
  /// **'진행중'**
  String get meetingStatusInProgress;

  /// No description provided for @meetingStatusFinished.
  ///
  /// In ko, this message translates to:
  /// **'종료'**
  String get meetingStatusFinished;

  /// No description provided for @joinMeeting.
  ///
  /// In ko, this message translates to:
  /// **'참여하기'**
  String get joinMeeting;

  /// No description provided for @leaveMeeting.
  ///
  /// In ko, this message translates to:
  /// **'나가기'**
  String get leaveMeeting;

  /// No description provided for @cancelMeeting.
  ///
  /// In ko, this message translates to:
  /// **'모임 취소'**
  String get cancelMeeting;

  /// No description provided for @cancelMeetingConfirm.
  ///
  /// In ko, this message translates to:
  /// **'정말 모임을 취소하시겠습니까?'**
  String get cancelMeetingConfirm;

  /// No description provided for @cancelMeetingButton.
  ///
  /// In ko, this message translates to:
  /// **'취소하기'**
  String get cancelMeetingButton;

  /// No description provided for @startMeeting.
  ///
  /// In ko, this message translates to:
  /// **'게임 시작하기'**
  String get startMeeting;

  /// No description provided for @joinedMeeting.
  ///
  /// In ko, this message translates to:
  /// **'모임에 참여했습니다!'**
  String get joinedMeeting;

  /// No description provided for @noMessages.
  ///
  /// In ko, this message translates to:
  /// **'아직 메시지가 없습니다'**
  String get noMessages;

  /// No description provided for @quickMessageArrived.
  ///
  /// In ko, this message translates to:
  /// **'지금 도착했어요'**
  String get quickMessageArrived;

  /// No description provided for @quickMessageLate5.
  ///
  /// In ko, this message translates to:
  /// **'5분 늦어요'**
  String get quickMessageLate5;

  /// No description provided for @quickMessageLate10.
  ///
  /// In ko, this message translates to:
  /// **'10분 늦어요'**
  String get quickMessageLate10;

  /// No description provided for @quickMessageReady.
  ///
  /// In ko, this message translates to:
  /// **'게임 시작 가능해요'**
  String get quickMessageReady;

  /// No description provided for @quickMessageOnMyWay.
  ///
  /// In ko, this message translates to:
  /// **'가고 있어요'**
  String get quickMessageOnMyWay;

  /// No description provided for @quickMessageCantMake.
  ///
  /// In ko, this message translates to:
  /// **'오늘 못 갈 것 같아요'**
  String get quickMessageCantMake;

  /// No description provided for @quickMessageWhereAreYou.
  ///
  /// In ko, this message translates to:
  /// **'어디쯤이세요?'**
  String get quickMessageWhereAreYou;

  /// No description provided for @quickMessageStartSoon.
  ///
  /// In ko, this message translates to:
  /// **'곧 시작해요'**
  String get quickMessageStartSoon;

  /// No description provided for @enterMessage.
  ///
  /// In ko, this message translates to:
  /// **'메시지를 입력하세요...'**
  String get enterMessage;

  /// No description provided for @send.
  ///
  /// In ko, this message translates to:
  /// **'전송'**
  String get send;

  /// No description provided for @systemSender.
  ///
  /// In ko, this message translates to:
  /// **'시스템'**
  String get systemSender;

  /// No description provided for @meetingCreated.
  ///
  /// In ko, this message translates to:
  /// **'모임이 생성되었습니다.'**
  String get meetingCreated;

  /// No description provided for @meetingCancelled.
  ///
  /// In ko, this message translates to:
  /// **'모임이 취소되었습니다.'**
  String get meetingCancelled;

  /// No description provided for @gameStarted.
  ///
  /// In ko, this message translates to:
  /// **'게임이 시작되었습니다!'**
  String get gameStarted;

  /// No description provided for @userJoined.
  ///
  /// In ko, this message translates to:
  /// **'{nickname}님이 참가했습니다.'**
  String userJoined(String nickname);

  /// No description provided for @userLeft.
  ///
  /// In ko, this message translates to:
  /// **'{nickname}님이 나갔습니다.'**
  String userLeft(String nickname);

  /// No description provided for @phaseRoleConfirm.
  ///
  /// In ko, this message translates to:
  /// **'역할 확인'**
  String get phaseRoleConfirm;

  /// No description provided for @phaseRoleConfirmCopsDesc.
  ///
  /// In ko, this message translates to:
  /// **'경찰/도둑 역할을 확인하세요'**
  String get phaseRoleConfirmCopsDesc;

  /// No description provided for @phaseRoleConfirmSeekerDesc.
  ///
  /// In ko, this message translates to:
  /// **'술래/도망자 역할을 확인하세요'**
  String get phaseRoleConfirmSeekerDesc;

  /// No description provided for @phaseRoleConfirmHiderDesc.
  ///
  /// In ko, this message translates to:
  /// **'술래/숨는이 역할을 확인하세요'**
  String get phaseRoleConfirmHiderDesc;

  /// No description provided for @phasePrisonConfirm.
  ///
  /// In ko, this message translates to:
  /// **'감옥 위치 확인'**
  String get phasePrisonConfirm;

  /// No description provided for @phasePrisonConfirmDesc.
  ///
  /// In ko, this message translates to:
  /// **'감옥 위치를 모두가 확인합니다'**
  String get phasePrisonConfirmDesc;

  /// No description provided for @phaseThiefHide.
  ///
  /// In ko, this message translates to:
  /// **'도둑 숨기'**
  String get phaseThiefHide;

  /// No description provided for @phaseThiefHideDesc.
  ///
  /// In ko, this message translates to:
  /// **'도둑이 먼저 흩어집니다'**
  String get phaseThiefHideDesc;

  /// No description provided for @phasePursuit.
  ///
  /// In ko, this message translates to:
  /// **'추격 시작'**
  String get phasePursuit;

  /// No description provided for @phasePursuitDesc.
  ///
  /// In ko, this message translates to:
  /// **'경찰이 도둑을 잡으러 갑니다'**
  String get phasePursuitDesc;

  /// No description provided for @phaseGameEnd.
  ///
  /// In ko, this message translates to:
  /// **'게임 종료'**
  String get phaseGameEnd;

  /// No description provided for @phaseGameEndCopsDesc.
  ///
  /// In ko, this message translates to:
  /// **'타이머 종료 또는 전원 체포 시'**
  String get phaseGameEndCopsDesc;

  /// No description provided for @phaseGameEndFreezeDesc.
  ///
  /// In ko, this message translates to:
  /// **'타이머 종료 또는 전원 얼음 시'**
  String get phaseGameEndFreezeDesc;

  /// No description provided for @phaseGameEndHideDesc.
  ///
  /// In ko, this message translates to:
  /// **'타이머 종료 또는 전원 발견 시'**
  String get phaseGameEndHideDesc;

  /// No description provided for @phaseGameEndFlagDesc.
  ///
  /// In ko, this message translates to:
  /// **'목표 점수 달성 또는 타이머 종료'**
  String get phaseGameEndFlagDesc;

  /// No description provided for @phasePrep.
  ///
  /// In ko, this message translates to:
  /// **'준비'**
  String get phasePrep;

  /// No description provided for @phasePrepDesc.
  ///
  /// In ko, this message translates to:
  /// **'도망자가 흩어집니다'**
  String get phasePrepDesc;

  /// No description provided for @phaseGameStart.
  ///
  /// In ko, this message translates to:
  /// **'게임 시작'**
  String get phaseGameStart;

  /// No description provided for @phaseGameStartFreezeDesc.
  ///
  /// In ko, this message translates to:
  /// **'술래가 \"얼음땡!\" 외치고 시작'**
  String get phaseGameStartFreezeDesc;

  /// No description provided for @phaseHide.
  ///
  /// In ko, this message translates to:
  /// **'숨기'**
  String get phaseHide;

  /// No description provided for @phaseHideDesc.
  ///
  /// In ko, this message translates to:
  /// **'술래가 눈 감고 세는 동안 숨기'**
  String get phaseHideDesc;

  /// No description provided for @phaseFindStart.
  ///
  /// In ko, this message translates to:
  /// **'찾기 시작'**
  String get phaseFindStart;

  /// No description provided for @phaseFindStartDesc.
  ///
  /// In ko, this message translates to:
  /// **'술래가 숨은 사람을 찾습니다'**
  String get phaseFindStartDesc;

  /// No description provided for @phaseTeamConfirm.
  ///
  /// In ko, this message translates to:
  /// **'팀 확인'**
  String get phaseTeamConfirm;

  /// No description provided for @phaseTeamConfirmDesc.
  ///
  /// In ko, this message translates to:
  /// **'A팀/B팀 진영을 확인하세요'**
  String get phaseTeamConfirmDesc;

  /// No description provided for @phaseFlagPlace.
  ///
  /// In ko, this message translates to:
  /// **'깃발 배치'**
  String get phaseFlagPlace;

  /// No description provided for @phaseFlagPlaceDesc.
  ///
  /// In ko, this message translates to:
  /// **'각 팀 진영에 깃발을 배치합니다'**
  String get phaseFlagPlaceDesc;

  /// No description provided for @phaseFlagStart.
  ///
  /// In ko, this message translates to:
  /// **'상대 깃발을 가져오세요!'**
  String get phaseFlagStart;

  /// No description provided for @preferenceNone.
  ///
  /// In ko, this message translates to:
  /// **'상관없음'**
  String get preferenceNone;

  /// No description provided for @preferenceRole1.
  ///
  /// In ko, this message translates to:
  /// **'{role} 희망'**
  String preferenceRole1(String role);

  /// No description provided for @teamBalanced.
  ///
  /// In ko, this message translates to:
  /// **'팀이 균형잡혀 있습니다. 바로 시작할 수 있어요!'**
  String get teamBalanced;

  /// No description provided for @teamNoneWillBeRandom.
  ///
  /// In ko, this message translates to:
  /// **'상관없음 인원이 랜덤 배치됩니다.'**
  String get teamNoneWillBeRandom;

  /// No description provided for @teamExcess.
  ///
  /// In ko, this message translates to:
  /// **'{role} 희망자가 {count}명 초과입니다. {count}명이 랜덤으로 {otherRole}이 됩니다.'**
  String teamExcess(String role, int count, String otherRole);

  /// No description provided for @teamNeedsAdjust.
  ///
  /// In ko, this message translates to:
  /// **'{role} 희망자가 {count}명 초과입니다. 협의 후 조정하거나 그대로 시작할 수 있어요.'**
  String teamNeedsAdjust(String role, int count);

  /// No description provided for @teamUnbalanced.
  ///
  /// In ko, this message translates to:
  /// **'팀 구성이 불균형합니다. 조정하거나 그대로 시작할 수 있어요.'**
  String get teamUnbalanced;

  /// No description provided for @localRulePrisonLocation.
  ///
  /// In ko, this message translates to:
  /// **'감옥 위치'**
  String get localRulePrisonLocation;

  /// No description provided for @localRulePrisonLocationDesc.
  ///
  /// In ko, this message translates to:
  /// **'잡힌 도둑이 대기하는 장소'**
  String get localRulePrisonLocationDesc;

  /// No description provided for @localRuleJailBreak.
  ///
  /// In ko, this message translates to:
  /// **'탈옥 허용'**
  String get localRuleJailBreak;

  /// No description provided for @localRuleJailBreakDesc.
  ///
  /// In ko, this message translates to:
  /// **'동료 도둑이 감옥 터치로 구출 가능'**
  String get localRuleJailBreakDesc;

  /// No description provided for @localRuleBoundary.
  ///
  /// In ko, this message translates to:
  /// **'경계 설정'**
  String get localRuleBoundary;

  /// No description provided for @localRuleBoundaryDesc.
  ///
  /// In ko, this message translates to:
  /// **'게임 영역 제한'**
  String get localRuleBoundaryDesc;

  /// No description provided for @localRuleSafeZone.
  ///
  /// In ko, this message translates to:
  /// **'안전지대 금지'**
  String get localRuleSafeZone;

  /// No description provided for @localRuleSafeZoneDesc.
  ///
  /// In ko, this message translates to:
  /// **'안전지대 없이 진행'**
  String get localRuleSafeZoneDesc;

  /// No description provided for @localRuleTagMethod.
  ///
  /// In ko, this message translates to:
  /// **'터치 방식'**
  String get localRuleTagMethod;

  /// No description provided for @localRuleTagMethodDesc.
  ///
  /// In ko, this message translates to:
  /// **'양손 터치/한손 터치/어깨 터치'**
  String get localRuleTagMethodDesc;

  /// No description provided for @localRuleFreezeRelease.
  ///
  /// In ko, this message translates to:
  /// **'얼음 해제'**
  String get localRuleFreezeRelease;

  /// No description provided for @localRuleFreezeReleaseDesc.
  ///
  /// In ko, this message translates to:
  /// **'동료가 터치하면 해제'**
  String get localRuleFreezeReleaseDesc;

  /// No description provided for @localRuleSeekerCount.
  ///
  /// In ko, this message translates to:
  /// **'술래 수 조정'**
  String get localRuleSeekerCount;

  /// No description provided for @localRuleSeekerCountDesc.
  ///
  /// In ko, this message translates to:
  /// **'인원에 따라 술래 수 조절'**
  String get localRuleSeekerCountDesc;

  /// No description provided for @localRuleHidingTime.
  ///
  /// In ko, this message translates to:
  /// **'숨는 시간'**
  String get localRuleHidingTime;

  /// No description provided for @localRuleHidingTimeDesc.
  ///
  /// In ko, this message translates to:
  /// **'술래가 세는 시간 (예: 30초)'**
  String get localRuleHidingTimeDesc;

  /// No description provided for @localRuleHintAllowed.
  ///
  /// In ko, this message translates to:
  /// **'힌트 허용'**
  String get localRuleHintAllowed;

  /// No description provided for @localRuleHintAllowedDesc.
  ///
  /// In ko, this message translates to:
  /// **'숨은 사람이 소리로 힌트 가능'**
  String get localRuleHintAllowedDesc;

  /// No description provided for @localRuleFlagReturn.
  ///
  /// In ko, this message translates to:
  /// **'깃발 반환'**
  String get localRuleFlagReturn;

  /// No description provided for @localRuleFlagReturnDesc.
  ///
  /// In ko, this message translates to:
  /// **'터치당하면 깃발 제자리 반환'**
  String get localRuleFlagReturnDesc;

  /// No description provided for @localRuleTeamTag.
  ///
  /// In ko, this message translates to:
  /// **'팀 터치'**
  String get localRuleTeamTag;

  /// No description provided for @localRuleTeamTagDesc.
  ///
  /// In ko, this message translates to:
  /// **'상대 진영에서 터치당하면 감옥'**
  String get localRuleTeamTagDesc;

  /// No description provided for @joinWithCode.
  ///
  /// In ko, this message translates to:
  /// **'코드로 참가'**
  String get joinWithCode;

  /// No description provided for @enterJoinCode.
  ///
  /// In ko, this message translates to:
  /// **'참가 코드 입력'**
  String get enterJoinCode;

  /// No description provided for @joinCodeHint.
  ///
  /// In ko, this message translates to:
  /// **'6자리 코드'**
  String get joinCodeHint;

  /// No description provided for @joinCodeInvalid.
  ///
  /// In ko, this message translates to:
  /// **'6자리 코드를 입력해주세요'**
  String get joinCodeInvalid;

  /// No description provided for @joinCodeNotFound.
  ///
  /// In ko, this message translates to:
  /// **'모임을 찾을 수 없습니다'**
  String get joinCodeNotFound;

  /// No description provided for @join.
  ///
  /// In ko, this message translates to:
  /// **'참가'**
  String get join;

  /// No description provided for @search.
  ///
  /// In ko, this message translates to:
  /// **'검색'**
  String get search;

  /// No description provided for @searchMeetings.
  ///
  /// In ko, this message translates to:
  /// **'모임 검색...'**
  String get searchMeetings;

  /// No description provided for @filterTimeAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get filterTimeAll;

  /// No description provided for @filterTimeToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get filterTimeToday;

  /// No description provided for @filterTimeTomorrow.
  ///
  /// In ko, this message translates to:
  /// **'내일'**
  String get filterTimeTomorrow;

  /// No description provided for @filterTimeThisWeek.
  ///
  /// In ko, this message translates to:
  /// **'이번 주'**
  String get filterTimeThisWeek;

  /// No description provided for @showRecruitingOnly.
  ///
  /// In ko, this message translates to:
  /// **'모집중만'**
  String get showRecruitingOnly;

  /// No description provided for @showAll.
  ///
  /// In ko, this message translates to:
  /// **'전체 보기'**
  String get showAll;

  /// No description provided for @activeFilters.
  ///
  /// In ko, this message translates to:
  /// **'필터 {count}개 적용중'**
  String activeFilters(int count);

  /// No description provided for @clearFilters.
  ///
  /// In ko, this message translates to:
  /// **'필터 초기화'**
  String get clearFilters;

  /// No description provided for @filterTitle.
  ///
  /// In ko, this message translates to:
  /// **'필터'**
  String get filterTitle;

  /// No description provided for @applyFilters.
  ///
  /// In ko, this message translates to:
  /// **'적용하기'**
  String get applyFilters;

  /// No description provided for @resetFilters.
  ///
  /// In ko, this message translates to:
  /// **'초기화'**
  String get resetFilters;

  /// No description provided for @filterRegion.
  ///
  /// In ko, this message translates to:
  /// **'지역'**
  String get filterRegion;

  /// No description provided for @regionAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get regionAll;

  /// No description provided for @regionSeoul.
  ///
  /// In ko, this message translates to:
  /// **'서울'**
  String get regionSeoul;

  /// No description provided for @regionGyeonggi.
  ///
  /// In ko, this message translates to:
  /// **'경기'**
  String get regionGyeonggi;

  /// No description provided for @regionIncheon.
  ///
  /// In ko, this message translates to:
  /// **'인천'**
  String get regionIncheon;

  /// No description provided for @regionBusan.
  ///
  /// In ko, this message translates to:
  /// **'부산'**
  String get regionBusan;

  /// No description provided for @regionDaegu.
  ///
  /// In ko, this message translates to:
  /// **'대구'**
  String get regionDaegu;

  /// No description provided for @regionDaejeon.
  ///
  /// In ko, this message translates to:
  /// **'대전'**
  String get regionDaejeon;

  /// No description provided for @regionGwangju.
  ///
  /// In ko, this message translates to:
  /// **'광주'**
  String get regionGwangju;

  /// No description provided for @regionUlsan.
  ///
  /// In ko, this message translates to:
  /// **'울산'**
  String get regionUlsan;

  /// No description provided for @regionSejong.
  ///
  /// In ko, this message translates to:
  /// **'세종'**
  String get regionSejong;

  /// No description provided for @regionGangwon.
  ///
  /// In ko, this message translates to:
  /// **'강원'**
  String get regionGangwon;

  /// No description provided for @regionChungbuk.
  ///
  /// In ko, this message translates to:
  /// **'충북'**
  String get regionChungbuk;

  /// No description provided for @regionChungnam.
  ///
  /// In ko, this message translates to:
  /// **'충남'**
  String get regionChungnam;

  /// No description provided for @regionJeonbuk.
  ///
  /// In ko, this message translates to:
  /// **'전북'**
  String get regionJeonbuk;

  /// No description provided for @regionJeonnam.
  ///
  /// In ko, this message translates to:
  /// **'전남'**
  String get regionJeonnam;

  /// No description provided for @regionGyeongbuk.
  ///
  /// In ko, this message translates to:
  /// **'경북'**
  String get regionGyeongbuk;

  /// No description provided for @regionGyeongnam.
  ///
  /// In ko, this message translates to:
  /// **'경남'**
  String get regionGyeongnam;

  /// No description provided for @regionJeju.
  ///
  /// In ko, this message translates to:
  /// **'제주'**
  String get regionJeju;

  /// No description provided for @filterAgeGroup.
  ///
  /// In ko, this message translates to:
  /// **'희망 연령대'**
  String get filterAgeGroup;

  /// No description provided for @ageGroupAll.
  ///
  /// In ko, this message translates to:
  /// **'상관없음'**
  String get ageGroupAll;

  /// No description provided for @ageGroupTeens.
  ///
  /// In ko, this message translates to:
  /// **'10대'**
  String get ageGroupTeens;

  /// No description provided for @ageGroupTwenties.
  ///
  /// In ko, this message translates to:
  /// **'20대'**
  String get ageGroupTwenties;

  /// No description provided for @ageGroupThirties.
  ///
  /// In ko, this message translates to:
  /// **'30대'**
  String get ageGroupThirties;

  /// No description provided for @ageGroupFortyPlus.
  ///
  /// In ko, this message translates to:
  /// **'40대 이상'**
  String get ageGroupFortyPlus;

  /// No description provided for @filterGroupSize.
  ///
  /// In ko, this message translates to:
  /// **'모집 인원'**
  String get filterGroupSize;

  /// No description provided for @groupSizeSmall.
  ///
  /// In ko, this message translates to:
  /// **'소규모 (4-8명)'**
  String get groupSizeSmall;

  /// No description provided for @groupSizeMedium.
  ///
  /// In ko, this message translates to:
  /// **'중규모 (9-15명)'**
  String get groupSizeMedium;

  /// No description provided for @groupSizeLarge.
  ///
  /// In ko, this message translates to:
  /// **'대규모 (16명+)'**
  String get groupSizeLarge;

  /// No description provided for @filterDifficulty.
  ///
  /// In ko, this message translates to:
  /// **'분위기'**
  String get filterDifficulty;

  /// No description provided for @difficultyCasual.
  ///
  /// In ko, this message translates to:
  /// **'가볍게'**
  String get difficultyCasual;

  /// No description provided for @difficultyCompetitive.
  ///
  /// In ko, this message translates to:
  /// **'진지하게'**
  String get difficultyCompetitive;

  /// No description provided for @difficultyBeginner.
  ///
  /// In ko, this message translates to:
  /// **'초보 환영'**
  String get difficultyBeginner;

  /// No description provided for @moreFilters.
  ///
  /// In ko, this message translates to:
  /// **'상세 필터'**
  String get moreFilters;

  /// No description provided for @buyCoffee.
  ///
  /// In ko, this message translates to:
  /// **'커피 한 잔 사주기'**
  String get buyCoffee;

  /// No description provided for @buyCoffeeDescription.
  ///
  /// In ko, this message translates to:
  /// **'개발자를 응원할 수 있어요'**
  String get buyCoffeeDescription;

  /// No description provided for @buyCoffeeButton.
  ///
  /// In ko, this message translates to:
  /// **'응원하기'**
  String get buyCoffeeButton;

  /// No description provided for @donationMessage.
  ///
  /// In ko, this message translates to:
  /// **'이 앱이 도움이 되었다면 선택적으로 응원할 수 있어요.\n광고 없는 버전이나 추가 기능과는 무관해요.'**
  String get donationMessage;

  /// No description provided for @donationThanks.
  ///
  /// In ko, this message translates to:
  /// **'감사합니다! 더 좋은 앱을 만들게요 ☕'**
  String get donationThanks;

  /// No description provided for @donationFailed.
  ///
  /// In ko, this message translates to:
  /// **'구매에 실패했어요. 나중에 다시 시도해주세요.'**
  String get donationFailed;

  /// No description provided for @donationHint.
  ///
  /// In ko, this message translates to:
  /// **'설정에서 \'커피 한 잔 사주기\'로 개발자를 응원할 수 있어요 ☕'**
  String get donationHint;

  /// No description provided for @shareMeeting.
  ///
  /// In ko, this message translates to:
  /// **'모임 공유하기'**
  String get shareMeeting;

  /// No description provided for @gatherPeople.
  ///
  /// In ko, this message translates to:
  /// **'사람 모으기'**
  String get gatherPeople;

  /// No description provided for @gatherPeopleDesc.
  ///
  /// In ko, this message translates to:
  /// **'초대 메시지를 만들어 공유하세요'**
  String get gatherPeopleDesc;

  /// No description provided for @whereToShare.
  ///
  /// In ko, this message translates to:
  /// **'어디서 공유할까요?'**
  String get whereToShare;

  /// No description provided for @messageStyle.
  ///
  /// In ko, this message translates to:
  /// **'메시지 스타일'**
  String get messageStyle;

  /// No description provided for @toneCasual.
  ///
  /// In ko, this message translates to:
  /// **'편하게'**
  String get toneCasual;

  /// No description provided for @toneCasualDesc.
  ///
  /// In ko, this message translates to:
  /// **'친구들에게'**
  String get toneCasualDesc;

  /// No description provided for @toneEnthusiastic.
  ///
  /// In ko, this message translates to:
  /// **'활기차게'**
  String get toneEnthusiastic;

  /// No description provided for @toneEnthusiasticDesc.
  ///
  /// In ko, this message translates to:
  /// **'동네 모집'**
  String get toneEnthusiasticDesc;

  /// No description provided for @chatLinkOptional.
  ///
  /// In ko, this message translates to:
  /// **'채팅방 링크 (선택)'**
  String get chatLinkOptional;

  /// No description provided for @chatLinkHint.
  ///
  /// In ko, this message translates to:
  /// **'오픈채팅 링크를 넣으면 메시지에 포함됩니다'**
  String get chatLinkHint;

  /// No description provided for @preview.
  ///
  /// In ko, this message translates to:
  /// **'미리보기'**
  String get preview;

  /// No description provided for @copyMessage.
  ///
  /// In ko, this message translates to:
  /// **'메시지 복사하기'**
  String get copyMessage;

  /// No description provided for @messageCopied.
  ///
  /// In ko, this message translates to:
  /// **'초대 메시지가 복사되었습니다'**
  String get messageCopied;

  /// No description provided for @copyAndPasteHint.
  ///
  /// In ko, this message translates to:
  /// **'복사 후 카카오톡이나 SNS에 붙여넣기 하세요'**
  String get copyAndPasteHint;

  /// No description provided for @joinCode.
  ///
  /// In ko, this message translates to:
  /// **'참가코드'**
  String get joinCode;

  /// No description provided for @joinCodeCopied.
  ///
  /// In ko, this message translates to:
  /// **'참가코드가 복사되었습니다'**
  String get joinCodeCopied;

  /// No description provided for @copyCode.
  ///
  /// In ko, this message translates to:
  /// **'코드 복사'**
  String get copyCode;

  /// No description provided for @qrCode.
  ///
  /// In ko, this message translates to:
  /// **'QR 코드'**
  String get qrCode;

  /// No description provided for @showToFriends.
  ///
  /// In ko, this message translates to:
  /// **'친구에게 이 화면을 보여주세요'**
  String get showToFriends;

  /// No description provided for @externalChatLink.
  ///
  /// In ko, this message translates to:
  /// **'외부 채팅방 링크'**
  String get externalChatLink;

  /// No description provided for @externalChatLinkHint.
  ///
  /// In ko, this message translates to:
  /// **'카카오 오픈채팅 등 외부 채팅방 URL'**
  String get externalChatLinkHint;

  /// No description provided for @goToChatroom.
  ///
  /// In ko, this message translates to:
  /// **'채팅방 바로가기'**
  String get goToChatroom;

  /// No description provided for @channelKakao.
  ///
  /// In ko, this message translates to:
  /// **'카카오톡'**
  String get channelKakao;

  /// No description provided for @channelOpenChat.
  ///
  /// In ko, this message translates to:
  /// **'오픈채팅'**
  String get channelOpenChat;

  /// No description provided for @channelInstagram.
  ///
  /// In ko, this message translates to:
  /// **'인스타그램'**
  String get channelInstagram;

  /// No description provided for @channelCommunity.
  ///
  /// In ko, this message translates to:
  /// **'커뮤니티'**
  String get channelCommunity;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
