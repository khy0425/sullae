import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/meeting_model.dart';
import '../../models/system_message_model.dart';
import '../../models/quick_message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/meeting_provider.dart';
import '../../services/system_message_service.dart';
import '../../services/quick_message_service.dart';
import '../../services/host_rating_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/share_dialog.dart';
import '../../widgets/host_rating_widget.dart';
import '../../widgets/quick_message_widget.dart';
import '../game/game_screen.dart';

class MeetingDetailScreen extends StatefulWidget {
  final String meetingId;

  const MeetingDetailScreen({super.key, required this.meetingId});

  @override
  State<MeetingDetailScreen> createState() => _MeetingDetailScreenState();
}

class _MeetingDetailScreenState extends State<MeetingDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SystemMessageService _systemMessageService = SystemMessageService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MeetingProvider>().subscribeToMeeting(widget.meetingId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer2<MeetingProvider, AuthProvider>(
      builder: (context, meetingProvider, authProvider, _) {
        final meeting = meetingProvider.currentMeeting;

        if (meeting == null) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final isHost = meeting.hostId == authProvider.userId;
        final isParticipant = meeting.participantIds.contains(authProvider.userId);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              meeting.title,
              style: AppTextStyles.titleSmall(context),
            ),
            actions: [
              // 공유 버튼 (참가자만)
              if (isParticipant)
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => _showShareDialog(meeting),
                  tooltip: '모임 공유',
                ),
              if (isHost)
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuAction(value, meeting, l10n),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'start_game',
                      child: Row(
                        children: [
                          Icon(GameIcons.playing, size: AppDimens.iconM),
                          SizedBox(width: AppDimens.paddingS),
                          Text(l10n.startMeeting),
                        ],
                      ),
                    ),
                    // 방장 위임 (참가자가 2명 이상일 때만)
                    if (meeting.participantIds.length > 1)
                      PopupMenuItem(
                        value: 'transfer_host',
                        child: Row(
                          children: [
                            Icon(Icons.swap_horiz, size: AppDimens.iconM),
                            SizedBox(width: AppDimens.paddingS),
                            Text('방장 위임'),
                          ],
                        ),
                      ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'cancel',
                      child: Row(
                        children: [
                          Icon(Icons.cancel, color: AppColors.warning, size: AppDimens.iconM),
                          SizedBox(width: AppDimens.paddingS),
                          Text(l10n.cancelMeeting, style: TextStyle(color: AppColors.warning)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_forever, color: AppColors.error, size: AppDimens.iconM),
                          SizedBox(width: AppDimens.paddingS),
                          Text('모임 삭제', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(GameIcons.info, size: AppDimens.iconS),
                      SizedBox(width: AppDimens.paddingXS),
                      Text(l10n.meetingInfo),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(GameIcons.chat, size: AppDimens.iconS),
                      SizedBox(width: AppDimens.paddingXS),
                      Text(l10n.meetingChat),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _InfoTab(meeting: meeting, l10n: l10n),
              _ChatTab(
                meetingId: widget.meetingId,
                systemMessageService: _systemMessageService,
                l10n: l10n,
              ),
            ],
          ),
          bottomNavigationBar: !isParticipant && meeting.isJoinable
              ? SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(AppDimens.paddingM),
                    child: ElevatedButton(
                      onPressed: () => _joinMeeting(meeting, l10n),
                      child: Text(
                        l10n.joinMeeting,
                        style: AppTextStyles.labelLarge(context).copyWith(
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                    ),
                  ),
                )
              : isParticipant && !isHost
                  ? SafeArea(
                      child: Padding(
                        padding: EdgeInsets.all(AppDimens.paddingM),
                        child: OutlinedButton(
                          onPressed: () => _leaveMeeting(meeting),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                          ),
                          child: Text(
                            l10n.leaveMeeting,
                            style: AppTextStyles.labelLarge(context).copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ),
                    )
                  : null,
        );
      },
    );
  }

  void _handleMenuAction(String action, MeetingModel meeting, AppLocalizations l10n) {
    switch (action) {
      case 'start_game':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GameScreen(meeting: meeting),
          ),
        );
        break;
      case 'cancel':
        _showCancelDialog(meeting, l10n);
        break;
      case 'delete':
        _showDeleteDialog(meeting, l10n);
        break;
      case 'transfer_host':
        _showTransferHostDialog(meeting, l10n);
        break;
    }
  }

  void _showCancelDialog(MeetingModel meeting, AppLocalizations l10n) {
    // 다이얼로그 밖에서 Provider 참조 가져오기
    final authProvider = context.read<AuthProvider>();
    final meetingProvider = context.read<MeetingProvider>();
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.cancel_outlined, color: AppColors.warning, size: 24),
            SizedBox(width: AppDimens.paddingS),
            Expanded(child: Text(l10n.cancelMeeting)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.cancelMeetingConfirm),
            SizedBox(height: AppDimens.paddingS),
            Text(
              '참가자들에게 취소 알림이 전송됩니다.',
              style: AppTextStyles.bodySmall(dialogContext).copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actionsPadding: EdgeInsets.all(AppDimens.paddingM),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: AppColors.border),
                  ),
                  child: Text('돌아가기'),
                ),
              ),
              SizedBox(width: AppDimens.paddingM),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext); // 다이얼로그 먼저 닫기
                    await meetingProvider.cancelMeeting(
                      meeting.id,
                      authProvider.userId,
                    );
                    if (mounted) {
                      navigator.pop(); // 상세 화면 닫기
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('모임 취소'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(MeetingModel meeting, AppLocalizations l10n) {
    final authProvider = context.read<AuthProvider>();
    final meetingProvider = context.read<MeetingProvider>();
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: AppColors.error, size: 24),
            SizedBox(width: AppDimens.paddingS),
            Text('모임 삭제'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('모임을 완전히 삭제하시겠습니까?'),
            SizedBox(height: AppDimens.paddingS),
            Container(
              padding: EdgeInsets.all(AppDimens.paddingS),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: AppColors.error, size: 16),
                  SizedBox(width: AppDimens.paddingXS),
                  Expanded(
                    child: Text(
                      '이 작업은 되돌릴 수 없습니다.',
                      style: AppTextStyles.bodySmall(dialogContext).copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsPadding: EdgeInsets.all(AppDimens.paddingM),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: AppColors.border),
                  ),
                  child: Text('돌아가기'),
                ),
              ),
              SizedBox(width: AppDimens.paddingM),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    final success = await meetingProvider.deleteMeeting(
                      meeting.id,
                      authProvider.userId,
                    );
                    if (mounted) {
                      if (success) {
                        navigator.pop();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('모임 삭제에 실패했습니다. 모집중/취소/완료 상태에서만 삭제할 수 있습니다.')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('삭제하기'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTransferHostDialog(MeetingModel meeting, AppLocalizations l10n) {
    final authProvider = context.read<AuthProvider>();
    final meetingProvider = context.read<MeetingProvider>();

    // 방장 본인 제외한 참가자 목록
    final otherParticipants = meeting.participantIds
        .where((id) => id != authProvider.userId)
        .toList();

    if (otherParticipants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('위임할 참가자가 없습니다.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.swap_horiz, color: AppColors.primary, size: 24),
            SizedBox(width: AppDimens.paddingS),
            Text('방장 위임'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '누구에게 방장을 넘기시겠습니까?',
                style: AppTextStyles.body(dialogContext),
              ),
              SizedBox(height: AppDimens.paddingM),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: otherParticipants.asMap().entries.map((entry) {
                    final index = entry.key;
                    final odId = entry.value;
                    final nickname = '참가자 ${index + 2}'; // TODO: 실제 닉네임 조회 필요
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          Navigator.pop(dialogContext);
                          final success = await meetingProvider.transferHost(
                            meeting.id,
                            authProvider.userId,
                            odId,
                            nickname,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success
                                    ? '$nickname님에게 방장을 위임했습니다.'
                                    : '방장 위임에 실패했습니다.'),
                              ),
                            );
                          }
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppDimens.paddingM,
                            vertical: AppDimens.paddingS + 4,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                child: Icon(Icons.person, color: AppColors.primary, size: 20),
                              ),
                              SizedBox(width: AppDimens.paddingM),
                              Expanded(
                                child: Text(
                                  nickname,
                                  style: AppTextStyles.body(dialogContext).copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        actionsPadding: EdgeInsets.all(AppDimens.paddingM),
        actions: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: AppColors.border),
              ),
              child: Text('닫기'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _joinMeeting(MeetingModel meeting, AppLocalizations l10n) async {
    final authProvider = context.read<AuthProvider>();
    final meetingProvider = context.read<MeetingProvider>();

    final success = await meetingProvider.joinMeeting(
      meeting.id,
      authProvider.userId,
      authProvider.nickname,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.joinedMeeting)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(meetingProvider.error ?? l10n.createMeetingFailed)),
      );
    }
  }

  Future<void> _leaveMeeting(MeetingModel meeting) async {
    final authProvider = context.read<AuthProvider>();
    final meetingProvider = context.read<MeetingProvider>();
    final navigator = Navigator.of(context);

    // 퇴장 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.exit_to_app, color: AppColors.error, size: 24),
            SizedBox(width: AppDimens.paddingS),
            Text('모임 나가기'),
          ],
        ),
        content: Text('이 모임에서 나가시겠습니까?'),
        actionsPadding: EdgeInsets.all(AppDimens.paddingM),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: AppColors.border),
                  ),
                  child: Text('취소'),
                ),
              ),
              SizedBox(width: AppDimens.paddingM),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('나가기'),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await meetingProvider.leaveMeeting(
      meeting.id,
      authProvider.userId,
      authProvider.nickname,
    );

    if (!mounted) return;

    if (success) {
      navigator.pop();
    }
  }

  void _showShareDialog(MeetingModel meeting) {
    showDialog(
      context: context,
      builder: (context) => ShareMeetingDialog(meeting: meeting),
    );
  }
}

