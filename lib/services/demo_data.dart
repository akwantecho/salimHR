import 'package:dio/dio.dart';

import 'api_config.dart';

/// Dio interceptor that serves mock data for the app's endpoints while
/// [ApiConfig.demoMode] is enabled — used to preview the UI without a backend.
///
/// This interceptor is ALWAYS registered but stays completely inert while
/// [ApiConfig.demoMode] is `false` (the default): it simply forwards every
/// request untouched, so a real server build behaves exactly as before.
/// Only the demo-login buttons flip the flag on.
class DemoInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!ApiConfig.demoMode) {
      handler.next(options);
      return;
    }

    final data = _DemoData.responseFor(
      method: options.method.toUpperCase(),
      path: options.path,
    );

    handler.resolve(
      Response<dynamic>(
        requestOptions: options,
        statusCode: 200,
        data: data,
      ),
    );
  }
}

/// Builds canned JSON payloads that match the shapes each service expects.
class _DemoData {
  /// In-memory acknowledgement time for "today", so the specialist's tap
  /// persists across requests within the demo session.
  static String? _todayAckAt;

  static String _d(DateTime dt) =>
      '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)}';

  static String _ts(DateTime dt) =>
      '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)}T${_pad(dt.hour)}:${_pad(dt.minute)}:00';

  static String _pad(int n) => n.toString().padLeft(2, '0');

  static Map<String, dynamic> responseFor({
    required String method,
    required String path,
  }) {
    final now = DateTime.now();

    // ---- Specialist: today's appointments ----
    if (path.startsWith('/appointments/my')) {
      return {
        'data': _appointments(now),
        'stats': {'total': 5, 'upcoming': 3, 'completed': 2},
      };
    }

    // ---- Acknowledge today's schedule (specialist) ----
    if (path == '/appointments/acknowledge-today') {
      if (method == 'POST') {
        _todayAckAt = _ts(now);
      }
      return {
        'data': {
          'acknowledged': _todayAckAt != null,
          'acknowledged_at': _todayAckAt,
        },
      };
    }

    // ---- Admin: specialists' schedule-acknowledgement status ----
    if (path == '/hr/schedule-acknowledgements') {
      return {'data': _acknowledgements(now)};
    }

    // ---- Treatment plan: session log for a patient ----
    if (path.startsWith('/appointments/') && path.endsWith('/sessions')) {
      return {'data': _treatmentSessions(now)};
    }

    // ---- Appointment detail / status change ----
    if (path.startsWith('/appointments/')) {
      if (method == 'GET') {
        return {'data': _appointments(now).first};
      }
      return {'success': true, 'data': _appointments(now).first};
    }

    // ---- Attendance: today ----
    if (path == '/employee/attendance/today') {
      return {
        'data': {
          'date': _d(now),
          'check_in_at': _ts(DateTime(now.year, now.month, now.day, 8, 5)),
          'check_out_at': null,
          'worked_minutes': null,
        },
      };
    }

    // ---- Attendance: check-in / check-out ----
    if (path == '/employee/attendance/check-in') {
      return {
        'data': {
          'date': _d(now),
          'check_in_at': _ts(now),
          'check_out_at': null,
        },
      };
    }
    if (path == '/employee/attendance/check-out') {
      return {
        'data': {
          'date': _d(now),
          'check_in_at': _ts(DateTime(now.year, now.month, now.day, 8, 5)),
          'check_out_at': _ts(now),
        },
      };
    }

    // ---- Attendance: monthly log ----
    if (path == '/employee/attendance') {
      return {
        'data': _attendanceDays(now),
        'summary': {
          'worked_days': 18,
          'total_sessions': 96,
          'total_minutes': 8640,
        },
      };
    }

    // ---- Leaves summary ----
    if (path == '/employee/leaves') {
      return {
        'summary': {
          'pending': 1,
          'approved': 4,
          'rejected': 0,
          'approved_this_month': 1,
        },
        'data': _leaves(now),
      };
    }

    // ---- Bonuses / deductions ----
    if (path == '/employee/bonuses') {
      return {
        'data': _bonuses(now),
        'summary': {'total_bonuses': 750.0, 'total_deductions': 120.0},
      };
    }

    // ---- Employee notes ----
    if (path == '/employee/notes') {
      if (method == 'GET') {
        return {'data': _notes(now)};
      }
      return {'success': true};
    }

    // ---- Promotional banners (home carousel) ----
    if (path == '/banners') {
      return {
        'data': [
          {
            'id': 1,
            'title': 'حملة الفحص الشامل',
            'subtitle': 'خصم 30% على باقات الفحص الطبي حتى نهاية الشهر.',
            'action_label': 'احجز الآن',
            'image_url': null,
            'color': '#6366F1',
            'sort_order': 1,
            'active': true,
          },
          {
            'id': 2,
            'title': 'جلسات العلاج الطبيعي',
            'subtitle': 'برنامج تأهيلي متكامل بإشراف نخبة من الأخصائيين.',
            'action_label': 'اعرف أكثر',
            'image_url': null,
            'color': '#10B981',
            'sort_order': 2,
            'active': true,
          },
          {
            'id': 3,
            'title': 'عيادة المتابعة عن بُعد',
            'subtitle': 'تابع حالتك الصحية من المنزل عبر الاستشارات الإلكترونية.',
            'action_label': 'ابدأ الاستشارة',
            'image_url': null,
            'color': '#F59E0B',
            'sort_order': 3,
            'active': true,
          },
        ],
      };
    }

    // ---- Leave types ----
    if (path == '/employee/leave-types' || path == '/hr/leave-types') {
      return {
        'data': [
          {'id': 1, 'name': 'إجازة سنوية', 'name_en': 'Annual', 'balance': 21},
          {'id': 2, 'name': 'إجازة مرضية', 'name_en': 'Sick', 'balance': 30},
          {'id': 3, 'name': 'إجازة طارئة', 'name_en': 'Emergency', 'balance': 5},
        ],
      };
    }

    // ---- Manager: HR dashboard ----
    if (path == '/hr/dashboard') {
      return {
        'data': {
          'employees_count': 24,
          'present_today': 19,
          'on_leave_today': 3,
          'pending_approvals': 4,
          'appointments_today': 12,
        },
      };
    }

    // ---- Manager: pending approvals ----
    if (path == '/approvals') {
      return {
        'leaves': _leaves(now),
        'excuses': [],
        'inventory_requests': [],
        'payroll': [],
      };
    }

    // ---- Notifications ----
    if (path == '/notifications') {
      final items = _notifications(now);
      return {
        'data': items,
        'unread_count': items.where((n) => n['is_read'] == false).length,
      };
    }
    if (path == '/notifications/unread-count') {
      return {'count': 3};
    }

    // ---- Payroll: employee salary + payment history ----
    if (path.startsWith('/payroll/employee/')) {
      if (path.endsWith('/history')) {
        return {'data': _payrollHistory(now)};
      }
      // getEmployeeSalary parses the whole body as a PayrollItem.
      return _salaryItem(now, now.month, now.year);
    }

    // ---- Generic fallbacks so nothing errors in demo mode ----
    if (method == 'GET') {
      return {'data': [], 'summary': {}, 'stats': {}};
    }
    return {'success': true, 'data': {}};
  }

