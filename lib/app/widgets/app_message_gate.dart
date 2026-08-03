import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../design_system/ds_provider.dart';
import '../../design_system/primitives/ds_button.dart';
import '../../design_system/primitives/ds_text.dart';
import '../../models/models.dart';
import '../../services/api_provider.dart';
import '../app_state.dart';
import '../i18n.dart';

const _storage = FlutterSecureStorage();
const _kDismissedNotice = 'notice_dismissed_id';
const _kSkippedUpdate = 'update_skipped_code';

/// After login, fetch the admin-controlled app-open messages and show, in
/// order: a blocking "must update" prompt, else a dismissible "update
/// available" prompt, then a one-time announcement. Fails silent — a network
/// error never blocks the app.
Future<void> runAppMessageGate(BuildContext context) async {
  final meta = await context.hrService.fetchAppMeta(
    lang: AppScope.of(context).locale.languageCode,
  );
  if (!context.mounted) return;

  int current = 0;
  try {
    final info = await PackageInfo.fromPlatform();
    current = int.tryParse(info.buildNumber) ?? 0;
  } catch (_) {}
  if (!context.mounted) return;

  final update = meta.update;
  if (update != null) {
    // 1) Force update — blocking, cannot be dismissed.
    if (update.forceRequired(current)) {
      await _showUpdateDialog(context, update, force: true);
      return; // stay on the blocking dialog; skip the rest
    }
    // 2) Soft update — dismissible, remembered per version.
    if (update.softAvailable(current)) {
      final skipped = int.tryParse(await _storage.read(key: _kSkippedUpdate) ?? '');
      if (skipped == null || (update.latestVersionCode ?? 0) > skipped) {
        if (!context.mounted) return;
        final updated = await _showUpdateDialog(context, update, force: false);
        if (!updated) {
          await _storage.write(
              key: _kSkippedUpdate,
              value: '${update.latestVersionCode ?? 0}');
        }
      }
    }
  }

  // 3) Announcement — shown once per id.
  final notice = meta.notice;
  if (notice != null && context.mounted) {
    final dismissed = await _storage.read(key: _kDismissedNotice);
    if (notice.dismissible && dismissed == notice.id) return;
    if (!context.mounted) return;
    await _showNoticeDialog(context, notice);
    await _storage.write(key: _kDismissedNotice, value: notice.id);
  }
}

Color _toneColor(String type) {
  switch (type) {
    case 'warning':
      return const Color(0xFFF59E0B);
    case 'success':
      return const Color(0xFF059669);
    default:
      return const Color(0xFF3B82F6);
  }
}

Future<void> _openStore(String? url) async {
  if (url == null || url.isEmpty) return;
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Returns true if the user tapped "Update".
Future<bool> _showUpdateDialog(
  BuildContext context,
  AppUpdateInfo update, {
  required bool force,
}) async {
  final result = await Navigator.of(context).push<bool>(
    PageRouteBuilder<bool>(
      opaque: false,
      barrierDismissible: !force,
      barrierColor: const Color(0x99000000),
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (ctx, _, _) => _MessageCard(
        tone: const Color(0xFF059669),
        force: force,
        title: tr(ctx,
            ar: force ? 'تحديث مطلوب' : 'تحديث متوفّر',
            en: force ? 'Update required' : 'Update available'),
        message: update.message ??
            tr(ctx,
                ar: force
                    ? 'يجب تحديث التطبيق للمتابعة.'
                    : 'يتوفّر إصدار جديد من التطبيق.',
                en: force
                    ? 'You must update the app to continue.'
                    : 'A new version of the app is available.'),
        primaryLabel: tr(ctx, ar: 'تحديث الآن', en: 'Update now'),
        onPrimary: () async {
          await _openStore(update.storeUrl);
        },
        secondaryLabel:
            force ? null : tr(ctx, ar: 'لاحقاً', en: 'Later'),
      ),
    ),
  );
  return result ?? false;
}

Future<void> _showNoticeDialog(BuildContext context, AppNotice notice) {
  return Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: notice.dismissible,
      barrierColor: const Color(0x99000000),
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (ctx, _, _) => _MessageCard(
        tone: _toneColor(notice.type),
        force: !notice.dismissible,
        title: notice.title ?? tr(ctx, ar: 'إشعار', en: 'Notice'),
        message: notice.message,
        primaryLabel: tr(ctx, ar: 'حسناً', en: 'OK'),
        onPrimary: () async {},
        secondaryLabel: null,
      ),
    ),
  );
}

/// A centered message card used by both the update and announcement dialogs.
class _MessageCard extends StatelessWidget {
  final Color tone;
  final bool force;
  final String title;
  final String message;
  final String primaryLabel;
  final Future<void> Function() onPrimary;
  final String? secondaryLabel;

  const _MessageCard({
    required this.tone,
    required this.force,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final card = Center(
      child: Padding(
        padding: EdgeInsetsDirectional.all(ds.spacing.lg),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: EdgeInsetsDirectional.all(ds.spacing.lg),
          decoration: BoxDecoration(
            color: ds.colors.surface,
            borderRadius: BorderRadius.circular(ds.radii.xLarge),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 8,
                height: 8,
                margin: EdgeInsetsDirectional.only(bottom: ds.spacing.sm),
                decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
              ),
              DSText(title, role: DSTextRole.headline),
              SizedBox(height: ds.spacing.sm),
              DSText(message,
                  role: DSTextRole.body, color: ds.colors.textSecondary),
              SizedBox(height: ds.spacing.lg),
              DSButton(
                label: primaryLabel,
                variant: DSButtonVariant.primary,
                size: DSButtonSize.large,
                onPressed: () async {
                  await onPrimary();
                  // Force dialogs stay open (blocking); others close.
                  if (!force && context.mounted) {
                    Navigator.of(context).pop(true);
                  }
                },
              ),
              if (secondaryLabel != null) ...[
                SizedBox(height: ds.spacing.sm),
                DSButton(
                  label: secondaryLabel!,
                  variant: DSButtonVariant.ghost,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    // Block the Android back button when the dialog must not be dismissed.
    return PopScope(canPop: !force, child: card);
  }
}
