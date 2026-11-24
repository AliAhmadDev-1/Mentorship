import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/api_models.dart';
import '../../../core/providers/api_provider.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../shared/widgets/error_state_widget.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/star_rating.dart';

class ReviewsScreen extends ConsumerStatefulWidget {
  const ReviewsScreen({super.key, this.mentorId, this.canManage = false});

  final String? mentorId;
  final bool canManage;

  @override
  ConsumerState<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends ConsumerState<ReviewsScreen> {
  late Future<List<ReviewMutationResponse>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _reviewsFuture = _load();
  }

  Future<List<ReviewMutationResponse>> _load() async {
    final response = await ref
        .read(microMentorApiProvider)
        .listReviews(mentorId: widget.mentorId);
    if (!response.success) throw response.error!;
    return response.data?.results ?? const [];
  }

  void _refresh() => setState(() => _reviewsFuture = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.canManage ? 'My reviews' : 'Reviews')),
      body: FutureBuilder<List<ReviewMutationResponse>>(
        future: _reviewsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorStateWidget(
              title: 'Could not load reviews',
              message: '${snapshot.error}',
              onRetry: _refresh,
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final reviews = snapshot.data!;
          if (reviews.isEmpty) {
            return const AppEmptyState(
              icon: Icons.rate_review_outlined,
              title: 'No reviews yet',
              message: 'Completed session reviews will appear here.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              itemCount: reviews.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final review = reviews[index];
                return GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  review.reviewer ?? 'MicroMentor user',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                if (review.createdAt != null)
                                  Text(
                                    DateFormat.yMMMd().format(
                                      review.createdAt!,
                                    ),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                              ],
                            ),
                          ),
                          if (widget.canManage)
                            PopupMenuButton<_ReviewAction>(
                              tooltip: 'Review actions',
                              onSelected: (action) =>
                                  action == _ReviewAction.edit
                                  ? _edit(review)
                                  : _delete(review),
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: _ReviewAction.edit,
                                  child: ListTile(
                                    leading: Icon(Icons.edit_outlined),
                                    title: Text('Edit'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                PopupMenuItem(
                                  value: _ReviewAction.delete,
                                  child: ListTile(
                                    leading: Icon(Icons.delete_outline),
                                    title: Text('Delete'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      StarRating(rating: review.rating.toDouble()),
                      if (review.body?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 8),
                        Text(review.body!.trim()),
                      ],
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _edit(ReviewMutationResponse review) async {
    var rating = review.rating.clamp(1, 5);
    final body = TextEditingController(text: review.body ?? '');
    final result = await showModalBottomSheet<_ReviewDraft>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit review',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var star = 1; star <= 5; star++)
                      IconButton(
                        tooltip: '$star stars',
                        onPressed: () => setSheetState(() => rating = star),
                        icon: Icon(
                          star <= rating ? Icons.star : Icons.star_border,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                  ],
                ),
                TextField(
                  controller: body,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Review'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(
                      sheetContext,
                      _ReviewDraft(rating: rating, body: body.text.trim()),
                    ),
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    body.dispose();
    if (result == null || !mounted) return;
    final response = await ref.read(microMentorApiProvider).updateReview(
      review.reviewId,
      {'rating': result.rating, 'body': result.body},
    );
    if (!mounted) return;
    if (!response.success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.error!.message)));
      return;
    }
    _refresh();
  }

  Future<void> _delete(ReviewMutationResponse review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete review?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final response = await ref
        .read(microMentorApiProvider)
        .deleteReview(review.reviewId);
    if (!mounted) return;
    if (!response.success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.error!.message)));
      return;
    }
    _refresh();
  }
}

enum _ReviewAction { edit, delete }

class _ReviewDraft {
  const _ReviewDraft({required this.rating, required this.body});

  final int rating;
  final String body;
}
