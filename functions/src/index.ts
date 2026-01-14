/**
 * 술래 앱 - Firebase Cloud Functions
 *
 * n8n 웹훅 연동을 통한 SNS 자동화 마케팅 시스템
 */

import * as admin from 'firebase-admin';

admin.initializeApp();

// 웹훅 함수들
export * from './webhooks/n8n';

// 추후 추가 예정
// export * from './notifications';
// export * from './statistics';
