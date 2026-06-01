import 'package:flutter/widgets.dart';

import '../../design_system/ds_provider.dart';
import '../../design_system/primitives/ds_button.dart';
import '../../design_system/primitives/ds_text.dart';
import '../i18n.dart';

/// Modal that asks the user for a free-text reason. Built on Navigator only
/// (no Material) so it works inside the WidgetsApp the project uses.
///
/// Returns the trimmed string on confirm, or null if dismissed/cancelled.
/// The confirm button stays disabled until the reason hits [minLength].
Future<String?> promptForReason(
  BuildContext context, {
  required String title,
  required String hint,
  String? confirmLabel,
  int minLength = 3,
}) {
  return Navigator.of(context).push<String>(
    PageRouteBuilder<String>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: const Color(0xCC000000),
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (ctx, _, __) => _ReasonPrompt(
        title: title,
        hint: hint,
        confirmLabel: confirmLabel,
        minLength: minLength,
      ),
    ),
  );
}

class _ReasonPrompt extends StatefulWidget {
  final String title;
  final String hint;
  final String? confirmLabel;
  final int minLength;

  const _ReasonPrompt({
    required this.title,
    required this.hint,
    required this.minLength,
    this.confirmLabel,
  });

  @override
  State<_ReasonPrompt> createState() => _ReasonPromptState();
}

class _ReasonPromptState extends State<_ReasonPrompt> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _value = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.text != _value) {
        setState(() => _value = _controller.text);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    final canConfirm = _value.trim().length >= widget.minLength;

    return Center(
      child: Padding(
        padding: EdgeInsetsDirectional.all(ds.spacing.lg),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
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
              DSText(widget.title, role: DSTextRole.headline),
              SizedBox(height: ds.spacing.sm),
              DSText(
                widget.hint,
                role: DSTextRole.caption,
                color: ds.colors.textSecondary,
              ),
              SizedBox(height: ds.spacing.sm),
              Container(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: ds.spacing.md,
                  vertical: ds.spacing.sm,
                ),
                decoration: BoxDecoration(
                  color: ds.colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(ds.radii.large),
                  border: Border.all(color: ds.colors.border, width: 1.5),
                ),
                child: EditableText(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: ds.typography.body.copyWith(color: ds.colors.textPrimary),
                  cursorColor: ds.colors.primary,
                  backgroundCursorColor: ds.colors.textMuted,
                  maxLines: 5,
                  minLines: 3,
                  textAlign: ds.textDirection == TextDirection.rtl
                      ? TextAlign.right
                      : TextAlign.left,
                ),
              ),
              SizedBox(height: ds.spacing.lg),
              Row(
                children: [
                  Expanded(
                    child: DSButton(
                      label: t('إلغاء', 'Cancel'),
                      variant: DSButtonVariant.ghost,
                      expanded: true,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  SizedBox(width: ds.spacing.sm),
                  Expanded(
                    child: DSButton(
                      label: widget.confirmLabel ?? t('تأكيد', 'Confirm'),
                      variant: DSButtonVariant.primary,
                      expanded: true,
                      onPressed: canConfirm
                          ? () => Navigator.of(context).pop(_value.trim())
                          : null,
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
