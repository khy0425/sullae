import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/meeting_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/ad_service.dart';
import '../../services/donation_service.dart';
import '../../services/game_service.dart';
import '../../services/vote_service.dart';
import '../../utils/app_theme.dart';

class GameScreen extends StatefulWidget {
  final MeetingModel meeting;

  const GameScreen({super.key, required this.meeting});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final GameService _gameService = GameService();
  final VoteService _voteService = VoteService();

  List<TeamAssignment>? _teamAssignments;
  List<ParticipantWithPreference> _participantsWithPreference = [];
  TeamBalanceResult? _balanceResult;
  bool _isGameStarted = false;
  bool _showRoleSelection = true; // 역할 선택 화면 표시 여부
  bool _showTeamStatus = false; // 팀 상태 표시 여부
  int _timerSeconds = 600; // 10분 기본
  Timer? _timer;
  String? _sessionId;

  // 라운드 관리
  int _currentRound = 1;
  int _totalRounds = 3; // 기본 3라운드

  @override
  void initState() {
    super.initState();
    _initParticipants();
  }

  void _initParticipants() {
    // 참가자 목록 초기화 (모두 상관없음으로 시작)
    _participantsWithPreference = widget.meeting.participantIds
        .asMap()
        .entries
        .map((e) => ParticipantWithPreference(
              odId: e.value,
              nickname: e.key == 0
                  ? widget.meeting.hostNickname
                  : '참가자 ${e.key + 1}',
              preference: RolePreference.none,
            ))
        .toList();
    _updateBalanceResult();
  }

  void _updateBalanceResult() {
    _balanceResult = _gameService.checkTeamBalance(
      participants: _participantsWithPreference,
      gameType: widget.meeting.gameType,
    );
  }

  void _updatePreference(String odId, RolePreference preference) {
    setState(() {
      final index = _participantsWithPreference.indexWhere((p) => p.odId == odId);
      if (index != -1) {
        _participantsWithPreference[index] = _participantsWithPreference[index].copyWith(
          preference: preference,
        );
        _updateBalanceResult();
      }
    });
  }

