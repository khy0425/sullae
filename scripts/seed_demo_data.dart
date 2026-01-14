// ignore_for_file: avoid_print

/// 술래 앱 - 데모 데이터 시딩 스크립트
///
/// 영상 촬영용 데모 데이터를 Firestore에 추가합니다.
///
/// 사용법:
/// 1. Firebase CLI 로그인 확인
/// 2. flutter run -t scripts/seed_demo_data.dart
///
/// 또는 앱 내에서 개발자 메뉴를 통해 실행
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// 데모용 가상 사용자 데이터
final demoUsers = [
  {
    'uid': 'demo_user_1',
    'nickname': '달리기왕',
    'photoUrl': null,
    'ageRange': 1, // 20대
    'loginProvider': 0, // kakao
    'gamesPlayed': 12,
    'gamesHosted': 3,
    'mvpCount': 2,
    'volunteerCount': 5,
  },
  {
    'uid': 'demo_user_2',
    'nickname': '숨바꼭질러버',
    'photoUrl': null,
    'ageRange': 1, // 20대
    'loginProvider': 1, // google
    'gamesPlayed': 8,
    'gamesHosted': 1,
    'mvpCount': 1,
    'volunteerCount': 3,
  },
  {
    'uid': 'demo_user_3',
    'nickname': '공원지기',
    'photoUrl': null,
    'ageRange': 2, // 30대+
    'loginProvider': 0,
    'gamesPlayed': 25,
    'gamesHosted': 10,
    'mvpCount': 5,
    'volunteerCount': 8,
  },
  {
    'uid': 'demo_user_4',
    'nickname': '러닝맨',
    'photoUrl': null,
    'ageRange': 1,
    'loginProvider': 0,
    'gamesPlayed': 15,
    'gamesHosted': 2,
    'mvpCount': 3,
    'volunteerCount': 4,
  },
  {
    'uid': 'demo_user_5',
    'nickname': '술래마스터',
    'photoUrl': null,
    'ageRange': 0, // 10대
    'loginProvider': 1,
    'gamesPlayed': 30,
    'gamesHosted': 5,
    'mvpCount': 8,
    'volunteerCount': 10,
  },
];

// 데모용 모임 데이터
List<Map<String, dynamic>> getDemoMeetings() {
  final now = DateTime.now();
  final tomorrow = now.add(const Duration(days: 1));
  final thisWeekend = now.add(Duration(days: (6 - now.weekday) % 7 + 1));

  return [
    // 오늘 모임 - 곧 시작
    {
      'id': 'demo_meeting_1',
      'title': '한강 술래잡기 같이해요! 🏃',
      'description': '퇴근하고 시원한 한강에서 술래잡기 한 판 어때요? 초보도 환영합니다!',
      'hostId': 'demo_user_3',
      'hostNickname': '공원지기',
      'gameType': 1, // 얼음땡
      'location': '여의도 한강공원',
      'locationDetail': '여의나루역 2번 출구 앞 잔디밭',
      'latitude': 37.5283,
      'longitude': 126.9324,
      'meetingTime': Timestamp.fromDate(
        DateTime(now.year, now.month, now.day, 19, 0),
      ),
      'maxParticipants': 8,
      'currentParticipants': 5,
      'participantIds': ['demo_user_3', 'demo_user_1', 'demo_user_2', 'demo_user_4', 'demo_user_5'],
      'status': 0, // recruiting
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 3))),
      'joinCode': 'HAN123',
      'region': 'seoul:yeongdeungpo',
      'difficulty': 0, // casual
      'targetAgeGroups': ['20대', '30대'],
    },
    // 내일 모임 - 모집중
    {
      'id': 'demo_meeting_2',
      'title': '올림픽공원 경찰과 도둑 ⚔️',
      'description': '넓은 올림픽공원에서 경찰과 도둑! 팀전으로 진행합니다. 체력 좀 있으신 분들 추천!',
      'hostId': 'demo_user_1',
      'hostNickname': '달리기왕',
      'gameType': 0, // 경찰과 도둑
      'location': '올림픽공원',
      'locationDetail': '평화의 광장',
      'latitude': 37.5209,
      'longitude': 127.1217,
      'meetingTime': Timestamp.fromDate(
        DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 15, 0),
      ),
      'maxParticipants': 12,
      'currentParticipants': 4,
      'participantIds': ['demo_user_1', 'demo_user_2', 'demo_user_5', 'demo_user_4'],
      'status': 0,
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 12))),
      'joinCode': 'OLY456',
      'region': 'seoul:songpa',
      'difficulty': 1, // competitive
      'targetAgeGroups': ['20대'],
    },
    // 주말 모임 - 대규모
    {
      'id': 'demo_meeting_3',
      'title': '주말 대규모 술래잡기 대회 🏆',
      'description': '매주 토요일 정기 모임! 우승팀에게 소정의 상품이 있어요. 처음 오시는 분들도 환영합니다~',
      'hostId': 'demo_user_5',
      'hostNickname': '술래마스터',
      'gameType': 2, // 숨바꼭질
      'location': '서울숲',
      'locationDetail': '뚝섬역 8번 출구에서 도보 5분',
      'latitude': 37.5443,
      'longitude': 127.0374,
      'meetingTime': Timestamp.fromDate(
        DateTime(thisWeekend.year, thisWeekend.month, thisWeekend.day, 14, 0),
      ),
      'maxParticipants': 20,
      'currentParticipants': 8,
      'participantIds': ['demo_user_5', 'demo_user_1', 'demo_user_2', 'demo_user_3', 'demo_user_4', 'demo_other_1', 'demo_other_2', 'demo_other_3'],
      'status': 0,
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
      'joinCode': 'WKD789',
      'region': 'seoul:seongdong',
      'difficulty': 2, // beginner
      'targetAgeGroups': [],
    },
  ];
}