  // ---------- dataset builders ----------

  static List<Map<String, dynamic>> _appointments(DateTime now) {
    final today = _d(now);
    // name, gender, fileNo, start, end, status, sessionNo, sessionsTotal, type, icd, icdTitle
    final rows = [
      ['سارة العتيبي', 'female', 'MRN-10231', '09:00', '09:30', 'completed', 7, 12, 'center', 'M54.5', 'ألم أسفل الظهر'],
      ['محمد الدوسري', 'male', 'MRN-10488', '10:00', '10:45', 'completed', 3, 8, 'home', 'S83.5', 'إصابة الرباط الصليبي'],
      ['نورة القحطاني', 'female', 'MRN-10675', '11:30', '12:00', 'checked_in', 5, 10, 'center', 'G80.9', 'شلل دماغي'],
      ['خالد الشهري', 'male', 'MRN-10820', '13:00', '13:30', 'booked', 2, 6, 'home', 'I69.3', 'إعاقة بعد سكتة دماغية'],
      ['ريم الغامدي', 'female', 'MRN-10944', '14:15', '15:00', 'booked', 1, 4, 'center', 'M17.0', 'خشونة الركبة'],
    ];
    return [
      for (var i = 0; i < rows.length; i++)
        {
          'id': 1000 + i + 1,
          'patient': {
            'name': rows[i][0],
            'gender': rows[i][1],
            'file_no': rows[i][2],
          },
          'appointment_date': today,
          'start_time': rows[i][3],
          'end_time': rows[i][4],
          'status': rows[i][5],
          'location_notes': rows[i][8] == 'home'
              ? 'زيارة منزلية'
              : 'العيادة الرئيسية - غرفة ${i + 1}',
          'service': {'name': 'جلسة علاج طبيعي'},
          'department': {'name': 'قسم العلاج الطبيعي'},
          'session_no': rows[i][6],
          'sessions_total': rows[i][7],
          'session_type': rows[i][8],
          'icd_code': rows[i][9],
          'icd_title': rows[i][10],
          'session_duration_minutes': 30,
        },
    ];
  }

