import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/api_models.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/models/mentor.dart';
import '../../../core/providers/api_provider.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/error_state_widget.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../home/providers/home_provider.dart';
import '../providers/booking_provider.dart';

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key, required this.mentorId});

  final String mentorId;

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  late Future<_BookingContent> _bookingFuture;
  DateTime _day = DateTime.now().add(const Duration(days: 1));
  String? _slotStart;
  int _duration = 15;
  final _goal = TextEditingController();

  @override
  void initState() {
    super.initState();
    _bookingFuture = _loadBookingContent();
  }

  @override
  void didUpdateWidget(covariant BookingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mentorId != widget.mentorId) {
      _slotStart = null;
      _bookingFuture = _loadBookingContent();
    }
  }

  @override
  void dispose() {
    _goal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _bookingFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Book Session')),
            body: SafeArea(
              child: ErrorStateWidget(
                title: 'Booking failed',
                message: '${snapshot.error}',
                onRetry: () =>
                    setState(() => _bookingFuture = _loadBookingContent()),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final content = snapshot.data!;
        final mentor = content.mentor;
        final slots = content.availableSlotsFor(_day);
        BookableSlotResponse? selectedSlot;
        for (final slot in slots) {
          if (slot.startsAt.toIso8601String() == _slotStart) {
            selectedSlot = slot;
            break;
          }
        }
        selectedSlot ??= slots.isEmpty ? null : slots.first;
        final durations =
            mentor.packages.isEmpty
                  ? const [15]
                  : mentor.packages
                        .map((package) => package.durationMinutes)
                        .toSet()
                        .toList()
              ..sort();
        final selectedDuration = durations.contains(_duration)
            ? _duration
            : durations.first;
        final selectedPackage = mentor.packageForDuration(selectedDuration);
        final price =
            selectedPackage?.priceUsd ??
            mentor.ratePerSlot * selectedDuration / 15;
        return Scaffold(
          appBar: AppBar(title: const Text('Book Session')),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlassCard(
                    child: Row(
                      children: [
                        AppAvatar(
                          initials: mentor.avatarInitials,
                          colorValue: mentor.avatarColorValue,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('${mentor.name}\n${mentor.title}'),
                        ),
                        Text(
                          '\$${mentor.ratePerSlot.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TableCalendar(
                    firstDay: DateTime.now(),
                    lastDay: DateTime.now().add(const Duration(days: 30)),
                    focusedDay: _day,
                    selectedDayPredicate: (day) => isSameDay(day, _day),
                    onDaySelected: (selected, focused) => setState(() {
                      _day = selected;
                      _slotStart = null;
                    }),
                    calendarStyle: const CalendarStyle(
                      defaultTextStyle: TextStyle(color: AppColors.textPrimary),
                      weekendTextStyle: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (slots.isEmpty)
                    const GlassCard(
                      child: Text('No available slots for this day.'),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: slots
                          .map(
                            (slot) => ChoiceChip(
                              label: Text(
                                DateFormat.jm().format(slot.startsAt.toLocal()),
                              ),
                              selected:
                                  slot.startsAt.toIso8601String() ==
                                  selectedSlot?.startsAt.toIso8601String(),
                              selectedColor: AppColors.primarySoft,
                              onSelected: (_) => setState(
                                () => _slotStart = slot.startsAt
                                    .toIso8601String(),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  const SizedBox(height: 18),
                  SegmentedButton<int>(
                    segments: durations
                        .map(
                          (duration) => ButtonSegment(
                            value: duration,
                            label: Text('$duration min'),
                          ),
                        )
                        .toList(),
                    selected: {selectedDuration},
                    onSelectionChanged: (value) => setState(() {
                      _duration = value.first;
                      _slotStart = null;
                      _bookingFuture = _loadBookingContent(
                        durationMinutes: _duration,
                      );
                    }),
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _goal,
                    hint: 'Session goals (optional)',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 22),
                  PrimaryButton(
                    label:
                        'Continue to Payment · \$${price.toStringAsFixed(0)}',
                    onPressed: selectedSlot == null
                        ? null
                        : () async {
                            try {
                              final booking = await ref
                                  .read(bookingProvider.notifier)
                                  .createBooking(
                                    mentor,
                                    selectedSlot!.startsAt,
                                    selectedDuration,
                                    _goal.text,
                                  );
                              if (context.mounted) {
                                context.push('/payment/${booking.id}');
                              }
                            } catch (error) {
                              if (!context.mounted) return;
                              if (error is ApiException &&
                                  error.statusCode == 403 &&
                                  error.code == 'mentor_not_available') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'This mentor is not currently available for bookings.',
                                    ),
                                  ),
                                );
                                context.go('/discover');
                                return;
                              }
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
        );
      },
    );
  }

  Future<_BookingContent> _loadBookingContent({int? durationMinutes}) async {
    final mentor = await ref
        .read(mentorRepositoryProvider)
        .getMentorById(widget.mentorId);
    final duration =
        durationMinutes ??
        (mentor.packages.isEmpty
            ? _duration
            : mentor.packages.first.durationMinutes);
    _duration = duration;
    final today = DateTime.now();
    final availability = await ref
        .read(microMentorApiProvider)
        .getMentorAvailability(
          widget.mentorId,
          from: today,
          to: today.add(const Duration(days: 30)),
          durationMinutes: duration,
        );
    if (!availability.success) throw availability.error!;
    final availabilityData = availability.data;
    var slots = availabilityData?.slots ?? const <BookableSlotResponse>[];
    if (slots.isEmpty && availabilityData != null) {
      slots = _synthesizeSlots(
        windows: availabilityData.weeklyWindows,
        bookedStarts: availabilityData.bookedStarts,
        durationMinutes: duration,
        fromDate: today,
        toDate: today.add(const Duration(days: 30)),
      );
    }
    return _BookingContent(
      mentor: mentor,
      slots: slots,
    );
  }
}

List<BookableSlotResponse> _synthesizeSlots({
  required List<AvailabilityWindowResponse> windows,
  required List<DateTime> bookedStarts,
  required int durationMinutes,
  required DateTime fromDate,
  required DateTime toDate,
}) {
  if (windows.isEmpty) return const [];
  final activeWindows = windows.where((w) => w.isActive ?? true).toList();
  if (activeWindows.isEmpty) return const [];

  final synthesized = <BookableSlotResponse>[];
  final now = DateTime.now();
  final leadBuffer = now.add(const Duration(minutes: 15));

  var currentDay = DateTime(fromDate.year, fromDate.month, fromDate.day);
  final endDay = DateTime(toDate.year, toDate.month, toDate.day);

  while (!currentDay.isAfter(endDay)) {
    final weekday = currentDay.weekday;
    final dayWindows = activeWindows.where((w) => w.weekday == weekday);

    for (final window in dayWindows) {
      final startHm = _parseHourMinute(window.startsAt);
      final endHm = _parseHourMinute(window.endsAt);
      if (startHm == null || endHm == null) continue;

      final windowStart = DateTime(
        currentDay.year,
        currentDay.month,
        currentDay.day,
        startHm.$1,
        startHm.$2,
      );
      final windowEnd = DateTime(
        currentDay.year,
        currentDay.month,
        currentDay.day,
        endHm.$1,
        endHm.$2,
      );

      final stepMinutes = window.slotIntervalMinutes != null &&
              window.slotIntervalMinutes! > 0
          ? window.slotIntervalMinutes!
          : durationMinutes;

      var slotStart = windowStart;
      while (true) {
        final slotEnd = slotStart.add(Duration(minutes: durationMinutes));
        if (slotEnd.isAfter(windowEnd)) break;

        if (slotStart.isAfter(leadBuffer)) {
          final isBooked = bookedStarts.any((booked) {
            final localBooked = booked.toLocal();
            return localBooked.isAtSameMomentAs(slotStart) ||
                (localBooked.isAfter(slotStart) &&
                    localBooked.isBefore(slotEnd));
          });

          synthesized.add(
            BookableSlotResponse(
              startsAt: slotStart,
              endsAt: slotEnd,
              available: !isBooked,
            ),
          );
        }

        slotStart = slotStart.add(Duration(minutes: stepMinutes));
      }
    }

    currentDay = currentDay.add(const Duration(days: 1));
  }

  return synthesized;
}

(int, int)? _parseHourMinute(String? timeStr) {
  if (timeStr == null || timeStr.trim().isEmpty) return null;
  final parts = timeStr.trim().split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return (hour, minute);
}

class _BookingContent {
  const _BookingContent({required this.mentor, required this.slots});

  final Mentor mentor;
  final List<BookableSlotResponse> slots;

  List<BookableSlotResponse> availableSlotsFor(DateTime day) {
    final matches = slots.where((slot) {
      final local = slot.startsAt.toLocal();
      return slot.available &&
          local.year == day.year &&
          local.month == day.month &&
          local.day == day.day;
    }).toList()..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return matches;
  }
}
