/// Salim ERP Design System for Flutter
/// Auto-generated from Laravel/Tailwind project analysis
///
/// Usage:
/// 1. Copy this file to your Flutter project's lib/theme/ directory
/// 2. Import and use: `import 'package:your_app/theme/flutter_design_system.dart';`
/// 3. Apply theme: `MaterialApp(theme: SalimTheme.lightTheme, ...)`
library;

import 'package:flutter/material.dart';

// =============================================================================
// COLORS
// =============================================================================

/// Brand and semantic colors matching the Laravel frontend
class SalimColors {
  SalimColors._();

  // ---------------------------------------------------------------------------
  // Primary Brand Colors (Teal/Cyan)
  // ---------------------------------------------------------------------------
  static const Color primary = Color(0xFF2BA6CB);
  static const Color primaryHover = Color(0xFF258FB0);
  static const Color primaryQuiet = Color(0xFFE3F6FB);

  static const MaterialColor primarySwatch = MaterialColor(0xFF2BA6CB, {
    50: Color(0xFFE3F6FB),
    100: Color(0xFFC7EAF5),
    200: Color(0xFF91D3E6),
    300: Color(0xFF5BB9D6),
    400: Color(0xFF3FA8CE),
    500: Color(0xFF2BA6CB),
    600: Color(0xFF258FB0),
    700: Color(0xFF1F7892),
    800: Color(0xFF1A6176),
    900: Color(0xFF134A5D),
  });

  // ---------------------------------------------------------------------------
  // Success Colors
  // ---------------------------------------------------------------------------
  static const Color success = Color(0xFF16A34A);
  static const Color successSoft = Color(0xFFDCFCE7);

  static const MaterialColor successSwatch = MaterialColor(0xFF16A34A, {
    50: Color(0xFFF0FDF4),
    100: Color(0xFFDCFCE7),
    200: Color(0xFFBBF7D0),
    300: Color(0xFF86EFAC),
    400: Color(0xFF4ADE80),
    500: Color(0xFF22C55E),
    600: Color(0xFF16A34A),
    700: Color(0xFF15803D),
    800: Color(0xFF166534),
    900: Color(0xFF14532D),
  });

  // ---------------------------------------------------------------------------
  // Warning Colors
  // ---------------------------------------------------------------------------
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSoft = Color(0xFFFEF3C7);

  static const MaterialColor warningSwatch = MaterialColor(0xFFF59E0B, {
    50: Color(0xFFFFFBEB),
    100: Color(0xFFFEF3C7),
    200: Color(0xFFFDE68A),
    300: Color(0xFFFCD34D),
    400: Color(0xFFFBBF24),
    500: Color(0xFFF59E0B),
    600: Color(0xFFD97706),
    700: Color(0xFFB45309),
    800: Color(0xFF92400E),
    900: Color(0xFF78350F),
  });

  // ---------------------------------------------------------------------------
  // Danger/Error Colors
  // ---------------------------------------------------------------------------
  static const Color danger = Color(0xFFE11D48);
  static const Color dangerSoft = Color(0xFFFFE4E6);

  static const MaterialColor dangerSwatch = MaterialColor(0xFFE11D48, {
    50: Color(0xFFFFF1F2),
    100: Color(0xFFFFE4E6),
    200: Color(0xFFFECDD3),
    300: Color(0xFFFDA4AF),
    400: Color(0xFFFB7185),
    500: Color(0xFFF43F5E),
    600: Color(0xFFE11D48),
    700: Color(0xFFBE123C),
    800: Color(0xFF9F1239),
    900: Color(0xFF881337),
  });

  // ---------------------------------------------------------------------------
  // Info Colors
  // ---------------------------------------------------------------------------
  static const Color info = Color(0xFF0EA5E9);
  static const Color infoSoft = Color(0xFFE0F2FE);

  static const MaterialColor infoSwatch = MaterialColor(0xFF0EA5E9, {
    50: Color(0xFFF0F9FF),
    100: Color(0xFFE0F2FE),
    200: Color(0xFFBAE6FD),
    300: Color(0xFF7DD3FC),
    400: Color(0xFF38BDF8),
    500: Color(0xFF0EA5E9),
    600: Color(0xFF0284C7),
    700: Color(0xFF0369A1),
    800: Color(0xFF075985),
    900: Color(0xFF0C4A6E),
  });

