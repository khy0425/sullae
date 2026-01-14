# n8n Render 무료 배포 가이드

## 1. Render 계정 생성

1. https://render.com 접속
2. GitHub 계정으로 가입 (가장 쉬움)

## 2. 새 Web Service 생성

### 방법 A: Blueprint 사용 (권장)

1. Render 대시보드 → **Blueprints** → **New Blueprint Instance**
2. GitHub 레포지토리 연결
3. `n8n-deploy/render.yaml` 경로 지정
4. 환경 변수 설정:
   - `N8N_BASIC_AUTH_USER`: 원하는 사용자명
   - `N8N_BASIC_AUTH_PASSWORD`: 안전한 비밀번호

### 방법 B: 수동 설정

1. Render 대시보드 → **New** → **Web Service**
2. **Docker** 선택
3. 설정:
   - **Name**: `sullae-n8n`
   - **Region**: Singapore (가장 가까움)
   - **Instance Type**: Free
   - **Docker Command**: (비워두기)

4. **Environment Variables** 추가:
   ```
   N8N_BASIC_AUTH_ACTIVE=true
   N8N_BASIC_AUTH_USER=admin
   N8N_BASIC_AUTH_PASSWORD=your_secure_password_here
   N8N_PROTOCOL=https
   GENERIC_TIMEZONE=Asia/Seoul
   ```

5. **Disk** 추가 (중요!):
   - Mount Path: `/home/node/.n8n`
   - Size: 1 GB

6. **Create Web Service** 클릭

## 3. 배포 완료 확인

배포 완료까지 약 3-5분 소요됩니다.

배포 완료 후:
1. Render에서 제공하는 URL 확인 (예: `https://sullae-n8n.onrender.com`)
2. 해당 URL 접속
3. 설정한 사용자명/비밀번호로 로그인

## 4. 슬립 방지 설정

Render 무료 플랜은 15분 미사용 시 슬립됩니다.
n8n 내부에서 자동으로 깨우는 워크플로우를 설정합니다.

1. n8n 접속 후 좌측 메뉴 → **Workflows**
2. **Import from File** → `00_keep_alive.json` 선택
3. `WEBHOOK_URL` 환경변수 확인 (Render URL과 동일해야 함)
4. 워크플로우 **Activate** (우측 상단 토글)

## 5. Firebase 웹훅 URL 설정

```bash
# Firebase Functions 환경변수 설정
firebase functions:config:set n8n.webhook_url="https://sullae-n8n.onrender.com/webhook"

# Functions 배포
cd sullae/functions
npm install
cd ..
firebase deploy --only functions --project mission100-app
```

## 6. 워크플로우 가져오기

1. n8n 접속
2. **Workflows** → **Import from File**
3. 순서대로 가져오기:
   - `01_twitter_new_meeting.json`
   - `02_discord_notifications.json`
   - `03_telegram_bot.json`
   - `04_instagram_auto_reply.json`
   - `05_multi_platform_broadcast.json`

4. 각 워크플로우에서 Credentials 설정 필요

## 7. Credentials 설정

### Twitter
1. n8n → **Settings** → **Credentials** → **Add Credential**
2. **Twitter OAuth2 API** 선택
3. https://developer.twitter.com 에서 발급받은 키 입력:
   - Client ID
   - Client Secret

### Discord
1. Discord 서버 → 채널 설정 → 연동 → 웹후크
2. 새 웹후크 생성 → URL 복사
3. 워크플로우의 Discord 노드에서 Webhook URL 붙여넣기

### Telegram
1. Telegram에서 @BotFather 검색
2. `/newbot` 명령으로 봇 생성
3. 토큰 복사
4. n8n → **Add Credential** → **Telegram API** → 토큰 입력

### Instagram (선택)
1. https://developers.facebook.com 에서 앱 생성
2. Instagram Graph API 추가
3. 비즈니스 계정 연결
4. 액세스 토큰 발급
5. n8n에서 HTTP Query Auth로 설정

## 8. 테스트

### 웹훅 테스트
```bash
# 터미널에서 테스트 요청
curl -X POST https://sullae-n8n.onrender.com/webhook/meeting-created \
  -H "Content-Type: application/json" \
  -d '{
    "event": "meeting_created",
    "title": "테스트 모임",
    "location": "서울 강남",
    "gameTypeName": "얼음땡",
    "meetingTimeFormatted": "1월 6일 (토) 오후 3:00",
    "maxParticipants": 8,
    "joinCode": "TEST01"
  }'
```

### n8n 실행 로그 확인
1. n8n → **Executions** (좌측 메뉴)
2. 각 실행 결과 확인

## 비용 정리

| 항목 | 비용 |
|------|------|
| Render Free | $0 |
| Disk 1GB | $0 (Free 포함) |
| Twitter API Free | $0 |
| Discord Webhook | $0 |
| Telegram Bot | $0 |
| **총합** | **$0** |

## 트러블슈팅

### 슬립에서 깨어나는 데 오래 걸림
- 첫 요청 시 30초 정도 대기 필요 (콜드스타트)
- Keep Alive 워크플로우가 활성화되어 있는지 확인

### 웹훅이 동작하지 않음
1. 워크플로우가 **Active** 상태인지 확인
2. Render 로그 확인: Dashboard → Logs
3. n8n Executions에서 에러 확인

### Credentials 에러
1. 토큰/키가 만료되지 않았는지 확인
2. API 권한 범위가 충분한지 확인

---

*작성: 2026-01-03*
