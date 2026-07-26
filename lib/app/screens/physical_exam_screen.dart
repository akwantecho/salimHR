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

/// Full physical-examination form for a patient, entered from the phone.
/// Sections are collapsible so the large clinical form fits the screen.
class PhysicalExamScreen extends StatefulWidget {
  final int appointmentId;
  final String? patientName;

  const PhysicalExamScreen({
    super.key,
    required this.appointmentId,
    this.patientName,
  });

  @override
  State<PhysicalExamScreen> createState() => _PhysicalExamScreenState();
}

class _PhysicalExamScreenState extends State<PhysicalExamScreen> {
  PhysicalExam? _exam;
  bool _loading = true;
  bool _saving = false;
  String? _message;
  final Map<String, TextEditingController> _controllers = {};
  final Set<String> _open = {'current_condition'}; // sections expanded

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final exam = await context.hrService.fetchPhysicalExam(widget.appointmentId);
    if (!mounted) return;
    setState(() {
      _exam = exam ?? PhysicalExam();
      _loading = false;
    });
  }

  TextEditingController _ctrl(String key, String? initial) {
    return _controllers.putIfAbsent(
      key,
      () => TextEditingController(text: initial ?? ''),
    );
  }

  Future<void> _save({required bool complete}) async {
    final exam = _exam!;
    if (complete) exam.status = 'completed';
    setState(() {
      _saving = true;
      _message = null;
    });
    final ok = await context.hrService.savePhysicalExam(widget.appointmentId, exam);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _message = ok
          ? tr(context, ar: 'تم الحفظ', en: 'Saved')
          : (context.hrService.error ??
              tr(context, ar: 'تعذّر الحفظ', en: 'Could not save'));
    });
  }

  void _toggle(String key) => setState(
      () => _open.contains(key) ? _open.remove(key) : _open.add(key));

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DSText(t('الفحص الفيزيائي', 'Physical Exam'),
                            role: DSTextRole.headline),
                        if (widget.patientName != null)
                          DSText(widget.patientName!,
                              role: DSTextRole.caption,
                              color: ds.colors.textSecondary),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: ds.spacing.md),
              Expanded(
                child: _loading || _exam == null
                    ? const ShimmerLoading()
                    : ListView(
                        children: [
                          for (final s in physicalExamSchema)
                            _section(s.key, t(s.ar, s.en),
                                _fieldsBody(s)),
                          _section('body_marks',
                              t('علامات الجسم', 'Body Marks'), _bodyMarksBody()),
                          _section('gait', t('تحليل المشية', 'Gait Analysis'),
                              _gaitBody()),
                          _section('problems', t('المشاكل', 'Problems'),
                              _listBody(_exam!.problems)),
                          _section('treatment_plans',
                              t('خطة العلاج', 'Treatment Plan'),
                              _listBody(_exam!.treatmentPlans)),
                          _section('remarks', t('ملاحظات', 'Remarks'),
                              _remarksBody()),
                          SizedBox(height: ds.spacing.md),
                          if (_message != null) ...[
                            DSText(_message!,
                                role: DSTextRole.caption,
                                color: ds.colors.primary),
                            SizedBox(height: ds.spacing.sm),
                          ],
                          Row(
                            children: [
                              Expanded(
                                child: DSButton(
                                  label: _saving
                                      ? t('جارٍ الحفظ...', 'Saving...')
                                      : t('حفظ كمسودّة', 'Save draft'),
                                  variant: DSButtonVariant.ghost,
                                  onPressed: _saving
                                      ? null
                                      : () => _save(complete: false),
                                ),
                              ),
                              SizedBox(width: ds.spacing.sm),
                              Expanded(
                                child: DSButton(
                                  label: t('اعتماد', 'Complete'),
                                  variant: DSButtonVariant.primary,
                                  onPressed: _saving
                                      ? null
                                      : () => _save(complete: true),
                                ),
                              ),
                            ],
                          ),
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

  // ---------- section shell ----------

  Widget _section(String key, String title, Widget body) {
    final ds = DSProvider.of(context);
    final open = _open.contains(key);
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: ds.spacing.sm),
      child: DSCard(
        padding: EdgeInsetsDirectional.all(ds.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => _toggle(key),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Expanded(child: DSText(title, role: DSTextRole.title)),
                  DSText(open ? '−' : '+',
                      role: DSTextRole.headline, color: ds.colors.primary),
                ],
              ),
            ),
            if (open) ...[
              SizedBox(height: ds.spacing.md),
              body,
            ],
          ],
        ),
      ),
    );
  }

  // ---------- generic field-based section ----------

  Widget _fieldsBody(PxSection s) {
    final ds = DSProvider.of(context);
    String tr2(PxField f) => tr(context, ar: f.ar, en: f.en);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (s.readOnly) ...[
          DSText(
            tr(context,
                ar: 'بيانات المريض من النظام (غير قابلة للتعديل)',
                en: 'Patient data from the system (read-only)'),
            role: DSTextRole.caption,
            color: ds.colors.textMuted,
          ),
          SizedBox(height: ds.spacing.sm),
        ],
        for (final f in s.fields) ...[
          s.readOnly
              ? _readOnlyField(s.key, f, tr2(f))
              : _field(s.key, f, tr2(f)),
          SizedBox(height: s.readOnly ? ds.spacing.sm : ds.spacing.md),
        ],
      ],
    );
  }

  Widget _readOnlyField(String section, PxField f, String label) {
    final ds = DSProvider.of(context);
    final raw = _exam!.value(section, f.key);
    String display;
    if (raw == null || raw.toString().isEmpty) {
      display = '—';
    } else if (f.type == PxFieldType.boolean) {
      display = (raw == true || raw == 1 || raw == '1')
          ? tr(context, ar: 'نعم', en: 'Yes')
          : tr(context, ar: 'لا', en: 'No');
    } else if (f.type == PxFieldType.select) {
      final opt = f.options.where((o) => o.value == raw.toString());
      final isAr = tr(context, ar: 'ar', en: 'en') == 'ar';
      display = opt.isNotEmpty
          ? (isAr ? opt.first.ar : opt.first.en)
          : raw.toString();
    } else {
      display = raw.toString();
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: DSText(label,
              role: DSTextRole.caption, color: ds.colors.textSecondary),
        ),
        SizedBox(width: ds.spacing.sm),
        Expanded(flex: 3, child: DSText(display, role: DSTextRole.body)),
      ],
    );
  }

  Widget _field(String section, PxField f, String label) {
    final key = '$section.${f.key}';
    final current = _exam!.value(section, f.key);
    switch (f.type) {
      case PxFieldType.boolean:
        return _PxBool(
          label: label,
          value: current == true || current == 1 || current == '1',
          onChanged: (v) => setState(() => _exam!.setValue(section, f.key, v)),
        );
      case PxFieldType.select:
        return _PxSelect(
          label: label,
          options: f.options,
          value: current?.toString(),
          onChanged: (v) => _exam!.setValue(section, f.key, v),
        );
      default:
        final ctrl = _ctrl(key, current?.toString());
        return _PxText(
          label: label,
          controller: ctrl,
          multiline: f.type == PxFieldType.textarea,
          number: f.type == PxFieldType.intNum ||
              f.type == PxFieldType.decimalNum,
          onChanged: (v) => _exam!.setValue(section, f.key, v),
        );
    }
  }

  // ---------- problems / treatment plans (string lists) ----------

  Widget _listBody(List<String> items) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: EdgeInsetsDirectional.only(bottom: ds.spacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: _PxText(
                    label: '${i + 1}',
                    controller: _ctrl('list_${identityHashCode(items)}_$i', items[i]),
                    onChanged: (v) => items[i] = v,
                  ),
                ),
                SizedBox(width: ds.spacing.xs),
                GestureDetector(
                  onTap: () => setState(() {
                    items.removeAt(i);
                    _controllers.remove('list_${identityHashCode(items)}_$i');
                  }),
                  behavior: HitTestBehavior.opaque,
                  child: DSLineIcon(
                      type: LineIconType.trash,
                      color: const Color(0xFFEF4444),
                      size: ds.spacing.md),
                ),
              ],
            ),
          ),
        GestureDetector(
          onTap: () => setState(() => items.add('')),
          behavior: HitTestBehavior.opaque,
          child: DSText('+ ${t('إضافة', 'Add')}',
              role: DSTextRole.label, color: ds.colors.primary),
        ),
      ],
    );
  }

  // ---------- remarks ----------

  Widget _remarksBody() {
    final ctrl = _ctrl('remarks', _exam!.remarks);
    return _PxText(
      label: tr(context, ar: 'ملاحظات عامة', en: 'General remarks'),
      controller: ctrl,
      multiline: true,
      onChanged: (v) => _exam!.remarks = v,
    );
  }

  // ---------- gait ----------

  Widget _gaitBody() {
    final ds = DSProvider.of(context);
    return Column(
      children: [
        _PxText(
          label: tr(context, ar: 'الجهاز التقويمي/التعويضي', en: 'Orthotic/Prosthetic/AD'),
          controller: _ctrl('gait_orthotic', _exam!.gaitOrthotic),
          onChanged: (v) => _exam!.gaitOrthotic = v,
        ),
        SizedBox(height: ds.spacing.md),
        _PxSelect(
          label: tr(context, ar: 'الطرف المرجعي', en: 'Reference limb'),
          options: const [
            PxOption('r', 'يمين', 'Right'),
            PxOption('l', 'يسار', 'Left'),
          ],
          value: _exam!.gaitReferenceLimb,
          onChanged: (v) => _exam!.gaitReferenceLimb = v,
        ),
      ],
    );
  }

  // ---------- body marks ----------

  Widget _bodyMarksBody() {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    final marks = _exam!.bodyMarks;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DSText(
          t('اضغط على المخطط لإضافة علامة', 'Tap the chart to add a mark'),
          role: DSTextRole.caption,
          color: ds.colors.textSecondary,
        ),
        SizedBox(height: ds.spacing.sm),
        for (final view in bodyMarkViews)
          _BodyView(
            view: view,
            label: t(view.ar, view.en),
            marks: marks.where((m) => m['view'] == view.value).toList(),
            onTapAt: (x, y) => setState(() => marks.add({
                  'view': view.value,
                  'x': x,
                  'y': y,
                  'mark_type': 'pain',
                  'pain_vas': 0,
                  'note': '',
                })),
          ),
        SizedBox(height: ds.spacing.sm),
        for (var i = 0; i < marks.length; i++)
          _BodyMarkRow(
            mark: marks[i],
            onRemove: () => setState(() => marks.removeAt(i)),
            onChanged: () => setState(() {}),
          ),
      ],
    );
  }
}

