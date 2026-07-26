import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

import '../../design_system/components/line_icons.dart';
import '../../design_system/ds_provider.dart';
import '../../design_system/primitives/ds_card.dart';
import '../../design_system/primitives/ds_text.dart';
import '../../models/models.dart';
import '../../models/reception.dart';
import '../../services/api_provider.dart';
import '../app_state.dart';
import '../i18n.dart';
import '../ui/blocks.dart';
import 'specialist_screens.dart' show PromoBannerCarousel;

// ==================== RECEPTION HOME (dashboard) ====================

class ReceptionHomeScreen extends StatefulWidget {
  const ReceptionHomeScreen({super.key});

  @override
  State<ReceptionHomeScreen> createState() => _ReceptionHomeScreenState();
}

class _ReceptionHomeScreenState extends State<ReceptionHomeScreen> {
  bool _loading = true;
  Map<String, dynamic> _stats = {};
  List<ReceptionAppointment> _today = [];
  List<PromoBanner> _banners = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final lang = AppScope.of(context).locale.languageCode;
    setState(() => _loading = true);
    final rec = context.receptionService;
    final hr = context.hrService;
    final data = await rec.fetchDashboard();
    final banners = await hr.fetchPromoBanners(lang: lang);
    if (!mounted) return;
    setState(() {
      _stats = (data['stats'] as Map?)?.cast<String, dynamic>() ?? {};
      _today = ((data['appointments'] as List?) ?? [])
          .map((e) => ReceptionAppointment.fromJson(e as Map<String, dynamic>))
          .toList();
      _banners = banners;
      _loading = false;
    });
  }

  int _stat(String key) => (_stats[key] as num?)?.toInt() ?? 0;

  /// Today's appointments grouped by specialist, each list sorted by time.
  Map<String, List<ReceptionAppointment>> _bySpecialist() {
    final map = <String, List<ReceptionAppointment>>{};
    for (final a in _today) {
      final key = a.specialistName ?? tr(context, ar: 'غير محدد', en: 'Unassigned');
      map.putIfAbsent(key, () => []).add(a);
    }
    for (final list in map.values) {
      list.sort((x, y) => (x.startTime ?? '').compareTo(y.startTime ?? ''));
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    if (_loading) return const ShimmerLoading();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Promotional banners
              if (_banners.isNotEmpty) ...[
                PromoBannerCarousel(banners: _banners),
                SizedBox(height: ds.spacing.lg),
              ],

              SectionHeader(title: t('نظرة اليوم', 'Today at a glance')),
              Row(
                children: [
                  Expanded(
                    child: _RecStatCard(
                      title: t('مواعيد اليوم', 'Today'),
                      value: '${_stat('today_total')}',
                      icon: LineIconType.calendar,
                      color: const Color(0xFF6366F1),
                      onTap: () =>
                          AppScope.of(context).setTab(UserRole.reception, 1),
                    ),
                  ),
                  SizedBox(width: ds.spacing.sm),
                  Expanded(
                    child: _RecStatCard(
                      title: t('قادمة', 'Booked'),
                      value: '${_stat('today_booked')}',
                      icon: LineIconType.chart,
                      color: const Color(0xFF10B981),
                      onTap: () =>
                          AppScope.of(context).setTab(UserRole.reception, 1),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ds.spacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _RecStatCard(
                      title: t('ملغاة', 'Cancelled'),
                      value: '${_stat('today_cancelled')}',
                      icon: LineIconType.bookmark,
                      color: const Color(0xFFEF4444),
                      onTap: () =>
                          AppScope.of(context).setTab(UserRole.reception, 1),
                    ),
                  ),
                  SizedBox(width: ds.spacing.sm),
                  Expanded(
                    child: _RecStatCard(
                      title: t('إجمالي المرضى', 'Patients'),
                      value: '${_stat('patients_total')}',
                      icon: LineIconType.heart,
                      color: const Color(0xFF8B5CF6),
                      onTap: () =>
                          AppScope.of(context).setTab(UserRole.reception, 2),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ds.spacing.lg),
              // Book new appointment
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, _, __) => const ReceptionBookScreen(),
                  ),
                ),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsetsDirectional.all(ds.spacing.md),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: AlignmentDirectional.topStart,
                      end: AlignmentDirectional.bottomEnd,
                      colors: [ds.colors.primary, ds.colors.primary.withValues(alpha: 0.8)],
                    ),
                    borderRadius: BorderRadius.circular(ds.radii.large),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      DSText('+ ', role: DSTextRole.title, color: const Color(0xFFFFFFFF)),
                      DSText(
                        t('حجز موعد جديد', 'Book Appointment'),
                        role: DSTextRole.title,
                        color: const Color(0xFFFFFFFF),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: ds.spacing.sm),
              // Send notification
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, _, __) => const ReceptionNotifyScreen(),
                  ),
                ),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsetsDirectional.all(ds.spacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFF06B6D4).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(ds.radii.large),
                    border: Border.all(
                      color: const Color(0xFF06B6D4).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      DSLineIcon(type: LineIconType.bell, color: const Color(0xFF06B6D4), size: ds.spacing.md),
                      SizedBox(width: ds.spacing.sm),
                      DSText(
                        t('إرسال إشعار', 'Send Notification'),
                        role: DSTextRole.title,
                        color: const Color(0xFF06B6D4),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: ds.spacing.lg),

              // Self-service quick links
              SectionHeader(title: t('روابط سريعة', 'Quick Links')),
              Row(
                children: [
                  Expanded(
                    child: _RecQuickLink(
                      label: t('راتبي', 'My Salary'),
                      icon: LineIconType.chart,
                      color: const Color(0xFF10B981),
                      onTap: () => AppScope.of(context)
                          .showSpecialistSub(SpecialistSubScreen.salary),
                    ),
                  ),
                  SizedBox(width: ds.spacing.sm),
                  Expanded(
                    child: _RecQuickLink(
                      label: t('طلب إجازة', 'Leave Request'),
                      icon: LineIconType.calendar,
                      color: const Color(0xFF6366F1),
                      onTap: () => AppScope.of(context)
                          .showSpecialistSub(SpecialistSubScreen.leaveRequest),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ds.spacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _RecQuickLink(
                      label: t('ملاحظة', 'Note'),
                      icon: LineIconType.chat,
                      color: const Color(0xFF3B82F6),
                      onTap: () => AppScope.of(context)
                          .showSpecialistSub(SpecialistSubScreen.noteRequest),
                    ),
                  ),
                  SizedBox(width: ds.spacing.sm),
                  Expanded(
                    child: _RecQuickLink(
                      label: t('طلب مخزون', 'Inventory Request'),
                      icon: LineIconType.bookmark,
                      color: const Color(0xFFF59E0B),
                      onTap: () => AppScope.of(context)
                          .showSpecialistSub(SpecialistSubScreen.inventoryRequest),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ds.spacing.lg),

              SectionHeader(title: t('جدول اليوم', "Today's Schedule")),
            ],
          ),
        ),
        if (_today.isEmpty)
          SliverToBoxAdapter(
            child: _EmptyBox(message: t('لا توجد مواعيد اليوم', 'No appointments today')),
          )
        else
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final entry in _bySpecialist().entries) ...[
                  Padding(
                    padding: EdgeInsetsDirectional.only(
                      top: ds.spacing.sm,
                      bottom: ds.spacing.xs,
                    ),
                    child: Row(
                      children: [
                        DSLineIcon(type: LineIconType.heart, color: ds.colors.primary, size: ds.spacing.md),
                        SizedBox(width: ds.spacing.sm),
                        Expanded(child: DSText(entry.key, role: DSTextRole.title)),
                        Container(
                          padding: EdgeInsetsDirectional.symmetric(
                            horizontal: ds.spacing.sm,
                            vertical: ds.spacing.xs / 2,
                          ),
                          decoration: BoxDecoration(
                            color: ds.colors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(ds.radii.pill),
                          ),
                          child: DSText(
                            '${entry.value.length}',
                            role: DSTextRole.caption,
                            color: ds.colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final a in entry.value)
                    Padding(
                      padding: EdgeInsetsDirectional.only(bottom: ds.spacing.xs),
                      child: ReceptionAppointmentCard(appointment: a),
                    ),
                  SizedBox(height: ds.spacing.sm),
                ],
              ],
            ),
          ),
        SliverToBoxAdapter(child: SizedBox(height: ds.spacing.xl)),
      ],
    );
  }
}

