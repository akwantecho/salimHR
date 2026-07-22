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
  final int colorValue;
  final int sortOrder;
  final bool active;

  const PromoBanner({
    required this.id,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.imageUrl,
    required this.colorValue,
    this.sortOrder = 0,
    this.active = true,
  });

  factory PromoBanner.fromJson(Map<String, dynamic> json) {
    return PromoBanner(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      actionLabel: json['action_label'] as String?,
      imageUrl: json['image_url'] as String?,
      colorValue: _parseColor(json['color']),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      active: json['active'] as bool? ?? true,
    );
  }

  /// Parses a `#RRGGBB`/`#AARRGGBB` hex string into an ARGB int.
  /// Falls back to a neutral indigo when missing or malformed.
  static int _parseColor(dynamic raw) {
    const fallback = 0xFF6366F1;
    if (raw is int) return raw;
    if (raw is! String || raw.isEmpty) return fallback;
    var hex = raw.replaceFirst('#', '').trim();
    if (hex.length == 6) hex = 'FF$hex';
    final value = int.tryParse(hex, radix: 16);
    return value ?? fallback;
  }

  @override
  List<Object?> get props => [id, title, subtitle, actionLabel, imageUrl];
}
