import 'package:equatable/equatable.dart';

/// One weekday of the specialist's weekly working template
/// (GET /api/me/schedule/weekly).
class ScheduleDay extends Equatable {
  final int dayOfWeek; // 0 = Sunday … 6 = Saturday (Carbon dayOfWeek)
  final bool isWorking;
  final String? start;
  final String? end;
  final int? slotDurationMinutes;
  final List<ScheduleBreak> breaks;

  const ScheduleDay({
    required this.dayOfWeek,
    this.isWorking = false,
    this.start,
    this.end,
    this.slotDurationMinutes,
    this.breaks = const [],
  });

  factory ScheduleDay.fromJson(Map<String, dynamic> json) => ScheduleDay(
        dayOfWeek: json['day_of_week'] as int? ?? 0,
        isWorking: json['is_working'] as bool? ?? false,
        start: json['start_time'] as String?,
        end: json['end_time'] as String?,
        slotDurationMinutes: json['slot_duration_minutes'] as int?,
        breaks: (json['breaks'] as List<dynamic>? ?? [])
            .map((e) => ScheduleBreak.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [dayOfWeek, isWorking, start, end];
}

class ScheduleBreak extends Equatable {
  final String? title;
  final String? start;
  final String? end;

  const ScheduleBreak({this.title, this.start, this.end});

  factory ScheduleBreak.fromJson(Map<String, dynamic> json) => ScheduleBreak(
        title: json['title'] as String?,
        start: json['start'] as String?,
        end: json['end'] as String?,
      );

  @override
  List<Object?> get props => [title, start, end];
}

/// A single bookable/again slot for a day (GET /api/me/slots).
class DaySlot extends Equatable {
  final String? start;
  final String? end;
  final bool available;

  const DaySlot({this.start, this.end, this.available = false});

  factory DaySlot.fromJson(Map<String, dynamic> json) => DaySlot(
        start: json['start'] as String?,
        end: json['end'] as String?,
        available: json['available'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [start, end, available];
}

/// Result of a slots query — the list plus an optional reason when empty
/// ('no_hours' | 'day_off' | 'full').
class DaySlots extends Equatable {
  final List<DaySlot> slots;
  final String? reason;

  const DaySlots({this.slots = const [], this.reason});

  @override
  List<Object?> get props => [slots, reason];
}
