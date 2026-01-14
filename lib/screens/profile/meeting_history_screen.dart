import 'package:flutter/material.dart';
import '../../services/meeting_history_service.dart';
import '../../widgets/stats_widget.dart';

/// 모임 히스토리 화면
class MeetingHistoryScreen extends StatefulWidget {
  final String odId;

  const MeetingHistoryScreen({super.key, required this.odId});

  @override
  State<MeetingHistoryScreen> createState() => _MeetingHistoryScreenState();
}

class _MeetingHistoryScreenState extends State<MeetingHistoryScreen> {
  final MeetingHistoryService _historyService = MeetingHistoryService();

  UserMeetingStats? _stats;
  List<MeetingHistoryItem> _meetings = [];
  List<FrequentFriend> _friends = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final stats = await _historyService.getUserStats(widget.odId);
    final meetings = await _historyService.getRecentMeetings(userId: widget.odId);
    final friends = await _historyService.getFrequentFriends(userId: widget.odId);

    if (mounted) {
      setState(() {
        _stats = stats;
        _meetings = meetings;
        _friends = friends;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('활동 기록'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 통계 카드
                    if (_stats != null)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: UserStatsCard(stats: _stats!),
                      ),

                    // 자주 함께한 친구
                    if (_friends.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: FrequentFriendsWidget(friends: _friends),
                      ),

                    // 최근 모임
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.history, color: Colors.grey[700]),
                          const SizedBox(width: 8),
                          const Text(
                            '최근 모임',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_meetings.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                '아직 참여한 모임이 없어요',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      MeetingHistoryList(meetings: _meetings),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
