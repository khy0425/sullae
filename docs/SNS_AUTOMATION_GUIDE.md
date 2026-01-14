# 술래 앱 - SNS 자동화 마케팅 시스템

## 개요

n8n을 활용한 SNS 자동화 마케팅 시스템 구축 가이드입니다.

### 자동화 대상 플랫폼

| 플랫폼 | 자동 포스팅 | 댓글 관리 | DM 응답 | 구현 난이도 |
|--------|------------|----------|---------|------------|
| Twitter/X | ✅ | ✅ | ✅ | 쉬움 |
| Discord | ✅ | ✅ | ✅ | 쉬움 |
| Telegram | ✅ | ✅ | ✅ | 쉬움 |
| Instagram | ❌ (이미지만) | ✅ | ✅ | 중간 |
| TikTok | ❌ | ✅ | ❌ | 어려움 |

---

## 1. n8n 설치 및 설정

### Docker로 설치 (권장)

```bash
# docker-compose.yml
version: '3.8'
services:
  n8n:
    image: n8nio/n8n
    restart: always
    ports:
      - "5678:5678"
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=your_secure_password
      - N8N_HOST=your-domain.com
      - N8N_PROTOCOL=https
      - WEBHOOK_URL=https://your-domain.com/
      - GENERIC_TIMEZONE=Asia/Seoul
    volumes:
      - n8n_data:/home/node/.n8n

volumes:
  n8n_data:
```

```bash
docker-compose up -d
```

### 클라우드 호스팅 옵션

- **Railway**: 월 $5~, 간편한 배포
- **Render**: 무료 티어 있음 (슬립 있음)
- **n8n Cloud**: 월 $20~, 공식 호스팅

---

## 2. Firebase 웹훅 연동

### Cloud Functions 설정

```javascript
// functions/src/webhooks/n8n.ts

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import fetch from 'node-fetch';

const N8N_WEBHOOK_URL = functions.config().n8n.webhook_url;

// 새 모임 생성 시 n8n에 알림
export const onMeetingCreated = functions
  .region('asia-northeast3')
  .firestore
  .document('meetings/{meetingId}')
  .onCreate(async (snapshot, context) => {
    const meeting = snapshot.data();
    const meetingId = context.params.meetingId;

    const payload = {
      event: 'meeting_created',
      meetingId,
      title: meeting.title,
      description: meeting.description,
      location: meeting.location,
      gameType: meeting.gameType,
      meetingTime: meeting.meetingTime.toDate().toISOString(),
      maxParticipants: meeting.maxParticipants,
      hostNickname: meeting.hostNickname,
      joinCode: meeting.joinCode,
      region: meeting.region,
    };

    try {
      await fetch(`${N8N_WEBHOOK_URL}/meeting-created`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });
      console.log('n8n webhook sent for meeting:', meetingId);
    } catch (error) {
      console.error('n8n webhook error:', error);
    }
  });

// 모임 참가자 변경 시
export const onParticipantChanged = functions
  .region('asia-northeast3')
  .firestore
  .document('meetings/{meetingId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const meetingId = context.params.meetingId;

    // 참가자 수가 변경된 경우만
    if (before.currentParticipants === after.currentParticipants) {
      return;
    }

    // 모집 완료 시 알림
    if (after.currentParticipants >= after.maxParticipants && before.currentParticipants < before.maxParticipants) {
      const payload = {
        event: 'meeting_full',
        meetingId,
        title: after.title,
        currentParticipants: after.currentParticipants,
        maxParticipants: after.maxParticipants,
      };

      try {
        await fetch(`${N8N_WEBHOOK_URL}/meeting-full`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload),
        });
      } catch (error) {
        console.error('n8n webhook error:', error);
      }
    }
  });

// 게임 종료 시 (하이라이트 공유용)
export const onGameEnded = functions
  .region('asia-northeast3')
  .firestore
  .document('games/{gameId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (before.status !== 'finished' && after.status === 'finished') {
      const payload = {
        event: 'game_ended',
        gameId: context.params.gameId,
        meetingId: after.meetingId,
        duration: after.duration,
        participantCount: after.participantCount,
        winnerTeam: after.winnerTeam,
      };

      try {
        await fetch(`${N8N_WEBHOOK_URL}/game-ended`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload),
        });
      } catch (error) {
        console.error('n8n webhook error:', error);
      }
    }
  });
```

### Firebase 환경 변수 설정

```bash
firebase functions:config:set n8n.webhook_url="https://your-n8n-domain.com/webhook"
```

---

## 3. Twitter/X 자동 포스팅

### Twitter Developer 설정

