import 'package:flutter/widgets.dart';

import '../../design_system/components/line_icons.dart';
import '../../design_system/ds_provider.dart';
import '../../design_system/primitives/ds_text.dart';
import '../../models/reception.dart';
import '../../services/api_provider.dart';
import '../i18n.dart';

/// A single chat turn with «د. يوسف».
class _Msg {
  final String role; // 'user' | 'assistant'
  final String content;
  const _Msg(this.role, this.content);
}

/// Chat screen for the internal AI assistant «د. يوسف» — a physiotherapy aide
/// for specialists. Backed by HRService.askAssistant → POST /ai/assistant.
class AiAssistantScreen extends StatefulWidget {
  /// Optional patient to attach as context from the start (e.g. opened from a
  /// patient screen).
  final Patient? patient;

  const AiAssistantScreen({super.key, this.patient});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  final List<_Msg> _messages = [];
  Patient? _patient;
  bool _sending = false;

  static const _green = Color(0xFF059669);

  @override
  void initState() {
    super.initState();
    _patient = widget.patient;
  }

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String text, {String action = 'chat'}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _sending) return;
    setState(() {
      _messages.add(_Msg('user', trimmed));
      _sending = true;
      _input.clear();
    });
    _scrollToEnd();

    final reply = await context.hrService.askAssistant(
      messages: _messages.map((m) => {'role': m.role, 'content': m.content}).toList(),
      patientId: _patient?.id,
      action: action,
    );
    if (!mounted) return;
    setState(() {
      _messages.add(_Msg(
        'assistant',
        reply ??
            tr(context,
                ar: 'تعذّر الرد الآن، حاول مرة أخرى.',
                en: 'Could not reply now, please try again.'),
      ));
      _sending = false;
    });
    _scrollToEnd();
  }

  Future<void> _attachPatient() async {
    final picked = await Navigator.of(context).push<Patient>(
      PageRouteBuilder(
        opaque: false,
        barrierColor: const Color(0x66000000),
        pageBuilder: (context, _, _) => const _PatientSearchSheet(),
      ),
    );
    if (picked != null && mounted) setState(() => _patient = picked);
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      color: ds.colors.background,
      child: SafeArea(
        child: Column(
          children: [
            _header(ds, t),
            _disclaimer(ds, t),
            if (_patient != null) _patientBar(ds, t),
            Expanded(
              child: _messages.isEmpty
                  ? _empty(ds, t)
                  : ListView.builder(
                      controller: _scroll,
                      padding: EdgeInsetsDirectional.all(ds.spacing.md),
                      itemCount: _messages.length + (_sending ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i >= _messages.length) return _typing(ds, t);
                        return _bubble(ds, _messages[i]);
                      },
                    ),
            ),
            _quickActions(ds, t),
            _inputBar(ds, t, viewInsets),
          ],
        ),
      ),
    );
  }

  Widget _header(DSTheme ds, String Function(String, String) t) {
    return Padding(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.opaque,
            child: DSLineIcon(
                type: LineIconType.arrowBack,
                color: ds.colors.primary,
                size: ds.spacing.lg),
          ),
          SizedBox(width: ds.spacing.sm),
          Container(
            width: ds.spacing.xl,
            height: ds.spacing.xl,
            decoration: const BoxDecoration(
              color: _green,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: DSLineIcon(
                  type: LineIconType.heart,
                  color: const Color(0xFFFFFFFF),
                  size: ds.spacing.md),
            ),
          ),
          SizedBox(width: ds.spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DSText(t('د. يوسف', 'Dr. Yousef'), role: DSTextRole.title),
                DSText(
                  t('مساعدك في العلاج الطبيعي', 'Your physiotherapy assistant'),
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

  Widget _disclaimer(DSTheme ds, String Function(String, String) t) {
    return Container(
      width: double.infinity,
      padding: EdgeInsetsDirectional.symmetric(
          horizontal: ds.spacing.md, vertical: ds.spacing.xs),
      color: ds.colors.surfaceAlt,
      child: DSText(
        t(
          'أداة مساعدة — القرار النهائي للأخصائي.',
          'An aid — the specialist makes the final decision.',
        ),
        role: DSTextRole.caption,
        color: ds.colors.textMuted,
      ),
    );
  }

  Widget _patientBar(DSTheme ds, String Function(String, String) t) {
    return Container(
      margin: EdgeInsetsDirectional.symmetric(horizontal: ds.spacing.md),
      padding: EdgeInsetsDirectional.symmetric(
          horizontal: ds.spacing.md, vertical: ds.spacing.sm),
      decoration: BoxDecoration(
        color: _green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ds.radii.medium),
        border: Border.all(color: _green.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          DSLineIcon(type: LineIconType.heart, color: _green, size: ds.spacing.md),
          SizedBox(width: ds.spacing.sm),
          Expanded(
            child: DSText('${t('المريض', 'Patient')}: ${_patient!.name}',
                role: DSTextRole.caption, color: _green, maxLines: 1),
          ),
          GestureDetector(
            onTap: () => setState(() => _patient = null),
            behavior: HitTestBehavior.opaque,
            child: DSText('✕', role: DSTextRole.caption, color: _green),
          ),
        ],
      ),
    );
  }

  Widget _empty(DSTheme ds, String Function(String, String) t) {
    return Center(
      child: Padding(
        padding: EdgeInsetsDirectional.all(ds.spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: ds.spacing.xl * 2,
              height: ds.spacing.xl * 2,
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: DSLineIcon(
                    type: LineIconType.chat, color: _green, size: ds.spacing.xl),
              ),
            ),
            SizedBox(height: ds.spacing.md),
            DSText(t('اسأل د. يوسف', 'Ask Dr. Yousef'),
                role: DSTextRole.title),
            SizedBox(height: ds.spacing.xs),
            DSText(
              t(
                'مرجع علاج طبيعي، صياغة تقارير، وتلخيص حالة المريض.',
                'PT reference, report drafting, and patient case summaries.',
              ),
              role: DSTextRole.caption,
              color: ds.colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(DSTheme ds, _Msg m) {
    final isUser = m.role == 'user';
    final bg = isUser ? ds.colors.primary : _green;
    return Container(
      margin: EdgeInsetsDirectional.only(bottom: ds.spacing.sm),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: EdgeInsetsDirectional.all(ds.spacing.md),
              decoration: BoxDecoration(
                color: isUser ? bg : bg,
                borderRadius: BorderRadius.circular(ds.radii.large),
              ),
              child: DSText(
                m.content,
                role: DSTextRole.body,
                color: const Color(0xFFFFFFFF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typing(DSTheme ds, String Function(String, String) t) {
    return Container(
      margin: EdgeInsetsDirectional.only(bottom: ds.spacing.sm),
      child: Row(
        children: [
          Container(
            padding: EdgeInsetsDirectional.all(ds.spacing.md),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(ds.radii.large),
            ),
            child: DSText(t('د. يوسف يكتب…', 'Dr. Yousef is typing…'),
                role: DSTextRole.caption, color: _green),
          ),
        ],
      ),
    );
  }

  Widget _quickActions(DSTheme ds, String Function(String, String) t) {
    return SizedBox(
      height: ds.spacing.xl + ds.spacing.sm,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsetsDirectional.symmetric(horizontal: ds.spacing.md),
        children: [
          _chip(ds, t('إرفاق مريض', 'Attach patient'), _attachPatient),
          if (_patient != null)
            _chip(
                ds,
                t('لخّص هذا المريض', 'Summarize patient'),
                () => _send(
                    t('لخّص حالة وتقدّم هذا المريض.',
                        'Summarize this patient\'s case and progress.'),
                    action: 'summarize_patient')),
          _chip(
              ds,
              t('اكتب تقرير جلسة', 'Draft session note'),
              () {
                _focus.requestFocus();
                _input.text = t('اكتب تقرير جلسة عن: ', 'Draft a session note about: ');
                _input.selection = TextSelection.collapsed(offset: _input.text.length);
                setState(() {});
              }),
        ],
      ),
    );
  }

  Widget _chip(DSTheme ds, String label, VoidCallback onTap) {
    return Padding(
      padding: EdgeInsetsDirectional.only(end: ds.spacing.sm),
      child: GestureDetector(
        onTap: _sending ? null : onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsetsDirectional.symmetric(horizontal: ds.spacing.md),
          decoration: BoxDecoration(
            color: ds.colors.surface,
            borderRadius: BorderRadius.circular(ds.radii.pill),
            border: Border.all(color: ds.colors.border),
          ),
          child: DSText(label, role: DSTextRole.caption, color: ds.colors.primary),
        ),
      ),
    );
  }

  Widget _inputBar(
      DSTheme ds, String Function(String, String) t, double viewInsets) {
    return Container(
      padding: EdgeInsetsDirectional.only(
        start: ds.spacing.md,
        end: ds.spacing.md,
        top: ds.spacing.sm,
        bottom: ds.spacing.sm + viewInsets,
      ),
      decoration: BoxDecoration(
        color: ds.colors.surface,
        border: BorderDirectional(
            top: BorderSide(color: ds.colors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              padding: EdgeInsetsDirectional.symmetric(
                  horizontal: ds.spacing.md, vertical: ds.spacing.sm),
              decoration: BoxDecoration(
                color: ds.colors.surfaceAlt,
                borderRadius: BorderRadius.circular(ds.radii.large),
                border: Border.all(color: ds.colors.border),
              ),
              child: EditableText(
                controller: _input,
                focusNode: _focus,
                style: ds.typography.body.copyWith(color: ds.colors.textPrimary),
                cursorColor: ds.colors.primary,
                backgroundCursorColor: ds.colors.textMuted,
                maxLines: null,
                minLines: 1,
                textAlign: ds.textDirection == TextDirection.rtl
                    ? TextAlign.right
                    : TextAlign.left,
              ),
            ),
          ),
          SizedBox(width: ds.spacing.sm),
          GestureDetector(
            onTap: _sending ? null : () => _send(_input.text),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: ds.spacing.xl + ds.spacing.xs,
              height: ds.spacing.xl + ds.spacing.xs,
              decoration: BoxDecoration(
                color: _sending ? ds.colors.textMuted : _green,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: DSLineIcon(
                    type: LineIconType.arrowBack,
                    color: const Color(0xFFFFFFFF),
                    size: ds.spacing.md),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modal for searching and picking a patient to attach to the conversation.
/// Pops the chosen [Patient]. Backed by ReceptionService.searchPatients.
class _PatientSearchSheet extends StatefulWidget {
  const _PatientSearchSheet();

  @override
  State<_PatientSearchSheet> createState() => _PatientSearchSheetState();
}

class _PatientSearchSheetState extends State<_PatientSearchSheet> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  List<Patient> _results = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _onChanged() async {
    final q = _ctrl.text.trim();
    if (q.length < 2) {
      if (_results.isNotEmpty) setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    final r = await context.receptionService.searchPatients(q);
    if (!mounted || _ctrl.text.trim() != q) return;
    setState(() {
      _results = r;
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 480),
        margin: EdgeInsetsDirectional.only(bottom: viewInsets),
        padding: EdgeInsetsDirectional.all(ds.spacing.lg),
        decoration: BoxDecoration(
          color: ds.colors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(ds.radii.xLarge)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DSText(t('اختر مريضاً', 'Choose a patient'), role: DSTextRole.title),
            SizedBox(height: ds.spacing.sm),
            Container(
              padding: EdgeInsetsDirectional.symmetric(
                  horizontal: ds.spacing.md, vertical: ds.spacing.sm),
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
                      size: ds.spacing.md),
                  SizedBox(width: ds.spacing.sm),
                  Expanded(
                    child: EditableText(
                      controller: _ctrl,
                      focusNode: _focus,
                      style: ds.typography.body
                          .copyWith(color: ds.colors.textPrimary),
                      cursorColor: ds.colors.primary,
                      backgroundCursorColor: ds.colors.textMuted,
                      textAlign: ds.textDirection == TextDirection.rtl
                          ? TextAlign.right
                          : TextAlign.left,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: ds.spacing.sm),
            Flexible(
              child: _searching
                  ? Padding(
                      padding: EdgeInsetsDirectional.all(ds.spacing.md),
                      child: DSText(t('جاري البحث…', 'Searching…'),
                          role: DSTextRole.caption,
                          color: ds.colors.textSecondary),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: _results.length,
                      separatorBuilder: (_, _) => SizedBox(height: ds.spacing.xs),
                      itemBuilder: (context, i) {
                        final p = _results[i];
                        return GestureDetector(
                          onTap: () => Navigator.of(context).pop(p),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: EdgeInsetsDirectional.all(ds.spacing.md),
                            decoration: BoxDecoration(
                              color: ds.colors.surfaceAlt,
                              borderRadius:
                                  BorderRadius.circular(ds.radii.medium),
                            ),
                            child: DSText(p.name, role: DSTextRole.body),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
