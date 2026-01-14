import 'package:flutter/material.dart';
import '../services/location_verification_service.dart';
import '../services/geolocation_service.dart';

/// 체크인 버튼 위젯
class CheckInButton extends StatefulWidget {
  final String meetingId;
  final String odId;
  final double meetingLat;
  final double meetingLon;
  final DateTime meetingTime;
  final VoidCallback? onCheckInSuccess;

  const CheckInButton({
    super.key,
    required this.meetingId,
    required this.odId,
    required this.meetingLat,
    required this.meetingLon,
    required this.meetingTime,
    this.onCheckInSuccess,
  });

  @override
  State<CheckInButton> createState() => _CheckInButtonState();
}

class _CheckInButtonState extends State<CheckInButton> {
  final LocationVerificationService _locationService = LocationVerificationService();
  final GeolocationService _geoService = GeolocationService();
  bool _isLoading = false;
  bool _isCheckedIn = false;

  @override
  void initState() {
    super.initState();
    _checkExistingCheckIn();
  }

  Future<void> _checkExistingCheckIn() async {
    final hasCheckedIn = await _locationService.hasCheckedIn(
      widget.meetingId,
      widget.odId,
    );
    if (mounted) {
      setState(() => _isCheckedIn = hasCheckedIn);
    }
  }

  Future<void> _performCheckIn() async {
    setState(() {
      _isLoading = true;
    });

    // 실제 위치 정보 가져오기
    final position = await _geoService.getCurrentPosition();

    if (position == null) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showCheckInFailedDialog(CheckInResult.locationDisabled());
      }
      return;
    }

    final userLat = position.latitude;
    final userLon = position.longitude;

    final result = _locationService.canCheckIn(
      userLat: userLat,
      userLon: userLon,
      meetingLat: widget.meetingLat,
      meetingLon: widget.meetingLon,
      meetingTime: widget.meetingTime,
    );

    if (result.isSuccess) {
      final success = await _locationService.checkIn(
        meetingId: widget.meetingId,
        odId: widget.odId,
        latitude: userLat,
        longitude: userLon,
      );

      if (success) {
        setState(() => _isCheckedIn = true);
        widget.onCheckInSuccess?.call();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } else {
      if (mounted) {
        _showCheckInFailedDialog(result);
      }
    }

    setState(() => _isLoading = false);
  }

  void _showCheckInFailedDialog(CheckInResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              _getStatusIcon(result.status),
              color: _getStatusColor(result.status),
            ),
            const SizedBox(width: 8),
            const Text('체크인 실패'),
          ],
        ),
        content: Text(result.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(CheckInStatus status) {
    switch (status) {
      case CheckInStatus.tooFar:
        return Icons.location_off;
      case CheckInStatus.tooEarly:
        return Icons.schedule;
      case CheckInStatus.tooLate:
        return Icons.timer_off;
      case CheckInStatus.locationDisabled:
        return Icons.gps_off;
      default:
        return Icons.error_outline;
    }
  }

  Color _getStatusColor(CheckInStatus status) {
    switch (status) {
      case CheckInStatus.success:
        return Colors.green;
      case CheckInStatus.tooFar:
        return Colors.orange;
      case CheckInStatus.tooEarly:
        return Colors.blue;
      case CheckInStatus.tooLate:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckedIn) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.green.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withAlpha(100)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            const Text(
              '체크인 완료',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _performCheckIn,
      icon: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.location_on),
      label: Text(_isLoading ? '확인 중...' : '체크인'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

/// 체크인 현황 카드
class CheckInStatusCard extends StatelessWidget {
  final String meetingId;
  final int totalParticipants;

  const CheckInStatusCard({
    super.key,
    required this.meetingId,
    required this.totalParticipants,
  });

  @override
  Widget build(BuildContext context) {
    final locationService = LocationVerificationService();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.how_to_reg, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  '체크인 현황',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<CheckInInfo>>(
              stream: locationService.getCheckInStream(meetingId),
              builder: (context, snapshot) {
                final checkIns = snapshot.data ?? [];
                final checkedInCount = checkIns.length;
                final percentage = totalParticipants > 0
                    ? checkedInCount / totalParticipants
                    : 0.0;

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$checkedInCount / $totalParticipants명',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${(percentage * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        percentage >= 1.0
                            ? Colors.green
                            : percentage >= 0.5
                                ? Colors.orange
                                : Colors.red,
                      ),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 12),
                    if (checkedInCount < totalParticipants)
                      Text(
                        '${totalParticipants - checkedInCount}명이 아직 체크인하지 않았습니다',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      )
                    else
                      const Text(
                        '모두 체크인 완료! 게임을 시작할 수 있습니다',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 체크인 안내 배너
class CheckInBanner extends StatelessWidget {
  final DateTime meetingTime;
  final bool isCheckedIn;
  final VoidCallback onCheckIn;

  const CheckInBanner({
    super.key,
    required this.meetingTime,
    required this.isCheckedIn,
    required this.onCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final windowStart = meetingTime.subtract(
      LocationVerificationService.checkInWindowBefore,
    );
    final windowEnd = meetingTime.add(
      LocationVerificationService.checkInWindowAfter,
    );

    final isCheckInTime = now.isAfter(windowStart) && now.isBefore(windowEnd);

    if (isCheckedIn) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '체크인 완료! 게임 시작을 기다려주세요.',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        ),
      );
    }

    if (!isCheckInTime && now.isBefore(windowStart)) {
      final remaining = windowStart.difference(now);
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '체크인은 ${_formatDuration(remaining)} 후부터 가능합니다',
                style: const TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      );
    }

    if (isCheckInTime) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: Colors.orange),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '모임 장소에 도착하면 체크인해주세요!',
                style: TextStyle(color: Colors.orange),
              ),
            ),
            TextButton(
              onPressed: onCheckIn,
              child: const Text('체크인'),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}시간 ${d.inMinutes % 60}분';
    }
    return '${d.inMinutes}분';
  }
}
