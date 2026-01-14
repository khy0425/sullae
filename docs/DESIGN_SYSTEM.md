# 술래 디자인 시스템

> lucid_dream_100의 판아스트로 UI 패턴을 참고하여 구축된 통일된 디자인 시스템

## 개요

이 문서는 술래 앱의 디자인 시스템을 정의합니다. 일관된 UI/UX를 위해 모든 화면에서 이 시스템을 따릅니다.

---

## 1. 컬러 시스템 (AppColors)

**파일 위치:** `lib/utils/app_theme.dart`

### 브랜드 컬러

| 컬러 | Hex | 용도 |
|------|-----|------|
| `primary` | #FF6B35 | 활동적인 오렌지 (메인 액센트) |
| `primaryLight` | #FF8A5C | 연한 오렌지 |
| `primaryDark` | #E55A2B | 진한 오렌지 |
| `secondary` | #4ECDC4 | 신뢰의 민트/틸 |

### 팀 컬러

| 컬러 | Hex | 용도 |
|------|-----|------|
| `cops` | #2196F3 | 경찰팀 - 블루 |
| `robbers` | #FF5722 | 도둑팀 - 레드오렌지 |
| `seekers` | #9C27B0 | 술래 - 퍼플 |
| `hiders` | #4CAF50 | 숨는이 - 그린 |

### 게임 타입 컬러

| 컬러 | Hex | 게임 |
|------|-----|------|
| `copsAndRobbers` | #FF6B35 | 경찰과 도둑 |
| `freezeTag` | #4ECDC4 | 얼음땡 |
| `hideAndSeek` | #9B59B6 | 숨바꼭질 |
| `captureFlag` | #3498DB | 깃발뺏기 |

### 상태 컬러

| 컬러 | Hex | 용도 |
|------|-----|------|
| `success` | #28A745 | 성공, 참여 완료 |
| `warning` | #FFC107 | 경고, 마감 임박 |
| `error` | #DC3545 | 에러, 취소 |
| `info` | #17A2B8 | 정보, 진행중 |

---

## 2. 텍스트 스타일 (AppTextStyles)

**파일 위치:** `lib/utils/app_text_styles.dart`

### 제목 스타일

| 스타일 | 크기 | 굵기 | 용도 |
|--------|------|------|------|
| `titleLarge` | 24px | bold | 화면 타이틀, 주요 섹션 헤더 |
| `titleMedium` | 20px | bold | 카드 타이틀, 섹션 헤더 |
| `titleSmall` | 16px | w600 | 리스트 아이템 타이틀, 서브 헤더 |

### 본문 스타일

| 스타일 | 크기 | 굵기 | 용도 |
|--------|------|------|------|
| `bodyLarge` | 16px | normal | 주요 설명 텍스트 |
| `body` | 14px | normal | 일반 텍스트 (기본값) |
| `bodySmall` | 13px | normal | 보조 설명, 힌트 텍스트 |

### 특수 스타일

| 스타일 | 용도 |
|--------|------|
| `accent` | 강조 텍스트 (primary color) |
| `success` | 성공 메시지 |
| `warning` | 경고 메시지 |
| `error` | 에러 메시지 |
| `counter` | 큰 숫자 표시 (48px) |
| `timer` | 게임 타이머 (72px) |
| `teamName` | 팀 이름 (팀 컬러 적용) |

### 사용 예시

```dart
import '../../utils/app_text_styles.dart';

// 제목
Text('오늘의 모임', style: AppTextStyles.titleLarge(context))

// 본문
Text('장소: 한강공원', style: AppTextStyles.body(context))

// 강조
Text('모집중!', style: AppTextStyles.accent(context))

// 팀 이름
Text('경찰', style: AppTextStyles.teamName(context, AppColors.cops))
```

---

## 3. 간격 및 크기 (AppDimens)

**파일 위치:** `lib/utils/app_dimens.dart`

### 패딩/마진 (8의 배수 기반)

| 상수 | 값 | 용도 |
|------|-----|------|
| `paddingXS` | 4px | 아주 작은 간격 |
| `paddingS` | 8px | 작은 간격 |
| `paddingM` | 16px | 중간 간격 (기본값) |
| `paddingL` | 24px | 큰 간격 |
| `paddingXL` | 32px | 아주 큰 간격 |
| `screenPaddingH` | 20px | 화면 수평 패딩 |
| `screenPaddingV` | 16px | 화면 수직 패딩 |

### 둥근 모서리

| 상수 | 값 | 용도 |
|------|-----|------|
| `radiusS` | 8px | 작은 라운드 |
| `radiusM` | 12px | 카드 기본값 |
| `radiusL` | 16px | 큰 라운드 |
| `radiusXL` | 24px | 아주 큰 라운드 |
| `radiusFull` | 999px | 칩, 뱃지용 |

