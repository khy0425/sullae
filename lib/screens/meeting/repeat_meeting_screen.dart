import 'package:flutter/material.dart';
import '../../services/repeat_meeting_service.dart';

/// 반복 모임 설정 화면
class RepeatMeetingScreen extends StatefulWidget {
  final String hostId;

  const RepeatMeetingScreen({super.key, required this.hostId});

  @override
  State<RepeatMeetingScreen> createState() => _RepeatMeetingScreenState();
}

class _RepeatMeetingScreenState extends State<RepeatMeetingScreen> {
  final RepeatMeetingService _repeatService = RepeatMeetingService();

  List<RepeatTemplate> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);

    final templates = await _repeatService.getMyTemplates(widget.hostId);

    if (mounted) {
      setState(() {
        _templates = templates;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('정기 모임'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _templates.isEmpty
              ? _buildEmptyState()
              : _buildTemplateList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(),
        backgroundColor: const Color(0xFFFF6B35),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('정기 모임 만들기', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.repeat, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '정기 모임이 없어요',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            '매주 같은 시간에 모임을 열어보세요!',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateList() {
    return RefreshIndicator(
      onRefresh: _loadTemplates,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _templates.length,
        itemBuilder: (context, index) {
          final template = _templates[index];
          return _TemplateCard(
            template: template,
            onCreateMeeting: () => _createMeetingFromTemplate(template),
            onDelete: () => _deleteTemplate(template),
          );
        },
      ),
    );
  }

  Future<void> _createMeetingFromTemplate(RepeatTemplate template) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('모임 생성'),
        content: Text('${template.title} 모임을 생성할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('생성'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final meetingId = await _repeatService.createMeetingFromTemplate(template.id);
      if (mounted) {
        if (meetingId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('모임이 생성되었습니다'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('모임 생성에 실패했습니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteTemplate(RepeatTemplate template) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('정기 모임 삭제'),
        content: const Text('이 정기 모임을 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _repeatService.deactivateTemplate(template.id);
      _loadTemplates();
    }
  }

  void _showCreateDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CreateTemplateSheet(
        hostId: widget.hostId,
        onCreated: _loadTemplates,
      ),
    );
  }
}

/// 템플릿 카드
class _TemplateCard extends StatelessWidget {
  final RepeatTemplate template;
  final VoidCallback onCreateMeeting;
  final VoidCallback onDelete;

  const _TemplateCard({
    required this.template,
    required this.onCreateMeeting,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getGameColor(template.gameType).withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getGameIcon(template.gameType),
                    color: _getGameColor(template.gameType),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        template.pattern.displayName,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('삭제', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  '${template.meetingTime.hour.toString().padLeft(2, '0')}:${template.meetingTime.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.people, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  '최대 ${template.maxParticipants}명',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
            if (template.locationName != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      template.locationName!,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event, size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 4),
                        Text(
                          '다음: ${_formatDate(template.nextMeetingDate)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: onCreateMeeting,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('모임 열기'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getGameIcon(String gameType) {
    switch (gameType) {
      case 'policeAndThief':
        return Icons.local_police;
      case 'freeze':
        return Icons.ac_unit;
      case 'hideAndSeek':
        return Icons.visibility_off;
      default:
        return Icons.sports_esports;
    }
  }

  Color _getGameColor(String gameType) {
    switch (gameType) {
      case 'policeAndThief':
        return Colors.blue;
      case 'freeze':
        return Colors.cyan;
      case 'hideAndSeek':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day} (${_weekdayName(date.weekday)})';
  }

  String _weekdayName(int weekday) {
    const names = ['', '월', '화', '수', '목', '금', '토', '일'];
    return names[weekday];
  }
}

/// 템플릿 생성 시트
class _CreateTemplateSheet extends StatefulWidget {
  final String hostId;
  final VoidCallback onCreated;

  const _CreateTemplateSheet({
    required this.hostId,
    required this.onCreated,
  });

  @override
  State<_CreateTemplateSheet> createState() => _CreateTemplateSheetState();
}

class _CreateTemplateSheetState extends State<_CreateTemplateSheet> {
  final RepeatMeetingService _repeatService = RepeatMeetingService();
  final TextEditingController _titleController = TextEditingController();

  String _gameType = 'policeAndThief';
  RepeatType _repeatType = RepeatType.weekly;
  int _selectedWeekday = 6; // 토요일
  TimeOfDay _meetingTime = const TimeOfDay(hour: 14, minute: 0);
  int _maxParticipants = 8;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모임 이름을 입력해주세요')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final pattern = RepeatPattern(
      type: _repeatType,
      weekdays: [_selectedWeekday],
    );

    final templateId = await _repeatService.createRepeatTemplate(
      hostId: widget.hostId,
      title: _titleController.text.trim(),
      gameType: _gameType,
      maxParticipants: _maxParticipants,
      pattern: pattern,
      meetingTime: MeetingTime(hour: _meetingTime.hour, minute: _meetingTime.minute),
      durationMinutes: 60,
    );

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (templateId != null) {
        Navigator.pop(context);
        widget.onCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('정기 모임이 생성되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('생성에 실패했습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '정기 모임 만들기',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // 모임 이름
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: '모임 이름',
                hintText: '예: 토요일 경찰과 도둑',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 게임 타입
            const Text('게임', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildGameChip('policeAndThief', '경찰과 도둑'),
                _buildGameChip('freeze', '얼음땡'),
                _buildGameChip('hideAndSeek', '숨바꼭질'),
              ],
            ),
            const SizedBox(height: 16),

            // 반복 주기
            const Text('반복 주기', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildRepeatChip(RepeatType.weekly, '매주'),
                _buildRepeatChip(RepeatType.biweekly, '격주'),
              ],
            ),
            const SizedBox(height: 16),

            // 요일 선택
            const Text('요일', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(7, (index) {
                final weekday = index + 1;
                const names = ['', '월', '화', '수', '목', '금', '토', '일'];
                return ChoiceChip(
                  label: Text(names[weekday]),
                  selected: _selectedWeekday == weekday,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedWeekday = weekday);
                  },
                );
              }),
            ),
            const SizedBox(height: 16),

            // 시간
            Row(
              children: [
                const Text('시간', style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _meetingTime,
                    );
                    if (time != null) {
                      setState(() => _meetingTime = time);
                    }
                  },
                  child: Text(
                    '${_meetingTime.hour.toString().padLeft(2, '0')}:${_meetingTime.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 인원
            Row(
              children: [
                const Text('최대 인원', style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  onPressed: _maxParticipants > 4
                      ? () => setState(() => _maxParticipants--)
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                Text('$_maxParticipants명', style: const TextStyle(fontSize: 16)),
                IconButton(
                  onPressed: _maxParticipants < 20
                      ? () => setState(() => _maxParticipants++)
                      : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 생성 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('생성하기', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameChip(String type, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _gameType == type,
      onSelected: (selected) {
        if (selected) setState(() => _gameType = type);
      },
    );
  }

  Widget _buildRepeatChip(RepeatType type, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _repeatType == type,
      onSelected: (selected) {
        if (selected) setState(() => _repeatType = type);
      },
    );
  }
}