  // ---------------------------------------------------------------------------
  // Neutral/Background Colors
  // ---------------------------------------------------------------------------
  static const Color pageBackground = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFD9E2EC);

  // ---------------------------------------------------------------------------
  // Text Colors
  // ---------------------------------------------------------------------------
  static const Color textStrong = Color(0xFF0F172A);
  static const Color textDeep = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textSubtle = Color(0xFF475569);

  // ---------------------------------------------------------------------------
  // Semantic Aliases
  // ---------------------------------------------------------------------------
  static const Color brandPrimary = primary;
  static const Color brandDeep = textDeep;
  static const Color brandMuted = textSubtle;
  static const Color brandBorder = borderLight;
  static const Color brandSurface = surface;
  static const Color brandPage = pageBackground;
  static const Color brandQuiet = primaryQuiet;

  // ---------------------------------------------------------------------------
  // Gradient Helpers
  // ---------------------------------------------------------------------------
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primary, Color(0xFF2BA6CB)], // to-brand-primary/90
  );

  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [surface, surfaceAlt, surface],
  );
}

// =============================================================================
// TYPOGRAPHY
// =============================================================================

/// Typography system matching Noto Sans / Cairo fonts
class SalimTypography {
  SalimTypography._();

  // ---------------------------------------------------------------------------
  // Font Families
  // ---------------------------------------------------------------------------
  static const String fontFamilyPrimary = 'NotoSans';
  static const String fontFamilyArabic = 'Cairo';

  // ---------------------------------------------------------------------------
  // Font Sizes (rem to px conversion: 1rem = 16px)
  // ---------------------------------------------------------------------------
  static const double fontSizeXs = 12.0;   // 0.75rem
  static const double fontSizeSm = 14.0;   // 0.875rem
  static const double fontSizeBase = 14.0; // 0.875rem
  static const double fontSizeLg = 16.0;   // 1rem
  static const double fontSizeXl = 18.0;   // 1.125rem
  static const double fontSize2xl = 24.0;  // 1.5rem
  static const double fontSize3xl = 30.0;  // 1.875rem

  // ---------------------------------------------------------------------------
  // Line Heights
  // ---------------------------------------------------------------------------
  static const double lineHeightXs = 18.0;   // 1.125rem
  static const double lineHeightSm = 22.0;   // 1.375rem
  static const double lineHeightBase = 22.0; // 1.375rem
  static const double lineHeightLg = 24.0;   // 1.5rem
  static const double lineHeightXl = 26.0;   // 1.625rem
  static const double lineHeight2xl = 32.0;  // 2rem

  // ---------------------------------------------------------------------------
  // Heading Styles
  // ---------------------------------------------------------------------------
  static TextStyle get h1 => const TextStyle(
        fontSize: fontSize2xl, // 24px
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4, // -0.025em
        color: SalimColors.textDeep,
        height: lineHeight2xl / fontSize2xl,
      );

  static TextStyle get h2 => const TextStyle(
        fontSize: fontSizeXl, // 18px
        fontWeight: FontWeight.w600,
        letterSpacing: -0.27, // -0.015em
        color: SalimColors.textDeep,
        height: lineHeightXl / fontSizeXl,
      );

  static TextStyle get h3 => const TextStyle(
        fontSize: fontSizeLg, // 16px
        fontWeight: FontWeight.w500,
        color: SalimColors.textDeep,
        height: lineHeightLg / fontSizeLg,
      );

  static TextStyle get h4 => const TextStyle(
        fontSize: fontSizeSm, // 14px
        fontWeight: FontWeight.w500,
        color: SalimColors.textDeep,
        height: lineHeightSm / fontSizeSm,
      );

  // ---------------------------------------------------------------------------
  // Body Styles
  // ---------------------------------------------------------------------------
  static TextStyle get bodyLarge => const TextStyle(
        fontSize: fontSizeLg, // 16px
        fontWeight: FontWeight.w400,
        color: SalimColors.textMuted,
        height: lineHeightLg / fontSizeLg,
      );

  static TextStyle get bodyMedium => const TextStyle(
        fontSize: fontSizeSm, // 14px
        fontWeight: FontWeight.w400,
        color: SalimColors.textMuted,
        height: lineHeightSm / fontSizeSm,
      );

  static TextStyle get bodySmall => const TextStyle(
        fontSize: fontSizeXs, // 12px
        fontWeight: FontWeight.w400,
        color: SalimColors.textMuted,
        height: lineHeightXs / fontSizeXs,
      );

  // ---------------------------------------------------------------------------
  // Label Styles
  // ---------------------------------------------------------------------------
  static TextStyle get labelLarge => const TextStyle(
        fontSize: fontSizeSm, // 14px
        fontWeight: FontWeight.w700,
        color: SalimColors.textDeep,
        height: lineHeightSm / fontSizeSm,
      );

  static TextStyle get labelMedium => const TextStyle(
        fontSize: fontSizeXs, // 12px
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: SalimColors.textDeep,
      );

  static TextStyle get labelSmall => const TextStyle(
        fontSize: 10.0, // 0.625rem
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: SalimColors.textMuted,
      );

