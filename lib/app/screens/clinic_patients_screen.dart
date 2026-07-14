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
import 'patient_detail_screen.dart';

/// Clinic patients list with search (manager drill-down). Tapping a patient
/// opens the read-only patient file (which enforces its own access rules).
class ClinicPatientsScreen extends StatefulWidget {
  const ClinicPatientsScreen({super.key});

  @override
  State<ClinicPatientsScreen> createState() => _ClinicPatientsScreenState();
}

class _ClinicPatientsScreenState extends State<ClinicPatientsScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  bool _loading = true;
  String? _error;
  List<ClinicPatient> _items = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.text != _query) {
        _query = _controller.text;
        _load(_query);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(''));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _load(String query) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await context.clinicService.getPatients(search: query.trim());
      if (!mounted || query != _query) return;
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
                      t('مرضى العيادة', 'Clinic Patients'),
                      role: DSTextRole.headline,
                      maxLines: 1,
                    ),
                  ),
                ],
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
                child: Row(
                  children: [
                    DSLineIcon(
                      type: LineIconType.bookmark,
                      color: ds.colors.textMuted,
                      size: ds.spacing.md,
                    ),
                    SizedBox(width: ds.spacing.sm),
                    Expanded(
                      child: EditableText(
                        controller: _controller,
                        focusNode: _focus,
                        style: ds.typography.body
                            .copyWith(color: ds.colors.textPrimary),
                        cursorColor: ds.colors.primary,
                        backgroundCursorColor: ds.colors.textMuted,
                        maxLines: 1,
                        textAlign: ds.textDirection == TextDirection.rtl
                            ? TextAlign.right
                            : TextAlign.left,
                      ),
                    ),
                  ],
                ),
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
          t('لا نتائج', 'No results'),
          role: DSTextRole.caption,
          color: ds.colors.textSecondary,
        ),
      );
    }
    return ListView.separated(
      itemCount: _items.length,
      separatorBuilder: (_, i) => SizedBox(height: ds.spacing.sm),
      itemBuilder: (context, index) {
        final p = _items[index];
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).push<void>(
            PageRouteBuilder(
              pageBuilder: (context, _, _) => PatientDetailScreen(
                patientId: p.id,
                patientName: p.name,
              ),
            ),
          ),
          child: DSCard(
            padding: EdgeInsetsDirectional.all(ds.spacing.md),
            background: ds.colors.surface,
            shadows: ds.shadows.level1,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DSText(p.name, role: DSTextRole.title, maxLines: 1),
                      SizedBox(height: ds.spacing.xs),
                      DSText(
                        [
                          if (p.fileNumber != null) '#${p.fileNumber}',
                          if (p.phone != null) p.phone!,
                        ].join(' · '),
                        role: DSTextRole.caption,
                        color: ds.colors.textSecondary,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                Transform.flip(
                  flipX: true,
                  child: DSLineIcon(
                    type: LineIconType.arrowBack,
                    color: ds.colors.textMuted,
                    size: ds.spacing.sm,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
