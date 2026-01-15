import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/meeting_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/meeting_provider.dart';
import '../../utils/app_theme.dart';
import 'meeting_detail_screen.dart';

class CreateMeetingScreen extends StatefulWidget {
  const CreateMeetingScreen({super.key});

  @override
  State<CreateMeetingScreen> createState() => _CreateMeetingScreenState();
}

class _CreateMeetingScreenState extends State<CreateMeetingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _locationDetailController = TextEditingController();
  final _externalChatLinkController = TextEditingController();

  GameType _selectedGameType = GameType.copsAndRobbers;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _maxParticipants = 10;
  bool _isLoading = false;

  // 필터 관련 상태
  Region _selectedRegion = Region.all;
  Difficulty _selectedDifficulty = Difficulty.casual;
  List<String> _targetAgeGroups = []; // 빈 리스트 = 상관없음

  // 모임 생성 제한 관련
  int _activeMeetingsCount = 0;
  bool _canCreate = true;
  bool _isCheckingLimit = true;

  @override
  void initState() {
    super.initState();
    _checkMeetingLimit();
  }

  Future<void> _checkMeetingLimit() async {
    final authProvider = context.read<AuthProvider>();
    final meetingProvider = context.read<MeetingProvider>();

    final count = await meetingProvider.getActiveHostedMeetingsCount(authProvider.userId);
    final canCreate = await meetingProvider.canCreateMeeting(authProvider.userId);

    if (mounted) {
      setState(() {
        _activeMeetingsCount = count;
        _canCreate = canCreate;
        _isCheckingLimit = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _locationDetailController.dispose();
    _externalChatLinkController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    // iOS 스타일 휠 피커로 시간 선택
    await showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 280,
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            // 상단 바
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('취소', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  Text('시간 선택', style: AppTextStyles.titleSmall(context)),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('완료', style: TextStyle(color: AppColors.primary)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // 휠 피커
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: DateTime(
                  _selectedDate.year,
                  _selectedDate.month,
                  _selectedDate.day,
                  _selectedTime.hour,
                  _selectedTime.minute,
                ),
                use24hFormat: false,
                minuteInterval: 5, // 5분 단위
                onDateTimeChanged: (DateTime newTime) {
                  setState(() {
                    _selectedTime = TimeOfDay(hour: newTime.hour, minute: newTime.minute);
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createMeeting() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final meetingProvider = context.read<MeetingProvider>();

    final meetingTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final meetingId = await meetingProvider.createMeeting(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      hostId: authProvider.userId,
      hostNickname: authProvider.nickname,
      gameType: _selectedGameType,
      location: _locationController.text.trim(),
      locationDetail: _locationDetailController.text.trim().isNotEmpty
          ? _locationDetailController.text.trim()
          : null,
      meetingTime: meetingTime,
      maxParticipants: _maxParticipants,
      region: _selectedRegion,
      difficulty: _selectedDifficulty,
      targetAgeGroups: _targetAgeGroups,
      externalChatLink: _externalChatLinkController.text.trim().isNotEmpty
          ? _externalChatLinkController.text.trim()
          : null,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (meetingId != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MeetingDetailScreen(meetingId: meetingId),
        ),
      );
    } else {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(meetingProvider.error ?? l10n.createMeetingFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final meetingProvider = context.read<MeetingProvider>();
    final maxMeetings = meetingProvider.maxActiveMeetings;

    // 제한 확인 중이면 로딩 표시
    if (_isCheckingLimit) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            l10n.createMeeting,
            style: AppTextStyles.titleSmall(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // 생성 불가능하면 안내 표시
    if (!_canCreate) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            l10n.createMeeting,
            style: AppTextStyles.titleSmall(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(AppDimens.paddingL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.block,
                  size: 64,
                  color: AppColors.error,
                ),
                SizedBox(height: AppDimens.paddingL),
                Text(
                  '모임 생성 제한',
                  style: AppTextStyles.titleLarge(context),
                ),
                SizedBox(height: AppDimens.paddingM),
                Text(
                  '모임은 최대 $maxMeetings개까지만 생성할 수 있습니다.\n현재 $_activeMeetingsCount개의 활성 모임이 있습니다.',
                  style: AppTextStyles.body(context).copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppDimens.paddingM),
                Text(
                  '기존 모임을 취소하거나 완료한 후 새 모임을 생성해주세요.',
                  style: AppTextStyles.labelSmall(context).copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppDimens.paddingXL),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('돌아가기'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.createMeeting,
          style: AppTextStyles.titleSmall(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(AppDimens.paddingM),
          children: [
            // 모임 생성 현황 안내
            if (_activeMeetingsCount > 0)
              Container(
                margin: EdgeInsets.only(bottom: AppDimens.paddingM),
                padding: EdgeInsets.all(AppDimens.paddingM),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: AppDimens.cardBorderRadius,
                  border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.info, size: 20),
                    SizedBox(width: AppDimens.paddingS),
                    Expanded(
                      child: Text(
                        '현재 $_activeMeetingsCount/$maxMeetings개 모임 운영 중',
                        style: AppTextStyles.labelSmall(context).copyWith(
                          color: AppColors.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Game Type Selection
            Text(
              l10n.gameType,
              style: AppTextStyles.titleSmall(context),
            ),
            SizedBox(height: AppDimens.paddingM),
            _GameTypeSelector(
              selected: _selectedGameType,
              onChanged: (type) => setState(() => _selectedGameType = type),
              l10n: l10n,
            ),
            SizedBox(height: AppDimens.paddingL),

            // Title
            TextFormField(
              controller: _titleController,
              style: AppTextStyles.body(context),
              decoration: InputDecoration(
                labelText: l10n.meetingTitle,
                hintText: l10n.meetingTitleHint,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.meetingTitleRequired;
                }
                return null;
              },
            ),
            SizedBox(height: AppDimens.paddingM),

            // Description
            TextFormField(
              controller: _descriptionController,
              style: AppTextStyles.body(context),
              decoration: InputDecoration(
                labelText: l10n.meetingDescription,
                hintText: l10n.meetingDescriptionHint,
              ),
              maxLines: 3,
            ),
            SizedBox(height: AppDimens.paddingM),

            // Location
            TextFormField(
              controller: _locationController,
              style: AppTextStyles.body(context),
              decoration: InputDecoration(
                labelText: l10n.location,
                hintText: l10n.locationHint,
                prefixIcon: Icon(GameIcons.location),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.locationRequired;
                }
                return null;
              },
            ),
            SizedBox(height: AppDimens.paddingM),

            // Location Detail
            TextFormField(
              controller: _locationDetailController,
              style: AppTextStyles.body(context),
              decoration: InputDecoration(
                labelText: l10n.locationDetail,
                hintText: l10n.locationDetailHint,
              ),
            ),
            SizedBox(height: AppDimens.paddingM),

            // External Chat Link (optional)
            TextFormField(
              controller: _externalChatLinkController,
              style: AppTextStyles.body(context),
              decoration: InputDecoration(
                labelText: l10n.externalChatLink,
                hintText: l10n.externalChatLinkHint,
                prefixIcon: const Icon(Icons.link),
                helperText: '카카오 오픈채팅 등 외부 채팅방을 연결할 수 있어요',
                helperMaxLines: 2,
              ),
              keyboardType: TextInputType.url,
            ),
            SizedBox(height: AppDimens.paddingL),

            // Region Selection
            Text(
              l10n.filterRegion,
              style: AppTextStyles.titleSmall(context),
            ),
            SizedBox(height: AppDimens.paddingM),
            _RegionSelector(
              selected: _selectedRegion,
              onChanged: (region) => setState(() => _selectedRegion = region),
              l10n: l10n,
            ),
            SizedBox(height: AppDimens.paddingL),

            // Difficulty Selection
            Text(
              l10n.filterDifficulty,
              style: AppTextStyles.titleSmall(context),
            ),
            SizedBox(height: AppDimens.paddingM),
            _DifficultySelector(
              selected: _selectedDifficulty,
              onChanged: (difficulty) => setState(() => _selectedDifficulty = difficulty),
              l10n: l10n,
            ),
            SizedBox(height: AppDimens.paddingL),

            // Age Group Selection
            Text(
              l10n.filterAgeGroup,
              style: AppTextStyles.titleSmall(context),
            ),
            SizedBox(height: AppDimens.paddingM),
            _AgeGroupMultiSelector(
              selected: _targetAgeGroups,
              onChanged: (groups) => setState(() => _targetAgeGroups = groups),
              l10n: l10n,
            ),
            SizedBox(height: AppDimens.paddingL),

            // Date & Time
            Text(
              l10n.dateTime,
              style: AppTextStyles.titleSmall(context),
            ),
            SizedBox(height: AppDimens.paddingM),
            Row(
              children: [
                Expanded(
                  child: _DateTimeButton(
                    icon: Icons.calendar_today,
                    label: DateFormat('M월 d일 (E)', 'ko_KR').format(_selectedDate),
                    onTap: _selectDate,
                  ),
                ),
                SizedBox(width: AppDimens.paddingM),
                Expanded(
                  child: _DateTimeButton(
                    icon: GameIcons.timer,
                    label: _selectedTime.format(context),
                    onTap: _selectTime,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppDimens.paddingL),

            // Max Participants
            Text(
              l10n.maxParticipants,
              style: AppTextStyles.titleSmall(context),
            ),
            SizedBox(height: AppDimens.paddingM),
            Row(
              children: [
                IconButton(
                  onPressed: _maxParticipants > 10
                      ? () => setState(() => _maxParticipants -= 10)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  iconSize: AppDimens.iconL,
                  color: AppColors.primary,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      l10n.participantsUnit(_maxParticipants),
                      style: AppTextStyles.titleLarge(context),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _maxParticipants < 2000
                      ? () => setState(() => _maxParticipants += 10)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                  iconSize: AppDimens.iconL,
                  color: AppColors.primary,
                ),
              ],
            ),
            Slider(
              value: _maxParticipants.toDouble(),
              min: 10,
              max: 2000,
              divisions: 199,  // (2000-10)/10 = 199
              activeColor: AppColors.primary,
              onChanged: (value) => setState(() => _maxParticipants = (value / 10).round() * 10),
            ),
            // 빠른 선택 버튼들
            Wrap(
              spacing: AppDimens.paddingS,
              runSpacing: AppDimens.paddingS,
              children: [10, 50, 100, 500, 1000, 2000].map((count) {
                final isSelected = _maxParticipants == count;
                return GestureDetector(
                  onTap: () => setState(() => _maxParticipants = count),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDimens.paddingM,
                      vertical: AppDimens.paddingXS,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: AppDimens.chipBorderRadius,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '$count명',
                      style: AppTextStyles.labelSmall(context).copyWith(
                        color: isSelected ? Colors.white : AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: AppDimens.paddingXL),

            // Create Button
            ElevatedButton(
              onPressed: _isLoading ? null : _createMeeting,
              child: _isLoading
                  ? SizedBox(
                      height: AppDimens.iconM,
                      width: AppDimens.iconM,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      l10n.createMeeting,
                      style: AppTextStyles.labelLarge(context).copyWith(
                        color: AppColors.textOnPrimary,
                      ),
                    ),
            ),
            SizedBox(height: AppDimens.paddingXL),
          ],
        ),
      ),
    );
  }
}

class _GameTypeSelector extends StatelessWidget {
  final GameType selected;
  final ValueChanged<GameType> onChanged;
  final AppLocalizations l10n;

  const _GameTypeSelector({
    required this.selected,
    required this.onChanged,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppDimens.paddingS,
      runSpacing: AppDimens.paddingS,
      children: GameType.values.map((type) {
        final isSelected = type == selected;
        final color = _getColor(type);
        final icon = _getIcon(type);
        final name = _getName(type);

        return GestureDetector(
          onTap: () => onChanged(type),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppDimens.paddingM,
              vertical: AppDimens.paddingM,
            ),
            decoration: BoxDecoration(
              color: isSelected ? color : color.withValues(alpha: 0.1),
              borderRadius: AppDimens.cardBorderRadius,
              border: Border.all(
                color: isSelected ? color : color.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: isSelected ? Colors.white : color, size: AppDimens.iconM),
                SizedBox(width: AppDimens.paddingS),
                Text(
                  name,
                  style: AppTextStyles.label(context).copyWith(
                    color: isSelected ? Colors.white : color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getColor(GameType type) {
    switch (type) {
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

  IconData _getIcon(GameType type) {
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

  String _getName(GameType type) {
    switch (type) {
      case GameType.copsAndRobbers:
        return l10n.gameCopsAndRobbers;
      case GameType.freezeTag:
        return l10n.gameFreezeTag;
      case GameType.hideAndSeek:
        return l10n.gameHideAndSeek;
      case GameType.captureFlag:
        return l10n.gameCaptureFlag;
      case GameType.custom:
        return l10n.gameCustom;
    }
  }
}

class _DateTimeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DateTimeButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: AppDimens.paddingM),
        side: BorderSide(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: AppDimens.iconS),
          SizedBox(width: AppDimens.paddingS),
          Text(
            label,
            style: AppTextStyles.label(context),
          ),
        ],
      ),
    );
  }
}

/// 지역 선택 위젯
class _RegionSelector extends StatefulWidget {
  final Region selected;
  final ValueChanged<Region> onChanged;
  final AppLocalizations l10n;

  const _RegionSelector({
    required this.selected,
    required this.onChanged,
    required this.l10n,
  });

  @override
  State<_RegionSelector> createState() => _RegionSelectorState();
}

class _RegionSelectorState extends State<_RegionSelector> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 광역시/도 선택
        Wrap(
          spacing: AppDimens.paddingXS,
          runSpacing: AppDimens.paddingXS,
          children: _buildProvinceChips(),
        ),
        // 세부 지역 (서울/경기 선택 시)
        if (widget.selected.province == Province.seoul) ...[
          SizedBox(height: AppDimens.paddingM),
          Container(
            padding: EdgeInsets.all(AppDimens.paddingS),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: AppDimens.cardBorderRadius,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '서울 세부 지역',
                  style: AppTextStyles.labelSmall(context).copyWith(
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: AppDimens.paddingS),
                Wrap(
                  spacing: AppDimens.paddingXS,
                  runSpacing: AppDimens.paddingXS,
                  children: _buildSeoulDistrictChips(),
                ),
              ],
            ),
          ),
        ],
        if (widget.selected.province == Province.gyeonggi) ...[
          SizedBox(height: AppDimens.paddingM),
          Container(
            padding: EdgeInsets.all(AppDimens.paddingS),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: AppDimens.cardBorderRadius,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '경기 세부 지역',
                  style: AppTextStyles.labelSmall(context).copyWith(
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: AppDimens.paddingS),
                Wrap(
                  spacing: AppDimens.paddingXS,
                  runSpacing: AppDimens.paddingXS,
                  children: _buildGyeonggiDistrictChips(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildProvinceChips() {
    final provinces = [
      (Province.seoul, widget.l10n.regionSeoul),
      (Province.gyeonggi, widget.l10n.regionGyeonggi),
      (Province.incheon, widget.l10n.regionIncheon),
      (Province.busan, widget.l10n.regionBusan),
      (Province.daegu, widget.l10n.regionDaegu),
      (Province.daejeon, widget.l10n.regionDaejeon),
      (Province.gwangju, widget.l10n.regionGwangju),
      (Province.ulsan, widget.l10n.regionUlsan),
      (Province.sejong, widget.l10n.regionSejong),
      (Province.gangwon, widget.l10n.regionGangwon),
      (Province.jeju, widget.l10n.regionJeju),
    ];

    return provinces.map((p) {
      final isSelected = widget.selected.province == p.$1;
      return _buildChip(
        label: p.$2,
        isSelected: isSelected,
        onTap: () => widget.onChanged(Region(province: p.$1)),
      );
    }).toList();
  }

  List<Widget> _buildSeoulDistrictChips() {
    final districts = [
      (SeoulDistrict.gangnam, '강남구'),
      (SeoulDistrict.gangdong, '강동구'),
      (SeoulDistrict.gangbuk, '강북구'),
      (SeoulDistrict.gangseo, '강서구'),
      (SeoulDistrict.gwanak, '관악구'),
      (SeoulDistrict.gwangjin, '광진구'),
      (SeoulDistrict.guro, '구로구'),
      (SeoulDistrict.geumcheon, '금천구'),
      (SeoulDistrict.nowon, '노원구'),
      (SeoulDistrict.dobong, '도봉구'),
      (SeoulDistrict.dongdaemun, '동대문구'),
      (SeoulDistrict.dongjak, '동작구'),
      (SeoulDistrict.mapo, '마포구'),
      (SeoulDistrict.seodaemun, '서대문구'),
      (SeoulDistrict.seocho, '서초구'),
      (SeoulDistrict.seongdong, '성동구'),
      (SeoulDistrict.seongbuk, '성북구'),
      (SeoulDistrict.songpa, '송파구'),
      (SeoulDistrict.yangcheon, '양천구'),
      (SeoulDistrict.yeongdeungpo, '영등포구'),
      (SeoulDistrict.yongsan, '용산구'),
      (SeoulDistrict.eunpyeong, '은평구'),
      (SeoulDistrict.jongno, '종로구'),
      (SeoulDistrict.jung, '중구'),
      (SeoulDistrict.jungnang, '중랑구'),
    ];

    return districts.map((d) {
      final currentDistrict = widget.selected.district as SeoulDistrict?;
      final isSelected = currentDistrict == d.$1;
      return _buildChip(
        label: d.$2,
        isSelected: isSelected,
        isSmall: true,
        onTap: () => widget.onChanged(Region(
          province: Province.seoul,
          district: d.$1,
        )),
      );
    }).toList();
  }

  List<Widget> _buildGyeonggiDistrictChips() {
    final districts = [
      (GyeonggiDistrict.suwon, '수원'),
      (GyeonggiDistrict.seongnam, '성남'),
      (GyeonggiDistrict.goyang, '고양'),
      (GyeonggiDistrict.yongin, '용인'),
      (GyeonggiDistrict.bucheon, '부천'),
      (GyeonggiDistrict.ansan, '안산'),
      (GyeonggiDistrict.anyang, '안양'),
      (GyeonggiDistrict.namyangju, '남양주'),
      (GyeonggiDistrict.hwaseong, '화성'),
      (GyeonggiDistrict.uijeongbu, '의정부'),
      (GyeonggiDistrict.siheung, '시흥'),
      (GyeonggiDistrict.gimpo, '김포'),
      (GyeonggiDistrict.gwangmyeong, '광명'),
      (GyeonggiDistrict.hanam, '하남'),
      (GyeonggiDistrict.gunpo, '군포'),
      (GyeonggiDistrict.icheon, '이천'),
      (GyeonggiDistrict.osan, '오산'),
      (GyeonggiDistrict.paju, '파주'),
      (GyeonggiDistrict.pyeongtaek, '평택'),
      (GyeonggiDistrict.other, '기타'),
    ];

    return districts.map((d) {
      final currentDistrict = widget.selected.district as GyeonggiDistrict?;
      final isSelected = currentDistrict == d.$1;
      return _buildChip(
        label: d.$2,
        isSelected: isSelected,
        isSmall: true,
        onTap: () => widget.onChanged(Region(
          province: Province.gyeonggi,
          district: d.$1,
        )),
      );
    }).toList();
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool isSmall = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? AppDimens.paddingS : AppDimens.paddingM,
          vertical: isSmall ? 6 : AppDimens.paddingS,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.08),
          borderRadius: AppDimens.chipBorderRadius,
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall(context).copyWith(
            color: isSelected ? Colors.white : AppColors.primary,
            fontWeight: FontWeight.w500,
            fontSize: isSmall ? 12 : null,
          ),
        ),
      ),
    );
  }
}

/// 분위기 선택 위젯
class _DifficultySelector extends StatelessWidget {
  final Difficulty selected;
  final ValueChanged<Difficulty> onChanged;
  final AppLocalizations l10n;

  const _DifficultySelector({
    required this.selected,
    required this.onChanged,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final difficulties = [
      (Difficulty.casual, l10n.difficultyCasual, Icons.sentiment_satisfied_alt),
      (Difficulty.competitive, l10n.difficultyCompetitive, Icons.sports_score),
      (Difficulty.beginner, l10n.difficultyBeginner, Icons.waving_hand),
    ];

    return Wrap(
      spacing: AppDimens.paddingS,
      runSpacing: AppDimens.paddingS,
      children: difficulties.map((d) {
        final isSelected = selected == d.$1;
        return GestureDetector(
          onTap: () => onChanged(d.$1),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppDimens.paddingM,
              vertical: AppDimens.paddingS,
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  d.$3,
                  size: 18,
                  color: isSelected ? Colors.white : AppColors.secondary,
                ),
                SizedBox(width: AppDimens.paddingXS),
                Text(
                  d.$2,
                  style: AppTextStyles.label(context).copyWith(
                    color: isSelected ? Colors.white : AppColors.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// 연령대 복수 선택 위젯
class _AgeGroupMultiSelector extends StatelessWidget {
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  final AppLocalizations l10n;

  const _AgeGroupMultiSelector({
    required this.selected,
    required this.onChanged,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final ageGroups = [
      ('10s', l10n.ageGroupTeens),
      ('20s', l10n.ageGroupTwenties),
      ('30s', l10n.ageGroupThirties),
      ('40s+', l10n.ageGroupFortyPlus),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          selected.isEmpty ? '선택하지 않으면 "상관없음"으로 표시됩니다' : '복수 선택 가능',
          style: AppTextStyles.labelSmall(context).copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: AppDimens.paddingS),
        Wrap(
          spacing: AppDimens.paddingS,
          runSpacing: AppDimens.paddingS,
          children: ageGroups.map((a) {
            final isSelected = selected.contains(a.$1);
            return GestureDetector(
              onTap: () {
                final newList = List<String>.from(selected);
                if (isSelected) {
                  newList.remove(a.$1);
                } else {
                  newList.add(a.$1);
                }
                onChanged(newList);
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingM,
                  vertical: AppDimens.paddingS,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.success
                      : AppColors.success.withValues(alpha: 0.1),
                  borderRadius: AppDimens.chipBorderRadius,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.success
                        : AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      Icon(Icons.check, size: 16, color: Colors.white),
                      SizedBox(width: 4),
                    ],
                    Text(
                      a.$2,
                      style: AppTextStyles.label(context).copyWith(
                        color: isSelected ? Colors.white : AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
