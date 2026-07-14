import 'package:flutter/widgets.dart';

import '../../design_system/components/line_icons.dart';
import '../../design_system/ds_provider.dart';
import '../../design_system/primitives/ds_button.dart';
import '../../design_system/primitives/ds_card.dart';
import '../../design_system/primitives/ds_text.dart';
import '../../models/models.dart';
import '../../services/api_exceptions.dart';
import '../../services/api_provider.dart';
import '../i18n.dart';
import '../ui/blocks.dart';
import 'specialist_leave_calendar.dart';

/// Treatment plan detail for specialists: plan summary + session list, with
/// reschedule / cancel actions on pending sessions.
class TreatmentPlanScreen extends StatefulWidget {
  final int planId;

  const TreatmentPlanScreen({super.key, required this.planId});

  @override
  State<TreatmentPlanScreen> createState() => _TreatmentPlanScreenState();
}

class _TreatmentPlanScreenState extends State<TreatmentPlanScreen> {
  bool _isLoading = true;
  bool _busy = false;
  String? _error;
  TreatmentPlanDetail? _plan;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final plan = await context.treatmentPlanService.getPlan(widget.planId);
      if (!mounted) return;
      setState(() {
        _plan = plan;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _reschedule(TreatmentSession session) async {
    final picked = await _pickDate(context);
    if (picked == null || !mounted) return;

    final dateStr =
        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';

    await _runAction(() => context.treatmentPlanService.rescheduleSession(
          sessionId: session.id,
          plannedDate: dateStr,
        ));
  }

  Future<void> _cancel(TreatmentSession session) async {
    final confirmed = await _confirm(
      context,
      title: tr(context, ar: 'إلغاء الجلسة', en: 'Cancel Session'),
      message: tr(
        context,
        ar: 'هل تريد إلغاء هذه الجلسة؟ لا يمكن التراجع.',
        en: 'Cancel this session? This cannot be undone.',
      ),
    );
    if (confirmed != true || !mounted) return;

    await _runAction(() => context.treatmentPlanService.cancelSession(session.id));
  }

  /// Run a session mutation, show busy state, surface errors, then reload.
  Future<void> _runAction(Future<TreatmentSession> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String message) {
    setState(() => _error = message);
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    return Container(
      color: ds.colors.background,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsetsDirectional.all(ds.spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DSIconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: DSLineIcon(
                      type: LineIconType.arrowBack,
                      color: ds.colors.textPrimary,
                      size: ds.spacing.md,
                    ),
                  ),
                  SizedBox(width: ds.spacing.md),
                  Expanded(
                    child: DSText(
                      t('خطة العلاج', 'Treatment Plan'),
                      role: DSTextRole.headline,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              SizedBox(height: ds.spacing.lg),
              Expanded(child: _body(context, t)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, String Function(String, String) t) {
    if (_isLoading) return const ShimmerLoading();
    if (_error != null && _plan == null) {
      return _PlanError(message: _error!, onRetry: _load);
    }

    final plan = _plan!;
    final ds = DSProvider.of(context);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PlanSummary(plan: plan),
              if (_error != null) ...[
                SizedBox(height: ds.spacing.md),
                _InlineError(message: _error!),
              ],
              SizedBox(height: ds.spacing.lg),
              SectionHeader(title: t('الجلسات', 'Sessions')),
              if (plan.sessions.isEmpty)
                DSText(
                  t('لا توجد جلسات', 'No sessions'),
                  role: DSTextRole.caption,
                  color: ds.colors.textSecondary,
                )
              else
                ...plan.sessions.map((s) => Padding(
                      padding: EdgeInsetsDirectional.only(bottom: ds.spacing.sm),
                      child: _SessionTile(
                        session: s,
                        busy: _busy,
                        onReschedule: () => _reschedule(s),
                        onCancel: () => _cancel(s),
                      ),
                    )),
              SizedBox(height: ds.spacing.xl),
            ],
          ),
        ),
      ],
    );
  }
}

// ==================== PLAN SUMMARY ====================

class _PlanSummary extends StatelessWidget {
  final TreatmentPlanDetail plan;

