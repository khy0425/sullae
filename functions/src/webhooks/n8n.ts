/**
 * n8n 웹훅 연동 함수들
 *
 * Firebase Firestore 이벤트를 감지하여 n8n으로 전송
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import fetch from 'node-fetch';

// n8n 웹훅 URL (Firebase 환경 변수에서 가져옴)
const getWebhookUrl = (): string => {
  return functions.config().n8n?.webhook_url || '';
};

// 게임 타입 이름 매핑
const gameTypeNames: Record<number, string> = {
  0: '경찰과 도둑',
  1: '얼음땡',
  2: '숨바꼭질',
  3: '깃발뺏기',
  4: '커스텀',
};

// 날짜 포맷팅 (한국 시간)
const formatDateTime = (date: Date): string => {
  return date.toLocaleString('ko-KR', {
    timeZone: 'Asia/Seoul',
    month: 'long',
    day: 'numeric',
    weekday: 'short',
    hour: '2-digit',
    minute: '2-digit',
  });
};

/**
 * 새 모임 생성 시 n8n으로 웹훅 전송
 */
export const onMeetingCreated = functions
  .region('asia-northeast3')
  .firestore
  .document('meetings/{meetingId}')
  .onCreate(async (snapshot, context) => {
    const webhookUrl = getWebhookUrl();
    if (!webhookUrl) {
      console.log('n8n webhook URL not configured');
      return;
    }

    const meeting = snapshot.data();
    const meetingId = context.params.meetingId;

    const meetingTime = meeting.meetingTime?.toDate() || new Date();

    const payload = {
      event: 'meeting_created',
      timestamp: new Date().toISOString(),
      meetingId,
      title: meeting.title,
      description: meeting.description,
      location: meeting.location,
      locationDetail: meeting.locationDetail || null,
      gameType: meeting.gameType,
      gameTypeName: gameTypeNames[meeting.gameType] || '기타',
      meetingTime: meetingTime.toISOString(),
      meetingTimeFormatted: formatDateTime(meetingTime),
      maxParticipants: meeting.maxParticipants,
      currentParticipants: meeting.currentParticipants || 1,
      hostId: meeting.hostId,
      hostNickname: meeting.hostNickname,
      joinCode: meeting.joinCode,
      region: meeting.region || 'all',
      difficulty: meeting.difficulty || 0,
      latitude: meeting.latitude || null,
      longitude: meeting.longitude || null,
    };

    try {
      const response = await fetch(`${webhookUrl}/meeting-created`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Webhook-Source': 'sullae-firebase',
        },
        body: JSON.stringify(payload),
      });

      if (response.ok) {
        console.log(`n8n webhook sent for meeting: ${meetingId}`);
      } else {
        console.error(`n8n webhook failed: ${response.status} ${response.statusText}`);
      }
    } catch (error) {
      console.error('n8n webhook error:', error);
    }
  });

/**
 * 모임 참가자 수 변경 시 (모집 완료 등)
 */
export const onMeetingUpdated = functions
  .region('asia-northeast3')
  .firestore
  .document('meetings/{meetingId}')
  .onUpdate(async (change, context) => {
    const webhookUrl = getWebhookUrl();
    if (!webhookUrl) return;

    const before = change.before.data();
    const after = change.after.data();
    const meetingId = context.params.meetingId;

    // 참가자 수가 변경되지 않으면 무시
    if (before.currentParticipants === after.currentParticipants) {
      return;
    }

    // 모집 완료 (정원 도달)
    if (
      after.currentParticipants >= after.maxParticipants &&
      before.currentParticipants < before.maxParticipants
    ) {
      const payload = {
        event: 'meeting_full',
        timestamp: new Date().toISOString(),
        meetingId,
        title: after.title,
        location: after.location,
        gameTypeName: gameTypeNames[after.gameType] || '기타',
        currentParticipants: after.currentParticipants,
        maxParticipants: after.maxParticipants,
        hostNickname: after.hostNickname,
      };

      try {
        await fetch(`${webhookUrl}/meeting-full`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-Webhook-Source': 'sullae-firebase',
          },
          body: JSON.stringify(payload),
        });
        console.log(`Meeting full webhook sent: ${meetingId}`);
      } catch (error) {
        console.error('n8n webhook error:', error);
      }
    }

    // 새 참가자 합류 (50% 이상 모집 시)
    const halfFull = after.maxParticipants / 2;
    if (
      after.currentParticipants >= halfFull &&
      before.currentParticipants < halfFull
    ) {
      const payload = {
        event: 'meeting_half_full',
        timestamp: new Date().toISOString(),
        meetingId,
        title: after.title,
        currentParticipants: after.currentParticipants,
        maxParticipants: after.maxParticipants,
        remainingSlots: after.maxParticipants - after.currentParticipants,
      };

      try {
        await fetch(`${webhookUrl}/meeting-progress`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-Webhook-Source': 'sullae-firebase',
          },
          body: JSON.stringify(payload),
        });
      } catch (error) {
        console.error('n8n webhook error:', error);
      }
    }
  });

