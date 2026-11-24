import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/booking.dart';
import '../../../core/models/app_user.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers/api_provider.dart';
import '../../../core/services/agora_service.dart';
import '../../../shared/widgets/audio_wave.dart';
import '../../../shared/widgets/session_timer.dart';
import '../../home/providers/home_provider.dart';
import '../../booking/providers/booking_provider.dart';
import '../../profile/providers/role_provider.dart';

class VideoSessionScreen extends ConsumerStatefulWidget {
  const VideoSessionScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<VideoSessionScreen> createState() => _VideoSessionScreenState();
}

class _VideoSessionScreenState extends ConsumerState<VideoSessionScreen> {
  final _service = AgoraService();
  Offset _localOffset = const Offset(230, 110);
  bool _muted = false;
  bool _cameraOff = false;
  bool _started = false;
  String _message = '';

  Future<void> _start(Booking booking) async {
    if (_started) return;
    _started = true;
    final statuses = await [Permission.camera, Permission.microphone].request();
    if (statuses.values.any(
      (status) => status.isDenied || status.isPermanentlyDenied,
    )) {
      setState(
        () => _message =
            'Camera or microphone permission was denied. Simulated session is still available.',
      );
    }
    try {
      await _service.initialize();
      await _service.joinChannel(
        token: '',
        channelId: booking.agoraChannel.isEmpty
            ? 'session_${booking.id}'
            : booking.agoraChannel,
        uid: 0,
      );
    } catch (_) {
      setState(
        () => _message = 'Agora is running in simulated prototype mode.',
      );
    }
  }

  Future<void> _endSession() async {
    final router = GoRouter.of(context);
    final role = ref.read(roleProvider);
    await _service.leaveChannel();
    if (!mounted) return;
    if (role == UserRole.mentor) {
      final response = await ref
          .read(microMentorApiProvider)
          .completeSession(widget.bookingId);
      if (!mounted) return;
      if (!response.success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.error!.message)));
      }
      router.go('/dashboard');
      return;
    }
    router.go('/review/${widget.bookingId}');
  }

  Future<void> _cancelSession(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel session?'),
        content: const Text(
          'The session will be cancelled. Any payment refund is handled separately.',
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
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Session cancelled')));
      context.go(
        ref.read(roleProvider) == UserRole.mentor ? '/dashboard' : '/home',
      );
    } catch (error) {
      if (!mounted) return;
      final message =
          error is ApiException &&
              error.statusCode == 409 &&
              error.code == 'invalid_transition'
          ? 'This session can no longer be cancelled.'
          : error is ApiException
          ? error.message
          : 'Could not cancel the session. Please try again.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: ref
          .read(bookingRepositoryProvider)
          .getBookingById(widget.bookingId),
      builder: (context, snapshot) {
        final booking = snapshot.data;
        if (snapshot.hasData) {
          _start(booking!);
        }
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.video_call_rounded, size: 92),
                      const SizedBox(height: 12),
                      Text(
                        booking == null
                            ? 'Loading session...'
                            : 'In session with ${booking.mentor.name}',
                        style: const TextStyle(fontSize: 20),
                        textAlign: TextAlign.center,
                      ),
                      if (_message.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(_message, textAlign: TextAlign.center),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  top: 12,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          booking == null
                              ? 'Session'
                              : '${booking.mentor.name} · ${booking.sessionGoal}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      SessionTimer(minutes: booking?.durationMinutes ?? 15),
                      if (booking != null &&
                          const {
                            'pending_payment',
                            'confirmed',
                            'draft',
                          }.contains(booking.status))
                        IconButton(
                          tooltip: 'Cancel session',
                          onPressed: () => _cancelSession(booking),
                          icon: const Icon(Icons.event_busy_outlined),
                        ),
                      const SizedBox(width: 12),
                      const AudioWave(),
                    ],
                  ),
                ),
                Positioned(
                  left: _localOffset.dx,
                  top: _localOffset.dy,
                  child: GestureDetector(
                    onPanUpdate: (d) => setState(() => _localOffset += d.delta),
                    child: Container(
                      width: 100,
                      height: 140,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderActive),
                      ),
                      child: Icon(
                        _cameraOff ? Icons.videocam_off : Icons.person,
                        size: 42,
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  left: 16,
                  right: 16,
                  bottom: 100,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Message in session',
                      suffixIcon: IconButton(
                        tooltip: 'In-session chat unavailable',
                        onPressed: null,
                        icon: Icon(Icons.send_rounded),
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _Circle(
                        icon: _muted ? Icons.mic_off : Icons.mic,
                        onTap: () => setState(() => _muted = !_muted),
                      ),
                      _Circle(
                        icon: Icons.call_end,
                        color: AppColors.error,
                        size: 68,
                        onTap: () async {
                          final end = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('End session?'),
                              actions: [
                                TextButton(
                                  onPressed: () => context.pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => context.pop(true),
                                  child: const Text('End'),
                                ),
                              ],
                            ),
                          );
                          if (end == true && context.mounted) {
                            await _endSession();
                          }
                        },
                      ),
                      _Circle(
                        icon: _cameraOff ? Icons.videocam_off : Icons.videocam,
                        onTap: () => setState(() => _cameraOff = !_cameraOff),
                      ),
                      _Circle(icon: Icons.more_horiz, onTap: () {}),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({
    required this.icon,
    required this.onTap,
    this.color = AppColors.surfaceHigh,
    this.size = 54,
  });
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    customBorder: const CircleBorder(),
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon),
    ),
  );
}