  /// A 12-session treatment plan, one session per week. Sessions before the
  /// current one are completed, the current week is checked-in, the rest are
  /// booked. Each carries its own date so the log can show day + date.
  static List<Map<String, dynamic>> _treatmentSessions(DateTime now) {
    const total = 12;
    const current = 7; // 1-based index of the in-progress session
    final sessions = <Map<String, dynamic>>[];
    for (var i = 1; i <= total; i++) {
      final date = now.add(Duration(days: (i - current) * 7));
      final String status;
      if (i < current) {
        status = 'completed';
      } else if (i == current) {
        status = 'checked_in';
      } else {
        status = 'booked';
      }
      sessions.add({
        'id': 2000 + i,
        'patient': {'name': 'سارة العتيبي', 'phone': '0551234567'},
        'appointment_date': _d(date),
        'start_time': '09:00',
        'end_time': '09:30',
        'status': status,
        'service': {'name': 'جلسة علاج طبيعي'},
        'session_no': i,
        'sessions_total': total,
        'session_type': i.isEven ? 'home' : 'center',
        'session_duration_minutes': 30,
      });
    }
    return sessions;
  }

  static List<Map<String, dynamic>> _attendanceDays(DateTime now) {
    final days = <Map<String, dynamic>>[];
    for (var day = 1; day <= now.day; day++) {
      final date = DateTime(now.year, now.month, day);
      final weekday = date.weekday; // 5 = Friday, 6 = Saturday
      final off = weekday == 5 || weekday == 6;
      days.add({
        'date': _d(date),
        'check_in_at': off ? null : _ts(DateTime(now.year, now.month, day, 8, 0)),
        'check_out_at':
            off ? null : _ts(DateTime(now.year, now.month, day, 16, 0)),
        'worked': !off,
        'partial': false,
        'worked_minutes': off ? 0 : 480,
        'sessions_count': off ? 0 : 6,
        'completed_count': off ? 0 : 6,
      });
    }
    return days;
  }

  static List<Map<String, dynamic>> _leaves(DateTime now) {
    return [
      {
        'id': 1,
        'type': 'إجازة سنوية',
        'status': 'pending',
        'start_date': _d(now.add(const Duration(days: 7))),
        'end_date': _d(now.add(const Duration(days: 10))),
        'days': 4,
        'reason': 'سفر عائلي',
        'employee': {'name': 'عبدالله المطيري'},
      },
      {
        'id': 2,
        'type': 'إجازة مرضية',
        'status': 'approved',
        'start_date': _d(now.subtract(const Duration(days: 12))),
        'end_date': _d(now.subtract(const Duration(days: 11))),
        'days': 2,
        'reason': 'وعكة صحية',
        'employee': {'name': 'عبدالله المطيري'},
      },
    ];
  }

  static List<Map<String, dynamic>> _bonuses(DateTime now) {
    return [
      {
        'id': 1,
        'employee_id': 1,
        'bonus_type': 'bonus',
        'amount': 500.0,
        'reason': 'مكافأة أداء متميز',
        'period_month': now.month,
        'period_year': now.year,
        'created_at': _ts(now.subtract(const Duration(days: 5))),
      },
      {
        'id': 2,
        'employee_id': 1,
        'bonus_type': 'bonus',
        'amount': 250.0,
        'reason': 'حافز حضور',
        'period_month': now.month,
        'period_year': now.year,
        'created_at': _ts(now.subtract(const Duration(days: 8))),
      },
      {
        'id': 3,
        'employee_id': 1,
        'bonus_type': 'deduction',
        'amount': 120.0,
        'reason': 'تأخير',
        'period_month': now.month,
        'period_year': now.year,
        'created_at': _ts(now.subtract(const Duration(days: 3))),
      },
    ];
  }

