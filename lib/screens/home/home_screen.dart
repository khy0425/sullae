import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../models/meeting_model.dart';
// user_model.dart import 제거됨 - RoleStats 미사용
import '../../providers/auth_provider.dart';
import '../../providers/meeting_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/donation_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/ad_banner_widget.dart';
import '../meeting/create_meeting_screen.dart';
import '../meeting/meeting_detail_screen.dart';
import '../../widgets/meeting/meeting_card.dart';
import '../../widgets/filter/filter_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final meetingProvider = context.read<MeetingProvider>();
      // 페이지네이션 모드로 첫 페이지 로드 (무한 스크롤)
      // subscribeToMeetings() 대신 loadFirstPage() 사용
      // 참고: _MeetingListTab에서도 loadFirstPage를 호출하므로 중복 방지
      if (authProvider.userId.isNotEmpty) {
        meetingProvider.subscribeToMyMeetings(authProvider.userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _MeetingListTab(),
          _MyMeetingsTab(),
          _ProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: [
          BottomNavigationBarItem(
            icon: Icon(GameIcons.explore),
            activeIcon: Icon(GameIcons.explore),
            label: l10n.navExplore,
          ),
          BottomNavigationBarItem(
            icon: Icon(GameIcons.meeting),
            activeIcon: Icon(GameIcons.meeting),
            label: l10n.navMyMeetings,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: l10n.navProfile,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createMeeting(context),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        icon: const Icon(Icons.add),
        label: Text(
          l10n.createMeeting,
          style: AppTextStyles.labelLarge(context).copyWith(
            color: AppColors.textOnPrimary,
          ),
        ),
      ),
    );
  }

  void _createMeeting(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateMeetingScreen()),
    );
  }
}

class _MeetingListTab extends StatefulWidget {
  const _MeetingListTab();

  @override
  State<_MeetingListTab> createState() => _MeetingListTabState();
}

class _MeetingListTabState extends State<_MeetingListTab> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // 페이지네이션 모드로 첫 페이지 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MeetingProvider>().loadFirstPage();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // 스크롤이 끝에서 200픽셀 이내로 도달하면 다음 페이지 로드
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<MeetingProvider>();
      if (provider.canLoadMore) {
        provider.loadMoreMeetings();
      }
    }
  }

  Widget _buildSearchField(BuildContext context, AppLocalizations l10n) {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: l10n.searchMeetings,
        border: InputBorder.none,
        hintStyle: AppTextStyles.body(context).copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      style: AppTextStyles.body(context),
      onChanged: (value) {
        context.read<MeetingProvider>().setSearchQuery(value);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return RefreshIndicator(
      onRefresh: () => context.read<MeetingProvider>().refreshMeetings(),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.surface,
            title: _showSearch
              ? _buildSearchField(context, l10n)
              : Row(
                  children: [
                    Icon(GameIcons.escape, color: AppColors.primary, size: AppDimens.iconL),
                    const SizedBox(width: AppDimens.paddingS),
                    Text(
                      l10n.appName,
                      style: AppTextStyles.titleMedium(context),
                    ),
                  ],
                ),
          actions: [
            // 검색 토글 버튼
            IconButton(
              icon: Icon(_showSearch ? Icons.close : Icons.search, size: 24),
              tooltip: _showSearch ? l10n.cancel : l10n.search,
              onPressed: () {
                setState(() {
                  _showSearch = !_showSearch;
                  if (!_showSearch) {
                    _searchController.clear();
                    context.read<MeetingProvider>().setSearchQuery('');
                  }
                });
              },
            ),
            // 참가 코드 입력 버튼
            IconButton(
              icon: const Icon(Icons.qr_code, size: 24),
              tooltip: l10n.joinWithCode,
              onPressed: () => _showJoinCodeDialog(context, l10n),
            ),
            IconButton(
              icon: Icon(GameIcons.notifications, size: AppDimens.iconM),
              onPressed: () {},
            ),
          ],
        ),
        // 시간대 필터 + 모집중 토글
        SliverToBoxAdapter(
          child: _TimeFilterBar(),
        ),
        // Game Type Filter
        SliverToBoxAdapter(
          child: _GameTypeFilter(),
        ),
        // Banner Ad
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(child: AdBannerWidget()),
          ),
        ),
        // Meeting List
        Consumer<MeetingProvider>(
          builder: (context, provider, _) {
            if (provider.filteredMeetings.isEmpty) {
              return SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: AppDimens.iconXXL,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(height: AppDimens.paddingM),
                      Text(
                        l10n.noRecruitingMeetings,
                        style: AppTextStyles.body(context).copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: AppDimens.paddingS),
                      Text(
                        l10n.createNewMeeting,
                        style: AppTextStyles.bodySmall(context),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: EdgeInsets.all(AppDimens.paddingM),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final meeting = provider.filteredMeetings[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: AppDimens.paddingM),
                      child: MeetingCard(
                        meeting: meeting,
                        onTap: () => _openMeetingDetail(context, meeting),
                      ),
                    );
                  },
                  childCount: provider.filteredMeetings.length,
                ),
              ),
            );
          },
        ),
        // Loading Indicator for pagination
        Consumer<MeetingProvider>(
          builder: (context, provider, _) {
            if (provider.isLoadingMore) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              );
            }
            return const SliverToBoxAdapter(child: SizedBox.shrink());
          },
        ),
        // Bottom Padding for FAB
        const SliverToBoxAdapter(
          child: SizedBox(height: 80),
        ),
      ],
      ),
    );
  }

  void _openMeetingDetail(BuildContext context, MeetingModel meeting) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MeetingDetailScreen(meetingId: meeting.id),
      ),
    );
  }

  void _showJoinCodeDialog(BuildContext context, AppLocalizations l10n) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          l10n.enterJoinCode,
          style: AppTextStyles.titleSmall(context),
        ),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 8,
          ),
          decoration: InputDecoration(
            hintText: l10n.joinCodeHint,
            counterText: '',
          ),
          onChanged: (value) {
            controller.text = value.toUpperCase();
            controller.selection = TextSelection.fromPosition(
              TextPosition(offset: controller.text.length),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = controller.text.trim().toUpperCase();
              if (code.length != 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.joinCodeInvalid)),
                );
                return;
              }

              Navigator.pop(context);

              // 코드로 모임 찾기
              final meetingProvider = context.read<MeetingProvider>();
              final meeting = await meetingProvider.findMeetingByCode(code);

              if (meeting != null && context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MeetingDetailScreen(meetingId: meeting.id),
                  ),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.joinCodeNotFound)),
                );
              }
            },
            child: Text(l10n.join),
          ),
        ],
      ),
    );
  }
}