1. https://developer.twitter.com 에서 앱 생성
2. OAuth 2.0 활성화
3. API Key, API Secret, Access Token, Access Token Secret 획득

### n8n 워크플로우: 새 모임 트윗

```json
{
  "name": "술래 - 새 모임 트윗",
  "nodes": [
    {
      "name": "Webhook",
      "type": "n8n-nodes-base.webhook",
      "parameters": {
        "path": "meeting-created",
        "httpMethod": "POST"
      }
    },
    {
      "name": "Format Tweet",
      "type": "n8n-nodes-base.set",
      "parameters": {
        "values": {
          "string": [
            {
              "name": "tweet",
              "value": "🏃 새로운 술래잡기 모임!\n\n📍 {{$json.location}}\n🎮 {{$json.gameTypeName}}\n⏰ {{$json.meetingTimeFormatted}}\n👥 {{$json.maxParticipants}}명 모집\n\n참가코드: {{$json.joinCode}}\n\n#술래 #술래잡기 #동네모임 #야외활동"
            }
          ]
        }
      }
    },
    {
      "name": "Twitter",
      "type": "n8n-nodes-base.twitter",
      "parameters": {
        "text": "={{$json.tweet}}",
        "additionalFields": {}
      },
      "credentials": {
        "twitterOAuth2Api": "Twitter Sullae"
      }
    }
  ]
}
```

### 트윗 템플릿 변형

```javascript
// 게임 타입별 이모지 매핑
const gameTypeEmoji = {
  0: '👮 경찰과 도둑',
  1: '🧊 얼음땡',
  2: '👀 숨바꼭질',
  3: '🚩 깃발뺏기',
  4: '🎮 커스텀 게임'
};

// 시간대별 메시지
const getTimeMessage = (hour) => {
  if (hour < 12) return '오전에 상쾌하게!';
  if (hour < 18) return '오후 햇살 아래서!';
  return '퇴근 후 시원하게!';
};

// 완성된 트윗
const tweet = `
🏃 ${getTimeMessage(meetingHour)}

${gameTypeEmoji[gameType]}
📍 ${location}
⏰ ${formattedTime}
👥 ${currentParticipants}/${maxParticipants}명

앱에서 "${joinCode}" 검색!
sullae.app/join/${joinCode}

#술래 #동네친구 #야외운동
`.trim();
```

---

## 4. Discord 봇 연동

### Discord 봇 설정

1. https://discord.com/developers/applications 에서 앱 생성
2. Bot 탭에서 봇 생성 및 토큰 획득
3. OAuth2 → URL Generator에서 `bot`, `applications.commands` 권한 선택
4. 생성된 URL로 서버에 봇 초대

### n8n 워크플로우: Discord 알림

```json
{
  "name": "술래 - Discord 모임 알림",
  "nodes": [
    {
      "name": "Webhook",
      "type": "n8n-nodes-base.webhook",
      "parameters": {
        "path": "meeting-created",
        "httpMethod": "POST"
      }
    },
    {
      "name": "Discord",
      "type": "n8n-nodes-base.discord",
      "parameters": {
        "resource": "message",
        "operation": "send",
        "channelId": "YOUR_CHANNEL_ID",
        "content": "",
        "options": {
          "embeds": [
            {
              "title": "🏃 새로운 술래잡기 모임!",
              "description": "{{$json.description}}",
              "color": 5814783,
              "fields": [
                {
                  "name": "📍 장소",
                  "value": "{{$json.location}}",
                  "inline": true
                },
                {
                  "name": "🎮 게임",
                  "value": "{{$json.gameTypeName}}",
                  "inline": true
                },
                {
                  "name": "⏰ 시간",
                  "value": "{{$json.meetingTimeFormatted}}",
                  "inline": true
                },
                {
                  "name": "👥 모집 인원",
                  "value": "{{$json.maxParticipants}}명",
                  "inline": true
                },
                {
                  "name": "🔑 참가 코드",
                  "value": "`{{$json.joinCode}}`",
                  "inline": true
                }
              ],
              "footer": {
                "text": "술래 앱에서 참가하세요!"
              }
            }
          ]
        }
      },
      "credentials": {
        "discordBotApi": "Discord Sullae Bot"
      }
    }
  ]
}
```

### Discord 슬래시 커맨드 (선택)

```javascript
// /모임 - 현재 모집중인 모임 목록
// /참가 [코드] - 참가 코드로 모임 참가
// /알림 - 새 모임 알림 설정
```

---

## 5. Telegram 봇 연동

### Telegram 봇 설정

1. @BotFather에게 `/newbot` 명령
2. 봇 이름, username 설정
3. 토큰 획득