  /// A single payroll item for the given period (whole-body shape used by
  /// getEmployeeSalary).
  static Map<String, dynamic> _salaryItem(DateTime now, int month, int year) {
    const base = 850.0;
    const allowances = 150.0;
    const bonuses = 100.0;
    const deductions = 40.0;
    return {
      'id': year * 100 + month,
      'payroll_run_id': year * 100 + month,
      'employee_id': 1,
      'base_salary': base,
      'allowances': allowances,
      'bonuses': bonuses,
      'deductions': deductions,
      'net_salary': base + allowances + bonuses - deductions,
      'employee': {
        'user': {'name': 'أخصائي تجريبي'},
      },
      'notes': null,
      'month': month,
      'year': year,
    };
  }

  /// Last 6 months of payroll records, newest first — each carries its month.
  static List<Map<String, dynamic>> _payrollHistory(DateTime now) {
    final items = <Map<String, dynamic>>[];
    var month = now.month;
    var year = now.year;
    for (var i = 0; i < 6; i++) {
      items.add(_salaryItem(now, month, year));
      month -= 1;
      if (month == 0) {
        month = 12;
        year -= 1;
      }
    }
    return items;
  }

  /// Admin list of specialists and whether they acknowledged today's schedule.
  /// The first row (the current demo specialist, id 1) reflects the live
  /// in-memory [_todayAckAt] so the admin sees the tap happen.
  static List<Map<String, dynamic>> _acknowledgements(DateTime now) {
    String at(int h, int m) => _ts(DateTime(now.year, now.month, now.day, h, m));
    return [
      {
        'specialist_id': 1,
        'name': 'أخصائي تجريبي',
        'acknowledged': _todayAckAt != null,
        'acknowledged_at': _todayAckAt,
        'sessions_count': 5,
      },
      {
        'specialist_id': 2,
        'name': 'د. سارة العتيبي',
        'acknowledged': true,
        'acknowledged_at': at(8, 5),
        'sessions_count': 6,
      },
      {
        'specialist_id': 3,
        'name': 'د. محمد الدوسري',
        'acknowledged': true,
        'acknowledged_at': at(8, 12),
        'sessions_count': 4,
      },
      {
        'specialist_id': 4,
        'name': 'د. نورة القحطاني',
        'acknowledged': true,
        'acknowledged_at': at(8, 30),
        'sessions_count': 7,
      },
      {
        'specialist_id': 5,
        'name': 'د. خالد الشهري',
        'acknowledged': false,
        'acknowledged_at': null,
        'sessions_count': 3,
      },
      {
        'specialist_id': 6,
        'name': 'د. ريم الغامدي',
        'acknowledged': false,
        'acknowledged_at': null,
        'sessions_count': 5,
      },
    ];
  }

  static List<Map<String, dynamic>> _notifications(DateTime now) {
    return [
      {
        'id': 1,
        'type': 'bonus',
        'title': 'مكافأة جديدة',
        'message': 'تم إضافة مكافأة أداء بقيمة 500 ر.ع لهذا الشهر.',
        'is_read': false,
        'created_at': _ts(now.subtract(const Duration(hours: 2))),
      },
      {
        'id': 2,
        'type': 'bonus',
        'title': 'حافز حضور',
        'message': 'حصلت على حافز الحضور المنتظم بقيمة 250 ر.ع.',
        'is_read': false,
        'created_at': _ts(now.subtract(const Duration(days: 1))),
      },
      {
        'id': 3,
        'type': 'leave_request',
        'title': 'تحديث طلب إجازة',
        'message': 'تمت الموافقة على طلب إجازتك السنوية.',
        'is_read': false,
        'created_at': _ts(now.subtract(const Duration(days: 2))),
      },
      {
        'id': 4,
        'type': 'payroll_pending',
        'title': 'كشف الراتب',
        'message': 'كشف راتب هذا الشهر جاهز للاطلاع.',
        'is_read': true,
        'created_at': _ts(now.subtract(const Duration(days: 4))),
      },
    ];
  }

  static List<Map<String, dynamic>> _notes(DateTime now) {
    return [
      {
        'id': 1,
        'employee_id': 1,
        'note': 'شكراً على جهودك المتميزة هذا الشهر.',
        'visibility': 'admin_to_employee',
        'read_at': null,
        'creator': {'name': 'الإدارة'},
        'created_at': _ts(now.subtract(const Duration(days: 2))),
      },
      {
        'id': 2,
        'employee_id': 1,
        'note': 'أرجو تحديث بيانات المرضى قبل نهاية الأسبوع.',
        'visibility': 'admin_to_employee',
        'read_at': _ts(now.subtract(const Duration(days: 6))),
        'creator': {'name': 'مدير الموارد البشرية'},
        'created_at': _ts(now.subtract(const Duration(days: 7))),
      },
    ];
  }
}
