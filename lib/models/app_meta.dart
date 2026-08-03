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

/// Admin-controlled update prompt, also from `GET /api/app/config` under
/// `update`. The app compares the installed build number against these.
class AppUpdateInfo extends Equatable {
  /// Newest available build. If the installed build is lower, a dismissible
  /// "update available" prompt is shown.
  final int? latestVersionCode;

  /// Minimum allowed build. If the installed build is lower, a blocking
  /// "must update" prompt is shown (no dismiss).
  final int? minVersionCode;

  final String? message;

  /// Where the update button sends the user (store page).
  final String? storeUrl;

  const AppUpdateInfo({
    this.latestVersionCode,
    this.minVersionCode,
    this.message,
    this.storeUrl,
  });

  static AppUpdateInfo? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    int? toInt(dynamic v) => v is int ? v : int.tryParse('${v ?? ''}');
    final info = AppUpdateInfo(
      latestVersionCode: toInt(json['latest_version_code']),
      minVersionCode: toInt(json['min_version_code']),
      message: (json['message'] as String?)?.trim(),
      storeUrl: (json['store_url'] as String?)?.trim(),
    );
    if (info.latestVersionCode == null && info.minVersionCode == null) {
      return null;
    }
    return info;
  }

  bool forceRequired(int current) =>
      minVersionCode != null && current < minVersionCode!;
  bool softAvailable(int current) =>
      latestVersionCode != null && current < latestVersionCode!;

  @override
  List<Object?> get props =>
      [latestVersionCode, minVersionCode, message, storeUrl];
}

/// Bundle of the admin-controlled app-open messages from `/app/config`.
class AppMeta {
  final AppNotice? notice;
  final AppUpdateInfo? update;
  const AppMeta({this.notice, this.update});
}
