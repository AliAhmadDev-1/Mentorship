import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.initials,
    required this.colorValue,
    this.size = 52,
    this.isOnline = false,
    this.verified = false,
  });

  final String initials;
  final int colorValue;
  final double size;
  final bool isOnline;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color(colorValue),
            border: Border.all(
              color: Theme.of(context).colorScheme.surface,
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: TextStyle(
              color: AppColors.darkest,
              fontWeight: FontWeight.w900,
              fontSize: size * .32,
            ),
          ),
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 2,
            child: Container(
              width: size * .2,
              height: size * .2,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
          ),
        if (verified)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: size * .25,
              height: size * .25,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                size: size * .16,
                color: AppColors.darkest,
              ),
            ),
          ),
      ],
    );
  }
}