/**
 * 게임 종료 시 (결과 공유용)
 */
export const onGameEnded = functions
  .region('asia-northeast3')
  .firestore
  .document('games/{gameId}')
  .onUpdate(async (change, context) => {
    const webhookUrl = getWebhookUrl();
    if (!webhookUrl) return;

    const before = change.before.data();
    const after = change.after.data();
    const gameId = context.params.gameId;

    // 게임이 'finished' 상태로 변경된 경우만
    if (before.status === 'finished' || after.status !== 'finished') {
      return;
    }

    const payload = {
      event: 'game_ended',
      timestamp: new Date().toISOString(),
      gameId,
      meetingId: after.meetingId,
      gameType: after.gameType,
      gameTypeName: gameTypeNames[after.gameType] || '기타',
      duration: after.duration, // 게임 진행 시간 (초)
      participantCount: after.participantCount,
      winnerTeam: after.winnerTeam || null,
      // 하이라이트 통계
      stats: {
        totalCatches: after.stats?.totalCatches || 0,
        longestSurvival: after.stats?.longestSurvival || 0,
        mvpUserId: after.stats?.mvpUserId || null,
        mvpNickname: after.stats?.mvpNickname || null,
      },
    };

    try {
      await fetch(`${webhookUrl}/game-ended`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Webhook-Source': 'sullae-firebase',
        },
        body: JSON.stringify(payload),
      });
      console.log(`Game ended webhook sent: ${gameId}`);
    } catch (error) {
      console.error('n8n webhook error:', error);
    }
  });

/**
 * 새 사용자 가입 시 (마일스톤 알림용)
 */
export const onUserCreated = functions
  .region('asia-northeast3')
  .firestore
  .document('users/{userId}')
  .onCreate(async (snapshot, context) => {
    const webhookUrl = getWebhookUrl();
    if (!webhookUrl) return;

    const user = snapshot.data();
    const userId = context.params.userId;

    // 사용자 수 카운트
    const usersSnapshot = await admin.firestore().collection('users').count().get();
    const totalUsers = usersSnapshot.data().count;

    // 마일스톤 체크 (100, 500, 1000, 5000, 10000...)
    const milestones = [100, 500, 1000, 5000, 10000, 50000, 100000];
    const isMilestone = milestones.includes(totalUsers);

    const payload = {
      event: 'user_created',
      timestamp: new Date().toISOString(),
      userId,
      nickname: user.nickname,
      totalUsers,
      isMilestone,
    };

    try {
      await fetch(`${webhookUrl}/user-created`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Webhook-Source': 'sullae-firebase',
        },
        body: JSON.stringify(payload),
      });

      // 마일스톤 달성 시 별도 알림
      if (isMilestone) {
        await fetch(`${webhookUrl}/milestone`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-Webhook-Source': 'sullae-firebase',
          },
          body: JSON.stringify({
            event: 'user_milestone',
            timestamp: new Date().toISOString(),
            milestone: totalUsers,
            message: `🎉 술래 앱 ${totalUsers.toLocaleString()}번째 사용자 달성!`,
          }),
        });
      }
    } catch (error) {
      console.error('n8n webhook error:', error);
    }
  });

/**
 * 일일 통계 집계 (스케줄 함수)
 * 매일 오후 11시 (KST) 실행
 */
export const dailyStats = functions
  .region('asia-northeast3')
  .pubsub
  .schedule('0 23 * * *')
  .timeZone('Asia/Seoul')
  .onRun(async () => {
    const webhookUrl = getWebhookUrl();
    if (!webhookUrl) return;

    const db = admin.firestore();
    const now = new Date();
    const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const todayEnd = new Date(todayStart.getTime() + 24 * 60 * 60 * 1000);

    try {
      // 오늘 생성된 모임 수
      const meetingsSnapshot = await db
        .collection('meetings')
        .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(todayStart))
        .where('createdAt', '<', admin.firestore.Timestamp.fromDate(todayEnd))
        .count()
        .get();

      // 오늘 가입한 사용자 수
      const usersSnapshot = await db
        .collection('users')
        .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(todayStart))
        .where('createdAt', '<', admin.firestore.Timestamp.fromDate(todayEnd))
        .count()
        .get();

      // 총 사용자 수
      const totalUsersSnapshot = await db.collection('users').count().get();

      // 총 모임 수
      const totalMeetingsSnapshot = await db.collection('meetings').count().get();

      const payload = {
        event: 'daily_stats',
        timestamp: now.toISOString(),
        date: todayStart.toISOString().split('T')[0],
        stats: {
          newMeetings: meetingsSnapshot.data().count,
          newUsers: usersSnapshot.data().count,
          totalUsers: totalUsersSnapshot.data().count,
          totalMeetings: totalMeetingsSnapshot.data().count,
        },
      };

      await fetch(`${webhookUrl}/daily-stats`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Webhook-Source': 'sullae-firebase',
        },
        body: JSON.stringify(payload),
      });

      console.log('Daily stats webhook sent:', payload.stats);
    } catch (error) {
      console.error('Daily stats error:', error);
    }
  });
