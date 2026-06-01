import 'package:flutter/widgets.dart';

@immutable
class DSColors {
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color accentMuted;
  final Color success;
  final Color warning;
  final Color danger;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color highlight;

  const DSColors({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.accentMuted,
    required this.success,
    required this.warning,
    required this.danger,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.highlight,
  });

  factory DSColors.light() {
    return const DSColors(
      background: Color(0xFFF8FAFC), // page
      surface: Color(0xFFFFFFFF),
      surfaceAlt: Color(0xFFF1F5F9),
      primary: Color(0xFF2BA6CB), // brand primary
      secondary: Color(0xFF0EA5E9), // info default
      accent: Color(0xFFE3F6FB), // quiet/soft primary
      accentMuted: Color(0xFFD9E2EC), // subtle surface/border
      success: Color(0xFF16A34A),
      warning: Color(0xFFF59E0B),
      danger: Color(0xFFE11D48),
      textPrimary: Color(0xFF0F172A),
      textSecondary: Color(0xFF475569),
      textMuted: Color(0xFF64748B),
      border: Color(0xFFE2E8F0),
      highlight: Color(0xFFE0F2FE), // info soft
    );
  }
}
