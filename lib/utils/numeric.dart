/// Numeric input helpers.
///
/// Arabic (and Persian) keyboards produce Arabic-Indic digits (٠-٩ / ۰-۹) and
/// their own decimal/thousands separators. `double.tryParse` only understands
/// ASCII, so an amount typed as ٣٠٠ would fail to parse and silently disable
/// submit buttons. [normalizeNumeric] converts such input to a plain ASCII
/// number string.
String normalizeNumeric(String input) {
  final buffer = StringBuffer();
  for (final rune in input.trim().runes) {
    // Arabic-Indic 0..9 → U+0660..U+0669
    if (rune >= 0x0660 && rune <= 0x0669) {
      buffer.writeCharCode(0x30 + (rune - 0x0660));
    // Extended (Persian) 0..9 → U+06F0..U+06F9
    } else if (rune >= 0x06F0 && rune <= 0x06F9) {
      buffer.writeCharCode(0x30 + (rune - 0x06F0));
    // Arabic decimal separator (٫) → '.'
    } else if (rune == 0x066B) {
      buffer.write('.');
    // Arabic thousands separator (٬), ASCII comma, and spaces → dropped
    } else if (rune == 0x066C || rune == 0x002C || rune == 0x0020) {
      // skip grouping separators
    } else {
      buffer.writeCharCode(rune);
    }
  }
  return buffer.toString();
}
