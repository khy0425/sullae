# 술래 (Sullae)

> 야외 단체 게임을 위한 모임 & 게임 진행 플랫폼

<p align="center">
  <img src="assets/icons/app_icon.png" width="120" alt="술래 앱 아이콘">
</p>

<p align="center">
  <strong>"경찰과 도둑, 얼음땡, 숨바꼭질 - 동네에서 함께 뛰어놀자!"</strong>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#supported-games">Games</a> •
  <a href="#tech-stack">Tech Stack</a> •
  <a href="#getting-started">Getting Started</a> •
  <a href="#screenshots">Screenshots</a>
</p>

---

## Overview

**술래**는 야외에서 단체 게임을 즐기고 싶은 사람들을 위한 모임 생성 및 게임 진행 도구입니다.

어릴 적 동네에서 친구들과 뛰어놀던 추억의 게임들 - 경찰과 도둑, 얼음땡, 숨바꼭질을 성인이 되어서도 즐길 수 있도록 도와드립니다.

### 핵심 철학

> **술래는 '게임 앱'이 아니라 '게임 진행 도구'입니다.**

| 상황 | 앱 사용 | 설명 |
|:----:|:-------:|------|
| 모임 전 | ✅ | 생성, 참가, 역할 선택 |
| 게임 시작 | ✅ | 팀 배정 확인, 타이머 시작 |
| 게임 중 | ❌ | 뛰어다니느라 폰 볼 시간 없음! |
| 라운드 종료 | ✅ | 결과 확인, 다음 라운드 |
| 게임 종료 | ✅ | 최종 결과, 리뷰 |

---

## Features

### 1. 빠른 모임 생성
- 게임 종류 선택 (경찰과 도둑, 얼음땡, 숨바꼭질, 깃발뺏기)
- 장소 & 시간 확정
- **6자리 참가 코드** 자동 생성

### 2. 간편한 참가
- 참가 코드 입력으로 즉시 참가
- 역할 희망 선택 (경찰/도둑, 술래/도망자 등)
- 호스트 공지사항 확인

### 3. 팀 자동 배정
- 희망 역할 기반 팀 구성
- 균형 맞추기 or 강제 시작 선택
- "상관없음" 선택자는 랜덤 배치

### 4. 게임 진행 도구
- **진동 타이머**: 화면 안 봐도 진동 패턴으로 남은 시간 파악
  - 시작 → 짧게 2번
  - 절반 → 길게 1번
  - 1분전 → 짧게 1번
  - 종료 → 길게 2번
- 라운드 관리
- 팀별 현황 표시

### 5. 퀵 메시지 (자유 채팅 X)
- 정해진 메시지만 주고받는 **통제된 소통**
- "도착했어요", "5분 늦어요" 등 상황별 프리셋
- 게임 중 폰 사용 최소화

### 6. 룰 프리셋
- 커스텀 게임 룰 저장 & 재사용
- 공개 프리셋 공유
- 인기 프리셋 랭킹

### 7. 리뷰 시스템
- 2단계 후기 (게임 직후 + 다음 날)
- MVP 투표
- 호스트 평점

### 8. 알림 시스템
- **FCM 푸시 알림**: 모임 참가, 변경, 취소 시 자동 알림
- **로컬 리마인더**: 모임 30분 전 알림 (앱 종료 후에도 동작)
- **Discord 연동**: 지역별 채널에 새 모임 자동 알림

### 9. 지역 필터링
- 서울 25개 자치구 지원
- 경기도 주요 도시 지원
- 지역별 모임 검색

### 10. 모임 관리
- 모임 정보 수정 (시간, 장소, 설명)
- 방장 위임 기능
- 모임 취소/삭제

---

## Supported Games

| 게임 | 역할 | 설명 |
|------|------|------|
| 🚔 **경찰과 도둑** | 경찰 / 도둑 | 경찰이 도둑을 잡는 추격전 |
| 🧊 **얼음땡** | 술래 / 도망자 | 술래에게 터치되면 얼음! 동료가 구출 |
| 👀 **숨바꼭질** | 술래 / 숨는이 | 클래식 숨바꼭질 |
| 🚩 **깃발뺏기** | A팀 / B팀 | 상대 진영의 깃발을 뺏어오기 |
| ⚙️ **커스텀** | 자유 설정 | 자유롭게 규칙 설정 |

---

## Tech Stack

