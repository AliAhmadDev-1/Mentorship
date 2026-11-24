import 'package:flutter/material.dart';

import '../../shared/widgets/primary_button.dart';

class RetryButton extends StatelessWidget {
  const RetryButton({super.key, required this.onPressed, this.label = 'Retry'});

  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(label: label, onPressed: onPressed);
  }
}
