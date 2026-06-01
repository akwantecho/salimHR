import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../design_system/components/line_icons.dart';
import '../../design_system/ds_provider.dart';
import '../../design_system/primitives/ds_button.dart';
import '../../design_system/primitives/ds_card.dart';
import '../../design_system/primitives/ds_text.dart';
import '../../models/models.dart';
import '../../services/api_provider.dart';
import '../../utils/time_format.dart';
import '../app_state.dart';
import '../i18n.dart';
import '../ui/blocks.dart';
import 'specialist_session_detail.dart';

// ==================== SPECIALIST HOME SCREEN ====================

class SpecialistHomeScreen extends StatefulWidget {
  const SpecialistHomeScreen({super.key});

  @override
  State<SpecialistHomeScreen> createState() => _SpecialistHomeScreenState();
}

class _SpecialistHomeScreenState extends State<SpecialistHomeScreen> {
  bool _isLoading = true;
  String? _error;
  List<Appointment> _todayAppointments = [];
  Map<String, int> _appointmentStats = {};
  Map<String, dynamic>? _attendanceSummary;
  int _pendingLeaves = 0;
  int _approvedLeavesThisMonth = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final hrService = context.hrService;
      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Today's appointments
      final appointmentsData = await hrService.fetchMyAppointments(date: dateStr);
      if (!mounted) return;

      final appointmentsList = appointmentsData['data'] as List<dynamic>? ?? [];
      _todayAppointments = appointmentsList
          .map((e) => Appointment.fromJson(e as Map<String, dynamic>))
          .toList();
      _appointmentStats = {
        'total': (appointmentsData['stats']?['total'] as int?) ??
            _todayAppointments.length,
        'upcoming': (appointmentsData['stats']?['upcoming'] as int?) ?? 0,
        'completed': (appointmentsData['stats']?['completed'] as int?) ?? 0,
      };

      // Attendance summary for the current month
      final attendanceData =
          await hrService.fetchMyAttendance(month: today.month, year: today.year);
      if (!mounted) return;
      _attendanceSummary = attendanceData['summary'] as Map<String, dynamic>?;

      // Leaves overview — pulled from /api/employee/leaves summary.
      final leavesSummary = await hrService.fetchMyLeavesSummary();
      if (!mounted) return;
      _pendingLeaves = leavesSummary['pending'] ?? 0;
      _approvedLeavesThisMonth = leavesSummary['approved_this_month'] ?? 0;

      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openDetail(Appointment appointment) async {
    final result = await Navigator.of(context).push<Appointment>(
      PageRouteBuilder(
        pageBuilder: (context, _, __) =>
            SessionDetailScreen(appointment: appointment),
      ),
    );
    if (result != null && mounted) {
      await _load();
    }
  }

  String _firstName(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return '';
    return fullName.trim().split(RegExp(r'\s+')).first;
  }

