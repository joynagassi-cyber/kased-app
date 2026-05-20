import 'package:flutter/material.dart';
import '../../core/theme/motion_tokens.dart';

class SkeletonLoading extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<SkeletonLoading> createState() => _SkeletonLoadingState();
}

class _SkeletonLoadingState extends State<SkeletonLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MotionDuration.long * 2, // Shimmer lent
    )..repeat();

    _animation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE0E0E0);
    final highlightColor = isDark ? const Color(0xFF334155) : const Color(0xFFF5F5F5);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                0.0,
                0.5 + (_animation.value / 4),
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }
}

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonLoading(width: 100, height: 14),
            SizedBox(height: 8),
            SkeletonLoading(width: 200, height: 48),
            SizedBox(height: 24),
            SkeletonLoading(width: 40, height: 4),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLoading(width: 80, height: 12),
                      SizedBox(height: 8),
                      SkeletonLoading(width: 60, height: 32),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLoading(width: 80, height: 12),
                      SizedBox(height: 8),
                      SkeletonLoading(width: 60, height: 32),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 48),
            SkeletonLoading(width: double.infinity, height: 48),
            SizedBox(height: 12),
            SkeletonLoading(width: double.infinity, height: 48),
          ],
        ),
      ),
    );
  }
}

class MembresListSkeleton extends StatelessWidget {
  const MembresListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: 6,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131A2A) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border(
                left: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  width: 6,
                ),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: const Row(
              children: [
                SkeletonLoading(
                  width: 48,
                  height: 48,
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLoading(width: 140, height: 16),
                      SizedBox(height: 6),
                      SkeletonLoading(width: 90, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CulteDetailSkeleton extends StatelessWidget {
  const CulteDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Premium top header card shimmered
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131A2A) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonLoading(width: 140, height: 16),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLoading(width: 60, height: 12),
                      SizedBox(height: 8),
                      SkeletonLoading(width: 100, height: 24),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SkeletonLoading(width: 60, height: 12),
                      SizedBox(height: 8),
                      SkeletonLoading(width: 60, height: 24),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16),
              SkeletonLoading(
                width: double.infinity,
                height: 8,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Bulk Actions buttons shimmer
        const Row(
          children: [
            Expanded(
              child: SkeletonLoading(
                width: double.infinity,
                height: 44,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Search bar shimmer
        const SkeletonLoading(
          width: double.infinity,
          height: 48,
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        const SizedBox(height: 16),
        // Filter Chips row shimmer
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Row(
            children: List.generate(4, (index) {
              return const Padding(
                padding: EdgeInsets.only(right: 8),
                child: SkeletonLoading(
                  width: 80,
                  height: 32,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),
        // List of cotisations shimmer
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: 5,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131A2A) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(12),
                child: const Row(
                  children: [
                    SkeletonLoading(
                      width: 40,
                      height: 40,
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonLoading(width: 120, height: 14),
                          SizedBox(height: 6),
                          SkeletonLoading(width: 80, height: 10),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    // Checkbox action shimmer
                    const SkeletonLoading(
                      width: 60,
                      height: 32,
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
