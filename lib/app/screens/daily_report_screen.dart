import 'package:flutter/widgets.dart';

import '../../design_system/components/line_icons.dart';
import '../../design_system/ds_provider.dart';
import '../../design_system/primitives/ds_button.dart';
import '../../design_system/primitives/ds_card.dart';
import '../../design_system/primitives/ds_text.dart';
import '../../models/models.dart';
import '../../services/api_provider.dart';
import '../i18n.dart';
import '../ui/blocks.dart';

/// Format a report's business day as `YYYY-MM-DD`.
String _fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Format a timestamp as `YYYY-MM-DD HH:MM` for the "read at" line.
String _fmtDateTime(DateTime d) {
  final h = d.hour.toString().padLeft(2, '0');
  final m = d.minute.toString().padLeft(2, '0');
  return '${_fmtDate(d)} $h:$m';
}

// ==================== EMPLOYEE: WRITE & HISTORY ====================

/// End-of-day short report composer for reception, with a history of their own
/// reports showing whether the admin has read each one.
class DailyReportScreen extends StatefulWidget {
  const DailyReportScreen({super.key});

  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  String _value = '';
  bool _sending = false;
  bool _loading = true;
  List<DailyReport> _mine = [];

  static const _green = Color(0xFF059669);

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.text != _value) setState(() => _value = _controller.text);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final mine = await context.hrService.fetchMyDailyReports();
    if (!mounted) return;
    setState(() {
      _mine = mine;
      _loading = false;
    });
  }

  Future<void> _submit() async {
    final text = _value.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final ok = await context.hrService.submitDailyReport(text);
    if (!mounted) return;
    if (ok) {
      _controller.clear();
      _focus.unfocus();
      setState(() {
        _value = '';
        _sending = false;
      });
      await _load();
    } else {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    final canSend = _value.trim().isNotEmpty && !_sending;

    return Container(
      color: ds.colors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.all(ds.spacing.lg),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: DSLineIcon(
                      type: LineIconType.arrowBack,
                      color: ds.colors.primary,
                      size: ds.spacing.lg,
                    ),
                  ),
                  SizedBox(width: ds.spacing.md),
                  DSText(
                    t('تقرير اليوم', "Today's Report"),
                    role: DSTextRole.headline,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsetsDirectional.symmetric(
                    horizontal: ds.spacing.lg),
                children: [
                  DSText(
                    t(
                      'اكتب ملخصاً قصيراً بأحداث اليوم يصل للإدارة.',
                      'Write a short summary of the day for the admin.',
                    ),
                    role: DSTextRole.caption,
                    color: ds.colors.textSecondary,
                  ),
                  SizedBox(height: ds.spacing.md),
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
                      focusNode: _focus,
                      style: ds.typography.body
                          .copyWith(color: ds.colors.textPrimary),
                      cursorColor: ds.colors.primary,
                      backgroundCursorColor: ds.colors.textMuted,
                      maxLines: 8,
                      minLines: 4,
                      textAlign: ds.textDirection == TextDirection.rtl
                          ? TextAlign.right
                          : TextAlign.left,
                    ),
                  ),
                  SizedBox(height: ds.spacing.md),
                  DSButton(
                    label: _sending
                        ? t('جاري الإرسال...', 'Sending...')
                        : t('إرسال التقرير', 'Send Report'),
                    variant: DSButtonVariant.primary,
                    size: DSButtonSize.large,
                    leading: DSLineIcon(
                      type: LineIconType.chat,
                      color: const Color(0xFFFFFFFF),
                      size: ds.spacing.md,
                    ),
                    onPressed: canSend ? _submit : null,
                  ),
                  SizedBox(height: ds.spacing.lg),
                  SectionHeader(title: t('تقاريري السابقة', 'My Past Reports')),
                  SizedBox(height: ds.spacing.sm),
                  if (_loading)
                    const ShimmerLoading()
                  else if (_mine.isEmpty)
                    DSText(
                      t('لا توجد تقارير بعد', 'No reports yet'),
                      role: DSTextRole.body,
                      color: ds.colors.textSecondary,
                    )
                  else
                    for (final r in _mine) ...[
                      _MyReportCard(report: r, green: _green),
                      SizedBox(height: ds.spacing.sm),
                    ],
                  SizedBox(height: ds.spacing.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One of the employee's own reports with its read status.
class _MyReportCard extends StatelessWidget {
  final DailyReport report;
  final Color green;
  const _MyReportCard({required this.report, required this.green});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    return DSCard(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DSText(_fmtDate(report.reportDate),
                    role: DSTextRole.title),
              ),
              _ReadPill(report: report, green: green),
            ],
          ),
          SizedBox(height: ds.spacing.xs),
          DSText(report.content,
              role: DSTextRole.body, color: ds.colors.textSecondary),
          if (report.isRead) ...[
            SizedBox(height: ds.spacing.xs),
            DSText(
              '${t('اطّلعت الإدارة', 'Seen by admin')} · ${_fmtDateTime(report.readAt!)}',
              role: DSTextRole.caption,
              color: green,
            ),
          ],
        ],
      ),
    );
  }
}

