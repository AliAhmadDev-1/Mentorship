import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/models/booking.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/error_state_widget.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../booking/providers/booking_provider.dart';
import '../providers/session_list_provider.dart';

class SessionsScreen extends ConsumerWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My sessions'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _SessionList(filter: SessionListFilter.upcoming),
            _SessionList(filter: SessionListFilter.completed),
          ],
        ),
      ),
    );
  }
}

class _SessionList extends ConsumerWidget {
  const _SessionList({required this.filter});

  final SessionListFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionListProvider(filter));
    return sessions.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(20),
        child: LoadingShimmer(count: 5),
      ),
      error: (error, _) => ErrorStateWidget(
        title: 'Could not load sessions',
        message: '$error',
        onRetry: () => ref.invalidate(sessionListProvider(filter)),
      ),
      data: (data) {
        if (data.items.isEmpty) {
          return EmptyStateWidget(
            icon: filter == SessionListFilter.upcoming
                ? Icons.event_available_outlined
                : Icons.history_rounded,
            title: filter == SessionListFilter.upcoming
                ? 'No upcoming sessions'
                : 'No completed sessions',
            message: filter == SessionListFilter.upcoming
                ? 'Your confirmed bookings will appear here.'
                : 'Finished mentorship sessions will appear here.',
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(sessionListProvider(filter).future),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            itemCount: data.items.length + (data.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == data.items.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: OutlinedButton.icon(
                    onPressed: data.loadingMore
                        ? null
                        : () => ref
                              .read(sessionListProvider(filter).notifier)
                              .loadMore(),
                    icon: data.loadingMore
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.expand_more_rounded),
                    label: const Text('Load more'),
                  ),
                );
              }
              final booking = data.items[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SessionCard(
                  booking: booking,
                  completed: filter == SessionListFilter.completed,
                  onCancel: () => _cancel(context, ref, booking),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _cancel(
    BuildContext context,
    WidgetRef ref,
    Booking booking,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel session?'),
        content: const Text(
          'Cancelling does not automatically issue a refund. Payment support may need to handle it separately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep session'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel session'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(bookingProvider.notifier).cancel(booking.id);
      ref.invalidate(sessionListProvider(SessionListFilter.upcoming));
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Session cancelled')));
      }
    } catch (error) {
      if (!context.mounted) return;
      final message =
          error is ApiException &&
              error.statusCode == 409 &&
              error.code == 'invalid_transition'
          ? 'This session can no longer be cancelled.'
          : error is ApiException
          ? error.message
          : 'Could not cancel the session.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.booking,
    required this.completed,
    required this.onCancel,
  });

  final Booking booking;
  final bool completed;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final cancellable = const {
      'pending_payment',
      'confirmed',
      'draft',
    }.contains(booking.status);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.mentor.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Chip(label: Text(booking.status.replaceAll('_', ' '))),
            ],
          ),
          Text(booking.sessionGoal),
          const SizedBox(height: 8),
          Text(
            '${DateFormat.yMMMd().format(booking.scheduledAt.toLocal())} · '
            '${DateFormat.jm().format(booking.scheduledAt.toLocal())} · '
            '${booking.durationMinutes} min',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (!completed && booking.status != 'cancelled') ...[
                if (booking.status == 'pending_payment')
                  FilledButton.icon(
                    onPressed: () => context.push('/payment/${booking.id}'),
                    icon: const Icon(Icons.payment_rounded),
                    label: const Text('Complete Payment'),
                  )
                else
                  FilledButton.icon(
                    onPressed: () => context.push('/session/${booking.id}'),
                    icon: const Icon(Icons.videocam_outlined),
                    label: const Text('Open session'),
                  ),
              ],
              if (!completed && cancellable) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Cancel session',
                  onPressed: onCancel,
                  icon: const Icon(Icons.event_busy_outlined),
                ),
              ],
              if (completed)
                OutlinedButton.icon(
                  onPressed: () => context.push('/review/${booking.id}'),
                  icon: const Icon(Icons.star_outline_rounded),
                  label: const Text('Review'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
