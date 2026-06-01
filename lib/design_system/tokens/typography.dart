import 'package:flutter/widgets.dart';

@immutable
class DSTypography {
  final TextStyle display;
  final TextStyle headline;
  final TextStyle title;
  final TextStyle body;
  final TextStyle caption;
  final TextStyle label;

  const DSTypography({
    required this.display,
    required this.headline,
    required this.title,
    required this.body,
    required this.caption,
    required this.label,
  });

  factory DSTypography.arabicDefault(Color primaryText, Color secondaryText) {
    const fontFallback = <String>[
      'NotoSansArabic',
      'NotoSans',
    ];

    const baseFont = 'Cairo';
    const double displaySize = 30; // 3xl
    const double headlineSize = 24; // 2xl
    const double titleSize = 18; // xl
    const double bodySize = 14; // base/sm
    const double captionSize = 12; // xs
    const double labelSize = 14; // sm

    return DSTypography(
      display: TextStyle(
        fontSize: displaySize,
        fontWeight: FontWeight.w600,
        height: 32 / displaySize,
        color: primaryText,
        fontFamily: baseFont,
        fontFamilyFallback: fontFallback,
        locale: const Locale('ar'),
      ),
      headline: TextStyle(
        fontSize: headlineSize,
        fontWeight: FontWeight.w600,
        height: 32 / headlineSize,
        color: primaryText,
        fontFamily: baseFont,
        fontFamilyFallback: fontFallback,
        locale: const Locale('ar'),
      ),
      title: TextStyle(
        fontSize: titleSize,
        fontWeight: FontWeight.w600,
        height: 26 / titleSize,
        color: primaryText,
        fontFamily: baseFont,
        fontFamilyFallback: fontFallback,
        locale: const Locale('ar'),
      ),
      body: TextStyle(
        fontSize: bodySize,
        fontWeight: FontWeight.w400,
        height: 22 / bodySize,
        color: secondaryText,
        fontFamily: baseFont,
        fontFamilyFallback: fontFallback,
        locale: const Locale('ar'),
      ),
      caption: TextStyle(
        fontSize: captionSize,
        fontWeight: FontWeight.w400,
        height: 18 / captionSize,
        color: secondaryText,
        fontFamily: baseFont,
        fontFamilyFallback: fontFallback,
        locale: const Locale('ar'),
      ),
      label: TextStyle(
        fontSize: labelSize,
        fontWeight: FontWeight.w700,
        height: 22 / labelSize,
        color: primaryText,
        fontFamily: baseFont,
        fontFamilyFallback: fontFallback,
        locale: const Locale('ar'),
      ),
    );
  }
}

enum DSTextRole { display, headline, title, body, caption, label }

extension DSTypographySelector on DSTypography {
  TextStyle resolve(DSTextRole role) {
    switch (role) {
      case DSTextRole.display:
        return display;
      case DSTextRole.headline:
        return headline;
      case DSTextRole.title:
        return title;
      case DSTextRole.body:
        return body;
      case DSTextRole.caption:
        return caption;
      case DSTextRole.label:
        return label;
    }
  }
}
