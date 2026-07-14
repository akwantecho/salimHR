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

/// Clinic-wide appointments for a day (manager drill-down).
class ClinicAppointmentsScreen extends StatefulWidget {
  const ClinicAppointmentsScreen({super.key});

  @override
  State<ClinicAppointmentsScreen> createState() =>
      _ClinicAppointmentsScreenState();
}

class _ClinicAppointmentsScreenState extends State<ClinicAppointmentsScreen> {
  bool _loading = true;
  String? _error;
  DateTime _date = DateTime.now();
  List<ClinicAppointment> _items = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final d = _date;
    final dateStr =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    try {
      final items = await context.clinicService.getAppointments(date: dateStr);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : e.toString();
        _loading = false;
      });
    }
  }

  void _shiftDay(int days) {
    setState(() => _date = _date.add(Duration(days: days)));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    final d = _date;

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
                      t('مواعيد العيادة', 'Clinic Appointments'),
                      role: DSTextRole.headline,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              SizedBox(height: ds.spacing.md),
              Row(
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
                    child: DSText(
                      '${d.day}/${d.month}/${d.year}',
                      role: DSTextRole.title,
                      align: TextAlign.center,
                    ),
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
              ),
              SizedBox(height: ds.spacing.md),
              Expanded(child: _body(context, t)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, String Function(String, String) t) {
    final ds = DSProvider.of(context);
    if (_loading) return const ShimmerLoading();
    if (_error != null) {
      return Center(
        child: DSText(_error!, role: DSTextRole.caption, align: TextAlign.center),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: DSText(
          t('لا مواعيد هذا اليوم', 'No appointments this day'),
          role: DSTextRole.caption,
          color: ds.colors.textSecondary,
        ),
      );
    }
    return ListView.separated(
      itemCount: _items.length,
      separatorBuilder: (_, i) => SizedBox(height: ds.spacing.sm),
      itemBuilder: (context, index) {
        final a = _items[index];
        final color = _statusColor(a.status);
        return DSCard(
          padding: EdgeInsetsDirectional.all(ds.spacing.md),
          background: ds.colors.surface,
          shadows: ds.shadows.level1,
          child: Row(
            children: [
              SizedBox(
                width: ds.spacing.xl * 2,
                child: DSText(
                  formatTime12h(context, a.startTime),
                  role: DSTextRole.caption,
                  color: ds.colors.textSecondary,
                ),
              ),
              SizedBox(width: ds.spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DSText(a.patient ?? t('مريض', 'Patient'),
                        role: DSTextRole.title, maxLines: 1),
                    SizedBox(height: ds.spacing.xs),
                    DSText(
                      [
                        if (a.specialist != null) a.specialist!,
                        if (a.service != null) a.service!,
                      ].join(' · '),
                      role: DSTextRole.caption,
                      color: ds.colors.textSecondary,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              StatusPill(label: _statusLabel(context, a.status), color: color),
            ],
          ),
        );
      },
    );
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'completed':
      return const Color(0xFF10B981);
    case 'cancelled':
      return const Color(0xFFEF4444);
    case 'no_show':
      return const Color(0xFFF59E0B);
    case 'checked_in':
    case 'confirmed':
      return const Color(0xFF6366F1);
    default:
      return const Color(0xFF3B82F6);
  }
}

String _statusLabel(BuildContext context, String status) {
  switch (status) {
    case 'completed':
      return tr(context, ar: 'مكتملة', en: 'Done');
    case 'cancelled':
      return tr(context, ar: 'ملغاة', en: 'Cancelled');
    case 'no_show':
      return tr(context, ar: 'لم يحضر', en: 'No show');
    case 'checked_in':
      return tr(context, ar: 'حاضر', en: 'In');
    case 'confirmed':
      return tr(context, ar: 'مؤكدة', en: 'Confirmed');
    default:
      return tr(context, ar: 'محجوزة', en: 'Booked');
  }
}
