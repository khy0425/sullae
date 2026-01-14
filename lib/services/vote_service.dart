import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/vote_model.dart';

class VoteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  CollectionReference get _votesRef => _firestore.collection('votes');

  // 투표 생성
  Future<String> createVote({
    required String meetingId,
    required String creatorId,
    required String title,
    required VoteType type,
    required List<String> optionTexts,
    bool allowMultiple = false,
    DateTime? endAt,
  }) async {
    final options = optionTexts.map((text) => VoteOption(
      id: _uuid.v4(),
      text: text,
    )).toList();

    final vote = VoteModel(
      id: '',
      meetingId: meetingId,
      creatorId: creatorId,
      title: title,
      type: type,
      options: options,
      allowMultiple: allowMultiple,
      createdAt: DateTime.now(),
      endAt: endAt,
    );

    final docRef = await _votesRef.add(vote.toFirestore());
    return docRef.id;
  }

  // MVP 투표 생성 (참가자 목록으로 자동 생성)
  Future<String> createMvpVote({
    required String meetingId,
    required String creatorId,
    required List<String> participantNames,
  }) async {
    return createVote(
      meetingId: meetingId,
      creatorId: creatorId,
      title: 'MVP를 선택해주세요!',
      type: VoteType.mvp,
      optionTexts: participantNames,
      allowMultiple: false,
    );
  }

  // 게임 규칙 투표 생성
  Future<String> createGameRuleVote({
    required String meetingId,
    required String creatorId,
    required String question,
    required List<String> options,
  }) async {
    return createVote(
      meetingId: meetingId,
      creatorId: creatorId,
      title: question,
      type: VoteType.gameRule,
      optionTexts: options,
      allowMultiple: false,
    );
  }

  // 투표하기
  Future<bool> vote({
    required String voteId,
    required String optionId,
    required String voterId,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final voteDoc = await transaction.get(_votesRef.doc(voteId));

        if (!voteDoc.exists) {
          throw Exception('투표를 찾을 수 없습니다.');
        }

        final vote = VoteModel.fromFirestore(voteDoc);

        if (!vote.isActive) {
          throw Exception('종료된 투표입니다.');
        }

        // 이미 투표했는지 확인
        for (final option in vote.options) {
          if (option.voterIds.contains(voterId)) {
            if (!vote.allowMultiple) {
              throw Exception('이미 투표하셨습니다.');
            }
          }
        }

        // 투표 옵션 업데이트
        final updatedOptions = vote.options.map((option) {
          if (option.id == optionId) {
            return VoteOption(
              id: option.id,
              text: option.text,
              voteCount: option.voteCount + 1,
              voterIds: [...option.voterIds, voterId],
            );
          }
          return option;
        }).toList();

        transaction.update(_votesRef.doc(voteId), {
          'options': updatedOptions.map((e) => e.toMap()).toList(),
        });
      });
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Vote error: $e');
      return false;
    }
  }

  // 투표 취소
  Future<bool> cancelVote({
    required String voteId,
    required String optionId,
    required String voterId,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final voteDoc = await transaction.get(_votesRef.doc(voteId));

        if (!voteDoc.exists) {
          throw Exception('투표를 찾을 수 없습니다.');
        }

        final vote = VoteModel.fromFirestore(voteDoc);

        final updatedOptions = vote.options.map((option) {
          if (option.id == optionId && option.voterIds.contains(voterId)) {
            return VoteOption(
              id: option.id,
              text: option.text,
              voteCount: option.voteCount - 1,
              voterIds: option.voterIds.where((id) => id != voterId).toList(),
            );
          }
          return option;
        }).toList();

        transaction.update(_votesRef.doc(voteId), {
          'options': updatedOptions.map((e) => e.toMap()).toList(),
        });
      });
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Cancel vote error: $e');
      return false;
    }
  }

  // 투표 종료
  Future<void> endVote(String voteId) async {
    await _votesRef.doc(voteId).update({
      'isActive': false,
      'endAt': Timestamp.now(),
    });
  }

  // 모임의 활성 투표 목록
  Stream<List<VoteModel>> getActiveVotes(String meetingId) {
    return _votesRef
        .where('meetingId', isEqualTo: meetingId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VoteModel.fromFirestore(doc))
            .toList());
  }

  // 단일 투표 스트림
  Stream<VoteModel?> getVoteStream(String voteId) {
    return _votesRef.doc(voteId).snapshots().map((doc) {
      if (doc.exists) {
        return VoteModel.fromFirestore(doc);
      }
      return null;
    });
  }

  // 투표 삭제
  Future<void> deleteVote(String voteId, String creatorId) async {
    final vote = await _votesRef.doc(voteId).get();
    final data = vote.data() as Map<String, dynamic>?;
    if (data != null && data['creatorId'] == creatorId) {
      await _votesRef.doc(voteId).delete();
    }
  }
}
