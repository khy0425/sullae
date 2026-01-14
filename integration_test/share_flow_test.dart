import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sullae/models/meeting_model.dart';
import 'package:sullae/services/share_service.dart';
import 'package:sullae/widgets/share_dialog.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MeetingModel testMeeting;
  late ShareService shareService;

  setUp(() {
    shareService = ShareService();
    testMeeting = MeetingModel(
      id: 'integration-test-meeting',
      title: '통합 테스트 모임',
      description: '통합 테스트용 모임입니다',
      hostId: 'host-integration',
      hostNickname: '통합테스트호스트',
      gameType: GameType.copsAndRobbers,
      location: '테스트 공원',
      locationDetail: '테스트 장소 상세',
      meetingTime: DateTime(2026, 2, 1, 15, 0),
      maxParticipants: 30,
      currentParticipants: 10,
      participantIds: List.generate(10, (i) => 'user-$i'),
      status: MeetingStatus.recruiting,
      createdAt: DateTime.now(),
      joinCode: 'TEST99',
      externalChatLink: 'https://open.kakao.com/integration-test',
    );
  });

  Widget createTestApp(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('Share Flow Integration Tests', () {
    testWidgets('Complete share flow: open dialog -> gather people -> copy message',
        (tester) async {
      await tester.pumpWidget(createTestApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => ShareMeetingDialog(meeting: testMeeting),
              );
            },
            child: const Text('공유하기'),
          ),
        ),
      ));

      // Step 1: Open share dialog
      await tester.tap(find.text('공유하기'));
      await tester.pumpAndSettle();

      // Verify dialog opened
      expect(find.text('모임 공유하기'), findsOneWidget);
      expect(find.text(testMeeting.joinCode), findsOneWidget);

      // Step 2: Tap "사람 모으기" button
      await tester.tap(find.text('사람 모으기'));
      await tester.pumpAndSettle();

      // Verify GatherPeopleSheet opened
      expect(find.text('사람 모으기'), findsOneWidget);
      expect(find.text('초대 메시지를 만들어 공유하세요'), findsOneWidget);

      // Step 3: Select a channel (Community)
      await tester.tap(find.text('커뮤니티'));
      await tester.pumpAndSettle();

      // Verify enthusiastic tone is auto-selected
      expect(find.textContaining('같이 하실 분!'), findsOneWidget);

      // Step 4: Change tone to casual
      await tester.tap(find.text('편하게'));
      await tester.pumpAndSettle();

      // Verify casual message format
      expect(find.textContaining('할 사람~?'), findsOneWidget);

      // Step 5: Modify chat link
      const newLink = 'https://modified.chat.link';
      await tester.enterText(find.byType(TextField), newLink);
      await tester.pumpAndSettle();

      // Verify new link in preview
      expect(find.textContaining(newLink), findsOneWidget);

      // Step 6: Copy message
      await tester.tap(find.text('메시지 복사하기'));
      await tester.pumpAndSettle();

      // Verify snackbar shows
      expect(find.text('초대 메시지가 복사되었습니다'), findsOneWidget);
    });

    testWidgets('Share dialog shows external chat link and can open it',
        (tester) async {
      await tester.pumpWidget(createTestApp(
        ShareMeetingDialog(meeting: testMeeting),
      ));

      // Verify external chat link row is displayed
      expect(find.text('채팅방 바로가기'), findsOneWidget);
      expect(find.textContaining('open.kakao.com'), findsOneWidget);

      // The open_in_new icon should be present
      expect(find.byIcon(Icons.open_in_new), findsOneWidget);
    });

    testWidgets('QR code dialog opens from share dialog', (tester) async {
      await tester.pumpWidget(createTestApp(
        ShareMeetingDialog(meeting: testMeeting),
      ));

      // Tap QR code button
      await tester.tap(find.text('QR 코드'));
      await tester.pumpAndSettle();

      // Verify QR dialog opened
      expect(find.text('참가 코드'), findsOneWidget);
      expect(find.text('친구에게 이 화면을 보여주세요'), findsOneWidget);
    });

    testWidgets('Copy join code from share dialog', (tester) async {
      await tester.pumpWidget(createTestApp(
        ShareMeetingDialog(meeting: testMeeting),
      ));

      // Tap copy code button
      await tester.tap(find.text('코드 복사'));
      await tester.pumpAndSettle();

      // Verify snackbar shows
      expect(find.text('참가코드가 복사되었습니다'), findsOneWidget);
    });

    testWidgets('Channel selection updates tone automatically', (tester) async {
      await tester.pumpWidget(createTestApp(
        GatherPeopleSheet(
          meeting: testMeeting,
          shareService: shareService,
        ),
      ));

      // Initially KakaoTalk is selected -> casual tone
      expect(find.textContaining('할 사람~?'), findsOneWidget);

      // Select OpenChat -> should switch to enthusiastic
      await tester.tap(find.text('오픈채팅'));
      await tester.pumpAndSettle();
      expect(find.textContaining('같이 하실 분!'), findsOneWidget);

      // Select Instagram -> should switch back to casual
      await tester.tap(find.text('인스타그램'));
      await tester.pumpAndSettle();
      expect(find.textContaining('할 사람~?'), findsOneWidget);

      // Select Community -> should switch to enthusiastic
      await tester.tap(find.text('커뮤니티'));
      await tester.pumpAndSettle();
      expect(find.textContaining('같이 하실 분!'), findsOneWidget);
    });

    testWidgets('Message preview updates in real-time', (tester) async {
      await tester.pumpWidget(createTestApp(
        GatherPeopleSheet(
          meeting: testMeeting,
          shareService: shareService,
        ),
      ));

      // Initial state - should contain meeting info
      expect(find.textContaining(testMeeting.title), findsWidgets);
      expect(find.textContaining(testMeeting.location), findsWidgets);
      expect(find.textContaining(testMeeting.joinCode), findsWidgets);

      // Change tone
      await tester.tap(find.text('활기차게'));
      await tester.pumpAndSettle();

      // Preview should update to enthusiastic format
      expect(find.textContaining('술래 앱에서 만나요!'), findsOneWidget);

      // Enter custom link
      const customLink = 'https://custom.test.link';
      await tester.enterText(find.byType(TextField), customLink);
      await tester.pumpAndSettle();

      // Preview should contain custom link
      expect(find.textContaining(customLink), findsOneWidget);
    });

    testWidgets('Meeting without external link works correctly', (tester) async {
      final meetingNoLink = MeetingModel(
        id: 'no-link-meeting',
        title: '링크 없는 모임',
        description: '설명',
        hostId: 'host',
        hostNickname: '호스트',
        gameType: GameType.freezeTag,
        location: '테스트 장소',
        meetingTime: DateTime(2026, 3, 1, 10, 0),
        maxParticipants: 15,
        currentParticipants: 3,
        participantIds: ['host', 'u1', 'u2'],
        status: MeetingStatus.recruiting,
        createdAt: DateTime.now(),
        joinCode: 'NOLINK',
      );

      await tester.pumpWidget(createTestApp(
        ShareMeetingDialog(meeting: meetingNoLink),
      ));

      // External chat link row should not be displayed
      expect(find.text('채팅방 바로가기'), findsNothing);

      // Open gather people sheet
      await tester.tap(find.text('사람 모으기'));
      await tester.pumpAndSettle();

      // TextField should be empty
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);

      // Preview should not contain chat link text
      expect(find.textContaining('참여하려면 여기로'), findsNothing);
      expect(find.textContaining('채팅방:'), findsNothing);
    });
  });

  group('ShareService Integration', () {
    test('generateInviteMessage produces valid message for all channels', () {
      for (final channel in ShareChannel.values) {
        final recommendedTone = shareService.getRecommendedTone(channel);
        final message = shareService.generateInviteMessage(
          meeting: testMeeting,
          tone: recommendedTone,
        );

        // All messages should contain essential info
        expect(message, contains(testMeeting.title));
        expect(message, contains(testMeeting.location));
        expect(message, contains(testMeeting.joinCode));

        // Message should not be empty
        expect(message.trim().isNotEmpty, isTrue);
      }
    });

    test('all channel names and icons are defined', () {
      for (final channel in ShareChannel.values) {
        final name = shareService.getChannelName(channel);
        final icon = shareService.getChannelIcon(channel);

        expect(name.isNotEmpty, isTrue);
        expect(icon, isNotNull);
      }
    });
  });
}
