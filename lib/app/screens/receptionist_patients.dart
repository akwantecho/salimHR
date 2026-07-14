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
import 'patient_detail_screen.dart';
import 'receptionist_common.dart';
import 'specialist_requests.dart' show RequestFormScaffold;

/// Receptionist "Patients" tab: search the clinic roster, open a patient file,
/// or add a new patient. Backed by the `patients.manage`-gated endpoints.
class ReceptionistPatientsScreen extends StatefulWidget {
  const ReceptionistPatientsScreen({super.key});

  @override
  State<ReceptionistPatientsScreen> createState() =>
      _ReceptionistPatientsScreenState();
}

class _ReceptionistPatientsScreenState
    extends State<ReceptionistPatientsScreen> {
  bool _isLoading = true;
  String? _error;
  List<Patient> _patients = [];
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results =
          await context.patientService.search(term: _search.text.trim());
      if (!mounted) return;
      setState(() {
        _patients = results;
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

  Future<void> _push(Widget Function(VoidCallback onBack) build) async {
    await Navigator.of(context).push<void>(
      PageRouteBuilder(
        pageBuilder: (ctx, _, _) => build(() => Navigator.of(ctx).pop()),
      ),
    );
    if (mounted) _load();
  }

  void _openPatient(Patient p) {
    Navigator.of(context).push<void>(
      PageRouteBuilder(
        pageBuilder: (ctx, _, _) =>
            PatientDetailScreen(patientId: p.id, patientName: p.name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    if (_isLoading) return const ShimmerLoading();
    if (_error != null) {
      return ReceptionErrorView(error: _error!, onRetry: _load);
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ReceptionField(
                      controller: _search,
                      label: t('بحث', 'Search'),
                      hint: t('الاسم أو الهاتف', 'Name or phone'),
                    ),
                  ),
                  SizedBox(width: ds.spacing.sm),
                  Padding(
                    padding: EdgeInsetsDirectional.only(top: ds.spacing.lg),
                    child: DSButton(
                      label: t('بحث', 'Go'),
                      variant: DSButtonVariant.pill,
                      onPressed: _load,
                    ),
                  ),
                ],
              ),
              SizedBox(height: ds.spacing.sm),
              DSButton(
                label: t('مريض جديد', 'New patient'),
                variant: DSButtonVariant.primary,
                expanded: true,
                onPressed: () => _push((onBack) => PatientFormScreen(onBack: onBack)),
              ),
              SizedBox(height: ds.spacing.lg),
              SectionHeader(title: t('المرضى', 'Patients')),
            ],
          ),
        ),
        if (_patients.isEmpty)
          SliverToBoxAdapter(
            child: ReceptionEmpty(message: t('لا يوجد مرضى', 'No patients')),
          )
        else
          SliverSeparatedList(
            itemBuilder: (context, index) {
              final p = _patients[index];
              return GestureDetector(
                onTap: () => _openPatient(p),
                child: DSCard(
                  padding: EdgeInsetsDirectional.all(ds.spacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DSText(p.name, role: DSTextRole.title, maxLines: 1),
                            SizedBox(height: 2),
                            DSText(
                              '${p.fileNumber ?? '—'} · ${p.phone ?? ''}',
                              role: DSTextRole.caption,
                              color: ds.colors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                      DSIconButton(
                        onPressed: () => _push(
                          (onBack) =>
                              PatientFormScreen(onBack: onBack, existing: p),
                        ),
                        icon: DSLineIcon(
                          type: LineIconType.bookmark,
                          color: ds.colors.textSecondary,
                          size: ds.spacing.md,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            itemCount: _patients.length,
            spacing: ds.spacing.sm,
          ),
        SliverToBoxAdapter(child: SizedBox(height: ds.spacing.lg)),
      ],
    );
  }
}

/// Create / edit a patient. POST /patients or PUT /patients/{id}.
class PatientFormScreen extends StatefulWidget {
  final VoidCallback onBack;
  final Patient? existing;

  const PatientFormScreen({super.key, required this.onBack, this.existing});

  @override
  State<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends State<PatientFormScreen> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _civilId;
  late final TextEditingController _nationality;
  late final TextEditingController _dob;
  late final TextEditingController _address;
  late final TextEditingController _notes;
  String? _gender;

  bool _submitting = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _phone = TextEditingController(text: e?.phone ?? '');
    _civilId = TextEditingController(text: e?.civilId ?? '');
    _nationality = TextEditingController(text: e?.nationality ?? '');
    _dob = TextEditingController(text: e?.dateOfBirth ?? '');
    _address = TextEditingController(text: e?.address ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
    _gender = e?.gender;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _civilId.dispose();
    _nationality.dispose();
    _dob.dispose();
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _name.text.trim().isNotEmpty &&
      _phone.text.trim().isNotEmpty &&
      _civilId.text.trim().isNotEmpty &&
      !_submitting;

  Map<String, dynamic> _body() {
    String? nn(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    return {
      'name': _name.text.trim(),
      'phone': _phone.text.trim(),
      'civil_id': _civilId.text.trim(),
      if (nn(_nationality) != null) 'nationality': nn(_nationality),
      if (nn(_dob) != null) 'date_of_birth': nn(_dob),
      if (nn(_address) != null) 'address': nn(_address),
      if (nn(_notes) != null) 'notes': nn(_notes),
      if (_gender != null) 'gender': _gender,
    };
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _submitting = true;
      _error = null;
      _success = null;
    });
    try {
      final svc = context.patientService;
      if (widget.existing != null) {
        await svc.update(widget.existing!.id, _body());
      } else {
        await svc.create(_body());
      }
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _success = tr(context, ar: 'تم الحفظ', en: 'Saved');
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
    final isEdit = widget.existing != null;

    return RequestFormScaffold(
      title: isEdit ? t('تعديل مريض', 'Edit patient') : t('مريض جديد', 'New patient'),
      onBack: widget.onBack,
      submitLabel: t('حفظ', 'Save'),
      canSubmit: _canSubmit,
      submitting: _submitting,
      onSubmit: _submit,
      errorMessage: _error,
      successMessage: _success,
      children: [
        ReceptionField(
          controller: _name,
          label: t('الاسم', 'Name'),
          hint: t('اسم المريض', 'Patient name'),
        ),
        SizedBox(height: ds.spacing.md),
        ReceptionField(
          controller: _phone,
          label: t('الهاتف (8 أرقام)', 'Phone (8 digits)'),
          number: true,
        ),
        SizedBox(height: ds.spacing.md),
        ReceptionField(
          controller: _civilId,
          label: t('الرقم المدني', 'Civil ID'),
        ),
        SizedBox(height: ds.spacing.md),
        DSText(t('الجنس', 'Gender'),
            role: DSTextRole.label, color: ds.colors.textSecondary),
        SizedBox(height: ds.spacing.xs),
        ReceptionChoiceChips<String>(
          options: const ['male', 'female'],
          selected: _gender,
          labelOf: (g) => g == 'male' ? t('ذكر', 'Male') : t('أنثى', 'Female'),
          onSelect: (g) => setState(() => _gender = g),
        ),
        SizedBox(height: ds.spacing.md),
        ReceptionField(
          controller: _dob,
          label: t('تاريخ الميلاد (YYYY-MM-DD)', 'Date of birth (YYYY-MM-DD)'),
          hint: 'YYYY-MM-DD',
        ),
        SizedBox(height: ds.spacing.md),
        ReceptionField(
          controller: _nationality,
          label: t('الجنسية', 'Nationality'),
        ),
        SizedBox(height: ds.spacing.md),
        ReceptionField(
          controller: _address,
          label: t('العنوان', 'Address'),
        ),
        SizedBox(height: ds.spacing.md),
        ReceptionField(
          controller: _notes,
          label: t('ملاحظات', 'Notes'),
          maxLines: 3,
        ),
        SizedBox(height: ds.spacing.lg),
      ],
    );
  }
}
