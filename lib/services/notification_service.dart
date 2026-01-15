import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

/// 푸시 알림 서비스
/// - 모임 시작 30분 전 알림
/// - 새 참가자 알림
/// - 방장 위임 알림
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isInitialized = false;

  /// 알림 채널 ID
  static const String _channelId = 'sullae_notifications';
  static const String _channelName = '술래 알림';
  static const String _channelDescription = '모임 알림 및 게임 알림';

  /// 알림 서비스 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Timezone 초기화 (한국 시간대 사용)
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    // 권한 요청
    await _requestPermission();

    // 로컬 알림 초기화
    await _initializeLocalNotifications();

    // FCM 토큰 저장
    await _saveTokenToFirestore();

    // 토큰 갱신 리스너
    _messaging.onTokenRefresh.listen(_updateToken);

    // 포그라운드 메시지 처리
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 백그라운드에서 알림 탭 시 처리
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    _isInitialized = true;
    if (kDebugMode) print('NotificationService initialized');
  }

  /// 권한 요청
  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (kDebugMode) {
      print('Notification permission: ${settings.authorizationStatus}');
    }
  }

  /// 로컬 알림 초기화
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Android 알림 채널 생성
    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
        ),
      );
    }
  }

  /// FCM 토큰을 Firestore에 저장
  Future<void> _saveTokenToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await _messaging.getToken();
    if (token == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'fcmToken': token,
      'fcmTokenUpdatedAt': Timestamp.now(),
    });

    if (kDebugMode) print('FCM Token saved: $token');
  }

  /// 토큰 갱신 시 업데이트
  Future<void> _updateToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'fcmToken': token,
      'fcmTokenUpdatedAt': Timestamp.now(),
    });
  }

  /// 포그라운드 메시지 처리
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) print('Foreground message: ${message.notification?.title}');

    final notification = message.notification;
    if (notification == null) return;

    // 로컬 알림으로 표시
    showLocalNotification(
      title: notification.title ?? '술래',
      body: notification.body ?? '',
      payload: message.data['meetingId'],
    );
  }

  /// 백그라운드에서 알림 탭 시 처리
  void _handleMessageOpenedApp(RemoteMessage message) {
    if (kDebugMode) print('Message opened app: ${message.data}');
    // 모임 상세 화면으로 이동 등의 처리
    // Navigator를 사용하려면 GlobalKey<NavigatorState> 필요
  }

  /// 알림 탭 처리
  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) print('Notification tapped: ${response.payload}');
    // payload에 meetingId가 있으면 모임 상세로 이동
  }

  /// 로컬 알림 표시
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// 모임 시작 알림 예약 (30분 전)
  /// zonedSchedule을 사용하여 앱이 종료되어도 알림이 동작하도록 함
  Future<void> scheduleMeetingReminder({
    required String meetingId,
    required String title,
    required DateTime meetingTime,
  }) async {
    final reminderTime = meetingTime.subtract(const Duration(minutes: 30));

    // 이미 지난 시간이면 예약하지 않음
    if (reminderTime.isBefore(DateTime.now())) return;

    // 알림 ID는 meetingId의 해시값 사용 (양수로 변환)
    final notificationId = meetingId.hashCode.abs() % 2147483647;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // TZDateTime으로 변환
    final tzReminderTime = tz.TZDateTime.from(reminderTime, tz.local);

    try {
      await _localNotifications.zonedSchedule(
        notificationId,
        '🏃 모임 시작 30분 전!',
        '$title 모임이 곧 시작됩니다',
        tzReminderTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: null,
        payload: meetingId,
      );

      if (kDebugMode) {
        print('Scheduled reminder for $meetingId at $reminderTime');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to schedule reminder: $e');
      }
    }
  }

  /// 예약된 알림 취소
  Future<void> cancelMeetingReminder(String meetingId) async {
    final notificationId = meetingId.hashCode.abs() % 2147483647;
    await _localNotifications.cancel(notificationId);
  }

  /// 모든 알림 취소
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// 특정 사용자에게 알림 전송 (서버 사이드에서 처리해야 함)
  /// 이 메서드는 Firestore에 알림 문서를 생성하여
  /// Cloud Functions에서 실제 FCM 발송을 처리하도록 함
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    String? meetingId,
    NotificationType type = NotificationType.general,
  }) async {
    await _firestore.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'meetingId': meetingId,
      'type': type.name,
      'read': false,
      'createdAt': Timestamp.now(),
    });
  }

  /// 모임 참가자들에게 알림 전송
  Future<void> notifyMeetingParticipants({
    required String meetingId,
    required List<String> participantIds,
    required String title,
    required String body,
    String? excludeUserId,
  }) async {
    for (final userId in participantIds) {
      if (userId == excludeUserId) continue;

      await sendNotificationToUser(
        userId: userId,
        title: title,
        body: body,
        meetingId: meetingId,
        type: NotificationType.meeting,
      );
    }
  }

  /// 로그아웃 시 토큰 제거
  Future<void> clearToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'fcmToken': FieldValue.delete(),
    });
  }
}