  String _arabicGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'صباح الخير';
    if (h < 17) return 'مساء الخير';
    return 'مساء النور';
  }

  String _englishGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    if (_isLoading) {
      return const ShimmerLoading();
    }

    if (_error != null) {
      return _ErrorView(error: _error!, onRetry: _load);
    }

    final user = context.authService.currentUser;
    final firstName = _firstName(user?.name);
    final greeting = t(_arabicGreeting(), _englishGreeting());

    final nextSession = _todayAppointments
        .where((a) => a.isUpcoming || a.isCheckedIn)
        .toList();

    final workedDays = (_attendanceSummary?['worked_days'] as int?) ?? 0;
    final totalSessionsMonth =
        (_attendanceSummary?['total_sessions'] as int?) ?? 0;
    final app = AppScope.of(context);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting hero
              _GreetingHero(
                greeting: greeting,
                name: firstName,
                roleLabel: t('أخصائي', 'Specialist'),
              ),
              SizedBox(height: ds.spacing.lg),

              // Stat cards: today's sessions, worked days, leaves
              Row(
                children: [
                  Expanded(
                    child: _SpecialistStatCard(
                      title: t('جلسات اليوم', 'Today Sessions'),
                      value: '${_appointmentStats['total'] ?? 0}',
                      icon: LineIconType.calendar,
                      color: const Color(0xFF6366F1),
                    ),
                  ),
                  SizedBox(width: ds.spacing.sm),
                  Expanded(
                    child: _SpecialistStatCard(
                      title: t('أيام الحضور', 'Days Worked'),
                      value: '$workedDays',
                      icon: LineIconType.home,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  SizedBox(width: ds.spacing.sm),
                  Expanded(
                    child: _SpecialistStatCard(
                      title: t('مكتملة', 'Done'),
                      value: '${_appointmentStats['completed'] ?? 0}',
                      icon: LineIconType.heart,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ds.spacing.md),

              // Secondary row: leaves
              Row(
                children: [
                  Expanded(
                    child: _SpecialistStatCard(
                      title: t('إجازات معلقة', 'Pending Leaves'),
                      value: '$_pendingLeaves',
                      icon: LineIconType.bookmark,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                  SizedBox(width: ds.spacing.sm),
                  Expanded(
                    child: _SpecialistStatCard(
                      title: t('إجازات الشهر', 'Leaves This Month'),
                      value: '$_approvedLeavesThisMonth',
                      icon: LineIconType.calendar,
                      color: const Color(0xFF8B5CF6),
                    ),
                  ),
                  SizedBox(width: ds.spacing.sm),
                  Expanded(
                    child: _SpecialistStatCard(
                      title: t('جلسات الشهر', 'Month Sessions'),
                      value: '$totalSessionsMonth',
                      icon: LineIconType.chart,
                      color: const Color(0xFF06B6D4),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ds.spacing.lg),

              // Next Session
              SectionHeader(title: t('الجلسة القادمة', 'Next Session')),
              if (nextSession.isNotEmpty)
                _NextSessionCard(
                  appointment: nextSession.first,
                  onTap: () => _openDetail(nextSession.first),
                )
              else
                _EmptyCard(
                  message: t('لا توجد جلسات قادمة اليوم',
                      'No upcoming sessions today'),
                  icon: LineIconType.calendar,
                ),
              SizedBox(height: ds.spacing.lg),

              // Quick links
              SectionHeader(title: t('روابط سريعة', 'Quick Links')),
              Row(
                children: [
                  Expanded(
                    child: _QuickLinkCard(
                      label: t('راتبي', 'My Salary'),
                      icon: LineIconType.chart,
                      color: const Color(0xFF10B981),
                      onTap: () =>
                          app.showSpecialistSub(SpecialistSubScreen.salary),
                    ),
                  ),
                  SizedBox(width: ds.spacing.sm),
                  Expanded(
                    child: _QuickLinkCard(
                      label: t('الملاحظات', 'Notes'),
                      icon: LineIconType.chat,
                      color: const Color(0xFF6366F1),
                      onTap: () => app
                          .showSpecialistSub(SpecialistSubScreen.noteRequest),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ds.spacing.xl * 2),
            ],
          ),
        ),
      ],
    );
  }
}

class _GreetingHero extends StatelessWidget {
  final String greeting;
  final String name;
  final String roleLabel;

  const _GreetingHero({
    required this.greeting,
    required this.name,
    required this.roleLabel,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final displayName = name.isEmpty ? roleLabel : name;
    return Container(
      padding: EdgeInsetsDirectional.all(ds.spacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(ds.radii.xLarge),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DSText(
                  greeting,
                  role: DSTextRole.caption,
                  color: const Color(0xFFFFFFFF).withOpacity(0.85),
                ),
                SizedBox(height: 4),
                DSText(
                  displayName,
                  role: DSTextRole.display,
                  color: const Color(0xFFFFFFFF),
                  maxLines: 1,
                ),
                SizedBox(height: 4),
                DSText(
                  roleLabel,
                  role: DSTextRole.caption,
                  color: const Color(0xFFFFFFFF).withOpacity(0.75),
                ),
              ],
            ),
          ),
          Container(
            width: ds.spacing.xl + ds.spacing.md,
            height: ds.spacing.xl + ds.spacing.md,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF).withOpacity(0.2),
              borderRadius: BorderRadius.circular(ds.radii.large),
            ),
            child: Center(
              child: DSText(
                _initials(displayName),
                role: DSTextRole.headline,
                color: const Color(0xFFFFFFFF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}

class _QuickLinkCard extends StatelessWidget {
  final String label;
  final LineIconType icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickLinkCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsetsDirectional.all(ds.spacing.md),
        decoration: BoxDecoration(
          color: ds.colors.surface,
          borderRadius: BorderRadius.circular(ds.radii.large),
          border: Border.all(color: color.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: ds.spacing.xl,
              height: ds.spacing.xl,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: DSLineIcon(
                  type: icon,
                  color: color,
                  size: ds.spacing.md,
                ),
              ),
            ),
            SizedBox(width: ds.spacing.md),
            Expanded(
              child: DSText(label, role: DSTextRole.title),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== SESSIONS SCREEN ====================

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  bool _isLoading = true;
  String? _error;
  List<Appointment> _appointments = [];
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final hrService = context.hrService;
      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final data = await hrService.fetchMyAppointments(date: dateStr);
      if (!mounted) return;

      final list = data['data'] as List<dynamic>? ?? [];
      _appointments = list
          .map((e) => Appointment.fromJson(e as Map<String, dynamic>))
          .toList();

      _stats = {
        'upcoming': (data['stats']?['upcoming'] as int?) ?? 0,
        'completed': (data['stats']?['completed'] as int?) ?? 0,
        'cancelled': (data['stats']?['cancelled'] as int?) ?? 0,
      };

      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openDetail(Appointment appointment) async {
    final result = await Navigator.of(context).push<Appointment>(
      PageRouteBuilder(
        pageBuilder: (context, _, __) =>
            SessionDetailScreen(appointment: appointment),
      ),
    );
    if (result != null && mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    if (_isLoading) {
      return const ShimmerLoading();
    }

    if (_error != null) {
      return _ErrorView(error: _error!, onRetry: _load);
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Stats
              Row(
                children: [
                  Expanded(
                    child: _SessionStatCard(
                      title: t('قادمة', 'Upcoming'),
                      value: '${_stats['upcoming'] ?? 0}',
                      color: const Color(0xFF6366F1),
                    ),
                  ),
                  SizedBox(width: ds.spacing.sm),
                  Expanded(
                    child: _SessionStatCard(
                      title: t('مكتملة', 'Completed'),
                      value: '${_stats['completed'] ?? 0}',
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  SizedBox(width: ds.spacing.sm),
                  Expanded(
                    child: _SessionStatCard(
                      title: t('ملغاة', 'Canceled'),
                      value: '${_stats['cancelled'] ?? 0}',
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ds.spacing.lg),

              SectionHeader(
                title: t('جلسات اليوم', 'Today\'s Sessions'),
              ),
            ],
          ),
        ),
        if (_appointments.isEmpty)
          SliverToBoxAdapter(
            child: _EmptyCard(
              message: t('لا توجد جلسات اليوم', 'No sessions today'),
              icon: LineIconType.calendar,
            ),
          )
        else
          SliverSeparatedList(
            itemBuilder: (context, index) => _SessionListCard(
              appointment: _appointments[index],
              onTap: () => _openDetail(_appointments[index]),
            ),
            itemCount: _appointments.length,
            spacing: ds.spacing.sm,
          ),
        SliverToBoxAdapter(
          child: SizedBox(height: ds.spacing.lg),
        ),
      ],
    );
  }
}

// ==================== ATTENDANCE SCREEN ====================

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool _isLoading = true;
  bool _actionInFlight = false;
  String? _error;
  String? _flash;
  Color _flashColor = const Color(0xFF10B981);
  AttendanceToday? _today;
  List<AttendanceDay> _days = [];
  Map<String, dynamic> _summary = {};
  late int _month;
  late int _year;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final hr = context.hrService;
      final results = await Future.wait([
        hr.fetchTodayAttendance(),
        hr.fetchMyAttendance(month: _month, year: _year),
      ]);
      if (!mounted) return;

      _today = results[0] as AttendanceToday?;
      final monthData = results[1] as Map<String, dynamic>;
      _days = ((monthData['data'] as List<dynamic>?) ?? const [])
          .map((e) => AttendanceDay.fromJson(e as Map<String, dynamic>))
          .toList();
      _summary = (monthData['summary'] as Map<String, dynamic>?) ?? {};

      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showFlash(String message, Color color) {
    setState(() {
      _flash = message;
      _flashColor = color;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _flash = null);
    });
  }

  Future<void> _doCheckIn() async {
    setState(() => _actionInFlight = true);
    final updated = await context.hrService.checkIn();
    if (!mounted) return;
    if (updated != null) {
      _showFlash(
          tr(context, ar: 'تم تسجيل الحضور بنجاح', en: 'Checked in'),
          const Color(0xFF10B981));
      await _load();
    } else {
      _showFlash(
          context.hrService.error ??
              tr(context, ar: 'فشل تسجيل الحضور', en: 'Check-in failed'),
          const Color(0xFFEF4444));
    }
    if (mounted) setState(() => _actionInFlight = false);
  }

  Future<void> _doCheckOut() async {
    setState(() => _actionInFlight = true);
    final updated = await context.hrService.checkOut();
    if (!mounted) return;
    if (updated != null) {
      _showFlash(
          tr(context, ar: 'تم تسجيل الانصراف', en: 'Checked out'),
          const Color(0xFF6366F1));
      await _load();
    } else {
      _showFlash(
          context.hrService.error ??
              tr(context, ar: 'فشل تسجيل الانصراف', en: 'Check-out failed'),
          const Color(0xFFEF4444));
    }
    if (mounted) setState(() => _actionInFlight = false);
  }

  void _changeMonth(int delta) {
    var m = _month + delta;
    var y = _year;
    while (m < 1) {
      m += 12;
      y -= 1;
    }
    while (m > 12) {
      m -= 12;
      y += 1;
    }
    setState(() {
      _month = m;
      _year = y;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    if (_isLoading) return const ShimmerLoading();
    if (_error != null) return _ErrorView(error: _error!, onRetry: _load);

    final workedDays = (_summary['worked_days'] as int?) ?? 0;
    final totalMinutes = (_summary['total_minutes'] as int?) ?? 0;
    final totalSessions = (_summary['total_sessions'] as int?) ?? 0;
    final monthLabel = _SpecialistMonths.label(context, _month, _year);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LiveClockCard(today: _today),
              SizedBox(height: ds.spacing.md),
              _CheckInOutPanel(
                today: _today,
                inFlight: _actionInFlight,
                onCheckIn: _doCheckIn,
                onCheckOut: _doCheckOut,
              ),
              if (_flash != null) ...[
                SizedBox(height: ds.spacing.sm),
                Container(
                  padding: EdgeInsetsDirectional.all(ds.spacing.sm),
                  decoration: BoxDecoration(
                    color: _flashColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(ds.radii.medium),
                    border: Border.all(color: _flashColor.withOpacity(0.4)),
                  ),
                  child: DSText(
                    _flash!,
                    role: DSTextRole.label,
                    color: _flashColor,
                    maxLines: 3,
                  ),
                ),
              ],
              SizedBox(height: ds.spacing.lg),
              _MonthSelector(
                label: monthLabel,
                onPrev: () => _changeMonth(-1),
                onNext: () => _changeMonth(1),
              ),
              SizedBox(height: ds.spacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _SpecialistStatCard(
                      title: t('أيام الحضور', 'Days Worked'),
                      value: '$workedDays',
                      icon: LineIconType.home,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  SizedBox(width: ds.spacing.sm),
                  Expanded(
                    child: _SpecialistStatCard(
                      title: t('ساعات العمل', 'Worked Hours'),
                      value: _formatHours(totalMinutes),
                      icon: LineIconType.chart,
                      color: const Color(0xFF6366F1),
                    ),
                  ),
                  SizedBox(width: ds.spacing.sm),
                  Expanded(
                    child: _SpecialistStatCard(
                      title: t('جلسات الشهر', 'Sessions'),
                      value: '$totalSessions',
                      icon: LineIconType.calendar,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ds.spacing.lg),
              SectionHeader(title: t('سجل الحضور', 'Attendance Log')),
            ],
          ),
        ),
        if (_days.isEmpty)
          SliverToBoxAdapter(
            child: _EmptyCard(
              message: t('لا توجد بيانات حضور', 'No attendance data'),
              icon: LineIconType.calendar,
            ),
          )
        else
          SliverSeparatedList(
            itemBuilder: (context, index) =>
                _AttendanceDayCard(day: _days[index]),
            itemCount: _days.length,
            spacing: ds.spacing.xs,
          ),
        SliverToBoxAdapter(child: SizedBox(height: ds.spacing.xl * 2)),
      ],
    );
  }

  String _formatHours(int minutes) {
    if (minutes <= 0) return '0';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}م';
    if (m == 0) return '${h}س';
    return '$h:${m.toString().padLeft(2, '0')}';
  }
}

/// Top hero card showing today's date and (when available) a live "worked
/// so far" counter — updates every minute while the user has a check-in but
/// no check-out.
class _LiveClockCard extends StatefulWidget {
  final AttendanceToday? today;

  const _LiveClockCard({required this.today});

  @override
  State<_LiveClockCard> createState() => _LiveClockCardState();
}

class _LiveClockCardState extends State<_LiveClockCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _maybeStartTicker();
  }

  @override
  void didUpdateWidget(covariant _LiveClockCard old) {
    super.didUpdateWidget(old);
    _ticker?.cancel();
    _maybeStartTicker();
  }

  void _maybeStartTicker() {
    final t = widget.today;
    if (t == null) return;
    if (t.checkInAt == null || t.checkOutAt != null) return;
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _liveDuration(DateTime start) {
    final diff = DateTime.now().difference(start);
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    return '$h:${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    final today = widget.today;
    final now = DateTime.now();

    final String mainText;
    final String subText;
    final Color color;

    if (today == null || today.checkInAt == null) {
      mainText = _formatClock(now);
      subText = t('لم تُسجّل الحضور بعد', 'Not checked in yet');
      color = const Color(0xFF6366F1);
    } else if (today.checkOutAt == null) {
      mainText = _liveDuration(today.checkInAt!);
      subText = t('وقت العمل حتى الآن', 'Worked so far');
      color = const Color(0xFF10B981);
    } else {
      mainText = _liveDuration(today.checkOutAt!.subtract(
          today.checkOutAt!.difference(today.checkInAt!)));
      subText = t('يوم العمل انتهى', 'Day complete');
      color = const Color(0xFF8B5CF6);
    }

    return Container(
      padding: EdgeInsetsDirectional.all(ds.spacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [color, Color.lerp(color, const Color(0xFF000000), 0.25)!],
        ),
        borderRadius: BorderRadius.circular(ds.radii.xLarge),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DSText(
            _formatDateLong(context, now),
            role: DSTextRole.caption,
            color: const Color(0xFFFFFFFF).withOpacity(0.85),
          ),
          SizedBox(height: ds.spacing.xs),
          DSText(
            mainText,
            role: DSTextRole.display,
            color: const Color(0xFFFFFFFF),
          ),
          SizedBox(height: ds.spacing.xs),
          DSText(
            subText,
            role: DSTextRole.body,
            color: const Color(0xFFFFFFFF).withOpacity(0.85),
          ),
        ],
      ),
    );
  }

  String _formatClock(DateTime d) {
    int hour = d.hour;
    final minute = d.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    return '$hour:$minute $ampm';
  }

  String _formatDateLong(BuildContext context, DateTime d) {
    const arDays = [
      'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد',
    ];
    const enDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const arMonths = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    const enMonths = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final day = tr(context, ar: arDays[d.weekday - 1], en: enDays[d.weekday - 1]);
    final month = tr(context, ar: arMonths[d.month - 1], en: enMonths[d.month - 1]);
    return '$day · ${d.day} $month ${d.year}';
  }
}

/// Side-by-side check-in and check-out tiles. Each tile shows the recorded
/// time when set; the unset one stays tappable, the set one becomes muted.
class _CheckInOutPanel extends StatelessWidget {
  final AttendanceToday? today;
  final bool inFlight;
  final VoidCallback onCheckIn;
  final VoidCallback onCheckOut;

  const _CheckInOutPanel({
    required this.today,
    required this.inFlight,
    required this.onCheckIn,
    required this.onCheckOut,
  });

  String _fmt(DateTime? d) {
    if (d == null) return '--:--';
    int hour = d.hour;
    final minute = d.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    return '$hour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    final hasIn = today?.checkInAt != null;
    final hasOut = today?.checkOutAt != null;

    return Row(
      children: [
        Expanded(
          child: _AttendanceActionTile(
            label: t('تسجيل دخول', 'Check In'),
            time: _fmt(today?.checkInAt),
            iconColor: const Color(0xFF10B981),
            done: hasIn,
            disabled: hasIn || inFlight,
            onTap: hasIn ? null : onCheckIn,
          ),
        ),
        SizedBox(width: ds.spacing.sm),
        Expanded(
          child: _AttendanceActionTile(
            label: t('تسجيل خروج', 'Check Out'),
            time: _fmt(today?.checkOutAt),
            iconColor: const Color(0xFF6366F1),
            done: hasOut,
            disabled: !hasIn || hasOut || inFlight,
            onTap: (!hasIn || hasOut) ? null : onCheckOut,
          ),
        ),
      ],
    );
  }
}

class _AttendanceActionTile extends StatelessWidget {
  final String label;
  final String time;
  final Color iconColor;
  final bool done;
  final bool disabled;
  final VoidCallback? onTap;

  const _AttendanceActionTile({
    required this.label,
    required this.time,
    required this.iconColor,
    required this.done,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final bg = done
        ? iconColor.withOpacity(0.1)
        : (disabled ? ds.colors.surfaceAlt : ds.colors.surface);
    final borderColor = done
        ? iconColor.withOpacity(0.35)
        : (disabled ? ds.colors.border : iconColor.withOpacity(0.45));

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: ds.animation.fast,
        padding: EdgeInsetsDirectional.all(ds.spacing.md),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(ds.radii.large),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: iconColor.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          children: [
            Container(
              width: ds.spacing.xl + 4,
              height: ds.spacing.xl + 4,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(done ? 0.18 : 0.12),
                shape: BoxShape.circle,
                border: done
                    ? Border.all(color: iconColor, width: 1.5)
                    : null,
              ),
              child: Center(
                child: DSText(
                  done ? '✓' : '⏺',
                  role: DSTextRole.headline,
                  color: iconColor,
                ),
              ),
            ),
            SizedBox(height: ds.spacing.sm),
            DSText(
              label,
              role: DSTextRole.label,
              color: disabled ? ds.colors.textMuted : ds.colors.textPrimary,
            ),
            SizedBox(height: 2),
            DSText(
              time,
              role: DSTextRole.title,
              color: done ? iconColor : ds.colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceDayCard extends StatelessWidget {
  final AttendanceDay day;

  const _AttendanceDayCard({required this.day});

  String _fmtTime(DateTime? d) {
    if (d == null) return '--:--';
    int hour = d.hour;
    final minute = d.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'م' : 'ص';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    return '$hour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    final parsed = day.date;

    final Color color;
    final String label;
    if (day.worked) {
      color = const Color(0xFF10B981);
      label = t('حضور كامل', 'Worked');
    } else if (day.partial) {
      color = const Color(0xFFF59E0B);
      label = t('بدون انصراف', 'No checkout');
    } else if (day.sessionsCount > 0) {
      color = const Color(0xFF6366F1);
      label = t('${day.sessionsCount} جلسة', '${day.sessionsCount} sessions');
    } else {
      color = ds.colors.textMuted;
      label = t('غياب', 'Absent');
    }

    return Container(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      decoration: BoxDecoration(
        color: ds.colors.surface,
        borderRadius: BorderRadius.circular(ds.radii.large),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: ds.spacing.xl,
            height: ds.spacing.xl,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(ds.radii.medium),
            ),
            child: Center(
              child: DSText(
                '${parsed.day}',
                role: DSTextRole.title,
                color: color,
              ),
            ),
          ),
          SizedBox(width: ds.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DSText(_weekdayName(context, parsed),
                    role: DSTextRole.title),
                SizedBox(height: 2),
                DSText(
                  '${_fmtTime(day.checkInAt)} → ${_fmtTime(day.checkOutAt)}',
                  role: DSTextRole.caption,
                  color: ds.colors.textSecondary,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: ds.spacing.sm,
                  vertical: ds.spacing.xs / 2,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(ds.radii.pill),
                ),
                child: DSText(label, role: DSTextRole.caption, color: color),
              ),
              if (day.workedMinutes != null && day.workedMinutes! > 0) ...[
                SizedBox(height: 2),
                DSText(
                  _hours(day.workedMinutes!),
                  role: DSTextRole.caption,
                  color: ds.colors.textSecondary,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _hours(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '$h:${m.toString().padLeft(2, '0')}';
  }

  static const _arWeekdays = [
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];
  static const _enWeekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  String _weekdayName(BuildContext context, DateTime d) {
    final idx = d.weekday - 1;
    return tr(context, ar: _arWeekdays[idx], en: _enWeekdays[idx]);
  }
}

class _MonthSelector extends StatelessWidget {
  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthSelector({
    required this.label,
    required this.onPrev,
    required this.onNext,
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
        color: ds.colors.surface,
        borderRadius: BorderRadius.circular(ds.radii.large),
        border: Border.all(color: ds.colors.border),
      ),
      child: Row(
        children: [
          _MonthArrow(onTap: onPrev, label: '◀'),
          Expanded(
            child: Center(
              child: DSText(label, role: DSTextRole.title),
            ),
          ),
          _MonthArrow(onTap: onNext, label: '▶'),
        ],
      ),
    );
  }
}

class _MonthArrow extends StatelessWidget {
  final VoidCallback onTap;
  final String label;

  const _MonthArrow({required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: ds.spacing.xl,
        height: ds.spacing.xl,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ds.colors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: DSText(label, role: DSTextRole.label, color: ds.colors.primary),
      ),
    );
  }
}

class _SpecialistMonths {
  static String label(BuildContext context, int month, int year) {
    const ar = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    const en = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${tr(context, ar: ar[month - 1], en: en[month - 1])} $year';
  }
}

// ==================== SPECIALIST SALARY SCREEN ====================

class SpecialistSalaryScreen extends StatefulWidget {
  final VoidCallback onBack;

  const SpecialistSalaryScreen({super.key, required this.onBack});

  @override
  State<SpecialistSalaryScreen> createState() => _SpecialistSalaryScreenState();
}

class _SpecialistSalaryScreenState extends State<SpecialistSalaryScreen> {
  bool _isLoading = true;
  String? _error;
  PayrollItem? _salary;
  List<PayrollItem> _history = [];
  List<EmployeeBonus> _bonuses = [];
  double _totalBonuses = 0;
  double _totalDeductions = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final user = context.authService.currentUser;
      final employeeId = user?.employeeId;
      final payroll = context.payrollService;
      final hr = context.hrService;
      final now = DateTime.now();

      if (employeeId != null) {
        _salary = await payroll.getEmployeeSalary(employeeId: employeeId);
        _history = await payroll.getPaymentHistory(employeeId);
      }

      final bonusData =
          await hr.fetchMyBonuses(month: now.month, year: now.year);
      if (!mounted) return;
      final list = bonusData['data'] as List<dynamic>? ?? [];
      _bonuses = list
          .map((e) => EmployeeBonus.fromJson(e as Map<String, dynamic>))
          .toList();
      _totalBonuses =
          (bonusData['summary']?['total_bonuses'] as num?)?.toDouble() ?? 0;
      _totalDeductions =
          (bonusData['summary']?['total_deductions'] as num?)?.toDouble() ?? 0;

      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    Widget body;
    if (_isLoading) {
      body = const ShimmerLoading();
    } else if (_error != null) {
      body = _ErrorView(error: _error!, onRetry: _load);
    } else {
      final net = _salary?.netSalary ?? 0;
      final base = _salary?.baseSalary ?? 0;
      final allowances = _salary?.allowances ?? 0;
      final periodLabel = _SpecialistMonths.label(
          context, DateTime.now().month, DateTime.now().year);

      body = CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Net salary hero
                Container(
                  padding: EdgeInsetsDirectional.all(ds.spacing.lg),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: AlignmentDirectional.topStart,
                      end: AlignmentDirectional.bottomEnd,
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(ds.radii.xLarge),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          DSText(
                            t('صافي الراتب', 'Net Salary'),
                            role: DSTextRole.caption,
                            color: const Color(0xFFFFFFFF).withOpacity(0.9),
                          ),
                          Container(
                            padding: EdgeInsetsDirectional.symmetric(
                              horizontal: ds.spacing.sm,
                              vertical: ds.spacing.xs / 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFFFFFFFF).withOpacity(0.2),
                              borderRadius:
                                  BorderRadius.circular(ds.radii.pill),
                            ),
                            child: DSText(
                              periodLabel,
                              role: DSTextRole.caption,
                              color: const Color(0xFFFFFFFF),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: ds.spacing.sm),
                      DSText(
                        _formatCurrency(context, net),
                        role: DSTextRole.display,
                        color: const Color(0xFFFFFFFF),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: ds.spacing.lg),
                SectionHeader(title: t('تفاصيل الراتب', 'Salary Breakdown')),
                _SalaryBreakdownRow(
                  label: t('راتب أساسي', 'Base Salary'),
                  value: _formatCurrency(context, base),
                  color: const Color(0xFF6366F1),
                  icon: LineIconType.bookmark,
                ),
                if (allowances > 0) ...[
                  SizedBox(height: ds.spacing.sm),
                  _SalaryBreakdownRow(
                    label: t('بدلات', 'Allowances'),
                    value: '+${_formatCurrency(context, allowances)}',
                    color: const Color(0xFF10B981),
                    icon: LineIconType.heart,
                  ),
                ],
                if (_totalBonuses > 0) ...[
                  SizedBox(height: ds.spacing.sm),
                  _SalaryBreakdownRow(
                    label: t('مكافآت', 'Bonuses'),
                    value: '+${_formatCurrency(context, _totalBonuses)}',
                    color: const Color(0xFF8B5CF6),
                    icon: LineIconType.chart,
                  ),
                ],
                if (_totalDeductions > 0) ...[
                  SizedBox(height: ds.spacing.sm),
                  _SalaryBreakdownRow(
                    label: t('خصومات', 'Deductions'),
                    value: '-${_formatCurrency(context, _totalDeductions)}',
                    color: const Color(0xFFEF4444),
                    icon: LineIconType.calendar,
                  ),
                ],
                SizedBox(height: ds.spacing.lg),

                // Inline bonuses & deductions list (merged from old bonuses tab)
                SectionHeader(
                    title: t('المكافآت والخصومات', 'Bonuses & Deductions')),
              ],
            ),
          ),
          if (_bonuses.isEmpty)
            SliverToBoxAdapter(
              child: _EmptyCard(
                message: t('لا توجد مكافآت أو خصومات هذا الشهر',
                    'No bonuses or deductions this month'),
                icon: LineIconType.heart,
              ),
            )
          else
            SliverSeparatedList(
              itemBuilder: (context, index) =>
                  _BonusListCard(bonus: _bonuses[index]),
              itemCount: _bonuses.length,
              spacing: ds.spacing.sm,
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsetsDirectional.only(top: ds.spacing.lg),
              child:
                  SectionHeader(title: t('سجل المدفوعات', 'Payment History')),
            ),
          ),
          if (_history.isEmpty)
            SliverToBoxAdapter(
              child: _EmptyCard(
                message: t('لا يوجد سجل مدفوعات', 'No payment history'),
                icon: LineIconType.bookmark,
              ),
            )
          else
            SliverSeparatedList(
              itemBuilder: (context, index) {
                final item = _history[index];
                return _PaymentHistoryRow(
                  label: item.employeeName ?? t('راتب', 'Salary'),
                  amount: _formatCurrency(context, item.netSalary),
                );
              },
              itemCount: _history.length,
              spacing: ds.spacing.sm,
            ),
          SliverToBoxAdapter(child: SizedBox(height: ds.spacing.xl)),
        ],
      );
    }

    return Container(
      color: ds.colors.background,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            ds.spacing.lg,
            ds.spacing.lg,
            ds.spacing.lg,
            ds.spacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  DSIconButton(
                    onPressed: widget.onBack,
                    icon: DSLineIcon(
                      type: LineIconType.arrowBack,
                      color: ds.colors.textPrimary,
                      size: ds.spacing.md,
                    ),
                  ),
                  SizedBox(width: ds.spacing.md),
                  DSText(t('راتبي', 'My Salary'), role: DSTextRole.headline),
                ],
              ),
              SizedBox(height: ds.spacing.lg),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}

class _SalaryBreakdownRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final LineIconType icon;

  const _SalaryBreakdownRow({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Container(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      decoration: BoxDecoration(
        color: ds.colors.surface,
        borderRadius: BorderRadius.circular(ds.radii.large),
        border: Border.all(color: ds.colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: ds.spacing.xl,
            height: ds.spacing.xl,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(ds.radii.medium),
            ),
            child: Center(
              child: DSLineIcon(type: icon, color: color, size: ds.spacing.md),
            ),
          ),
          SizedBox(width: ds.spacing.md),
          Expanded(child: DSText(label, role: DSTextRole.title)),
          DSText(value, role: DSTextRole.title, color: color),
        ],
      ),
    );
  }
}

class _PaymentHistoryRow extends StatelessWidget {
  final String label;
  final String amount;

  const _PaymentHistoryRow({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    return DSCard(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      child: Row(
        children: [
          Expanded(child: DSText(label, role: DSTextRole.title)),
          DSText(amount, role: DSTextRole.title),
          SizedBox(width: ds.spacing.sm),
          Container(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: ds.spacing.sm,
              vertical: ds.spacing.xs / 2,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.12),
              borderRadius: BorderRadius.circular(ds.radii.pill),
            ),
            child: DSText(
              t('مدفوع', 'Paid'),
              role: DSTextRole.caption,
              color: const Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== NOTES SCREEN ====================

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  bool _isLoading = true;
  String? _error;
  List<EmployeeNote> _inbox = [];
  List<EmployeeNote> _outbox = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final hrService = context.hrService;
      final notes = await hrService.fetchMyNotes();
      if (!mounted) return;

      _inbox = notes.where((n) => n.isIncoming).toList();
      _outbox = notes.where((n) => n.isOutgoing).toList();

      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    if (_isLoading) {
      return const ShimmerLoading();
    }

    if (_error != null) {
      return _ErrorView(error: _error!, onRetry: _load);
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SectionHeader(
            title: t('الوارد', 'Inbox'),
          ),
        ),
        if (_inbox.isEmpty)
          SliverToBoxAdapter(
            child: _EmptyCard(
              message: t('لا توجد رسائل واردة', 'No incoming messages'),
              icon: LineIconType.chat,
            ),
          )
        else
          SliverSeparatedList(
            itemBuilder: (context, index) {
              final note = _inbox[index];
              return DSCard(
                padding: EdgeInsetsDirectional.all(ds.spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DSText(
                            note.creatorName ?? t('الإدارة', 'Admin'),
                            role: DSTextRole.title,
                          ),
                        ),
                        if (!note.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF6366F1),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: ds.spacing.xs),
                    DSText(
                      note.note,
                      role: DSTextRole.body,
                      color: ds.colors.textSecondary,
                    ),
                    SizedBox(height: ds.spacing.xs),
                    DSText(
                      _formatDate(note.createdAt),
                      role: DSTextRole.caption,
                      color: ds.colors.textMuted,
                    ),
                  ],
                ),
              );
            },
            itemCount: _inbox.length,
            spacing: ds.spacing.sm,
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsetsDirectional.only(top: ds.spacing.lg),
            child: SectionHeader(title: t('الصادر', 'Outbox')),
          ),
        ),
        if (_outbox.isEmpty)
          SliverToBoxAdapter(
            child: _EmptyCard(
              message: t('لا توجد رسائل صادرة', 'No outgoing messages'),
              icon: LineIconType.chat,
            ),
          )
        else
          SliverSeparatedList(
            itemBuilder: (context, index) {
              final note = _outbox[index];
              return DSCard(
                padding: EdgeInsetsDirectional.all(ds.spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DSText(
                            t('للإدارة', 'To Admin'),
                            role: DSTextRole.title,
                          ),
                        ),
                        DSText(
                          _formatDate(note.createdAt),
                          role: DSTextRole.caption,
                          color: ds.colors.textMuted,
                        ),
                      ],
                    ),
                    SizedBox(height: ds.spacing.xs),
                    DSText(
                      note.note,
                      role: DSTextRole.body,
                      color: ds.colors.textSecondary,
                    ),
                  ],
                ),
              );
            },
            itemCount: _outbox.length,
            spacing: ds.spacing.sm,
          ),
        SliverToBoxAdapter(
          child: SizedBox(height: ds.spacing.lg),
        ),
      ],
    );
  }
}

