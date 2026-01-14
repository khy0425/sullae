import 'dart:async';
import 'package:flutter/material.dart';
import '../models/quick_message_model.dart';
import '../services/quick_message_service.dart';

/// 퀵메시지 상태 관리 Provider
///
/// 역할:
/// - 메시지 전송 상태 관리
/// - 쿨타임 관리 (커스텀 공지)
/// - 메시지 스트림 제공
///
/// MeetingProvider와 분리하여 책임 명확화
class QuickMessageProvider with ChangeNotifier {
  final QuickMessageService _service = QuickMessageService();

  // 전송 상태
  bool _isSending = false;
  String? _error;

  // 쿨타임 관리
  Timer? _cooldownTimer;
  int _cooldownRemaining = 0;

  // 메시지 스트림
  Stream<List<QuickMessage>>? _messagesStream;
  String? _currentMeetingId;

  // Getters
  bool get isSending => _isSending;
  String? get error => _error;
  int get cooldownRemaining => _cooldownRemaining;
  bool get canSendAnnouncement => _cooldownRemaining == 0;
  Stream<List<QuickMessage>>? get messagesStream => _messagesStream;

  /// 모임 연결
  void connect(String meetingId) {
    if (_currentMeetingId == meetingId) return;

    _currentMeetingId = meetingId;
    _messagesStream = _service.getRecentMessages(meetingId, limit: 50);
    notifyListeners();
  }

  /// 퀵메시지 전송
  Future<bool> sendMessage({
    required String meetingId,
    required String senderId,
    required String senderNickname,
    required QuickMessageType type,
  }) async {
    if (_isSending) return false;

    _isSending = true;
    _error = null;
    notifyListeners();

    try {
      await _service.sendMessage(
        meetingId: meetingId,
        senderId: senderId,
        senderNickname: senderNickname,
        type: type,
      );
      _isSending = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = '메시지 전송 실패';
      _isSending = false;
      notifyListeners();
      return false;
    }
  }

  /// 커스텀 공지 전송 (방장 전용)
  Future<bool> sendCustomAnnouncement({
    required String meetingId,
    required String hostId,
    required String hostNickname,
    required String text,
  }) async {
    if (_isSending || !canSendAnnouncement) return false;

    _isSending = true;
    _error = null;
    notifyListeners();

    try {
      final errorMessage = await _service.sendCustomAnnouncement(
        meetingId: meetingId,
        hostId: hostId,
        hostNickname: hostNickname,
        text: text,
      );

      if (errorMessage != null) {
        _error = errorMessage;
        _isSending = false;
        notifyListeners();
        return false;
      }

      // 쿨타임 시작
      _startCooldown();
      _isSending = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = '공지 전송 실패';
      _isSending = false;
      notifyListeners();
      return false;
    }
  }

  /// 쿨타임 시작 (1분)
  void _startCooldown() {
    _cooldownRemaining = QuickMessage.cooldownDuration.inSeconds;

    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownRemaining > 0) {
        _cooldownRemaining--;
        notifyListeners();
      } else {
        timer.cancel();
      }
    });
  }

  /// 에러 초기화
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// 리소스 정리
  void disconnect() {
    _cooldownTimer?.cancel();
    _messagesStream = null;
    _currentMeetingId = null;
    _cooldownRemaining = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }
}
