import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================================
// 술래 디자인 시스템
// ============================================================
//
// 핵심 철학:
// - 행동을 줄이고, 상태를 전달하는 UI
// - 화면을 오래 보지 않게 만드는 구조
// - 야외/햇빛/이동 중에도 가독성 확보
// - 팀 구분이 직관적으로 드러나는 색상
//
// 드림플로 디자인 시스템 기반:
// - 텍스트 규칙화 ✅
// - 카드 중심 정보 전달 ✅
// - 큰 버튼, 넉넉한 패딩 ✅
// - Glassmorphism 제한적 사용 (야외 대비 고려)
// ============================================================

// ============================================================
// 1. 컬러 시스템 (야외 친화적)
// ============================================================

class AppColors {
  // ==================== 브랜드 컬러 ====================
  /// 활동 오렌지 - 에너지, 즐거움
  static const Color primary = Color(0xFFFF6B35);
  static const Color primaryLight = Color(0xFFFF8A5C);
  static const Color primaryDark = Color(0xFFE55A2B);

  /// 민트 - 신선함, 야외
  static const Color secondary = Color(0xFF4ECDC4);
  static const Color secondaryLight = Color(0xFF7EDDD6);
  static const Color secondaryDark = Color(0xFF3DBDB5);

  // ==================== 팀 컬러 (Q1 답변) ====================
  // 원칙: 색맹/색약 고려, 야외 햇빛 아래 구분 가능
  // 전략: 색상 + 명도 차이 + 아이콘으로 삼중 구분

  /// 경찰 - 차분한 블루 (권위, 규칙)
  static const Color cops = Color(0xFF2196F3);
  static const Color copsLight = Color(0xFF64B5F6);
  static const Color copsDark = Color(0xFF1976D2);

  /// 도둑 - 따뜻한 레드오렌지 (도전, 스릴)
  static const Color robbers = Color(0xFFFF5722);
  static const Color robbersLight = Color(0xFFFF8A65);
  static const Color robbersDark = Color(0xFFE64A19);

  /// 술래 (숨바꼭질) - 퍼플 (미스터리)
  static const Color seekers = Color(0xFF9C27B0);
  static const Color seekersLight = Color(0xFFBA68C8);
  static const Color seekersDark = Color(0xFF7B1FA2);

  /// 숨는이 - 그린 (자연, 은신)
  static const Color hiders = Color(0xFF4CAF50);
  static const Color hidersLight = Color(0xFF81C784);
  static const Color hidersDark = Color(0xFF388E3C);

  /// 공격팀 - 레드
  static const Color attackers = Color(0xFFE53935);

  /// 수비팀 - 블루
  static const Color defenders = Color(0xFF1E88E5);

  // ==================== 게임 타입 컬러 ====================
  static const Color copsAndRobbers = Color(0xFFFF6B35);
  static const Color freezeTag = Color(0xFF4ECDC4);
  static const Color hideAndSeek = Color(0xFF9B59B6);
  static const Color captureFlag = Color(0xFF3498DB);

