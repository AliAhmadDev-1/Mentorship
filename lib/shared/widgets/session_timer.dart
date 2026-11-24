import 'dart:async';

import 'package:flutter/material.dart';

class SessionTimer extends StatefulWidget {
  const SessionTimer({super.key, required this.minutes});

  final int minutes;

  @override
  State<SessionTimer> createState() => _SessionTimerState();
}

class _SessionTimerState extends State<SessionTimer> {
  late int _seconds = widget.minutes * 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _seconds == 0) return;
      setState(() => _seconds--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mins = (_seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (_seconds % 60).toString().padLeft(2, '0');
    return Text(
      '$mins:$secs',
      style: const TextStyle(fontWeight: FontWeight.w900),
    );
  }
}