// ==================== RECEPTION APPOINTMENTS ====================

class ReceptionAppointmentsScreen extends StatefulWidget {
  const ReceptionAppointmentsScreen({super.key});

  @override
  State<ReceptionAppointmentsScreen> createState() =>
      _ReceptionAppointmentsScreenState();
}

class _ReceptionAppointmentsScreenState
    extends State<ReceptionAppointmentsScreen> {
  bool _loading = true;
  DateTime _date = DateTime.now();
  List<ReceptionAppointment> _items = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  String get _dateStr =>
      '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await context.receptionService.fetchAppointments(date: _dateStr);
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  void _shiftDate(int days) {
    setState(() => _date = _date.add(Duration(days: days)));
    _load();
  }

  Future<void> _cancel(ReceptionAppointment a) async {
    final ok = await context.receptionService.cancel(a.id);
    if (ok) _load();
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date navigator
              DSCard(
                padding: EdgeInsetsDirectional.all(ds.spacing.sm),
                child: Row(
                  children: [
                    _DateArrow(icon: LineIconType.arrowBack, onTap: () => _shiftDate(-1)),
                    Expanded(
                      child: Center(
                        child: DSText(_dateStr, role: DSTextRole.title),
                      ),
                    ),
                    Transform.flip(
                      flipX: true,
                      child: _DateArrow(
                        icon: LineIconType.arrowBack,
                        onTap: () => _shiftDate(1),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: ds.spacing.md),
              SectionHeader(
                title: t('مواعيد العيادة', 'Clinic Appointments'),
                actionLabel: '${_items.length}',
              ),
            ],
          ),
        ),
        if (_loading)
          const SliverToBoxAdapter(child: ShimmerLoading())
        else if (_items.isEmpty)
          SliverToBoxAdapter(
            child: _EmptyBox(message: t('لا توجد مواعيد', 'No appointments')),
          )
        else
          SliverSeparatedList(
            itemBuilder: (context, i) => ReceptionAppointmentCard(
              appointment: _items[i],
              onCancel: _items[i].status == 'cancelled'
                  ? null
                  : () => _cancel(_items[i]),
            ),
            itemCount: _items.length,
            spacing: ds.spacing.sm,
          ),
        SliverToBoxAdapter(child: SizedBox(height: ds.spacing.xl)),
      ],
    );
  }
}

