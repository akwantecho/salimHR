import 'package:flutter/widgets.dart';

import '../../design_system/components/line_icons.dart';
import '../../design_system/ds_provider.dart';
import '../../design_system/primitives/ds_button.dart';
import '../../design_system/primitives/ds_text.dart';
import '../../models/models.dart';
import '../../services/api_provider.dart';
import '../../utils/time_format.dart';
import '../i18n.dart';

/// Detail screen for a single appointment with two outcome actions:
/// "End session" (status=completed) and "No show" (status=no_show).
/// Both require a typed comment — enforced by the bottom-sheet dialog.
class SessionDetailScreen extends StatefulWidget {
  final Appointment appointment;

  const SessionDetailScreen({super.key, required this.appointment});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  late Appointment _appointment;
  bool _submitting = false;
  String? _error;

  // Pending action while the comment dialog is open. null = dialog closed.
  String? _pendingAction; // 'complete' | 'no_show'
  final TextEditingController _commentController = TextEditingController();
  String _commentText = '';

  @override
  void initState() {
    super.initState();
    _appointment = widget.appointment;
    _commentController.addListener(() {
      if (_commentController.text != _commentText) {
        setState(() => _commentText = _commentController.text);
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _openCommentDialog(String action) {
    _commentController.clear();
    setState(() {
      _pendingAction = action;
      _commentText = '';
      _error = null;
    });
  }

  void _closeCommentDialog() {
    setState(() {
      _pendingAction = null;
      _commentText = '';
    });
    _commentController.clear();
  }

  Future<void> _submit() async {
    final action = _pendingAction;
    final notes = _commentText.trim();
    if (action == null || notes.length < 3) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    final result = await context.hrService.updateAppointmentStatus(
      appointmentId: _appointment.id,
      action: action,
      notes: notes,
    );

    if (!mounted) return;

    if (result == null) {
      setState(() {
        _submitting = false;
        _error = context.hrService.error ?? 'Request failed';
      });
      return;
    }

    final updated = Appointment.fromJson(result);
    setState(() {
      _appointment = updated;
      _submitting = false;
      _pendingAction = null;
      _commentText = '';
    });
    _commentController.clear();

    if (mounted) {
      Navigator.of(context).pop(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    final isTerminal = _appointment.isCompleted ||
        _appointment.isCancelled ||
        _appointment.status == 'no_show';

    return Container(
      color: ds.colors.background,
      child: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsetsDirectional.all(ds.spacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TopBar(
                          title: t('تفاصيل الجلسة', 'Session Details'),
                          onBack: () => Navigator.of(context).pop(_appointment),
                        ),
                        SizedBox(height: ds.spacing.lg),
                        _StatusBadge(status: _appointment.status),
                        SizedBox(height: ds.spacing.md),
                        _PatientCard(appointment: _appointment),
                        SizedBox(height: ds.spacing.md),
                        _InfoCard(appointment: _appointment),
                        if (_error != null) ...[
                          SizedBox(height: ds.spacing.md),
                          _ErrorBanner(message: _error!),
                        ],
                        SizedBox(height: ds.spacing.xl),
                        if (!isTerminal) _ActionButtons(
                          onEnd: _submitting
                              ? null
                              : () => _openCommentDialog('complete'),
                          submitting: _submitting,
                        ),
                        if (isTerminal)
                          _TerminalNotice(status: _appointment.status),
                        SizedBox(height: ds.spacing.xl),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_pendingAction != null)
              _CommentDialog(
                action: _pendingAction!,
                controller: _commentController,
                value: _commentText,
                submitting: _submitting,
                onCancel: _submitting ? null : _closeCommentDialog,
                onConfirm: _submit,
              ),
          ],
        ),
      ),
    );
  }
}

// ==================== TOP BAR ====================

class _TopBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _TopBar({required this.title, required this.onBack});

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
          child: DSText(
            title,
            role: DSTextRole.headline,
          ),
        ),
      ],
    );
  }
}

// ==================== STATUS BADGE ====================

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final color = _statusColor(status);
    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: ds.spacing.md,
        vertical: ds.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(ds.radii.pill),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: DSText(
        _statusLabel(context, status),
        role: DSTextRole.label,
        color: color,
      ),
    );
  }
}

// ==================== PATIENT CARD ====================

class _PatientCard extends StatelessWidget {
  final Appointment appointment;

