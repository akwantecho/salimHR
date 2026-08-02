import 'package:flutter/widgets.dart';

import '../../design_system/ds_provider.dart';
import '../../design_system/primitives/ds_text.dart';
import '../i18n.dart';

/// Full month calendar with date-range selection. The first tap sets the
/// start; the second tap sets the end (or resets start if the new tap is
/// before the current start). Past dates are visible but not selectable.
///
/// Designed to live inside a vertically scrolling form — no horizontal
/// gestures inside the grid so it composes nicely.
class MonthRangeCalendar extends StatefulWidget {
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final void Function(DateTime start, DateTime end) onRangeChanged;
  final DateTime? minDate;
  final Color accentColor;

  const MonthRangeCalendar({
    super.key,
    required this.rangeStart,
    required this.rangeEnd,
    required this.onRangeChanged,
    this.minDate,
    this.accentColor = const Color(0xFF6366F1),
  });

  @override
  State<MonthRangeCalendar> createState() => _MonthRangeCalendarState();
}

class _MonthRangeCalendarState extends State<MonthRangeCalendar> {
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    final base = widget.rangeStart ?? DateTime.now();
    _visibleMonth = DateTime(base.year, base.month, 1);
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth =
          DateTime(_visibleMonth.year, _visibleMonth.month + delta, 1);
    });
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isInRange(DateTime d) {
    final s = widget.rangeStart;
    final e = widget.rangeEnd;
    if (s == null || e == null) return false;
    return !d.isBefore(_dayOnly(s)) && !d.isAfter(_dayOnly(e));
  }

  DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  void _handleTap(DateTime d) {
    if (widget.minDate != null &&
        d.isBefore(_dayOnly(widget.minDate!))) {
      return;
    }
    final start = widget.rangeStart;
    final end = widget.rangeEnd;

    // First tap, or both start+end already set → restart selection.
    if (start == null || (end != null && !_sameDay(start, end))) {
      widget.onRangeChanged(d, d);
      return;
    }
    // Tap before current start → restart at the earlier date.
    if (d.isBefore(start)) {
      widget.onRangeChanged(d, d);
      return;
    }
    // Tap on or after start → extend range.
    widget.onRangeChanged(start, d);
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final isRtl = ds.textDirection == TextDirection.rtl;

    return Container(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      decoration: BoxDecoration(
        color: ds.colors.surface,
        borderRadius: BorderRadius.circular(ds.radii.large),
        border: Border.all(color: ds.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            month: _visibleMonth,
            onPrev: () => _changeMonth(-1),
            onNext: () => _changeMonth(1),
            onToday: () {
              final now = DateTime.now();
              setState(() => _visibleMonth = DateTime(now.year, now.month, 1));
            },
          ),
          SizedBox(height: ds.spacing.md),
          _WeekdaysRow(rtl: isRtl),
          SizedBox(height: ds.spacing.xs),
          _DaysGrid(
            month: _visibleMonth,
            rangeStart: widget.rangeStart,
            rangeEnd: widget.rangeEnd,
            accentColor: widget.accentColor,
            minDate: widget.minDate,
            isInRange: _isInRange,
            sameDay: _sameDay,
            onTap: _handleTap,
          ),
          SizedBox(height: ds.spacing.sm),
          if (widget.rangeStart != null && widget.rangeEnd != null)
            _RangeSummary(
              start: widget.rangeStart!,
              end: widget.rangeEnd!,
              accentColor: widget.accentColor,
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;

  const _Header({
    required this.month,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    return Row(
      children: [
        _NavArrow(label: '◀', onTap: onPrev),
        SizedBox(width: ds.spacing.sm),
        Expanded(
          child: GestureDetector(
            onTap: onToday,
            behavior: HitTestBehavior.opaque,
            child: Center(
              child: Column(
                children: [
                  DSText(_monthYear(context, month), role: DSTextRole.title),
                  SizedBox(height: 2),
                  DSText(
                    t('اضغط للعودة لهذا الشهر', 'Tap to jump to current month'),
                    role: DSTextRole.caption,
                    color: ds.colors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: ds.spacing.sm),
        _NavArrow(label: '▶', onTap: onNext),
      ],
    );
  }

  static const _arMonths = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];
  static const _enMonths = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  String _monthYear(BuildContext context, DateTime d) {
    final name = tr(context,
        ar: _arMonths[d.month - 1], en: _enMonths[d.month - 1]);
    return '$name ${d.year}';
  }
}

class _NavArrow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NavArrow({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: ds.spacing.xl,
        height: ds.spacing.xl,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ds.colors.surfaceAlt,
          shape: BoxShape.circle,
          border: Border.all(color: ds.colors.border),
        ),
        child: DSText(label,
            role: DSTextRole.label, color: ds.colors.textPrimary),
      ),
    );
  }
}

class _WeekdaysRow extends StatelessWidget {
  final bool rtl;
  const _WeekdaysRow({required this.rtl});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    // Week starts Saturday for clinic ops (Oman/Gulf calendar).
    final labels = [
      t('سبت', 'Sat'),
      t('أحد', 'Sun'),
      t('إثنين', 'Mon'),
      t('ثلاثاء', 'Tue'),
      t('أربعاء', 'Wed'),
      t('خميس', 'Thu'),
      t('جمعة', 'Fri'),
    ];
    return Row(
      children: [
        for (final label in labels)
          Expanded(
            child: Center(
              child: DSText(
                label,
                role: DSTextRole.caption,
                color: ds.colors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

class _DaysGrid extends StatelessWidget {
  final DateTime month;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final Color accentColor;
  final DateTime? minDate;
  final bool Function(DateTime) isInRange;
  final bool Function(DateTime, DateTime) sameDay;
  final ValueChanged<DateTime> onTap;

  const _DaysGrid({
    required this.month,
    required this.rangeStart,
    required this.rangeEnd,
    required this.accentColor,
    required this.minDate,
    required this.isInRange,
    required this.sameDay,
    required this.onTap,
  });

  /// Returns 0..6 representing Sat=0, Sun=1, ..., Fri=6.
  int _columnOf(DateTime d) {
    // DateTime.weekday: Mon=1, Tue=2, Wed=3, Thu=4, Fri=5, Sat=6, Sun=7
    // We want Sat=0, Sun=1, Mon=2, Tue=3, Wed=4, Thu=5, Fri=6
    switch (d.weekday) {
      case DateTime.saturday:
        return 0;
      case DateTime.sunday:
        return 1;
      case DateTime.monday:
        return 2;
      case DateTime.tuesday:
        return 3;
      case DateTime.wednesday:
        return 4;
      case DateTime.thursday:
        return 5;
      default:
        return 6; // Friday
    }
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final lastOfMonth = DateTime(month.year, month.month + 1, 0);
    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);

    final leadingBlanks = _columnOf(firstOfMonth);
    final daysInMonth = lastOfMonth.day;
    final totalCells = leadingBlanks + daysInMonth;
    final rowCount = (totalCells / 7).ceil();

    return Column(
      children: [
        for (var row = 0; row < rowCount; row++)
          Padding(
            padding: EdgeInsetsDirectional.only(bottom: ds.spacing.xs),
            child: Row(
              children: [
                for (var col = 0; col < 7; col++)
                  Expanded(
                    child: _cell(
                      context,
                      ds,
                      row: row,
                      col: col,
                      leadingBlanks: leadingBlanks,
                      daysInMonth: daysInMonth,
                      todayDay: todayDay,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _cell(
    BuildContext context,
    DSTheme ds, {
    required int row,
    required int col,
    required int leadingBlanks,
    required int daysInMonth,
    required DateTime todayDay,
  }) {
    final cellIndex = row * 7 + col;
    final dayNumber = cellIndex - leadingBlanks + 1;
    if (dayNumber < 1 || dayNumber > daysInMonth) {
      return const AspectRatio(aspectRatio: 1, child: SizedBox.shrink());
    }
    final date = DateTime(month.year, month.month, dayNumber);
    final isPast = minDate != null &&
        date.isBefore(DateTime(minDate!.year, minDate!.month, minDate!.day));
    final isToday = sameDay(date, todayDay);
    final isStart = rangeStart != null && sameDay(date, rangeStart!);
    final isEnd = rangeEnd != null && sameDay(date, rangeEnd!);
    final inRange = isInRange(date);
    final isEdge = isStart || isEnd;

    Color bg;
    Color fg;
    BoxShape shape = BoxShape.circle;

    if (isEdge) {
      bg = accentColor;
      fg = const Color(0xFFFFFFFF);
    } else if (inRange) {
      bg = accentColor.withValues(alpha: 0.18);
      fg = accentColor;
      shape = BoxShape.rectangle;
    } else if (isToday) {
      bg = accentColor.withValues(alpha: 0.08);
      fg = accentColor;
    } else {
      bg = ds.colors.surface;
      fg = isPast ? ds.colors.textMuted : ds.colors.textPrimary;
    }

    final border = isToday && !isEdge
        ? Border.all(color: accentColor, width: 1.2)
        : null;

    return AspectRatio(
      aspectRatio: 1,
      child: GestureDetector(
        onTap: isPast ? null : () => onTap(date),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsetsDirectional.all(2),
          child: AnimatedContainer(
            duration: ds.animation.fast,
            curve: ds.animation.curve,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              shape: shape,
              borderRadius: shape == BoxShape.rectangle
                  ? BorderRadius.circular(ds.radii.medium)
                  : null,
              border: border,
            ),
            child: DSText(
              '$dayNumber',
              role: DSTextRole.label,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}

class _RangeSummary extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  final Color accentColor;

  const _RangeSummary({
    required this.start,
    required this.end,
    required this.accentColor,
  });

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  int get _days => end.difference(start).inDays + 1;

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: ds.spacing.md,
        vertical: ds.spacing.sm,
      ),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(ds.radii.medium),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DSText(
                  t('من', 'From'),
                  role: DSTextRole.caption,
                  color: ds.colors.textSecondary,
                ),
                SizedBox(height: 2),
                DSText(_fmt(start), role: DSTextRole.label),
              ],
            ),
          ),
          Container(
            width: 1,
            height: ds.spacing.xl,
            color: accentColor.withValues(alpha: 0.25),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsetsDirectional.only(start: ds.spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DSText(
                    t('إلى', 'To'),
                    role: DSTextRole.caption,
                    color: ds.colors.textSecondary,
                  ),
                  SizedBox(height: 2),
                  DSText(_fmt(end), role: DSTextRole.label),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: ds.spacing.sm,
              vertical: ds.spacing.xs / 2,
            ),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(ds.radii.pill),
            ),
            child: DSText(
              t('$_days يوم', '$_days days'),
              role: DSTextRole.caption,
              color: const Color(0xFFFFFFFF),
            ),
          ),
        ],
      ),
    );
  }
}
