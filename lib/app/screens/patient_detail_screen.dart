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

/// Read-only patient file for specialists: profile, visit history and
/// uploaded documents. Reached from a session's "Patient File" button.
class PatientDetailScreen extends StatefulWidget {
  final int patientId;
  final String? patientName;

  const PatientDetailScreen({
    super.key,
    required this.patientId,
    this.patientName,
  });

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  bool _isLoading = true;
  String? _error;
  Patient? _patient;
  List<PatientVisit> _visits = [];
  List<PatientDocumentInfo> _documents = [];

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

    final service = context.patientService;
    try {
      // Profile is required; the two lists are best-effort so a failure on
      // one (e.g. no documents permission) doesn't blank the whole screen.
      final patient = await service.getPatient(widget.patientId);
      if (!mounted) return;

      List<PatientVisit> visits = [];
      List<PatientDocumentInfo> documents = [];
      try {
        visits = await service.getAppointments(widget.patientId);
      } catch (_) {}
      try {
        documents = await service.getDocuments(widget.patientId);
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _patient = patient;
        _visits = visits;
        _documents = documents;
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
                      _patient?.name ??
                          widget.patientName ??
                          t('ملف المريض', 'Patient File'),
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
    if (_isLoading) {
      return const ShimmerLoading();
    }
    if (_error != null) {
      return _PatientError(message: _error!, onRetry: _load);
    }

    final patient = _patient!;
    final ds = DSProvider.of(context);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileCard(patient: patient),
              SizedBox(height: ds.spacing.lg),
              SectionHeader(
                title: t('سجل الزيارات', 'Visit History'),
              ),
              if (_visits.isEmpty)
                _EmptyLine(text: t('لا توجد زيارات', 'No visits'))
              else
                ..._visits.map((v) => Padding(
                      padding: EdgeInsetsDirectional.only(bottom: ds.spacing.sm),
                      child: _VisitTile(visit: v),
                    )),
              SizedBox(height: ds.spacing.lg),
              SectionHeader(
                title: t('المستندات', 'Documents'),
              ),
              if (_documents.isEmpty)
                _EmptyLine(text: t('لا توجد مستندات', 'No documents'))
              else
                ..._documents.map((d) => Padding(
                      padding: EdgeInsetsDirectional.only(bottom: ds.spacing.sm),
                      child: _DocumentTile(doc: d),
                    )),
              SizedBox(height: ds.spacing.xl),
            ],
          ),
        ),
      ],
    );
  }
}

// ==================== PROFILE CARD ====================

class _ProfileCard extends StatelessWidget {
  final Patient patient;

  const _ProfileCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    final rows = <(String, String?)>[
      (t('رقم الملف', 'File No.'), patient.fileNumber),
      (t('الهاتف', 'Phone'), patient.phone),
      (
        t('الجنس', 'Gender'),
        patient.gender == null
            ? null
            : (patient.gender == 'male'
                ? t('ذكر', 'Male')
                : patient.gender == 'female'
                    ? t('أنثى', 'Female')
                    : patient.gender),
      ),
      (
        t('العمر', 'Age'),
        patient.age != null ? t('${patient.age} سنة', '${patient.age} yrs') : null,
      ),
      (t('الجنسية', 'Nationality'), patient.nationality),
      (t('المدينة', 'City'), patient.city ?? patient.region),
      (t('العنوان', 'Address'), patient.address),
      if (patient.isChild) (t('ولي الأمر', 'Guardian'), patient.guardianName),
      if (patient.isChild)
        (t('هاتف ولي الأمر', 'Guardian Phone'), patient.guardianPhone),
      (t('التشخيص', 'Diagnosis'), patient.diagnosisCode?.title),
    ].where((r) => r.$2 != null && r.$2!.isNotEmpty).toList();

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
                child: DSText(patient.name, role: DSTextRole.title, maxLines: 2),
              ),
              StatusPill(
                label: patient.isActive
                    ? t('نشط', 'Active')
                    : t('غير نشط', 'Inactive'),
                color: patient.isActive
                    ? const Color(0xFF10B981)
                    : const Color(0xFF9CA3AF),
              ),
            ],
          ),
          SizedBox(height: ds.spacing.md),
          for (final r in rows) ...[
            Padding(
              padding: EdgeInsetsDirectional.only(bottom: ds.spacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: ds.spacing.xl * 2.2,
                    child: DSText(
                      r.$1,
                      role: DSTextRole.caption,
                      color: ds.colors.textSecondary,
                    ),
                  ),
                  SizedBox(width: ds.spacing.sm),
                  Expanded(
                    child: DSText(r.$2!, role: DSTextRole.body),
                  ),
                ],
              ),
            ),
          ],
          if (patient.notes != null && patient.notes!.isNotEmpty) ...[
            SizedBox(height: ds.spacing.xs),
            DSText(
              t('ملاحظات', 'Notes'),
              role: DSTextRole.caption,
              color: ds.colors.textSecondary,
            ),
            SizedBox(height: ds.spacing.xs),
            DSText(patient.notes!, role: DSTextRole.body),
          ],
        ],
      ),
    );
  }
}

