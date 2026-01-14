# 술래 (Sullae)

> 야외 단체 게임을 위한 모임 & 게임 진행 앱

## 한 줄 소개

**"경찰과 도둑, 얼음땡, 숨바꼭질 - 동네에서 함께 뛰어놀자!"**

---

## 핵심 기능

### 1. 빠른 모임 생성
- 게임 종류 선택 (경찰과 도둑, 얼음땡, 숨바꼭질, 깃발뺏기)
- 장소 & 시간 확정
- 6자리 참가 코드 자동 생성

### 2. 간편한 참가
- 참가 코드 입력으로 바로 참가
- QR코드 스캔 지원
- 역할 희망 선택 (경찰/도둑, 술래/도망자 등)

### 3. 팀 자동 배정
- 희망 역할 기반 팀 구성
- 균형 맞추기 or 강제 시작 선택 가능
- 상관없음 선택자는 랜덤 배치

### 4. 게임 진행
- 게임 타이머
- 팀별 현황 표시
- 라운드 관리

### 5. 룰 프리셋

- 커스텀 게임 룰 저장 & 재사용
- 공개 프리셋 공유
- 인기 프리셋 랭킹

### 6. 퀵 메시지 (자유 채팅 X)

- 정해진 메시지만 주고받는 통제된 소통
- "도착했어요", "5분 늦어요" 등 상황별 프리셋
- 게임 중 폰 사용 최소화

---

## 지원 게임

| 게임 | 역할 | 설명 |
|------|------|------|
| 경찰과 도둑 | 경찰 / 도둑 | 경찰이 도둑을 잡는 추격전 |
| 얼음땡 | 술래 / 도망자 | 술래에게 터치되면 얼음! 동료가 구출 |
| 숨바꼭질 | 술래 / 숨는이 | 클래식 숨바꼭질 |
| 깃발뺏기 | A팀 / B팀 | 상대 진영의 깃발을 뺏어오기 |
| 커스텀 | A팀 / B팀 | 자유롭게 규칙 설정 |

---

## 사용자 플로우

```
┌─────────────────────────────────────────────────────────┐
│                        호스트                            │
├─────────────────────────────────────────────────────────┤
│  1. 모임 생성                                            │
│     - 게임: 경찰과 도둑                                   │
│     - 장소: 한강공원 여의도지구                            │
│     - 시간: 오후 3시                                      │
│     - 인원: 10명                                         │
│                                                         │
│  2. 참가 코드 공유: K3X7P2                                │
│                                                         │
│  3. 공지: "2번 출구 앞에서 만나요!"                        │
│                                                         │
│  4. 게임 시작 버튼                                        │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                       참가자                             │
├─────────────────────────────────────────────────────────┤
│  1. 참가 코드 입력: K3X7P2                                │
│                                                         │
│  2. 역할 선택                                            │
│     ┌─────────┐  ┌─────────┐  ┌─────────┐              │
│     │  경찰   │  │  도둑   │  │ 상관없음 │              │
│     │  희망   │  │  희망   │  │         │              │
│     └─────────┘  └─────────┘  └─────────┘              │
│                                                         │
│  3. 대기 → 게임 시작                                     │
└─────────────────────────────────────────────────────────┘
```

---

## 핵심 철학: 게임 도구 ≠ 게임 앱

> **술래는 '게임 앱'이 아니라 '게임 진행 도구'다.**

| 상황 | 앱 사용 | 설명 |
|------|---------|------|
| 모임 전 | O | 생성, 참가, 역할 선택 |
| 게임 시작 | O | 팀 배정 확인, 타이머 시작 |
| 게임 중 | **X** | 뛰어다니느라 폰 볼 시간 없음 |
| 라운드 종료 | O | 결과 확인, 다음 라운드 |
| 게임 종료 | O | 최종 결과, 다음 모임 예고 |

**자유 채팅이 없는 이유**: 게임 중 폰 사용 최소화. 퀵 메시지로 필수 소통만.

**진동 타이머**: 화면 안 봐도 진동 패턴으로 남은 시간 파악 (1분 남음 → 길게 2번 진동)

---

## 당근마켓 모임 vs 술래

| 기능 | 당근 모임 | 술래 |
|------|----------|------|
| 장소 협의 | 채팅으로 협의 | 호스트가 확정 |
| 참가 방식 | 글 → 댓글 → 채팅 | 코드 입력으로 즉시 |
| 팀 구성 | 없음 | 역할 희망 + 자동 배정 |
| 게임 진행 | 없음 | 타이머, 라운드, 점수 |
| 목적 | 범용 모임 | 야외 게임 특화 |

---

## 기술 스택

- **Frontend**: Flutter
- **Backend**: Firebase (Firestore, Auth)
- **상태관리**: Provider / Riverpod
- **지도**: Google Maps (장소 선택)

---

## 파일 구조

