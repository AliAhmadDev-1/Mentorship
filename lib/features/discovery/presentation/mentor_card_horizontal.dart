import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/mentor.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/price_badge.dart';
import '../../../shared/widgets/star_rating.dart';

class MentorCardHorizontal extends StatelessWidget {
  const MentorCardHorizontal({super.key, required this.mentor});

  final Mentor mentor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return SizedBox(
      width: 276,
      child: GlassCard(
        onTap: () => context.push('/mentor/${mentor.id}'),
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 88,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Color.alphaBlend(
                  Color(mentor.avatarColorValue).withValues(alpha: .12),
                  isDark ? AppColors.surface : AppColors.lightSurface,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  AppAvatar(
                    initials: mentor.avatarInitials,
                    colorValue: mentor.avatarColorValue,
                    verified: mentor.verified,
                    size: 56,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mentor.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mentor.company,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mentor.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 30,
                      child: Row(
                        children: [
                          for (final skill in mentor.expertise.take(3)) ...[
                            Flexible(child: _SkillChip(label: skill)),
                            if (skill != mentor.expertise.take(3).last)
                              const SizedBox(width: 6),
                          ],
                        ],
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        StarRating(rating: mentor.rating, size: 14),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            '${mentor.ratingLabel} (${mentor.reviewCount})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        PriceBadge(price: mentor.ratePerSlot, compact: true),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9),
      alignment: Alignment.center,
      constraints: const BoxConstraints(maxWidth: 86),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceHigh : AppColors.lightSurfaceHigh,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? AppColors.border : AppColors.lightBorder,
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: isDark
              ? AppColors.textSecondary
              : AppColors.lightTextSecondary,
        ),
      ),
    );
  }
}
