import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game_guide_model.dart';
import '../models/meeting_model.dart';

/// 게임 가이드 서비스
///
/// 게임 설명서와 로컬 룰을 관리
class GameGuideService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _guidesRef => _firestore.collection('game_guides');

  // ============== 가이드 CRUD ==============

  /// 가이드 생성 (모임 생성 시 자동)
  Future<String> createGuide({
    required String meetingId,
    required String hostId,
    required GameType gameType,
    List<String>? localRules,
    String? specialNote,
  }) async {
    final guide = GameGuide(
      id: '',
      meetingId: meetingId,
      hostId: hostId,
      gameType: gameType,
      localRules: localRules ?? [],
      specialNote: specialNote,
      requirements: GameGuide.getDefaultRequirements(gameType),
      phases: DefaultGamePhases.getPhases(gameType),
      safetyRules: GameGuide.defaultSafetyRules,
      createdAt: DateTime.now(),
    );

    final docRef = await _guidesRef.add(guide.toFirestore());
    return docRef.id;
  }

  /// 가이드 조회
  Future<GameGuide?> getGuide(String guideId) async {
    final doc = await _guidesRef.doc(guideId).get();
    if (doc.exists) {
      return GameGuide.fromFirestore(doc);
    }
    return null;
  }

  /// 모임별 가이드 조회
  Future<GameGuide?> getGuideByMeeting(String meetingId) async {
    final snapshot = await _guidesRef
        .where('meetingId', isEqualTo: meetingId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return GameGuide.fromFirestore(snapshot.docs.first);
  }

  /// 가이드 스트림 (실시간)
  Stream<GameGuide?> getGuideStream(String meetingId) {
    return _guidesRef
        .where('meetingId', isEqualTo: meetingId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return GameGuide.fromFirestore(snapshot.docs.first);
    });
  }

  // ============== 가이드 수정 ==============

  /// 로컬 룰 업데이트
  Future<void> updateLocalRules(
    String guideId,
    String hostId,
    List<String> localRules,
  ) async {
    final guide = await getGuide(guideId);
    if (guide != null && guide.hostId == hostId) {
      await _guidesRef.doc(guideId).update({
        'localRules': localRules,
        'updatedAt': Timestamp.now(),
      });
    }
  }

  /// 로컬 룰 추가
  Future<void> addLocalRule(String guideId, String hostId, String rule) async {
    final guide = await getGuide(guideId);
    if (guide != null && guide.hostId == hostId) {
      await _guidesRef.doc(guideId).update({
        'localRules': FieldValue.arrayUnion([rule]),
        'updatedAt': Timestamp.now(),
      });
    }
  }

  /// 로컬 룰 삭제
  Future<void> removeLocalRule(String guideId, String hostId, String rule) async {
    final guide = await getGuide(guideId);
    if (guide != null && guide.hostId == hostId) {
      await _guidesRef.doc(guideId).update({
        'localRules': FieldValue.arrayRemove([rule]),
        'updatedAt': Timestamp.now(),
      });
    }
  }

  /// 특별 주의사항 업데이트
  Future<void> updateSpecialNote(
    String guideId,
    String hostId,
    String? specialNote,
  ) async {
    final guide = await getGuide(guideId);
    if (guide != null && guide.hostId == hostId) {
      await _guidesRef.doc(guideId).update({
        'specialNote': specialNote,
        'updatedAt': Timestamp.now(),
      });
    }
  }

  /// 준비물 업데이트
  Future<void> updateRequirements(
    String guideId,
    String hostId,
    List<String> requirements,
  ) async {
    final guide = await getGuide(guideId);
    if (guide != null && guide.hostId == hostId) {
      await _guidesRef.doc(guideId).update({
        'requirements': requirements,
        'updatedAt': Timestamp.now(),
      });
    }
  }

  /// 안전 수칙 업데이트
  Future<void> updateSafetyRules(
    String guideId,
    String hostId,
    List<String> safetyRules,
  ) async {
    final guide = await getGuide(guideId);
    if (guide != null && guide.hostId == hostId) {
      await _guidesRef.doc(guideId).update({
        'safetyRules': safetyRules,
        'updatedAt': Timestamp.now(),
      });
    }
  }

  // ============== 포맷팅 ==============

  /// 전체 가이드 텍스트 생성 (공유용)
  String formatGuideText(GameGuide guide) {
    final buffer = StringBuffer();

    // 게임 설명
    buffer.writeln('📖 게임 설명');
    buffer.writeln('─' * 20);
    buffer.writeln(GameGuide.getDefaultDescription(guide.gameType));
    buffer.writeln();

    // 로컬 룰
    if (guide.localRules.isNotEmpty) {
      buffer.writeln('🏠 로컬 룰');
      buffer.writeln('─' * 20);
      for (final rule in guide.localRules) {
        buffer.writeln('• $rule');
      }
      buffer.writeln();
    }

    // 특별 주의사항
    if (guide.specialNote != null && guide.specialNote!.isNotEmpty) {
      buffer.writeln('⚠️ 특별 주의사항');
      buffer.writeln('─' * 20);
      buffer.writeln(guide.specialNote);
      buffer.writeln();
    }

    // 준비물
    if (guide.requirements.isNotEmpty) {
      buffer.writeln('🎒 준비물');
      buffer.writeln('─' * 20);
      for (final item in guide.requirements) {
        buffer.writeln('• $item');
      }
      buffer.writeln();
    }

    // 진행 순서
    if (guide.phases.isNotEmpty) {
      buffer.writeln('📋 진행 순서');
      buffer.writeln('─' * 20);
      for (final phase in guide.phases) {
        buffer.writeln('${phase.order}. ${phase.title}');
        buffer.writeln('   ${phase.description}');
      }
      buffer.writeln();
    }

    // 안전 수칙
    if (guide.safetyRules.isNotEmpty) {
      buffer.writeln('🛡️ 안전 수칙');
      buffer.writeln('─' * 20);
      for (final rule in guide.safetyRules) {
        buffer.writeln('• $rule');
      }
    }

    return buffer.toString();
  }

  /// 간단한 가이드 요약 (퀵뷰용)
  String formatGuideSummary(GameGuide guide) {
    final buffer = StringBuffer();

    buffer.writeln(_getGameTypeName(guide.gameType));

    if (guide.localRules.isNotEmpty) {
      buffer.writeln('\n🏠 로컬 룰 ${guide.localRules.length}개');
    }

    if (guide.requirements.isNotEmpty) {
      buffer.writeln('🎒 준비물: ${guide.requirements.take(3).join(', ')}');
    }

    return buffer.toString();
  }

  String _getGameTypeName(GameType gameType) {
    switch (gameType) {
      case GameType.copsAndRobbers:
        return '👮 경찰과 도둑';
      case GameType.freezeTag:
        return '❄️ 얼음땡';
      case GameType.hideAndSeek:
        return '👀 숨바꼭질';
      case GameType.captureFlag:
        return '🚩 깃발뺏기';
      case GameType.custom:
        return '🎮 커스텀 게임';
    }
  }

  // ============== 프리셋 연동 ==============

  /// 프리셋의 룰을 가이드에 적용
  Future<void> applyPresetRules(
    String guideId,
    String hostId,
    Map<String, dynamic> presetRules,
  ) async {
    final guide = await getGuide(guideId);
    if (guide == null || guide.hostId != hostId) return;

    // 프리셋 룰을 로컬 룰 텍스트로 변환
    final localRules = _convertPresetRulesToText(guide.gameType, presetRules);

    await updateLocalRules(guideId, hostId, localRules);
  }

  List<String> _convertPresetRulesToText(
    GameType gameType,
    Map<String, dynamic> rules,
  ) {
    final result = <String>[];

    switch (gameType) {
      case GameType.copsAndRobbers:
        if (rules['roundTimeMinutes'] != null) {
          result.add('라운드 시간: ${rules['roundTimeMinutes']}분');
        }
        if (rules['jailLocation'] != null) {
          result.add('감옥 위치: ${rules['jailLocation']}');
        }
        if (rules['allowJailbreak'] == false) {
          result.add('탈옥 불가');
        }
        break;

      case GameType.freezeTag:
        if (rules['seekerCount'] != null) {
          result.add('술래 수: ${rules['seekerCount']}명');
        }
        if (rules['unfreezeSeconds'] != null) {
          result.add('해동 시간: ${rules['unfreezeSeconds']}초');
        }
        break;

      case GameType.hideAndSeek:
        if (rules['hideTimeSeconds'] != null) {
          result.add('숨는 시간: ${rules['hideTimeSeconds']}초');
        }
        if (rules['seekerCanRun'] == false) {
          result.add('술래는 뛸 수 없음');
        }
        break;

      case GameType.captureFlag:
        if (rules['flagCount'] != null) {
          result.add('깃발 수: ${rules['flagCount']}개');
        }
        if (rules['useGpsArea'] == true) {
          result.add('GPS 영역 사용');
        }
        break;

      default:
        break;
    }

    return result;
  }
}
