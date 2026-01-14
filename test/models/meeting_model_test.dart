import 'package:flutter_test/flutter_test.dart';
import 'package:sullae/models/meeting_model.dart';

void main() {
  group('MeetingModel', () {
    late MeetingModel baseMeeting;

    setUp(() {
      baseMeeting = MeetingModel(
        id: 'test-id',
        title: '테스트 모임',
        description: '테스트 설명',
        hostId: 'host-123',
        hostNickname: '호스트닉네임',
        gameType: GameType.copsAndRobbers,
        location: '서울 강남',
        meetingTime: DateTime(2026, 1, 15, 14, 0),
        maxParticipants: 20,
        currentParticipants: 5,
        participantIds: ['host-123', 'u1', 'u2', 'u3', 'u4'],
        status: MeetingStatus.recruiting,
        createdAt: DateTime(2026, 1, 1),
        joinCode: 'ABC123',
        externalChatLink: 'https://open.kakao.com/test',
      );
    });

    group('externalChatLink', () {
      test('should store external chat link', () {
        expect(baseMeeting.externalChatLink, 'https://open.kakao.com/test');
      });

      test('should allow null external chat link', () {
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

        expect(meetingNoLink.externalChatLink, isNull);
      });
    });

    group('copyWith', () {
      test('should copy with new externalChatLink', () {
        const newLink = 'https://new.link/chat';
        final copied = baseMeeting.copyWith(externalChatLink: newLink);

        expect(copied.externalChatLink, newLink);
        expect(copied.title, baseMeeting.title);
        expect(copied.id, baseMeeting.id);
      });

      test('should preserve externalChatLink when not specified', () {
        final copied = baseMeeting.copyWith(title: '새 제목');

        expect(copied.externalChatLink, baseMeeting.externalChatLink);
        expect(copied.title, '새 제목');
      });
    });

    group('toFirestore', () {
      test('should include externalChatLink in map', () {
        final map = baseMeeting.toFirestore();

        expect(map['externalChatLink'], 'https://open.kakao.com/test');
      });

      test('should include null externalChatLink in map', () {
        final meetingNoLink = MeetingModel(
          id: 'test-id',
          title: '테스트',
          description: '설명',
          hostId: 'host',
          hostNickname: '호스트',
          gameType: GameType.hideAndSeek,
          location: '장소',
          meetingTime: DateTime.now(),
          maxParticipants: 10,
          currentParticipants: 1,
          participantIds: ['host'],
          status: MeetingStatus.recruiting,
          createdAt: DateTime.now(),
          joinCode: 'XYZ789',
        );

        final map = meetingNoLink.toFirestore();
        expect(map.containsKey('externalChatLink'), isTrue);
        expect(map['externalChatLink'], isNull);
      });
    });

    group('gameTypeName', () {
      test('should return correct name for each game type', () {
        final cops = baseMeeting.copyWith(gameType: GameType.copsAndRobbers);
        expect(cops.gameTypeName, '경찰과 도둑');

        final freeze = baseMeeting.copyWith(gameType: GameType.freezeTag);
        expect(freeze.gameTypeName, '얼음땡');

        final hide = baseMeeting.copyWith(gameType: GameType.hideAndSeek);
        expect(hide.gameTypeName, '숨바꼭질');

        final flag = baseMeeting.copyWith(gameType: GameType.captureFlag);
        expect(flag.gameTypeName, '깃발뺏기');

        final custom = baseMeeting.copyWith(gameType: GameType.custom);
        expect(custom.gameTypeName, '커스텀');
      });
    });

    group('groupSize', () {
      test('should return small for 8 or less participants', () {
        final small = MeetingModel(
          id: 'id',
          title: 't',
          description: 'd',
          hostId: 'h',
          hostNickname: 'hn',
          gameType: GameType.freezeTag,
          location: 'l',
          meetingTime: DateTime.now(),
          maxParticipants: 8,
          currentParticipants: 1,
          participantIds: ['h'],
          status: MeetingStatus.recruiting,
          createdAt: DateTime.now(),
          joinCode: 'ABC',
        );

        expect(small.groupSize, GroupSize.small);
      });

      test('should return medium for 9-15 participants', () {
        final medium = MeetingModel(
          id: 'id',
          title: 't',
          description: 'd',
          hostId: 'h',
          hostNickname: 'hn',
          gameType: GameType.freezeTag,
          location: 'l',
          meetingTime: DateTime.now(),
          maxParticipants: 15,
          currentParticipants: 1,
          participantIds: ['h'],
          status: MeetingStatus.recruiting,
          createdAt: DateTime.now(),
          joinCode: 'ABC',
        );

        expect(medium.groupSize, GroupSize.medium);
      });

      test('should return large for 16+ participants', () {
        final large = MeetingModel(
          id: 'id',
          title: 't',
          description: 'd',
          hostId: 'h',
          hostNickname: 'hn',
          gameType: GameType.freezeTag,
          location: 'l',
          meetingTime: DateTime.now(),
          maxParticipants: 20,
          currentParticipants: 1,
          participantIds: ['h'],
          status: MeetingStatus.recruiting,
          createdAt: DateTime.now(),
          joinCode: 'ABC',
        );

        expect(large.groupSize, GroupSize.large);
      });
    });

    group('generateJoinCode', () {
      test('should generate 6 character code', () {
        final code = MeetingModel.generateJoinCode();
        expect(code.length, 6);
      });

      test('should not contain confusing characters (0, O, 1, I)', () {
        // Generate multiple codes to increase confidence
        for (int i = 0; i < 100; i++) {
          final code = MeetingModel.generateJoinCode();
          expect(code, isNot(contains('0')));
          expect(code, isNot(contains('O')));
          expect(code, isNot(contains('1')));
          expect(code, isNot(contains('I')));
        }
      });

      test('should only contain uppercase letters and numbers', () {
        final code = MeetingModel.generateJoinCode();
        expect(code, matches(RegExp(r'^[A-Z2-9]+$')));
      });
    });

    group('status checks', () {
      test('isRecruiting should be true when recruiting', () {
        expect(baseMeeting.status, MeetingStatus.recruiting);
      });

      test('different statuses should work correctly', () {
        final inProgress = baseMeeting.copyWith(status: MeetingStatus.inProgress);
        expect(inProgress.status, MeetingStatus.inProgress);

        final finished = baseMeeting.copyWith(status: MeetingStatus.finished);
        expect(finished.status, MeetingStatus.finished);

        final cancelled = baseMeeting.copyWith(status: MeetingStatus.cancelled);
        expect(cancelled.status, MeetingStatus.cancelled);
      });
    });
  });
}
