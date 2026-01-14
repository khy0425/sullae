import 'package:flutter/material.dart';
import '../../utils/app_dimens.dart';

/// Shimmer 효과가 적용된 로딩 위젯
///
/// 데이터 로딩 중 스켈레톤 UI를 표시
/// 사용 예시:
/// ```dart
/// isLoading ? ShimmerLoading.card() : ActualContent()
/// ```
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
  });

  /// 카드 형태 Shimmer
  static Widget card({
    double? width,
    double height = 120,
    BorderRadius? borderRadius,
  }) {
    return ShimmerLoading(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? AppDimens.cardBorderRadius,
        ),
      ),
    );
  }

  /// 모임 카드 Shimmer
  static Widget meetingCard({int count = 3}) {
    return Column(
      children: List.generate(count, (index) => Padding(
        padding: const EdgeInsets.only(bottom: AppDimens.paddingM),
        child: ShimmerLoading(
          child: Container(
            height: AppDimens.meetingCardHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppDimens.cardBorderRadius,
            ),
          ),
        ),
      )),
    );
  }

  /// 리스트 아이템 Shimmer
  static Widget listItem({int count = 3}) {
    return Column(
      children: List.generate(count, (index) => Padding(
        padding: const EdgeInsets.only(bottom: AppDimens.paddingS),
        child: ShimmerLoading(
          child: Container(
            height: AppDimens.listItemHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppDimens.cardBorderRadius,
            ),
          ),
        ),
      )),
    );
  }

  /// 텍스트 라인 Shimmer
  static Widget textLine({
    double width = double.infinity,
    double height = 16,
  }) {
    return ShimmerLoading(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusS),
        ),
      ),
    );
  }

  /// 원형 Shimmer (아바타, 아이콘)
  static Widget circle({double size = 48}) {
    return ShimmerLoading(
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  /// 프로필 카드 Shimmer
  static Widget profileCard() {
    return ShimmerLoading(
      child: Container(
        padding: AppDimens.cardPaddingAll,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppDimens.cardBorderRadius,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppDimens.paddingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(AppDimens.radiusS),
                    ),
                  ),
                  const SizedBox(height: AppDimens.paddingS),
                  Container(
                    height: 12,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(AppDimens.radiusS),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 채팅 메시지 Shimmer
  static Widget chatMessage({int count = 5}) {
    return Column(
      children: List.generate(count, (index) {
        final isMe = index % 2 == 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimens.paddingS),
          child: Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isMe) ...[
                ShimmerLoading(
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimens.paddingS),
              ],
              ShimmerLoading(
                child: Container(
                  width: 150 + (index * 20) % 100,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppDimens.chatBubbleBorderRadius,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  /// 팀 카드 Shimmer
  static Widget teamCard() {
    return Row(
      children: [
        Expanded(
          child: ShimmerLoading(
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppDimens.cardBorderRadius,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppDimens.paddingM),
        Expanded(
          child: ShimmerLoading(
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppDimens.cardBorderRadius,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = Colors.grey[300]!;
    final highlightColor = Colors.grey[100]!;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                0.0,
                0.5 + _animation.value * 0.25,
                1.0,
              ],
              transform: _SlidingGradientTransform(
                slidePercent: _animation.value,
              ),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}
