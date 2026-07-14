import 'package:equatable/equatable.dart';

/// Clinic-at-a-glance overview (GET /api/clinic/overview).
class ClinicOverview extends Equatable {
  final bool financeVisible;
  final TodayStats today;
  final MonthStats month;
  final List<RevenueRow> bySpecialist;
  final List<RevenueRow> byService;
  final ClinicAlerts alerts;

  const ClinicOverview({
    required this.financeVisible,
    required this.today,
    required this.month,
    this.bySpecialist = const [],
    this.byService = const [],
    required this.alerts,
  });

  factory ClinicOverview.fromJson(Map<String, dynamic> json) {
    final breakdown = json['breakdown'] as Map<String, dynamic>?;
    return ClinicOverview(
      financeVisible: json['finance_visible'] as bool? ?? false,
      today: TodayStats.fromJson(json['today'] as Map<String, dynamic>? ?? {}),
      month: MonthStats.fromJson(json['month'] as Map<String, dynamic>? ?? {}),
      bySpecialist: (breakdown?['by_specialist'] as List<dynamic>? ?? [])
          .map((e) => RevenueRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      byService: (breakdown?['by_service'] as List<dynamic>? ?? [])
          .map((e) => RevenueRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      alerts:
          ClinicAlerts.fromJson(json['alerts'] as Map<String, dynamic>? ?? {}),
    );
  }

  @override
  List<Object?> get props => [financeVisible, today, month];
}

class TodayStats extends Equatable {
  final int total;
  final int completed;
  final int noShow;
  final int cancelled;
  final int booked;
  final int patientsSeen;
  final int staffPresent;
  final num? revenue;

  const TodayStats({
    this.total = 0,
    this.completed = 0,
    this.noShow = 0,
    this.cancelled = 0,
    this.booked = 0,
    this.patientsSeen = 0,
    this.staffPresent = 0,
    this.revenue,
  });

  factory TodayStats.fromJson(Map<String, dynamic> json) {
    final appts = json['appointments'] as Map<String, dynamic>? ?? {};
    return TodayStats(
      total: appts['total'] as int? ?? 0,
      completed: appts['completed'] as int? ?? 0,
      noShow: appts['no_show'] as int? ?? 0,
      cancelled: appts['cancelled'] as int? ?? 0,
      booked: appts['booked'] as int? ?? 0,
      patientsSeen: json['patients_seen'] as int? ?? 0,
      staffPresent: json['staff_present'] as int? ?? 0,
      revenue: json['revenue'] as num?,
    );
  }

  @override
  List<Object?> get props => [total, completed, patientsSeen, revenue];
}

class MonthStats extends Equatable {
  final int newPatients;
  final int sessionsTotal;
  final int sessionsExamination;
  final int sessionsPhysio;
  final int sessionsHome;
  final num? noShowRate;
  final num? revenue;
  final num? billed;
  final num? outstanding;
  final num? deltaNewPatients;
  final num? deltaSessions;
  final num? deltaRevenue;

  const MonthStats({
    this.newPatients = 0,
    this.sessionsTotal = 0,
    this.sessionsExamination = 0,
    this.sessionsPhysio = 0,
    this.sessionsHome = 0,
    this.noShowRate,
    this.revenue,
    this.billed,
    this.outstanding,
    this.deltaNewPatients,
    this.deltaSessions,
    this.deltaRevenue,
  });

  factory MonthStats.fromJson(Map<String, dynamic> json) {
    final s = json['sessions'] as Map<String, dynamic>? ?? {};
    final d = json['deltas'] as Map<String, dynamic>? ?? {};
    return MonthStats(
      newPatients: json['new_patients'] as int? ?? 0,
      sessionsTotal: s['total'] as int? ?? 0,
      sessionsExamination: s['examination'] as int? ?? 0,
      sessionsPhysio: s['physio'] as int? ?? 0,
      sessionsHome: s['home'] as int? ?? 0,
      noShowRate: json['no_show_rate'] as num?,
      revenue: json['revenue'] as num?,
      billed: json['billed'] as num?,
      outstanding: json['outstanding'] as num?,
      deltaNewPatients: d['new_patients'] as num?,
      deltaSessions: d['sessions'] as num?,
      deltaRevenue: d['revenue'] as num?,
    );
  }

  @override
  List<Object?> get props => [newPatients, sessionsTotal, revenue];
}

class RevenueRow extends Equatable {
  final String name;
  final num revenue;
  final int count;

  const RevenueRow({required this.name, this.revenue = 0, this.count = 0});

  factory RevenueRow.fromJson(Map<String, dynamic> json) => RevenueRow(
        name: json['name'] as String? ?? '—',
        revenue: json['revenue'] as num? ?? 0,
        count: json['count'] as int? ?? 0,
      );

  @override
  List<Object?> get props => [name, revenue, count];
}

class ClinicAlerts extends Equatable {
  final int lowStock;
  final num? noShowRate;
  final num? outstanding;

  const ClinicAlerts({this.lowStock = 0, this.noShowRate, this.outstanding});

  factory ClinicAlerts.fromJson(Map<String, dynamic> json) => ClinicAlerts(
        lowStock: json['low_stock'] as int? ?? 0,
        noShowRate: json['no_show_rate'] as num?,
        outstanding: json['outstanding'] as num?,
      );

  @override
  List<Object?> get props => [lowStock, noShowRate, outstanding];
}

/// Revenue report for a date range (GET /api/clinic/revenue). Finance-gated.
class RevenueReport extends Equatable {
  final String from;
  final String to;
  final num billed;
  final num collected;
  final num outstanding;
  final int invoiceCount;
  final num avgInvoice;
  final List<RevenueRow> bySpecialist;
  final List<RevenueRow> byService;

  const RevenueReport({
    required this.from,
    required this.to,
    this.billed = 0,
    this.collected = 0,
    this.outstanding = 0,
    this.invoiceCount = 0,
    this.avgInvoice = 0,
    this.bySpecialist = const [],
    this.byService = const [],
  });

  factory RevenueReport.fromJson(Map<String, dynamic> json) {
    final fin = json['financials'] as Map<String, dynamic>? ?? {};
    return RevenueReport(
      from: json['from'] as String? ?? '',
      to: json['to'] as String? ?? '',
      billed: fin['billed'] as num? ?? 0,
      collected: fin['collected'] as num? ?? 0,
      outstanding: fin['outstanding'] as num? ?? 0,
      invoiceCount: fin['invoice_count'] as int? ?? 0,
      avgInvoice: fin['avg_invoice'] as num? ?? 0,
      bySpecialist: (json['by_specialist'] as List<dynamic>? ?? [])
          .map((e) => RevenueRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      byService: (json['by_service'] as List<dynamic>? ?? [])
          .map((e) => RevenueRow.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [from, to, collected, invoiceCount];
}

/// Row of the clinic appointments drill-down.
class ClinicAppointment extends Equatable {
  final int id;
  final String? startTime;
  final String status;
  final String? patient;
  final String? specialist;
  final String? service;

  const ClinicAppointment({
    required this.id,
    this.startTime,
    required this.status,
    this.patient,
    this.specialist,
    this.service,
  });

  factory ClinicAppointment.fromJson(Map<String, dynamic> json) =>
      ClinicAppointment(
        id: json['id'] as int,
        startTime: json['start_time'] as String?,
        status: json['status'] as String? ?? 'booked',
        patient: json['patient'] as String?,
        specialist: json['specialist'] as String?,
        service: json['service'] as String?,
      );

  @override
  List<Object?> get props => [id, status];
}

/// Row of the clinic patients drill-down.
class ClinicPatient extends Equatable {
  final int id;
  final String name;
  final String? phone;
  final String? fileNumber;
  final bool isActive;

  const ClinicPatient({
    required this.id,
    required this.name,
    this.phone,
    this.fileNumber,
    this.isActive = true,
  });

  factory ClinicPatient.fromJson(Map<String, dynamic> json) => ClinicPatient(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String?,
        fileNumber: json['file_number']?.toString(),
        isActive: json['is_active'] as bool? ?? true,
      );

  @override
  List<Object?> get props => [id, name];
}
