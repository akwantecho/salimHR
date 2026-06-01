import 'package:flutter/widgets.dart';

import '../app/i18n.dart';

/// Render "HH:mm[:ss]" backend time as 12-hour with a locale-aware AM/PM
/// marker (صباحاً / مساءً in Arabic, AM/PM in English).
/// Returns '' for null/empty input.
String formatTime12h(BuildContext context, String? time) {
  if (time == null || time.isEmpty) return '';
  final parts = time.split(':');
  if (parts.length < 2) return time;
  final h24 = int.tryParse(parts[0]) ?? 0;
  final m = parts[1].padLeft(2, '0');
  final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
  final isPM = h24 >= 12;
  final marker = isPM
      ? tr(context, ar: 'مساءً', en: 'PM')
      : tr(context, ar: 'صباحاً', en: 'AM');
  return '${h12.toString().padLeft(2, '0')}:$m $marker';
}

/// Format DateTime as YYYY-MM-DD (calendar date, no timezone shifts).
String formatDateIso(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