  const _PatientCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    return Container(
      padding: EdgeInsetsDirectional.all(ds.spacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(ds.radii.xLarge),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: ds.spacing.xl + ds.spacing.sm,
            height: ds.spacing.xl + ds.spacing.sm,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF).withOpacity(0.2),
              borderRadius: BorderRadius.circular(ds.radii.large),
            ),
            child: Center(
              child: DSLineIcon(
                type: LineIconType.heart,
                color: const Color(0xFFFFFFFF),
                size: ds.spacing.lg,
              ),
            ),
          ),
          SizedBox(width: ds.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DSText(
                  appointment.patientName ?? t('مريض', 'Patient'),
                  role: DSTextRole.headline,
                  color: const Color(0xFFFFFFFF),
                ),
                if (appointment.patientPhone != null) ...[
                  SizedBox(height: ds.spacing.xs),
                  DSText(
                    appointment.patientPhone!,
                    role: DSTextRole.body,
                    color: const Color(0xFFFFFFFF).withOpacity(0.85),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== INFO ROWS ====================

class _InfoCard extends StatelessWidget {
  final Appointment appointment;

  const _InfoCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    return Container(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      decoration: BoxDecoration(
        color: ds.colors.surface,
        borderRadius: BorderRadius.circular(ds.radii.large),
        border: Border.all(color: ds.colors.border),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: LineIconType.calendar,
            label: t('التاريخ', 'Date'),
            value: _formatDate(appointment.appointmentDate),
          ),
          SizedBox(height: ds.spacing.sm),
          _InfoRow(
            icon: LineIconType.calendar,
            label: t('الوقت', 'Time'),
            value: _formatTime(context, appointment.startTime) +
                (appointment.endTime != null
                    ? ' — ${_formatTime(context, appointment.endTime)}'
                    : ''),
          ),
          if (appointment.serviceName != null) ...[
            SizedBox(height: ds.spacing.sm),
            _InfoRow(
              icon: LineIconType.heart,
              label: t('الخدمة', 'Service'),
              value: appointment.serviceName!,
            ),
          ],
          if (appointment.departmentName != null) ...[
            SizedBox(height: ds.spacing.sm),
            _InfoRow(
              icon: LineIconType.home,
              label: t('القسم', 'Department'),
              value: appointment.departmentName!,
            ),
          ],
          if (appointment.locationNotes != null &&
              appointment.locationNotes!.isNotEmpty) ...[
            SizedBox(height: ds.spacing.sm),
            _InfoRow(
              icon: LineIconType.home,
              label: t('ملاحظات الموقع', 'Location'),
              value: appointment.locationNotes!,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final LineIconType icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Row(
      children: [
        Container(
          width: ds.spacing.lg,
          height: ds.spacing.lg,
          decoration: BoxDecoration(
            color: ds.colors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(ds.radii.small),
          ),
          child: Center(
            child: DSLineIcon(
              type: icon,
              color: ds.colors.primary,
              size: 14,
            ),
          ),
        ),
        SizedBox(width: ds.spacing.sm),
        Expanded(
          child: DSText(
            label,
            role: DSTextRole.caption,
            color: ds.colors.textSecondary,
          ),
        ),
        Flexible(
          child: DSText(
            value,
            role: DSTextRole.label,
            color: ds.colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ==================== ACTION BUTTONS ====================

class _ActionButtons extends StatelessWidget {
  final VoidCallback? onEnd;
  final bool submitting;

  const _ActionButtons({
    required this.onEnd,
    required this.submitting,
  });

  @override
  Widget build(BuildContext context) {
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    return _OutcomeButton(
      label: t('إنهاء الجلسة', 'End Session'),
      icon: LineIconType.heart,
      color: const Color(0xFF10B981),
      onPressed: onEnd,
    );
  }
}

class _OutcomeButton extends StatelessWidget {
  final String label;
  final LineIconType icon;
  final Color color;
  final VoidCallback? onPressed;

  const _OutcomeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final enabled = onPressed != null;
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: ds.animation.fast,
        width: double.infinity,
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: ds.spacing.lg,
          vertical: ds.spacing.md,
        ),
        decoration: BoxDecoration(
          gradient: enabled
              ? LinearGradient(
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                  colors: [color, color.withOpacity(0.8)],
                )
              : null,
          color: enabled ? null : color.withOpacity(0.3),
          borderRadius: BorderRadius.circular(ds.radii.large),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DSLineIcon(
              type: icon,
              color: const Color(0xFFFFFFFF),
              size: ds.spacing.md,
            ),
            SizedBox(width: ds.spacing.sm),
            DSText(
              label,
              role: DSTextRole.label,
              color: const Color(0xFFFFFFFF),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== COMMENT DIALOG ====================

class _CommentDialog extends StatelessWidget {
  final String action;
  final TextEditingController controller;
  final String value;
  final bool submitting;
  final VoidCallback? onCancel;
  final VoidCallback onConfirm;

  const _CommentDialog({
    required this.action,
    required this.controller,
    required this.value,
    required this.submitting,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    final isComplete = action == 'complete';
    final title = isComplete
        ? t('إنهاء الجلسة', 'End Session')
        : t('تسجيل عدم حضور', 'Mark No Show');
    final hint = isComplete
        ? t('اكتب تعليقاً عن الجلسة (مطلوب)', 'Write a session comment (required)')
        : t('سبب عدم الحضور (مطلوب)', 'Reason for no-show (required)');
    final color = isComplete ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    final trimmed = value.trim();
    final canConfirm = trimmed.length >= 3 && !submitting;

    return Positioned.fill(
      child: Stack(
        children: [
          // Scrim — taps dismiss when not submitting
          GestureDetector(
            onTap: submitting ? null : onCancel,
            child: Container(color: const Color(0xCC000000)),
          ),
          Center(
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
                    Row(
                      children: [
                        Container(
                          width: ds.spacing.xl,
                          height: ds.spacing.xl,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(ds.radii.medium),
                          ),
                          child: Center(
                            child: DSLineIcon(
                              type: isComplete
                                  ? LineIconType.heart
                                  : LineIconType.bell,
                              color: color,
                              size: ds.spacing.md,
                            ),
                          ),
                        ),
                        SizedBox(width: ds.spacing.sm),
                        Expanded(
                          child: DSText(title, role: DSTextRole.headline),
                        ),
                      ],
                    ),
                    SizedBox(height: ds.spacing.md),
                    DSText(
                      hint,
                      role: DSTextRole.caption,
                      color: ds.colors.textSecondary,
                    ),
                    SizedBox(height: ds.spacing.sm),
                    _CommentField(
                      controller: controller,
                      enabled: !submitting,
                    ),
                    SizedBox(height: ds.spacing.xs),
                    DSText(
                      t(
                        'يجب كتابة 3 أحرف على الأقل قبل الإنهاء.',
                        'Comment must be at least 3 characters.',
                      ),
                      role: DSTextRole.caption,
                      color: trimmed.length >= 3
                          ? ds.colors.textMuted
                          : const Color(0xFFEF4444),
                    ),
                    SizedBox(height: ds.spacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: DSButton(
                            label: t('إلغاء', 'Cancel'),
                            variant: DSButtonVariant.ghost,
                            expanded: true,
                            onPressed: submitting ? null : onCancel,
                          ),
                        ),
                        SizedBox(width: ds.spacing.sm),
                        Expanded(
                          child: DSButton(
                            label: submitting
                                ? t('جاري الحفظ...', 'Saving...')
                                : t('إنهاء', 'Confirm'),
                            variant: DSButtonVariant.primary,
                            expanded: true,
                            onPressed: canConfirm ? onConfirm : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentField extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;

  const _CommentField({required this.controller, required this.enabled});

  @override
  State<_CommentField> createState() => _CommentFieldState();
}

class _CommentFieldState extends State<_CommentField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.enabled) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Container(
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
        controller: widget.controller,
        focusNode: _focusNode,
        style: ds.typography.body.copyWith(color: ds.colors.textPrimary),
        cursorColor: ds.colors.primary,
        backgroundCursorColor: ds.colors.textMuted,
        maxLines: 5,
        minLines: 3,
        readOnly: !widget.enabled,
        textAlign: ds.textDirection == TextDirection.rtl
            ? TextAlign.right
            : TextAlign.left,
      ),
    );
  }
}

// ==================== TERMINAL + ERROR ====================

class _TerminalNotice extends StatelessWidget {
  final String status;

  const _TerminalNotice({required this.status});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    final color = _statusColor(status);
    final message = status == 'completed'
        ? t('تم إنهاء هذه الجلسة بالفعل.', 'This session has already been ended.')
        : status == 'no_show'
            ? t('تم تسجيل عدم حضور المريض.', 'Patient was marked as no-show.')
            : t('تم إلغاء هذه الجلسة.', 'This session has been cancelled.');
    return Container(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(ds.radii.large),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          DSLineIcon(type: LineIconType.bell, color: color, size: ds.spacing.md),
          SizedBox(width: ds.spacing.sm),
          Expanded(
            child: DSText(message, role: DSTextRole.body, color: color),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    const red = Color(0xFFEF4444);
    return Container(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      decoration: BoxDecoration(
        color: red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(ds.radii.large),
        border: Border.all(color: red.withOpacity(0.3)),
      ),
      child: DSText(message, role: DSTextRole.body, color: red),
    );
  }
}

// ==================== HELPERS ====================

String _formatDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

String _formatTime(BuildContext context, String? time) =>
    formatTime12h(context, time);

Color _statusColor(String status) {
  switch (status) {
    case 'booked':
      return const Color(0xFF6366F1);
    case 'checked_in':
      return const Color(0xFFF59E0B);
    case 'completed':
      return const Color(0xFF10B981);
    case 'no_show':
      return const Color(0xFFEF4444);
    case 'cancelled':
      return const Color(0xFF94A3B8);
    default:
      return const Color(0xFF6366F1);
  }
}

String _statusLabel(BuildContext context, String status) {
  String t(String ar, String en) => tr(context, ar: ar, en: en);
  switch (status) {
    case 'booked':
      return t('قادمة', 'Upcoming');
    case 'checked_in':
      return t('حاضر', 'Checked In');
    case 'completed':
      return t('مكتملة', 'Completed');
    case 'no_show':
      return t('لم يحضر', 'No Show');
    case 'cancelled':
      return t('ملغاة', 'Cancelled');
    default:
      return status;
  }
}
