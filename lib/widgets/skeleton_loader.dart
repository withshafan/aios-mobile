import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/tokens.dart';

class SkeletonCard extends StatelessWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const SkeletonCard({
    super.key,
    this.height = 80,
    this.width,
    this.borderRadius = radiusMd,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceRaised,
      highlightColor: AppColors.surfaceOverlay,
      period: const Duration(milliseconds: 1400),
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

// Usage example: show skeleton list while loading
class SkeletonList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const SkeletonList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: space3),
      itemBuilder: (_, __) => SkeletonCard(height: itemHeight),
    );
  }
}
