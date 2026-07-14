import 'package:flutter/widgets.dart';

import '../../design_system/components/line_icons.dart';
import '../../design_system/ds_provider.dart';
import '../../design_system/primitives/ds_button.dart';
import '../../design_system/primitives/ds_card.dart';
import '../../design_system/primitives/ds_text.dart';
import '../../models/models.dart';
import '../../services/api_exceptions.dart';
import '../../services/api_provider.dart';
import '../../utils/time_format.dart';
import '../i18n.dart';
import '../ui/blocks.dart';

/// The specialist's own schedule: weekly working template + open slots by day.
class MyScheduleScreen extends StatefulWidget {
  const MyScheduleScreen({super.key});

  @override
  State<MyScheduleScreen> createState() => _MyScheduleScreenState();
}

class _MyScheduleScreenState extends State<MyScheduleScreen> {
  bool _loadingWeekly = true;
  bool _loadingSlots = true;
  String? _weeklyError;
  List<ScheduleDay> _weekly = [];
  DateTime _selectedDate = DateTime.now();
  DaySlots _slots = const DaySlots();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWeekly();
      _loadSlots();
    });
  }

  Future<void> _loadWeekly() async {
    setState(() {
      _loadingWeekly = true;
      _weeklyError = null;
    });
    try {
      final weekly = await context.scheduleService.getWeekly();
      if (!mounted) return;
      setState(() {
        _weekly = weekly;
        _loadingWeekly = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _weeklyError = e is ApiException ? e.message : e.toString();
        _loadingWeekly = false;
      });
    }
  }

  Future<void> _loadSlots() async {
    setState(() => _loadingSlots = true);
    final d = _selectedDate;
    final dateStr =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    try {
      final slots = await context.scheduleService.getSlots(dateStr);
      if (!mounted) return;
      setState(() {
        _slots = slots;
        _loadingSlots = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _slots = const DaySlots();
        _loadingSlots = false;
      });
    }
  }

  void _shiftDay(int days) {
    setState(() => _selectedDate = _selectedDate.add(Duration(days: days)));
    _loadSlots();
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
                      t('جدولي', 'My Schedule'),
                      role: DSTextRole.headline,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              SizedBox(height: ds.spacing.lg),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(title: t('الجدول الأسبوعي', 'Weekly Hours')),
                          _weeklySection(context, t),
                          SizedBox(height: ds.spacing.lg),
                          SectionHeader(title: t('الأوقات المتاحة', 'Open Slots')),
                          _daySelector(context, t),
                          SizedBox(height: ds.spacing.md),
                          _slotsSection(context, t),
                          SizedBox(height: ds.spacing.xl),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _weeklySection(BuildContext context, String Function(String, String) t) {
    final ds = DSProvider.of(context);
    if (_loadingWeekly) return const ShimmerLoading();
    if (_weeklyError != null) {
      return DSText(_weeklyError!,
          role: DSTextRole.caption, color: const Color(0xFFEF4444));
    }
    if (_weekly.isEmpty) {
      return DSText(t('لا يوجد جدول', 'No schedule set'),
          role: DSTextRole.caption, color: ds.colors.textSecondary);
    }
    return Column(
      children: _weekly
          .map((d) => Padding(
                padding: EdgeInsetsDirectional.only(bottom: ds.spacing.sm),
                child: _WeeklyRow(day: d),
              ))
          .toList(),
    );
  }

  Widget _daySelector(BuildContext context, String Function(String, String) t) {
    final ds = DSProvider.of(context);
    final d = _selectedDate;
    final label = '${_weekdayName(context, d.weekday % 7)} ${d.day}/${d.month}';
    return Row(
      children: [
        DSIconButton(
          onPressed: () => _shiftDay(-1),
          icon: DSLineIcon(
            type: LineIconType.arrowBack,
            color: ds.colors.textPrimary,
            size: ds.spacing.md,
          ),
        ),
        Expanded(
          child: DSText(label, role: DSTextRole.title, align: TextAlign.center),
        ),
        DSIconButton(
          onPressed: () => _shiftDay(1),
          icon: Transform.flip(
            flipX: true,
            child: DSLineIcon(
              type: LineIconType.arrowBack,
              color: ds.colors.textPrimary,
              size: ds.spacing.md,
            ),
          ),
        ),
      ],
    );
  }

  Widget _slotsSection(BuildContext context, String Function(String, String) t) {
    final ds = DSProvider.of(context);
    if (_loadingSlots) return const ShimmerLoading();

    if (_slots.slots.isEmpty) {
      final reason = switch (_slots.reason) {
        'no_hours' => t('لا توجد ساعات عمل هذا اليوم', 'No working hours this day'),
        'day_off' => t('يوم إجازة', 'Day off'),
        'full' => t('محجوز بالكامل', 'Fully booked'),
        _ => t('لا توجد أوقات متاحة', 'No open slots'),
      };
      return DSText(reason,
          role: DSTextRole.caption, color: ds.colors.textSecondary);
    }

    return Wrap(
      spacing: ds.spacing.sm,
      runSpacing: ds.spacing.sm,
      children: _slots.slots.map((s) => _SlotChip(slot: s)).toList(),
    );
  }
}

class _WeeklyRow extends StatelessWidget {
  final ScheduleDay day;

  const _WeeklyRow({required this.day});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    final working = day.isWorking && day.start != null && day.end != null;

    return DSCard(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      background: ds.colors.surface,
      shadows: ds.shadows.level1,
      child: Row(
        children: [
          Expanded(
            child: DSText(
              _weekdayName(context, day.dayOfWeek),
              role: DSTextRole.title,
            ),
          ),
          DSText(
            working
                ? '${formatTime12h(context, day.start)} - ${formatTime12h(context, day.end)}'
                : t('عطلة', 'Off'),
            role: DSTextRole.body,
            color: working ? ds.colors.textPrimary : ds.colors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  final DaySlot slot;

  const _SlotChip({required this.slot});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final color =
        slot.available ? ds.colors.primary : ds.colors.textSecondary;
    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: ds.spacing.md,
        vertical: ds.spacing.sm,
      ),
      decoration: BoxDecoration(
        color: slot.available
            ? ds.colors.accent
            : ds.colors.surfaceAlt,
        borderRadius: BorderRadius.circular(ds.radii.pill),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: DSText(
        formatTime12h(context, slot.start),
        role: DSTextRole.caption,
        color: color,
      ),
    );
  }
}

String _weekdayName(BuildContext context, int dayOfWeek) {
  // 0 = Sunday … 6 = Saturday (Carbon dayOfWeek).
  switch (dayOfWeek) {
    case 0:
      return tr(context, ar: 'الأحد', en: 'Sun');
    case 1:
      return tr(context, ar: 'الإثنين', en: 'Mon');
    case 2:
      return tr(context, ar: 'الثلاثاء', en: 'Tue');
    case 3:
      return tr(context, ar: 'الأربعاء', en: 'Wed');
    case 4:
      return tr(context, ar: 'الخميس', en: 'Thu');
    case 5:
      return tr(context, ar: 'الجمعة', en: 'Fri');
    default:
      return tr(context, ar: 'السبت', en: 'Sat');
  }
}
