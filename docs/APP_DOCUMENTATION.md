# 술래 (Sullae) - 야외 술래잡기 게임 플랫폼

## 목차
1. [앱 개요](#1-앱-개요)
2. [기술 스택](#2-기술-스택)
3. [아키텍처](#3-아키텍처)
4. [주요 기능](#4-주요-기능)
5. [데이터 구조](#5-데이터-구조)
6. [사용자 플로우](#6-사용자-플로우)
7. [게임 타입](#7-게임-타입)
8. [개선점 및 TODO](#8-개선점-및-todo)

---

## 1. 앱 개요

### 소개
**술래**는 야외에서 즐기는 술래잡기 게임(경찰과 도둑, 얼음땡, 숨바꼭질 등)을 위한 모임 플랫폼입니다.

### 해결하는 문제

- 즉흥적으로 열리는 야외 게임을 체계적으로 조직
- 참가자 간 간단한 조율 (퀵메시지로 도착/지연 알림)
- 팀 배정 및 역할 관리 자동화
- 게임 피드백 수집으로 품질 향상

### 핵심 철학

- **"30초 회원가입"** - 소셜 로그인 후 닉네임만 입력하면 바로 시작
- **"자유 채팅 없음"** - 야외 게임은 직접 만나서 소통. 앱은 퀵메시지와 시스템 알림만 제공
- **"앱 없이도 가능한 놀이"** - 앱은 조율 도구일 뿐, 게임 자체는 오프라인에서 진행

---

## 2. 기술 스택

### Flutter & Dart
- **Flutter SDK**: ^3.9.2
- **Dart**: Latest stable

### Firebase 서비스
| 서비스 | 버전 | 용도 |
|--------|------|------|
| firebase_core | ^3.13.0 | Firebase 초기화 |
| firebase_auth | ^5.5.4 | 사용자 인증 |
| cloud_firestore | ^5.6.6 | 메인 데이터베이스 |
| firebase_database | ^11.3.4 | 게임 상태 + 시스템 메시지 (실시간) |
| firebase_messaging | ^15.2.4 | 푸시 알림 |
| firebase_storage | ^12.4.4 | 파일 저장 |
| firebase_remote_config | ^5.5.0 | 원격 설정 |

### 소셜 로그인
| 패키지 | 버전 |
|--------|------|
| google_sign_in | ^6.2.2 |
| kakao_flutter_sdk_user | ^1.10.0 |
| sign_in_with_apple | ^6.1.4 |

### 상태 관리
- **provider**: ^6.1.2 (ChangeNotifier 패턴)

### UI/UX
| 패키지 | 용도 |
|--------|------|
| flutter_animate | 애니메이션 |
| google_fonts | 타이포그래피 |
| flutter_svg | SVG 아이콘 |
| cached_network_image | 이미지 캐싱 |

### 광고
- **google_mobile_ads**: ^5.3.0 (AdMob 배너 + 전면 광고)

---

## 3. 아키텍처

### 폴더 구조
```
lib/
├── main.dart                    # 앱 진입점, 스플래시, 라우팅
├── firebase_options.dart        # Firebase 설정
│
├── models/                      # 데이터 모델 (10개)
│   ├── user_model.dart          # 사용자 프로필
│   ├── meeting_model.dart       # 모임 (핵심 모델)
│   ├── system_message_model.dart # 시스템 메시지
│   ├── quick_message_model.dart # 퀵메시지 (사용자 소통)
│   ├── game_preset_model.dart   # 게임 규칙 프리셋
│   ├── game_timer_model.dart    # 타이머
│   ├── vote_model.dart          # 투표
│   ├── review_model.dart        # 후기
│   └── ...
│
├── providers/                   # 상태 관리 (5개)
│   ├── auth_provider.dart       # 인증 상태
│   ├── meeting_provider.dart    # 모임 상태
│   ├── game_flow_provider.dart  # 게임 진행 (라운드/타이머)
│   ├── quick_message_provider.dart # 퀵메시지 (전송/쿨타임)
│   └── ad_provider.dart         # 광고 상태 (금지구간/타이밍)
│
├── services/                    # 비즈니스 로직 (13개)
│   ├── auth_service.dart        # Firebase Auth
│   ├── meeting_service.dart     # 모임 CRUD
│   ├── system_message_service.dart # 시스템 메시지
│   ├── quick_message_service.dart # 퀵메시지 (사용자 소통)
│   ├── game_service.dart        # 팀 배정
│   ├── game_timer_service.dart  # 타이머 관리
│   └── ...
│
├── screens/                     # UI 화면 (7개)
│   ├── auth/                    # 인증 관련
│   ├── home/                    # 메인 홈
│   ├── meeting/                 # 모임 관련
│   └── game/                    # 게임 화면
│
├── widgets/                     # 재사용 컴포넌트
│   ├── ad_banner_widget.dart
│   ├── meeting/
│   └── filter/
│
├── utils/                       # 유틸리티
│   └── app_theme.dart           # 디자인 시스템
│
└── l10n/                        # 다국어 지원
    ├── app_localizations.dart
    └── app_ko.arb / app_en.arb
```

### 데이터 흐름

```
┌─────────────────────────────────────────────────────────┐
│                         UI Layer                         │
│  (Screens: LoginScreen, HomeScreen, MeetingScreen...)   │
└─────────────────────────┬───────────────────────────────┘
                          │ User Actions
                          ▼
┌─────────────────────────────────────────────────────────┐
│                    Provider Layer                        │
│  AuthProvider, MeetingProvider, GameFlowProvider,       │
│  QuickMessageProvider (ChangeNotifier)                   │
└─────────────────────────┬───────────────────────────────┘
                          │ Business Logic
                          ▼
┌─────────────────────────────────────────────────────────┐
│                    Service Layer                         │
│ AuthService, MeetingService, SystemMessageService,      │
│ QuickMessageService, GameService                         │
└─────────────────────────┬───────────────────────────────┘
                          │ Firebase SDK
                          ▼
┌─────────────────────────────────────────────────────────┐
│                    Firebase Backend                      │
│      (Firestore, Realtime DB, Auth, Storage, FCM)       │
└─────────────────────────────────────────────────────────┘
```

### Provider 책임 분리

| Provider | 책임 | 상태 |
|----------|------|------|
| AuthProvider | 인증, 사용자 정보 | userId, nickname, isLoggedIn |
| MeetingProvider | 모임 목록, 필터링, CRUD | meetings, filters, currentMeeting |
| GameFlowProvider | 게임 진행, 라운드, 타이머 | round, timer, teamAssignments |
| QuickMessageProvider | 메시지 전송, 쿨타임 | isSending, cooldown, messages |
| AdProvider | 광고 타이밍, 금지구간 관리 | isInForbiddenZone, isBannerVisible |

> **설계 원칙**: 광고/게임/메시지 로직이 섞이지 않도록 Provider 분리
> **핵심 철학**: 게임 로직은 광고의 존재를 모른다. 광고는 이벤트를 구독하여 스스로 타이밍을 결정한다.

---

## 4. 주요 기능

### 4.1 인증 시스템
- **소셜 로그인**: Google, 카카오, Apple
- **30초 회원가입**: 닉네임만 필수, 연령대 선택
- **자동 로그인**: 마지막 로그인 방식 기억
- **프로필 관리**: 닉네임 변경, 계정 삭제

### 4.2 모임 생성 & 탐색
- **모임 생성**: 제목, 설명, 게임 타입, 장소, 시간, 최대 인원
- **참가 코드**: 6자리 영숫자 코드로 빠른 참여
- **실시간 업데이트**: Firestore 스트림으로 목록 자동 갱신
- **모임 상태**: recruiting → full → inProgress → finished/cancelled

### 4.3 필터링 시스템
| 필터 | 옵션 |
|------|------|
| 게임 타입 | 경찰과 도둑, 얼음땡, 숨바꼭질, 깃발뺏기 |
| 시간 | 오늘, 내일, 이번 주, 전체 |
| 지역 | 8개 광역시/도 + 세부 구/군 |
| 연령대 | 10대, 20대, 30대, 40대+ |
| 인원 규모 | 소규모(4-8), 중규모(9-15), 대규모(16+) |
| 난이도 | 캐주얼, 경쟁적, 초보 환영 |
| 모집 상태 | 모집중만 보기 |

### 4.4 소통 시스템 (자유 채팅 없음)

#### 설계 철학

앱은 **조율 도구**이지 소셜 플랫폼이 아님. 야외 게임은 직접 만나서 소통하는 것이 본질.
자유 채팅은 의도적으로 제외하여 앱의 정체성을 유지.

#### 시스템 메시지 (SystemMessageService)

시스템이 자동 발송하는 알림만 제공:

- 입장/퇴장 알림
- 게임 시작/종료
- 라운드 시작
- 방장 위임

#### 퀵메시지 (QuickMessageService)

미리 정의된 메시지 원터치 전송:

참가자용:

| 이모지 | 메시지 |
| ------ | ------ |
| 📍 | 지금 도착했어요 |
| 🚶 | 가고 있어요 |
| ⏰ | 5분 늦어요 / 10분 늦어요 |
| ✅ | 게임 시작 가능해요 |
| 🏃 | 먼저 가서 기다릴게요 |
| 👋 | 오늘 못 갈 것 같아요 |
| ❓ | 위치 변경됐나요? |

방장 전용:

| 이모지 | 메시지 |
| ------ | ------ |
| 📍 | 어디쯤이세요? |
| ⏳ | 곧 시작해요 |
| 🚪 | 입구에서 기다릴게요 |
| 📢 | 장소/시간 변경 공지 |
| 📢 | 커스텀 공지 (5-60자, 1분 쿨타임) |

#### 의도적으로 하지 않는 것

- 자유 텍스트 입력
- 메시지 히스토리 스크롤
- 답장/멘션/이모지 리액션
- 읽음 확인

### 4.5 게임 관리

- **역할 선호도**: 상관없음, 역할1, 역할2
- **팀 배정 알고리즘**: 선호도 반영 + 밸런스 체크
- **풀스크린 타이머**: 앱의 얼굴, 게임 중 가장 많이 보는 화면
  - 일시정지 없음 (오프라인 게임에서 불필요)
  - 라운드 표시 (Round 1/3)
  - 진동 알림 패턴 (모든 게임 동일, 패턴 수 = 의미):
    - 시작: 짧게 2번 (100ms-pause-100ms) → "뭔가 시작됨"
    - 절반: 길게 1번 (500ms) → "중간이다"
    - 1분 전: 짧게 3번 → 긴급성 전달
    - 종료: 길게 2번 (500ms-pause-500ms) → 시작과 대칭
    - **원칙**: 1번=정보, 2번=시작/끝, 3번=긴급
- **방장 자동 위임**: 방장 이탈 시 게임 중단 방지
  - 3분 미응답 시 자동 위임
  - 위임 우선순위: 가장 먼저 참가한 사용자
  - 참가자 없으면 모임 자동 취소
  - Realtime DB timestamp로 서버 로직 없이 구현

### 4.6 후기 시스템 (2단계)
**1단계 - 즉시 후기 (게임 종료 30초 후)**
- 이모지 반응: 😆 완전 재밌었어 / 🙂 괜찮았어 / 😐 별로였어 / 😓 힘들었어
- 짧은 메모 (선택)

**2단계 - 상세 후기 (다음날 푸시)**
- 체력 난이도 평가
- 연령대 분위기 평가
- 재참여 의향

### 4.7 통계 & 명예
- **사용자 통계**: 참여 횟수, 주최 횟수, MVP 횟수
- **역할별 통계**: 경찰/도둑/술래/숨는이/팀별 플레이 횟수
- **명예 시스템**: 오늘의 MVP, 용감한 지원자, 정신력상

### 4.8 광고 시스템

#### 설계 철학

**"게임 로직은 광고의 존재를 모른다"**

- 광고는 별도 Provider(AdProvider)에서 관리
- 게임/모임 로직에서 광고 코드 직접 호출 금지
- 광고는 이벤트를 구독하여 스스로 타이밍을 결정

#### 광고 금지 구간 (Forbidden Zones)

| 구간 | 사유 |
|------|------|
| 타이머 진행 중 | 게임 집중 방해 |
| 라운드 진행 중 | 게임 집중 방해 |
| 역할 선택 화면 | 선택 방해 |
| 팀 배정 화면 | 정보 확인 방해 |

#### 광고 허용 구간 (Safe Zones)

| 구간 | 광고 유형 |
|------|----------|
| 모임 생성 완료 후 | 전면 광고 (3회 액션마다) |
| 모임 참여 완료 후 | 전면 광고 (3회 액션마다) |
| 모임 퇴장 시 | 전면 광고 (3회 액션마다) |
| 게임 종료 후 | 전면 광고 (즉시) |
| 홈 화면 하단 | 배너 광고 (상시) |

#### AdProvider 상태 관리

```dart
// 광고 금지 구간 진입
adProvider.enterForbiddenZone(AdForbiddenReason.gameInProgress);

// 광고 금지 구간 퇴장 (대기 중인 광고 자동 표시)
adProvider.exitForbiddenZone();

// 이벤트 기반 광고 트리거 (게임 로직에서 직접 호출하지 않음)
adProvider.onGameEnded();      // 게임 종료 시
adProvider.onMeetingCreated(); // 모임 생성 시
adProvider.onMeetingJoined();  // 모임 참여 시
adProvider.onMeetingLeft();    // 모임 퇴장 시
```

#### 수익화 전략

- **현재**: AdMob 배너 + 전면 광고
- **향후**: 프리미엄 구독 (광고 제거, 대규모 모임 지원)

### 4.9 개발자 응원 (커피 한 잔 사주기)

#### 설계 철학

**"수익 최대화가 아닌 진짜 팬 확인"**

- 수익화 도구 ❌
- 팬 게이지 ⭕
- 감정적 연결 ⭕

#### 배치 원칙

| 원칙 | 이유 |
|------|------|
| 설정 화면에만 존재 | UX 방해 없음 |
| 첫 게임 종료 시 토스트로 한 번만 안내 | 최소한의 노출 |
| 기능과 연결되지 않음 | 순수 응원 |
| 실패해도 앱 흐름에 영향 없음 | 광고와 동일 원칙 |

#### 구현 파일

| 파일 | 역할 |
|------|------|
| `lib/services/donation_service.dart` | IAP 처리, 힌트 표시 상태 관리 |
| `lib/screens/home/home_screen.dart` | 설정 메뉴에 커피 항목 추가 |
| `lib/screens/game/game_screen.dart` | 첫 게임 종료 시 힌트 토스트 |

#### IAP 상품

| 상품 ID | 가격 | 유형 |
|---------|------|------|
| `coffee_donation` | ₩1,000 / $0.99 | 소모품 (Consumable) |

#### 힌트 표시 로직

```dart
// 첫 게임 종료 시에만 표시 (한 번만)
final shouldShow = await donationService.shouldShowHint();
if (shouldShow) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(l10n.donationHint)),
  );
  await donationService.markHintShown();
}
```

---

## 5. 데이터 구조

### Firestore 컬렉션

#### users/{uid}

```javascript
{
  nickname: "플레이어123",
  email: "user@example.com",
  photoUrl: "https://...",
  ageRange: 1,              // 0: teens, 1: 20s, 2: 30s, 3: 40s+
  loginProvider: 0,         // 0: google, 1: kakao, 2: apple
  gamesPlayed: 10,
  gamesHosted: 3,
  mvpCount: 2,
  createdAt: Timestamp,
  lastActiveAt: Timestamp
}
```

> **참고**: roleStats는 제거됨. 역할별 통계는 게임 복잡성 대비 사용 빈도가 낮아 단순화.

#### meetings/{meetingId}
```javascript
{
  title: "한강공원 경찰과 도둑",
  description: "재미있게 놀아요!",
  hostId: "uid123",
  hostNickname: "호스트닉네임",
  gameType: 0,              // 0: 경찰과도둑, 1: 얼음땡, 2: 숨바꼭질, 3: 깃발뺏기
  location: "여의도 한강공원",
  locationDetail: "3번 출구 앞",
  latitude: 37.5283,
  longitude: 126.9346,
  meetingTime: Timestamp,
  maxParticipants: 20,
  currentParticipants: 5,
  participantIds: ["uid1", "uid2", "uid3", "uid4", "uid5"],
  status: 0,                // 0: recruiting, 1: full, 2: inProgress, 3: finished, 4: cancelled
  joinCode: "ABC123",
  announcement: "준비물: 편한 옷",
  announcementAt: Timestamp,
  region: {
    province: 0,            // 0: 서울, 1: 경기, ...
    district: "영등포구"
  },
  difficulty: 0,            // 0: casual, 1: competitive, 2: beginner
  targetAgeGroups: ["20s", "30s"],
  gameSettings: {...},
  createdAt: Timestamp
}
```

### Realtime Database

> **용도**: 실시간 동기화가 필요한 데이터만 저장 (게임 상태, 시스템 메시지)

#### ⚠️ Source of Truth 원칙 (중요)

**"게임 진행 중 상태의 진실 소스는 Realtime DB다"**

| 데이터 | 진실 소스 | 이유 |
|--------|----------|------|
| 모임 정보 (제목, 장소, 인원) | Firestore | 자주 변경 안 됨 |
| 모임 상태 (recruiting, finished) | Firestore | 요약 상태 |
| 게임 진행 상태 (running, round, timer) | **Realtime DB** | 실시간 동기화 필수 |
| 시스템 메시지 | Realtime DB | 실시간 표시 |

**상태 불일치 시 처리 원칙:**
- 게임 중 UI 판단: Realtime DB `game_state`만 기준
- Firestore `status`는 게임 종료 후 최종 상태 반영용
- 네트워크 복구 시: Realtime DB 상태를 우선 신뢰

#### meetings/{meetingId}/game_state

게임 진행 중 실시간 상태 (방장 이탈 시에도 다른 참가자가 기준 유지):

```javascript
{
  status: "running",            // ready, running, paused, finished
  currentRound: 2,
  totalRounds: 3,
  remainingSeconds: 420,
  totalDurationSeconds: 600,    // 전체 게임 시간 (백그라운드 복귀 시 재계산용)
  startedAt: 1704067200000,     // 서버 타임스탬프 (Source of Truth)
  updatedAt: 1704067620000
}
```

> **백그라운드 복귀 처리**: `onAppResumed()` 호출 시 `startedAt` 기준으로 `remainingSeconds` 재계산. 클라이언트 시간 오차가 있어도 서버 기준으로 보정됨.

#### meetings/{meetingId}/system_messages/{messageId}

시스템이 자동 발송하는 알림 (입장/퇴장/게임 이벤트):

```javascript
{
  meetingId: "meeting123",
  senderId: "system",           // 항상 "system"
  senderNickname: "시스템",
  message: "플레이어123님이 입장하셨습니다.",
  timestamp: 1704067200000,     // milliseconds
  type: 1                       // 1: system, 3: game
}
```

> **메시지 타입**: `text(0)` 제거됨. system(1) 또는 game(3)만 사용.

### Firestore 서브컬렉션

#### meetings/{meetingId}/quick_messages/{messageId}

사용자가 보내는 퀵메시지 (미리 정의된 메시지만):

```javascript
{
  senderId: "uid123",
  senderNickname: "플레이어123",
  messageType: "arriving",      // 미리 정의된 메시지 키
  isAnnouncement: false,        // 방장 공지 여부
  customText: null,             // 커스텀 공지 시에만 사용
  timestamp: Timestamp
}
```

---

## 6. 사용자 플로우

### 신규 사용자 플로우
```
앱 실행
  ↓
스플래시 화면 (애니메이션)
  ↓
로그인 화면
  ├─ Google로 시작하기
  ├─ 카카오로 시작하기
  └─ Apple로 시작하기
  ↓
닉네임 입력 (2-10자, 실시간 검증)
  ↓
연령대 선택 (선택사항)
  ↓
홈 화면 (탐색 탭)
```

### 모임 생성 플로우
```
홈 화면 → [+ 모임 만들기]
  ↓
모임 생성 폼
  ├─ 제목 입력
  ├─ 설명 입력
  ├─ 게임 타입 선택
  ├─ 장소 입력
  ├─ 시간 선택
  ├─ 최대 인원 설정
  ├─ 지역 선택 (선택)
  ├─ 난이도 선택 (선택)
  └─ 대상 연령대 선택 (선택)
  ↓
[모임 만들기] 탭
  ↓
모임 상세 화면 (퀵메시지로 소통)
```

### 게임 진행 플로우

```
모임 상세 화면
  ↓
[게임 시작하기] (방장만)
  ↓
역할 선호도 선택 (모든 참가자)
  ↓
팀 배정 (자동 or 수동 조정)
  ↓
풀스크린 타이머 시작
  ├─ 라운드 표시 (Round 1/3)
  ├─ 진동 알림 (시작, 절반, 1분전, 종료)
  └─ 일시정지 없음 (오프라인 게임)
  ↓
게임 종료
  ↓
즉시 후기 작성 (30초 후)
```

---

## 7. 게임 타입

### 경찰과 도둑 (Cops & Robbers)
| 항목 | 설명 |
|------|------|
| 팀 구성 | 경찰 vs 도둑 |
| 게임 방식 | 경찰이 도둑을 잡음, 도둑은 시간 내 생존 |
| 기본 시간 | 15분 |
| 설정 옵션 | 감옥 위치, 구출 방법, 경찰 비율, 탈옥 허용 |

### 얼음땡 (Freeze Tag)
| 항목 | 설명 |
|------|------|
| 팀 구성 | 술래 vs 도망자 |
| 게임 방식 | 술래가 터치하면 얼음, 동료가 구출 |
| 기본 시간 | 10분 |
| 설정 옵션 | 술래 수, 해동 시간, 해동 방법, 자가 해동 |

### 숨바꼭질 (Hide & Seek)
| 항목 | 설명 |
|------|------|
| 팀 구성 | 술래 vs 숨는 사람 |
| 게임 방식 | 술래가 모든 숨는 사람을 찾음 |
| 기본 시간 | 15분 |
| 설정 옵션 | 술래 수, 숨는 시간, 술래 달리기 허용 |

### 깃발뺏기 (Capture Flag)
| 항목 | 설명 |
|------|------|
| 팀 구성 | A팀 vs B팀 |
| 게임 방식 | 상대팀 깃발을 빼앗아 옴 |
| 기본 시간 | 20분 |
| 설정 옵션 | 깃발 수, GPS 영역 사용, 자기 진영 터치 |

---

## 8. 개선점 및 TODO

### ✅ 해결됨 (Critical)

#### 1. 푸시 알림 ✅ 구현 완료

- **구현 파일**: `lib/services/notification_service.dart`
- **기능**:
  - 모임 시작 30분 전 리마인더 (flutter_local_notifications)
  - 새 참가자 알림 (방장에게)
  - 게임 시작 알림 (참가자들에게)
  - 방장 위임 알림
  - 후기 요청 알림 (게임 종료 1분 후)
  - 모임 취소 알림
- **템플릿**: `NotificationTemplates` 클래스로 메시지 표준화

#### 2. Firebase 보안 규칙 ✅ 구현 완료

- **Firestore**: `firestore.rules`
  - 사용자는 본인 프로필만 수정 가능
  - 모임은 방장만 수정/삭제 가능
  - 퀵메시지는 참가자만 추가 가능
  - Helper 함수: `isAuthenticated()`, `isMeetingHost()`, `isMeetingParticipant()`
- **Realtime DB**: `database.rules.json`
  - 게임 상태: 참가자만 읽기/쓰기
  - 위치 정보: 본인만 쓰기
  - Presence: 본인만 쓰기
  - 타이머: 참가자만 읽기/쓰기

#### 3. 에러 핸들링 ✅ 구현 완료

- **구현 파일**: `lib/services/error_handler_service.dart`
- **기능**:
  - 전역 에러 핸들링 (`main.dart`에서 설정)
  - Firebase Auth/Firestore 에러 → 한국어 메시지 변환
  - 네트워크/타임아웃 에러 감지
  - `Result<T>` 패턴으로 성공/실패 명시
  - `AppError` 클래스로 에러 타입 분류

### ✅ 해결됨 (Important)

#### 4. 페이지네이션 ✅ 구현 완료 (무한 스크롤)

- **구현 파일**:
  - `lib/services/meeting_service.dart` - `getFirstPage()`, `getNextPage()`
  - `lib/providers/meeting_provider.dart` - `loadFirstPage()`, `loadMoreMeetings()`
  - `lib/screens/home/home_screen.dart` - `ScrollController` 연동
- **기능**:
  - 20개씩 페이지네이션 로드
  - 스크롤 끝에서 200px 이내 도달 시 자동 로드
  - Pull-to-refresh 지원
  - 로딩 인디케이터 표시

#### 5. 위치 기반 기능 ✅ 구현 완료

- **구현 파일**:
  - `lib/services/geolocation_service.dart` - GPS 위치 서비스
  - `lib/services/meeting_service.dart` - `getNearbyMeetings()`, `addDistanceToMeetings()`, `filterByDistance()`
  - `lib/providers/meeting_provider.dart` - 위치 상태 관리 및 필터링
  - `lib/widgets/filter/filter_bottom_sheet.dart` - 거리 필터 UI
- **기능**:
  - GPS 기반 모임 탐색 (거리 계산)
  - 거리별 필터링 (1km, 3km, 5km, 10km)
  - 가까운 순 정렬
  - 위치 권한 요청 및 상태 관리
  - `MeetingWithDistance` 클래스로 거리 정보 포함

#### 6. 접근성 (Accessibility) ✅ 구현 완료

- **구현 파일**:
  - `lib/widgets/meeting/meeting_card.dart` - MeetingCard Semantics
  - `lib/screens/home/home_screen.dart` - 필터 칩, 메뉴 아이템 Semantics
  - `lib/screens/meeting/meeting_detail_screen.dart` - 퀵메시지 버튼 Semantics
- **기능**:
  - 스크린 리더 지원 (Semantics 위젯)
  - 모임 카드: 게임 타입, 제목, 상태, 장소, 시간, 참가자 수, 방장 정보 읽기
  - 필터 칩: 선택 상태 알림
  - 퀵메시지 버튼: 메시지 내용 및 활성화 상태 알림

### 🟡 Important (중요)

#### 1. 오프라인 지원 없음

- **현재**: 인터넷 필수
- **필요**: 로컬 캐싱 (Hive/SQLite) 또는 연결 상태 피드백

### 🟢 Nice to Have (있으면 좋음)

#### 1. 소셜 기능 확장

- 사용자 팔로우/친구 시스템
- 다른 사용자 프로필 보기
- 1:1 메시지

#### 2. 게임 내 기능 강화

- 실시간 점수판
- 게임 내 이벤트 추적
- 라운드 시스템

#### 3. 수익화 확장

- 프리미엄 기능 (광고 제거, 대규모 모임 등)
- 인앱 결제

#### 4. 테스트 코드 추가

- 유닛 테스트
- 위젯 테스트
- 통합 테스트

### 기술 부채 (Tech Debt)

| 항목 | 현재 상태 | 개선 방안 |
|------|----------|----------|
| 의존성 주입 | 서비스 직접 생성 | get_it 패키지 도입 |
| ~~에러 타입~~ | ~~bool 반환~~ | ~~Result 패턴 사용~~ ✅ 구현됨 |
| DateTime 처리 | 혼재 (Timestamp/epoch) | Timestamp로 통일 |
| 닉네임 검증 | 경합 조건 가능 | 분산 카운터 사용 |

---

## 부록: 주요 파일 참조

| 파일 | 용도 | 줄 수 |
|------|------|------|
| `lib/models/meeting_model.dart` | 모임 핵심 모델 | ~400 |
| `lib/services/meeting_service.dart` | 모임 CRUD | ~330 |
| `lib/providers/meeting_provider.dart` | 모임 상태 관리 | ~425 |
| `lib/screens/home/home_screen.dart` | 메인 홈 UI | ~1080 |
| `lib/screens/meeting/meeting_detail_screen.dart` | 모임 상세 UI | ~800 |
| `lib/utils/app_theme.dart` | 디자인 시스템 | ~560 |

---

*문서 최종 업데이트: 2026-01-03*