  // ==================== 중립/배경 ====================
  /// 밝은 배경 (야외 가독성)
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF1F3F5);

  /// 텍스트 (높은 대비)
  static const Color textPrimary = Color(0xFF212529);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textTertiary = Color(0xFFADB5BD);
  static const Color textOnPrimary = Colors.white;
  static const Color textOnDark = Colors.white;

  /// 구분선
  static const Color divider = Color(0xFFE9ECEF);
  static const Color border = Color(0xFFDEE2E6);

  // ==================== 상태 컬러 ====================
  static const Color success = Color(0xFF28A745);
  static const Color successLight = Color(0xFFD4EDDA);
  static const Color warning = Color(0xFFFFC107);
  static const Color warningLight = Color(0xFFFFF3CD);
  static const Color error = Color(0xFFDC3545);
  static const Color errorLight = Color(0xFFF8D7DA);
  static const Color info = Color(0xFF17A2B8);
  static const Color infoLight = Color(0xFFD1ECF1);

  // ==================== 특수 용도 ====================
  /// 진동 타이머 배경
  static const Color timerBackground = Color(0xFF1A1A2E);
  static const Color timerText = Colors.white;

  /// 비활성화
  static const Color disabled = Color(0xFFCED4DA);
  static const Color disabledText = Color(0xFF868E96);

  // ==================== 그라데이션 ====================
  /// 게임 시작 그라데이션
  static LinearGradient get gameStartGradient => const LinearGradient(
        colors: [primary, primaryLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// 경찰팀 그라데이션
  static LinearGradient get copsGradient => const LinearGradient(
        colors: [cops, copsLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// 도둑팀 그라데이션
  static LinearGradient get robbersGradient => const LinearGradient(
        colors: [robbers, robbersLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}

// ============================================================
// 2. 간격 및 크기 (8의 배수 기반)
// ============================================================

class AppDimens {
  // ==================== 패딩/마진 ====================
  static const double paddingXS = 4;
  static const double paddingS = 8;
  static const double paddingM = 16;
  static const double paddingL = 24;
  static const double paddingXL = 32;
  static const double paddingXXL = 48;

  /// 화면 패딩
  static const double screenPaddingH = 20;
  static const double screenPaddingV = 16;
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: screenPaddingH,
    vertical: screenPaddingV,
  );

  // ==================== 둥근 모서리 ====================
  static const double radiusS = 8;
  static const double radiusM = 12;
  static const double radiusL = 16;
  static const double radiusXL = 24;
  static const double radiusFull = 999;

  static BorderRadius get cardBorderRadius => BorderRadius.circular(radiusM);
  static BorderRadius get buttonBorderRadius => BorderRadius.circular(radiusM);
  static BorderRadius get chipBorderRadius => BorderRadius.circular(radiusFull);

  // ==================== 버튼 높이 (야외 탭 고려) ====================
  static const double buttonHeightS = 36;
  static const double buttonHeightM = 48;
  static const double buttonHeightL = 56;
  static const double buttonHeightXL = 64;

  // ==================== 아이콘 크기 ====================
  static const double iconXS = 14;
  static const double iconS = 18;
  static const double iconM = 24;
  static const double iconL = 32;
  static const double iconXL = 48;
  static const double iconXXL = 64;

  // ==================== 카드 ====================
  static const double cardElevation = 2;
  static const double cardElevationHigh = 4;
  static const double cardPadding = 16;
  static EdgeInsets get cardPaddingAll => const EdgeInsets.all(cardPadding);

  // ==================== 그림자 ====================
  static const double elevationS = 2;
  static const double elevationM = 4;
  static const double elevationL = 8;

  // ==================== 특수 ====================
  /// 타이머 숫자 크기
  static const double timerFontSize = 72;

  /// 역할 칩 높이
  static const double roleChipHeight = 40;

  // ==================== 헬퍼 ====================
  static EdgeInsets paddingAll(double value) => EdgeInsets.all(value);
  static EdgeInsets paddingHorizontal(double value) =>
      EdgeInsets.symmetric(horizontal: value);
  static EdgeInsets paddingVertical(double value) =>
      EdgeInsets.symmetric(vertical: value);
}

// ============================================================
// 3. 텍스트 스타일
// ============================================================

class AppTextStyles {
  // ==================== 제목 ====================
  static TextStyle titleLarge(BuildContext context) =>
      Theme.of(context).textTheme.headlineMedium!.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          );

  static TextStyle titleMedium(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge!.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          );

  static TextStyle titleSmall(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          );

  // ==================== 본문 ====================
  static TextStyle bodyLarge(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge!.copyWith(
            color: AppColors.textPrimary,
          );

  static TextStyle body(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: AppColors.textPrimary,
          );

  /// body() 별칭 - 코드 일관성을 위해 제공
  static TextStyle bodyMedium(BuildContext context) => body(context);

  static TextStyle bodySmall(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall!.copyWith(
            color: AppColors.textSecondary,
          );

  /// 캡션 스타일 (subtitle보다 작은 보조 텍스트)
  static TextStyle caption(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall!.copyWith(
            fontSize: 12,
            color: AppColors.textTertiary,
          );

  // ==================== 레이블 ====================
  static TextStyle labelLarge(BuildContext context) =>
      Theme.of(context).textTheme.labelLarge!.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          );

  static TextStyle label(BuildContext context) =>
      Theme.of(context).textTheme.labelMedium!.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          );

  static TextStyle labelSmall(BuildContext context) =>
      Theme.of(context).textTheme.labelSmall!.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          );

  // ==================== 특수 ====================
  /// 강조 텍스트
  static TextStyle accent(BuildContext context) =>
      body(context).copyWith(color: AppColors.primary);

  /// 성공 메시지
  static TextStyle success(BuildContext context) =>
      body(context).copyWith(color: AppColors.success);

  /// 경고 메시지
  static TextStyle warning(BuildContext context) =>
      body(context).copyWith(color: AppColors.warning);

  /// 에러 메시지
  static TextStyle error(BuildContext context) =>
      body(context).copyWith(color: AppColors.error);

  /// 큰 숫자 (타이머, 라운드)
  static TextStyle counter(BuildContext context) => GoogleFonts.robotoMono(
        fontSize: AppDimens.timerFontSize,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      );

  /// 타이머 숫자 (다크 배경용)
  static TextStyle timerDisplay(BuildContext context) => GoogleFonts.robotoMono(
        fontSize: AppDimens.timerFontSize,
        fontWeight: FontWeight.bold,
        color: AppColors.timerText,
      );
}

// ============================================================
// 4. 캐릭터 메시지 (조용한 안내자)
// ============================================================

class GuideMessages {
  // Q3 답변: 캐릭터 등장 시점
  // 1. 게임 규칙 설명
  // 2. 역할 부족 알림
  // 3. 로컬 룰 확인 요청
  // 4. 에러/문제 상황

  static const String gameStart = '게임 시작합니다!';
  static const String roleNeeded = '경찰이 부족해요';
  static const String checkLocalRule = '로컬 룰을 확인하세요';
  static const String connectionLost = '연결이 끊어졌어요';
  static const String gameEnd = '게임이 끝났어요!';
  static const String mvpVote = 'MVP를 투표해주세요';
  static const String welcomeBack = '다시 만나서 반가워요!';
}

// ============================================================
// 5. 아이콘으로 충분한 정보 (Q2 답변)
// ============================================================

class GameIcons {
  // 텍스트 없이 아이콘만으로 이해 가능한 정보:
  // - 역할 구분: 경찰(방패), 도둑(마스크)
  // - 게임 상태: 진행중(플레이), 대기(시계)
  // - 기본 액션: 잡다(손), 탈출(달리기)

  // ==================== 역할 ====================
  static const IconData police = Icons.shield;
  static const IconData robber = Icons.masks;
  static const IconData seeker = Icons.visibility;
  static const IconData hider = Icons.visibility_off;

  // ==================== 게임 상태 ====================
  static const IconData playing = Icons.play_arrow;
  static const IconData waiting = Icons.access_time;
  static const IconData paused = Icons.pause;
  static const IconData finished = Icons.stop;

  // ==================== 액션 ====================
  static const IconData catch_ = Icons.pan_tool;
  static const IconData escape = Icons.directions_run;
  static const IconData freeze = Icons.ac_unit;
  static const IconData rescue = Icons.handshake;

  // ==================== 네비게이션 ====================
  static const IconData explore = Icons.explore;
  static const IconData meeting = Icons.event;
  static const IconData profile = Icons.person;
  static const IconData settings = Icons.settings;
  static const IconData notifications = Icons.notifications_outlined;

  // ==================== 일반 ====================
  static const IconData timer = Icons.timer;
  static const IconData location = Icons.location_on;
  static const IconData people = Icons.people;
  static const IconData rules = Icons.rule;
  static const IconData add = Icons.add;
  static const IconData edit = Icons.edit;
  static const IconData delete = Icons.delete;
  static const IconData share = Icons.share;
  static const IconData chat = Icons.chat_bubble_outline;
  static const IconData info = Icons.info_outline;

  // ==================== 게임 타입 ====================
  static const IconData copsAndRobbers = Icons.local_police;
  static const IconData freezeTag = Icons.ac_unit;
  static const IconData hideAndSeek = Icons.visibility_off;
  static const IconData captureFlag = Icons.flag;
  static const IconData custom = Icons.games;
}

// ============================================================
// 6. 테마
// ============================================================

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.notoSansKrTextTheme().copyWith(
        headlineLarge: GoogleFonts.notoSansKr(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.notoSansKr(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.notoSansKr(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.notoSansKr(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.notoSansKr(
          fontSize: 16,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.notoSansKr(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
        bodySmall: GoogleFonts.notoSansKr(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
        labelLarge: GoogleFonts.notoSansKr(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: GoogleFonts.notoSansKr(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: GoogleFonts.notoSansKr(
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.notoSansKr(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: AppDimens.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimens.cardBorderRadius,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: Size.fromHeight(AppDimens.buttonHeightL),
          padding: EdgeInsets.symmetric(
            horizontal: AppDimens.paddingL,
            vertical: AppDimens.paddingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppDimens.buttonBorderRadius,
          ),
          textStyle: GoogleFonts.notoSansKr(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          minimumSize: Size.fromHeight(AppDimens.buttonHeightL),
          padding: EdgeInsets.symmetric(
            horizontal: AppDimens.paddingL,
            vertical: AppDimens.paddingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppDimens.buttonBorderRadius,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.notoSansKr(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppDimens.paddingM,
          vertical: AppDimens.paddingM,
        ),
        border: OutlineInputBorder(
          borderRadius: AppDimens.buttonBorderRadius,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppDimens.buttonBorderRadius,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppDimens.buttonBorderRadius,
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppDimens.buttonBorderRadius,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppDimens.buttonBorderRadius,
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.notoSansKr(fontSize: 14),
        padding: EdgeInsets.symmetric(
          horizontal: AppDimens.paddingM,
          vertical: AppDimens.paddingS,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppDimens.chipBorderRadius,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: GoogleFonts.notoSansKr(
          color: Colors.white,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusS),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
