import 'package:flutter/material.dart';
import 'package:meeteor/main.dart';

/// A shimmer animation widget that produces a sweeping highlight effect.
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _controller.value, 0),
              end: Alignment(-0.5 + 2.0 * _controller.value, 0),
              colors: [
                AppColors.spaceIndigo.withValues(alpha: 0.6),
                AppColors.vintageLavender.withValues(alpha: 0.25),
                AppColors.spaceIndigo.withValues(alpha: 0.6),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton placeholder for a post card in the home feed.
class PostCardSkeleton extends StatelessWidget {
  const PostCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.spaceIndigo.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User row skeleton
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const ShimmerBox(width: 36, height: 36, borderRadius: 18),
                const SizedBox(width: 10),
                ShimmerBox(
                  width: 100,
                  height: 14,
                  borderRadius: 7,
                ),
              ],
            ),
          ),
          // Image skeleton
          const ShimmerBox(
            width: double.infinity,
            height: 220,
            borderRadius: 0,
          ),
          // Action bar skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: const [
                ShimmerBox(width: 36, height: 36, borderRadius: 10),
                SizedBox(width: 8),
                ShimmerBox(width: 36, height: 36, borderRadius: 10),
                SizedBox(width: 8),
                ShimmerBox(width: 36, height: 36, borderRadius: 10),
              ],
            ),
          ),
          // Caption skeleton
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(width: double.infinity, height: 12, borderRadius: 6),
                SizedBox(height: 6),
                ShimmerBox(width: 180, height: 12, borderRadius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton placeholder for the explore grid.
class ExploreGridSkeleton extends StatelessWidget {
  final int itemCount;

  const ExploreGridSkeleton({super.key, this.itemCount = 15});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 88),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return const ShimmerBox(width: double.infinity, height: double.infinity, borderRadius: 2);
      },
    );
  }
}

/// Skeleton placeholder for the profile page.
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Profile header skeleton
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 24, 16),
          child: Row(
            children: [
              const ShimmerBox(width: 92, height: 92, borderRadius: 46),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerBox(width: 140, height: 22, borderRadius: 8),
                    SizedBox(height: 10),
                    ShimmerBox(width: 200, height: 14, borderRadius: 6),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Tab bar skeleton
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              ShimmerBox(width: 28, height: 28, borderRadius: 6),
              ShimmerBox(width: 28, height: 28, borderRadius: 6),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Grid skeleton
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 88),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              return const ShimmerBox(
                width: double.infinity,
                height: double.infinity,
                borderRadius: 8,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Skeleton for the challenges page.
class ChallengeSkeleton extends StatelessWidget {
  const ChallengeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Header skeleton
          const ShimmerBox(width: 200, height: 28, borderRadius: 8),
          const SizedBox(height: 10),
          const ShimmerBox(width: double.infinity, height: 14, borderRadius: 6),
          const SizedBox(height: 22),
          // Trophy collection skeleton
          ShimmerBox(
            width: double.infinity,
            height: 130,
            borderRadius: 22,
          ),
          const SizedBox(height: 22),
          // Today section skeleton
          const ShimmerBox(width: 160, height: 20, borderRadius: 8),
          const SizedBox(height: 12),
          ShimmerBox(
            width: double.infinity,
            height: 200,
            borderRadius: 16,
          ),
          const SizedBox(height: 22),
          // Past section skeleton
          const ShimmerBox(width: 140, height: 20, borderRadius: 8),
          const SizedBox(height: 12),
          ShimmerBox(
            width: double.infinity,
            height: 100,
            borderRadius: 16,
          ),
          const SizedBox(height: 12),
          ShimmerBox(
            width: double.infinity,
            height: 100,
            borderRadius: 16,
          ),
        ],
      ),
    );
  }
}
