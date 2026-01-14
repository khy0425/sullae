# 술래 앱 출시 전 체크리스트

## 1. 보안 설정

| 상태 | 항목 | 설명 |
|:----:|------|------|
| ✅ | Firebase API 키 보호 | SHA-1/SHA-256 4개 등록 완료 |
| ✅ | Firestore 규칙 | 인증, 소유권, 참가자 권한 검증 완료 |

---

## 2. 릴리스 빌드

| 상태 | 항목 | 설명 |
|:----:|------|------|
| ✅ | 릴리스 서명 | `android/sullae-release.keystore` 생성됨 |
| ✅ | key.properties | `.gitignore`에 추가됨 |
| ✅ | App Bundle | `app-release.aab` (60.4MB) 빌드 완료 |

### Keystore 정보
- **파일**: `android/sullae-release.keystore`
- **Alias**: sullae
- **유효기간**: 약 27년 (2053년까지)
- **SHA-1**: `36:0B:EF:32:2D:F5:F2:D8:D3:CD:18:BE:99:6B:58:57:84:5F:D2:71`

---

## 3. Firebase 설정

| 상태 | 항목 | 설명 |
|:----:|------|------|
| ✅ | Project ID | `mission100-app` |
| ✅ | Firestore Rules | 배포됨 |
| ✅ | Cloud Functions | asia-northeast3 배포됨 |
| ✅ | SHA 인증서 | 4개 등록 (Debug/Release SHA-1/SHA-256) |
| ✅ | Crashlytics | 추가됨 (릴리스만 수집) |
| ✅ | Analytics | 주요 이벤트 로깅 추가됨 |
| ✅ | n8n Webhook | 지역별 Discord 알림 설정됨 |

---

## 4. 기능 테스트

### 인증
- [ ] 카카오 로그인 작동
- [ ] Google 로그인 작동
- [ ] 로그아웃 작동
- [ ] 계정 삭제 작동
- [ ] 닉네임 변경 작동

> Apple 로그인은 iOS 출시 시 활성화 예정

### 모임
- [ ] 모임 생성 (모든 필드 입력)
- [ ] 모임 목록 조회
- [ ] 지역 필터링 (서울 구별)
- [ ] 모임 참가
- [ ] 모임 퇴장
- [ ] 6자리 참가 코드로 참여
- [ ] 모임 삭제 (방장만)

### 채팅/퀵메시지
- [ ] 퀵메시지 전송
- [ ] 실시간 메시지 수신
- [ ] 외부 채팅 링크 열기

### 게임
- [ ] 게임 시작
- [ ] 팀 배정
- [ ] 타이머 작동
- [ ] 진동 알림

### 프로필
- [ ] 닉네임 변경
- [ ] 디스코드 커뮤니티 링크

---

## 5. UI/UX 확인

| 상태 | 항목 | 확인 사항 |
|:----:|------|----------|
| ✅ | 홈 화면 | 모임 목록, 필터, FAB |
| ✅ | 모임 상세 | 정보, 채팅, 참가/퇴장 |
| ✅ | 모임 생성 | 폼 입력, 지역 선택 |
| ✅ | 프로필 | 메뉴, 설정, 디스코드 링크 |
| ✅ | 앱 아이콘 | `assets/icons/app_icon.png` |
| ✅ | 스플래시 | `assets/icons/splash_logo.png` |

---

## 6. Google Play 스토어 제출

### 필수 에셋
- [ ] 앱 아이콘 (512x512 PNG)
- [ ] 기능 그래픽 (1024x500 PNG)
- [ ] 스크린샷 (최소 2장, 권장 8장)
  - 휴대전화: 16:9 또는 9:16
  - 7인치 태블릿 (선택)
  - 10인치 태블릿 (선택)

### 스토어 등록정보
- [ ] 앱 이름: 술래 - 야외 술래잡기 모임
- [ ] 짧은 설명 (80자 이내)
- [ ] 긴 설명 (4000자 이내)
- [ ] 카테고리: 소셜

### 필수 정책
- [ ] 개인정보 처리방침 URL
- [ ] 콘텐츠 등급 설문 완료
- [ ] 타겟 연령층 설정

### 앱 서명
- [ ] Play App Signing 등록
- [ ] 업로드 키 등록 (sullae-release.keystore)

---

## 7. 빌드 명령어

```bash
# 릴리스 App Bundle 빌드
cd e:/Projects/mission_apps/sullae
flutter build appbundle --release

# 빌드 결과물 위치
# build/app/outputs/bundle/release/app-release.aab
```

---

## 8. 출시 후 모니터링

### Firebase Console에서 확인
- [ ] Crashlytics 대시보드 - 크래시 리포트
- [ ] Analytics 대시보드 - 사용자 행동
- [ ] Cloud Messaging - 푸시 알림 전송

### Discord에서 확인
- [ ] 지역별 채널에 모임 알림 도착 확인

---

## 변경 이력

| 날짜 | 변경 내용 |
|------|----------|
| 2026-01-04 | 초기 체크리스트 작성 |
| 2026-01-04 | 릴리스 서명 설정 완료 |
| 2026-01-04 | Crashlytics/Analytics 추가 |
| 2026-01-04 | Apple 로그인 비활성화 |
