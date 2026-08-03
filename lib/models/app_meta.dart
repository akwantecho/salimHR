import 'package:equatable/equatable.dart';

/// An admin-controlled announcement shown when the app opens. Editable from the
/// backend so the message can change without shipping an app update. Delivered
/// inside `GET /api/app/config` under `announcement`.
class AppNotice extends Equatable {
  /// Stable id used to remember that the user dismissed this specific notice
  /// (so it isn't shown again). Change the id to re-show an updated notice.
  final String id;
  final String? title;
  final String message;

  /// Visual tone: info | warning | success.
  final String type;

  /// When false, the user cannot dismiss it (use sparingly).
  final bool dismissible;
  final bool active;

  const AppNotice({
    required this.id,
    this.title,
    required this.message,
    this.type = 'info',
    this.dismissible = true,
    this.active = true,
  });

  static AppNotice? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final message = (json['message'] ?? '').toString().trim();
    if (message.isEmpty) return null;
    final active = json['active'] as bool? ?? true;
    if (!active) return null;
    return AppNotice(
      id: (json['id'] ?? json['message']).toString(),
      title: (json['title'] as String?)?.trim(),
      message: message,
      type: (json['type'] as String?) ?? 'info',
      dismissible: json['dismissible'] as bool? ?? true,
      active: active,
    );
  }

  @override
  List<Object?> get props => [id, message, type];
}

/// Public app status from `GET /api/app/status` (version gate + maintenance).
/// Shape: `{version: {latest, min_supported, force_update, update_message,
/// android_url, ios_url}, maintenance: {enabled, message}}`.
class AppStatus extends Equatable {
  final String? latest;        // e.g. "1.1.0"
  final String? minSupported;  // e.g. "1.0.0" or null
  final bool forceUpdate;      // admin override to force everyone
  final String? updateMessage;
  final String? androidUrl;
  final String? iosUrl;
  final bool maintenanceEnabled;
  final String? maintenanceMessage;

  const AppStatus({
    this.latest,
    this.minSupported,
    this.forceUpdate = false,
    this.updateMessage,
    this.androidUrl,
    this.iosUrl,
    this.maintenanceEnabled = false,
    this.maintenanceMessage,
  });

  static AppStatus? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final v = (json['version'] as Map?)?.cast<String, dynamic>() ?? const {};
    final m = (json['maintenance'] as Map?)?.cast<String, dynamic>() ?? const {};
    return AppStatus(
      latest: (v['latest'] as String?)?.trim(),
      minSupported: (v['min_supported'] as String?)?.trim(),
      forceUpdate: v['force_update'] as bool? ?? false,
      updateMessage: (v['update_message'] as String?)?.trim(),
      androidUrl: (v['android_url'] as String?)?.trim(),
      iosUrl: (v['ios_url'] as String?)?.trim(),
      maintenanceEnabled: m['enabled'] as bool? ?? false,
      maintenanceMessage: (m['message'] as String?)?.trim(),
    );
  }

  /// Compare dotted version strings ("1.2.0"). Returns <0, 0, >0.
  static int compareVersions(String a, String b) {
    final pa = a.split('.').map((e) => int.tryParse(e.trim()) ?? 0).toList();
    final pb = b.split('.').map((e) => int.tryParse(e.trim()) ?? 0).toList();
    for (var i = 0; i < (pa.length > pb.length ? pa.length : pb.length); i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x - y;
    }
    return 0;
  }

  /// Blocking update needed: admin forced it, or the installed [current]
  /// version is below the minimum supported.
  bool forceRequired(String current) {
    if (forceUpdate) return true;
    if (minSupported != null && minSupported!.isNotEmpty) {
      return compareVersions(current, minSupported!) < 0;
    }
    return false;
  }

  /// A newer version exists (soft, dismissible prompt).
  bool softAvailable(String current) {
    if (latest == null || latest!.isEmpty) return false;
    return compareVersions(current, latest!) < 0;
  }

  @override
  List<Object?> get props =>
      [latest, minSupported, forceUpdate, maintenanceEnabled];
}

/// Bundle of the admin-controlled app-open signals.
class AppMeta {
  final AppNotice? notice;   // from /app/config
  final AppStatus? status;   // from /app/status
  const AppMeta({this.notice, this.status});
}
