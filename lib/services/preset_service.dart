import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game_preset_model.dart';
import '../models/meeting_model.dart';

/// 게임 프리셋 관리 서비스
class PresetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _presetsRef => _firestore.collection('game_presets');

  // ============== 프리셋 CRUD ==============

  /// 프리셋 생성
  Future<String> createPreset(GamePreset preset) async {
    final docRef = await _presetsRef.add(preset.toFirestore());
    return docRef.id;
  }

  /// 프리셋 조회
  Future<GamePreset?> getPreset(String presetId) async {
    final doc = await _presetsRef.doc(presetId).get();
    if (doc.exists) {
      return GamePreset.fromFirestore(doc);
    }
    return null;
  }

  /// 프리셋 업데이트
  Future<void> updatePreset(GamePreset preset) async {
    await _presetsRef.doc(preset.id).update(preset.toFirestore());
  }

  /// 프리셋 삭제
  Future<void> deletePreset(String presetId, String userId) async {
    final preset = await getPreset(presetId);
    if (preset != null && preset.creatorId == userId) {
      await _presetsRef.doc(presetId).delete();
    }
  }

  // ============== 프리셋 목록 ==============

  /// 내 프리셋 목록
  Stream<List<GamePreset>> getMyPresets(String userId) {
    return _presetsRef
        .where('creatorId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GamePreset.fromFirestore(doc))
            .toList());
  }

  /// 게임 타입별 내 프리셋
  Stream<List<GamePreset>> getMyPresetsByGameType(String userId, GameType gameType) {
    return _presetsRef
        .where('creatorId', isEqualTo: userId)
        .where('baseGameType', isEqualTo: gameType.index)
        .orderBy('usageCount', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GamePreset.fromFirestore(doc))
            .toList());
  }

  /// 공개 프리셋 목록 (인기순)
  Stream<List<GamePreset>> getPublicPresets({GameType? gameType, int limit = 20}) {
    Query query = _presetsRef
        .where('isPublic', isEqualTo: true)
        .orderBy('usageCount', descending: true)
        .limit(limit);

    if (gameType != null) {
      query = query.where('baseGameType', isEqualTo: gameType.index);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => GamePreset.fromFirestore(doc))
        .toList());
  }

  // ============== 프리셋 사용 ==============

  /// 프리셋 사용 횟수 증가
  Future<void> incrementUsage(String presetId) async {
    await _presetsRef.doc(presetId).update({
      'usageCount': FieldValue.increment(1),
    });
  }

  /// 프리셋으로 모임 생성용 설정 가져오기
  Future<Map<String, dynamic>?> getGameSettingsFromPreset(String presetId) async {
    final preset = await getPreset(presetId);
    if (preset == null) return null;

    await incrementUsage(presetId);

    return {
      'presetId': presetId,
      'presetName': preset.name,
      'rules': preset.rules,
    };
  }

  /// 프리셋 복사 (다른 유저의 공개 프리셋 복사)
  Future<String> copyPreset({
    required String originalPresetId,
    required String newUserId,
    required String newUserNickname,
    String? newName,
  }) async {
    final original = await getPreset(originalPresetId);
    if (original == null) throw Exception('프리셋을 찾을 수 없습니다.');

    final copied = GamePreset(
      id: '',
      name: newName ?? '${original.name} (복사본)',
      description: original.description,
      creatorId: newUserId,
      creatorNickname: newUserNickname,
      baseGameType: original.baseGameType,
      rules: Map<String, dynamic>.from(original.rules),
      isPublic: false,  // 복사본은 비공개로 시작
      usageCount: 0,
      createdAt: DateTime.now(),
    );

    return await createPreset(copied);
  }

  // ============== 공개 설정 ==============

  /// 프리셋 공개/비공개 전환
  Future<void> togglePublic(String presetId, String userId) async {
    final preset = await getPreset(presetId);
    if (preset != null && preset.creatorId == userId) {
      await _presetsRef.doc(presetId).update({
        'isPublic': !preset.isPublic,
        'updatedAt': Timestamp.now(),
      });
    }
  }
}
