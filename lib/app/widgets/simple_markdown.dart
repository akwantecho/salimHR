import 'package:flutter/widgets.dart';

import '../../design_system/ds_provider.dart';

/// A lightweight Markdown renderer for chat replies. Supports the subset the
/// assistant actually emits: headings (`#`), bold (`**`/`__`), italic
/// (`*`/`_`), inline code (`` ` ``), bullet lists (`-`/`*`/`•`), numbered
/// lists (`1.`), and paragraphs. No external package — pure flutter/widgets so
/// it fits the custom design system.
class SimpleMarkdown extends StatelessWidget {
  final String text;

  /// Base text color (bubbles pass their foreground color).
  final Color color;

  /// Muted color for bullets/numbers.
  final Color accent;

  const SimpleMarkdown({
    super.key,
    required this.text,
    required this.color,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final rtl = ds.textDirection == TextDirection.rtl;
    final base = ds.typography.body.copyWith(color: color, height: 1.45);
    final align = rtl ? TextAlign.right : TextAlign.left;

    final blocks = <Widget>[];
    final lines = text.replaceAll('\r\n', '\n').split('\n');
    bool inCode = false;
    final codeBuf = <String>[];

    void flushCode() {
      if (codeBuf.isEmpty) return;
      blocks.add(_codeBlock(ds, codeBuf.join('\n'), color));
      codeBuf.clear();
    }

    for (final raw in lines) {
      final line = raw.trimRight();
      final trimmed = line.trim();

      // Fenced code blocks ```
      if (trimmed.startsWith('```')) {
        if (inCode) {
          flushCode();
          inCode = false;
        } else {
          inCode = true;
        }
        continue;
      }
      if (inCode) {
        codeBuf.add(raw);
        continue;
      }

      // Blank line → small gap.
      if (trimmed.isEmpty) {
        blocks.add(SizedBox(height: ds.spacing.xs));
        continue;
      }

      // Headings: #, ##, ###
      final heading = RegExp(r'^(#{1,3})\s+(.*)$').firstMatch(trimmed);
      if (heading != null) {
        final level = heading.group(1)!.length;
        final content = heading.group(2)!;
        final size = level == 1 ? 1.25 : (level == 2 ? 1.12 : 1.02);
        blocks.add(Padding(
          padding: EdgeInsetsDirectional.only(
              top: ds.spacing.xs, bottom: ds.spacing.xs / 2),
          child: RichText(
            textDirection: ds.textDirection,
            textAlign: align,
            text: TextSpan(
              children: _inline(
                content,
                base.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: (base.fontSize ?? 15) * size,
                ),
              ),
            ),
          ),
        ));
        continue;
      }

      // Bullet list: -, *, •
      final bullet = RegExp(r'^[-*•]\s+(.*)$').firstMatch(trimmed);
      if (bullet != null) {
        blocks.add(_listItem(ds, base, align, accent, '•', bullet.group(1)!));
        continue;
      }

      // Numbered list: 1. 2) ...
      final numbered = RegExp(r'^(\d+)[.)]\s+(.*)$').firstMatch(trimmed);
      if (numbered != null) {
        blocks.add(_listItem(
            ds, base, align, accent, '${numbered.group(1)}.', numbered.group(2)!));
        continue;
      }

      // Plain paragraph line.
      blocks.add(RichText(
        textDirection: ds.textDirection,
        textAlign: align,
        text: TextSpan(children: _inline(line, base)),
      ));
    }
    flushCode();

    return Column(
      crossAxisAlignment:
          rtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: blocks,
    );
  }

  Widget _listItem(DSTheme ds, TextStyle base, TextAlign align, Color accent,
      String marker, String content) {
    final rtl = ds.textDirection == TextDirection.rtl;
    final markerWidget = Padding(
      padding: EdgeInsetsDirectional.only(
          end: rtl ? 0 : ds.spacing.xs, start: rtl ? ds.spacing.xs : 0),
      child: Text(marker,
          style: base.copyWith(color: accent, fontWeight: FontWeight.w700),
          textDirection: ds.textDirection),
    );
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: ds.spacing.xs / 2),
      child: Row(
        textDirection: ds.textDirection,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          markerWidget,
          Expanded(
            child: RichText(
              textDirection: ds.textDirection,
              textAlign: align,
              text: TextSpan(children: _inline(content, base)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _codeBlock(DSTheme ds, String code, Color color) {
    return Container(
      width: double.infinity,
      margin: EdgeInsetsDirectional.symmetric(vertical: ds.spacing.xs),
      padding: EdgeInsetsDirectional.all(ds.spacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(ds.radii.medium),
      ),
      child: Text(
        code,
        style: ds.typography.body.copyWith(
          color: color,
          fontFamily: 'monospace',
          fontSize: (ds.typography.body.fontSize ?? 15) * 0.92,
        ),
      ),
    );
  }

  /// Parse inline emphasis/code into styled spans.
  List<InlineSpan> _inline(String text, TextStyle base) {
    final spans = <InlineSpan>[];
    final codeRe = RegExp(r'`([^`]+)`');
    int i = 0;
    for (final m in codeRe.allMatches(text)) {
      if (m.start > i) spans.addAll(_emphasis(text.substring(i, m.start), base));
      spans.add(TextSpan(
        text: m.group(1),
        style: base.copyWith(
          fontFamily: 'monospace',
          background: (Paint()..color = base.color!.withValues(alpha: 0.10)),
        ),
      ));
      i = m.end;
    }
    if (i < text.length) spans.addAll(_emphasis(text.substring(i), base));
    return spans.isEmpty ? [TextSpan(text: text, style: base)] : spans;
  }

  List<InlineSpan> _emphasis(String text, TextStyle base) {
    final spans = <InlineSpan>[];
    final re = RegExp(r'\*\*(.+?)\*\*|__(.+?)__|\*(.+?)\*|_(.+?)_');
    int i = 0;
    for (final m in re.allMatches(text)) {
      if (m.start > i) {
        spans.add(TextSpan(text: text.substring(i, m.start), style: base));
      }
      final bold = m.group(1) ?? m.group(2);
      final italic = m.group(3) ?? m.group(4);
      if (bold != null) {
        spans.add(
            TextSpan(text: bold, style: base.copyWith(fontWeight: FontWeight.w700)));
      } else {
        spans.add(TextSpan(
            text: italic, style: base.copyWith(fontStyle: FontStyle.italic)));
      }
      i = m.end;
    }
    if (i < text.length) spans.add(TextSpan(text: text.substring(i), style: base));
    return spans;
  }
}