// ==================== field widgets ====================

class _PxText extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final bool multiline;
  final bool number;
  final ValueChanged<String> onChanged;

  const _PxText({
    required this.label,
    required this.controller,
    required this.onChanged,
    this.multiline = false,
    this.number = false,
  });

  @override
  State<_PxText> createState() => _PxTextState();
}

class _PxTextState extends State<_PxText> {
  final FocusNode _focus = FocusNode();

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
        DSText(widget.label,
            role: DSTextRole.caption, color: ds.colors.textSecondary),
        SizedBox(height: ds.spacing.xs),
        Container(
          padding: EdgeInsetsDirectional.symmetric(
              horizontal: ds.spacing.md, vertical: ds.spacing.sm),
          decoration: BoxDecoration(
            color: ds.colors.surfaceAlt,
            borderRadius: BorderRadius.circular(ds.radii.medium),
            border: Border.all(color: ds.colors.border, width: 1.2),
          ),
          child: EditableText(
            controller: widget.controller,
            focusNode: _focus,
            style: ds.typography.body.copyWith(color: ds.colors.textPrimary),
            cursorColor: ds.colors.primary,
            backgroundCursorColor: ds.colors.textMuted,
            keyboardType: widget.number
                ? TextInputType.number
                : (widget.multiline
                    ? TextInputType.multiline
                    : TextInputType.text),
            maxLines: widget.multiline ? 4 : 1,
            minLines: widget.multiline ? 2 : 1,
            onChanged: widget.onChanged,
            textAlign: ds.textDirection == TextDirection.rtl
                ? TextAlign.right
                : TextAlign.left,
          ),
        ),
      ],
    );
  }
}