### 버튼 높이

| 상수 | 값 | 용도 |
|------|-----|------|
| `buttonHeightS` | 32px | 작은 버튼 |
| `buttonHeightM` | 44px | 중간 버튼 |
| `buttonHeightL` | 52px | 큰 버튼 (기본값) |
| `buttonHeightXL` | 60px | 아주 큰 버튼 |

### 게임 관련

| 상수 | 값 | 용도 |
|------|-----|------|
| `timerHeight` | 200px | 게임 타이머 영역 |
| `teamCardPadding` | 12px | 팀 카드 내부 패딩 |
| `avatarS` | 24px | 작은 아바타 |
| `avatarM` | 40px | 중간 아바타 |
| `avatarL` | 100px | 큰 아바타 |

### 사용 예시

```dart
import '../../utils/app_dimens.dart';

// 화면 기본 패딩
Padding(
  padding: AppDimens.screenPadding,
  child: ...
)

// 카드 BorderRadius
Container(
  decoration: BoxDecoration(
    borderRadius: AppDimens.cardBorderRadius,
  ),
)
```

---

## 4. Shimmer 로딩 (ShimmerLoading)

**파일 위치:** `lib/widgets/common/shimmer_loading.dart`

데이터 로딩 중 스켈레톤 UI를 표시하는 위젯입니다.

### 사용 가능한 타입

| 타입 | 용도 |
|------|------|
| `ShimmerLoading.card()` | 카드 형태 로딩 |
| `ShimmerLoading.meetingCard()` | 모임 카드 로딩 |
| `ShimmerLoading.listItem()` | 리스트 아이템 로딩 |
| `ShimmerLoading.textLine()` | 텍스트 라인 로딩 |
| `ShimmerLoading.circle()` | 원형 로딩 (아바타) |
| `ShimmerLoading.profileCard()` | 프로필 카드 로딩 |
| `ShimmerLoading.chatMessage()` | 채팅 메시지 로딩 |
| `ShimmerLoading.teamCard()` | 팀 카드 로딩 |

### 사용 예시

```dart
import '../../widgets/common/shimmer_loading.dart';

// 모임 카드 로딩 (3개)
isLoading
  ? ShimmerLoading.meetingCard(count: 3)
  : MeetingListWidget()

// 채팅 메시지 로딩
isLoading
  ? ShimmerLoading.chatMessage(count: 5)
  : ChatMessageList()
```

---

## 5. AppCard 변형 시스템

**파일 위치:** `lib/widgets/common/app_card.dart`

다양한 스타일의 카드를 일관되게 사용할 수 있는 시스템입니다.

### 카드 변형 타입

| 타입 | 용도 | 특징 |
|------|------|------|
| `content` | 기본 콘텐츠 카드 | 그림자, 배경색 |
| `highlight` | 강조 카드 | 그라데이션 배경 |
| `glass` | 유리 카드 | Glassmorphism 블러 |
| `outline` | 아웃라인 카드 | 테두리만 |
| `flat` | 플랫 카드 | 그림자 없음 |
| `team` | 팀 카드 | 팀 컬러 적용 |

### 사용 예시

```dart
import '../../widgets/common/app_card.dart';

// 기본 카드
AppCard(child: Text('내용'))

// 강조 카드 (게임 시작)
AppCard.highlight(
  child: Column(
    children: [
      Text('게임 시작!'),
      Text('10분 타이머'),
    ],
  ),
)

// 유리 카드
AppCard.glass(
  blurAmount: 10,
  child: Text('모던한 효과'),
)

// 팀 카드
AppCard.team(
  teamColor: AppColors.cops,
  child: Column(
    children: [
      Text('경찰팀'),
      Text('3명'),
    ],
  ),
)
```

---

## 파일 구조

```
lib/
├── utils/
│   ├── app_theme.dart        # 테마 및 AppColors
│   ├── app_text_styles.dart  # 텍스트 스타일
│   └── app_dimens.dart       # 간격 및 크기
├── widgets/
│   └── common/
│       ├── shimmer_loading.dart  # 스켈레톤 로딩
│       └── app_card.dart         # 카드 변형
```

---

## 변경 이력

| 날짜 | 변경 내용 |
|------|----------|
| 2026-01-01 | 초기 디자인 시스템 구축 |
|            | - AppColors (팀 컬러, 게임 타입 컬러) |
|            | - AppTextStyles (timer, teamName 추가) |
|            | - AppDimens (게임 관련 상수 추가) |
|            | - ShimmerLoading (meetingCard, chatMessage, teamCard) |
|            | - AppCard 변형 시스템 (team 카드 추가) |