// ==================== SHARED HELPERS ====================

String _formatCurrency(BuildContext context, double amount) {
  String t(String ar, String en) => tr(context, ar: ar, en: en);
  final formatted = amount.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]},',
  );
  return t('$formatted ر.ع', 'OMR $formatted');
}

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String _formatTime(BuildContext context, String? time) =>
    formatTime12h(context, time);

Color _appointmentStatusColor(String status) {
  switch (status) {
    case 'booked':
      return const Color(0xFF6366F1);
    case 'checked_in':
      return const Color(0xFFF59E0B);
    case 'completed':
      return const Color(0xFF10B981);
    case 'cancelled':
      return const Color(0xFFEF4444);
    default:
      return const Color(0xFF6366F1);
  }
}

String _appointmentStatusLabel(BuildContext context, String status) {
  String t(String ar, String en) => tr(context, ar: ar, en: en);
  switch (status) {
    case 'booked':
      return t('قادمة', 'Upcoming');
    case 'checked_in':
      return t('حاضر', 'Checked In');
    case 'completed':
      return t('مكتملة', 'Completed');
    case 'cancelled':
      return t('ملغاة', 'Canceled');
    default:
      return status;
  }
}

// ==================== SHARED WIDGETS ====================

class _SpecialistStatCard extends StatelessWidget {
  final String title;
  final String value;
  final LineIconType icon;
  final Color color;

