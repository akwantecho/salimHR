import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../design_system/components/line_icons.dart';
import '../../design_system/ds_provider.dart';
import '../../design_system/primitives/ds_text.dart';
import '../../models/reception.dart';
import '../../services/api_provider.dart';
import '../i18n.dart';
import '../widgets/simple_markdown.dart';

/// A single chat turn with «د. أليكس».
class _Msg {
  final String role; // 'user' | 'assistant'
  String content; // mutable so streamed deltas can append live
  _Msg(this.role, this.content);
}

/// Chat screen for the internal AI assistant «د. أليكس» — a physiotherapy aide
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
  String? _conversationId;

  // Index of the assistant message currently being streamed (deltas append to
  // it live). Null when no stream is in flight.
  int? _streamingIndex;

  // Transient "copied" feedback per message index.
  int? _copiedIndex;
  Timer? _copiedTimer;

  static const _green = Color(0xFF059669);

  @override
  void initState() {
    super.initState();
    _patient = widget.patient;
  }

  @override
  void dispose() {
    _copiedTimer?.cancel();
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

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _sending) return;
    setState(() {
      _messages.add(_Msg('user', trimmed));
      _input.clear();
    });
    _scrollToEnd();
    await _requestAssistant(trimmed);
  }

  /// Ask the assistant for [coreText] and stream its reply live into a fresh
  /// assistant bubble. Does not add a user bubble — the caller owns that.
  Future<void> _requestAssistant(String coreText) async {
    // The backend keeps history; we only send this turn's message. When a
    // patient is attached, name them so the assistant can look them up.
    final outgoing = _patient != null
        ? '${tr(context, ar: 'بخصوص المريض', en: 'Regarding patient')} '
            '"${_patient!.name}": $coreText'
        : coreText;

    final errorText = tr(context,
        ar: 'تعذّر الرد الآن، حاول مرة أخرى.',
        en: 'Could not reply now, please try again.');

    // Placeholder bubble that deltas append to.
    final idx = _messages.length;
    setState(() {
      _messages.add(_Msg('assistant', ''));
      _streamingIndex = idx;
      _sending = true;
    });
    _scrollToEnd();

    bool gotDelta = false;
    bool sawError = false;
    int sinceScroll = 0;
    try {
      await for (final ev in context.hrService.askAssistantStream(
        message: outgoing,
        conversationId: _conversationId,
      )) {
        if (!mounted) return;
        switch (ev.type) {
          case 'meta':
          case 'done':
            if (ev.conversationId != null) _conversationId = ev.conversationId;
            break;
          case 'delta':
            final chunk = ev.text ?? '';
            if (chunk.isEmpty) break;
            gotDelta = true;
            setState(() => _messages[idx].content += chunk);
            if ((sinceScroll += chunk.length) >= 40) {
              sinceScroll = 0;
              _scrollToEnd();
            }
            break;
          case 'error':
            sawError = true;
            setState(() => _messages[idx].content = ev.message ?? errorText);
            break;
        }
      }
    } catch (_) {
      // Network/parse failure → fall back to the plain JSON endpoint below.
    }
    if (!mounted) return;

    // If streaming yielded nothing usable (e.g. backend not streaming yet),
    // fall back to the non-stream JSON endpoint so replies never come back empty.
    if (!gotDelta && !sawError && _messages[idx].content.isEmpty) {
      final res = await context.hrService.askAssistant(
        message: outgoing,
        conversationId: _conversationId,
      );
      if (!mounted) return;
      _conversationId = res?['conversation_id'] ?? _conversationId;
      setState(() => _messages[idx].content = res?['answer'] ?? errorText);
    }

    setState(() {
      _streamingIndex = null;
      _sending = false;
    });
    _scrollToEnd();
  }

  void _copy(int index) {
    Clipboard.setData(ClipboardData(text: _messages[index].content));
    _copiedTimer?.cancel();
    setState(() => _copiedIndex = index);
    _copiedTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _copiedIndex = null);
    });
  }

  Future<void> _regenerate() async {
    if (_sending) return;
    final u = _messages.lastIndexWhere((m) => m.role == 'user');
    if (u < 0) return;
    final text = _messages[u].content;
    setState(() {
      if (u + 1 < _messages.length) {
        _messages.removeRange(u + 1, _messages.length);
      }
    });
    await _requestAssistant(text);
  }

  void _newChat() {
    setState(() {
      _messages.clear();
      _conversationId = null;
      _streamingIndex = null;
      _sending = false;
    });
  }

  Future<void> _openHistory() async {
    final picked = await Navigator.of(context).push<String>(
      PageRouteBuilder(
        opaque: false,
        barrierColor: const Color(0x66000000),
        pageBuilder: (context, _, _) => const _HistorySheet(),
      ),
    );
    if (picked == null || !mounted) return;
    await _loadConversation(picked);
  }

  Future<void> _loadConversation(String id) async {
    setState(() {
      _sending = true;
      _streamingIndex = null;
    });
    final msgs = await context.hrService.fetchConversationMessages(id);
    if (!mounted) return;
    setState(() {
      _messages
        ..clear()
        ..addAll(msgs.map((m) => _Msg(m['role'] ?? 'assistant', m['content'] ?? '')));
      _conversationId = id;
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
                      itemCount: _messages.length,
                      itemBuilder: (context, i) =>
                          _bubble(ds, _messages[i], i, t),
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
                DSText(t('د. أليكس', 'Dr. Alex'), role: DSTextRole.title),
                DSText(
                  t('مساعدك الذكي في العمل', 'Your smart work assistant'),
                  role: DSTextRole.caption,
                  color: ds.colors.textSecondary,
                ),
              ],
            ),
          ),
          _headerIcon(ds, LineIconType.history, _openHistory),
          SizedBox(width: ds.spacing.xs),
          _headerIcon(ds, LineIconType.plus,
              _messages.isEmpty ? null : _newChat),
        ],
      ),
    );
  }

  Widget _headerIcon(DSTheme ds, LineIconType type, VoidCallback? onTap) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: ds.spacing.xl,
        height: ds.spacing.xl,
        decoration: BoxDecoration(
          color: ds.colors.surfaceAlt,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: DSLineIcon(
            type: type,
            color: enabled ? ds.colors.primary : ds.colors.textMuted,
            size: ds.spacing.md,
          ),
        ),
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
            DSText(t('اسأل د. أليكس', 'Ask Dr. Alex'),
                role: DSTextRole.title),
            SizedBox(height: ds.spacing.xs),
            DSText(
              t(
                'اسأله عن رصيد مريض، جلساته، المواعيد، المخزون — أو مرجع مهني وصياغة تقارير.',
                'Ask about a patient balance, sessions, appointments, inventory — or professional reference & reports.',
              ),
              role: DSTextRole.caption,
              color: ds.colors.textSecondary,
            ),
            SizedBox(height: ds.spacing.lg),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: ds.spacing.sm,
              runSpacing: ds.spacing.sm,
              children: [
                for (final s in _starters(t))
                  _chip(ds, s, () => _send(s)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<String> _starters(String Function(String, String) t) => [
        t('كم موعد عندي اليوم؟', 'How many appointments today?'),
        t('اكتب تقرير جلسة علاج طبيعي', 'Draft a physiotherapy session note'),
        t('تمارين لتقوية أسفل الظهر', 'Exercises for lower-back strengthening'),
        t('اشرح تقنية Mulligan', 'Explain the Mulligan technique'),
      ];

  Widget _bubble(DSTheme ds, _Msg m, int index, String Function(String, String) t) {
    final isUser = m.role == 'user';
    // The assistant message currently receiving streamed deltas.
    final streaming = _streamingIndex == index;

    if (isUser) {
      return Container(
        margin: EdgeInsetsDirectional.only(bottom: ds.spacing.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding: EdgeInsetsDirectional.all(ds.spacing.md),
                decoration: BoxDecoration(
                  color: ds.colors.primary,
                  borderRadius: BorderRadius.circular(ds.radii.large),
                ),
                child: DSText(m.content,
                    role: DSTextRole.body, color: const Color(0xFFFFFFFF)),
              ),
            ),
          ],
        ),
      );
    }

    // Assistant: neutral card with Markdown + action row.
    return Container(
      margin: EdgeInsetsDirectional.only(bottom: ds.spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsetsDirectional.only(
                end: ds.spacing.sm, top: ds.spacing.xs / 2),
            width: ds.spacing.lg,
            height: ds.spacing.lg,
            decoration: const BoxDecoration(
                color: _green, shape: BoxShape.circle),
            child: Center(
              child: DSLineIcon(
                  type: LineIconType.heart,
                  color: const Color(0xFFFFFFFF),
                  size: ds.spacing.sm),
            ),
          ),
          Flexible(
            child: Container(
              padding: EdgeInsetsDirectional.all(ds.spacing.md),
              decoration: BoxDecoration(
                color: ds.colors.surface,
                borderRadius: BorderRadius.circular(ds.radii.large),
                border: Border.all(color: ds.colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (streaming && m.content.isEmpty)
                    DSText(t('د. أليكس يكتب…', 'Dr. Alex is typing…'),
                        role: DSTextRole.caption, color: _green)
                  else
                    SimpleMarkdown(
                      text: m.content,
                      color: ds.colors.textPrimary,
                      accent: _green,
                    ),
                  if (!streaming) ...[
                    SizedBox(height: ds.spacing.sm),
                    Row(
                      children: [
                        _msgAction(
                          ds,
                          _copiedIndex == index
                              ? LineIconType.check
                              : LineIconType.copy,
                          _copiedIndex == index
                              ? t('تم النسخ', 'Copied')
                              : t('نسخ', 'Copy'),
                          () => _copy(index),
                        ),
                        SizedBox(width: ds.spacing.md),
                        if (index == _messages.length - 1)
                          _msgAction(ds, LineIconType.refresh,
                              t('إعادة', 'Regenerate'), _regenerate),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _msgAction(
      DSTheme ds, LineIconType icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: _sending ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DSLineIcon(type: icon, color: ds.colors.textMuted, size: ds.spacing.md),
          SizedBox(width: ds.spacing.xs / 2),
          DSText(label, role: DSTextRole.caption, color: ds.colors.textMuted),
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
                () => _send(t('لخّص حالة وتقدّم هذا المريض.',
                    'Summarize this patient\'s case and progress.'))),
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

/// Bottom sheet listing the user's past conversations. Pops the chosen
/// conversation id. Backed by HRService.fetchMyConversations.
class _HistorySheet extends StatefulWidget {
  const _HistorySheet();

  @override
  State<_HistorySheet> createState() => _HistorySheetState();
}

class _HistorySheetState extends State<_HistorySheet> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final items = await context.hrService.fetchMyConversations();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  String _title(Map<String, dynamic> c) {
    final title = (c['title'] ?? c['preview'] ?? '').toString().trim();
    if (title.isNotEmpty) return title;
    return tr(context, ar: 'محادثة', en: 'Conversation');
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 480),
        width: double.infinity,
        padding: EdgeInsetsDirectional.all(ds.spacing.lg),
        decoration: BoxDecoration(
          color: ds.colors.surface,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(ds.radii.xLarge)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DSText(t('محادثاتي السابقة', 'My conversations'),
                role: DSTextRole.title),
            SizedBox(height: ds.spacing.md),
            Flexible(
              child: _loading
                  ? Padding(
                      padding: EdgeInsetsDirectional.all(ds.spacing.lg),
                      child: Center(
                        child: DSText(t('جارٍ التحميل…', 'Loading…'),
                            role: DSTextRole.caption,
                            color: ds.colors.textSecondary),
                      ),
                    )
                  : _items.isEmpty
                      ? Padding(
                          padding: EdgeInsetsDirectional.all(ds.spacing.lg),
                          child: Center(
                            child: DSText(
                                t('لا توجد محادثات سابقة',
                                    'No past conversations'),
                                role: DSTextRole.body,
                                color: ds.colors.textSecondary),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: _items.length,
                          separatorBuilder: (_, _) =>
                              SizedBox(height: ds.spacing.sm),
                          itemBuilder: (context, i) {
                            final c = _items[i];
                            return GestureDetector(
                              onTap: () => Navigator.of(context)
                                  .pop(c['id']?.toString()),
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                padding:
                                    EdgeInsetsDirectional.all(ds.spacing.md),
                                decoration: BoxDecoration(
                                  color: ds.colors.surfaceAlt,
                                  borderRadius:
                                      BorderRadius.circular(ds.radii.medium),
                                ),
                                child: Row(
                                  children: [
                                    DSLineIcon(
                                        type: LineIconType.chat,
                                        color: _AiAssistantScreenState._green,
                                        size: ds.spacing.md),
                                    SizedBox(width: ds.spacing.sm),
                                    Expanded(
                                      child: DSText(_title(c),
                                          role: DSTextRole.body, maxLines: 1),
                                    ),
                                  ],
                                ),
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