class _PxSelect extends StatelessWidget {
  final String label;
  final List<PxOption> options;
  final String? value;
  final ValueChanged<String> onChanged;

  const _PxSelect({
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final isAr = tr(context, ar: 'ar', en: 'en') == 'ar';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DSText(label, role: DSTextRole.caption, color: ds.colors.textSecondary),
        SizedBox(height: ds.spacing.xs),
        Wrap(
          spacing: ds.spacing.xs,
          runSpacing: ds.spacing.xs,
          children: [
            for (final o in options)
              GestureDetector(
                onTap: () => onChanged(o.value),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: EdgeInsetsDirectional.symmetric(
                      horizontal: ds.spacing.md, vertical: ds.spacing.xs),
                  decoration: BoxDecoration(
                    color: value == o.value
                        ? ds.colors.primary
                        : ds.colors.surfaceAlt,
                    borderRadius: BorderRadius.circular(ds.radii.pill),
                    border: Border.all(color: ds.colors.border),
                  ),
                  child: DSText(
                    isAr ? o.ar : o.en,
                    role: DSTextRole.caption,
                    color: value == o.value
                        ? const Color(0xFFFFFFFF)
                        : ds.colors.textPrimary,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _PxBool extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PxBool({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            width: ds.spacing.lg,
            height: ds.spacing.lg,
            decoration: BoxDecoration(
              color: value ? ds.colors.primary : ds.colors.surfaceAlt,
              borderRadius: BorderRadius.circular(ds.radii.small),
              border: Border.all(color: ds.colors.border),
            ),
            child: value
                ? const Center(
                    child: DSText('✓',
                        role: DSTextRole.caption, color: Color(0xFFFFFFFF)))
                : null,
          ),
          SizedBox(width: ds.spacing.sm),
          Expanded(child: DSText(label, role: DSTextRole.body)),
        ],
      ),
    );
  }
}

// ==================== body marks ====================

class _BodyView extends StatelessWidget {
  final PxOption view;
  final String label;
  final List<Map<String, dynamic>> marks;
  final void Function(double x, double y) onTapAt;

  const _BodyView({
    required this.view,
    required this.label,
    required this.marks,
    required this.onTapAt,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: ds.spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DSText(label, role: DSTextRole.label),
          SizedBox(height: ds.spacing.xs),
          LayoutBuilder(
            builder: (context, c) {
              const h = 180.0;
              final w = c.maxWidth;
              return GestureDetector(
                onTapUp: (d) => onTapAt(
                    (d.localPosition.dx / w).clamp(0, 1),
                    (d.localPosition.dy / h).clamp(0, 1)),
                child: Container(
                  width: w,
                  height: h,
                  decoration: BoxDecoration(
                    color: ds.colors.surfaceAlt,
                    borderRadius: BorderRadius.circular(ds.radii.medium),
                    border: Border.all(color: ds.colors.border),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _BodyPainter(ds.colors.textMuted),
                        ),
                      ),
                      for (final m in marks)
                        PositionedDirectional(
                          start: ((m['x'] as num?)?.toDouble() ?? 0) * w - 6,
                          top: ((m['y'] as num?)?.toDouble() ?? 0) * h - 6,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BodyMarkRow extends StatelessWidget {
  final Map<String, dynamic> mark;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _BodyMarkRow({
    required this.mark,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final isAr = tr(context, ar: 'ar', en: 'en') == 'ar';
    final viewLabel = bodyMarkViews.firstWhere(
        (v) => v.value == mark['view'],
        orElse: () => bodyMarkViews.first);
    return Container(
      margin: EdgeInsetsDirectional.only(bottom: ds.spacing.xs),
      padding: EdgeInsetsDirectional.all(ds.spacing.sm),
      decoration: BoxDecoration(
        color: ds.colors.surfaceAlt,
        borderRadius: BorderRadius.circular(ds.radii.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DSText(isAr ? viewLabel.ar : viewLabel.en,
                  role: DSTextRole.label),
              const Spacer(),
              GestureDetector(
                onTap: onRemove,
                behavior: HitTestBehavior.opaque,
                child: DSLineIcon(
                    type: LineIconType.trash,
                    color: const Color(0xFFEF4444),
                    size: ds.spacing.md),
              ),
            ],
          ),
          SizedBox(height: ds.spacing.xs),
          Wrap(
            spacing: ds.spacing.xs,
            runSpacing: ds.spacing.xs,
            children: [
              for (final ty in bodyMarkTypes)
                GestureDetector(
                  onTap: () {
                    mark['mark_type'] = ty.value;
                    onChanged();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: EdgeInsetsDirectional.symmetric(
                        horizontal: ds.spacing.sm, vertical: 2),
                    decoration: BoxDecoration(
                      color: mark['mark_type'] == ty.value
                          ? ds.colors.primary
                          : ds.colors.surface,
                      borderRadius: BorderRadius.circular(ds.radii.pill),
                      border: Border.all(color: ds.colors.border),
                    ),
                    child: DSText(isAr ? ty.ar : ty.en,
                        role: DSTextRole.caption,
                        color: mark['mark_type'] == ty.value
                            ? const Color(0xFFFFFFFF)
                            : ds.colors.textPrimary),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Draws a simple human-body silhouette for the body-marks chart, replacing the
/// old emoji placeholder.
class _BodyPainter extends CustomPainter {
  final Color color;

  const _BodyPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..color = color.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;

    void figure(Path p) {
      canvas.drawPath(p, fill);
      canvas.drawPath(p, stroke);
    }

    // Head + neck
    figure(Path()
      ..addOval(Rect.fromCircle(center: Offset(cx, h * 0.10), radius: h * 0.07)));

    // Torso (shoulders → hips)
    figure(Path()
      ..moveTo(cx - w * 0.15, h * 0.20)
      ..lineTo(cx + w * 0.15, h * 0.20)
      ..lineTo(cx + w * 0.11, h * 0.52)
      ..lineTo(cx - w * 0.11, h * 0.52)
      ..close());

    // Arms
    final armW = w * 0.055;
    figure(Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - w * 0.15 - armW, h * 0.21, armW, h * 0.30),
          Radius.circular(armW))));
    figure(Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(cx + w * 0.15, h * 0.21, armW, h * 0.30),
          Radius.circular(armW))));

    // Legs
    final legW = w * 0.08;
    figure(Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - w * 0.11, h * 0.52, legW, h * 0.42),
          Radius.circular(legW * 0.5))));
    figure(Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(cx + w * 0.11 - legW, h * 0.52, legW, h * 0.42),
          Radius.circular(legW * 0.5))));
  }

  @override
  bool shouldRepaint(covariant _BodyPainter oldDelegate) =>
      oldDelegate.color != color;
}
