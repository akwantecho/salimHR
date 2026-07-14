import 'package:flutter/widgets.dart';

import 'tokens/animation.dart';
import 'tokens/colors.dart';
import 'tokens/opacity.dart';
import 'tokens/radius.dart';
import 'tokens/shadows.dart';
import 'tokens/spacing.dart';
import 'tokens/typography.dart';

@immutable
class DSTheme {
  final DSColors colors;
  final DSTypography typography;
  final DSSpacing spacing;
  final DSRadii radii;
  final DSShadows shadows;
  final DSAnimation animation;
  final DSOpacity opacity;
  final TextDirection textDirection;
  final Locale locale;

  const DSTheme({
    required this.colors,
    required this.typography,
    required this.spacing,
    required this.radii,
    required this.shadows,
    required this.animation,
    required this.opacity,
    required this.textDirection,
    required this.locale,
  });

  factory DSTheme.light({
    TextDirection direction = TextDirection.rtl,
    Locale locale = const Locale('ar'),
  }) {
    final colors = DSColors.light();
    return DSTheme(
      colors: colors,
      typography: DSTypography.arabicDefault(
        colors.textPrimary,
        colors.textSecondary,
      ),
      spacing: const DSSpacing(),
      radii: const DSRadii(),
      shadows: DSShadows.soft(colors.textPrimary),
      animation: const DSAnimation(),
      opacity: const DSOpacity(),
      textDirection: direction,
      locale: locale,
    );
  }

  factory DSTheme.dark({
    TextDirection direction = TextDirection.rtl,
    Locale locale = const Locale('ar'),
  }) {
    final colors = DSColors.dark();
    return DSTheme(
      colors: colors,
      typography: DSTypography.arabicDefault(
        colors.textPrimary,
        colors.textSecondary,
      ),
      spacing: const DSSpacing(),
      radii: const DSRadii(),
      shadows: DSShadows.soft(colors.textPrimary),
      animation: const DSAnimation(),
      opacity: const DSOpacity(),
      textDirection: direction,
      locale: locale,
    );
  }

  DSTheme withDirection(TextDirection direction) {
    return DSTheme(
      colors: colors,
      typography: typography,
      spacing: spacing,
      radii: radii,
      shadows: shadows,
      animation: animation,
      opacity: opacity,
      textDirection: direction,
      locale: locale,
    );
  }
}

/// Convenience accessor matching `DS.of(context)` expectation.
class DS {
  static DSTheme of(BuildContext context) => DSProvider.of(context);
}

class DSProvider extends InheritedWidget {
  final DSTheme theme;

  const DSProvider({
    super.key,
    required this.theme,
    required Widget child,
  }) : super(child: child);

  static DSTheme of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<DSProvider>();
    assert(provider != null, 'DSProvider not found in context');
    return provider!.theme;
  }

  @override
  bool updateShouldNotify(covariant DSProvider oldWidget) {
    return theme != oldWidget.theme;
  }
}
