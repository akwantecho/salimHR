import 'package:equatable/equatable.dart';

/// A promotional banner shown in the specialist home carousel.
///
/// Shape is API-ready: it maps a Laravel-style `/api/banners` row so the
/// carousel can later be driven from the server's control panel without any
/// change to the UI. `color` is an optional accent used when [imageUrl] is null.
class PromoBanner extends Equatable {
  final int id;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final String? imageUrl;
  final String? linkUrl;

  /// Background accent used only when [imageUrl] is null. Null when the server
  /// sends no color (e.g. image banners) — the slide then shows just the image.
  final int? colorValue;
  final int sortOrder;
  final bool active;

  // ===== Display fields (admin-controlled, from /app/config) =====
  /// Horizontal alignment of the text + button: 'left' | 'center' | 'right'.
  /// Applied explicitly (not tied to app language direction).
  final String textAlign;

  /// Whether to draw a shadow under the slide.
  final bool shadow;

  /// Text colour (title/subtitle). Null → default (white).
  final int? textColorValue;

  /// Action button colour. Null → default.
  final int? buttonColorValue;

  /// Action button style: 'filled' | 'outline' | 'text'.
  final String buttonStyle;

  /// Button alignment: 'inherit' follows [textAlign]; otherwise 'left' |
  /// 'center' | 'right' positions the button independently of the text.
  final String buttonAlign;

  const PromoBanner({
    required this.id,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.imageUrl,
    this.linkUrl,
    this.colorValue,
    this.sortOrder = 0,
    this.active = true,
    this.textAlign = 'right',
    this.shadow = true,
    this.textColorValue,
    this.buttonColorValue,
    this.buttonStyle = 'filled',
    this.buttonAlign = 'inherit',
  });

  factory PromoBanner.fromJson(Map<String, dynamic> json) {
    return PromoBanner(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      actionLabel: json['action_label'] as String?,
      imageUrl: json['image_url'] as String?,
      linkUrl: json['link_url'] as String?,
      colorValue: _parseColor(json['color']),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      active: json['active'] as bool? ?? true,
      textAlign: (json['text_align'] as String?) ?? 'right',
      shadow: json['shadow'] as bool? ?? true,
      textColorValue: _parseColor(json['text_color']),
      buttonColorValue: _parseColor(json['button_color']),
      buttonStyle: (json['button_style'] as String?) ?? 'filled',
      buttonAlign: (json['button_align'] as String?) ?? 'inherit',
    );
  }

  /// Parses a `#RRGGBB`/`#AARRGGBB` hex string into an ARGB int, or null when
  /// the server sends no/invalid color (e.g. image banners have color = null).
  static int? _parseColor(dynamic raw) {
    if (raw is int) return raw;
    if (raw is! String || raw.isEmpty) return null;
    var hex = raw.replaceFirst('#', '').trim();
    if (hex.length == 6) hex = 'FF$hex';
    return int.tryParse(hex, radix: 16);
  }

  @override
  List<Object?> get props => [id, title, subtitle, actionLabel, imageUrl];
}