  // ---------------------------------------------------------------------------
  // Button Text Styles
  // ---------------------------------------------------------------------------
  static TextStyle get buttonLarge => const TextStyle(
        fontSize: fontSizeLg, // 16px
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      );

  static TextStyle get buttonMedium => const TextStyle(
        fontSize: 15.0, // text-[15px]
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      );

  static TextStyle get buttonSmall => const TextStyle(
        fontSize: fontSizeSm, // 14px
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      );

  // ---------------------------------------------------------------------------
  // Caption / Hint Styles
  // ---------------------------------------------------------------------------
  static TextStyle get caption => const TextStyle(
        fontSize: fontSizeXs, // 12px
        fontWeight: FontWeight.w400,
        color: SalimColors.textMuted,
        height: lineHeightXs / fontSizeXs,
      );

  static TextStyle get errorText => TextStyle(
        fontSize: fontSizeXs, // 12px
        fontWeight: FontWeight.w400,
        color: SalimColors.dangerSwatch.shade700,
      );
}

// =============================================================================
// SPACING
// =============================================================================

/// Consistent spacing values based on Tailwind's scale
class SalimSpacing {
  SalimSpacing._();

  // Base unit: 4px (Tailwind default)
  static const double unit = 4.0;

  // Common spacing values
  static const double xs = 4.0;    // 1 unit
  static const double sm = 8.0;    // 2 units
  static const double md = 12.0;   // 3 units
  static const double base = 16.0; // 4 units
  static const double lg = 20.0;   // 5 units
  static const double xl = 24.0;   // 6 units
  static const double xxl = 28.0;  // 7 units
  static const double xxxl = 32.0; // 8 units

  // Component-specific padding
  static const double cardPaddingSm = 20.0;  // p-5 (1.25rem)
  static const double cardPaddingMd = 28.0;  // p-7 (1.75rem)
  static const double cardPaddingLg = 36.0;  // p-9 (2.25rem)

  // Input padding
  static const double inputPaddingX = 16.0;    // px-4
  static const double inputPaddingXLg = 20.0;  // px-5

  // Page padding
  static const double pagePadding = 24.0; // p-6

  // Gap values
  static const double gap4 = 16.0;  // gap-4
  static const double gap6 = 24.0;  // gap-6
  static const double gap8 = 32.0;  // gap-8

  // Field group gaps
  static const double fieldGapSm = 16.0;
  static const double fieldGapMd = 24.0;
  static const double fieldGapLg = 32.0;
}

// =============================================================================
// BORDER RADIUS
// =============================================================================

/// Border radius values matching the design system
class SalimRadius {
  SalimRadius._();

  static const double xs = 6.0;
  static const double sm = 10.0;
  static const double md = 14.0;
  static const double lg = 18.0;
  static const double xl = 24.0;
  static const double pill = 9999.0;

  // Semantic aliases
  static const double button = 14.0;
  static const double input = 10.0;
  static const double card = 18.0;
  static const double modal = 24.0;

  // BorderRadius objects for convenience
  static BorderRadius get borderRadiusXs => BorderRadius.circular(xs);
  static BorderRadius get borderRadiusSm => BorderRadius.circular(sm);
  static BorderRadius get borderRadiusMd => BorderRadius.circular(md);
  static BorderRadius get borderRadiusLg => BorderRadius.circular(lg);
  static BorderRadius get borderRadiusXl => BorderRadius.circular(xl);
  static BorderRadius get borderRadiusPill => BorderRadius.circular(pill);

  static BorderRadius get borderRadiusButton => BorderRadius.circular(button);
  static BorderRadius get borderRadiusInput => BorderRadius.circular(input);
  static BorderRadius get borderRadiusCard => BorderRadius.circular(card);
  static BorderRadius get borderRadiusModal => BorderRadius.circular(modal);
}

// =============================================================================
// SHADOWS
// =============================================================================

/// Box shadow definitions matching the design system
class SalimShadows {
  SalimShadows._();

