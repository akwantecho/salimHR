import 'package:flutter/widgets.dart';

import '../../design_system/ds_provider.dart';
import '../../design_system/primitives/ds_button.dart';
import '../../design_system/primitives/ds_text.dart';
import '../i18n.dart';

/// Simple yes/no confirmation modal built on Navigator only (no Material), to
/// match the project's WidgetsApp. Returns true if confirmed, false/null
/// otherwise. Set [destructive] to colour the confirm button red.
Future<bool?> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  String? cancelLabel,
  bool destructive = false,
}) {
  return Navigator.of(context).push<bool>(
    PageRouteBuilder<bool>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: const Color(0x99000000),
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (ctx, _, _) => _ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
      ),
    ),
  );
}

class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? confirmLabel;
  final String? cancelLabel;

  const _ConfirmDialog({
    required this.title,
    required this.message,
    this.confirmLabel,
    this.cancelLabel,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    return Center(
      child: Padding(
        padding: EdgeInsetsDirectional.all(ds.spacing.lg),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: EdgeInsetsDirectional.all(ds.spacing.lg),
          decoration: BoxDecoration(
            color: ds.colors.surface,
            borderRadius: BorderRadius.circular(ds.radii.xLarge),
            boxShadow: ds.shadows.level2,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DSText(title, role: DSTextRole.headline),
              SizedBox(height: ds.spacing.sm),
              DSText(message,
                  role: DSTextRole.body, color: ds.colors.textSecondary),
              SizedBox(height: ds.spacing.lg),
              Row(
                children: [
                  Expanded(
                    child: DSButton(
                      label: cancelLabel ?? t('إلغاء', 'Cancel'),
                      variant: DSButtonVariant.ghost,
                      expanded: true,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  SizedBox(width: ds.spacing.sm),
                  Expanded(
                    child: DSButton(
                      label: confirmLabel ?? t('تأكيد', 'Confirm'),
                      variant: DSButtonVariant.primary,
                      expanded: true,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
