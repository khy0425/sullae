import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sullae/models/meeting_model.dart';
import 'package:sullae/services/share_service.dart';
import 'package:sullae/widgets/share_dialog.dart';

void main() {
  late MeetingModel testMeeting;
  late ShareService shareService;

  setUp(() {
    shareService = ShareService();
    testMeeting = MeetingModel(
      id: 'test-meeting-id',
      title: '한강공원 경찰과 도둑',
      description: '재밌게 놀아요!',
      hostId: 'host-123',
      hostNickname: '테스트호스트',
      gameType: GameType.copsAndRobbers,
      location: '여의도 한강공원',
      locationDetail: '물빛무대 앞',
      meetingTime: DateTime(2026, 1, 10, 14, 0),
      maxParticipants: 20,
      currentParticipants: 5,
      participantIds: ['host-123', 'user-1', 'user-2', 'user-3', 'user-4'],
      status: MeetingStatus.recruiting,
      createdAt: DateTime.now(),
      joinCode: 'ABC123',
      externalChatLink: 'https://open.kakao.com/test',
    );
  });

  Widget createTestWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => child,
        ),
      ),
    );
  }

  group('GatherPeopleSheet', () {
    testWidgets('should display title and subtitle', (tester) async {
      await tester.pumpWidget(createTestWidget(
        GatherPeopleSheet(
          meeting: testMeeting,
          shareService: shareService,
        ),
      ));

      expect(find.text('사람 모으기'), findsOneWidget);
      expect(find.text('초대 메시지를 만들어 공유하세요'), findsOneWidget);
    });

    testWidgets('should display channel selection chips', (tester) async {
      await tester.pumpWidget(createTestWidget(
        GatherPeopleSheet(
          meeting: testMeeting,
          shareService: shareService,
        ),
      ));

      expect(find.text('어디서 공유할까요?'), findsOneWidget);
      expect(find.text('카카오톡'), findsOneWidget);
      expect(find.text('오픈채팅'), findsOneWidget);
      expect(find.text('인스타그램'), findsOneWidget);
      expect(find.text('커뮤니티'), findsOneWidget);
    });

    testWidgets('should display tone selection buttons', (tester) async {
      await tester.pumpWidget(createTestWidget(
        GatherPeopleSheet(
          meeting: testMeeting,
          shareService: shareService,
        ),
      ));

      expect(find.text('메시지 스타일'), findsOneWidget);
      expect(find.text('편하게'), findsOneWidget);
      expect(find.text('활기차게'), findsOneWidget);
      expect(find.text('친구들에게'), findsOneWidget);
      expect(find.text('동네 모집'), findsOneWidget);
    });

    testWidgets('should display chat link input field', (tester) async {
      await tester.pumpWidget(createTestWidget(
        GatherPeopleSheet(
          meeting: testMeeting,
          shareService: shareService,
        ),
      ));

      expect(find.text('채팅방 링크 (선택)'), findsOneWidget);
      expect(find.text('오픈채팅 링크를 넣으면 메시지에 포함됩니다'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('should pre-fill chat link from meeting', (tester) async {
      await tester.pumpWidget(createTestWidget(
        GatherPeopleSheet(
          meeting: testMeeting,
          shareService: shareService,
        ),
      ));

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, testMeeting.externalChatLink);
    });

    testWidgets('should display preview section', (tester) async {
      await tester.pumpWidget(createTestWidget(
        GatherPeopleSheet(
          meeting: testMeeting,
          shareService: shareService,
        ),
      ));

      expect(find.text('미리보기'), findsOneWidget);
    });

    testWidgets('should display copy button', (tester) async {
      await tester.pumpWidget(createTestWidget(
        GatherPeopleSheet(
          meeting: testMeeting,
          shareService: shareService,
        ),
      ));

      expect(find.text('메시지 복사하기'), findsOneWidget);
      expect(find.byIcon(Icons.copy), findsOneWidget);
    });

    testWidgets('should change tone when button tapped', (tester) async {
      await tester.pumpWidget(createTestWidget(
        GatherPeopleSheet(
          meeting: testMeeting,
          shareService: shareService,
        ),
      ));

      // Initially casual is selected (default for KakaoTalk)
      // Tap on enthusiastic
      await tester.tap(find.text('활기차게'));
      await tester.pumpAndSettle();

      // Preview should now show enthusiastic message
      expect(find.textContaining('같이 하실 분!'), findsOneWidget);
    });

    testWidgets('should update preview when chat link changed', (tester) async {
      await tester.pumpWidget(createTestWidget(
        GatherPeopleSheet(
          meeting: testMeeting,
          shareService: shareService,
        ),
      ));

      // Enter new chat link
      const newLink = 'https://new.chat.link';
      await tester.enterText(find.byType(TextField), newLink);
      await tester.pumpAndSettle();

      // Preview should contain new link (may appear in TextField and preview)
      expect(find.textContaining(newLink), findsWidgets);
    });

    testWidgets('channel selection should change recommended tone', (tester) async {
      await tester.pumpWidget(createTestWidget(
        GatherPeopleSheet(
          meeting: testMeeting,
          shareService: shareService,
        ),
      ));

      // Tap on community channel (should recommend enthusiastic)
      await tester.tap(find.text('커뮤니티'));
      await tester.pumpAndSettle();

      // Message should now be enthusiastic style
      expect(find.textContaining('같이 하실 분!'), findsOneWidget);
    });

    testWidgets('should show meeting details in preview', (tester) async {
      await tester.pumpWidget(createTestWidget(
        GatherPeopleSheet(
          meeting: testMeeting,
          shareService: shareService,
        ),
      ));

      // Check that meeting details are in the preview
      expect(find.textContaining(testMeeting.title), findsWidgets);
      expect(find.textContaining(testMeeting.location), findsWidgets);
      expect(find.textContaining(testMeeting.joinCode), findsWidgets);
    });

    testWidgets('should display hint text at bottom', (tester) async {
      await tester.pumpWidget(createTestWidget(
        GatherPeopleSheet(
          meeting: testMeeting,
          shareService: shareService,
        ),
      ));

      expect(
        find.text('복사 후 카카오톡이나 SNS에 붙여넣기 하세요'),
        findsOneWidget,
      );
    });
  });

  group('ShareMeetingDialog', () {
    testWidgets('should display join code prominently', (tester) async {
      await tester.pumpWidget(createTestWidget(
        ShareMeetingDialog(meeting: testMeeting),
      ));

      expect(find.text('참가코드'), findsOneWidget);
      expect(find.text(testMeeting.joinCode), findsOneWidget);
    });

    testWidgets('should display share buttons', (tester) async {
      await tester.pumpWidget(createTestWidget(
        ShareMeetingDialog(meeting: testMeeting),
      ));

      expect(find.text('코드 복사'), findsOneWidget);
      expect(find.text('사람 모으기'), findsOneWidget);
      expect(find.text('QR 코드'), findsOneWidget);
    });

    testWidgets('should show external chat link when available', (tester) async {
      await tester.pumpWidget(createTestWidget(
        ShareMeetingDialog(meeting: testMeeting),
      ));

      expect(find.text('채팅방 바로가기'), findsOneWidget);
    });

    testWidgets('should not show external chat link row when null', (tester) async {
      final meetingNoLink = MeetingModel(
        id: 'test-id',
        title: '테스트',
        description: '설명',
        hostId: 'host',
        hostNickname: '호스트',
        gameType: GameType.freezeTag,
        location: '장소',
        meetingTime: DateTime.now(),
        maxParticipants: 10,
        currentParticipants: 1,
        participantIds: ['host'],
        status: MeetingStatus.recruiting,
        createdAt: DateTime.now(),
        joinCode: 'XYZ789',
      );

      await tester.pumpWidget(createTestWidget(
        ShareMeetingDialog(meeting: meetingNoLink),
      ));

      expect(find.text('채팅방 바로가기'), findsNothing);
    });

    testWidgets('should have close button', (tester) async {
      await tester.pumpWidget(createTestWidget(
        ShareMeetingDialog(meeting: testMeeting),
      ));

      expect(find.text('닫기'), findsOneWidget);
    });
  });
}