```
lib/
├── models/
│   ├── meeting_model.dart        # 모임 데이터 모델
│   ├── meeting_preview_model.dart # 모임 미리보기 (연령대/강도)
│   ├── game_preset_model.dart    # 게임 룰 프리셋
│   ├── rule_card_model.dart      # 30초 룰 카드
│   ├── quick_message_model.dart  # 퀵 메시지 모델
│   ├── game_guide_model.dart     # 게임 가이드 (로컬 룰)
│   ├── game_timer_model.dart     # 진동 타이머
│   ├── review_model.dart         # 2단계 후기 시스템
│   └── role_honor_model.dart     # MVP/지원자 명예
├── services/
│   ├── meeting_service.dart      # 모임 CRUD, 참가 시스템
│   ├── game_service.dart         # 팀 배정, 게임 진행
│   ├── preset_service.dart       # 프리셋 관리
│   ├── quick_message_service.dart # 퀵 메시지 송수신
│   ├── game_guide_service.dart   # 가이드 배포
│   └── game_timer_service.dart   # 진동 타이머 관리
├── screens/
│   ├── home/                     # 홈 화면
│   ├── meeting/                  # 모임 생성/상세
│   └── game/                     # 게임 진행 화면
├── widgets/
│   └── common/                   # 공통 위젯 (AppCard, Shimmer 등)
└── utils/
    ├── app_theme.dart            # 테마, 컬러
    ├── app_text_styles.dart      # 텍스트 스타일
    └── app_dimens.dart           # 간격, 크기
```

---

## 핵심 모델

### MeetingModel
```dart
- id, title, description
- hostId, hostNickname
- gameType (경찰과도둑/얼음땡/숨바꼭질/깃발뺏기)
- location, latitude, longitude
- meetingTime
- maxParticipants, currentParticipants
- participantIds
- status (모집중/진행중/종료)
- joinCode (6자리 참가 코드)
- announcement (호스트 공지)
```

### GameService 주요 기능

```dart
- getRoleOptions(gameType)        // 게임별 역할 옵션
- checkTeamBalance(participants)  // 팀 균형 확인
- assignTeamsWithPreference()     // 희망 기반 팀 배정
```

### GamePreset (룰 프리셋)

```dart
- id, name, description
- creatorId, creatorNickname
- baseGameType (경찰과도둑/얼음땡/숨바꼭질/깃발뺏기)
- rules (게임별 커스텀 룰)
- isPublic (공개 여부)
- usageCount (사용 횟수)
```

### QuickMessage (퀵 메시지)

```dart
QuickMessageType:
- arrived       // 📍 지금 도착했어요
- late5         // ⏰ 5분 늦어요
- late10        // ⏰ 10분 늦어요
- ready         // ✅ 게임 시작 가능해요
- onMyWay       // 🚶 가고 있어요
- cantMake      // 👋 오늘 못 갈 것 같아요
- whereAreYou   // 📍 어디쯤이세요? (호스트용)
- startSoon     // ⏳ 곧 시작해요 (호스트용)
```

### GameGuide (게임 가이드)

```dart
- gameType              // 게임 종류
- localRules            // 로컬 룰 목록
- specialNote           // 특별 주의사항
- requirements          // 준비물 목록
- phases                // 진행 단계
- safetyRules           // 안전 수칙
```

### GameTimer (진동 타이머)

```dart
- totalSeconds          // 전체 시간
- remainingSeconds      // 남은 시간
- status                // ready/running/paused/finished
- alerts                // 진동 알림 설정

VibrationPattern (모든 게임 동일):
- 시작   → 짧게 2번  ━ ━
- 절반   → 길게 1번  ━━━
- 1분전  → 짧게 1번  ━
- 종료   → 길게 2번  ━━━ ━━━
```

### MeetingPreview (모임 미리보기)

```dart
- expectedAgeGroup      // 10대/20대/30대/혼합
- intensity             // 😌 라이트 / 🙂 보통 / 🔥 빡셈
- estimatedMinutes      // 예상 시간
- avgRating             // 평균 평점
```

### GameReview (2단계 후기)

```dart
1단계 (게임 직후):
- feeling: 😆/🙂/😐/😓
- quickNote (선택)

2단계 (다음 날):
- intensityFeedback     // 체력 난이도
- ageGroupFeedback      // 연령대 분위기
- willReturn            // 재참가 의향
```

### RoleHonor (역할 명예)

```dart
- MVP 투표 (게임 종료 후)
- 용감한 지원자 (먼저 손든 사람)
- 역할 로테이션 제안
```

---

## 브랜드 컬러

| 컬러 | 용도 |
|------|------|
| `#FF6B35` | Primary - 활동적인 오렌지 |
| `#4ECDC4` | Secondary - 신뢰의 민트 |
| `#2196F3` | 경찰팀 - 블루 |
| `#FF5722` | 도둑팀 - 레드오렌지 |
| `#9C27B0` | 술래 - 퍼플 |
| `#4CAF50` | 숨는이 - 그린 |

---

## 로드맵

### MVP (v1.0)

- [x] 모임 생성/참가 시스템
- [x] 6자리 참가 코드
- [x] 역할 희망 선택
- [x] 팀 자동 배정
- [x] 호스트 공지 기능
- [x] 퀵 메시지 시스템
- [x] 게임 가이드 (로컬 룰, 준비물, 안전 수칙)
- [x] 진동 타이머 (화면 안 봐도 시간 알림)

### v1.1

- [x] 룰 프리셋 저장/불러오기
- [ ] QR코드 생성/스캔
- [ ] 위치 기반 모임 검색
- [ ] 게임 타이머 UI

### v2.0

- [ ] 프리셋 공유 & 인기 랭킹
- [ ] 게임 기록/통계
- [ ] 커뮤니티 기능