  // Card shadow
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x140F172A), // rgba(15, 23, 42, 0.08)
      blurRadius: 3.0,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Color(0x0F0F172A), // rgba(15, 23, 42, 0.06)
      blurRadius: 2.0,
      offset: Offset(0, 1),
      spreadRadius: -1.0,
    ),
  ];

  // Card hover shadow
  static const List<BoxShadow> cardHover = [
    BoxShadow(
      color: Color(0x140F172A), // rgba(15, 23, 42, 0.08)
      blurRadius: 6.0,
      offset: Offset(0, 4),
      spreadRadius: -1.0,
    ),
    BoxShadow(
      color: Color(0x0F0F172A), // rgba(15, 23, 42, 0.06)
      blurRadius: 4.0,
      offset: Offset(0, 2),
      spreadRadius: -2.0,
    ),
  ];

  // Modal shadow
  static const List<BoxShadow> modal = [
    BoxShadow(
      color: Color(0x1A0F172A), // rgba(15, 23, 42, 0.1)
      blurRadius: 25.0,
      offset: Offset(0, 20),
      spreadRadius: -5.0,
    ),
    BoxShadow(
      color: Color(0x140F172A), // rgba(15, 23, 42, 0.08)
      blurRadius: 10.0,
      offset: Offset(0, 8),
      spreadRadius: -6.0,
    ),
  ];

  // Input shadow
  static const List<BoxShadow> input = [
    BoxShadow(
      color: Color(0x0D0F172A), // rgba(15, 23, 42, 0.05)
      blurRadius: 2.0,
      offset: Offset(0, 1),
    ),
  ];

  // Small shadow (shadow-sm)
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x0D0F172A),
      blurRadius: 2.0,
      offset: Offset(0, 1),
    ),
  ];

  // Medium shadow (shadow-md)
  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x1A0F172A),
      blurRadius: 6.0,
      offset: Offset(0, 4),
      spreadRadius: -1.0,
    ),
  ];

  // Large shadow (shadow-lg)
  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x1A0F172A),
      blurRadius: 15.0,
      offset: Offset(0, 10),
      spreadRadius: -3.0,
    ),
    BoxShadow(
      color: Color(0x0F0F172A),
      blurRadius: 6.0,
      offset: Offset(0, 4),
      spreadRadius: -4.0,
    ),
  ];

  // XL shadow (shadow-xl)
  static const List<BoxShadow> xl = [
    BoxShadow(
      color: Color(0x1A0F172A),
      blurRadius: 25.0,
      offset: Offset(0, 20),
      spreadRadius: -5.0,
    ),
    BoxShadow(
      color: Color(0x0F0F172A),
      blurRadius: 10.0,
      offset: Offset(0, 8),
      spreadRadius: -6.0,
    ),
  ];

  // Primary button shadow
  static List<BoxShadow> primaryButton = [
    BoxShadow(
      color: SalimColors.primary.withValues(alpha: 0.3),
      blurRadius: 15.0,
      offset: const Offset(0, 10),
      spreadRadius: -3.0,
    ),
  ];

  // Danger button shadow
  static List<BoxShadow> dangerButton = [
    BoxShadow(
      color: SalimColors.danger.withValues(alpha: 0.3),
      blurRadius: 15.0,
      offset: const Offset(0, 10),
      spreadRadius: -3.0,
    ),
  ];
}

// =============================================================================
// SIZES
// =============================================================================

/// Common size values for components
class SalimSizes {
  SalimSizes._();

  // ---------------------------------------------------------------------------
  // Input Heights
  // ---------------------------------------------------------------------------
  static const double inputHeightSm = 40.0;  // h-10 (2.5rem)
  static const double inputHeightMd = 44.0;  // h-11 (2.75rem)
  static const double inputHeightLg = 48.0;  // h-12 (3rem)

  // ---------------------------------------------------------------------------
  // Button Heights
  // ---------------------------------------------------------------------------
  static const double buttonHeightSm = 40.0;
  static const double buttonHeightMd = 44.0;
  static const double buttonHeightLg = 48.0;

  // ---------------------------------------------------------------------------
  // Icon Sizes
  // ---------------------------------------------------------------------------
  static const double iconTiny = 14.0;    // h-3.5
  static const double iconSmall = 16.0;   // h-4
  static const double iconMedium = 20.0;  // h-5
  static const double iconLarge = 24.0;   // h-6
  static const double iconXl = 56.0;      // h-14

  // ---------------------------------------------------------------------------
  // Avatar Sizes
  // ---------------------------------------------------------------------------
  static const double avatarSm = 32.0;
  static const double avatarMd = 44.0;    // h-11
  static const double avatarLg = 56.0;

  // ---------------------------------------------------------------------------
  // Sidebar
  // ---------------------------------------------------------------------------
  static const double sidebarWidth = 290.0;
  static const double sidebarCollapsedWidth = 90.0;

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------
  static const double headerHeight = 80.0; // h-20 (5rem)

  // ---------------------------------------------------------------------------
  // Modal Widths
  // ---------------------------------------------------------------------------
  static const double modalWidthSm = 448.0;   // max-w-md
  static const double modalWidthMd = 512.0;   // max-w-lg
  static const double modalWidthLg = 576.0;   // max-w-xl
  static const double modalWidthXl = 672.0;   // max-w-2xl
  static const double modalWidth2xl = 896.0;  // max-w-4xl

  // ---------------------------------------------------------------------------
  // Border Widths
  // ---------------------------------------------------------------------------
  static const double borderWidth = 2.0;
  static const double borderWidthThin = 1.0;
}

