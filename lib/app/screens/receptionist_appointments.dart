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
import 'receptionist_common.dart';
import 'specialist_requests.dart' show RequestFormScaffold;

/// Booking form: pick patient → service → specialist → date → slot, then
/// POST /reception/appointments. Reuses [RequestFormScaffold] for chrome.
class AppointmentBookingScreen extends StatefulWidget {
  final VoidCallback onBack;

  const AppointmentBookingScreen({super.key, required this.onBack});

  @override
  State<AppointmentBookingScreen> createState() =>
      _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  bool _loadingOptions = true;
  bool _loadingSlots = false;
  bool _submitting = false;
  String? _error;
  String? _success;

  BookingOptions _options = const BookingOptions();
  List<AppointmentSlot> _slots = [];

  final TextEditingController _patientSearch = TextEditingController();
  List<Patient> _patientResults = [];
  Patient? _patient;

  ServiceOption? _service;
  SpecialistOption? _specialist;
  final TextEditingController _dateCtrl = TextEditingController();
  String? _slot;

  @override
  void initState() {
    super.initState();
    _dateCtrl.text = _today();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOptions());
  }

  @override
  void dispose() {
    _patientSearch.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadOptions() async {
    setState(() {
      _loadingOptions = true;
      _error = null;
    });
    try {
      final opts = await context.receptionService.getBookingOptions();
      if (!mounted) return;
      setState(() {
        _options = opts;
        _loadingOptions = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingOptions = false;
      });
    }
  }

  Future<void> _searchPatients() async {
    try {
      final results =
          await context.patientService.search(term: _patientSearch.text.trim());
      if (!mounted) return;
      setState(() => _patientResults = results);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _loadSlots() async {
    if (_service == null || _specialist == null || _dateCtrl.text.isEmpty) {
      return;
    }
    setState(() {
      _loadingSlots = true;
      _slot = null;
      _error = null;
    });
    try {
      final slots = await context.receptionService.getSlots(
        serviceId: _service!.id,
        specialistId: _specialist!.id,
        departmentId: _specialist!.departmentId,
        date: _dateCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _slots = slots;
        _loadingSlots = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingSlots = false;
      });
    }
  }

  bool get _canSubmit =>
      _patient != null &&
      _service != null &&
      _service!.appointmentTypeId != null &&
      _specialist != null &&
      _slot != null &&
      !_submitting;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _submitting = true;
      _error = null;
      _success = null;
    });
    try {
      await context.receptionService.bookAppointment({
        'patient_id': _patient!.id,
        'service_id': _service!.id,
        'appointment_type_id': _service!.appointmentTypeId,
        'specialist_employee_id': _specialist!.id,
        if (_specialist!.departmentId != null)
          'department_id': _specialist!.departmentId,
        'appointment_date': _dateCtrl.text.trim(),
        'start_time': _slot,
        'is_home_visit': _service!.isHome,
      });
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _success = tr(context, ar: 'تم حجز الموعد', en: 'Appointment booked');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    if (_loadingOptions) {
      return Container(
        color: ds.colors.background,
        child: const SafeArea(child: Padding(
          padding: EdgeInsets.all(16),
          child: ShimmerLoading(),
        )),
      );
    }

    // Services filtered by the chosen appointment type of the picked service is
    // implicit — here we just show all bookable services.
    return RequestFormScaffold(
      title: t('حجز موعد', 'Book appointment'),
      subtitle: t('اختر المريض والخدمة والوقت', 'Pick patient, service and time'),
      onBack: widget.onBack,
      submitLabel: t('تأكيد الحجز', 'Confirm booking'),
      canSubmit: _canSubmit,
      submitting: _submitting,
      onSubmit: _submit,
      errorMessage: _error,
      successMessage: _success,
      children: [
        // ---- Patient ----
        SectionHeader(title: t('المريض', 'Patient')),
        if (_patient != null)
          DSCard(
            padding: EdgeInsetsDirectional.all(ds.spacing.md),
            child: Row(
              children: [
                Expanded(
                  child: DSText(_patient!.name, role: DSTextRole.title),
                ),
                DSButton(
                  label: t('تغيير', 'Change'),
                  variant: DSButtonVariant.ghost,
                  onPressed: () => setState(() => _patient = null),
                ),
              ],
            ),
          )
        else ...[
          ReceptionField(
            controller: _patientSearch,
            label: t('ابحث عن مريض', 'Search patient'),
            hint: t('الاسم أو الهاتف', 'Name or phone'),
          ),
          SizedBox(height: ds.spacing.sm),
          DSButton(
            label: t('بحث', 'Search'),
            variant: DSButtonVariant.pill,
            onPressed: _searchPatients,
          ),
          SizedBox(height: ds.spacing.sm),
          ..._patientResults.take(6).map(
                (p) => Padding(
                  padding: EdgeInsetsDirectional.only(bottom: ds.spacing.sm),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _patient = p;
                      _patientResults = [];
                    }),
                    child: DSCard(
                      padding: EdgeInsetsDirectional.all(ds.spacing.md),
                      child: Row(
                        children: [
                          Expanded(child: DSText(p.name, role: DSTextRole.title)),
                          DSText(p.phone ?? '', role: DSTextRole.caption),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
        ],
        SizedBox(height: ds.spacing.lg),

        // ---- Service ----
        SectionHeader(title: t('الخدمة', 'Service')),
        ReceptionChoiceChips<ServiceOption>(
          options: _options.services,
          selected: _service,
          labelOf: (s) => s.name,
          onSelect: (s) => setState(() {
            _service = s;
            _slots = [];
            _slot = null;
          }),
        ),
        SizedBox(height: ds.spacing.lg),

        // ---- Specialist ----
        SectionHeader(title: t('الأخصائي', 'Specialist')),
        ReceptionChoiceChips<SpecialistOption>(
          options: _options.specialists,
          selected: _specialist,
          labelOf: (s) => s.name,
          onSelect: (s) => setState(() {
            _specialist = s;
            _slots = [];
            _slot = null;
          }),
        ),
        SizedBox(height: ds.spacing.lg),

        // ---- Date + slots ----
        ReceptionField(
          controller: _dateCtrl,
          label: t('التاريخ (YYYY-MM-DD)', 'Date (YYYY-MM-DD)'),
          hint: 'YYYY-MM-DD',
        ),
        SizedBox(height: ds.spacing.sm),
        DSButton(
          label: t('عرض الأوقات', 'Show times'),
          variant: DSButtonVariant.pill,
          onPressed: (_service != null && _specialist != null) ? _loadSlots : null,
        ),
        SizedBox(height: ds.spacing.sm),
        if (_loadingSlots)
          DSText(t('جاري التحميل...', 'Loading...'), role: DSTextRole.caption)
        else if (_slots.isEmpty)
          DSText(
            t('لا توجد أوقات متاحة', 'No available times'),
            role: DSTextRole.caption,
            color: ds.colors.textSecondary,
          )
        else
          ReceptionChoiceChips<String>(
            options: _slots.where((s) => s.available).map((s) => s.start).toList(),
            selected: _slot,
            labelOf: (s) => s,
            onSelect: (s) => setState(() => _slot = s),
          ),
        SizedBox(height: ds.spacing.lg),
      ],
    );
  }
}

/// Appointment detail sheet with reception actions: confirm, mark attendance,
/// cancel. Calls back [onChanged] after any mutation so the list refreshes.
class ReceptionAppointmentDetailScreen extends StatefulWidget {
  final ReceptionAppointment appointment;
  final VoidCallback onBack;
  final VoidCallback onChanged;

  const ReceptionAppointmentDetailScreen({
    super.key,
    required this.appointment,
    required this.onBack,
    required this.onChanged,
  });

  @override
  State<ReceptionAppointmentDetailScreen> createState() =>
      _ReceptionAppointmentDetailScreenState();
}

class _ReceptionAppointmentDetailScreenState
    extends State<ReceptionAppointmentDetailScreen> {
  late ReceptionAppointment _appt = widget.appointment;
  bool _busy = false;
  String? _error;

  Future<void> _run(Future<ReceptionAppointment> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final updated = await action();
      if (!mounted) return;
      setState(() {
        _appt = updated;
        _busy = false;
      });
      widget.onChanged();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    final svc = context.receptionService;
    final canAct = !_busy &&
        (_appt.status == 'booked' || _appt.status == 'confirmed');

    return Container(
      color: ds.colors.background,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsetsDirectional.all(ds.spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  DSIconButton(
                    onPressed: widget.onBack,
                    icon: DSLineIcon(
                      type: LineIconType.arrowBack,
                      color: ds.colors.textPrimary,
                      size: ds.spacing.md,
                    ),
                  ),
                  SizedBox(width: ds.spacing.md),
                  Expanded(
                    child: DSText(
                      _appt.patientName ?? t('موعد', 'Appointment'),
                      role: DSTextRole.headline,
                    ),
                  ),
                  StatusPill(
                    label: appointmentStatusLabel(context, _appt.status),
                    color: appointmentStatusColor(_appt.status),
                  ),
                ],
              ),
              SizedBox(height: ds.spacing.lg),
              DSCard(
                padding: EdgeInsetsDirectional.all(ds.spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row(context, t('التاريخ', 'Date'),
                        '${_appt.date ?? ''}  ${_appt.startTime ?? ''}'),
                    _row(context, t('الخدمة', 'Service'), _appt.serviceName ?? '—'),
                    _row(context, t('الأخصائي', 'Specialist'),
                        _appt.specialistName ?? '—'),
                    _row(context, t('الهاتف', 'Phone'), _appt.patientPhone ?? '—'),
                    if (_appt.priceTotal != null)
                      _row(context, t('السعر', 'Price'),
                          formatMoney(context, _appt.priceTotal!)),
                  ],
                ),
              ),
              if (_error != null) ...[
                SizedBox(height: ds.spacing.md),
                DSText(_error!, role: DSTextRole.caption,
                    color: const Color(0xFFEF4444)),
              ],
              const Spacer(),
              if (canAct) ...[
                DSButton(
                  label: _appt.status == 'confirmed'
                      ? t('إلغاء التأكيد', 'Unconfirm')
                      : t('تأكيد الموعد', 'Confirm'),
                  variant: DSButtonVariant.primary,
                  expanded: true,
                  onPressed: () => _run(() => svc.confirm(_appt.id)),
                ),
                SizedBox(height: ds.spacing.sm),
                DSButton(
                  label: t('تسجيل حضور', 'Mark attended'),
                  variant: DSButtonVariant.pill,
                  expanded: true,
                  onPressed: () =>
                      _run(() => svc.setAttendance(_appt.id, 'attended')),
                ),
                SizedBox(height: ds.spacing.sm),
                DSButton(
                  label: t('إلغاء الموعد', 'Cancel appointment'),
                  variant: DSButtonVariant.ghost,
                  expanded: true,
                  onPressed: () =>
                      _run(() => svc.setAttendance(_appt.id, 'cancelled')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final ds = DSProvider.of(context);
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: ds.spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: ds.spacing.xl * 2,
            child: DSText(label,
                role: DSTextRole.caption, color: ds.colors.textSecondary),
          ),
          SizedBox(width: ds.spacing.sm),
          Expanded(child: DSText(value, role: DSTextRole.body)),
        ],
      ),
    );
  }
}