  const _PlanSummary({required this.plan});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    return DSCard(
      padding: EdgeInsetsDirectional.all(ds.spacing.lg),
      background: ds.colors.surface,
      shadows: ds.shadows.level1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DSText(
                  plan.patientName ?? t('خطة علاج', 'Treatment Plan'),
                  role: DSTextRole.title,
                  maxLines: 1,
                ),
              ),
              StatusPill(
                label: _planStatusLabel(context, plan.status),
                color: _planStatusColor(plan.status),
              ),
            ],
          ),
          SizedBox(height: ds.spacing.md),
          _row(context, t('القسم', 'Department'), plan.departmentName),
          _row(context, t('تاريخ البدء', 'Start Date'), plan.startDate),
          _row(
            context,
            t('الجلسات', 'Sessions'),
            plan.totalSessions != null
                ? '${plan.sessionsCount}/${plan.totalSessions}'
                : '${plan.sessionsCount}',
          ),
          if (plan.isHomeVisit)
            _row(context, t('النوع', 'Type'), t('زيارة منزلية', 'Home visit')),
          if (plan.totalAmount != null)
            _row(
              context,
              t('الإجمالي', 'Total'),
              '${plan.totalAmount}${plan.currency != null ? ' ${plan.currency}' : ''}',
            ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    final ds = DSProvider.of(context);
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: ds.spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: ds.spacing.xl * 2.2,
            child: DSText(
              label,
              role: DSTextRole.caption,
              color: ds.colors.textSecondary,
            ),
          ),
          SizedBox(width: ds.spacing.sm),
          Expanded(child: DSText(value, role: DSTextRole.body)),
        ],
      ),
    );
  }
}

// ==================== SESSION TILE ====================

class _SessionTile extends StatelessWidget {
  final TreatmentSession session;
  final bool busy;
  final VoidCallback onReschedule;
  final VoidCallback onCancel;