// 데모용 채팅 메시지
List<Map<String, dynamic>> getDemoMessages(String meetingId) {
  final now = DateTime.now();
  return [
    {
      'id': 'msg_1',
      'meetingId': meetingId,
      'senderId': 'demo_user_3',
      'senderNickname': '공원지기',
      'content': '오늘 날씨 좋아서 기대되네요!',
      'type': 'text',
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 2))),
    },
    {
      'id': 'msg_2',
      'meetingId': meetingId,
      'senderId': 'demo_user_1',
      'senderNickname': '달리기왕',
      'content': '저도요! 빨리 뛰고 싶어요 ㅋㅋ',
      'type': 'text',
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 1, minutes: 45))),
    },
    {
      'id': 'msg_3',
      'meetingId': meetingId,
      'senderId': 'demo_user_2',
      'senderNickname': '숨바꼭질러버',
      'content': '혹시 물 챙겨가야 하나요?',
      'type': 'text',
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 1, minutes: 30))),
    },
    {
      'id': 'msg_4',
      'meetingId': meetingId,
      'senderId': 'demo_user_3',
      'senderNickname': '공원지기',
      'content': '근처 편의점 있어요! 가볍게 오세요~',
      'type': 'text',
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 1, minutes: 20))),
    },
    {
      'id': 'msg_5',
      'meetingId': meetingId,
      'senderId': 'demo_user_4',
      'senderNickname': '러닝맨',
      'content': '저 거의 도착했어요!',
      'type': 'text',
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(minutes: 30))),
    },
  ];
}

/// Firestore에 데모 데이터 추가
Future<void> seedDemoData() async {
  final firestore = FirebaseFirestore.instance;
  final batch = firestore.batch();
  final now = DateTime.now();

  print('🌱 데모 데이터 시딩 시작...');

  // 1. 사용자 데이터 추가
  print('👤 사용자 데이터 추가 중...');
  for (final user in demoUsers) {
    final docRef = firestore.collection('users').doc(user['uid'] as String);
    batch.set(docRef, {
      ...user,
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 30))),
      'lastActiveAt': Timestamp.fromDate(now),
    });
  }

  // 2. 모임 데이터 추가
  print('📍 모임 데이터 추가 중...');
  final meetings = getDemoMeetings();
  for (final meeting in meetings) {
    final docRef = firestore.collection('meetings').doc(meeting['id'] as String);
    batch.set(docRef, meeting);
  }

  await batch.commit();

  // 3. 첫 번째 모임에 채팅 메시지 추가
  print('💬 채팅 메시지 추가 중...');
  final messageBatch = firestore.batch();
  final messages = getDemoMessages('demo_meeting_1');
  for (final message in messages) {
    final docRef = firestore
        .collection('meetings')
        .doc('demo_meeting_1')
        .collection('messages')
        .doc(message['id'] as String);
    messageBatch.set(docRef, message);
  }
  await messageBatch.commit();

  print('✅ 데모 데이터 시딩 완료!');
  print('');
  print('📊 추가된 데이터:');
  print('   - 사용자: ${demoUsers.length}명');
  print('   - 모임: ${meetings.length}개');
  print('   - 채팅 메시지: ${messages.length}개');
}

/// 데모 데이터 삭제
Future<void> clearDemoData() async {
  final firestore = FirebaseFirestore.instance;

  print('🗑️ 데모 데이터 삭제 중...');

  // 사용자 삭제
  for (final user in demoUsers) {
    await firestore.collection('users').doc(user['uid'] as String).delete();
  }

  // 모임 및 하위 컬렉션 삭제
  final meetings = getDemoMeetings();
  for (final meeting in meetings) {
    final meetingId = meeting['id'] as String;

    // 메시지 삭제
    final messagesSnapshot = await firestore
        .collection('meetings')
        .doc(meetingId)
        .collection('messages')
        .get();
    for (final doc in messagesSnapshot.docs) {
      await doc.reference.delete();
    }

    // 모임 삭제
    await firestore.collection('meetings').doc(meetingId).delete();
  }

  print('✅ 데모 데이터 삭제 완료!');
}

// 개발자 메뉴에서 호출할 수 있는 위젯
class DemoDataSeeder extends StatelessWidget {
  const DemoDataSeeder({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '영상 촬영용 데모 데이터',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text(
          '데모 사용자 5명, 모임 3개, 채팅 메시지가 추가됩니다.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  await seedDemoData();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('데모 데이터가 추가되었습니다!')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('오류: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('데이터 추가'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  await clearDemoData();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('데모 데이터가 삭제되었습니다!')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('오류: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.delete),
              label: const Text('데이터 삭제'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
