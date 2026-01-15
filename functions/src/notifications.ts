/**
 * FCM 푸시 알림 Cloud Functions
 *
 * notifications 컬렉션에 새 문서가 생성되면 자동으로 FCM 발송
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * notifications 컬렉션에 새 문서 생성 시 FCM 발송
 */
export const sendPushNotification = functions
  .region('asia-northeast3')
  .firestore.document('notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const notification = snap.data();
    const { userId, title, body, meetingId, type } = notification;

    if (!userId || !title || !body) {
      console.log('Missing required fields:', { userId, title, body });
      return null;
    }

    try {
      // 사용자의 FCM 토큰 조회
      const userDoc = await db.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        console.log('User not found:', userId);
        return null;
      }

      const userData = userDoc.data();
      const fcmToken = userData?.fcmToken;

      if (!fcmToken) {
        console.log('No FCM token for user:', userId);
        return null;
      }

      // FCM 메시지 구성
      const message: admin.messaging.Message = {
        token: fcmToken,
        notification: {
          title,
          body,
        },
        data: {
          type: type || 'general',
          meetingId: meetingId || '',
          notificationId: context.params.notificationId,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'sullae_notifications',
            priority: 'high',
            defaultSound: true,
            defaultVibrateTimings: true,
          },
        },
        apns: {
          payload: {
            aps: {
              alert: { title, body },
              sound: 'default',
              badge: 1,
            },
          },
        },
      };

      // FCM 발송
      const response = await messaging.send(message);
      console.log('FCM sent successfully:', response);

      // 발송 상태 업데이트
      await snap.ref.update({
        fcmSent: true,
        fcmSentAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return response;
    } catch (error: any) {
      console.error('FCM send error:', error);

      // 토큰이 유효하지 않은 경우 토큰 삭제
      if (
        error.code === 'messaging/invalid-registration-token' ||
        error.code === 'messaging/registration-token-not-registered'
      ) {
        console.log('Invalid token, removing from user document');
        await db.collection('users').doc(userId).update({
          fcmToken: admin.firestore.FieldValue.delete(),
        });
      }

      // 에러 상태 업데이트
      await snap.ref.update({
        fcmSent: false,
        fcmError: error.message,
      });

      return null;
    }
  });

/**
 * 모임 시작 30분 전 리마인더 (Scheduled Function)
 * 매 5분마다 실행하여 30분 이내 시작 모임 찾기
 */
export const sendMeetingReminders = functions
  .region('asia-northeast3')
  .pubsub.schedule('every 5 minutes')
  .onRun(async (context) => {
    const now = new Date();
    const thirtyMinutesLater = new Date(now.getTime() + 30 * 60 * 1000);
    const twentyFiveMinutesLater = new Date(now.getTime() + 25 * 60 * 1000);

    try {
      // 25~30분 후 시작하는 모임 조회 (5분 간격으로 실행되므로)
      const meetingsSnapshot = await db
        .collection('meetings')
        .where('status', '==', 'recruiting')
        .where('meetingTime', '>=', admin.firestore.Timestamp.fromDate(twentyFiveMinutesLater))
        .where('meetingTime', '<=', admin.firestore.Timestamp.fromDate(thirtyMinutesLater))
        .get();

      if (meetingsSnapshot.empty) {
        console.log('No meetings starting in 25-30 minutes');
        return null;
      }

      const batch = db.batch();

      for (const meetingDoc of meetingsSnapshot.docs) {
        const meeting = meetingDoc.data();
        const { title, location, participantIds } = meeting;

        // 이미 리마인더를 보냈는지 확인
        if (meeting.reminderSent) {
          continue;
        }

        // 각 참가자에게 알림 생성
        for (const participantId of participantIds) {
          const notificationRef = db.collection('notifications').doc();
          batch.set(notificationRef, {
            userId: participantId,
            title: '🏃 모임 시작 30분 전!',
            body: `"${title}" 모임이 곧 시작됩니다.\n장소: ${location}`,
            meetingId: meetingDoc.id,
            type: 'reminder',
            read: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }

        // 리마인더 발송 완료 표시
        batch.update(meetingDoc.ref, { reminderSent: true });
      }

      await batch.commit();
      console.log(`Sent reminders for ${meetingsSnapshot.docs.length} meetings`);

      return null;
    } catch (error) {
      console.error('Error sending reminders:', error);
      return null;
    }
  });

/**
 * 마감 임박 알림 (인원 80% 이상 찼을 때)
 */
export const checkAlmostFullMeetings = functions
  .region('asia-northeast3')
  .firestore.document('meetings/{meetingId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // 참가자 수가 변경되었는지 확인
    if (before.currentParticipants === after.currentParticipants) {
      return null;
    }

    const { maxParticipants, currentParticipants, title, status, hostId } = after;

    // 모집중인 모임만 체크
    if (status !== 'recruiting') {
      return null;
    }

    // 이미 알림을 보냈는지 확인
    if (after.almostFullNotified) {
      return null;
    }

    // 80% 이상 찼는지 확인
    const fillRate = currentParticipants / maxParticipants;
    if (fillRate < 0.8) {
      return null;
    }

    const remaining = maxParticipants - currentParticipants;

    // 방장에게 알림
    await db.collection('notifications').add({
      userId: hostId,
      title: '마감 임박! 🔥',
      body: `"${title}" 모임 ${remaining}자리 남았어요!`,
      meetingId: context.params.meetingId,
      type: 'almostFull',
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 알림 발송 완료 표시
    await change.after.ref.update({ almostFullNotified: true });

    console.log(`Almost full notification sent for meeting: ${context.params.meetingId}`);
    return null;
  });