| Category | Technology |
|----------|------------|
| **Framework** | Flutter 3.x |
| **State Management** | Provider |
| **Backend** | Firebase (Firestore, Auth, Cloud Functions) |
| **Authentication** | Google, Apple, Kakao 소셜 로그인 |
| **Push Notification** | Firebase Cloud Messaging + Local Notifications |
| **Scheduled Notifications** | timezone + zonedSchedule (앱 종료 후에도 동작) |
| **Analytics** | Firebase Analytics |
| **Crash Reporting** | Firebase Crashlytics |
| **Monetization** | Google AdMob (배너, 전면 광고) |
| **In-App Purchase** | 커피 한 잔 사주기 (개발자 후원) |
| **Location** | Geolocator |
| **Automation** | n8n 웹훅 연동 (Discord 자동 알림) |

---

## Project Structure

```
lib/
├── models/              # 데이터 모델
│   ├── meeting_model.dart
│   ├── user_model.dart
│   ├── game_preset_model.dart
│   └── ...
├── providers/           # 상태 관리
│   ├── auth_provider.dart
│   ├── meeting_provider.dart
│   └── game_flow_provider.dart
├── screens/             # UI 화면
│   ├── auth/            # 로그인, 회원가입
│   ├── home/            # 홈 화면
│   ├── meeting/         # 모임 생성/상세
│   └── game/            # 게임 진행
├── services/            # 비즈니스 로직
│   ├── auth_service.dart
│   ├── meeting_service.dart
│   ├── notification_service.dart
│   ├── ad_service.dart
│   └── ...
├── widgets/             # 재사용 위젯
│   ├── ad_banner_widget.dart
│   └── ...
└── utils/               # 유틸리티

functions/
├── src/
│   ├── index.ts           # Cloud Functions 진입점
│   ├── notifications.ts   # FCM 푸시 알림
│   └── webhooks/
│       └── n8n.ts         # n8n 웹훅 (Discord 연동)
└── package.json
```

---

## Getting Started

### Prerequisites

- Flutter SDK 3.x
- Firebase CLI
- Android Studio / Xcode

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/sullae.git
   cd sullae
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a Firebase project
   - Add Android/iOS apps
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place them in appropriate directories

4. **Environment Setup**
   - Kakao SDK: Add native app key to `android/app/src/main/AndroidManifest.xml`
   - Google Sign-In: Configure OAuth consent screen

5. **Run the app**
   ```bash
   flutter run
   ```

---

## User Flow

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

## Brand Colors

| Color | Hex | Usage |
|-------|-----|-------|
| 🟠 Primary | `#FF6B35` | 활동적인 오렌지 |
| 🔵 Secondary | `#4ECDC4` | 신뢰의 민트 |
| 🔵 Police | `#2196F3` | 경찰팀 |
| 🔴 Thief | `#FF5722` | 도둑팀 |
| 🟣 Seeker | `#9C27B0` | 술래 |
| 🟢 Hider | `#4CAF50` | 숨는이 |

---

## Roadmap

### ✅ v1.0 (MVP)

- [x] 소셜 로그인 (Google, Apple, Kakao)
- [x] 모임 생성/참가 시스템
- [x] 6자리 참가 코드
- [x] 역할 희망 선택 & 팀 자동 배정
- [x] 퀵 메시지 시스템
- [x] 게임 가이드 (로컬 룰, 준비물, 안전 수칙)
- [x] 진동 타이머

### ✅ v1.1

- [x] 룰 프리셋 저장/불러오기
- [x] FCM 푸시 알림 (Cloud Functions)
- [x] 로컬 리마인더 (앱 종료 후에도 동작)
- [x] 모임 정보 변경 알림
- [x] 지역별 필터링 (서울 25개구, 경기도)
- [x] 방장 위임 기능
- [x] 모임 수정/삭제
- [x] Discord 커뮤니티 연동
- [x] 배너 광고 (AdMob)

### 🚧 v1.2

- [ ] QR코드 생성/스캔
- [ ] 위치 기반 모임 검색
- [ ] 전면 광고 최적화

### 📋 v2.0

- [ ] 프리셋 공유 & 인기 랭킹
- [ ] 게임 기록/통계
- [ ] 커뮤니티 기능

---

## Community

**Discord 커뮤니티**에서 지역별 모임 알림을 받아보세요!

[![Discord](https://img.shields.io/badge/Discord-술래_커뮤니티-5865F2?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/kK3v7ZGdTV)

- 📍 지역별 채널 (서울, 경기, 부산 등)
- 🎮 게임별 채널 (경찰과 도둑, 얼음땡 등)
- 📢 새 모임 자동 알림 (n8n 연동)

---

## License

This project is proprietary software. All rights reserved.

---

## Contact

- **Developer**: Reaf
- **Email**: contact@reaf.co
- **Website**: https://reaf.co

---

<p align="center">
  Made with ❤️ for outdoor game lovers
</p>
