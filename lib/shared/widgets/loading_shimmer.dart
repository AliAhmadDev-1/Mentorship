import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants/app_colors.dart';
import 'glass_card.dart';

class LoadingShimmer extends StatelessWidget {
  const LoadingShimmer({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surface,
      highlightColor: theme.brightness == Brightness.dark
          ? AppColors.surfaceHigh
          : AppColors.lightSurfaceHigh,
      child: Column(
        children: [
          for (var i = 0; i < count; i++)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: GlassCard(
                child: SizedBox(height: 74, width: double.infinity),
              ),
            ),
        ],
      ),
    );
  }
}
