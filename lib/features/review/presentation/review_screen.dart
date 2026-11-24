import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/api_provider.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../home/providers/home_provider.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  int _rating = 5;
  final _review = TextEditingController();
  final _tags = <String>{};
  bool _submitting = false;

  @override
  void dispose() {
    _review.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingFuture = ref
        .read(bookingRepositoryProvider)
        .getBookingById(widget.bookingId);
    final labels = {
      5: 'Excellent',
      4: 'Very Good',
      3: 'Good',
      2: 'Fair',
      1: 'Poor',
    };
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: .32),
                  ),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.gold,
                  size: 36,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Session Complete!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              FutureBuilder(
                future: bookingFuture,
                builder: (context, snapshot) => Text(
                  snapshot.data?.mentor.name ?? 'Mentor',
                  style: const TextStyle(color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      onPressed: () => setState(() => _rating = i),
                      icon: Icon(
                        i <= _rating ? Icons.star : Icons.star_border,
                        size: 40,
                        color: AppColors.gold,
                      ),
                    ),
                ],
              ),
              Text('${labels[_rating]} ($_rating/5)'),
              const SizedBox(height: 16),
              AppTextField(
                controller: _review,
                hint: 'Share your review',
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children:
                    [
                          'Helpful',
                          'Clear',
                          'Knowledgeable',
                          'Friendly',
                          'Would rebook',
                        ]
                        .map(
                          (tag) => FilterChip(
                            label: Text(tag),
                            selected: _tags.contains(tag),
                            onSelected: (value) => setState(
                              () => value ? _tags.add(tag) : _tags.remove(tag),
                            ),
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Submit Review',
                isLoading: _submitting,
                onPressed: _submitting ? null : _submitReview,
              ),
              TextButton(
                onPressed: () => context.go('/home'),
                child: const Text('Skip for now'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitReview() async {
    setState(() => _submitting = true);
    final api = ref.read(microMentorApiProvider);
    final complete = await api.completeSession(widget.bookingId);
    if (!complete.success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(complete.error!.message)));
    }
    final response = await api.submitSessionReview(
      sessionId: widget.bookingId,
      rating: _rating,
      body: _review.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (!response.success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.error!.message)));
      return;
    }
    context.go('/home');
  }
}