  const _SessionTile({
    required this.session,
    required this.busy,
    required this.onReschedule,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    final color = _sessionStatusColor(session.status);

    return DSCard(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      background: ds.colors.surface,
      shadows: ds.shadows.level1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: ds.spacing.xl,
                height: ds.spacing.xl,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: DSText(
                    '${session.sessionNo ?? '-'}',
                    role: DSTextRole.label,
                    color: color,
                  ),
                ),
              ),
              SizedBox(width: ds.spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DSText(
                      session.plannedDate ?? t('غير مجدولة', 'Unscheduled'),
                      role: DSTextRole.title,
                      maxLines: 1,
                    ),
                    if (session.isMakeup) ...[
                      SizedBox(height: ds.spacing.xs),
                      DSText(
                        t('جلسة تعويضية', 'Make-up session'),
                        role: DSTextRole.caption,
                        color: ds.colors.textSecondary,
                      ),
                    ],
                  ],
                ),
              ),
              StatusPill(
                label: _sessionStatusLabel(context, session.status),
                color: color,
              ),
            ],
          ),
          if (session.isPending) ...[
            SizedBox(height: ds.spacing.md),
            Row(
              children: [
                Expanded(
                  child: DSButton(
                    label: t('تغيير الموعد', 'Reschedule'),
                    variant: DSButtonVariant.ghost,
                    expanded: true,
                    onPressed: busy ? null : onReschedule,
                  ),
                ),
                SizedBox(width: ds.spacing.sm),
                Expanded(
                  child: DSButton(
                    label: t('إلغاء', 'Cancel'),
                    variant: DSButtonVariant.ghost,
                    expanded: true,
                    onPressed: busy ? null : onCancel,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ==================== PICKERS ====================

/// Single-date picker built on [MonthRangeCalendar] (start day is the choice).
Future<DateTime?> _pickDate(BuildContext context) {
  return Navigator.of(context).push<DateTime>(
    PageRouteBuilder<DateTime>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: const Color(0xCC000000),
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (ctx, _, _) => const _DatePickerSheet(),
    ),
  );
}

class _DatePickerSheet extends StatefulWidget {
  const _DatePickerSheet();

  @override
  State<_DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<_DatePickerSheet> {
  DateTime? _selected;

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    final today = DateTime.now();

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
              DSText(t('اختر تاريخاً', 'Pick a date'), role: DSTextRole.headline),
              SizedBox(height: ds.spacing.md),
              MonthRangeCalendar(
                rangeStart: _selected,
                rangeEnd: _selected,
                minDate: DateTime(today.year, today.month, today.day),
                accentColor: ds.colors.primary,
                onRangeChanged: (start, _) =>
                    setState(() => _selected = start),
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
                      label: t('تأكيد', 'Confirm'),
                      variant: DSButtonVariant.primary,
                      expanded: true,
                      onPressed: _selected == null
                          ? null
                          : () => Navigator.of(context).pop(_selected),
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

/// Simple yes/no confirmation modal.
Future<bool?> _confirm(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return Navigator.of(context).push<bool>(
    PageRouteBuilder<bool>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: const Color(0xCC000000),
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (ctx, _, _) => _ConfirmSheet(title: title, message: message),
    ),
  );
}

class _ConfirmSheet extends StatelessWidget {
  final String title;
  final String message;

  const _ConfirmSheet({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);

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
              DSText(title, role: DSTextRole.headline),
              SizedBox(height: ds.spacing.sm),
              DSText(message, role: DSTextRole.body, color: ds.colors.textSecondary),
              SizedBox(height: ds.spacing.lg),
              Row(
                children: [
                  Expanded(
                    child: DSButton(
                      label: t('تراجع', 'Back'),
                      variant: DSButtonVariant.ghost,
                      expanded: true,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  SizedBox(width: ds.spacing.sm),
                  Expanded(
                    child: DSButton(
                      label: t('تأكيد', 'Confirm'),
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

// ==================== HELPERS ====================

class _InlineError extends StatelessWidget {
  final String message;

  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Container(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.1),
        borderRadius: BorderRadius.circular(ds.radii.large),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
      ),
      child: DSText(
        message,
        role: DSTextRole.caption,
        color: const Color(0xFFEF4444),
      ),
    );
  }
}

class _PlanError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _PlanError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
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
          DSText(message, role: DSTextRole.caption, align: TextAlign.center),
          SizedBox(height: ds.spacing.lg),
          DSButton(
            label: t('إعادة المحاولة', 'Retry'),
            variant: DSButtonVariant.ghost,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

Color _planStatusColor(String status) {
  switch (status) {
    case 'active':
      return const Color(0xFF10B981);
    case 'completed':
      return const Color(0xFF6366F1);
    case 'cancelled':
      return const Color(0xFFEF4444);
    case 'approved':
      return const Color(0xFF3B82F6);
    default:
      return const Color(0xFF9CA3AF);
  }
}

String _planStatusLabel(BuildContext context, String status) {
  switch (status) {
    case 'active':
      return tr(context, ar: 'نشطة', en: 'Active');
    case 'completed':
      return tr(context, ar: 'مكتملة', en: 'Completed');
    case 'cancelled':
      return tr(context, ar: 'ملغاة', en: 'Cancelled');
    case 'approved':
      return tr(context, ar: 'معتمدة', en: 'Approved');
    default:
      return tr(context, ar: 'مسودة', en: 'Draft');
  }
}

Color _sessionStatusColor(String status) {
  switch (status) {
    case 'attended':
    case 'completed':
      return const Color(0xFF10B981);
    case 'cancelled':
      return const Color(0xFFEF4444);
    case 'no_show':
      return const Color(0xFFF59E0B);
    case 'scheduled':
      return const Color(0xFF6366F1);
    default:
      return const Color(0xFF3B82F6);
  }
}

String _sessionStatusLabel(BuildContext context, String status) {
  switch (status) {
    case 'attended':
      return tr(context, ar: 'حضر', en: 'Attended');
    case 'completed':
      return tr(context, ar: 'مكتملة', en: 'Completed');
    case 'cancelled':
      return tr(context, ar: 'ملغاة', en: 'Cancelled');
    case 'no_show':
      return tr(context, ar: 'لم يحضر', en: 'No show');
    case 'scheduled':
      return tr(context, ar: 'مجدولة', en: 'Scheduled');
    default:
      return tr(context, ar: 'مخططة', en: 'Planned');
  }
}