// =============================================================================
// BREAKPOINTS
// =============================================================================

/// Responsive breakpoints matching Tailwind defaults
class SalimBreakpoints {
  SalimBreakpoints._();

  static const double sm = 640.0;
  static const double md = 768.0;
  static const double lg = 1024.0;
  static const double xl = 1280.0;
  static const double xxl = 1536.0;

  // Helper methods
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < sm;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= sm && width < lg;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= lg;

  static bool isLargeDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= xl;
}

// =============================================================================
// ANIMATIONS
// =============================================================================

/// Animation constants matching the design system
class SalimAnimations {
  SalimAnimations._();

  // Duration
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 300);

  // Curves
  static const Curve easeDefault = Curves.ease;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeInOut = Curves.easeInOut;

  // Scale values
  static const double scaleHoverButton = 1.02;
  static const double scaleHoverCard = 1.01;
  static const double scalePressed = 1.0;
}

// =============================================================================
// THEME DATA
// =============================================================================

/// Complete Flutter ThemeData matching the Laravel design system
class SalimTheme {
  SalimTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: SalimColors.primary,
        brightness: Brightness.light,
        primary: SalimColors.primary,
        onPrimary: Colors.white,
        secondary: SalimColors.primaryQuiet,
        onSecondary: SalimColors.primary,
        error: SalimColors.danger,
        onError: Colors.white,
        surface: SalimColors.surface,
        onSurface: SalimColors.textDeep,
      ),

      // Scaffold
      scaffoldBackgroundColor: SalimColors.pageBackground,

      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: SalimColors.surface,
        foregroundColor: SalimColors.textDeep,
        titleTextStyle: SalimTypography.h2,
        iconTheme: const IconThemeData(
          color: SalimColors.textMuted,
          size: SalimSizes.iconLarge,
        ),
      ),

      // Card
      cardTheme: CardTheme(
        elevation: 0,
        color: SalimColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: SalimRadius.borderRadiusCard,
          side: const BorderSide(
            color: SalimColors.border,
            width: SalimSizes.borderWidth,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // Elevated Button (Primary)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: SalimColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, SalimSizes.buttonHeightMd),
          padding: const EdgeInsets.symmetric(
            horizontal: SalimSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: SalimRadius.borderRadiusButton,
          ),
          textStyle: SalimTypography.buttonMedium,
        ),
      ),

      // Outlined Button (Secondary)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          backgroundColor: SalimColors.surface,
          foregroundColor: SalimColors.textDeep,
          minimumSize: const Size(0, SalimSizes.buttonHeightMd),
          padding: const EdgeInsets.symmetric(
            horizontal: SalimSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: SalimRadius.borderRadiusButton,
          ),
          side: BorderSide(
            color: SalimColors.border.withValues(alpha: 0.6),
            width: SalimSizes.borderWidth,
          ),
          textStyle: SalimTypography.buttonMedium,
        ),
      ),

      // Text Button (Ghost/Link)
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: SalimColors.primary,
          minimumSize: const Size(0, SalimSizes.buttonHeightMd),
          padding: const EdgeInsets.symmetric(
            horizontal: SalimSpacing.base,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: SalimRadius.borderRadiusButton,
          ),
          textStyle: SalimTypography.buttonMedium,
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SalimColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SalimSpacing.inputPaddingX,
          vertical: SalimSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: SalimRadius.borderRadiusInput,
          borderSide: BorderSide(
            color: SalimColors.border.withValues(alpha: 0.6),
            width: SalimSizes.borderWidth,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: SalimRadius.borderRadiusInput,
          borderSide: BorderSide(
            color: SalimColors.border.withValues(alpha: 0.6),
            width: SalimSizes.borderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: SalimRadius.borderRadiusInput,
          borderSide: const BorderSide(
            color: SalimColors.primary,
            width: SalimSizes.borderWidth,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: SalimRadius.borderRadiusInput,
          borderSide: const BorderSide(
            color: SalimColors.danger,
            width: SalimSizes.borderWidth,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: SalimRadius.borderRadiusInput,
          borderSide: BorderSide(
            color: SalimColors.dangerSwatch.shade600,
            width: SalimSizes.borderWidth,
          ),
        ),
        labelStyle: SalimTypography.labelLarge,
        hintStyle: TextStyle(
          color: SalimColors.textDeep.withValues(alpha: 0.4),
          fontWeight: FontWeight.normal,
        ),
        errorStyle: SalimTypography.errorText,
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return SalimColors.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(
          color: SalimColors.border,
          width: SalimSizes.borderWidth,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // Radio
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return SalimColors.primary;
          }
          return SalimColors.border;
        }),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return SalimColors.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return SalimColors.primary;
          }
          return SalimColors.border;
        }),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: SalimColors.surfaceAlt,
        labelStyle: SalimTypography.bodySmall,
        padding: const EdgeInsets.symmetric(
          horizontal: SalimSpacing.md,
          vertical: SalimSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: SalimRadius.borderRadiusPill,
        ),
      ),

      // Dialog
      dialogTheme: DialogTheme(
        elevation: 0,
        backgroundColor: SalimColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: SalimRadius.borderRadiusModal,
          side: BorderSide(
            color: SalimColors.border.withValues(alpha: 0.6),
            width: SalimSizes.borderWidth,
          ),
        ),
        titleTextStyle: SalimTypography.h2,
        contentTextStyle: SalimTypography.bodyMedium,
      ),

      // Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: SalimColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(SalimRadius.xl),
            topRight: Radius.circular(SalimRadius.xl),
          ),
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: SalimColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: SalimRadius.borderRadiusButton,
        ),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: SalimColors.border.withValues(alpha: 0.6),
        thickness: 2,
        space: 0,
      ),

      // Tab Bar
      tabBarTheme: TabBarTheme(
        labelColor: SalimColors.primary,
        unselectedLabelColor: SalimColors.textMuted,
        labelStyle: SalimTypography.labelLarge,
        unselectedLabelStyle: SalimTypography.bodyMedium,
        indicator: BoxDecoration(
          color: SalimColors.surface,
          borderRadius: SalimRadius.borderRadiusPill,
          boxShadow: SalimShadows.sm,
        ),
      ),

      // Navigation Rail
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: SalimColors.surface,
        selectedIconTheme: const IconThemeData(
          color: SalimColors.primary,
          size: SalimSizes.iconLarge,
        ),
        unselectedIconTheme: const IconThemeData(
          color: SalimColors.textMuted,
          size: SalimSizes.iconLarge,
        ),
        selectedLabelTextStyle: SalimTypography.labelMedium.copyWith(
          color: SalimColors.primary,
        ),
        unselectedLabelTextStyle: SalimTypography.labelMedium.copyWith(
          color: SalimColors.textMuted,
        ),
      ),

      // Drawer
      drawerTheme: const DrawerThemeData(
        backgroundColor: SalimColors.surface,
        elevation: 0,
        width: SalimSizes.sidebarWidth,
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: SalimTypography.h1.copyWith(fontSize: 32),
        displayMedium: SalimTypography.h1,
        displaySmall: SalimTypography.h2,
        headlineLarge: SalimTypography.h1,
        headlineMedium: SalimTypography.h2,
        headlineSmall: SalimTypography.h3,
        titleLarge: SalimTypography.h2,
        titleMedium: SalimTypography.h3,
        titleSmall: SalimTypography.h4,
        bodyLarge: SalimTypography.bodyLarge,
        bodyMedium: SalimTypography.bodyMedium,
        bodySmall: SalimTypography.bodySmall,
        labelLarge: SalimTypography.labelLarge,
        labelMedium: SalimTypography.labelMedium,
        labelSmall: SalimTypography.labelSmall,
      ),

      // Visual Density
      visualDensity: VisualDensity.standard,
    );
  }
}

