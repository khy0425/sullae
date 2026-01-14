import 'package:cloud_firestore/cloud_firestore.dart';

enum VoteType {
  mvp,           // MVP 투표
  gameRule,      // 게임 규칙 투표
  nextLocation,  // 다음 장소 투표
  custom,        // 커스텀 투표
}

class VoteOption {
  final String id;
  final String text;
  final int voteCount;
  final List<String> voterIds;

  VoteOption({
    required this.id,
    required this.text,
    this.voteCount = 0,
    this.voterIds = const [],
  });

  factory VoteOption.fromMap(Map<String, dynamic> data) {
    return VoteOption(
      id: data['id'] ?? '',
      text: data['text'] ?? '',
      voteCount: data['voteCount'] ?? 0,
      voterIds: List<String>.from(data['voterIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'voteCount': voteCount,
      'voterIds': voterIds,
    };
  }
}

class VoteModel {
  final String id;
  final String meetingId;
  final String creatorId;
  final String title;
  final VoteType type;
  final List<VoteOption> options;
  final bool isActive;
  final bool allowMultiple;
  final DateTime createdAt;
  final DateTime? endAt;

  VoteModel({
    required this.id,
    required this.meetingId,
    required this.creatorId,
    required this.title,
    required this.type,
    required this.options,
    this.isActive = true,
    this.allowMultiple = false,
    required this.createdAt,
    this.endAt,
  });

  factory VoteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VoteModel(
      id: doc.id,
      meetingId: data['meetingId'] ?? '',
      creatorId: data['creatorId'] ?? '',
      title: data['title'] ?? '',
      type: VoteType.values[data['type'] ?? 0],
      options: (data['options'] as List<dynamic>?)
              ?.map((e) => VoteOption.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      isActive: data['isActive'] ?? true,
      allowMultiple: data['allowMultiple'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endAt: (data['endAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'meetingId': meetingId,
      'creatorId': creatorId,
      'title': title,
      'type': type.index,
      'options': options.map((e) => e.toMap()).toList(),
      'isActive': isActive,
      'allowMultiple': allowMultiple,
      'createdAt': Timestamp.fromDate(createdAt),
      'endAt': endAt != null ? Timestamp.fromDate(endAt!) : null,
    };
  }

  int get totalVotes => options.fold(0, (total, opt) => total + opt.voteCount);

  VoteOption? get winningOption {
    if (options.isEmpty) return null;
    return options.reduce((a, b) => a.voteCount >= b.voteCount ? a : b);
  }
}