// ==================== VISIT TILE ====================

class _VisitTile extends StatelessWidget {
  final PatientVisit visit;

  const _VisitTile({required this.visit});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final color = _visitStatusColor(visit.status);
    final subtitleParts = <String>[
      if (visit.appointmentDate != null) visit.appointmentDate!,
      if (visit.startTime != null) visit.startTime!,
    ];

    return DSCard(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      background: ds.colors.surface,
      shadows: ds.shadows.level1,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DSText(
                  visit.serviceName ??
                      visit.departmentName ??
                      tr(context, ar: 'زيارة', en: 'Visit'),
                  role: DSTextRole.title,
                  maxLines: 1,
                ),
                if (subtitleParts.isNotEmpty) ...[
                  SizedBox(height: ds.spacing.xs),
                  DSText(
                    subtitleParts.join(' · '),
                    role: DSTextRole.caption,
                    color: ds.colors.textSecondary,
                  ),
                ],
              ],
            ),
          ),
          StatusPill(label: _visitStatusLabel(context, visit.status), color: color),
        ],
      ),
    );
  }
}

// ==================== DOCUMENT TILE ====================

class _DocumentTile extends StatelessWidget {
  final PatientDocumentInfo doc;

  const _DocumentTile({required this.doc});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return DSCard(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      background: ds.colors.surface,
      shadows: ds.shadows.level1,
      child: Row(
        children: [
          Container(
            width: ds.spacing.xl,
            height: ds.spacing.xl,
            decoration: BoxDecoration(
              color: ds.colors.accent,
              borderRadius: BorderRadius.circular(ds.radii.medium),
            ),
            child: Center(
              child: DSLineIcon(
                type: doc.isImage ? LineIconType.heart : LineIconType.bookmark,
                color: ds.colors.primary,
                size: ds.spacing.md,
              ),
            ),
          ),
          SizedBox(width: ds.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DSText(doc.displayName, role: DSTextRole.title, maxLines: 1),
                SizedBox(height: ds.spacing.xs),
                DSText(
                  [
                    if (doc.category != null) doc.category!,
                    if (doc.readableSize != null) doc.readableSize!,
                  ].join(' · '),
                  role: DSTextRole.caption,
                  color: ds.colors.textSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== HELPERS ====================

class _EmptyLine extends StatelessWidget {
  final String text;

  const _EmptyLine({required this.text});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(vertical: ds.spacing.md),
      child: DSText(
        text,
        role: DSTextRole.caption,
        color: ds.colors.textSecondary,
      ),
    );
  }
}

class _PatientError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _PatientError({required this.message, required this.onRetry});

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

Color _visitStatusColor(String status) {
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

String _visitStatusLabel(BuildContext context, String status) {
  switch (status) {
    case 'completed':
      return tr(context, ar: 'مكتملة', en: 'Completed');
    case 'cancelled':
      return tr(context, ar: 'ملغاة', en: 'Cancelled');
    case 'no_show':
      return tr(context, ar: 'لم يحضر', en: 'No show');
    case 'checked_in':
      return tr(context, ar: 'حاضر', en: 'Checked in');
    case 'confirmed':
      return tr(context, ar: 'مؤكدة', en: 'Confirmed');
    default:
      return tr(context, ar: 'محجوزة', en: 'Booked');
  }
}