// =============================================================================
// COMPONENT STYLES (for custom widgets)
// =============================================================================

/// Pre-defined box decorations for common components
class SalimDecorations {
  SalimDecorations._();

  // Card decoration
  static BoxDecoration get card => BoxDecoration(
        color: SalimColors.surface,
        borderRadius: SalimRadius.borderRadiusCard,
        border: Border.all(
          color: SalimColors.border.withValues(alpha: 0.6),
          width: SalimSizes.borderWidth,
        ),
      );

  // Card with shadow
  static BoxDecoration get cardElevated => BoxDecoration(
        color: SalimColors.surface,
        borderRadius: SalimRadius.borderRadiusCard,
        border: Border.all(
          color: SalimColors.border.withValues(alpha: 0.6),
          width: SalimSizes.borderWidth,
        ),
        boxShadow: SalimShadows.card,
      );

  // Card header/footer gradient
  static BoxDecoration get cardHeader => BoxDecoration(
        gradient: SalimColors.headerGradient,
        border: Border(
          bottom: BorderSide(
            color: SalimColors.border.withValues(alpha: 0.6),
            width: SalimSizes.borderWidth,
          ),
        ),
      );

  static BoxDecoration get cardFooter => BoxDecoration(
        gradient: SalimColors.headerGradient,
        border: Border(
          top: BorderSide(
            color: SalimColors.border.withValues(alpha: 0.6),
            width: SalimSizes.borderWidth,
          ),
        ),
      );

