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

/// Search-and-attach a diagnosis code to an appointment.
class DiagnosisPickerScreen extends StatefulWidget {
  final int appointmentId;

  const DiagnosisPickerScreen({super.key, required this.appointmentId});

  @override
  State<DiagnosisPickerScreen> createState() => _DiagnosisPickerScreenState();
}

class _DiagnosisPickerScreenState extends State<DiagnosisPickerScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  bool _loading = true;
  bool _searching = false;
  bool _saving = false;
  String? _error;
  DiagnosisCode? _current;
  List<DiagnosisCode> _results = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.text != _query) {
        _query = _controller.text;
        _search(_query);
      }
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
    try {
      final current =
          await context.diagnosisService.getForAppointment(widget.appointmentId);
      if (!mounted) return;
      setState(() {
        _current = current;
        _loading = false;
      });
      // Seed the list with an initial (unfiltered) fetch.
      _search('');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _search(String query) async {
    setState(() => _searching = true);
    try {
      final results = await context.diagnosisService.search(query.trim());
      if (!mounted) return;
      // Ignore stale responses if the query moved on.
      if (query != _query) return;
      setState(() {
        _results = results;
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _error = e is ApiException ? e.message : e.toString();
      });
    }
  }

  Future<void> _select(DiagnosisCode? code) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await context.diagnosisService.setForAppointment(
        appointmentId: widget.appointmentId,
        diagnosisCodeId: code?.id,
      );
      if (!mounted) return;
      setState(() {
        _current = saved;
        _saving = false;
      });
      Navigator.of(context).pop(saved);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e is ApiException ? e.message : e.toString();
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
                      t('التشخيص', 'Diagnosis'),
                      role: DSTextRole.headline,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              SizedBox(height: ds.spacing.lg),
              if (_current != null) ...[
                DSCard(
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
                              t('الحالي', 'Current'),
                              role: DSTextRole.caption,
                              color: ds.colors.textSecondary,
                            ),
                            SizedBox(height: ds.spacing.xs),
                            DSText(_current!.display, role: DSTextRole.title),
                          ],
                        ),
                      ),
                      DSButton(
                        label: t('إزالة', 'Clear'),
                        variant: DSButtonVariant.ghost,
                        onPressed: _saving ? null : () => _select(null),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: ds.spacing.md),
              ],
              _SearchField(
                controller: _controller,
                focusNode: _focus,
                hint: t('ابحث بالرمز أو الاسم', 'Search by code or title'),
              ),
              if (_error != null) ...[
                SizedBox(height: ds.spacing.sm),
                DSText(
                  _error!,
                  role: DSTextRole.caption,
                  color: const Color(0xFFEF4444),
                ),
              ],
              SizedBox(height: ds.spacing.md),
              Expanded(child: _resultsList(context, t)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultsList(BuildContext context, String Function(String, String) t) {
    final ds = DSProvider.of(context);
    if (_loading) return const ShimmerLoading();
    if (_searching && _results.isEmpty) return const ShimmerLoading();
    if (_results.isEmpty) {
      return Center(
        child: DSText(
          t('لا توجد نتائج', 'No results'),
          role: DSTextRole.caption,
          color: ds.colors.textSecondary,
        ),
      );
    }

    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (_, __) => SizedBox(height: ds.spacing.sm),
      itemBuilder: (context, index) {
        final code = _results[index];
        final selected = _current?.id == code.id;
        return GestureDetector(
          onTap: _saving ? null : () => _select(code),
          behavior: HitTestBehavior.opaque,
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
                      if (code.code != null)
                        DSText(code.code!, role: DSTextRole.label),
                      SizedBox(height: ds.spacing.xs),
                      DSText(
                        code.title ?? code.display,
                        role: DSTextRole.body,
                        color: ds.colors.textSecondary,
                      ),
                    ],
                  ),
                ),
                if (selected)
                  DSLineIcon(
                    type: LineIconType.heart,
                    color: ds.colors.primary,
                    size: ds.spacing.md,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;

  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Container(
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
              controller: controller,
              focusNode: focusNode,
              style: ds.typography.body.copyWith(color: ds.colors.textPrimary),
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
    );
  }
}
