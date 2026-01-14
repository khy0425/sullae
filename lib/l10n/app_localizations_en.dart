// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Sullae';

  @override
  String get appTagline => 'Let\'s play together!';

  @override
  String get navExplore => 'Explore';

  @override
  String get navMyMeetings => 'My Games';

  @override
  String get navProfile => 'Profile';

  @override
  String get createMeeting => 'Create Game';

  @override
  String get gameType => 'Game Type';

  @override
  String get meetingTitle => 'Game Title';

  @override
  String get meetingTitleHint => 'e.g. Cops and Robbers at the Park!';

  @override
  String get meetingTitleRequired => 'Please enter a game title';

  @override
  String get meetingDescription => 'Description';

  @override
  String get meetingDescriptionHint => 'Describe your game';

  @override
  String get location => 'Location';

  @override
  String get locationHint => 'e.g. Central Park';

  @override
  String get locationRequired => 'Please enter a location';

  @override
  String get locationDetail => 'Detailed Location (optional)';

  @override
  String get locationDetailHint => 'e.g. Near the fountain';

  @override
  String get dateTime => 'Date & Time';

  @override
  String get maxParticipants => 'Max Players';

  @override
  String participantsUnit(int count) {
    return '$count players';
  }

  @override
  String get createMeetingFailed => 'Failed to create game';

  @override
  String get gameCopsAndRobbers => 'Cops and Robbers';

  @override
  String get gameFreezeTag => 'Freeze Tag';

  @override
  String get gameHideAndSeek => 'Hide and Seek';

  @override
  String get gameCaptureFlag => 'Capture the Flag';

  @override
  String get gameCustom => 'Custom';

  @override
  String get filterAll => 'All';

  @override
  String get noRecruitingMeetings => 'No games available';

  @override
  String get createNewMeeting => 'Create a new game!';

  @override
  String get noJoinedMeetings => 'No games joined';

  @override
  String gamesPlayedCount(int count) {
    return '$count games played';
  }

  @override
  String get statParticipation => 'Played';

  @override
  String get statHosting => 'Hosted';

  @override
  String get statMvp => 'MVP';

  @override
  String get changeNickname => 'Change Nickname';

  @override
  String get newNickname => 'New Nickname';

  @override
  String get notificationSettings => 'Notifications';

  @override
  String get help => 'Help';

  @override
  String get logout => 'Logout';

  @override
  String get cancel => 'Cancel';

  @override
  String get change => 'Change';

  @override
  String get ok => 'OK';

  @override
  String get no => 'No';

  @override
  String get complete => 'Complete';

  @override
  String get later => 'Later';

  @override
  String get loginWithKakao => 'Continue with Kakao';

  @override
  String get loginWithGoogle => 'Continue with Google';

  @override
  String get loginWithApple => 'Continue with Apple';

  @override
  String get termsNotice =>
      'By continuing, you agree to our Terms of Service\nand Privacy Policy.';

  @override
  String get nicknameSetup => 'Set Nickname';

  @override
  String get enterNickname => 'Enter your nickname';

  @override
  String get nicknameGuide => 'Choose a name\nfor the game';

  @override
  String get nicknameHint => '2-10 characters';

  @override
  String get nicknameFormat => 'Letters and numbers, 2-10 characters';

  @override
  String get nicknameRequired => 'Please enter a nickname';

  @override
  String get nicknameTooShort => 'At least 2 characters';

  @override
  String get nicknameTooLong => 'Maximum 10 characters';

  @override
  String get nicknameInvalid => 'Letters and numbers only';

  @override
  String get checkingDuplicate => 'Checking availability...';

  @override
  String get nicknameAvailable => 'This nickname is available!';

  @override
  String get startGame => 'Let\'s Play!';

  @override
  String get selectAgeGroup => 'Select Age Group';

  @override
  String get ageGuide => 'Tell us your age group';

  @override
  String get ageGroupOptional =>
      'Optional. Used for better game recommendations.';

  @override
  String get ageMatchingHelp =>
      'Helps match with similar age groups\n(You can skip this)';

  @override
  String get ageGroup10s => 'Teens';

  @override
  String get ageGroup20s => '20s';

  @override
  String get ageGroup30s => '30s';

  @override
  String get ageGroup40sPlus => '40s+';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get startPrivately => 'Start Privately';

  @override
  String get signupFailed => 'Sign up failed. Please try again.';

  @override
  String get gameTime => 'Game Time';

  @override
  String minutesUnit(int count) {
    return '$count min';
  }

  @override
  String get teamAssignment => 'Team Assignment';

  @override
  String get shuffleTeamHint => 'Tap shuffle to assign teams';

  @override
  String get startGameButton => 'Start Game';

  @override
  String get remainingTime => 'Time Remaining';

  @override
  String get shuffleTeam => 'Shuffle';

  @override
  String get endGame => 'End Game';

  @override
  String get gameEndTitle => 'Game Over!';

  @override
  String get endGameConfirmTitle => 'End game?';

  @override
  String get endGameConfirmMessage => 'This will end the current game.';

  @override
  String get mvpVoteConfirm => 'Start MVP voting?';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get paused => 'PAUSED';

  @override
  String get tapToPause => 'Tap to pause';

  @override
  String get tapToResume => 'Tap to resume';

  @override
  String get mvpVoteButton => 'MVP Vote';

  @override
  String get mvpVoteCreated => 'MVP vote has been created!';

  @override
  String get roleCops => 'Cops';

  @override
  String get roleRobbers => 'Robbers';

  @override
  String get roleSeeker => 'Seeker';

  @override
  String get roleRunner => 'Runner';

  @override
  String get roleHider => 'Hider';

  @override
  String get roleTeamA => 'Team A';

  @override
  String get roleTeamB => 'Team B';

  @override
  String get meetingChat => 'Chat';

  @override
  String get meetingInfo => 'Info';

  @override
  String get meetingParticipants => 'Players';

  @override
  String get meetingHost => 'Host';

  @override
  String get meetingStatus => 'Status';

  @override
  String get meetingStatusRecruiting => 'Open';

  @override
  String get meetingStatusInProgress => 'In Progress';

  @override
  String get meetingStatusFinished => 'Finished';

  @override
  String get joinMeeting => 'Join';

  @override
  String get leaveMeeting => 'Leave';

  @override
  String get cancelMeeting => 'Cancel Game';

  @override
  String get cancelMeetingConfirm =>
      'Are you sure you want to cancel this game?';

  @override
  String get cancelMeetingButton => 'Cancel Game';

  @override
  String get startMeeting => 'Start Game';

  @override
  String get joinedMeeting => 'You joined the game!';

  @override
  String get noMessages => 'No messages yet';

  @override
  String get quickMessageArrived => 'I\'m here!';

  @override
  String get quickMessageLate5 => '5 min late';

  @override
  String get quickMessageLate10 => '10 min late';

  @override
  String get quickMessageReady => 'Ready to play!';

  @override
  String get quickMessageOnMyWay => 'On my way';

  @override
  String get quickMessageCantMake => 'Can\'t make it today';

  @override
  String get quickMessageWhereAreYou => 'Where are you?';

  @override
  String get quickMessageStartSoon => 'Starting soon';

  @override
  String get enterMessage => 'Type a message...';

  @override
  String get send => 'Send';

  @override
  String get systemSender => 'System';

  @override
  String get meetingCreated => 'Game created.';

  @override
  String get meetingCancelled => 'Game cancelled.';

  @override
  String get gameStarted => 'Game has started!';

  @override
  String userJoined(String nickname) {
    return '$nickname joined.';
  }

  @override
  String userLeft(String nickname) {
    return '$nickname left.';
  }

  @override
  String get phaseRoleConfirm => 'Check Roles';

  @override
  String get phaseRoleConfirmCopsDesc => 'Check your Cop/Robber role';

  @override
  String get phaseRoleConfirmSeekerDesc => 'Check your Seeker/Runner role';

  @override
  String get phaseRoleConfirmHiderDesc => 'Check your Seeker/Hider role';

  @override
  String get phasePrisonConfirm => 'Check Jail Location';

  @override
  String get phasePrisonConfirmDesc => 'Everyone confirms the jail location';

  @override
  String get phaseThiefHide => 'Robbers Scatter';

  @override
  String get phaseThiefHideDesc => 'Robbers spread out first';

  @override
  String get phasePursuit => 'Chase Begins';

  @override
  String get phasePursuitDesc => 'Cops go catch the robbers';

  @override
  String get phaseGameEnd => 'Game End';

  @override
  String get phaseGameEndCopsDesc => 'Timer ends or all caught';

  @override
  String get phaseGameEndFreezeDesc => 'Timer ends or all frozen';

  @override
  String get phaseGameEndHideDesc => 'Timer ends or all found';

  @override
  String get phaseGameEndFlagDesc => 'Target score or timer ends';

  @override
  String get phasePrep => 'Prepare';

  @override
  String get phasePrepDesc => 'Runners scatter';

  @override
  String get phaseGameStart => 'Game Start';

  @override
  String get phaseGameStartFreezeDesc => 'Seeker yells \"Freeze!\" and starts';

  @override
  String get phaseHide => 'Hide';

  @override
  String get phaseHideDesc => 'Hide while seeker counts';

  @override
  String get phaseFindStart => 'Seek Begins';

  @override
  String get phaseFindStartDesc => 'Seeker looks for hiders';

  @override
  String get phaseTeamConfirm => 'Check Teams';

  @override
  String get phaseTeamConfirmDesc => 'Check Team A/B territories';

  @override
  String get phaseFlagPlace => 'Place Flags';

  @override
  String get phaseFlagPlaceDesc => 'Place flags in each team\'s territory';

  @override
  String get phaseFlagStart => 'Capture the opponent\'s flag!';

  @override
  String get preferenceNone => 'No preference';

  @override
  String preferenceRole1(String role) {
    return 'Prefer $role';
  }

  @override
  String get teamBalanced => 'Teams are balanced. Ready to start!';

  @override
  String get teamNoneWillBeRandom =>
      'No-preference players will be randomly assigned.';

  @override
  String teamExcess(String role, int count, String otherRole) {
    return '$count extra $role players. $count will be randomly assigned to $otherRole.';
  }

  @override
  String teamNeedsAdjust(String role, int count) {
    return '$count extra $role players. Discuss adjustments or start as is.';
  }

  @override
  String get teamUnbalanced => 'Teams are unbalanced. Adjust or start as is.';

  @override
  String get localRulePrisonLocation => 'Jail Location';

  @override
  String get localRulePrisonLocationDesc => 'Where caught robbers wait';

  @override
  String get localRuleJailBreak => 'Jail Break Allowed';

  @override
  String get localRuleJailBreakDesc => 'Teammates can rescue by touching jail';

  @override
  String get localRuleBoundary => 'Boundary';

  @override
  String get localRuleBoundaryDesc => 'Game area limits';

  @override
  String get localRuleSafeZone => 'No Safe Zone';

  @override
  String get localRuleSafeZoneDesc => 'Play without safe zones';

  @override
  String get localRuleTagMethod => 'Tag Method';

  @override
  String get localRuleTagMethodDesc => 'Two-hand/one-hand/shoulder tag';

  @override
  String get localRuleFreezeRelease => 'Unfreeze';

  @override
  String get localRuleFreezeReleaseDesc => 'Teammate touch to unfreeze';

  @override
  String get localRuleSeekerCount => 'Seeker Count';

  @override
  String get localRuleSeekerCountDesc => 'Adjust seekers based on players';

  @override
  String get localRuleHidingTime => 'Hiding Time';

  @override
  String get localRuleHidingTimeDesc => 'Count time (e.g. 30 seconds)';

  @override
  String get localRuleHintAllowed => 'Hints Allowed';

  @override
  String get localRuleHintAllowedDesc => 'Hiders can make sounds as hints';

  @override
  String get localRuleFlagReturn => 'Flag Return';

  @override
  String get localRuleFlagReturnDesc => 'Flag returns to base when tagged';

  @override
  String get localRuleTeamTag => 'Team Tag';

  @override
  String get localRuleTeamTagDesc => 'Tagged in enemy territory goes to jail';

  @override
  String get joinWithCode => 'Join with Code';

  @override
  String get enterJoinCode => 'Enter Join Code';

  @override
  String get joinCodeHint => '6-digit code';

  @override
  String get joinCodeInvalid => 'Please enter a 6-digit code';

  @override
  String get joinCodeNotFound => 'Game not found';

  @override
  String get join => 'Join';

  @override
  String get search => 'Search';

  @override
  String get searchMeetings => 'Search games...';

  @override
  String get filterTimeAll => 'All';

  @override
  String get filterTimeToday => 'Today';

  @override
  String get filterTimeTomorrow => 'Tomorrow';

  @override
  String get filterTimeThisWeek => 'This Week';

  @override
  String get showRecruitingOnly => 'Open Only';

  @override
  String get showAll => 'Show All';

  @override
  String activeFilters(int count) {
    return '$count filters active';
  }

  @override
  String get clearFilters => 'Clear Filters';

  @override
  String get filterTitle => 'Filters';

  @override
  String get applyFilters => 'Apply';

  @override
  String get resetFilters => 'Reset';

  @override
  String get filterRegion => 'Region';

  @override
  String get regionAll => 'All';

  @override
  String get regionSeoul => 'Seoul';

  @override
  String get regionGyeonggi => 'Gyeonggi';

  @override
  String get regionIncheon => 'Incheon';

  @override
  String get regionBusan => 'Busan';

  @override
  String get regionDaegu => 'Daegu';

  @override
  String get regionDaejeon => 'Daejeon';

  @override
  String get regionGwangju => 'Gwangju';

  @override
  String get regionUlsan => 'Ulsan';

  @override
  String get regionSejong => 'Sejong';

  @override
  String get regionGangwon => 'Gangwon';

  @override
  String get regionChungbuk => 'Chungbuk';

  @override
  String get regionChungnam => 'Chungnam';

  @override
  String get regionJeonbuk => 'Jeonbuk';

  @override
  String get regionJeonnam => 'Jeonnam';

  @override
  String get regionGyeongbuk => 'Gyeongbuk';

  @override
  String get regionGyeongnam => 'Gyeongnam';

  @override
  String get regionJeju => 'Jeju';

  @override
  String get filterAgeGroup => 'Age Group';

  @override
  String get ageGroupAll => 'Any';

  @override
  String get ageGroupTeens => 'Teens';

  @override
  String get ageGroupTwenties => '20s';

  @override
  String get ageGroupThirties => '30s';

  @override
  String get ageGroupFortyPlus => '40s+';

  @override
  String get filterGroupSize => 'Group Size';

  @override
  String get groupSizeSmall => 'Small (4-8)';

  @override
  String get groupSizeMedium => 'Medium (9-15)';

  @override
  String get groupSizeLarge => 'Large (16+)';

  @override
  String get filterDifficulty => 'Atmosphere';

  @override
  String get difficultyCasual => 'Casual';

  @override
  String get difficultyCompetitive => 'Competitive';

  @override
  String get difficultyBeginner => 'Beginner Friendly';

  @override
  String get moreFilters => 'More Filters';

  @override
  String get buyCoffee => 'Buy Coffee for Developer';

  @override
  String get buyCoffeeDescription => 'Support the developer';

  @override
  String get buyCoffeeButton => 'Support';

  @override
  String get donationMessage =>
      'If this app was helpful, you can optionally support the developer.\nThis is not related to ads or extra features.';

  @override
  String get donationThanks => 'Thank you! I\'ll make an even better app ☕';

  @override
  String get donationFailed => 'Purchase failed. Please try again later.';

  @override
  String get donationHint =>
      'You can support the developer with \'Buy Coffee\' in Settings ☕';

  @override
  String get shareMeeting => 'Share Game';

  @override
  String get gatherPeople => 'Gather People';

  @override
  String get gatherPeopleDesc => 'Create and share an invite message';

  @override
  String get whereToShare => 'Where will you share?';

  @override
  String get messageStyle => 'Message Style';

  @override
  String get toneCasual => 'Casual';

  @override
  String get toneCasualDesc => 'For friends';

  @override
  String get toneEnthusiastic => 'Enthusiastic';

  @override
  String get toneEnthusiasticDesc => 'Community posting';

  @override
  String get chatLinkOptional => 'Chat Link (optional)';

  @override
  String get chatLinkHint => 'Add a chat link to include it in the message';

  @override
  String get preview => 'Preview';

  @override
  String get copyMessage => 'Copy Message';

  @override
  String get messageCopied => 'Invite message copied';

  @override
  String get copyAndPasteHint =>
      'Paste this in your messaging app or social media';

  @override
  String get joinCode => 'Join Code';

  @override
  String get joinCodeCopied => 'Join code copied';

  @override
  String get copyCode => 'Copy Code';

  @override
  String get qrCode => 'QR Code';

  @override
  String get showToFriends => 'Show this to your friends';

  @override
  String get externalChatLink => 'External Chat Link';

  @override
  String get externalChatLinkHint =>
      'URL for external chat room (e.g. Discord)';

  @override
  String get goToChatroom => 'Go to Chatroom';

  @override
  String get channelKakao => 'KakaoTalk';

  @override
  String get channelOpenChat => 'Open Chat';

  @override
  String get channelInstagram => 'Instagram';

  @override
  String get channelCommunity => 'Community';
}
