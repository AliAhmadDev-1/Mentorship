import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final buttonStyle = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(52),
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.darkest,
      disabledBackgroundColor: AppColors.primary.withValues(alpha: .4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
    );
    if (isLoading) {
      return FilledButton(
        onPressed: null,
        style: buttonStyle,
        child: const SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.darkest,
          ),
        ),
      );
    }
    return icon == null
        ? FilledButton(
            onPressed: onPressed,
            style: buttonStyle,
            child: Text(label),
          )
        : FilledButton.icon(
            onPressed: onPressed,
            style: buttonStyle,
            icon: Icon(icon),
            label: Text(label),
          );
  }
}
