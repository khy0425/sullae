import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/meeting_model.dart';
import '../../providers/meeting_provider.dart';
import '../../services/meeting_service.dart';
import '../../utils/app_theme.dart';

/// 필터 바텀 시트
class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FilterBottomSheet(),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  // 임시 필터 상태 (적용 전까지 Provider에 반영하지 않음)
  late Region _tempRegion;
  late AgeGroupFilter _tempAgeGroup;
  late GroupSize? _tempGroupSize;
  late Difficulty? _tempDifficulty;
  late DistanceRange? _tempDistanceFilter;
  late bool _tempSortByDistance;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<MeetingProvider>();
    _tempRegion = provider.selectedRegion;
    _tempAgeGroup = provider.ageGroupFilter;
    _tempGroupSize = provider.selectedGroupSize;
    _tempDifficulty = provider.selectedDifficulty;
    _tempDistanceFilter = provider.distanceFilter;
    _tempSortByDistance = provider.sortByDistance;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // 핸들
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 헤더
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.filterTitle,
                      style: AppTextStyles.titleMedium(context),
                    ),
                    TextButton(
                      onPressed: _resetFilters,
                      child: Text(
                        l10n.resetFilters,
                        style: AppTextStyles.label(context).copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // 필터 목록
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.all(AppDimens.paddingM),
                  children: [
                    // 지역 필터 (광역시/도)
                    _buildFilterSection(
                      title: l10n.filterRegion,
                      icon: Icons.location_on_outlined,
                      child: _buildProvinceFilter(l10n),
                    ),

                    // 세부 지역 (서울/경기 선택 시)
                    if (_tempRegion.province == Province.seoul) ...[
                      SizedBox(height: AppDimens.paddingM),
                      _buildSubFilterSection(
                        title: '서울 세부 지역',
                        child: _buildSeoulDistrictFilter(l10n),
                      ),
                    ],
                    if (_tempRegion.province == Province.gyeonggi) ...[
                      SizedBox(height: AppDimens.paddingM),
                      _buildSubFilterSection(
                        title: '경기 세부 지역',
                        child: _buildGyeonggiDistrictFilter(l10n),
                      ),
                    ],
                    SizedBox(height: AppDimens.paddingL),

                    // 연령대 필터
                    _buildFilterSection(
                      title: l10n.filterAgeGroup,
                      icon: Icons.people_outline,
                      child: _buildAgeGroupFilter(l10n),
                    ),
                    SizedBox(height: AppDimens.paddingL),

                    // 인원 규모 필터
                    _buildFilterSection(
                      title: l10n.filterGroupSize,
                      icon: Icons.groups_outlined,
                      child: _buildGroupSizeFilter(l10n),
                    ),
                    SizedBox(height: AppDimens.paddingL),

                    // 분위기 필터
                    _buildFilterSection(
                      title: l10n.filterDifficulty,
                      icon: Icons.mood_outlined,
                      child: _buildDifficultyFilter(l10n),
                    ),
                    SizedBox(height: AppDimens.paddingL),

                    // 내 위치 기반 필터
                    _buildFilterSection(
                      title: '내 위치 기반',
                      icon: Icons.my_location,
                      child: _buildDistanceFilter(l10n),
                    ),
                    SizedBox(height: AppDimens.paddingXL),
                  ],
                ),
              ),
              // 적용 버튼
              Container(
                padding: EdgeInsets.all(AppDimens.paddingM),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _applyFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: AppDimens.paddingM),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppDimens.buttonBorderRadius,
                        ),
                      ),
                      child: Text(
                        l10n.applyFilters,
                        style: AppTextStyles.labelLarge(context).copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            SizedBox(width: AppDimens.paddingS),
            Text(
              title,
              style: AppTextStyles.titleSmall(context),
            ),
          ],
        ),
        SizedBox(height: AppDimens.paddingM),
        child,
      ],
    );
  }

  Widget _buildSubFilterSection({
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.all(AppDimens.paddingM),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: AppDimens.cardBorderRadius,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.label(context).copyWith(
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: AppDimens.paddingS),
          child,
        ],
      ),
    );
  }

  Widget _buildProvinceFilter(AppLocalizations l10n) {
    final provinces = [
      (Province.all, l10n.regionAll),
      (Province.seoul, l10n.regionSeoul),
      (Province.gyeonggi, l10n.regionGyeonggi),
      (Province.incheon, l10n.regionIncheon),
      (Province.busan, l10n.regionBusan),
      (Province.daegu, l10n.regionDaegu),
      (Province.daejeon, l10n.regionDaejeon),
      (Province.gwangju, l10n.regionGwangju),
      (Province.ulsan, l10n.regionUlsan),
      (Province.sejong, l10n.regionSejong),
      (Province.gangwon, l10n.regionGangwon),
      (Province.chungbuk, l10n.regionChungbuk),
      (Province.chungnam, l10n.regionChungnam),
      (Province.jeonbuk, l10n.regionJeonbuk),
      (Province.jeonnam, l10n.regionJeonnam),
      (Province.gyeongbuk, l10n.regionGyeongbuk),
      (Province.gyeongnam, l10n.regionGyeongnam),
      (Province.jeju, l10n.regionJeju),
    ];

    return Wrap(
      spacing: AppDimens.paddingS,
      runSpacing: AppDimens.paddingS,
      children: provinces.map((p) {
        final isSelected = _tempRegion.province == p.$1;
        return _buildFilterChip(
          label: p.$2,
          isSelected: isSelected,
          onTap: () => setState(() {
            _tempRegion = Region(province: p.$1);
          }),
        );
      }).toList(),
    );
  }

  Widget _buildSeoulDistrictFilter(AppLocalizations l10n) {
    final districts = [
      (SeoulDistrict.all, '전체'),
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

    return Wrap(
      spacing: AppDimens.paddingXS,
      runSpacing: AppDimens.paddingXS,
      children: districts.map((d) {
        final currentDistrict = _tempRegion.district as SeoulDistrict?;
        final isSelected = currentDistrict == d.$1 ||
            (d.$1 == SeoulDistrict.all && currentDistrict == null);
        return _buildFilterChip(
          label: d.$2,
          isSelected: isSelected,
          isSmall: true,
          onTap: () => setState(() {
            _tempRegion = Region(
              province: Province.seoul,
              district: d.$1 == SeoulDistrict.all ? null : d.$1,
            );
          }),
        );
      }).toList(),
    );
  }

  Widget _buildGyeonggiDistrictFilter(AppLocalizations l10n) {
    final districts = [
      (GyeonggiDistrict.all, '전체'),
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

    return Wrap(
      spacing: AppDimens.paddingXS,
      runSpacing: AppDimens.paddingXS,
      children: districts.map((d) {
        final currentDistrict = _tempRegion.district as GyeonggiDistrict?;
        final isSelected = currentDistrict == d.$1 ||
            (d.$1 == GyeonggiDistrict.all && currentDistrict == null);
        return _buildFilterChip(
          label: d.$2,
          isSelected: isSelected,
          isSmall: true,
          onTap: () => setState(() {
            _tempRegion = Region(
              province: Province.gyeonggi,
              district: d.$1 == GyeonggiDistrict.all ? null : d.$1,
            );
          }),
        );
      }).toList(),
    );
  }

  Widget _buildAgeGroupFilter(AppLocalizations l10n) {
    final ageGroups = [
      (AgeGroupFilter.all, l10n.ageGroupAll),
      (AgeGroupFilter.teens, l10n.ageGroupTeens),
      (AgeGroupFilter.twenties, l10n.ageGroupTwenties),
      (AgeGroupFilter.thirties, l10n.ageGroupThirties),
      (AgeGroupFilter.fortyPlus, l10n.ageGroupFortyPlus),
    ];

    return Wrap(
      spacing: AppDimens.paddingS,
      runSpacing: AppDimens.paddingS,
      children: ageGroups.map((a) {
        final isSelected = _tempAgeGroup == a.$1;
        return _buildFilterChip(
          label: a.$2,
          isSelected: isSelected,
          onTap: () => setState(() => _tempAgeGroup = a.$1),
        );
      }).toList(),
    );
  }

  Widget _buildGroupSizeFilter(AppLocalizations l10n) {
    final sizes = [
      (null, l10n.regionAll),
      (GroupSize.small, l10n.groupSizeSmall),
      (GroupSize.medium, l10n.groupSizeMedium),
      (GroupSize.large, l10n.groupSizeLarge),
    ];

    return Wrap(
      spacing: AppDimens.paddingS,
      runSpacing: AppDimens.paddingS,
      children: sizes.map((s) {
        final isSelected = _tempGroupSize == s.$1;
        return _buildFilterChip(
          label: s.$2,
          isSelected: isSelected,
          onTap: () => setState(() => _tempGroupSize = s.$1),
        );
      }).toList(),
    );
  }

  Widget _buildDifficultyFilter(AppLocalizations l10n) {
    final difficulties = [
      (null, l10n.regionAll),
      (Difficulty.casual, l10n.difficultyCasual),
      (Difficulty.competitive, l10n.difficultyCompetitive),
      (Difficulty.beginner, l10n.difficultyBeginner),
    ];

    return Wrap(
      spacing: AppDimens.paddingS,
      runSpacing: AppDimens.paddingS,
      children: difficulties.map((d) {
        final isSelected = _tempDifficulty == d.$1;
        return _buildFilterChip(
          label: d.$2,
          isSelected: isSelected,
          onTap: () => setState(() => _tempDifficulty = d.$1),
        );
      }).toList(),
    );
  }

  Widget _buildDistanceFilter(AppLocalizations l10n) {
    final provider = context.read<MeetingProvider>();
    final hasLocation = provider.hasUserLocation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 위치 권한 요청 버튼 또는 거리 필터
        if (!hasLocation && !_isLoadingLocation)
          OutlinedButton.icon(
            onPressed: _requestLocation,
            icon: const Icon(Icons.location_searching),
            label: const Text('내 위치 사용하기'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary),
            ),
          )
        else if (_isLoadingLocation)
          const Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text('위치 확인 중...'),
            ],
          )
        else ...[
          // 거리 필터 칩들
          Wrap(
            spacing: AppDimens.paddingS,
            runSpacing: AppDimens.paddingS,
            children: [
              _buildFilterChip(
                label: '전체',
                isSelected: _tempDistanceFilter == null,
                onTap: () => setState(() => _tempDistanceFilter = null),
              ),
              _buildFilterChip(
                label: '1km 이내',
                isSelected: _tempDistanceFilter == DistanceRange.within1km,
                onTap: () => setState(() => _tempDistanceFilter = DistanceRange.within1km),
              ),
              _buildFilterChip(
                label: '3km 이내',
                isSelected: _tempDistanceFilter == DistanceRange.within3km,
                onTap: () => setState(() => _tempDistanceFilter = DistanceRange.within3km),
              ),
              _buildFilterChip(
                label: '5km 이내',
                isSelected: _tempDistanceFilter == DistanceRange.within5km,
                onTap: () => setState(() => _tempDistanceFilter = DistanceRange.within5km),
              ),
              _buildFilterChip(
                label: '10km 이내',
                isSelected: _tempDistanceFilter == DistanceRange.within10km,
                onTap: () => setState(() => _tempDistanceFilter = DistanceRange.within10km),
              ),
            ],
          ),
          SizedBox(height: AppDimens.paddingM),
          // 거리순 정렬 토글
          Row(
            children: [
              Checkbox(
                value: _tempSortByDistance,
                onChanged: (value) => setState(() => _tempSortByDistance = value ?? false),
                activeColor: AppColors.primary,
              ),
              GestureDetector(
                onTap: () => setState(() => _tempSortByDistance = !_tempSortByDistance),
                child: Text(
                  '가까운 순으로 정렬',
                  style: AppTextStyles.body(context),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _requestLocation() async {
    setState(() => _isLoadingLocation = true);

    final provider = context.read<MeetingProvider>();
    final success = await provider.updateUserLocation();

    setState(() => _isLoadingLocation = false);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('위치 권한을 허용해주세요'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildFilterChip({
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
          style: (isSmall ? AppTextStyles.labelSmall(context) : AppTextStyles.labelSmall(context)).copyWith(
            color: isSelected ? Colors.white : AppColors.primary,
            fontWeight: FontWeight.w500,
            fontSize: isSmall ? 12 : null,
          ),
        ),
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _tempRegion = Region.all;
      _tempAgeGroup = AgeGroupFilter.all;
      _tempGroupSize = null;
      _tempDifficulty = null;
      _tempDistanceFilter = null;
      _tempSortByDistance = false;
    });
  }

  void _applyFilters() {
    final provider = context.read<MeetingProvider>();
    provider.setRegionFilter(_tempRegion);
    provider.setAgeGroupFilter(_tempAgeGroup);
    provider.setGroupSizeFilter(_tempGroupSize);
    provider.setDifficultyFilter(_tempDifficulty);
    provider.setDistanceFilter(_tempDistanceFilter);
    provider.setSortByDistance(_tempSortByDistance);
    Navigator.pop(context);
  }
}