// ==================== RECEPTION PATIENTS ====================

class ReceptionPatientsScreen extends StatefulWidget {
  const ReceptionPatientsScreen({super.key});

  @override
  State<ReceptionPatientsScreen> createState() =>
      _ReceptionPatientsScreenState();
}

class _ReceptionPatientsScreenState extends State<ReceptionPatientsScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  bool _loading = true;
  List<Patient> _patients = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await context.receptionService.searchPatients(_searchCtrl.text.trim());
    if (!mounted) return;
    setState(() {
      _patients = list;
      _loading = false;
    });
  }

  Future<void> _openRegister() async {
    final created = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        pageBuilder: (context, _, __) => const ReceptionPatientFormScreen(),
      ),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    return Column(
      children: [
        // Search + register
        DSCard(
          padding: EdgeInsetsDirectional.all(ds.spacing.sm),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsetsDirectional.symmetric(
                    horizontal: ds.spacing.md,
                    vertical: ds.spacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: ds.colors.surfaceAlt,
                    borderRadius: BorderRadius.circular(ds.radii.large),
                    border: Border.all(color: ds.colors.border),
                  ),
                  child: Row(
                    children: [
                      DSLineIcon(
                        type: LineIconType.search,
                        color: ds.colors.textMuted,
                        size: ds.spacing.md,
                      ),
                      SizedBox(width: ds.spacing.sm),
                      Expanded(
                        child: EditableText(
                          controller: _searchCtrl,
                          focusNode: _searchFocus,
                          style: ds.typography.body.copyWith(
                            color: ds.colors.textPrimary,
                          ),
                          cursorColor: ds.colors.primary,
                          backgroundCursorColor: ds.colors.textMuted,
                          onSubmitted: (_) => _load(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: ds.spacing.sm),
              GestureDetector(
                onTap: _load,
                child: Container(
                  padding: EdgeInsetsDirectional.all(ds.spacing.sm + 2),
                  decoration: BoxDecoration(
                    color: ds.colors.primary,
                    borderRadius: BorderRadius.circular(ds.radii.large),
                  ),
                  child: DSText(
                    t('بحث', 'Search'),
                    role: DSTextRole.label,
                    color: const Color(0xFFFFFFFF),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: ds.spacing.sm),
        // Register new patient button
        GestureDetector(
          onTap: _openRegister,
          child: Container(
            width: double.infinity,
            padding: EdgeInsetsDirectional.all(ds.spacing.md),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(ds.radii.large),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DSText('+ ', role: DSTextRole.title, color: const Color(0xFF10B981)),
                DSText(
                  t('تسجيل مريض جديد', 'Register New Patient'),
                  role: DSTextRole.title,
                  color: const Color(0xFF10B981),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: ds.spacing.md),
        Expanded(
          child: _loading
              ? const ShimmerLoading()
              : _patients.isEmpty
              ? _EmptyBox(message: t('لا يوجد مرضى', 'No patients'))
              : ListView.separated(
                  itemCount: _patients.length,
                  separatorBuilder: (_, __) => SizedBox(height: ds.spacing.sm),
                  itemBuilder: (context, i) => GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, _, _) =>
                            ReceptionPatientDetailScreen(patient: _patients[i]),
                      ),
                    ),
                    child: _PatientCard(patient: _patients[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

// ==================== PATIENT REGISTRATION FORM ====================

class ReceptionPatientFormScreen extends StatefulWidget {
  const ReceptionPatientFormScreen({super.key});

  @override
  State<ReceptionPatientFormScreen> createState() =>
      _ReceptionPatientFormScreenState();
}

class _ReceptionPatientFormScreenState
    extends State<ReceptionPatientFormScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  String _gender = 'male';
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = tr(context, ar: 'أدخل اسم المريض', en: 'Enter patient name'));
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final patient = await context.receptionService.createPatient(
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      gender: _gender,
    );
    if (!mounted) return;
    if (patient != null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _submitting = false;
        _error = context.receptionService.error ??
            tr(context, ar: 'فشل التسجيل', en: 'Registration failed');
      });
    }
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
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: DSLineIcon(
                      type: LineIconType.arrowBack,
                      color: ds.colors.primary,
                      size: ds.spacing.lg,
                    ),
                  ),
                  SizedBox(width: ds.spacing.md),
                  DSText(t('تسجيل مريض جديد', 'New Patient'), role: DSTextRole.headline),
                ],
              ),
              SizedBox(height: ds.spacing.lg),
              _Field(label: t('اسم المريض', 'Patient Name'), controller: _name),
              SizedBox(height: ds.spacing.md),
              _Field(label: t('رقم الجوال', 'Phone'), controller: _phone),
              SizedBox(height: ds.spacing.md),
              DSText(t('الجنس', 'Gender'), role: DSTextRole.label, color: ds.colors.textSecondary),
              SizedBox(height: ds.spacing.xs),
              Row(
                children: [
                  _GenderChip(
                    label: t('ذكر', 'Male'),
                    selected: _gender == 'male',
                    onTap: () => setState(() => _gender = 'male'),
                  ),
                  SizedBox(width: ds.spacing.sm),
                  _GenderChip(
                    label: t('أنثى', 'Female'),
                    selected: _gender == 'female',
                    onTap: () => setState(() => _gender = 'female'),
                  ),
                ],
              ),
              if (_error != null) ...[
                SizedBox(height: ds.spacing.md),
                DSText(_error!, role: DSTextRole.caption, color: const Color(0xFFEF4444)),
              ],
              const Spacer(),
              GestureDetector(
                onTap: _submitting ? null : _submit,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsetsDirectional.all(ds.spacing.md),
                  decoration: BoxDecoration(
                    color: _submitting ? ds.colors.textMuted : ds.colors.primary,
                    borderRadius: BorderRadius.circular(ds.radii.large),
                  ),
                  child: Center(
                    child: DSText(
                      _submitting ? t('جاري الحفظ...', 'Saving...') : t('حفظ', 'Save'),
                      role: DSTextRole.title,
                      color: const Color(0xFFFFFFFF),
                    ),
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

// ==================== BOOK APPOINTMENT ====================

class ReceptionBookScreen extends StatefulWidget {
  const ReceptionBookScreen({super.key});

  @override
  State<ReceptionBookScreen> createState() => _ReceptionBookScreenState();
}

class _ReceptionBookScreenState extends State<ReceptionBookScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  final _timeCtrl = TextEditingController(text: '09:00');
  final _timeFocus = FocusNode();

  List<Patient> _results = [];
  Patient? _patient;
  List<NamedRef> _specialists = [];
  List<ServiceOption> _services = [];
  int? _specialistId;
  int? _serviceId;
  DateTime _date = DateTime.now();
  bool _submitting = false;
  String? _message;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOptions());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _timeCtrl.dispose();
    _timeFocus.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    final rec = context.receptionService;
    final specs = await rec.fetchSpecialists();
    final servs = await rec.fetchServices();
    if (!mounted) return;
    setState(() {
      _specialists = specs;
      _services = servs;
      _specialistId ??= specs.isNotEmpty ? specs.first.id : null;
      _serviceId ??= servs.isNotEmpty ? servs.first.id : null;
    });
  }

  Future<void> _search() async {
    final list = await context.receptionService.searchPatients(_searchCtrl.text.trim());
    if (!mounted) return;
    setState(() => _results = list);
  }

  String get _dateStr =>
      '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  Future<void> _book() async {
    if (_patient == null || _specialistId == null || _serviceId == null) {
      setState(() => _message = tr(context, ar: 'اختر المريض والأخصائي والخدمة', en: 'Pick patient, specialist and service'));
      return;
    }
    setState(() {
      _submitting = true;
      _message = null;
    });
    final booked = await context.receptionService.book(
      patientId: _patient!.id,
      specialistId: _specialistId!,
      serviceId: _serviceId!,
      date: _dateStr,
      startTime: _timeCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _success = booked != null;
      _message = booked != null
          ? tr(context, ar: 'تم حجز الموعد بنجاح', en: 'Appointment booked')
          : (context.receptionService.error ?? tr(context, ar: 'فشل الحجز', en: 'Booking failed'));
      if (booked != null) {
        _patient = null;
        _searchCtrl.clear();
        _results = [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    return Container(
      color: ds.colors.background,
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsetsDirectional.all(ds.spacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: DSLineIcon(type: LineIconType.arrowBack, color: ds.colors.primary, size: ds.spacing.lg),
                        ),
                        SizedBox(width: ds.spacing.md),
                        DSText(t('حجز موعد جديد', 'New Appointment'), role: DSTextRole.headline),
                      ],
                    ),
                    SizedBox(height: ds.spacing.lg),

                    // Patient
                    SectionHeader(title: t('المريض', 'Patient')),
                    if (_patient != null)
                      _PatientCard(patient: _patient!)
                    else ...[
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: EdgeInsetsDirectional.symmetric(horizontal: ds.spacing.md, vertical: ds.spacing.sm),
                              decoration: BoxDecoration(
                                color: ds.colors.surfaceAlt,
                                borderRadius: BorderRadius.circular(ds.radii.large),
                                border: Border.all(color: ds.colors.border),
                              ),
                              child: EditableText(
                                controller: _searchCtrl,
                                focusNode: _searchFocus,
                                style: ds.typography.body.copyWith(color: ds.colors.textPrimary),
                                cursorColor: ds.colors.primary,
                                backgroundCursorColor: ds.colors.textMuted,
                                onSubmitted: (_) => _search(),
                              ),
                            ),
                          ),
                          SizedBox(width: ds.spacing.sm),
                          GestureDetector(
                            onTap: _search,
                            child: Container(
                              padding: EdgeInsetsDirectional.all(ds.spacing.sm + 2),
                              decoration: BoxDecoration(color: ds.colors.primary, borderRadius: BorderRadius.circular(ds.radii.large)),
                              child: DSText(t('بحث', 'Search'), role: DSTextRole.label, color: const Color(0xFFFFFFFF)),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: ds.spacing.sm),
                      for (final p in _results.take(5))
                        Padding(
                          padding: EdgeInsetsDirectional.only(bottom: ds.spacing.xs),
                          child: GestureDetector(
                            onTap: () => setState(() => _patient = p),
                            child: _PatientCard(patient: p),
                          ),
                        ),
                    ],
                    if (_patient != null)
                      Padding(
                        padding: EdgeInsetsDirectional.only(top: ds.spacing.xs),
                        child: GestureDetector(
                          onTap: () => setState(() => _patient = null),
                          child: DSText(t('تغيير المريض', 'Change patient'), role: DSTextRole.caption, color: ds.colors.primary),
                        ),
                      ),
                    SizedBox(height: ds.spacing.lg),

                    // Specialist
                    SectionHeader(title: t('الأخصائي', 'Specialist')),
                    Wrap(
                      spacing: ds.spacing.xs,
                      runSpacing: ds.spacing.xs,
                      children: [
                        for (final s in _specialists)
                          _PickChip(
                            label: s.name,
                            selected: _specialistId == s.id,
                            onTap: () => setState(() => _specialistId = s.id),
                          ),
                      ],
                    ),
                    SizedBox(height: ds.spacing.lg),

                    // Service
                    SectionHeader(title: t('الخدمة', 'Service')),
                    Wrap(
                      spacing: ds.spacing.xs,
                      runSpacing: ds.spacing.xs,
                      children: [
                        for (final s in _services)
                          _PickChip(
                            label: s.name,
                            selected: _serviceId == s.id,
                            onTap: () => setState(() => _serviceId = s.id),
                          ),
                      ],
                    ),
                    SizedBox(height: ds.spacing.lg),

                    // Date + time
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DSText(t('التاريخ', 'Date'), role: DSTextRole.label, color: ds.colors.textSecondary),
                              SizedBox(height: ds.spacing.xs),
                              DSCard(
                                padding: EdgeInsetsDirectional.all(ds.spacing.xs),
                                child: Row(
                                  children: [
                                    _DateArrow(icon: LineIconType.arrowBack, onTap: () => setState(() => _date = _date.subtract(const Duration(days: 1)))),
                                    Expanded(child: Center(child: DSText(_dateStr, role: DSTextRole.label))),
                                    Transform.flip(flipX: true, child: _DateArrow(icon: LineIconType.arrowBack, onTap: () => setState(() => _date = _date.add(const Duration(days: 1))))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: ds.spacing.md),
                        SizedBox(
                          width: 110,
                          child: _Field(label: t('الوقت', 'Time'), controller: _timeCtrl),
                        ),
                      ],
                    ),

                    if (_message != null) ...[
                      SizedBox(height: ds.spacing.md),
                      DSText(_message!, role: DSTextRole.caption, color: _success ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                    ],
                    SizedBox(height: ds.spacing.lg),
                    GestureDetector(
                      onTap: _submitting ? null : _book,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsetsDirectional.all(ds.spacing.md),
                        decoration: BoxDecoration(
                          color: _submitting ? ds.colors.textMuted : ds.colors.primary,
                          borderRadius: BorderRadius.circular(ds.radii.large),
                        ),
                        child: Center(
                          child: DSText(
                            _submitting ? t('جاري الحجز...', 'Booking...') : t('تأكيد الحجز', 'Confirm Booking'),
                            role: DSTextRole.title,
                            color: const Color(0xFFFFFFFF),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: ds.spacing.xl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== SEND NOTIFICATION ====================

class ReceptionNotifyScreen extends StatefulWidget {
  const ReceptionNotifyScreen({super.key});

  @override
  State<ReceptionNotifyScreen> createState() => _ReceptionNotifyScreenState();
}

class _ReceptionNotifyScreenState extends State<ReceptionNotifyScreen> {
  final _title = TextEditingController();
  final _message = TextEditingController();
  final _messageFocus = FocusNode();
  List<NamedRef> _specialists = [];
  int? _target; // null = all
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;
  String? _imageUrl;
  bool _uploading = false;
  bool _submitting = false;
  String? _msg;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _imageBytes = bytes;
      _uploading = true;
    });
    final url = await context.receptionService
        .uploadNotificationImage(bytes, filename: file.name);
    if (!mounted) return;
    setState(() {
      _imageUrl = url;
      _uploading = false;
      if (url == null) _imageBytes = null;
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    _messageFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final specs = await context.receptionService.fetchRecipients();
    if (!mounted) return;
    setState(() => _specialists = specs);
  }

  Future<void> _send() async {
    if (_title.text.trim().isEmpty || _message.text.trim().isEmpty) {
      setState(() => _msg = tr(context, ar: 'أدخل العنوان والرسالة', en: 'Enter title and message'));
      return;
    }
    setState(() {
      _submitting = true;
      _msg = null;
    });
    final sent = await context.receptionService.sendNotification(
      title: _title.text.trim(),
      message: _message.text.trim(),
      specialistId: _target,
      imageUrl: _imageUrl,
    );
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _success = sent != null;
      _msg = sent != null
          ? tr(context, ar: 'تم إرسال الإشعار إلى $sent', en: 'Sent to $sent')
          : (context.receptionService.error ?? tr(context, ar: 'فشل الإرسال', en: 'Send failed'));
      if (sent != null) {
        _title.clear();
        _message.clear();
        _imageBytes = null;
        _imageUrl = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    return Container(
      color: ds.colors.background,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            ds.spacing.lg,
            ds.spacing.lg,
            ds.spacing.lg,
            ds.spacing.lg + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: DSLineIcon(type: LineIconType.arrowBack, color: ds.colors.primary, size: ds.spacing.lg),
                  ),
                  SizedBox(width: ds.spacing.md),
                  DSText(t('إرسال إشعار', 'Send Notification'), role: DSTextRole.headline),
                ],
              ),
              SizedBox(height: ds.spacing.lg),
              DSText(t('إلى', 'To'), role: DSTextRole.label, color: ds.colors.textSecondary),
              SizedBox(height: ds.spacing.xs),
              Wrap(
                spacing: ds.spacing.xs,
                runSpacing: ds.spacing.xs,
                children: [
                  _PickChip(
                    label: t('الكل', 'Everyone'),
                    selected: _target == null,
                    onTap: () => setState(() => _target = null),
                  ),
                  for (final s in _specialists)
                    _PickChip(
                      label: s.name,
                      selected: _target == s.id,
                      onTap: () => setState(() => _target = s.id),
                    ),
                ],
              ),
              SizedBox(height: ds.spacing.lg),
              _Field(label: t('العنوان', 'Title'), controller: _title),
              SizedBox(height: ds.spacing.md),
              DSText(t('الرسالة', 'Message'), role: DSTextRole.label, color: ds.colors.textSecondary),
              SizedBox(height: ds.spacing.xs),
              Container(
                height: 140,
                padding: EdgeInsetsDirectional.all(ds.spacing.md),
                decoration: BoxDecoration(
                  color: ds.colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(ds.radii.large),
                  border: Border.all(color: ds.colors.border, width: 1.5),
                ),
                child: EditableText(
                  controller: _message,
                  focusNode: _messageFocus,
                  maxLines: null,
                  style: ds.typography.body.copyWith(color: ds.colors.textPrimary),
                  cursorColor: ds.colors.primary,
                  backgroundCursorColor: ds.colors.textMuted,
                ),
              ),
              SizedBox(height: ds.spacing.md),
              // Attach image
              if (_imageBytes != null) ...[
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(ds.radii.large),
                      child: Image.memory(
                        _imageBytes!,
                        width: double.infinity,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (_uploading)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0x66000000),
                            borderRadius: BorderRadius.circular(ds.radii.large),
                          ),
                          alignment: Alignment.center,
                          child: DSText(t('جاري الرفع...', 'Uploading...'),
                              role: DSTextRole.label, color: const Color(0xFFFFFFFF)),
                        ),
                      ),
                    PositionedDirectional(
                      top: ds.spacing.xs,
                      end: ds.spacing.xs,
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _imageBytes = null;
                          _imageUrl = null;
                        }),
                        child: Container(
                          padding: EdgeInsetsDirectional.all(ds.spacing.xs),
                          decoration: const BoxDecoration(
                            color: Color(0xCC000000),
                            shape: BoxShape.circle,
                          ),
                          child: DSText('✕', role: DSTextRole.label, color: const Color(0xFFFFFFFF)),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else
                GestureDetector(
                  onTap: _pickImage,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsetsDirectional.all(ds.spacing.md),
                    decoration: BoxDecoration(
                      color: ds.colors.surfaceAlt,
                      borderRadius: BorderRadius.circular(ds.radii.large),
                      border: Border.all(color: ds.colors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DSLineIcon(type: LineIconType.search, color: ds.colors.primary, size: ds.spacing.md),
                        SizedBox(width: ds.spacing.sm),
                        DSText(t('إرفاق صورة (اختياري)', 'Attach image (optional)'),
                            role: DSTextRole.label, color: ds.colors.primary),
                      ],
                    ),
                  ),
                ),
              if (_msg != null) ...[
                SizedBox(height: ds.spacing.md),
                DSText(_msg!, role: DSTextRole.caption, color: _success ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
              ],
              SizedBox(height: ds.spacing.lg),
              GestureDetector(
                onTap: _submitting ? null : _send,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsetsDirectional.all(ds.spacing.md),
                  decoration: BoxDecoration(
                    color: _submitting ? ds.colors.textMuted : ds.colors.primary,
                    borderRadius: BorderRadius.circular(ds.radii.large),
                  ),
                  child: Center(
                    child: DSText(
                      _submitting ? t('جاري الإرسال...', 'Sending...') : t('إرسال', 'Send'),
                      role: DSTextRole.title,
                      color: const Color(0xFFFFFFFF),
                    ),
                  ),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PickChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PickChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsetsDirectional.symmetric(horizontal: ds.spacing.md, vertical: ds.spacing.sm),
        decoration: BoxDecoration(
          color: selected ? ds.colors.primary : ds.colors.surfaceAlt,
          borderRadius: BorderRadius.circular(ds.radii.pill),
          border: Border.all(color: selected ? ds.colors.primary : ds.colors.border),
        ),
        child: DSText(label, role: DSTextRole.label, color: selected ? const Color(0xFFFFFFFF) : ds.colors.textSecondary),
      ),
    );
  }
}

// ==================== SHARED WIDGETS ====================

class ReceptionAppointmentCard extends StatelessWidget {
  final ReceptionAppointment appointment;
  final VoidCallback? onCancel;

  const ReceptionAppointmentCard({
    super.key,
    required this.appointment,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final color = _statusColor(appointment.status);
    return DSCard(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: ds.spacing.sm,
                  vertical: ds.spacing.xs / 2,
                ),
                decoration: BoxDecoration(
                  color: ds.colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(ds.radii.medium),
                ),
                child: DSText(
                  appointment.startTime ?? '--',
                  role: DSTextRole.label,
                  color: ds.colors.primary,
                ),
              ),
              SizedBox(width: ds.spacing.sm),
              Expanded(
                child: DSText(
                  appointment.patient?.name ?? '-',
                  role: DSTextRole.title,
                ),
              ),
              Container(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: ds.spacing.sm,
                  vertical: ds.spacing.xs / 2,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(ds.radii.pill),
                ),
                child: DSText(
                  _statusLabel(context, appointment.status),
                  role: DSTextRole.caption,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: ds.spacing.xs),
          Row(
            children: [
              DSLineIcon(type: LineIconType.heart, color: ds.colors.textMuted, size: ds.spacing.sm + 2),
              SizedBox(width: ds.spacing.xs),
              Expanded(
                child: DSText(
                  '${appointment.specialistName ?? '-'}${appointment.serviceName != null ? ' · ${appointment.serviceName}' : ''}',
                  role: DSTextRole.caption,
                  color: ds.colors.textSecondary,
                ),
              ),
              if (onCancel != null)
                GestureDetector(
                  onTap: onCancel,
                  child: DSText(
                    tr(context, ar: 'إلغاء', en: 'Cancel'),
                    role: DSTextRole.caption,
                    color: const Color(0xFFEF4444),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final Patient patient;

  const _PatientCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final color = patient.gender == 'female'
        ? const Color(0xFFEC4899)
        : const Color(0xFF3B82F6);
    return DSCard(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      child: Row(
        children: [
          Container(
            width: ds.spacing.xl,
            height: ds.spacing.xl,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(ds.radii.medium),
            ),
            child: Center(
              child: DSLineIcon(type: LineIconType.heart, color: color, size: ds.spacing.md),
            ),
          ),
          SizedBox(width: ds.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DSText(patient.name, role: DSTextRole.title, maxLines: 1),
                SizedBox(height: 2),
                DSText(
                  '${patient.fileNumber ?? ''}${patient.phone != null ? ' · ${patient.phone}' : ''}',
                  role: DSTextRole.caption,
                  color: ds.colors.textMuted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecQuickLink extends StatelessWidget {
  final String label;
  final LineIconType icon;
  final Color color;
  final VoidCallback onTap;

  const _RecQuickLink({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsetsDirectional.all(ds.spacing.md),
        decoration: BoxDecoration(
          color: ds.colors.surface,
          borderRadius: BorderRadius.circular(ds.radii.large),
          border: Border.all(color: ds.colors.border),
        ),
        child: Row(
          children: [
            Container(
              width: ds.spacing.xl,
              height: ds.spacing.xl,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(ds.radii.medium),
              ),
              child: Center(
                child: DSLineIcon(type: icon, color: color, size: ds.spacing.md),
              ),
            ),
            SizedBox(width: ds.spacing.sm),
            Expanded(
              child: DSText(label, role: DSTextRole.label, maxLines: 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecStatCard extends StatelessWidget {
  final String title;
  final String value;
  final LineIconType icon;
  final Color color;
  final VoidCallback? onTap;

  const _RecStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final card = Container(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ds.radii.large),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DSLineIcon(type: icon, color: color, size: ds.spacing.md),
              Flexible(
                child: DSText(value, role: DSTextRole.headline, color: color),
              ),
            ],
          ),
          SizedBox(height: ds.spacing.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: DSText(title, role: DSTextRole.caption, color: ds.colors.textSecondary),
          ),
        ],
      ),
    );

    if (onTap == null) return card;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }
}

class _DateArrow extends StatelessWidget {
  final LineIconType icon;
  final VoidCallback onTap;

  const _DateArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsetsDirectional.all(ds.spacing.sm),
        child: DSLineIcon(type: icon, color: ds.colors.primary, size: ds.spacing.md),
      ),
    );
  }
}

class _GenderChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GenderChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: ds.spacing.lg,
          vertical: ds.spacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? ds.colors.primary : ds.colors.surfaceAlt,
          borderRadius: BorderRadius.circular(ds.radii.pill),
          border: Border.all(
            color: selected ? ds.colors.primary : ds.colors.border,
          ),
        ),
        child: DSText(
          label,
          role: DSTextRole.label,
          color: selected ? const Color(0xFFFFFFFF) : ds.colors.textSecondary,
        ),
      ),
    );
  }
}

class _Field extends StatefulWidget {
  final String label;
  final TextEditingController controller;

  const _Field({required this.label, required this.controller});

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  final _focus = FocusNode();

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
            vertical: ds.spacing.sm + 2,
          ),
          decoration: BoxDecoration(
            color: ds.colors.surfaceAlt,
            borderRadius: BorderRadius.circular(ds.radii.large),
            border: Border.all(color: ds.colors.border, width: 1.5),
          ),
          child: EditableText(
            controller: widget.controller,
            focusNode: _focus,
            style: ds.typography.body.copyWith(color: ds.colors.textPrimary),
            cursorColor: ds.colors.primary,
            backgroundCursorColor: ds.colors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final String message;

  const _EmptyBox({required this.message});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsetsDirectional.all(ds.spacing.xl),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DSLineIcon(type: LineIconType.calendar, color: ds.colors.textMuted, size: ds.spacing.xl),
          SizedBox(height: ds.spacing.sm),
          DSText(message, role: DSTextRole.body, color: ds.colors.textSecondary),
        ],
      ),
    );
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'completed':
      return const Color(0xFF10B981);
    case 'checked_in':
      return const Color(0xFFF59E0B);
    case 'cancelled':
      return const Color(0xFF94A3B8);
    case 'no_show':
      return const Color(0xFFEF4444);
    default:
      return const Color(0xFF6366F1);
  }
}

String _statusLabel(BuildContext context, String status) {
  switch (status) {
    case 'completed':
      return tr(context, ar: 'مكتمل', en: 'Done');
    case 'checked_in':
      return tr(context, ar: 'حاضر', en: 'In');
    case 'cancelled':
      return tr(context, ar: 'ملغى', en: 'Cancelled');
    case 'no_show':
      return tr(context, ar: 'لم يحضر', en: 'No show');
    default:
      return tr(context, ar: 'محجوز', en: 'Booked');
  }
}

// ==================== PATIENT DETAIL (reception) ====================

/// Full patient file for reception: profile, appointments and remaining
/// sessions. Data comes from GET /api/reception/patients/{id}.
class ReceptionPatientDetailScreen extends StatefulWidget {
  final Patient patient;

  const ReceptionPatientDetailScreen({super.key, required this.patient});

  @override
  State<ReceptionPatientDetailScreen> createState() =>
      _ReceptionPatientDetailScreenState();
}

class _ReceptionPatientDetailScreenState
    extends State<ReceptionPatientDetailScreen> {
  bool _loading = true;
  Map<String, dynamic>? _data;
  List<ReceptionAppointment> _appointments = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final d = await context.receptionService.fetchPatientDetail(widget.patient.id);
    if (!mounted) return;
    setState(() {
      _data = d;
      _appointments = ((d?['appointments'] as List?) ?? [])
          .map((e) => ReceptionAppointment.fromJson(e as Map<String, dynamic>))
          .toList();
      _loading = false;
    });
  }

  int _summary(String key) {
    final s = _data?['sessions_summary'] as Map?;
    return (s?[key] as num?)?.toInt() ?? 0;
  }

  String _field(String key) {
    final v = _data?[key];
    return (v == null || v.toString().isEmpty) ? '—' : v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    final p = widget.patient;

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
                    child: DSLineIcon(
                        type: LineIconType.arrowBack,
                        color: ds.colors.primary,
                        size: ds.spacing.lg),
                  ),
                  SizedBox(width: ds.spacing.md),
                  Expanded(
                    child: DSText(p.name, role: DSTextRole.headline, maxLines: 1),
                  ),
                ],
              ),
              SizedBox(height: ds.spacing.md),
              Expanded(
                child: _loading
                    ? const ShimmerLoading()
                    : ListView(
                        children: [
                          // Profile
                          DSCard(
                            padding: EdgeInsetsDirectional.all(ds.spacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _row(t('رقم الملف', 'File No'),
                                    p.fileNumber ?? _field('file_number')),
                                _row(t('الجوال', 'Phone'),
                                    p.phone ?? _field('phone')),
                                _row(
                                    t('الجنس', 'Gender'),
                                    p.gender == 'female'
                                        ? t('أنثى', 'Female')
                                        : t('ذكر', 'Male')),
                                _row(t('الجنسية', 'Nationality'),
                                    p.nationality ?? _field('nationality')),
                                _row(t('تاريخ الميلاد', 'Date of birth'),
                                    _field('date_of_birth')),
                              ],
                            ),
                          ),
                          SizedBox(height: ds.spacing.md),
                          // Sessions summary
                          SectionHeader(title: t('الجلسات', 'Sessions')),
                          Row(
                            children: [
                              Expanded(
                                  child: _summaryCard(
                                      t('الإجمالي', 'Total'),
                                      _summary('total'),
                                      const Color(0xFF6366F1))),
                              SizedBox(width: ds.spacing.sm),
                              Expanded(
                                  child: _summaryCard(
                                      t('مكتملة', 'Done'),
                                      _summary('completed'),
                                      const Color(0xFF10B981))),
                              SizedBox(width: ds.spacing.sm),
                              Expanded(
                                  child: _summaryCard(
                                      t('متبقّية', 'Left'),
                                      _summary('remaining'),
                                      const Color(0xFFF59E0B))),
                            ],
                          ),
                          SizedBox(height: ds.spacing.md),
                          // Appointments
                          SectionHeader(
                              title: t('المواعيد', 'Appointments')),
                          if (_appointments.isEmpty)
                            _EmptyBox(
                                message:
                                    t('لا توجد مواعيد', 'No appointments'))
                          else
                            for (final a in _appointments) ...[
                              ReceptionAppointmentCard(appointment: a),
                              SizedBox(height: ds.spacing.sm),
                            ],
                          SizedBox(height: ds.spacing.xl),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    final ds = DSProvider.of(context);
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: ds.spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              flex: 2,
              child: DSText(label,
                  role: DSTextRole.caption, color: ds.colors.textSecondary)),
          SizedBox(width: ds.spacing.sm),
          Expanded(flex: 3, child: DSText(value, role: DSTextRole.body)),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, int value, Color color) {
    final ds = DSProvider.of(context);
    return Container(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ds.radii.large),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          DSText('$value', role: DSTextRole.headline, color: color),
          SizedBox(height: ds.spacing.xs),
          DSText(label,
              role: DSTextRole.caption, color: ds.colors.textSecondary),
        ],
      ),
    );
  }
}
