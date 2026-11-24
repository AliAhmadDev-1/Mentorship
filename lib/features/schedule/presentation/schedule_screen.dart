import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/error_state_widget.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../providers/availability_provider.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  String _day = 'Mon';

  @override
  Widget build(BuildContext context) {
    final availability = ref.watch(availabilityProvider);
    final dashboard = ref.watch(dashboardProvider);
    return Scaffold(
      body: SafeArea(
        child: availability.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: LoadingShimmer(count: 5),
          ),
          error: (error, stack) => ErrorStateWidget(
            title: 'Schedule failed',
            message: '$error',
            onRetry: () => ref.invalidate(availabilityProvider),
          ),
          data: (items) {
            final selected = items.firstWhere((item) => item.day == _day);
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Schedule',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const Text('Manage your availability'),
                const SizedBox(height: 16),
                SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: items
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(item.day),
                              selected: item.day == _day,
                              onSelected: (_) =>
                                  setState(() => _day = item.day),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                SwitchListTile(
                  value: selected.isEnabled,
                  onChanged: (_) =>
                      ref.read(availabilityProvider.notifier).toggleDay(_day),
                  title: Text('$_day active'),
                ),
                if (selected.slots.isEmpty)
                  const EmptyStateWidget(
                    icon: Icons.event_busy,
                    title: 'No slots',
                    message: 'Add a slot to start taking bookings.',
                  )
                else
                  for (final slot in selected.slots)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${slot.startTime} - ${slot.endTime}',
                              ),
                            ),
                            Chip(
                              label: Text(slot.isBooked ? 'Booked' : 'Free'),
                              backgroundColor: slot.isBooked
                                  ? AppColors.error.withValues(alpha: .12)
                                  : AppColors.success.withValues(alpha: .12),
                            ),
                            if (!slot.isBooked)
                              IconButton(
                                onPressed: () => ref
                                    .read(availabilityProvider.notifier)
                                    .removeTimeSlot(_day, slot.id),
                                icon: const Icon(Icons.delete_outline),
                              ),
                          ],
                        ),
                      ),
                    ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Add Slot',
                  icon: Icons.add,
                  onPressed: () => _showAddSlot(context),
                ),
                const SizedBox(height: 22),
                const Text('Upcoming sessions'),
                const SizedBox(height: 8),
                dashboard.when(
                  loading: () => const LoadingShimmer(count: 1),
                  error: (error, stack) => GlassCard(child: Text('$error')),
                  data: (data) {
                    if (data.todaySessions.isEmpty) {
                      return const GlassCard(
                        child: Text('No upcoming sessions today.'),
                      );
                    }
                    return Column(
                      children: data.todaySessions
                          .map(
                            (booking) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: GlassCard(
                                child: Text(
                                  '${booking.mentor.name} · ${booking.scheduledAt.hour.toString().padLeft(2, '0')}:${booking.scheduledAt.minute.toString().padLeft(2, '0')}',
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showAddSlot(BuildContext context) {
    final start = TextEditingController(text: '16:00');
    final end = TextEditingController(text: '16:15');
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Add slot', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              TextField(
                controller: start,
                decoration: const InputDecoration(
                  labelText: 'Start time',
                  hintText: '16:00',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: end,
                decoration: const InputDecoration(
                  labelText: 'End time',
                  hintText: '16:15',
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Save',
                onPressed: () async {
                  final startText = start.text.trim();
                  final endText = end.text.trim();
                  if (!_isTime(startText) || !_isTime(endText)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Use 24-hour time like 16:00'),
                      ),
                    );
                    return;
                  }
                  try {
                    await ref
                        .read(availabilityProvider.notifier)
                        .addTimeSlot(_day, startText, endText);
                    if (context.mounted) Navigator.pop(context);
                  } catch (error) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('$error')));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      start.dispose();
      end.dispose();
    });
  }
}

bool _isTime(String value) {
  final match = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').firstMatch(value);
  return match != null;
}