### n8n 워크플로우: Telegram 알림

```json
{
  "name": "술래 - Telegram 모임 알림",
  "nodes": [
    {
      "name": "Webhook",
      "type": "n8n-nodes-base.webhook",
      "parameters": {
        "path": "meeting-created",
        "httpMethod": "POST"
      }
    },
    {
      "name": "Telegram",
      "type": "n8n-nodes-base.telegram",
      "parameters": {
        "resource": "message",
        "operation": "sendMessage",
        "chatId": "YOUR_CHAT_ID",
        "text": "🏃 *새로운 술래잡기 모임!*\n\n📍 장소: {{$json.location}}\n🎮 게임: {{$json.gameTypeName}}\n⏰ 시간: {{$json.meetingTimeFormatted}}\n👥 모집: {{$json.maxParticipants}}명\n\n🔑 참가코드: `{{$json.joinCode}}`\n\n[앱에서 참가하기](https://sullae.app/join/{{$json.joinCode}})",
        "additionalFields": {
          "parse_mode": "Markdown",
          "disable_web_page_preview": false
        }
      },
      "credentials": {
        "telegramApi": "Telegram Sullae Bot"
      }
    }
  ]
}
```

### Telegram 봇 명령어

```
/start - 봇 시작, 알림 구독
/meetings - 현재 모집중인 모임 목록
/join [코드] - 참가 코드로 모임 정보 조회
/subscribe [지역] - 특정 지역 모임 알림 구독
/unsubscribe - 알림 구독 해제
```

---

## 6. Instagram 자동 응답

### Instagram Graph API 설정

1. Facebook Developer 계정 생성
2. 앱 생성 → Instagram Graph API 추가
3. Instagram 비즈니스 계정 연결
4. 액세스 토큰 획득

### n8n 워크플로우: 댓글 자동 응답

```json
{
  "name": "술래 - Instagram 댓글 응답",
  "nodes": [
    {
      "name": "Schedule",
      "type": "n8n-nodes-base.scheduleTrigger",
      "parameters": {
        "rule": {
          "interval": [{ "field": "minutes", "minutesInterval": 5 }]
        }
      }
    },
    {
      "name": "Get Recent Comments",
      "type": "n8n-nodes-base.httpRequest",
      "parameters": {
        "url": "https://graph.facebook.com/v18.0/{{$credentials.instagramBusinessAccountId}}/media",
        "method": "GET",
        "qs": {
          "fields": "id,comments{id,text,from,timestamp}",
          "access_token": "{{$credentials.accessToken}}"
        }
      }
    },
    {
      "name": "Filter New Comments",
      "type": "n8n-nodes-base.filter",
      "parameters": {
        "conditions": {
          "string": [
            {
              "value1": "={{$json.text.toLowerCase()}}",
              "operation": "contains",
              "value2": "다운"
            }
          ]
        }
      }
    },
    {
      "name": "Reply to Comment",
      "type": "n8n-nodes-base.httpRequest",
      "parameters": {
        "url": "https://graph.facebook.com/v18.0/{{$json.id}}/replies",
        "method": "POST",
        "body": {
          "message": "@{{$json.from.username}} 앱 다운로드는 프로필 링크에서! 🏃 동네에서 술래잡기 같이해요!",
          "access_token": "{{$credentials.accessToken}}"
        }
      }
    }
  ]
}
```

### 키워드 기반 자동 응답

| 키워드 | 응답 메시지 |
|--------|-----------|
| 다운, 앱, 어디서 | "앱 다운로드는 프로필 링크에서! 🏃" |
| 어떻게, 참가, 방법 | "앱 설치 후 참가코드 입력하면 끝! 쉽죠?" |
| 서울, 경기, 부산... | "해당 지역 모임 있어요! 앱에서 확인해보세요 📍" |
| 재밌어, 좋아 | "감사합니다! 다음에 같이 뛰어요 🏃‍♂️" |

---

## 7. 콘텐츠 예약 시스템

### Google Sheets 연동 콘텐츠 캘린더

```
| 날짜 | 시간 | 플랫폼 | 콘텐츠 타입 | 텍스트 | 이미지 URL | 상태 |
|------|-----|--------|------------|--------|-----------|------|
| 2026-01-06 | 09:00 | Twitter | 일반 | 월요일 아침... | - | 대기 |
| 2026-01-06 | 12:00 | Discord | 모임홍보 | 점심시간에... | - | 대기 |
```

### n8n 예약 포스팅 워크플로우