/// Small "read / unread" status chip.
class _ReadPill extends StatelessWidget {
  final DailyReport report;
  final Color green;
  const _ReadPill({required this.report, required this.green});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    final read = report.isRead;
    final color = read ? green : ds.colors.textMuted;
    return Container(
      padding: EdgeInsetsDirectional.symmetric(
          horizontal: ds.spacing.sm, vertical: ds.spacing.xs / 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(ds.radii.large),
      ),
      child: DSText(
        read ? t('تم الاطلاع', 'Read') : t('بانتظار الاطلاع', 'Unread'),
        role: DSTextRole.caption,
        color: color,
      ),
    );
  }
}

// ==================== ADMIN: DAILY REPORTS INBOX ====================

/// Admin inbox of all employees' daily reports, each dated. The admin marks a
/// report read as proof of having seen it, which notifies the author.
class DailyReportsInboxScreen extends StatefulWidget {
  const DailyReportsInboxScreen({super.key});

  @override
  State<DailyReportsInboxScreen> createState() =>
      _DailyReportsInboxScreenState();
}

class _DailyReportsInboxScreenState extends State<DailyReportsInboxScreen> {
  bool _loading = true;
  List<DailyReport> _reports = [];
  final Set<int> _marking = {};

  static const _green = Color(0xFF059669);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final reports = await context.hrService.fetchDailyReports();
    if (!mounted) return;
    setState(() {
      _reports = reports;
      _loading = false;
    });
  }

  Future<void> _markRead(DailyReport report) async {
    if (report.isRead || _marking.contains(report.id)) return;
    setState(() => _marking.add(report.id));
    final readAt = await context.hrService.markDailyReportRead(report.id);
    if (!mounted) return;
    setState(() {
      _marking.remove(report.id);
      if (readAt != null) {
        final i = _reports.indexWhere((r) => r.id == report.id);
        if (i != -1) {
          final r = _reports[i];
          _reports[i] = DailyReport(
            id: r.id,
            authorId: r.authorId,
            authorName: r.authorName,
            content: r.content,
            reportDate: r.reportDate,
            createdAt: r.createdAt,
            readAt: readAt,
            readByName: r.readByName,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    final unread = _reports.where((r) => !r.isRead).length;

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
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: DSLineIcon(
                      type: LineIconType.arrowBack,
                      color: ds.colors.primary,
                      size: ds.spacing.lg,
                    ),
                  ),
                  SizedBox(width: ds.spacing.md),
                  Expanded(
                    child: DSText(
                      t('التقارير اليومية', 'Daily Reports'),
                      role: DSTextRole.headline,
                    ),
                  ),
                  if (unread > 0)
                    Container(
                      padding: EdgeInsetsDirectional.symmetric(
                          horizontal: ds.spacing.sm,
                          vertical: ds.spacing.xs / 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEC4899).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(ds.radii.large),
                      ),
                      child: DSText(
                        '$unread ${t('جديد', 'new')}',
                        role: DSTextRole.caption,
                        color: const Color(0xFFEC4899),
                      ),
                    ),
                ],
              ),
              SizedBox(height: ds.spacing.md),
              Expanded(
                child: _loading
                    ? const ShimmerLoading()
                    : _reports.isEmpty
                        ? Center(
                            child: DSText(
                              t('لا توجد تقارير', 'No reports'),
                              role: DSTextRole.body,
                              color: ds.colors.textSecondary,
                            ),
                          )
                        : ListView.separated(
                            itemCount: _reports.length,
                            separatorBuilder: (_, _) =>
                                SizedBox(height: ds.spacing.sm),
                            itemBuilder: (context, i) => _AdminReportCard(
                              report: _reports[i],
                              marking: _marking.contains(_reports[i].id),
                              green: _green,
                              onMarkRead: () => _markRead(_reports[i]),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminReportCard extends StatelessWidget {
  final DailyReport report;
  final bool marking;
  final Color green;
  final VoidCallback onMarkRead;

  const _AdminReportCard({
    required this.report,
    required this.marking,
    required this.green,
    required this.onMarkRead,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    return DSCard(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DSText(
                  report.authorName ?? t('موظف', 'Employee'),
                  role: DSTextRole.title,
                ),
              ),
              DSText(
                _fmtDate(report.reportDate),
                role: DSTextRole.caption,
                color: ds.colors.textMuted,
              ),
            ],
          ),
          SizedBox(height: ds.spacing.xs),
          DSText(report.content,
              role: DSTextRole.body, color: ds.colors.textSecondary),
          SizedBox(height: ds.spacing.md),
          if (report.isRead)
            Row(
              children: [
                DSLineIcon(
                    type: LineIconType.check, color: green, size: ds.spacing.md),
                SizedBox(width: ds.spacing.xs),
                Expanded(
                  child: DSText(
                    '${t('تم الاطلاع', 'Read')} · ${_fmtDateTime(report.readAt!)}',
                    role: DSTextRole.caption,
                    color: green,
                  ),
                ),
              ],
            )
          else
            DSButton(
              label: marking
                  ? t('جاري الحفظ...', 'Saving...')
                  : t('تأكيد الاطلاع', 'Mark as Read'),
              variant: DSButtonVariant.primary,
              leading: DSLineIcon(
                type: LineIconType.check,
                color: const Color(0xFFFFFFFF),
                size: ds.spacing.md,
              ),
              onPressed: marking ? null : onMarkRead,
            ),
        ],
      ),
    );
  }
}