  // Input decoration
  static BoxDecoration get input => BoxDecoration(
        color: SalimColors.surface,
        borderRadius: SalimRadius.borderRadiusInput,
        border: Border.all(
          color: SalimColors.border.withValues(alpha: 0.6),
          width: SalimSizes.borderWidth,
        ),
        boxShadow: SalimShadows.input,
      );

  // Input focused
  static BoxDecoration get inputFocused => BoxDecoration(
        color: SalimColors.surface,
        borderRadius: SalimRadius.borderRadiusInput,
        border: Border.all(
          color: SalimColors.primary,
          width: SalimSizes.borderWidth,
        ),
      );

  // Input error
  static BoxDecoration get inputError => BoxDecoration(
        color: SalimColors.surface,
        borderRadius: SalimRadius.borderRadiusInput,
        border: Border.all(
          color: SalimColors.danger,
          width: SalimSizes.borderWidth,
        ),
      );

  // Modal decoration
  static BoxDecoration get modal => BoxDecoration(
        color: SalimColors.surface,
        borderRadius: SalimRadius.borderRadiusModal,
        border: Border.all(
          color: SalimColors.border.withValues(alpha: 0.6),
          width: SalimSizes.borderWidth,
        ),
        boxShadow: SalimShadows.modal,
      );

  // Sidebar menu item (inactive)
  static BoxDecoration get menuItemInactive => BoxDecoration(
        borderRadius: SalimRadius.borderRadiusButton,
      );

  // Sidebar menu item (active)
  static BoxDecoration get menuItemActive => BoxDecoration(
        color: SalimColors.primaryQuiet,
        borderRadius: SalimRadius.borderRadiusButton,
        boxShadow: SalimShadows.card,
      );

  // Badge decorations
  static BoxDecoration badgeSuccess = BoxDecoration(
    color: SalimColors.successSwatch.shade100,
    borderRadius: SalimRadius.borderRadiusPill,
    border: Border.all(
      color: SalimColors.successSwatch.shade200,
      width: SalimSizes.borderWidth,
    ),
  );

  static BoxDecoration badgeWarning = BoxDecoration(
    color: SalimColors.warningSwatch.shade100,
    borderRadius: SalimRadius.borderRadiusPill,
    border: Border.all(
      color: SalimColors.warningSwatch.shade200,
      width: SalimSizes.borderWidth,
    ),
  );

  static BoxDecoration badgeDanger = BoxDecoration(
    color: SalimColors.dangerSwatch.shade100,
    borderRadius: SalimRadius.borderRadiusPill,
    border: Border.all(
      color: SalimColors.dangerSwatch.shade200,
      width: SalimSizes.borderWidth,
    ),
  );

  static BoxDecoration badgeNeutral = BoxDecoration(
    color: SalimColors.surfaceAlt,
    borderRadius: SalimRadius.borderRadiusPill,
    border: Border.all(
      color: SalimColors.border,
      width: SalimSizes.borderWidth,
    ),
  );

  static BoxDecoration badgeAccent = BoxDecoration(
    color: SalimColors.primary.withValues(alpha: 0.1),
    borderRadius: SalimRadius.borderRadiusPill,
    border: Border.all(
      color: SalimColors.primary.withValues(alpha: 0.2),
      width: SalimSizes.borderWidth,
    ),
  );

  static BoxDecoration badgeInfo = BoxDecoration(
    color: SalimColors.infoSwatch.shade100,
    borderRadius: SalimRadius.borderRadiusPill,
    border: Border.all(
      color: SalimColors.infoSwatch.shade200,
      width: SalimSizes.borderWidth,
    ),
  );
}

// =============================================================================
// BUTTON STYLES (for custom button widgets)
// =============================================================================

/// Custom button style configurations
class SalimButtonStyles {
  SalimButtonStyles._();

