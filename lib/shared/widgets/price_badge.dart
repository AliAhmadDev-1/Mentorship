import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class PriceBadge extends StatelessWidget {
  const PriceBadge({
    super.key,
    required this.price,
    this.suffix = '/15m',
    this.compact = false,
  });

  final double price;
  final String suffix;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '\$${price.toStringAsFixed(0)}$suffix',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppColors.gold,
          fontWeight: FontWeight.w900,
          fontSize: compact ? 12 : null,
        ),
      ),
    );
  }
}
