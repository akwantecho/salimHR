import 'package:flutter/widgets.dart';

import '../../design_system/components/line_icons.dart';
import '../../design_system/ds_provider.dart';
import '../../design_system/primitives/ds_button.dart';
import '../../design_system/primitives/ds_text.dart';
import '../i18n.dart';

/// Shared UI helpers for the Receptionist shell (appointments / patients /
/// billing). Kept in one place so the screens stay consistent and thin.

/// Locale-aware money formatter (OMR, thousands separators).
String formatMoney(BuildContext context, double amount) {
  final formatted = amount.toStringAsFixed(3).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+\.)'),
        (m) => '${m[1]},',
      );
  return tr(context, ar: '$formatted ر.ع', en: 'OMR $formatted');
}

/// Colour for an appointment status chip.
Color appointmentStatusColor(String status) {
  switch (status) {
    case 'confirmed':
      return const Color(0xFF10B981);
    case 'checked_in':
      return const Color(0xFF6366F1);
    case 'completed':
      return const Color(0xFF0EA5E9);
    case 'cancelled':
      return const Color(0xFFEF4444);
    case 'no_show':
      return const Color(0xFFF59E0B);
    case 'booked':
    default:
      return const Color(0xFF64748B);
  }
}

/// Localised label for an appointment status.
String appointmentStatusLabel(BuildContext context, String status) {
  switch (status) {
    case 'confirmed':
      return tr(context, ar: 'مؤكد', en: 'Confirmed');
    case 'checked_in':
      return tr(context, ar: 'حضر', en: 'Checked in');
    case 'completed':
      return tr(context, ar: 'مكتمل', en: 'Completed');
    case 'cancelled':
      return tr(context, ar: 'ملغى', en: 'Cancelled');
    case 'no_show':
      return tr(context, ar: 'لم يحضر', en: 'No-show');
    case 'booked':
    default:
      return tr(context, ar: 'محجوز', en: 'Booked');
  }
}

/// Colour for an invoice status chip.
Color invoiceStatusColor(String status) {
  switch (status) {
    case 'paid':
      return const Color(0xFF10B981);
    case 'partially_paid':
      return const Color(0xFFF59E0B);
    case 'free':
      return const Color(0xFF6366F1);
    case 'void':
      return const Color(0xFF94A3B8);
    default:
      return const Color(0xFFEF4444); // draft/posted → outstanding
  }
}

String invoiceStatusLabel(BuildContext context, String status) {
  switch (status) {
    case 'paid':
      return tr(context, ar: 'مدفوع', en: 'Paid');
    case 'partially_paid':
      return tr(context, ar: 'مدفوع جزئياً', en: 'Partial');
    case 'free':
      return tr(context, ar: 'مجاني', en: 'Free');
    case 'void':
      return tr(context, ar: 'ملغاة', en: 'Void');
    case 'posted':
      return tr(context, ar: 'غير مدفوع', en: 'Unpaid');
    case 'draft':
    default:
      return tr(context, ar: 'مسودة', en: 'Draft');
  }
}

/// A labelled text input following the app's DS (raw EditableText, no Material).
class ReceptionField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool number;
  final int maxLines;

  const ReceptionField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.number = false,
    this.maxLines = 1,
  });

  @override
  State<ReceptionField> createState() => _ReceptionFieldState();
}

class _ReceptionFieldState extends State<ReceptionField> {
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DSText(widget.label, role: DSTextRole.label, color: ds.colors.textSecondary),
        SizedBox(height: ds.spacing.xs),
        Container(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: ds.spacing.md,
            vertical: ds.spacing.sm,
          ),
          decoration: BoxDecoration(
            color: ds.colors.surfaceAlt,
            borderRadius: BorderRadius.circular(ds.radii.large),
            border: Border.all(color: ds.colors.border),
          ),
          child: ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) => Stack(
              children: [
                if (widget.controller.text.isEmpty && widget.hint != null)
                  DSText(
                    widget.hint!,
                    role: DSTextRole.body,
                    color: ds.colors.textMuted,
                  ),
                EditableText(
                  controller: widget.controller,
                  focusNode: _focus,
                  style: ds.typography.body.copyWith(color: ds.colors.textPrimary),
                  cursorColor: ds.colors.primary,
                  backgroundCursorColor: ds.colors.textMuted,
                  keyboardType:
                      widget.number ? TextInputType.number : TextInputType.text,
                  maxLines: widget.maxLines,
                  minLines: widget.maxLines,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A simple pick-one chip row used for selecting a service/specialist/status.
class ReceptionChoiceChips<T> extends StatelessWidget {
  final List<T> options;
  final T? selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelect;

  const ReceptionChoiceChips({
    super.key,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Wrap(
      spacing: ds.spacing.sm,
      runSpacing: ds.spacing.sm,
      children: options.map((opt) {
        final isSel = opt == selected;
        return GestureDetector(
          onTap: () => onSelect(opt),
          child: Container(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: ds.spacing.md,
              vertical: ds.spacing.xs,
            ),
            decoration: BoxDecoration(
              color: isSel ? ds.colors.primary.withOpacity(0.15) : ds.colors.surface,
              borderRadius: BorderRadius.circular(ds.radii.pill),
              border: Border.all(
                color: isSel ? ds.colors.primary : ds.colors.border,
              ),
            ),
            child: DSText(
              labelOf(opt),
              role: DSTextRole.label,
              color: isSel ? ds.colors.primary : ds.colors.textSecondary,
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Full-canvas error view with retry.
class ReceptionErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const ReceptionErrorView({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DSLineIcon(
            type: LineIconType.bell,
            color: const Color(0xFFEF4444),
            size: ds.spacing.xl,
          ),
          SizedBox(height: ds.spacing.md),
          DSText(
            tr(context, ar: 'حدث خطأ', en: 'An error occurred'),
            role: DSTextRole.title,
            color: const Color(0xFFEF4444),
          ),
          SizedBox(height: ds.spacing.sm),
          DSText(error, role: DSTextRole.caption, color: ds.colors.textSecondary),
          SizedBox(height: ds.spacing.lg),
          DSButton(
            label: tr(context, ar: 'إعادة المحاولة', en: 'Retry'),
            onPressed: onRetry,
            variant: DSButtonVariant.primary,
          ),
        ],
      ),
    );
  }
}

/// Centered empty-state caption.
class ReceptionEmpty extends StatelessWidget {
  final String message;

  const ReceptionEmpty({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsetsDirectional.all(ds.spacing.lg),
        child: DSText(message, role: DSTextRole.caption, color: ds.colors.textSecondary),
      ),
    );
  }
}