  // Primary button style
  static ButtonStyle get primary => ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: SalimColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, SalimSizes.buttonHeightMd),
        padding: const EdgeInsets.symmetric(horizontal: SalimSpacing.lg),
        shape: RoundedRectangleBorder(
          borderRadius: SalimRadius.borderRadiusButton,
        ),
        textStyle: SalimTypography.buttonMedium,
      );

  // Secondary button style
  static ButtonStyle get secondary => OutlinedButton.styleFrom(
        elevation: 0,
        backgroundColor: SalimColors.surface,
        foregroundColor: SalimColors.textDeep,
        minimumSize: const Size(0, SalimSizes.buttonHeightMd),
        padding: const EdgeInsets.symmetric(horizontal: SalimSpacing.lg),
        shape: RoundedRectangleBorder(
          borderRadius: SalimRadius.borderRadiusButton,
        ),
        side: BorderSide(
          color: SalimColors.border.withValues(alpha: 0.6),
          width: SalimSizes.borderWidth,
        ),
        textStyle: SalimTypography.buttonMedium,
      );

  // Danger button style
  static ButtonStyle get danger => ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: SalimColors.danger,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, SalimSizes.buttonHeightMd),
        padding: const EdgeInsets.symmetric(horizontal: SalimSpacing.lg),
        shape: RoundedRectangleBorder(
          borderRadius: SalimRadius.borderRadiusButton,
        ),
        textStyle: SalimTypography.buttonMedium,
      );

  // Ghost button style
  static ButtonStyle get ghost => TextButton.styleFrom(
        foregroundColor: SalimColors.textDeep.withValues(alpha: 0.7),
        minimumSize: const Size(0, SalimSizes.buttonHeightMd),
        padding: const EdgeInsets.symmetric(horizontal: SalimSpacing.base),
        shape: RoundedRectangleBorder(
          borderRadius: SalimRadius.borderRadiusButton,
        ),
        textStyle: SalimTypography.buttonMedium,
      );

  // Link button style
  static ButtonStyle get link => TextButton.styleFrom(
        foregroundColor: SalimColors.primary,
        minimumSize: Size.zero,
        padding: EdgeInsets.zero,
        textStyle: SalimTypography.buttonMedium.copyWith(
          decoration: TextDecoration.underline,
          decorationColor: SalimColors.primary,
        ),
      );

  // Small variants
  static ButtonStyle get primarySmall => primary.copyWith(
        minimumSize: WidgetStateProperty.all(
          const Size(0, SalimSizes.buttonHeightSm),
        ),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: SalimSpacing.base),
        ),
        textStyle: WidgetStateProperty.all(SalimTypography.buttonSmall),
      );

  static ButtonStyle get secondarySmall => secondary.copyWith(
        minimumSize: WidgetStateProperty.all(
          const Size(0, SalimSizes.buttonHeightSm),
        ),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: SalimSpacing.base),
        ),
        textStyle: WidgetStateProperty.all(SalimTypography.buttonSmall),
      );

  // Large variants
  static ButtonStyle get primaryLarge => primary.copyWith(
        minimumSize: WidgetStateProperty.all(
          const Size(0, SalimSizes.buttonHeightLg),
        ),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: SalimSpacing.xl),
        ),
        textStyle: WidgetStateProperty.all(SalimTypography.buttonLarge),
      );

  static ButtonStyle get secondaryLarge => secondary.copyWith(
        minimumSize: WidgetStateProperty.all(
          const Size(0, SalimSizes.buttonHeightLg),
        ),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: SalimSpacing.xl),
        ),
        textStyle: WidgetStateProperty.all(SalimTypography.buttonLarge),
      );
}

// =============================================================================
// EXTENSIONS
// =============================================================================

/// Extension on BuildContext for easy access to design system
extension SalimThemeExtension on BuildContext {
  /// Get screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Get screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Check if device is mobile
  bool get isMobile => SalimBreakpoints.isMobile(this);

  /// Check if device is tablet
  bool get isTablet => SalimBreakpoints.isTablet(this);

  /// Check if device is desktop
  bool get isDesktop => SalimBreakpoints.isDesktop(this);

  /// Get responsive value based on screen size
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }

  /// Get responsive padding based on screen size
  EdgeInsets get responsivePadding => responsive(
        mobile: const EdgeInsets.all(SalimSpacing.base),
        tablet: const EdgeInsets.all(SalimSpacing.xl),
        desktop: const EdgeInsets.all(SalimSpacing.xxxl),
      );
}

// =============================================================================
// USAGE EXAMPLE
// =============================================================================
/*

// In your main.dart:
void main() {
  runApp(
    MaterialApp(
      theme: SalimTheme.lightTheme,
      home: MyHomePage(),
    ),
  );
}

// Using colors:
Container(
  color: SalimColors.primary,
  child: Text('Hello', style: TextStyle(color: SalimColors.textDeep)),
)

// Using typography:
Text('Heading', style: SalimTypography.h1),
Text('Body text', style: SalimTypography.bodyMedium),

// Using spacing:
Padding(
  padding: EdgeInsets.all(SalimSpacing.cardPaddingMd),
  child: Column(
    children: [
      SizedBox(height: SalimSpacing.xl),
      // content
    ],
  ),
)

// Using decorations:
Container(
  decoration: SalimDecorations.card,
  child: // card content
)

// Using button styles:
ElevatedButton(
  style: SalimButtonStyles.primary,
  onPressed: () {},
  child: Text('Submit'),
)

// Using responsive helpers:
Widget build(BuildContext context) {
  return Container(
    padding: context.responsivePadding,
    child: context.isMobile
      ? MobileLayout()
      : DesktopLayout(),
  );
}

*/