```json
{
  "name": "술래 - 예약 콘텐츠 포스팅",
  "nodes": [
    {
      "name": "Schedule",
      "type": "n8n-nodes-base.scheduleTrigger",
      "parameters": {
        "rule": {
          "interval": [{ "field": "minutes", "minutesInterval": 5 }]
        }
      }
    },
    {
      "name": "Get Scheduled Posts",
      "type": "n8n-nodes-base.googleSheets",
      "parameters": {
        "operation": "read",
        "sheetId": "YOUR_SHEET_ID",
        "range": "콘텐츠캘린더!A:G",
        "options": {}
      }
    },
    {
      "name": "Filter Due Posts",
      "type": "n8n-nodes-base.filter",
      "parameters": {
        "conditions": {
          "string": [
            {
              "value1": "={{$json.상태}}",
              "operation": "equal",
              "value2": "대기"
            }
          ],
          "dateTime": [
            {
              "value1": "={{$json.날짜}} {{$json.시간}}",
              "operation": "beforeOrEqual",
              "value2": "={{$now}}"
            }
          ]
        }
      }
    },
    {
      "name": "Switch Platform",
      "type": "n8n-nodes-base.switch",
      "parameters": {
        "dataPropertyName": "플랫폼",
        "rules": [
          { "value": "Twitter" },
          { "value": "Discord" },
          { "value": "Telegram" }
        ]
      }
    }
  ]
}
```

---

## 8. 분석 및 리포팅

### 일일 마케팅 리포트

```javascript
// 매일 오후 6시 실행
const dailyReport = {
  date: today,
  metrics: {
    twitter: {
      impressions: 1234,
      engagements: 56,
      followers_gained: 12,
      link_clicks: 34
    },
    discord: {
      new_members: 5,
      messages: 89,
      reactions: 123
    },
    telegram: {
      new_subscribers: 8,
      messages: 45
    },
    app: {
      new_users: 23,
      meetings_created: 5,
      total_participants: 42
    }
  }
};
```

### Notion 대시보드 연동

```json
{
  "name": "술래 - 일일 리포트 → Notion",
  "nodes": [
    {
      "name": "Schedule",
      "type": "n8n-nodes-base.scheduleTrigger",
      "parameters": {
        "rule": {
          "interval": [{ "field": "hours", "hoursInterval": 24 }]
        }
      }
    },
    {
      "name": "Aggregate Metrics",
      "type": "n8n-nodes-base.code",
      "parameters": {
        "jsCode": "// 각 플랫폼 메트릭 수집 로직"
      }
    },
    {
      "name": "Notion",
      "type": "n8n-nodes-base.notion",
      "parameters": {
        "resource": "databasePage",
        "operation": "create",
        "databaseId": "YOUR_DATABASE_ID",
        "properties": {
          "날짜": { "date": { "start": "{{$json.date}}" } },
          "신규 가입": { "number": "{{$json.app.new_users}}" },
          "모임 생성": { "number": "{{$json.app.meetings_created}}" },
          "트위터 노출": { "number": "{{$json.twitter.impressions}}" }
        }
      }
    }
  ]
}
```

---

## 9. 배포 체크리스트

### 필수 설정

- [ ] n8n 서버 배포 (Docker/Cloud)
- [ ] HTTPS 설정 (Let's Encrypt)
- [ ] Firebase Cloud Functions 배포
- [ ] 환경 변수 설정 (`n8n.webhook_url`)

### API 키 획득

- [ ] Twitter API (Developer Portal)
- [ ] Discord Bot Token
- [ ] Telegram Bot Token (@BotFather)
- [ ] Instagram Graph API (Facebook Developer)

### 워크플로우 활성화

- [ ] 새 모임 생성 → 멀티 플랫폼 포스팅
- [ ] 모임 모집 완료 → 알림
- [ ] 댓글/DM 자동 응답
- [ ] 예약 콘텐츠 발행
- [ ] 일일 리포트 생성

---

## 10. 비용 예상

### 무료 운영 가능

| 항목 | 비용 | 비고 |
|------|------|-----|
| n8n (셀프호스팅) | $0 | 개인 서버 필요 |
| Twitter API | $0 | Free tier (1,500 트윗/월) |
| Discord Bot | $0 | 무료 |
| Telegram Bot | $0 | 무료 |
| Firebase Functions | $0~ | Blaze 플랜 (무료 할당량) |

### 유료 옵션

| 항목 | 비용 | 비고 |
|------|------|-----|
| n8n Cloud | $20/월 | 관리 편의성 |
| Twitter Basic | $100/월 | 더 많은 API 호출 |
| Railway 호스팅 | $5~/월 | n8n 호스팅 |

---

*문서 작성: 2026-01-03*
