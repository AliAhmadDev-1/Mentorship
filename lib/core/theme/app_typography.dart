import 'package:flutter/material.dart';

class AppTypography {
  const AppTypography._();

  static TextTheme textTheme({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;
    final primaryText = isDark
        ? const Color(0xFFF2F6F3)
        : const Color(0xFF18211D);
    final secondaryText = isDark
        ? const Color(0xFFB0BAB4)
        : const Color(0xFF56635C);
    final tertiaryText = isDark
        ? const Color(0xFF7A857E)
        : const Color(0xFF849089);
    final body = brightness == Brightness.dark
        ? Typography.material2021().white
        : Typography.material2021().black;
    return body.copyWith(
      displayLarge: body.displayLarge?.copyWith(
        color: primaryText,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      headlineLarge: body.headlineLarge?.copyWith(
        color: primaryText,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      headlineMedium: body.headlineMedium?.copyWith(
        color: primaryText,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      titleLarge: body.titleLarge?.copyWith(
        color: primaryText,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      titleMedium: body.titleMedium?.copyWith(
        color: primaryText,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      bodyLarge: body.bodyLarge?.copyWith(color: primaryText, letterSpacing: 0),
      bodyMedium: body.bodyMedium?.copyWith(
        color: secondaryText,
        letterSpacing: 0,
      ),
      bodySmall: body.bodySmall?.copyWith(
        color: tertiaryText,
        letterSpacing: 0,
      ),
      labelLarge: body.labelLarge?.copyWith(
        color: primaryText,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      labelMedium: body.labelMedium?.copyWith(
        color: primaryText,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      labelSmall: body.labelSmall?.copyWith(
        color: secondaryText,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
    );
  }
}
