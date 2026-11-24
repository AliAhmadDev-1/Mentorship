import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/api_provider.dart';
import '../../../shared/extensions/date_extensions.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../home/providers/home_provider.dart';
import '../providers/booking_provider.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  bool _paying = false;
  bool _isConfirmed = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: ref
          .read(bookingRepositoryProvider)
          .getBookingById(widget.bookingId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final booking = snapshot.data!;
        final alreadyConfirmed = booking.status == 'confirmed';
        final showSuccess = _isConfirmed || alreadyConfirmed;

        if (showSuccess) {
          final now = DateTime.now();
          final minutesUntil = booking.scheduledAt.difference(now).inMinutes;
          final isStartingSoon =
              minutesUntil <= 10 && minutesUntil >= -booking.durationMinutes;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Confirmation'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  tooltip: 'Done',
                  icon: const Icon(Icons.close),
                  onPressed: () => context.go('/home'),
                ),
              ],
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.16),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.success.withValues(alpha: 0.4),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.success,
                              size: 48,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Booking Confirmed!',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your session with ${booking.mentor.name} is scheduled.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 28),
                        GlassCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking.mentor.name,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              if (booking.sessionGoal.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  booking.sessionGoal,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                              const Divider(height: 24),
                              _InfoRow(
                                icon: Icons.calendar_today_rounded,
                                label: 'Date',
                                value: booking.scheduledAt.toLocal().shortDate,
                              ),
                              const SizedBox(height: 10),
                              _InfoRow(
                                icon: Icons.access_time_rounded,
                                label: 'Time',
                                value:
                                    '${booking.scheduledAt.toLocal().timeLabel} (${booking.durationMinutes} min)',
                              ),
                              const SizedBox(height: 10),
                              _InfoRow(
                                icon: Icons.payments_rounded,
                                label: 'Amount Paid',
                                value: '\$${booking.amount.toStringAsFixed(0)}',
                              ),
                              const SizedBox(height: 10),
                              _InfoRow(
                                icon: Icons.tag_rounded,
                                label: 'Reference',
                                value: '#${booking.id}',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        if (isStartingSoon) ...[
                          PrimaryButton(
                            label: 'Join Video Session Now',
                            icon: Icons.videocam_rounded,
                            onPressed: () => context.pushReplacement(
                              '/session/${widget.bookingId}',
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () => context.go('/sessions-list'),
                            child: const Text('View All Sessions'),
                          ),
                        ] else ...[
                          PrimaryButton(
                            label: 'View My Sessions',
                            icon: Icons.event_note_rounded,
                            onPressed: () => context.go('/sessions-list'),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => context.go('/home'),
                            child: const Text('Return to Home'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        final paymentStatusFuture = ref
            .read(microMentorApiProvider)
            .getPaymentStatus(widget.bookingId);
        return Scaffold(
          appBar: AppBar(title: const Text('Confirm & Pay')),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.mentor.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '${booking.scheduledAt.shortDate} · ${booking.scheduledAt.timeLabel} · ${booking.durationMinutes} min',
                        ),
                        const Divider(),
                        _Line('Session fee', booking.amount),
                        const _Line('Platform fee', 0),
                        const Divider(),
                        _Line('Total', booking.amount, gold: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  FutureBuilder(
                    future: paymentStatusFuture,
                    builder: (context, paymentSnapshot) {
                      final payment = paymentSnapshot.data?.data;
                      return GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(payment?.provider ?? 'Payment provider'),
                            const SizedBox(height: 8),
                            Text(payment?.status ?? 'Awaiting confirmation'),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Amount \$${(payment?.amountUsd ?? booking.amount).toStringAsFixed(0)}',
                                  ),
                                ),
                                Expanded(child: Text('Session #${booking.id}')),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Row(
                              children: [
                                Icon(Icons.lock, color: AppColors.success),
                                SizedBox(width: 8),
                                Text('Secure payment confirmation'),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  PrimaryButton(
                    label:
                        'Pay \$${booking.amount.toStringAsFixed(0)} Securely',
                    isLoading: _paying,
                    onPressed: () async {
                      setState(() => _paying = true);
                      try {
                        await ref
                            .read(bookingProvider.notifier)
                            .confirmPayment(widget.bookingId);
                        ref.invalidate(homeProvider);
                        if (!context.mounted) return;
                        setState(() {
                          _paying = false;
                          _isConfirmed = true;
                        });
                      } catch (error) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('$error')));
                        setState(() => _paying = false);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: AppColors.textSecondary),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(color: AppColors.textSecondary)),
      const Spacer(),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
    ],
  );
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.amount, {this.gold = false});
  final String label;
  final double amount;
  final bool gold;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Text(label),
        const Spacer(),
        Text(
          '\$${amount.toStringAsFixed(0)}',
          style: TextStyle(
            color: gold ? AppColors.gold : null,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}
