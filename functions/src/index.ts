/**
 * 술래 앱 - Firebase Cloud Functions
 *
 * - n8n 웹훅 연동을 통한 SNS 자동화 마케팅 시스템
 * - FCM 푸시 알림 발송
 * - 스케줄 기반 리마인더
 */

import * as admin from 'firebase-admin';

admin.initializeApp();

// 웹훅 함수들
export * from './webhooks/n8n';

// FCM 알림 함수들
export * from './notifications';

// 추후 추가 예정
// export * from './statistics';
