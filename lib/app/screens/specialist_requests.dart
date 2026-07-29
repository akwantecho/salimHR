import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../design_system/components/line_icons.dart';
import '../../design_system/ds_provider.dart';
import '../../design_system/primitives/ds_button.dart';
import '../../design_system/primitives/ds_card.dart';
import '../../design_system/primitives/ds_text.dart';
import '../../models/models.dart';
import '../../models/reception.dart';
import '../../services/api_provider.dart';
import '../../utils/numeric.dart';
import '../i18n.dart';
import '../widgets/attachment_picker.dart';
import 'specialist_leave_calendar.dart';

// ==================== ADD POPUP (BOTTOM SHEET) ====================

/// Animated bottom-sheet popup triggered by the center FAB. Presents the four
/// request entry points. Tapping one dismisses the popup and asks the host
/// (via [onSelect]) to navigate to the matching sub-screen.
class AddRequestPopup extends StatefulWidget {
  final ValueChanged<RequestKind> onSelect;
  final VoidCallback onDismiss;

  const AddRequestPopup({
    super.key,
    required this.onSelect,
    required this.onDismiss,
  });

  @override
  State<AddRequestPopup> createState() => _AddRequestPopupState();
}

enum RequestKind { leave, note, patientTransfer, loan }

class _AddRequestPopupState extends State<AddRequestPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _slide = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _close({RequestKind? selection}) async {
    await _ctrl.reverse();
    if (!mounted) return;
    if (selection != null) {
      widget.onSelect(selection);
    } else {
      widget.onDismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    final options = [
      _PopupOption(
        kind: RequestKind.leave,
        label: t('طلب إجازة', 'Leave Request'),
        sub: t('إجازة سنوية أو مرضية', 'Annual or sick leave'),
        icon: LineIconType.calendar,
        color: const Color(0xFF6366F1),
      ),
      _PopupOption(
        kind: RequestKind.note,
        label: t('ملاحظة', 'Note'),
        sub: t('إرسال ملاحظة للإدارة', 'Send a note to admin'),
        icon: LineIconType.chat,
        color: const Color(0xFF10B981),
      ),
      _PopupOption(
        kind: RequestKind.patientTransfer,
        label: t('طلب نقل مريض', 'Patient Transfer'),
        sub: t(
          'تحويل مريض لأخصائي آخر',
          'Transfer patient to another specialist',
        ),
        icon: LineIconType.heart,
        color: const Color(0xFFEF4444),
      ),
      _PopupOption(
        kind: RequestKind.loan,
        label: t('طلب سلفة', 'Loan Request'),
        sub: t('سلفة على الراتب', 'Salary advance'),
        icon: LineIconType.chart,
        color: const Color(0xFFF59E0B),
      ),
    ];

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Stack(
          children: [
            // Scrim
            Positioned.fill(
              child: GestureDetector(
                onTap: _close,
                child: Container(
                  color: const Color(
                    0xFF000000,
                  ).withValues(alpha: 0.45 * _fade.value),
                ),
              ),
            ),
            // Sheet
            PositionedDirectional(
              start: 0,
              end: 0,
              bottom: 0,
              child: Transform.translate(
                offset: Offset(0, (1 - _slide.value) * 400),
                child: Container(
                  decoration: BoxDecoration(
                    color: ds.colors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(ds.radii.xLarge),
                      topRight: Radius.circular(ds.radii.xLarge),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF000000).withValues(alpha: 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, -8),
                      ),
                    ],
                  ),
                  padding: EdgeInsetsDirectional.only(
                    start: ds.spacing.lg,
                    end: ds.spacing.lg,
                    top: ds.spacing.md,
                    bottom:
                        ds.spacing.xl +
                        MediaQuery.viewPaddingOf(context).bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: ds.colors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      SizedBox(height: ds.spacing.md),
                      DSText(
                        t('طلب جديد', 'New Request'),
                        role: DSTextRole.title,
                      ),
                      SizedBox(height: ds.spacing.xs),
                      DSText(
                        t('اختر نوع الطلب', 'Choose request type'),
                        role: DSTextRole.caption,
                        color: ds.colors.textSecondary,
                      ),
                      SizedBox(height: ds.spacing.lg),
                      for (var i = 0; i < options.length; i++) ...[
                        if (i > 0) SizedBox(height: ds.spacing.sm),
                        _PopupOptionTile(
                          option: options[i],
                          onTap: () => _close(selection: options[i].kind),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PopupOption {
  final RequestKind kind;
  final String label;
  final String sub;
  final LineIconType icon;
  final Color color;

  const _PopupOption({
    required this.kind,
    required this.label,
    required this.sub,
    required this.icon,
    required this.color,
  });
}

class _PopupOptionTile extends StatelessWidget {
  final _PopupOption option;
  final VoidCallback onTap;

  const _PopupOptionTile({required this.option, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: DSCard(
        padding: EdgeInsetsDirectional.all(ds.spacing.md),
        child: Row(
          children: [
            Container(
              width: ds.spacing.xl + ds.spacing.sm,
              height: ds.spacing.xl + ds.spacing.sm,
              decoration: BoxDecoration(
                color: option.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: DSLineIcon(
                  type: option.icon,
                  color: option.color,
                  size: ds.spacing.md + 4,
                ),
              ),
            ),
            SizedBox(width: ds.spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DSText(option.label, role: DSTextRole.title),
                  SizedBox(height: 2),
                  DSText(
                    option.sub,
                    role: DSTextRole.caption,
                    color: ds.colors.textSecondary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== SHARED FORM PIECES ====================

/// Page-level scaffold for any request form: title bar with back button,
/// scrollable body, success/error banner, primary submit button pinned to
/// bottom. Standardizes look-and-feel across the four request screens.
class RequestFormScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onBack;
  final List<Widget> children;
  final String submitLabel;
  final bool canSubmit;
  final bool submitting;
  final VoidCallback? onSubmit;
  final String? errorMessage;
  final String? successMessage;

  /// Hides the fixed bottom submit button — for forms that place their own
  /// submit button inline (e.g. directly under a text field).
  final bool hideSubmitButton;

  const RequestFormScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.onBack,
    required this.children,
    required this.submitLabel,
    required this.onSubmit,
    this.canSubmit = true,
    this.submitting = false,
    this.errorMessage,
    this.successMessage,
    this.hideSubmitButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Container(
      color: ds.colors.background,
      child: SafeArea(
        child: Padding(
          // Lift the form (incl. the submit button) above the keyboard.
          padding: EdgeInsetsDirectional.fromSTEB(
            ds.spacing.lg,
            ds.spacing.lg,
            ds.spacing.lg,
            ds.spacing.lg + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FormHeader(title: title, subtitle: subtitle, onBack: onBack),
              SizedBox(height: ds.spacing.lg),
              if (errorMessage != null) ...[
                _Banner(message: errorMessage!, color: const Color(0xFFEF4444)),
                SizedBox(height: ds.spacing.md),
              ],
              if (successMessage != null) ...[
                _Banner(
                  message: successMessage!,
                  color: const Color(0xFF10B981),
                ),
                SizedBox(height: ds.spacing.md),
              ],
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ),
              if (!hideSubmitButton) ...[
                SizedBox(height: ds.spacing.md),
                DSButton(
                  label: submitting
                      ? tr(context, ar: 'جاري الإرسال...', en: 'Submitting...')
                      : submitLabel,
                  onPressed: (canSubmit && !submitting) ? onSubmit : null,
                  variant: DSButtonVariant.primary,
                  size: DSButtonSize.large,
                  expanded: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FormHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onBack;

  const _FormHeader({required this.title, this.subtitle, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Row(
      children: [
        DSIconButton(
          onPressed: onBack,
          icon: DSLineIcon(
            type: LineIconType.arrowBack,
            color: ds.colors.textPrimary,
            size: ds.spacing.md,
          ),
        ),
        SizedBox(width: ds.spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DSText(title, role: DSTextRole.headline),
              if (subtitle != null) ...[
                SizedBox(height: 2),
                DSText(
                  subtitle!,
                  role: DSTextRole.caption,
                  color: ds.colors.textSecondary,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  final String message;
  final Color color;

  const _Banner({required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Container(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ds.radii.medium),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: DSText(message, role: DSTextRole.body, color: color, maxLines: 4),
    );
  }
}

/// Multi-line text input with a label, used for reason/details fields in the
/// request forms. Self-contained — does not depend on Material.
class MultilineFieldCard extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final int minLines;
  final int maxLines;
  final bool required;
  final TextInputType? keyboardType;

  const MultilineFieldCard({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.minLines = 3,
    this.maxLines = 6,
    this.required = false,
    this.keyboardType,
  });

  @override
  State<MultilineFieldCard> createState() => _MultilineFieldCardState();
}

class _MultilineFieldCardState extends State<MultilineFieldCard> {
  late final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final hasValue = widget.controller.text.isNotEmpty;
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final showHint = !hasValue && widget.controller.text.isEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DSText(
                  widget.label,
                  role: DSTextRole.label,
                  color: ds.colors.textSecondary,
                ),
                if (widget.required) ...[
                  SizedBox(width: 4),
                  DSText(
                    '*',
                    role: DSTextRole.label,
                    color: const Color(0xFFEF4444),
                  ),
                ],
              ],
            ),
            SizedBox(height: ds.spacing.xs),
            Container(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: ds.spacing.md,
                vertical: ds.spacing.sm + 2,
              ),
              decoration: BoxDecoration(
                color: ds.colors.surfaceAlt,
                borderRadius: BorderRadius.circular(ds.radii.large),
                border: Border.all(color: ds.colors.border, width: 1.5),
              ),
              child: Stack(
                children: [
                  if (showHint)
                    PositionedDirectional(
                      top: 0,
                      start: 0,
                      child: DSText(
                        widget.hint,
                        role: DSTextRole.body,
                        color: ds.colors.textMuted,
                      ),
                    ),
                  EditableText(
                    controller: widget.controller,
                    focusNode: _focus,
                    style: ds.typography.body.copyWith(
                      color: ds.colors.textPrimary,
                    ),
                    cursorColor: ds.colors.primary,
                    backgroundCursorColor: ds.colors.textMuted,
                    minLines: widget.minLines,
                    maxLines: widget.maxLines,
                    keyboardType:
                        widget.keyboardType ?? TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Single-line text input card. Used for subject / amount fields.
class SingleLineFieldCard extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool required;
  final TextInputType? keyboardType;
  final LineIconType? icon;

  const SingleLineFieldCard({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.required = false,
    this.keyboardType,
    this.icon,
  });

  @override
  State<SingleLineFieldCard> createState() => _SingleLineFieldCardState();
}

class _SingleLineFieldCardState extends State<SingleLineFieldCard> {
  late final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final showHint = widget.controller.text.isEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DSText(
                  widget.label,
                  role: DSTextRole.label,
                  color: ds.colors.textSecondary,
                ),
                if (widget.required) ...[
                  SizedBox(width: 4),
                  DSText(
                    '*',
                    role: DSTextRole.label,
                    color: const Color(0xFFEF4444),
                  ),
                ],
              ],
            ),
            SizedBox(height: ds.spacing.xs),
            Container(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: ds.spacing.md,
                vertical: ds.spacing.sm + 2,
              ),
              decoration: BoxDecoration(
                color: ds.colors.surfaceAlt,
                borderRadius: BorderRadius.circular(ds.radii.large),
                border: Border.all(color: ds.colors.border, width: 1.5),
              ),
              child: Row(
                children: [
                  if (widget.icon != null) ...[
                    DSLineIcon(
                      type: widget.icon!,
                      color: ds.colors.primary.withValues(alpha: 0.6),
                      size: ds.spacing.md,
                    ),
                    SizedBox(width: ds.spacing.sm),
                  ],
                  Expanded(
                    child: Stack(
                      children: [
                        if (showHint)
                          DSText(
                            widget.hint,
                            role: DSTextRole.body,
                            color: ds.colors.textMuted,
                          ),
                        EditableText(
                          controller: widget.controller,
                          focusNode: _focus,
                          style: ds.typography.body.copyWith(
                            color: ds.colors.textPrimary,
                          ),
                          cursorColor: ds.colors.primary,
                          backgroundCursorColor: ds.colors.textMuted,
                          maxLines: 1,
                          keyboardType: widget.keyboardType,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Inline date stepper. Tap +/- to adjust by one day. The label shows the
/// chosen date in YYYY-MM-DD format with a weekday hint. Lightweight
/// alternative to a full calendar picker (which would need Material).
class DateStepperField extends StatelessWidget {
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final DateTime? minDate;

  const DateStepperField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.minDate,
  });

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static const _weekdaysAr = [
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];

  static const _weekdaysEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  void _adjust(int delta) {
    final next = value.add(Duration(days: delta));
    if (minDate != null && next.isBefore(minDate!)) return;
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    final weekday = t(
      _weekdaysAr[value.weekday - 1],
      _weekdaysEn[value.weekday - 1],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DSText(label, role: DSTextRole.label, color: ds.colors.textSecondary),
        SizedBox(height: ds.spacing.xs),
        Container(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: ds.spacing.md,
            vertical: ds.spacing.sm + 2,
          ),
          decoration: BoxDecoration(
            color: ds.colors.surfaceAlt,
            borderRadius: BorderRadius.circular(ds.radii.large),
            border: Border.all(color: ds.colors.border, width: 1.5),
          ),
          child: Row(
            children: [
              _StepBtn(label: '-', onTap: () => _adjust(-1)),
              SizedBox(width: ds.spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    DSText(_fmt(value), role: DSTextRole.title),
                    SizedBox(height: 2),
                    DSText(
                      weekday,
                      role: DSTextRole.caption,
                      color: ds.colors.textSecondary,
                    ),
                  ],
                ),
              ),
              SizedBox(width: ds.spacing.sm),
              _StepBtn(label: '+', onTap: () => _adjust(1)),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _StepBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: ds.spacing.xl,
        height: ds.spacing.xl,
        decoration: BoxDecoration(
          color: ds.colors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: ds.colors.primary.withValues(alpha: 0.4)),
        ),
        child: Center(
          child: DSText(
            label,
            role: DSTextRole.title,
            color: ds.colors.primary,
          ),
        ),
      ),
    );
  }
}

/// Inline single-select chip group used for leave type, etc. Avoids the
/// material dropdown (the app uses WidgetsApp, no Material).
class ChoiceChipsField<T> extends StatelessWidget {
  final String label;
  final List<T> options;
  final String Function(T) labelOf;
  final T? selected;
  final ValueChanged<T> onSelect;

  const ChoiceChipsField({
    super.key,
    required this.label,
    required this.options,
    required this.labelOf,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DSText(label, role: DSTextRole.label, color: ds.colors.textSecondary),
        SizedBox(height: ds.spacing.xs),
        Wrap(
          spacing: ds.spacing.sm,
          runSpacing: ds.spacing.sm,
          children: [
            for (final opt in options)
              GestureDetector(
                onTap: () => onSelect(opt),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: ds.animation.fast,
                  padding: EdgeInsetsDirectional.symmetric(
                    horizontal: ds.spacing.md,
                    vertical: ds.spacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: selected == opt
                        ? ds.colors.primary
                        : ds.colors.surfaceAlt,
                    borderRadius: BorderRadius.circular(ds.radii.pill),
                    border: Border.all(
                      color: selected == opt
                          ? ds.colors.primary
                          : ds.colors.border,
                    ),
                  ),
                  child: DSText(
                    labelOf(opt),
                    role: DSTextRole.label,
                    color: selected == opt
                        ? ds.colors.surface
                        : ds.colors.textPrimary,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ==================== LEAVE REQUEST SCREEN ====================

class LeaveRequestScreen extends StatefulWidget {
  final VoidCallback onBack;

  const LeaveRequestScreen({super.key, required this.onBack});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  final _reasonCtrl = TextEditingController();
  List<LeaveType> _types = [];
  LeaveType? _selectedType;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  bool _loadingTypes = true;
  bool _submitting = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTypes());
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTypes() async {
    final hr = context.hrService;
    final types = await hr.fetchMyLeaveTypes();
    if (!mounted) return;
    setState(() {
      _types = types;
      _selectedType = types.isNotEmpty ? types.first : null;
      _loadingTypes = false;
    });
  }

  int get _totalDays => _endDate.difference(_startDate).inDays + 1;

  bool get _canSubmit =>
      _selectedType != null && !_endDate.isBefore(_startDate);

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _submitting = true;
      _error = null;
      _success = null;
    });

    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    final ok = await context.hrService.submitLeaveRequest(
      leaveTypeId: _selectedType!.id,
      startDate: fmt(_startDate),
      endDate: fmt(_endDate),
      reason: _reasonCtrl.text.trim().isEmpty ? null : _reasonCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _submitting = false;
      if (ok) {
        _success = tr(
          context,
          ar: 'تم إرسال طلب الإجازة بنجاح',
          en: 'Leave request submitted',
        );
        _reasonCtrl.clear();
      } else {
        _error =
            context.hrService.error ??
            tr(context, ar: 'فشل الإرسال', en: 'Submit failed');
      }
    });
  }

  Color _accentForSelected(BuildContext context) {
    final ds = DSProvider.of(context);
    final hex = _selectedType?.color;
    if (hex == null || hex.isEmpty) return ds.colors.primary;
    final cleaned = hex.startsWith('#') ? hex.substring(1) : hex;
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return ds.colors.primary;
    return Color(value | 0xFF000000);
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    final accent = _accentForSelected(context);

    return RequestFormScaffold(
      title: t('طلب إجازة', 'Leave Request'),
      subtitle: t('املأ بيانات الطلب وأرسله للمدير', 'Fill in your request'),
      onBack: widget.onBack,
      submitLabel: t('إرسال الطلب', 'Submit Request'),
      onSubmit: _submit,
      canSubmit: _canSubmit,
      submitting: _submitting,
      errorMessage: _error,
      successMessage: _success,
      children: [
        if (_loadingTypes)
          Padding(
            padding: EdgeInsetsDirectional.all(ds.spacing.md),
            child: DSText(
              t('جاري تحميل أنواع الإجازات...', 'Loading leave types...'),
              role: DSTextRole.caption,
              color: ds.colors.textSecondary,
            ),
          )
        else if (_types.isEmpty)
          DSCard(
            child: DSText(
              t(
                'لا توجد أنواع إجازات متاحة. اطلب من الإدارة إضافتها.',
                'No leave types available. Ask admin to add them.',
              ),
              role: DSTextRole.body,
              color: ds.colors.textSecondary,
            ),
          )
        else ...[
          ChoiceChipsField<LeaveType>(
            label: t('نوع الإجازة', 'Leave Type'),
            options: _types,
            labelOf: (lt) => lt.displayName(),
            selected: _selectedType,
            onSelect: (lt) => setState(() => _selectedType = lt),
          ),
          if (_selectedType != null) ...[
            SizedBox(height: ds.spacing.sm),
            _LeaveTypeDetailCard(type: _selectedType!, accent: accent),
          ],
        ],
        SizedBox(height: ds.spacing.lg),
        DSText(
          t('اختر الفترة', 'Pick the range'),
          role: DSTextRole.label,
          color: ds.colors.textSecondary,
        ),
        SizedBox(height: ds.spacing.xs),
        MonthRangeCalendar(
          rangeStart: _startDate,
          rangeEnd: _endDate,
          minDate: DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
          ),
          accentColor: accent,
          onRangeChanged: (start, end) {
            setState(() {
              _startDate = start;
              _endDate = end;
            });
          },
        ),
        if (_selectedType?.maxDaysPerYear != null &&
            _totalDays > _selectedType!.maxDaysPerYear!) ...[
          SizedBox(height: ds.spacing.sm),
          Container(
            padding: EdgeInsetsDirectional.all(ds.spacing.sm),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(ds.radii.medium),
              border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
              ),
            ),
            child: DSText(
              t(
                'تنبيه: عدد الأيام يتجاوز الحد السنوي (${_selectedType!.maxDaysPerYear} يوم).',
                'Warning: Days exceed annual limit (${_selectedType!.maxDaysPerYear} days).',
              ),
              role: DSTextRole.caption,
              color: const Color(0xFFD97706),
              maxLines: 2,
            ),
          ),
        ],
        SizedBox(height: ds.spacing.lg),
        MultilineFieldCard(
          label: t('السبب (اختياري)', 'Reason (optional)'),
          hint: t('اكتب سبب الإجازة...', 'Enter the reason...'),
          controller: _reasonCtrl,
          minLines: 3,
          maxLines: 6,
        ),
      ],
    );
  }
}

/// Detail card for the currently-selected leave type. Shows max days,
/// paid/unpaid badge, approval requirement, and description. The accent color
/// is driven by the type's stored color so each type feels visually distinct.
class _LeaveTypeDetailCard extends StatelessWidget {
  final LeaveType type;
  final Color accent;

  const _LeaveTypeDetailCard({required this.type, required this.accent});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    final chips = <Widget>[
      _Chip(
        label: type.isPaid ? t('مدفوعة', 'Paid') : t('بدون راتب', 'Unpaid'),
        color: type.isPaid ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
      ),
      if (type.maxDaysPerYear != null)
        _Chip(
          label: t(
            'حتى ${type.maxDaysPerYear} يوم/سنة',
            'Up to ${type.maxDaysPerYear} d/yr',
          ),
          color: accent,
        ),
      if (type.requiresApproval)
        _Chip(
          label: t('يتطلب موافقة', 'Needs approval'),
          color: const Color(0xFF6366F1),
        ),
    ];

    return Container(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(ds.radii.large),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: ds.spacing.md,
                height: ds.spacing.md,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: ds.spacing.sm),
              Expanded(
                child: DSText(type.displayName(), role: DSTextRole.title),
              ),
            ],
          ),
          if (type.description != null && type.description!.isNotEmpty) ...[
            SizedBox(height: ds.spacing.xs),
            DSText(
              type.description!,
              role: DSTextRole.caption,
              color: ds.colors.textSecondary,
              maxLines: 3,
            ),
          ],
          SizedBox(height: ds.spacing.sm),
          Wrap(
            spacing: ds.spacing.xs,
            runSpacing: ds.spacing.xs,
            children: chips,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: ds.spacing.sm,
        vertical: ds.spacing.xs / 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(ds.radii.pill),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: DSText(label, role: DSTextRole.caption, color: color),
    );
  }
}

/// A lightweight dropdown/select field that matches the app's Material-free
/// design. Tapping the field expands an inline list of [options]; picking one
/// collapses it and reports the choice via [onChanged].
class SelectFieldCard extends StatefulWidget {
  final String label;
  final String hint;
  final List<String> options;
  final String? value;
  final ValueChanged<String> onChanged;
  final bool required;
  final LineIconType? icon;

  const SelectFieldCard({
    super.key,
    required this.label,
    required this.hint,
    required this.options,
    required this.value,
    required this.onChanged,
    this.required = false,
    this.icon,
  });

  @override
  State<SelectFieldCard> createState() => _SelectFieldCardState();
}

class _SelectFieldCardState extends State<SelectFieldCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final hasValue = widget.value != null && widget.value!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            DSText(
              widget.label,
              role: DSTextRole.label,
              color: ds.colors.textSecondary,
            ),
            if (widget.required) ...[
              SizedBox(width: 4),
              DSText(
                '*',
                role: DSTextRole.label,
                color: const Color(0xFFEF4444),
              ),
            ],
          ],
        ),
        SizedBox(height: ds.spacing.xs),
        // Selected value / trigger
        GestureDetector(
          onTap: () => setState(() => _open = !_open),
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: ds.spacing.md,
              vertical: ds.spacing.sm + 2,
            ),
            decoration: BoxDecoration(
              color: ds.colors.surfaceAlt,
              borderRadius: BorderRadius.circular(ds.radii.large),
              border: Border.all(
                color: _open ? ds.colors.primary : ds.colors.border,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                if (widget.icon != null) ...[
                  DSLineIcon(
                    type: widget.icon!,
                    color: ds.colors.primary.withValues(alpha: 0.6),
                    size: ds.spacing.md,
                  ),
                  SizedBox(width: ds.spacing.sm),
                ],
                Expanded(
                  child: DSText(
                    hasValue ? widget.value! : widget.hint,
                    role: DSTextRole.body,
                    color: hasValue
                        ? ds.colors.textPrimary
                        : ds.colors.textMuted,
                  ),
                ),
                _Caret(open: _open),
              ],
            ),
          ),
        ),
        // Expanded options
        if (_open) ...[
          SizedBox(height: ds.spacing.xs),
          Container(
            decoration: BoxDecoration(
              color: ds.colors.surfaceAlt,
              borderRadius: BorderRadius.circular(ds.radii.large),
              border: Border.all(color: ds.colors.border, width: 1.5),
            ),
            child: Column(
              children: [
                for (var i = 0; i < widget.options.length; i++)
                  GestureDetector(
                    onTap: () {
                      widget.onChanged(widget.options[i]);
                      setState(() => _open = false);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsetsDirectional.symmetric(
                        horizontal: ds.spacing.md,
                        vertical: ds.spacing.sm + 2,
                      ),
                      decoration: BoxDecoration(
                        border: i == 0
                            ? null
                            : Border(
                                top: BorderSide(
                                  color: ds.colors.border.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: DSText(
                              widget.options[i],
                              role: DSTextRole.body,
                              color: widget.value == widget.options[i]
                                  ? ds.colors.primary
                                  : ds.colors.textPrimary,
                            ),
                          ),
                          if (widget.value == widget.options[i])
                            DSText(
                              '✓',
                              role: DSTextRole.title,
                              color: ds.colors.primary,
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Small chevron that flips when its parent select is open.
class _Caret extends StatelessWidget {
  final bool open;

  const _Caret({required this.open});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return AnimatedRotation(
      turns: open ? 0.5 : 0,
      duration: const Duration(milliseconds: 200),
      child: DSText(
        '⌄',
        role: DSTextRole.title,
        color: ds.colors.textMuted,
      ),
    );
  }
}

// ==================== NOTE REQUEST SCREEN ====================

class NoteRequestScreen extends StatefulWidget {
  final VoidCallback onBack;

  const NoteRequestScreen({super.key, required this.onBack});

  @override
  State<NoteRequestScreen> createState() => _NoteRequestScreenState();
}

class _NoteRequestScreenState extends State<NoteRequestScreen> {
  final _noteCtrl = TextEditingController();
  String? _category;
  bool _submitting = false;
  String? _error;
  String? _success;
  PickedAttachment? _attachment;

  Future<void> _attach() async {
    final picked = await pickAttachment(context);
    if (picked != null && mounted) setState(() => _attachment = picked);
  }

  /// Message categories the user picks from before writing the body.
  static const List<(String ar, String en)> _categories = [
    ('ملاحظة', 'Note'),
    ('شكوى', 'Complaint'),
    ('طلب', 'Request'),
    ('استفسار', 'Inquiry'),
    ('مقترح', 'Suggestion'),
  ];

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _category != null && _noteCtrl.text.trim().length >= 3;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _submitting = true;
      _error = null;
      _success = null;
    });
    // Prepend the chosen category so it reaches the admin with the message.
    final body = '[$_category] ${_noteCtrl.text.trim()}';
    final ok = await context.hrService.sendMyNote(
      body,
      fileBytes: _attachment?.bytes,
      filename: _attachment?.filename,
    );
    if (!mounted) return;
    setState(() {
      _submitting = false;
      if (ok) {
        _success = tr(
          context,
          ar: 'تم إرسال الرسالة بنجاح',
          en: 'Message sent successfully',
        );
        _noteCtrl.clear();
        _category = null;
        _attachment = null;
      } else {
        _error =
            context.hrService.error ??
            tr(context, ar: 'فشل الإرسال', en: 'Send failed');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final isArabic = tr(context, ar: 'ar', en: 'en') == 'ar';
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    final options = [
      for (final c in _categories) isArabic ? c.$1 : c.$2,
    ];
    return ListenableBuilder(
      listenable: _noteCtrl,
      builder: (context, _) => RequestFormScaffold(
        title: t('رسالة جديدة', 'New Message'),
        subtitle: t('إرسال رسالة للإدارة', 'Send a message to admin'),
        onBack: widget.onBack,
        submitLabel: t('إرسال', 'Send'),
        canSubmit: _canSubmit,
        submitting: _submitting,
        onSubmit: _submit,
        errorMessage: _error,
        successMessage: _success,
        hideSubmitButton: true,
        children: [
          SelectFieldCard(
            label: t('نوع الرسالة', 'Message Type'),
            hint: t('اختر النوع', 'Choose a type'),
            options: options,
            value: _category,
            onChanged: (v) => setState(() => _category = v),
            required: true,
            icon: LineIconType.bookmark,
          ),
          SizedBox(height: ds.spacing.lg),
          MultilineFieldCard(
            label: t('نص الرسالة', 'Message Body'),
            hint: t('اكتب رسالتك هنا...', 'Write your message here...'),
            controller: _noteCtrl,
            required: true,
            minLines: 6,
            maxLines: 10,
          ),
          SizedBox(height: ds.spacing.md),
          AttachmentField(
            attachment: _attachment,
            onAttach: _attach,
            onRemove: () => setState(() => _attachment = null),
          ),
          // Send button sits directly under the message box (not pinned to the
          // bottom of the page).
          SizedBox(height: ds.spacing.md),
          DSButton(
            label: _submitting
                ? t('جاري الإرسال...', 'Submitting...')
                : t('إرسال', 'Send'),
            onPressed: (_canSubmit && !_submitting) ? _submit : null,
            variant: DSButtonVariant.primary,
            size: DSButtonSize.large,
            expanded: true,
          ),
        ],
      ),
    );
  }
}

// ==================== PATIENT TRANSFER REQUEST ====================

class PatientTransferRequestScreen extends StatefulWidget {
  final VoidCallback onBack;

  const PatientTransferRequestScreen({super.key, required this.onBack});

  @override
  State<PatientTransferRequestScreen> createState() =>
      _PatientTransferRequestScreenState();
}

class _PatientTransferRequestScreenState
    extends State<PatientTransferRequestScreen> {
  final _searchCtrl = TextEditingController();
  final _detailsCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;
  String? _success;

  List<Patient> _results = [];
  Patient? _selectedPatient;
  bool _searching = false;

  List<NamedRef> _specialists = [];
  NamedRef? _selectedSpecialist;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSpecialists());
  }

  Future<void> _loadSpecialists() async {
    final s = await context.receptionService.fetchSpecialists();
    if (mounted) setState(() => _specialists = s);
  }

  void _onSearchChanged() {
    if (_selectedPatient != null) setState(() => _selectedPatient = null);
    final q = _searchCtrl.text.trim();
    if (q.length < 2) {
      setState(() => _results = []);
      return;
    }
    _search(q);
  }

  Future<void> _search(String q) async {
    setState(() => _searching = true);
    final r = await context.receptionService.searchPatients(q);
    if (!mounted || _searchCtrl.text.trim() != q) return;
    setState(() {
      _results = r;
      _searching = false;
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _detailsCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _selectedPatient != null &&
      _selectedSpecialist != null &&
      _detailsCtrl.text.trim().length >= 3;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _submitting = true;
      _error = null;
      _success = null;
    });
    final details =
        '${tr(context, ar: 'نقل إلى', en: 'Transfer to')}: ${_selectedSpecialist!.name}\n${_detailsCtrl.text.trim()}';
    final ok = await context.hrService.submitEmployeeRequest(
      type: 'patient_transfer',
      subject: _selectedPatient!.name,
      details: details,
      patientId: _selectedPatient!.id,
      toSpecialistId: _selectedSpecialist!.id,
    );
    if (!mounted) return;
    setState(() {
      _submitting = false;
      if (ok) {
        _success = tr(context,
            ar: 'تم إرسال طلب النقل بنجاح', en: 'Transfer request submitted');
        _searchCtrl.clear();
        _detailsCtrl.clear();
        _selectedPatient = null;
        _selectedSpecialist = null;
        _results = [];
      } else {
        _error = context.hrService.error ??
            tr(context, ar: 'فشل الإرسال', en: 'Submit failed');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    final showResults =
        _selectedPatient == null && _searchCtrl.text.trim().length >= 2;

    return ListenableBuilder(
      listenable: Listenable.merge([_searchCtrl, _detailsCtrl]),
      builder: (context, _) => RequestFormScaffold(
        title: t('طلب نقل مريض', 'Patient Transfer'),
        subtitle: t('تحويل مريض لأخصائي آخر', 'Transfer to another specialist'),
        onBack: widget.onBack,
        submitLabel: t('إرسال الطلب', 'Submit Request'),
        canSubmit: _canSubmit,
        submitting: _submitting,
        onSubmit: _submit,
        errorMessage: _error,
        successMessage: _success,
        children: [
          SingleLineFieldCard(
            label: t('المريض', 'Patient'),
            hint: t('ابحث باسم أو رقم المريض', 'Search by name or file'),
            controller: _searchCtrl,
            required: true,
            icon: LineIconType.heart,
          ),
          if (_selectedPatient != null) ...[
            SizedBox(height: ds.spacing.sm),
            _TransferSelected(
              label:
                  '${_selectedPatient!.name}${_selectedPatient!.fileNumber != null ? ' · ${_selectedPatient!.fileNumber}' : ''}',
              onClear: () {
                _searchCtrl.clear();
                setState(() => _selectedPatient = null);
              },
            ),
          ] else if (showResults) ...[
            SizedBox(height: ds.spacing.sm),
            if (_searching)
              DSText(t('جارٍ البحث...', 'Searching...'),
                  role: DSTextRole.caption, color: ds.colors.textSecondary)
            else if (_results.isEmpty)
              DSText(t('لا نتائج', 'No results'),
                  role: DSTextRole.caption, color: ds.colors.textMuted)
            else
              for (final p in _results.take(8))
                _TransferResult(
                  label:
                      '${p.name}${p.fileNumber != null ? ' · ${p.fileNumber}' : ''}',
                  onTap: () => setState(() {
                    _selectedPatient = p;
                    _results = [];
                  }),
                ),
          ],
          SizedBox(height: ds.spacing.lg),
          DSText(t('نقل إلى أخصائي', 'Transfer to specialist'),
              role: DSTextRole.label, color: ds.colors.textSecondary),
          SizedBox(height: ds.spacing.xs),
          if (_specialists.isEmpty)
            DSText(t('جارٍ التحميل...', 'Loading...'),
                role: DSTextRole.caption, color: ds.colors.textSecondary)
          else
            Wrap(
              spacing: ds.spacing.xs,
              runSpacing: ds.spacing.xs,
              children: [
                for (final s in _specialists)
                  GestureDetector(
                    onTap: () => setState(() => _selectedSpecialist = s),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: EdgeInsetsDirectional.symmetric(
                          horizontal: ds.spacing.md, vertical: ds.spacing.xs),
                      decoration: BoxDecoration(
                        color: _selectedSpecialist?.id == s.id
                            ? ds.colors.primary
                            : ds.colors.surfaceAlt,
                        borderRadius: BorderRadius.circular(ds.radii.pill),
                        border: Border.all(color: ds.colors.border),
                      ),
                      child: DSText(s.name,
                          role: DSTextRole.caption,
                          color: _selectedSpecialist?.id == s.id
                              ? const Color(0xFFFFFFFF)
                              : ds.colors.textPrimary),
                    ),
                  ),
              ],
            ),
          SizedBox(height: ds.spacing.lg),
          MultilineFieldCard(
            label: t('سبب النقل', 'Reason'),
            hint: t('سبب النقل وملاحظات...', 'Reason and notes...'),
            controller: _detailsCtrl,
            required: true,
            minLines: 3,
            maxLines: 6,
          ),
        ],
      ),
    );
  }
}

class _TransferSelected extends StatelessWidget {
  final String label;
  final VoidCallback onClear;
  const _TransferSelected({required this.label, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Container(
      padding: EdgeInsetsDirectional.all(ds.spacing.sm),
      decoration: BoxDecoration(
        color: ds.colors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ds.radii.medium),
        border: Border.all(color: ds.colors.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          DSLineIcon(
              type: LineIconType.heart,
              color: ds.colors.primary,
              size: ds.spacing.md),
          SizedBox(width: ds.spacing.sm),
          Expanded(child: DSText(label, role: DSTextRole.label, maxLines: 1)),
          GestureDetector(
            onTap: onClear,
            behavior: HitTestBehavior.opaque,
            child: DSText('✕',
                role: DSTextRole.caption, color: ds.colors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _TransferResult extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TransferResult({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsetsDirectional.only(bottom: ds.spacing.xs),
        padding: EdgeInsetsDirectional.all(ds.spacing.sm),
        decoration: BoxDecoration(
          color: ds.colors.surfaceAlt,
          borderRadius: BorderRadius.circular(ds.radii.medium),
          border: Border.all(color: ds.colors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            DSLineIcon(
                type: LineIconType.search,
                color: ds.colors.textMuted,
                size: ds.spacing.md),
            SizedBox(width: ds.spacing.sm),
            Expanded(child: DSText(label, role: DSTextRole.body, maxLines: 1)),
          ],
        ),
      ),
    );
  }
}

// ==================== LOAN REQUEST SCREEN ====================

class LoanRequestScreen extends StatefulWidget {
  final VoidCallback onBack;

  const LoanRequestScreen({super.key, required this.onBack});

  @override
  State<LoanRequestScreen> createState() => _LoanRequestScreenState();
}

class _LoanRequestScreenState extends State<LoanRequestScreen> {
  final _amountCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  double? get _amount {
    // Normalise Arabic-Indic / Persian digits and separators to ASCII so an
    // amount typed on an Arabic keyboard (e.g. ٣٠٠) still parses.
    final raw = normalizeNumeric(_amountCtrl.text);
    return double.tryParse(raw);
  }

  bool get _canSubmit =>
      _amount != null && _amount! > 0 && _reasonCtrl.text.trim().length >= 5;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _submitting = true;
      _error = null;
      _success = null;
    });
    final ok = await context.hrService.submitEmployeeRequest(
      type: 'loan',
      details: _reasonCtrl.text.trim(),
      amount: _amount,
    );
    if (!mounted) return;
    setState(() {
      _submitting = false;
      if (ok) {
        _success = tr(
          context,
          ar: 'تم إرسال طلب السلفة بنجاح',
          en: 'Loan request submitted',
        );
        _amountCtrl.clear();
        _reasonCtrl.clear();
      } else {
        _error =
            context.hrService.error ??
            tr(context, ar: 'فشل الإرسال', en: 'Submit failed');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    return ListenableBuilder(
      listenable: Listenable.merge([_amountCtrl, _reasonCtrl]),
      builder: (context, _) => RequestFormScaffold(
        title: t('طلب سلفة', 'Loan Request'),
        subtitle: t('سلفة مالية على الراتب', 'Salary advance request'),
        onBack: widget.onBack,
        submitLabel: t('إرسال الطلب', 'Submit Request'),
        canSubmit: _canSubmit,
        submitting: _submitting,
        onSubmit: _submit,
        errorMessage: _error,
        successMessage: _success,
        children: [
          SingleLineFieldCard(
            label: t('المبلغ المطلوب', 'Amount'),
            hint: t('0.00', '0.00'),
            controller: _amountCtrl,
            required: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            icon: LineIconType.chart,
          ),
          SizedBox(height: ds.spacing.lg),
          MultilineFieldCard(
            label: t('السبب', 'Reason'),
            hint: t('وضح سبب طلب السلفة...', 'Explain reason for advance...'),
            controller: _reasonCtrl,
            required: true,
            minLines: 4,
            maxLines: 8,
          ),
        ],
      ),
    );
  }
}
