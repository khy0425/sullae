# 술래 앱 - n8n 워크플로우

SNS 자동화 마케팅을 위한 n8n 워크플로우 모음입니다.

## 워크플로우 목록

| 파일 | 설명 | 트리거 |
|------|------|--------|
| `01_twitter_new_meeting.json` | 새 모임 생성 시 Twitter 자동 포스팅 | Webhook |
| `02_discord_notifications.json` | Discord 서버 알림 (새 모임, 모집 완료, 마일스톤) | Webhook |
| `03_telegram_bot.json` | Telegram 채널 알림 + 일일 통계 | Webhook |
| `04_instagram_auto_reply.json` | Instagram 댓글 키워드 자동 응답 | Schedule (5분) |
| `05_multi_platform_broadcast.json` | 모든 플랫폼 동시 발송 | Webhook |

## 설치 방법

### 1. n8n 접속
```
https://your-n8n-domain.com
```

### 2. 워크플로우 가져오기
1. 좌측 메뉴 → Workflows
2. 우측 상단 "Import from File" 클릭
3. JSON 파일 선택

### 3. 자격 증명 설정

#### Twitter
1. Settings → Credentials → Add Credential
2. "Twitter OAuth2 API" 선택
3. Developer Portal에서 발급받은 키 입력

#### Discord
1. Discord 서버 설정 → 연동 → 웹후크
2. 새 웹후크 생성 → URL 복사
3. 워크플로우의 `webhookId` 값 교체

#### Telegram
1. @BotFather에서 봇 생성 및 토큰 획득
2. Settings → Credentials → Add Credential
3. "Telegram API" 선택 → 토큰 입력

#### Instagram
1. Facebook Developer에서 앱 생성
2. Instagram Graph API 추가
3. 비즈니스 계정 연결 및 토큰 발급

### 4. Firebase 환경 변수 설정

```bash
firebase functions:config:set n8n.webhook_url="https://your-n8n-domain.com/webhook"
firebase deploy --only functions
```

## 워크플로우 상세

### 01. Twitter 새 모임 포스팅

**트리거**: Firebase → `meetings` 컬렉션에 새 문서 생성

**동작**:
1. 웹훅으로 모임 정보 수신
2. 게임 타입별 이모지 매핑
3. 트윗 텍스트 포맷팅
4. Twitter API로 포스팅

**트윗 예시**:
```
🧊 오후 햇살 아래서!

📍 여의도 한강공원
🎮 얼음땡
⏰ 1월 6일 (토) 오후 3:00
👥 8명 모집

참가코드: HAN123

#술래 #술래잡기 #동네모임 #야외활동
```

### 02. Discord 알림

**채널 구조 권장**:
```
#새-모임      - 새 모임 생성 알림
#공지사항    - 모집 완료, 마일스톤 알림
#일반        - 자유 대화
```

**Embed 색상**:
- 새 모임: 파란색 (`5814783`)
- 모집 완료: 초록색 (`3066993`)
- 마일스톤: 골드색 (`15844367`)

### 03. Telegram 봇

**명령어**:
- `/start` - 알림 구독
- `/meetings` - 오늘 모집 중인 모임
- `/stats` - 일일 통계 (관리자)

### 04. Instagram 자동 응답

**키워드 매칭**:

| 키워드 | 응답 |
|--------|------|
| 다운, 앱, 설치 | 앱 다운로드는 프로필 링크에서! 🏃 |
| 어떻게, 참가, 방법 | 앱 설치 후 참가코드 입력하면 끝! |
| 서울, 경기, 부산... | 해당 지역 모임 있어요! |
| 재밌어, 좋아 | 감사합니다! 다음에 같이 뛰어요 🏃‍♂️ |

**Rate Limit**: 댓글당 2초 간격

### 05. 멀티 플랫폼 동시 발송

새 모임 생성 시 Twitter, Discord, Telegram에 동시 발송합니다.
각 플랫폼 포맷에 맞게 메시지가 자동 변환됩니다.

## 트러블슈팅

### 웹훅이 작동하지 않을 때
1. n8n이 실행 중인지 확인
2. 워크플로우가 "Active" 상태인지 확인
3. Firebase Functions 로그 확인: `firebase functions:log`

### Twitter 포스팅 실패
1. API 할당량 확인 (Free: 1,500/월)
2. OAuth 토큰 만료 여부 확인
3. 트윗 길이 280자 이하인지 확인

### Instagram 응답이 안 될 때
1. 비즈니스 계정인지 확인
2. 액세스 토큰 유효기간 확인 (60일)
3. 이미 응답한 댓글인지 확인 (중복 방지)

## 비용

| 서비스 | 비용 | 비고 |
|--------|------|-----|
| n8n (셀프호스팅) | $0 | 서버 비용 별도 |
| Twitter API (Free) | $0 | 1,500 트윗/월 |
| Discord Webhook | $0 | 무제한 |
| Telegram Bot API | $0 | 무제한 |
| Instagram Graph API | $0 | 비즈니스 계정 필요 |

---

*마지막 업데이트: 2026-01-03*