/// 알림 타입
enum NotificationType {
  general,          // 일반 알림
  meeting,          // 모임 관련
  newParticipant,   // 새 참가자
  gameStart,        // 게임 시작
  hostTransfer,     // 방장 위임
  badge,            // 배지 획득
  reminder,         // 리마인더
  reviewRequest,    // 후기 요청
  hostAnnouncement, // 방장 공지
  meetingUpdated,   // 모임 정보 변경
  meetingCancelled, // 모임 취소
}

/// 알림 템플릿
class NotificationTemplates {
  /// 새 참가자 알림 (방장에게)
  static ({String title, String body}) newParticipant({
    required String nickname,
    required String meetingTitle,
  }) {
    return (
      title: '새 참가자가 있어요! 🎉',
      body: '$nickname님이 "$meetingTitle" 모임에 참가했습니다.',
    );
  }

  /// 모임 시작 30분 전 리마인더
  static ({String title, String body}) meetingReminder({
    required String meetingTitle,
    required String location,
  }) {
    return (
      title: '🏃 모임 시작 30분 전!',
      body: '"$meetingTitle" 모임이 곧 시작됩니다.\n장소: $location',
    );
  }

  /// 게임 시작 알림 (참가자들에게)
  static ({String title, String body}) gameStarted({
    required String meetingTitle,
  }) {
    return (
      title: '게임이 시작되었습니다! 🚨',
      body: '"$meetingTitle" 게임이 시작되었어요. 어서 참여하세요!',
    );
  }

  /// 방장 위임 알림 (새 방장에게)
  static ({String title, String body}) hostTransferred({
    required String meetingTitle,
  }) {
    return (
      title: '방장이 되었습니다! 👑',
      body: '"$meetingTitle" 모임의 새로운 방장이 되었어요.',
    );
  }

  /// 방장 공지 알림 (참가자들에게)
  static ({String title, String body}) hostAnnouncement({
    required String meetingTitle,
    required String announcement,
  }) {
    return (
      title: '📢 [$meetingTitle] 공지',
      body: announcement.length > 50
          ? '${announcement.substring(0, 50)}...'
          : announcement,
    );
  }

  /// 후기 요청 알림 (모임 종료 후)
  static ({String title, String body}) reviewRequest({
    required String meetingTitle,
    required String hostNickname,
  }) {
    return (
      title: '모임은 즐거우셨나요? ⭐',
      body: '"$meetingTitle" 모임의 방장 $hostNickname님에게 별점을 남겨주세요!',
    );
  }

  /// 모임 취소 알림 (참가자들에게)
  static ({String title, String body}) meetingCancelled({
    required String meetingTitle,
  }) {
    return (
      title: '모임이 취소되었습니다 😢',
      body: '"$meetingTitle" 모임이 취소되었습니다.',
    );
  }

  /// 모임 인원 마감 임박 알림
  static ({String title, String body}) almostFull({
    required String meetingTitle,
    required int remaining,
  }) {
    return (
      title: '마감 임박! 🔥',
      body: '"$meetingTitle" 모임 $remaining자리 남았어요!',
    );
  }

  /// 모임 정보 변경 알림 (참가자들에게)
  static ({String title, String body}) meetingUpdated({
    required String meetingTitle,
    required String changes,
  }) {
    return (
      title: '📝 모임 정보가 변경되었습니다',
      body: '"$meetingTitle" $changes',
    );
  }

  /// 모임 시간 변경 알림 (참가자들에게)
  static ({String title, String body}) meetingTimeChanged({
    required String meetingTitle,
    required String newTime,
  }) {
    return (
      title: '⏰ 모임 시간이 변경되었습니다',
      body: '"$meetingTitle" 새로운 시간: $newTime',
    );
  }

  /// 모임 장소 변경 알림 (참가자들에게)
  static ({String title, String body}) meetingLocationChanged({
    required String meetingTitle,
    required String newLocation,
  }) {
    return (
      title: '📍 모임 장소가 변경되었습니다',
      body: '"$meetingTitle" 새로운 장소: $newLocation',
    );
  }
}