  void _proceedToTeamAssignment() {
    setState(() {
      _showRoleSelection = false;
      _teamAssignments = _gameService.assignTeamsWithPreference(
        participants: _participantsWithPreference,
        gameType: widget.meeting.gameType,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _assignTeams() {
    setState(() {
      _teamAssignments = _gameService.assignTeamsWithPreference(
        participants: _participantsWithPreference,
        gameType: widget.meeting.gameType,
      );
    });
  }

  void _startGame() async {
    if (_teamAssignments == null) return;

    try {
      // 로딩 상태 표시
      setState(() {
        _isGameStarted = true; // 일단 화면 전환
      });

      final sessionId = await _gameService.startGameSession(
        meetingId: widget.meeting.id,
        gameType: widget.meeting.gameType,
        teams: _teamAssignments!,
        durationMinutes: _timerSeconds ~/ 60,
      );

      if (!mounted) return;

      // 게임 시작 진동 (강하게 2번)
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 200));
      HapticFeedback.heavyImpact();

      setState(() {
        _sessionId = sessionId;
      });

      _startTimer();
    } catch (e) {
      // 에러 발생 시 원래 상태로 복구
      if (mounted) {
        setState(() {
          _isGameStarted = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('게임 시작 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        setState(() => _timerSeconds--);
        // 타이머 알림 진동
        _checkTimerVibration();
      } else {
        _endGame();
      }
    });
  }

  /// 타이머 진동 알림 체크
  void _checkTimerVibration() {
    switch (_timerSeconds) {
      case 300: // 5분 남음
        HapticFeedback.mediumImpact();
        break;
      case 60: // 1분 남음
        HapticFeedback.heavyImpact();
        break;
      case 30: // 30초 남음
        HapticFeedback.heavyImpact();
        break;
      case 10: // 10초 남음
      case 9:
      case 8:
      case 7:
      case 6:
      case 5:
      case 4:
      case 3:
      case 2:
      case 1:
        HapticFeedback.lightImpact(); // 카운트다운 진동
        break;
    }
  }

  void _endGame() async {
    _timer?.cancel();

    // 진동 피드백 (게임 종료)
    HapticFeedback.heavyImpact();

    if (_sessionId != null) {
      try {
        await _gameService.endGameSession(_sessionId!);
      } catch (e) {
        // 세션 종료 실패해도 계속 진행
      }
    }

    if (!mounted) return;

    // 게임 종료 시 전면 광고 표시 (에러 무시)
    try {
      await AdService().showAdOnGameEnd();
    } catch (e) {
      // 광고 실패해도 계속 진행
    }

    if (!mounted) return;

    _showMvpVoteDialog();
  }

  void _showMvpVoteDialog() {
    final l10n = AppLocalizations.of(context)!;

    // 첫 게임 종료 시 도네이션 힌트 표시 (한 번만)
    _showDonationHintIfNeeded(l10n);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.gameEndTitle),
        content: Text(l10n.mvpVoteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.later),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startMvpVote();
            },
            child: Text(l10n.mvpVoteButton),
          ),
        ],
      ),
    );
  }

  /// 첫 게임 종료 시 도네이션 힌트 표시 (한 번만)
  Future<void> _showDonationHintIfNeeded(AppLocalizations l10n) async {
    final donationService = DonationService();
    final shouldShow = await donationService.shouldShowHint();

    if (shouldShow && mounted) {
      // 다이얼로그가 표시된 후 잠시 뒤에 토스트 표시
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.donationHint),
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });

      // 힌트 표시 완료 기록
      await donationService.markHintShown();
    }
  }

  void _startMvpVote() async {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.read<AuthProvider>();
    final participantNames = _teamAssignments
            ?.map((e) => e.odNickname)
            .toList() ??
        [];

    await _voteService.createMvpVote(
      meetingId: widget.meeting.id,
      creatorId: authProvider.userId,
      participantNames: participantNames,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.mvpVoteCreated)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 게임 시작 후: 풀스크린 타이머
    if (_isGameStarted) {
      return _buildFullscreenTimer();
    }

    // 역할 선택 화면
    if (_showRoleSelection) {
      return _buildRoleSelectionView();
    }

    // 게임 시작 전: 설정 화면
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.meeting.gameTypeName,
          style: AppTextStyles.titleSmall(context),
        ),
      ),
      body: _buildSetupView(),
    );
  }

  Widget _buildRoleSelectionView() {
    final l10n = AppLocalizations.of(context)!;
    final roleOptions = _gameService.getRoleOptions(widget.meeting.gameType);
    final role1Name = roleOptions[0].name;
    final role2Name = roleOptions[1].name;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.teamAssignment,
          style: AppTextStyles.titleSmall(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(AppDimens.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 안내 텍스트
            Card(
              child: Padding(
                padding: EdgeInsets.all(AppDimens.paddingM),
                child: Column(
                  children: [
                    Icon(
                      Icons.how_to_vote,
                      size: AppDimens.iconXL,
                      color: AppColors.primary,
                    ),
                    SizedBox(height: AppDimens.paddingS),
                    Text(
                      '희망하는 역할을 선택해주세요',
                      style: AppTextStyles.titleSmall(context),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppDimens.paddingXS),
                    Text(
                      '선택 결과에 따라 팀이 배정됩니다',
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: AppDimens.paddingM),

            // 참가자 역할 선택 리스트
            Expanded(
              child: ListView.builder(
                itemCount: _participantsWithPreference.length,
                itemBuilder: (context, index) {
                  final participant = _participantsWithPreference[index];
                  return _RoleSelectionTile(
                    participant: participant,
                    role1Name: role1Name,
                    role2Name: role2Name,
                    onPreferenceChanged: (preference) {
                      _updatePreference(participant.odId, preference);
                    },
                  );
                },
              ),
            ),

            // 팀 균형 상태
            if (_balanceResult != null) ...[
              Container(
                padding: EdgeInsets.all(AppDimens.paddingM),
                decoration: BoxDecoration(
                  color: _balanceResult!.isBalanced
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: AppDimens.cardBorderRadius,
                  border: Border.all(
                    color: _balanceResult!.isBalanced
                        ? AppColors.success.withValues(alpha: 0.3)
                        : AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _balanceResult!.isBalanced
                          ? Icons.check_circle_outline
                          : Icons.info_outline,
                      color: _balanceResult!.isBalanced
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                    SizedBox(width: AppDimens.paddingS),
                    Expanded(
                      child: Text(
                        _balanceResult!.message,
                        style: AppTextStyles.bodySmall(context),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppDimens.paddingM),
            ],

            // 다음 버튼
            ElevatedButton(
              onPressed: _proceedToTeamAssignment,
              child: Text(
                l10n.next,
                style: AppTextStyles.labelLarge(context).copyWith(
                  color: AppColors.textOnPrimary,
                ),
              ),
            ),
            SizedBox(height: AppDimens.paddingM),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupView() {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.all(AppDimens.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timer Setting
          Card(
            child: Padding(
              padding: EdgeInsets.all(AppDimens.paddingL),
              child: Column(
                children: [
                  Text(
                    l10n.gameTime,
                    style: AppTextStyles.titleSmall(context),
                  ),
                  SizedBox(height: AppDimens.paddingM),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _timerSeconds > 300
                            ? () => setState(() => _timerSeconds -= 300) // 5분 단위
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        iconSize: AppDimens.iconL,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: AppDimens.paddingM),
                      Text(
                        l10n.minutesUnit(_timerSeconds ~/ 60),
                        style: AppTextStyles.titleLarge(context),
                      ),
                      SizedBox(width: AppDimens.paddingM),
                      IconButton(
                        onPressed: _timerSeconds < 3600
                            ? () => setState(() => _timerSeconds += 300) // 5분 단위, 최대 60분
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                        iconSize: AppDimens.iconL,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: AppDimens.paddingM),

          // Round Setting
          Card(
            child: Padding(
              padding: EdgeInsets.all(AppDimens.paddingL),
              child: Column(
                children: [
                  Text(
                    '라운드 수',
                    style: AppTextStyles.titleSmall(context),
                  ),
                  SizedBox(height: AppDimens.paddingM),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _totalRounds > 1
                            ? () => setState(() => _totalRounds--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        iconSize: AppDimens.iconL,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: AppDimens.paddingM),
                      Text(
                        '$_totalRounds 라운드',
                        style: AppTextStyles.titleLarge(context),
                      ),
                      SizedBox(width: AppDimens.paddingM),
                      IconButton(
                        onPressed: _totalRounds < 10
                            ? () => setState(() => _totalRounds++)
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                        iconSize: AppDimens.iconL,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: AppDimens.paddingM),

          // Team Assignment
          Card(
            child: Padding(
              padding: EdgeInsets.all(AppDimens.paddingL),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.teamAssignment,
                        style: AppTextStyles.titleSmall(context),
                      ),
                      IconButton(
                        onPressed: _assignTeams,
                        icon: const Icon(Icons.shuffle),
                        iconSize: AppDimens.iconM,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                  SizedBox(height: AppDimens.paddingM),
                  if (_teamAssignments == null)
                    Text(
                      l10n.shuffleTeamHint,
                      style: AppTextStyles.body(context).copyWith(
                        color: AppColors.textSecondary,
                      ),
                    )
                  else
                    _buildTeamsList(),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Start Button
          ElevatedButton(
            onPressed: _teamAssignments != null ? _startGame : null,
            child: Text(
              l10n.startGameButton,
              style: AppTextStyles.labelLarge(context).copyWith(
                color: AppColors.textOnPrimary,
              ),
            ),
          ),
          SizedBox(height: AppDimens.paddingM),
        ],
      ),
    );
  }

  Widget _buildTeamsList() {
    final l10n = AppLocalizations.of(context)!;
    final team1 = _teamAssignments!.where((t) =>
        t.team == TeamType.cops ||
        t.team == TeamType.seekers ||
        t.team == TeamType.teamA);
    final team2 = _teamAssignments!.where((t) =>
        t.team == TeamType.robbers ||
        t.team == TeamType.hiders ||
        t.team == TeamType.teamB);

    final team1Color = _getTeam1Color();
    final team2Color = _getTeam2Color();
    final team1Name = _getTeam1Name(l10n);
    final team2Name = _getTeam2Name(l10n);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _TeamColumn(
            teamName: team1Name,
            color: team1Color,
            members: team1.map((e) => e.odNickname).toList(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _TeamColumn(
            teamName: team2Name,
            color: team2Color,
            members: team2.map((e) => e.odNickname).toList(),
          ),
        ),
      ],
    );
  }

  Color _getTeam1Color() {
    switch (widget.meeting.gameType) {
      case GameType.copsAndRobbers:
        return AppColors.cops;
      case GameType.freezeTag:
      case GameType.hideAndSeek:
        return AppColors.seekers;
      default:
        return AppColors.primary;
    }
  }

  Color _getTeam2Color() {
    switch (widget.meeting.gameType) {
      case GameType.copsAndRobbers:
        return AppColors.robbers;
      case GameType.freezeTag:
      case GameType.hideAndSeek:
        return AppColors.hiders;
      default:
        return AppColors.secondary;
    }
  }

  String _getTeam1Name(AppLocalizations l10n) {
    switch (widget.meeting.gameType) {
      case GameType.copsAndRobbers:
        return l10n.roleCops;
      case GameType.freezeTag:
      case GameType.hideAndSeek:
        return l10n.roleSeeker;
      default:
        return l10n.roleTeamA;
    }
  }

  String _getTeam2Name(AppLocalizations l10n) {
    switch (widget.meeting.gameType) {
      case GameType.copsAndRobbers:
        return l10n.roleRobbers;
      case GameType.freezeTag:
      case GameType.hideAndSeek:
        return l10n.roleRunner;
      default:
        return l10n.roleTeamB;
    }
  }

  void _toggleTeamStatus() {
    setState(() => _showTeamStatus = !_showTeamStatus);
  }

  /// 풀스크린 타이머 - 앱의 얼굴
  /// 일시정지 없음 (오프라인에서 직접 소통)
  /// 숫자 크게 + 라운드 정보만
  Widget _buildFullscreenTimer() {
    final l10n = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 팀 상태 토글 버튼
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppDimens.paddingM,
                vertical: AppDimens.paddingS,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: _toggleTeamStatus,
                    icon: Icon(
                      _showTeamStatus ? Icons.expand_less : Icons.groups,
                      color: Colors.white54,
                    ),
                    tooltip: _showTeamStatus ? '팀 숨기기' : '팀 보기',
                  ),
                ],
              ),
            ),

            // 팀 상태 표시 (토글 시)
            if (_showTeamStatus && _teamAssignments != null)
              _buildTeamStatusBar(),

            // 타이머 영역 (화면의 대부분 차지)
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.black,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 라운드 표시 (타이머 위)
                    Text(
                      'Round $_currentRound / $_totalRounds',
                      style: TextStyle(
                        fontSize: screenHeight * 0.025,
                        fontWeight: FontWeight.w400,
                        color: Colors.white54,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: AppDimens.paddingS),

                    // 큰 타이머 숫자
                    Text(
                      _formatTime(_timerSeconds),
                      style: TextStyle(
                        fontSize: screenHeight * 0.15,
                        fontWeight: FontWeight.w300,
                        color: _timerSeconds <= 60
                            ? AppColors.error
                            : Colors.white,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 하단 종료 버튼
            Padding(
              padding: EdgeInsets.all(AppDimens.paddingL),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _confirmEndGame,
                  icon: const Icon(Icons.stop),
                  label: Text(
                    l10n.endGame,
                    style: AppTextStyles.labelLarge(context).copyWith(
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppDimens.buttonBorderRadius,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 팀 상태 바 (게임 중 표시)
  Widget _buildTeamStatusBar() {
    final l10n = AppLocalizations.of(context)!;
    final team1 = _teamAssignments!.where((t) =>
        t.team == TeamType.cops ||
        t.team == TeamType.seekers ||
        t.team == TeamType.teamA).toList();
    final team2 = _teamAssignments!.where((t) =>
        t.team == TeamType.robbers ||
        t.team == TeamType.hiders ||
        t.team == TeamType.teamB).toList();

    final team1Color = _getTeam1Color();
    final team2Color = _getTeam2Color();
    final team1Name = _getTeam1Name(l10n);
    final team2Name = _getTeam2Name(l10n);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
      padding: EdgeInsets.all(AppDimens.paddingM),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: AppDimens.cardBorderRadius,
      ),
      child: Row(
        children: [
          // 팀1
          Expanded(
            child: _TeamStatusColumn(
              teamName: team1Name,
              color: team1Color,
              members: team1.map((e) => e.odNickname).toList(),
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: Colors.white24,
            margin: EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
          ),
          // 팀2
          Expanded(
            child: _TeamStatusColumn(
              teamName: team2Name,
              color: team2Color,
              members: team2.map((e) => e.odNickname).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmEndGame() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.endGameConfirmTitle),
        content: Text(l10n.endGameConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _endGame();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(l10n.endGame),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

class _TeamColumn extends StatelessWidget {
  final String teamName;
  final Color color;
  final List<String> members;

  const _TeamColumn({
    required this.teamName,
    required this.color,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppDimens.paddingM),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppDimens.cardBorderRadius,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppDimens.paddingM,
              vertical: AppDimens.paddingXS + 2,
            ),
            decoration: BoxDecoration(
              color: color,
              borderRadius: AppDimens.chipBorderRadius,
            ),
            child: Text(
              teamName,
              style: AppTextStyles.label(context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: AppDimens.paddingM),
          ...members.map((name) => Padding(
                padding: EdgeInsets.symmetric(vertical: AppDimens.paddingXS),
                child: Text(
                  name,
                  style: AppTextStyles.body(context).copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

/// 역할 선택 타일
class _RoleSelectionTile extends StatelessWidget {
  final ParticipantWithPreference participant;
  final String role1Name;
  final String role2Name;
  final ValueChanged<RolePreference> onPreferenceChanged;

  const _RoleSelectionTile({
    required this.participant,
    required this.role1Name,
    required this.role2Name,
    required this.onPreferenceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: AppDimens.paddingS),
      child: Padding(
        padding: EdgeInsets.all(AppDimens.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 닉네임
            Text(
              participant.nickname,
              style: AppTextStyles.titleSmall(context),
            ),
            SizedBox(height: AppDimens.paddingS),
            // 역할 선택 버튼들
            Row(
              children: [
                _RoleChip(
                  label: '상관없음',
                  isSelected: participant.preference == RolePreference.none,
                  color: AppColors.textSecondary,
                  onTap: () => onPreferenceChanged(RolePreference.none),
                ),
                SizedBox(width: AppDimens.paddingS),
                _RoleChip(
                  label: role1Name,
                  isSelected: participant.preference == RolePreference.role1,
                  color: AppColors.cops,
                  onTap: () => onPreferenceChanged(RolePreference.role1),
                ),
                SizedBox(width: AppDimens.paddingS),
                _RoleChip(
                  label: role2Name,
                  isSelected: participant.preference == RolePreference.role2,
                  color: AppColors.robbers,
                  onTap: () => onPreferenceChanged(RolePreference.role2),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 역할 선택 칩
class _RoleChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppDimens.paddingM,
          vertical: AppDimens.paddingS,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: AppDimens.chipBorderRadius,
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.label(context).copyWith(
            color: isSelected ? Colors.white : color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

/// 팀 상태 컬럼 (게임 중 표시용)
class _TeamStatusColumn extends StatelessWidget {
  final String teamName;
  final Color color;
  final List<String> members;

  const _TeamStatusColumn({
    required this.teamName,
    required this.color,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 팀 이름 + 인원수
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppDimens.paddingS,
                vertical: AppDimens.paddingXS,
              ),
              decoration: BoxDecoration(
                color: color,
                borderRadius: AppDimens.chipBorderRadius,
              ),
              child: Text(
                teamName,
                style: AppTextStyles.labelSmall(context).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: AppDimens.paddingXS),
            Text(
              '${members.length}명',
              style: AppTextStyles.labelSmall(context).copyWith(
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: AppDimens.paddingXS),
        // 멤버 목록 (가로로 나열)
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppDimens.paddingXS,
          children: members.map((name) => Text(
            name,
            style: AppTextStyles.labelSmall(context).copyWith(
              color: Colors.white70,
            ),
          )).toList(),
        ),
      ],
    );
  }
}
