# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2025-01-15

### Added
- **FCM 푸시 알림**: Cloud Functions를 통한 서버 사이드 푸시 알림 발송
- **로컬 리마인더 개선**: `zonedSchedule`을 사용하여 앱 종료 후에도 알림 동작
- **모임 정보 변경 알림**: 시간, 장소, 제목 변경 시 참가자에게 알림
- **지역 필터링**: 서울 25개 자치구, 경기도 주요 도시 지원
- **방장 위임 기능**: 다른 참가자에게 방장 권한 위임
- **모임 수정/삭제**: 방장이 모임 정보 수정 및 삭제 가능
- **Discord 커뮤니티 연동**: n8n 웹훅을 통한 자동 알림
- **배너 광고 확대**: 내 모임 탭, 모임 상세 화면에 배너 추가

### Fixed
- **커스텀 공지 무한로딩**: Firestore 인덱스 수정 및 타임아웃 추가
- **진동 기능 미작동**: HapticFeedback 구현 완료

### Changed
- Android 권한 추가: `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`
- 알림 ID 계산 방식 변경 (양수로 변환)

## [1.0.0] - 2025-01-10

### Added
- 소셜 로그인 (Google, Apple, Kakao)
- 모임 생성/참가 시스템
- 6자리 참가 코드 자동 생성
- 역할 희망 선택 & 팀 자동 배정
- 퀵 메시지 시스템 (정해진 메시지만 전송)
- 게임 가이드 (로컬 룰, 준비물, 안전 수칙)
- 진동 타이머 (시작, 절반, 1분 전, 종료)
- 룰 프리셋 저장/불러오기
- 호스트 평점 시스템
- MVP 투표

---

## Known Issues

### 해결 예정
- [ ] QR코드 스캔 기능 미구현
- [ ] 위치 기반 모임 검색 미구현

### 알려진 제한사항
- iOS에서는 AdMob 테스트 ID 사용 중 (실제 광고 미표시)
- Discord 알림은 n8n 서버 가동 시에만 동작

---

## Reporting Issues

버그를 발견하셨나요? [GitHub Issues](https://github.com/khy0425/sullae/issues)에 리포트해주세요.

버그 리포트 시 다음 정보를 포함해주세요:
1. 기기 정보 (기종, OS 버전)
2. 앱 버전
3. 재현 방법
4. 예상 동작 vs 실제 동작
5. 스크린샷 (가능한 경우)