  const _SpecialistStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Container(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(ds.radii.large),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            width: ds.spacing.xl,
            height: ds.spacing.xl,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(ds.radii.medium),
            ),
            child: Center(
              child: DSLineIcon(
                type: icon,
                color: color,
                size: ds.spacing.md,
              ),
            ),
          ),
          SizedBox(height: ds.spacing.sm),
          DSText(
            value,
            role: DSTextRole.headline,
            color: color,
          ),
          SizedBox(height: ds.spacing.xs / 2),
          DSText(
            title,
            role: DSTextRole.caption,
            color: ds.colors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _NextSessionCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback? onTap;

  const _NextSessionCard({required this.appointment, this.onTap});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    final color = _appointmentStatusColor(appointment.status);

    final card = Container(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            color,
            color.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(ds.radii.xLarge),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: ds.spacing.sm,
                  vertical: ds.spacing.xs / 2,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(ds.radii.pill),
                ),
                child: DSText(
                  _appointmentStatusLabel(context, appointment.status),
                  role: DSTextRole.caption,
                  color: const Color(0xFFFFFFFF),
                ),
              ),
              DSText(
                _formatTime(context, appointment.startTime),
                role: DSTextRole.title,
                color: const Color(0xFFFFFFFF),
              ),
            ],
          ),
          SizedBox(height: ds.spacing.md),
          DSText(
            appointment.patientName ?? t('مريض', 'Patient'),
            role: DSTextRole.headline,
            color: const Color(0xFFFFFFFF),
          ),
          SizedBox(height: ds.spacing.xs),
          Row(
            children: [
              DSLineIcon(
                type: LineIconType.home,
                color: const Color(0xFFFFFFFF).withOpacity(0.8),
                size: 14,
              ),
              SizedBox(width: ds.spacing.xs),
              Flexible(
                child: DSText(
                  appointment.locationNotes ?? appointment.serviceName ?? t('عيادة', 'Clinic'),
                  role: DSTextRole.body,
                  color: const Color(0xFFFFFFFF).withOpacity(0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (onTap == null) return card;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }
}

class _SessionStatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _SessionStatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Container(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(ds.radii.large),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          DSText(
            value,
            role: DSTextRole.headline,
            color: color,
          ),
          SizedBox(height: ds.spacing.xs / 2),
          DSText(
            title,
            role: DSTextRole.caption,
            color: ds.colors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _SessionListCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback? onTap;

  const _SessionListCard({required this.appointment, this.onTap});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final statusColor = _appointmentStatusColor(appointment.status);

    final card = Container(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      decoration: BoxDecoration(
        color: ds.colors.surface,
        borderRadius: BorderRadius.circular(ds.radii.large),
        border: Border.all(color: ds.colors.border),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: ds.spacing.xl,
            height: ds.spacing.xl,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(ds.radii.medium),
            ),
            child: Center(
              child: DSLineIcon(
                type: LineIconType.calendar,
                color: statusColor,
                size: ds.spacing.md,
              ),
            ),
          ),
          SizedBox(width: ds.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DSText(
                  appointment.patientName ?? '-',
                  role: DSTextRole.title,
                ),
                SizedBox(height: ds.spacing.xs / 2),
                Row(
                  children: [
                    DSText(
                      _formatTime(context, appointment.startTime),
                      role: DSTextRole.caption,
                      color: ds.colors.textSecondary,
                    ),
                    if (appointment.locationNotes != null || appointment.serviceName != null) ...[
                      DSText(
                        ' \u2022 ',
                        role: DSTextRole.caption,
                        color: ds.colors.textMuted,
                      ),
                      Flexible(
                        child: DSText(
                          appointment.locationNotes ?? appointment.serviceName ?? '',
                          role: DSTextRole.caption,
                          color: ds.colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: ds.spacing.sm,
              vertical: ds.spacing.xs / 2,
            ),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(ds.radii.pill),
            ),
            child: DSText(
              _appointmentStatusLabel(context, appointment.status),
              role: DSTextRole.caption,
              color: statusColor,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }
}

class _BonusListCard extends StatelessWidget {
  final EmployeeBonus bonus;

  const _BonusListCard({required this.bonus});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final isBonus = bonus.isBonus;
    final color = isBonus ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final icon = isBonus ? LineIconType.heart : LineIconType.calendar;

    return Container(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      decoration: BoxDecoration(
        color: ds.colors.surface,
        borderRadius: BorderRadius.circular(ds.radii.large),
        border: Border.all(color: ds.colors.border),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: ds.spacing.xl,
            height: ds.spacing.xl,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: [
                  color,
                  color.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(ds.radii.medium),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: DSLineIcon(
                type: icon,
                color: const Color(0xFFFFFFFF),
                size: ds.spacing.md,
              ),
            ),
          ),
          SizedBox(width: ds.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DSText(
                  bonus.reason ?? (isBonus ? 'Bonus' : 'Deduction'),
                  role: DSTextRole.title,
                ),
                SizedBox(height: ds.spacing.xs / 2),
                DSText(
                  _formatDate(bonus.createdAt),
                  role: DSTextRole.caption,
                  color: ds.colors.textSecondary,
                ),
              ],
            ),
          ),
          DSText(
            '${isBonus ? '+' : '-'}${_formatCurrency(context, bonus.amount)}',
            role: DSTextRole.label,
            color: color,
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;
  final LineIconType icon;

  const _EmptyCard({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Container(
      padding: EdgeInsetsDirectional.all(ds.spacing.lg),
      decoration: BoxDecoration(
        color: ds.colors.surface,
        borderRadius: BorderRadius.circular(ds.radii.large),
        border: Border.all(color: ds.colors.border),
      ),
      child: Column(
        children: [
          DSLineIcon(
            type: icon,
            color: ds.colors.textMuted,
            size: ds.spacing.xl,
          ),
          SizedBox(height: ds.spacing.sm),
          DSText(
            message,
            role: DSTextRole.caption,
            color: ds.colors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DSLineIcon(
            type: LineIconType.bell,
            color: const Color(0xFFEF4444),
            size: ds.spacing.xl,
          ),
          SizedBox(height: ds.spacing.md),
          DSText(
            t('حدث خطأ', 'An error occurred'),
            role: DSTextRole.title,
            color: const Color(0xFFEF4444),
          ),
          SizedBox(height: ds.spacing.sm),
          DSText(
            error,
            role: DSTextRole.caption,
            color: ds.colors.textSecondary,
          ),
          SizedBox(height: ds.spacing.lg),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: ds.spacing.lg,
                vertical: ds.spacing.sm,
              ),
              decoration: BoxDecoration(
                color: ds.colors.primary,
                borderRadius: BorderRadius.circular(ds.radii.medium),
              ),
              child: DSText(
                t('إعادة المحاولة', 'Retry'),
                role: DSTextRole.label,
                color: const Color(0xFFFFFFFF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

