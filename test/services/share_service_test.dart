import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sullae/models/meeting_model.dart';
import 'package:sullae/services/share_service.dart';

void main() {
  late ShareService shareService;
  late MeetingModel testMeeting;

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

  group('ShareService', () {
    group('generateInviteMessage', () {
      test('casual tone should include friendly language', () {
        final message = shareService.generateInviteMessage(
          meeting: testMeeting,
          tone: InviteTone.casual,
        );

        expect(message, contains('할 사람~?'));
        expect(message, contains(testMeeting.title));
        expect(message, contains(testMeeting.location));
        expect(message, contains(testMeeting.joinCode));
        expect(message, contains('5/20명 모집 중!'));
      });

      test('enthusiastic tone should include energetic language', () {
        final message = shareService.generateInviteMessage(
          meeting: testMeeting,
          tone: InviteTone.enthusiastic,
        );

        expect(message, contains('같이 하실 분!'));
        expect(message, contains(testMeeting.title));
        expect(message, contains(testMeeting.location));
        expect(message, contains(testMeeting.joinCode));
        expect(message, contains('술래 앱에서 만나요!'));
      });

      test('should include external chat link when available', () {
        final message = shareService.generateInviteMessage(
          meeting: testMeeting,
          tone: InviteTone.casual,
        );

        expect(message, contains(testMeeting.externalChatLink!));
      });

      test('should use custom chat link when provided', () {
        const customLink = 'https://custom.link/chat';
        final message = shareService.generateInviteMessage(
          meeting: testMeeting,
          tone: InviteTone.casual,
          customChatLink: customLink,
        );

        expect(message, contains(customLink));
        expect(message, isNot(contains(testMeeting.externalChatLink)));
      });

      test('should not include chat link section when no link available', () {
        // Create meeting without external chat link
        final noLinkMeeting = MeetingModel(
          id: testMeeting.id,
          title: testMeeting.title,
          description: testMeeting.description,
          hostId: testMeeting.hostId,
          hostNickname: testMeeting.hostNickname,
          gameType: testMeeting.gameType,
          location: testMeeting.location,
          meetingTime: testMeeting.meetingTime,
          maxParticipants: testMeeting.maxParticipants,
          currentParticipants: testMeeting.currentParticipants,
          participantIds: testMeeting.participantIds,
          status: testMeeting.status,
          createdAt: testMeeting.createdAt,
          joinCode: testMeeting.joinCode,
          // externalChatLink is null
        );

        final message = shareService.generateInviteMessage(
          meeting: noLinkMeeting,
          tone: InviteTone.casual,
        );

        expect(message, isNot(contains('참여하려면 여기로')));
        expect(message, isNot(contains('채팅방:')));
      });
    });

    group('getRecommendedTone', () {
      test('should return casual for KakaoTalk', () {
        expect(
          shareService.getRecommendedTone(ShareChannel.kakaoTalk),
          equals(InviteTone.casual),
        );
      });

      test('should return casual for Instagram', () {
        expect(
          shareService.getRecommendedTone(ShareChannel.instagram),
          equals(InviteTone.casual),
        );
      });

      test('should return enthusiastic for OpenChat', () {
        expect(
          shareService.getRecommendedTone(ShareChannel.openChat),
          equals(InviteTone.enthusiastic),
        );
      });

      test('should return enthusiastic for Community', () {
        expect(
          shareService.getRecommendedTone(ShareChannel.community),
          equals(InviteTone.enthusiastic),
        );
      });
    });

    group('getChannelName', () {
      test('should return correct Korean names', () {
        expect(shareService.getChannelName(ShareChannel.kakaoTalk), '카카오톡');
        expect(shareService.getChannelName(ShareChannel.openChat), '오픈채팅');
        expect(shareService.getChannelName(ShareChannel.instagram), '인스타그램');
        expect(shareService.getChannelName(ShareChannel.community), '커뮤니티');
      });
    });

    group('getChannelIcon', () {
      test('should return correct icons', () {
        expect(shareService.getChannelIcon(ShareChannel.kakaoTalk), Icons.chat_bubble);
        expect(shareService.getChannelIcon(ShareChannel.openChat), Icons.forum);
        expect(shareService.getChannelIcon(ShareChannel.instagram), Icons.camera_alt);
        expect(shareService.getChannelIcon(ShareChannel.community), Icons.groups);
      });
    });

    group('generateShareMessage', () {
      test('should include all meeting details', () {
        final message = shareService.generateShareMessage(testMeeting);

        expect(message, contains(testMeeting.title));
        expect(message, contains('경찰과 도둑')); // gameTypeName
        expect(message, contains(testMeeting.location));
        expect(message, contains(testMeeting.joinCode));
      });
    });

    group('generateSimpleShareText', () {
      test('should be concise', () {
        final text = shareService.generateSimpleShareText(testMeeting);

        expect(text, contains(testMeeting.title));
        expect(text, contains(testMeeting.joinCode));
        expect(text.length, lessThan(100));
      });
    });
  });
}
