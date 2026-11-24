import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/mentor.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/price_badge.dart';
import '../../../shared/widgets/star_rating.dart';

class MentorCardVertical extends StatelessWidget {
  const MentorCardVertical({super.key, required this.mentor, this.index = 0});

  final Mentor mentor;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GlassCard(
      onTap: () => context.push('/mentor/${mentor.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppAvatar(
            initials: mentor.avatarInitials,
            colorValue: mentor.avatarColorValue,
            verified: mentor.verified,
            size: 58,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mentor.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  '${mentor.title} · ${mentor.company}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: mentor.expertise
                      .take(3)
                      .map(
                        (skill) => Chip(
                          label: Text(skill),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: isDark
                              ? AppColors.surfaceHigh
                              : AppColors.lightSurfaceHigh,
                          side: BorderSide(
                            color: isDark
                                ? AppColors.border
                                : AppColors.lightBorder,
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    StarRating(rating: mentor.rating),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${mentor.ratingLabel} (${mentor.reviewCount})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    PriceBadge(price: mentor.ratePerSlot),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