class _GameTypeFilter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<MeetingProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(
            horizontal: AppDimens.paddingM,
            vertical: AppDimens.paddingS,
          ),
          child: Row(
            children: [
              _FilterChip(
                label: l10n.filterAll,
                isSelected: provider.selectedGameType == null,
                onTap: () => provider.setGameTypeFilter(null),
              ),
              SizedBox(width: AppDimens.paddingS),
              _FilterChip(
                label: l10n.gameCopsAndRobbers,
                icon: GameIcons.copsAndRobbers,
                color: AppColors.copsAndRobbers,
                isSelected: provider.selectedGameType == GameType.copsAndRobbers,
                onTap: () => provider.setGameTypeFilter(GameType.copsAndRobbers),
              ),
              SizedBox(width: AppDimens.paddingS),
              _FilterChip(
                label: l10n.gameFreezeTag,
                icon: GameIcons.freezeTag,
                color: AppColors.freezeTag,
                isSelected: provider.selectedGameType == GameType.freezeTag,
                onTap: () => provider.setGameTypeFilter(GameType.freezeTag),
              ),
              SizedBox(width: AppDimens.paddingS),
              _FilterChip(
                label: l10n.gameHideAndSeek,
                icon: GameIcons.hideAndSeek,
                color: AppColors.hideAndSeek,
                isSelected: provider.selectedGameType == GameType.hideAndSeek,
                onTap: () => provider.setGameTypeFilter(GameType.hideAndSeek),
              ),
              SizedBox(width: AppDimens.paddingS),
              _FilterChip(
                label: l10n.gameCaptureFlag,
                icon: GameIcons.captureFlag,
                color: AppColors.captureFlag,
                isSelected: provider.selectedGameType == GameType.captureFlag,
                onTap: () => provider.setGameTypeFilter(GameType.captureFlag),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 시간대 필터 바
class _TimeFilterBar extends StatelessWidget {
  const _TimeFilterBar();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<MeetingProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppDimens.paddingM,
            vertical: AppDimens.paddingS,
          ),
          child: Row(
            children: [
              // 시간대 필터 칩들
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _TimeChip(
                        label: l10n.filterTimeAll,
                        isSelected: provider.timeFilter == TimeFilter.all,
                        onTap: () => provider.setTimeFilter(TimeFilter.all),
                      ),
                      SizedBox(width: AppDimens.paddingXS),
                      _TimeChip(
                        label: l10n.filterTimeToday,
                        isSelected: provider.timeFilter == TimeFilter.today,
                        onTap: () => provider.setTimeFilter(TimeFilter.today),
                      ),
                      SizedBox(width: AppDimens.paddingXS),
                      _TimeChip(
                        label: l10n.filterTimeTomorrow,
                        isSelected: provider.timeFilter == TimeFilter.tomorrow,
                        onTap: () => provider.setTimeFilter(TimeFilter.tomorrow),
                      ),
                      SizedBox(width: AppDimens.paddingXS),
                      _TimeChip(
                        label: l10n.filterTimeThisWeek,
                        isSelected: provider.timeFilter == TimeFilter.thisWeek,
                        onTap: () => provider.setTimeFilter(TimeFilter.thisWeek),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: AppDimens.paddingS),
              // 모집중만 토글
              GestureDetector(
                onTap: () => provider.setShowRecruitingOnly(!provider.showRecruitingOnly),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDimens.paddingS,
                    vertical: AppDimens.paddingXS,
                  ),
                  decoration: BoxDecoration(
                    color: provider.showRecruitingOnly
                        ? AppColors.success.withValues(alpha: 0.15)
                        : AppColors.textSecondary.withValues(alpha: 0.1),
                    borderRadius: AppDimens.chipBorderRadius,
                    border: Border.all(
                      color: provider.showRecruitingOnly
                          ? AppColors.success.withValues(alpha: 0.5)
                          : AppColors.textSecondary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        provider.showRecruitingOnly
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        size: 16,
                        color: provider.showRecruitingOnly
                            ? AppColors.success
                            : AppColors.textSecondary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        l10n.showRecruitingOnly,
                        style: AppTextStyles.labelSmall(context).copyWith(
                          color: provider.showRecruitingOnly
                              ? AppColors.success
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: AppDimens.paddingS),
              // 상세 필터 버튼
              GestureDetector(
                onTap: () => FilterBottomSheet.show(context),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDimens.paddingS,
                    vertical: AppDimens.paddingXS,
                  ),
                  decoration: BoxDecoration(
                    color: provider.hasActiveFilters
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.textSecondary.withValues(alpha: 0.1),
                    borderRadius: AppDimens.chipBorderRadius,
                    border: Border.all(
                      color: provider.hasActiveFilters
                          ? AppColors.primary.withValues(alpha: 0.5)
                          : AppColors.textSecondary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tune,
                        size: 16,
                        color: provider.hasActiveFilters
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      if (provider.activeFilterCount > 0) ...[
                        SizedBox(width: 4),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${provider.activeFilterCount}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 시간 필터 칩
class _TimeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label 시간 필터${isSelected ? ', 선택됨' : ''}',
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppDimens.paddingM,
          vertical: AppDimens.paddingXS,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondary
              : AppColors.secondary.withValues(alpha: 0.1),
          borderRadius: AppDimens.chipBorderRadius,
          border: Border.all(
            color: isSelected
                ? AppColors.secondary
                : AppColors.secondary.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall(context).copyWith(
            color: isSelected ? Colors.white : AppColors.secondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.icon,
    this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;

    return Semantics(
      label: '$label 게임 필터${isSelected ? ', 선택됨' : ''}',
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppDimens.paddingM,
            vertical: AppDimens.paddingS,
          ),
          decoration: BoxDecoration(
            color: isSelected ? chipColor : chipColor.withValues(alpha: 0.1),
            borderRadius: AppDimens.chipBorderRadius,
            border: Border.all(
              color: isSelected ? chipColor : chipColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: AppDimens.iconS,
                  color: isSelected ? Colors.white : chipColor,
                ),
                SizedBox(width: AppDimens.paddingXS + 2),
              ],
              Text(
                label,
                style: AppTextStyles.labelSmall(context).copyWith(
                  color: isSelected ? Colors.white : chipColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyMeetingsTab extends StatelessWidget {
  const _MyMeetingsTab();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          backgroundColor: AppColors.surface,
          title: Text(
            l10n.navMyMeetings,
            style: AppTextStyles.titleMedium(context),
          ),
        ),
        // Banner Ad
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(child: AdBannerWidget()),
          ),
        ),
        Consumer<MeetingProvider>(
          builder: (context, provider, _) {
            if (provider.myMeetings.isEmpty) {
              return SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_note,
                        size: AppDimens.iconXXL,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(height: AppDimens.paddingM),
                      Text(
                        l10n.noJoinedMeetings,
                        style: AppTextStyles.body(context).copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: EdgeInsets.all(AppDimens.paddingM),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final meeting = provider.myMeetings[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: AppDimens.paddingM),
                      child: MeetingCard(
                        meeting: meeting,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MeetingDetailScreen(meetingId: meeting.id),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  childCount: provider.myMeetings.length,
                ),
              ),
            );
          },
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 80),
        ),
      ],
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: AppColors.surface,
              title: Text(
                l10n.navProfile,
                style: AppTextStyles.titleMedium(context),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(AppDimens.paddingL),
                child: Column(
                  children: [
                    // Profile Avatar
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        authProvider.nickname.isNotEmpty
                            ? authProvider.nickname[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    SizedBox(height: AppDimens.paddingM),
                    Text(
                      authProvider.nickname,
                      style: AppTextStyles.titleLarge(context),
                    ),
                    SizedBox(height: AppDimens.paddingS),
                    Text(
                      l10n.gamesPlayedCount(authProvider.userModel?.gamesPlayed ?? 0),
                      style: AppTextStyles.bodySmall(context),
                    ),
                    SizedBox(height: AppDimens.paddingXL),

                    // Stats Card
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(AppDimens.paddingL),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatItem(
                              label: l10n.statParticipation,
                              value: '${authProvider.userModel?.gamesPlayed ?? 0}',
                            ),
                            _StatItem(
                              label: l10n.statHosting,
                              value: '${authProvider.userModel?.gamesHosted ?? 0}',
                            ),
                            _StatItem(
                              label: l10n.statMvp,
                              value: '${authProvider.userModel?.mvpCount ?? 0}',
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: AppDimens.paddingM),

                    // Role Stats Card - v1.1에서 활성화 예정
                    // MVP에서는 핵심 지표만 표시
                    const _RoleStatsCard(),
                    SizedBox(height: AppDimens.paddingL),

                    // Menu Items
                    _MenuItem(
                      icon: GameIcons.edit,
                      title: l10n.changeNickname,
                      onTap: () => _showNicknameDialog(context, l10n),
                    ),
                    _MenuItem(
                      icon: GameIcons.notifications,
                      title: l10n.notificationSettings,
                      onTap: () => _showNotificationSettings(context, l10n),
                    ),
                    _MenuItem(
                      icon: GameIcons.info,
                      title: l10n.help,
                      onTap: () => _showHelpDialog(context, l10n),
                    ),
                    _MenuItem(
                      icon: Icons.discord,
                      title: '디스코드 커뮤니티',
                      subtitle: '지역별 모임 알림을 받아보세요',
                      onTap: () => _openDiscord(context),
                    ),
                    const Divider(height: 32),
                    // 커피 한 잔 사주기 - 설정 화면 맨 아래, 로그아웃 위
                    // 감정적 버튼: UX 방해 없이 진짜 팬만 누르도록
                    _MenuItem(
                      icon: Icons.coffee_outlined,
                      title: l10n.buyCoffee,
                      subtitle: l10n.buyCoffeeDescription,
                      onTap: () => _showDonationDialog(context, l10n),
                    ),
                    const SizedBox(height: 8),
                    _MenuItem(
                      icon: Icons.logout,
                      title: l10n.logout,
                      isDestructive: true,
                      onTap: () => authProvider.signOut(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showNicknameDialog(BuildContext context, AppLocalizations l10n) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          l10n.changeNickname,
          style: AppTextStyles.titleSmall(context),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: l10n.newNickname,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await context.read<AuthProvider>().updateNickname(controller.text.trim());
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: Text(l10n.change),
          ),
        ],
      ),
    );
  }

  /// Discord 커뮤니티 열기
  void _openDiscord(BuildContext context) async {
    // Analytics: 디스코드 클릭 이벤트
    AnalyticsService().logDiscordOpened();

    const discordUrl = 'https://discord.gg/kK3v7ZGdTV';
    final uri = Uri.parse(discordUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('링크를 열 수 없습니다')),
        );
      }
    }
  }

  /// 알림 설정 다이얼로그
  void _showNotificationSettings(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          l10n.notificationSettings,
          style: AppTextStyles.titleSmall(context),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _NotificationToggle(
              title: '모임 알림',
              subtitle: '새 모임이 등록되면 알려드려요',
              initialValue: true,
            ),
            _NotificationToggle(
              title: '참가 알림',
              subtitle: '모임에 새 참가자가 있으면 알려드려요',
              initialValue: true,
            ),
            _NotificationToggle(
              title: '게임 알림',
              subtitle: '게임 시작/종료 시 알려드려요',
              initialValue: true,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 도움말 다이얼로그
  void _showHelpDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.help_outline, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              l10n.help,
              style: AppTextStyles.titleSmall(context),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _HelpSection(
                title: '모임 만들기',
                content: '+ 버튼을 눌러 새 모임을 만들 수 있어요. 게임 종류, 장소, 시간을 설정하고 참가자를 모집해보세요.',
              ),
              _HelpSection(
                title: '모임 참가하기',
                content: '탐색 탭에서 원하는 모임을 찾아 참가할 수 있어요. 참가 코드가 있다면 QR 버튼을 눌러 입력하세요.',
              ),
              _HelpSection(
                title: '게임 진행',
                content: '모임 상세 화면에서 "게임 시작" 버튼을 눌러 게임을 시작할 수 있어요. 팀 배정 후 타이머가 시작됩니다.',
              ),
              _HelpSection(
                title: '퀵 메시지',
                content: '모임 중 간단한 상태 메시지를 보낼 수 있어요. "도착했어요", "늦어요" 등을 빠르게 전달하세요.',
              ),
              const SizedBox(height: 16),
              Text(
                '더 궁금한 점이 있다면 디스코드 커뮤니티에서 문의해주세요!',
                style: AppTextStyles.bodySmall(context).copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 커피 한 잔 사주기 다이얼로그
  ///
  /// 담백한 톤: 감정 과잉 없이, 선택적 응원임을 명확히
  void _showDonationDialog(BuildContext context, AppLocalizations l10n) {
    final donationService = DonationService();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Text('☕ '),
            Text(
              l10n.buyCoffee,
              style: AppTextStyles.titleSmall(context),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.donationMessage,
              style: AppTextStyles.bodyMedium(context),
            ),
            const SizedBox(height: 16),
            Text(
              donationService.coffeePrice,
              style: AppTextStyles.titleMedium(context).copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              final success = await donationService.buyCoffee();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? l10n.donationThanks : l10n.donationFailed,
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            icon: const Icon(Icons.coffee),
            label: Text(l10n.buyCoffeeButton),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: AppDimens.paddingXS),
        Text(
          label,
          style: AppTextStyles.bodySmall(context),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.textPrimary;

    return Semantics(
      label: subtitle != null ? '$title, $subtitle' : title,
      button: true,
      child: ListTile(
        leading: Icon(icon, color: color, size: AppDimens.iconM),
        title: Text(
          title,
          style: AppTextStyles.body(context).copyWith(color: color),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: AppTextStyles.caption(context).copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            : null,
        trailing: Icon(
          Icons.chevron_right,
          color: AppColors.textSecondary,
          size: AppDimens.iconM,
        ),
        onTap: onTap,
      ),
    );
  }
}

/// 역할별 통계 카드 - MVP에서는 Coming Soon
class _RoleStatsCard extends StatelessWidget {
  const _RoleStatsCard();

  @override
  Widget build(BuildContext context) {
    // MVP Phase: roleStats 제거됨
    // v1.1+에서 Cloud Function 집계 후 활성화
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppDimens.paddingL),
        child: Column(
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: AppDimens.iconL,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: AppDimens.paddingS),
            Text(
              '역할별 통계',
              style: AppTextStyles.body(context).copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: AppDimens.paddingXS),
            Text(
              '곧 추가될 예정이에요',
              style: AppTextStyles.bodySmall(context).copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// _RoleStatChip 제거됨 - roleStats가 MVP에서 제거됨
// v1.1+에서 Cloud Function 집계 후 복원 예정

/// 알림 설정 토글 위젯
class _NotificationToggle extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool initialValue;

  const _NotificationToggle({
    required this.title,
    required this.subtitle,
    required this.initialValue,
  });

  @override
  State<_NotificationToggle> createState() => _NotificationToggleState();
}

class _NotificationToggleState extends State<_NotificationToggle> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        widget.title,
        style: AppTextStyles.body(context),
      ),
      subtitle: Text(
        widget.subtitle,
        style: AppTextStyles.caption(context).copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Switch(
        value: _value,
        onChanged: (value) {
          setState(() => _value = value);
          // TODO: SharedPreferences에 저장
        },
        activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.textSecondary;
        }),
      ),
    );
  }
}

/// 도움말 섹션 위젯
class _HelpSection extends StatelessWidget {
  final String title;
  final String content;

  const _HelpSection({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleSmall(context).copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: AppTextStyles.bodySmall(context),
          ),
        ],
      ),
    );
  }
}