class _InfoTab extends StatelessWidget {
  final MeetingModel meeting;
  final AppLocalizations l10n;

  const _InfoTab({required this.meeting, required this.l10n});

  Color get _gameTypeColor {
    switch (meeting.gameType) {
      case GameType.copsAndRobbers:
        return AppColors.copsAndRobbers;
      case GameType.freezeTag:
        return AppColors.freezeTag;
      case GameType.hideAndSeek:
        return AppColors.hideAndSeek;
      case GameType.captureFlag:
        return AppColors.captureFlag;
      case GameType.custom:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(AppDimens.paddingM),
      children: [
        // Game Type Card
        Card(
          color: _gameTypeColor.withValues(alpha: 0.1),
          child: Padding(
            padding: EdgeInsets.all(AppDimens.paddingM),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppDimens.paddingM),
                  decoration: BoxDecoration(
                    color: _gameTypeColor,
                    borderRadius: AppDimens.cardBorderRadius,
                  ),
                  child: Icon(
                    _getGameTypeIcon(meeting.gameType),
                    color: Colors.white,
                    size: AppDimens.iconL,
                  ),
                ),
                SizedBox(width: AppDimens.paddingM),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meeting.gameTypeName,
                      style: AppTextStyles.titleSmall(context).copyWith(
                        color: _gameTypeColor,
                      ),
                    ),
                    Text(
                      meeting.statusName,
                      style: AppTextStyles.bodySmall(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: AppDimens.paddingM),

        // Description
        if (meeting.description.isNotEmpty) ...[
          Card(
            child: Padding(
              padding: EdgeInsets.all(AppDimens.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.meetingDescription,
                    style: AppTextStyles.titleSmall(context),
                  ),
                  SizedBox(height: AppDimens.paddingS),
                  Text(
                    meeting.description,
                    style: AppTextStyles.body(context),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: AppDimens.paddingM),
        ],

        // Info Card
        Card(
          child: Padding(
            padding: EdgeInsets.all(AppDimens.paddingM),
            child: Column(
              children: [
                _InfoRow(
                  icon: GameIcons.location,
                  label: l10n.location,
                  value: meeting.locationDetail != null
                      ? '${meeting.location} (${meeting.locationDetail})'
                      : meeting.location,
                ),
                Divider(height: AppDimens.paddingL, color: AppColors.divider),
                _InfoRow(
                  icon: Icons.calendar_today,
                  label: l10n.dateTime,
                  value: DateFormat('M월 d일 (E) HH:mm', 'ko_KR')
                      .format(meeting.meetingTime),
                ),
                Divider(height: AppDimens.paddingL, color: AppColors.divider),
                _InfoRow(
                  icon: Icons.person_outline,
                  label: l10n.meetingHost,
                  value: meeting.hostNickname,
                ),
                // 호스트 평점 표시
                FutureBuilder(
                  future: HostRatingService().getHostRatingSummary(meeting.hostId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    final rating = snapshot.data!;
                    if (rating.totalReviews == 0) return const SizedBox.shrink();
                    return Padding(
                      padding: EdgeInsets.only(top: AppDimens.paddingS),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          HostRatingBadge(rating: rating),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: AppDimens.paddingM),

        // Participants
        Card(
          child: Padding(
            padding: EdgeInsets.all(AppDimens.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.meetingParticipants,
                      style: AppTextStyles.titleSmall(context),
                    ),
                    Text(
                      '${l10n.participantsUnit(meeting.currentParticipants)}/${l10n.participantsUnit(meeting.maxParticipants)}',
                      style: AppTextStyles.label(context).copyWith(
                        color: _gameTypeColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppDimens.paddingM),
                LinearProgressIndicator(
                  value: meeting.currentParticipants / meeting.maxParticipants,
                  backgroundColor: AppColors.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(_gameTypeColor),
                  borderRadius: BorderRadius.circular(AppDimens.radiusS),
                ),
                SizedBox(height: AppDimens.paddingM),
                Wrap(
                  spacing: AppDimens.paddingS,
                  runSpacing: AppDimens.paddingS,
                  children: List.generate(
                    meeting.currentParticipants,
                    (index) => _ParticipantChip(
                      isHost: index == 0,
                      color: _gameTypeColor,
                      l10n: l10n,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _getGameTypeIcon(GameType type) {
    switch (type) {
      case GameType.copsAndRobbers:
        return GameIcons.copsAndRobbers;
      case GameType.freezeTag:
        return GameIcons.freezeTag;
      case GameType.hideAndSeek:
        return GameIcons.hideAndSeek;
      case GameType.captureFlag:
        return GameIcons.captureFlag;
      case GameType.custom:
        return GameIcons.custom;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: AppDimens.iconM),
        SizedBox(width: AppDimens.paddingM),
        Text(
          label,
          style: AppTextStyles.bodySmall(context),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: AppTextStyles.body(context).copyWith(
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _ParticipantChip extends StatelessWidget {
  final bool isHost;
  final Color color;
  final AppLocalizations l10n;

  const _ParticipantChip({
    required this.isHost,
    required this.color,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimens.paddingM,
        vertical: AppDimens.paddingXS + 2,
      ),
      decoration: BoxDecoration(
        color: isHost ? color : color.withValues(alpha: 0.1),
        borderRadius: AppDimens.chipBorderRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isHost) ...[
            Icon(Icons.star, size: AppDimens.iconXS, color: Colors.white),
            SizedBox(width: AppDimens.paddingXS),
          ],
          Text(
            isHost ? l10n.meetingHost : l10n.meetingParticipants,
            style: AppTextStyles.labelSmall(context).copyWith(
              color: isHost ? Colors.white : color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatTab extends StatelessWidget {
  final String meetingId;
  final SystemMessageService systemMessageService;
  final AppLocalizations l10n;

  const _ChatTab({
    required this.meetingId,
    required this.systemMessageService,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final meetingProvider = context.read<MeetingProvider>();
    final meeting = meetingProvider.currentMeeting;
    final isHost = meeting?.hostId == authProvider.userId;

    return Column(
      children: [
        // 시스템 메시지 + 퀵메시지 목록
        Expanded(
          child: _CombinedMessageList(
            meetingId: meetingId,
            systemMessageService: systemMessageService,
            l10n: l10n,
          ),
        ),

        // 퀵메시지 입력 영역 (텍스트 입력 없음)
        _QuickMessageInput(
          meetingId: meetingId,
          userId: authProvider.userId,
          userNickname: authProvider.nickname,
          isHost: isHost,
        ),
      ],
    );
  }
}

/// 시스템 메시지 + 퀵메시지 통합 목록
class _CombinedMessageList extends StatelessWidget {
  final String meetingId;
  final SystemMessageService systemMessageService;
  final AppLocalizations l10n;

  const _CombinedMessageList({
    required this.meetingId,
    required this.systemMessageService,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final quickMessageService = QuickMessageService();

    return StreamBuilder<List<dynamic>>(
      stream: _combineStreams(systemMessageService, quickMessageService),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.flash_on,
                  size: 48,
                  color: AppColors.textTertiary,
                ),
                SizedBox(height: AppDimens.paddingM),
                Text(
                  '퀵메시지로 빠르게 소통하세요',
                  style: AppTextStyles.body(context).copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: AppDimens.paddingS),
                Text(
                  '아래 버튼을 눌러 메시지를 보내세요',
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(AppDimens.paddingM),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            if (item is SystemMessage) {
              return _SystemMessageBubble(message: item);
            } else if (item is QuickMessage) {
              return _QuickMessageBubble(message: item);
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  Stream<List<dynamic>> _combineStreams(
    SystemMessageService systemMessageService,
    QuickMessageService quickMessageService,
  ) async* {
    // 두 스트림을 합쳐서 시간순 정렬
    await for (final systemMessages in systemMessageService.getMessages(meetingId)) {
      final quickMessages = await quickMessageService
          .getRecentMessages(meetingId, limit: 50)
          .first;

      final combined = <dynamic>[...systemMessages, ...quickMessages];
      combined.sort((a, b) {
        final aTime = a is SystemMessage ? a.timestamp : (a as QuickMessage).sentAt;
        final bTime = b is SystemMessage ? b.timestamp : (b as QuickMessage).sentAt;
        return aTime.compareTo(bTime);
      });

      yield combined;
    }
  }
}

/// 시스템 메시지 버블
class _SystemMessageBubble extends StatelessWidget {
  final SystemMessage message;

  const _SystemMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppDimens.paddingS),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppDimens.paddingM,
            vertical: AppDimens.paddingXS + 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.divider,
            borderRadius: AppDimens.cardBorderRadius,
          ),
          child: Text(
            message.message,
            style: AppTextStyles.labelSmall(context).copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// 퀵메시지 버블
class _QuickMessageBubble extends StatelessWidget {
  final QuickMessage message;

  const _QuickMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final isMe = message.senderId == authProvider.userId;
    final def = message.definition;
    final isAnnouncement = message.type == QuickMessageType.customAnnounce ||
        message.type == QuickMessageType.locationChanged ||
        message.type == QuickMessageType.timeChanged ||
        message.type == QuickMessageType.cancelled;

    // 공지 메시지는 중앙에 강조 표시
    if (isAnnouncement) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: AppDimens.paddingS),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(AppDimens.paddingM),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: AppDimens.cardBorderRadius,
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    def?.emoji ?? '📢',
                    style: const TextStyle(fontSize: 16),
                  ),
                  SizedBox(width: AppDimens.paddingXS),
                  Text(
                    '방장 공지',
                    style: AppTextStyles.labelSmall(context).copyWith(
                      color: Colors.orange[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppDimens.paddingXS),
              Text(
                message.customText ?? def?.text ?? '',
                style: AppTextStyles.body(context).copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // 일반 퀵메시지
    return Padding(
      padding: EdgeInsets.only(bottom: AppDimens.paddingS),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppDimens.paddingM,
              vertical: AppDimens.paddingS,
            ),
            decoration: BoxDecoration(
              color: isMe
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(AppDimens.radiusL),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  def?.emoji ?? '',
                  style: const TextStyle(fontSize: 16),
                ),
                SizedBox(width: AppDimens.paddingXS),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isMe)
                      Text(
                        message.senderNickname,
                        style: AppTextStyles.labelSmall(context).copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    Text(
                      def?.text ?? '',
                      style: AppTextStyles.body(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 퀵메시지 입력 영역 (자유 텍스트 없음)
class _QuickMessageInput extends StatefulWidget {
  final String meetingId;
  final String userId;
  final String userNickname;
  final bool isHost;

  const _QuickMessageInput({
    required this.meetingId,
    required this.userId,
    required this.userNickname,
    required this.isHost,
  });

  @override
  State<_QuickMessageInput> createState() => _QuickMessageInputState();
}

class _QuickMessageInputState extends State<_QuickMessageInput> {
  final QuickMessageService _messageService = QuickMessageService();
  bool _isSending = false;

  List<QuickMessageDef> get _quickMessages {
    // 자주 쓰는 메시지만 표시 (전체는 바텀시트에서)
    if (widget.isHost) {
      return [
        QuickMessageDef.fromType(QuickMessageType.whereAreYou)!,
        QuickMessageDef.fromType(QuickMessageType.startSoon)!,
        QuickMessageDef.fromType(QuickMessageType.arrived)!,
      ];
    }
    return [
      QuickMessageDef.fromType(QuickMessageType.arrived)!,
      QuickMessageDef.fromType(QuickMessageType.onMyWay)!,
      QuickMessageDef.fromType(QuickMessageType.late5)!,
    ];
  }

  Future<void> _sendQuickMessage(QuickMessageType type) async {
    if (_isSending) return;

    setState(() => _isSending = true);

    try {
      await _messageService.sendMessage(
        meetingId: widget.meetingId,
        senderId: widget.userId,
        senderNickname: widget.userNickname,
        type: type,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('메시지 전송 실패'), backgroundColor: Colors.red),
        );
      }
    }

    if (mounted) {
      setState(() => _isSending = false);
    }
  }

  void _showAllQuickMessages() {
    QuickMessageBottomSheet.show(
      context: context,
      meetingId: widget.meetingId,
      userId: widget.userId,
      userNickname: widget.userNickname,
      isHost: widget.isHost,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppDimens.paddingS),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // 더보기 버튼
            IconButton(
              onPressed: _showAllQuickMessages,
              icon: const Icon(Icons.add_circle_outline),
              color: AppColors.primary,
              tooltip: '모든 퀵메시지',
            ),

            // 퀵메시지 버튼들
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _quickMessages.map((msg) {
                    return Padding(
                      padding: EdgeInsets.only(right: AppDimens.paddingS),
                      child: _QuickButton(
                        message: msg,
                        onTap: () => _sendQuickMessage(msg.type),
                        enabled: !_isSending,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            if (_isSending)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 퀵메시지 버튼
class _QuickButton extends StatelessWidget {
  final QuickMessageDef message;
  final VoidCallback onTap;
  final bool enabled;

  const _QuickButton({
    required this.message,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${message.text} 퀵메시지 보내기',
      button: true,
      enabled: enabled,
      child: Material(
        color: message.hostOnly
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(20),
          excludeFromSemantics: true,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppDimens.paddingM,
              vertical: AppDimens.paddingS,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message.emoji, style: const TextStyle(fontSize: 14)),
                SizedBox(width: AppDimens.paddingXS),
                Text(
                  message.text,
                  style: AppTextStyles.labelSmall(context).copyWith(
                    color: enabled ? AppColors.textPrimary : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
