import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../design_system/components/line_icons.dart';
import '../../design_system/ds_provider.dart';
import '../../design_system/primitives/ds_button.dart';
import '../../design_system/primitives/ds_card.dart';
import '../../design_system/primitives/ds_text.dart';
import '../../models/models.dart';
import '../widgets/attachment_picker.dart';
import '../widgets/reason_prompt.dart';
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
  List<PromoBanner> _banners = [];

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
      final appointmentsData = await hrService.fetchMyAppointments(
        date: dateStr,
      );
      if (!mounted) return;

      final appointmentsList = appointmentsData['data'] as List<dynamic>? ?? [];
      _todayAppointments = appointmentsList
          .map((e) => Appointment.fromJson(e as Map<String, dynamic>))
          .toList();
      _appointmentStats = {
        'total':
            (appointmentsData['stats']?['total'] as int?) ??
            _todayAppointments.length,
        'upcoming': (appointmentsData['stats']?['upcoming'] as int?) ?? 0,
        'completed': (appointmentsData['stats']?['completed'] as int?) ?? 0,
      };

      // Attendance summary for the current month
      final attendanceData = await hrService.fetchMyAttendance(
        month: today.month,
        year: today.year,
      );
      if (!mounted) return;
      _attendanceSummary = attendanceData['summary'] as Map<String, dynamic>?;

      // Leaves overview — pulled from /api/employee/leaves summary.
      final leavesSummary = await hrService.fetchMyLeavesSummary();
      if (!mounted) return;
      _pendingLeaves = leavesSummary['pending'] ?? 0;
      _approvedLeavesThisMonth = leavesSummary['approved_this_month'] ?? 0;

      // Promotional banners — managed from the server control panel.
      final lang = AppScope.of(context).locale.languageCode;
      _banners = await hrService.fetchPromoBanners(lang: lang);
      if (!mounted) return;

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
        pageBuilder: (context, _, _) =>
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
              // Promotional banners — auto-rotating carousel of 3 slides,
              // managed from the server control panel (see fetchPromoBanners).
              if (_banners.isNotEmpty) ...[
                PromoBannerCarousel(banners: _banners),
                SizedBox(height: ds.spacing.lg),
              ],

              // Stat cards: today's sessions, worked days, leaves
              Row(
                children: [
                  Expanded(
                    child: _SpecialistStatCard(
                      title: t('جلسات اليوم', 'Today Sessions'),
                      value: '${_appointmentStats['total'] ?? 0}',
                      icon: LineIconType.calendar,
                      color: const Color(0xFF6366F1),
                      onTap: () => app.setTab(UserRole.specialist, 1),
                    ),
                  ),
                  SizedBox(width: ds.spacing.sm),
                  Expanded(
                    child: _SpecialistStatCard(
                      title: t('أيام الحضور', 'Days Worked'),
                      value: '$workedDays',
                      icon: LineIconType.home,
                      color: const Color(0xFF10B981),
                      onTap: () => app.setTab(UserRole.specialist, 2),
                    ),
                  ),
                  SizedBox(width: ds.spacing.sm),
                  Expanded(
                    child: _SpecialistStatCard(
                      title: t('مكتملة', 'Done'),
                      value: '${_appointmentStats['completed'] ?? 0}',
                      icon: LineIconType.heart,
                      color: const Color(0xFFF59E0B),
                      onTap: () => app.setTab(UserRole.specialist, 1),
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
                      onTap: () =>
                          app.showSpecialistSub(SpecialistSubScreen.leaveRequest),
                    ),
                  ),
                  SizedBox(width: ds.spacing.sm),
                  Expanded(
                    child: _SpecialistStatCard(
                      title: t('إجازات الشهر', 'Leaves This Month'),
                      value: '$_approvedLeavesThisMonth',
                      icon: LineIconType.calendar,
                      color: const Color(0xFF8B5CF6),
                      onTap: () =>
                          app.showSpecialistSub(SpecialistSubScreen.leaveRequest),
                    ),
                  ),
                  SizedBox(width: ds.spacing.sm),
                  Expanded(
                    child: _SpecialistStatCard(
                      title: t('جلسات الشهر', 'Month Sessions'),
                      value: '$totalSessionsMonth',
                      icon: LineIconType.chart,
                      color: const Color(0xFF06B6D4),
                      onTap: () => app.setTab(UserRole.specialist, 1),
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
                  message: t(
                    'لا توجد جلسات قادمة اليوم',
                    'No upcoming sessions today',
                  ),
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
                      onTap: () => app.showSpecialistSub(
                        SpecialistSubScreen.noteRequest,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ds.spacing.sm),
              _QuickLinkCard(
                label: t('طلبات النقل الواردة', 'Incoming Transfers'),
                icon: LineIconType.heart,
                color: const Color(0xFFF97316),
                onTap: () => Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, _, _) =>
                        const IncomingTransfersScreen(),
                  ),
                ),
              ),
              SizedBox(height: ds.spacing.xl * 2),
            ],
          ),
        ),
      ],
    );
  }
}

/// Auto-rotating promotional banner carousel for the specialist home.
///
/// Cycles through [banners] every few seconds, supports manual swiping, and
/// shows a page-dot indicator. Slides come from [HRService.fetchPromoBanners]
/// so they can be managed from the server control panel.
class PromoBannerCarousel extends StatefulWidget {
  final List<PromoBanner> banners;

  const PromoBannerCarousel({required this.banners});

  @override
  State<PromoBannerCarousel> createState() => PromoBannerCarouselState();
}

class PromoBannerCarouselState extends State<PromoBannerCarousel> {
  static const Duration _interval = Duration(seconds: 4);
  static const Duration _animDuration = Duration(milliseconds: 450);

  final PageController _controller = PageController();
  Timer? _timer;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _timer?.cancel();
    if (widget.banners.length < 2) return;
    _timer = Timer.periodic(_interval, (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_current + 1) % widget.banners.length;
      _controller.animateToPage(
        next,
        duration: _animDuration,
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.banners.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, i) =>
                PromoBannerSlide(banner: widget.banners[i]),
          ),
        ),
        SizedBox(height: ds.spacing.sm),
        // Page-dot indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.banners.length; i++)
              AnimatedContainer(
                duration: _animDuration,
                margin: EdgeInsetsDirectional.symmetric(
                  horizontal: ds.spacing.xs,
                ),
                width: i == _current ? ds.spacing.lg : ds.spacing.sm,
                height: ds.spacing.sm,
                decoration: BoxDecoration(
                  color: i == _current
                      ? ds.colors.primary
                      : ds.colors.primary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(ds.radii.pill),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// A single promotional slide — gradient (or image) background with a title,
/// subtitle and optional action pill.
class PromoBannerSlide extends StatelessWidget {
  final PromoBanner banner;

  const PromoBannerSlide({required this.banner});

  /// Opens the banner's [PromoBanner.linkUrl] in the browser, when present.
  Future<void> _openLink() async {
    final link = banner.linkUrl;
    if (link == null || link.isEmpty) return;
    final uri = Uri.tryParse(link);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    const white = Color(0xFFFFFFFF);
    final hasLink = banner.linkUrl != null && banner.linkUrl!.isNotEmpty;
    final hasImage = banner.imageUrl != null && banner.imageUrl!.isNotEmpty;
    // Admin explicitly chose a background colour (null = not chosen).
    final hasColor = banner.colorValue != null;
    // Accent color is used ONLY when there is no image.
    final base = Color(banner.colorValue ?? 0xFF6366F1);

    // With an image: show it clean (no colored gradient/frame) — just a light
    // neutral darken so overlaid text stays legible. Without an image: use color.
    final decoration = hasImage
        ? BoxDecoration(
            borderRadius: BorderRadius.circular(ds.radii.large),
            image: DecorationImage(
              image: NetworkImage(banner.imageUrl!),
              fit: BoxFit.cover,
              colorFilter: const ColorFilter.mode(
                Color(0x33000000),
                BlendMode.darken,
              ),
            ),
            // Shadow only when the admin also chose a background colour; a plain
            // image banner renders flat with no elevation.
            boxShadow: hasColor
                ? const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ]
                : null,
          )
        : BoxDecoration(
            borderRadius: BorderRadius.circular(ds.radii.large),
            gradient: LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: [base, base.withValues(alpha: 0.72)],
            ),
            // Only cast a shadow when the admin actually chose a background
            // colour; a default (unstyled) slide stays flat with no elevation.
            boxShadow: hasColor
                ? [
                    BoxShadow(
                      color: base.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          );

    final slide = Container(
      margin: EdgeInsetsDirectional.symmetric(horizontal: ds.spacing.xs),
      padding: EdgeInsets.all(ds.spacing.lg),
      decoration: decoration,
      // Force LTR so title, subtitle and the action button all align to the
      // same (left) edge, regardless of the app language direction.
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DSText(
            banner.title,
            role: DSTextRole.headline,
            color: white,
          ),
          SizedBox(height: ds.spacing.xs),
          DSText(
            banner.subtitle,
            role: DSTextRole.body,
            color: white.withValues(alpha: 0.92),
          ),
          if (banner.actionLabel != null &&
              banner.actionLabel!.isNotEmpty) ...[
            SizedBox(height: ds.spacing.md),
            // Action label on the same (left) edge as the texts.
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ds.spacing.md,
                  vertical: ds.spacing.xs,
                ),
                decoration: BoxDecoration(
                  color: white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(ds.radii.pill),
                  border: Border.all(color: white.withValues(alpha: 0.5)),
                ),
                child: DSText(
                  banner.actionLabel!,
                  role: DSTextRole.label,
                  color: white,
                ),
              ),
            ),
          ],
        ],
        ),
      ),
    );

    if (!hasLink) return slide;
    return GestureDetector(
      onTap: _openLink,
      behavior: HitTestBehavior.opaque,
      child: slide,
    );
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
          border: Border.all(color: color.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
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
                color: color.withValues(alpha: 0.15),
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
            Expanded(child: DSText(label, role: DSTextRole.title)),
          ],
        ),
      ),
    );
  }
}

// ==================== SESSIONS SCREEN ====================

/// Header with previous/next-day arrows around the day label, letting the
/// specialist step through yesterday / today / tomorrow (and beyond).
class _DayNavHeader extends StatelessWidget {
  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _DayNavHeader({
    required this.label,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);

    Widget arrow(bool flip, VoidCallback onTap) => GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: EdgeInsetsDirectional.all(ds.spacing.sm),
            decoration: BoxDecoration(
              color: ds.colors.surface,
              borderRadius: BorderRadius.circular(ds.radii.medium),
              border: Border.all(color: ds.colors.border.withValues(alpha: 0.5)),
            ),
            child: Transform.flip(
              flipX: flip,
              child: DSLineIcon(
                type: LineIconType.arrowBack,
                color: ds.colors.textPrimary,
                size: ds.spacing.md,
              ),
            ),
          ),
        );

    return Row(
      children: [
        arrow(false, onPrev), // اليوم السابق
        SizedBox(width: ds.spacing.sm),
        Expanded(
          child: Center(
            child: DSText(label, role: DSTextRole.title, maxLines: 1),
          ),
        ),
        SizedBox(width: ds.spacing.sm),
        arrow(true, onNext), // اليوم التالي
      ],
    );
  }
}

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
  DateTime? _acknowledgedAt;
  bool _acking = false;
  late DateTime _selectedDate = _dateOnly(DateTime.now());

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  bool get _isToday => _isSameDay(_selectedDate, DateTime.now());

  /// Move the viewed day by [delta] days (−1 = yesterday, +1 = tomorrow).
  void _changeDay(int delta) {
    setState(() => _selectedDate = _dateOnly(_selectedDate.add(Duration(days: delta))));
    _load();
  }

  /// Header label: "جلسات أمس/اليوم/الغد" + the date, else a plain date.
  String _dayLabel(BuildContext context) {
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    final diff = _selectedDate.difference(_dateOnly(DateTime.now())).inDays;
    final rel = switch (diff) {
      -1 => t('جلسات أمس', "Yesterday's Sessions"),
      0 => t('جلسات اليوم', "Today's Sessions"),
      1 => t('جلسات الغد', "Tomorrow's Sessions"),
      _ => t('جلسات', 'Sessions'),
    };
    final d = _selectedDate;
    final date =
        '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
    return '$rel • $date';
  }

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
      final d = _selectedDate;
      final dateStr =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
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

      _acknowledgedAt =
          _isToday ? await hrService.fetchTodayAcknowledgement() : null;
      if (!mounted) return;

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
        pageBuilder: (context, _, _) =>
            SessionDetailScreen(appointment: appointment),
      ),
    );
    if (result != null && mounted) {
      await _load();
    }
  }

  /// Opens the room picker for a session; reloads the day when a room changes
  /// so the schedule reflects the new assignment (and others' availability).
  Future<void> _openRoomPicker(Appointment appointment) async {
    final changed = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        opaque: false,
        barrierColor: const Color(0x66000000),
        pageBuilder: (context, _, _) =>
            _RoomPickerSheet(appointment: appointment),
      ),
    );
    if (changed == true && mounted) {
      await _load();
    }
  }

  Future<void> _acknowledge() async {
    setState(() => _acking = true);
    final at = await context.hrService.acknowledgeTodaySchedule();
    if (!mounted) return;
    setState(() {
      _acking = false;
      if (at != null) _acknowledgedAt = at;
    });
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
              // Acknowledge today's schedule (only while viewing today)
              if (_isToday) ...[
                _ScheduleAckCard(
                  acknowledgedAt: _acknowledgedAt,
                  sessionsCount: _appointments.length,
                  loading: _acking,
                  onAcknowledge: _acknowledge,
                ),
                SizedBox(height: ds.spacing.lg),
              ],

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

              _DayNavHeader(
                label: _dayLabel(context),
                onPrev: () => _changeDay(-1),
                onNext: () => _changeDay(1),
              ),
            ],
          ),
        ),
        if (_appointments.isEmpty)
          SliverToBoxAdapter(
            child: _EmptyCard(
              message: t('لا توجد جلسات في هذا اليوم', 'No sessions on this day'),
              icon: LineIconType.calendar,
            ),
          )
        else
          SliverSeparatedList(
            itemBuilder: (context, index) => _SessionListCard(
              appointment: _appointments[index],
              onTap: () => _openDetail(_appointments[index]),
              onPickRoom: () => _openRoomPicker(_appointments[index]),
            ),
            itemCount: _appointments.length,
            spacing: ds.spacing.sm,
          ),
        SliverToBoxAdapter(child: SizedBox(height: ds.spacing.lg)),
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
        const Color(0xFF10B981),
      );
      await _load();
    } else {
      _showFlash(
        context.hrService.error ??
            tr(context, ar: 'فشل تسجيل الحضور', en: 'Check-in failed'),
        const Color(0xFFEF4444),
      );
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
        const Color(0xFF6366F1),
      );
      await _load();
    } else {
      _showFlash(
        context.hrService.error ??
            tr(context, ar: 'فشل تسجيل الانصراف', en: 'Check-out failed'),
        const Color(0xFFEF4444),
      );
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
                    color: _flashColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(ds.radii.medium),
                    border: Border.all(
                      color: _flashColor.withValues(alpha: 0.4),
                    ),
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
    if (h == 0) return '$mم';
    if (m == 0) return '$hس';
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
      mainText = _liveDuration(
        today.checkOutAt!.subtract(
          today.checkOutAt!.difference(today.checkInAt!),
        ),
      );
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
            color: color.withValues(alpha: 0.3),
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
            color: const Color(0xFFFFFFFF).withValues(alpha: 0.85),
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
            color: const Color(0xFFFFFFFF).withValues(alpha: 0.85),
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
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    const enDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const arMonths = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    const enMonths = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = tr(
      context,
      ar: arDays[d.weekday - 1],
      en: enDays[d.weekday - 1],
    );
    final month = tr(
      context,
      ar: arMonths[d.month - 1],
      en: enMonths[d.month - 1],
    );
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
        ? iconColor.withValues(alpha: 0.1)
        : (disabled ? ds.colors.surfaceAlt : ds.colors.surface);
    final borderColor = done
        ? iconColor.withValues(alpha: 0.35)
        : (disabled ? ds.colors.border : iconColor.withValues(alpha: 0.45));

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
                    color: iconColor.withValues(alpha: 0.15),
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
                color: iconColor.withValues(alpha: done ? 0.18 : 0.12),
                shape: BoxShape.circle,
                border: done ? Border.all(color: iconColor, width: 1.5) : null,
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
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: ds.spacing.xl,
            height: ds.spacing.xl,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
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
                DSText(_weekdayName(context, parsed), role: DSTextRole.title),
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
                  color: color.withValues(alpha: 0.12),
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
  static const _enWeekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

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
            child: Center(child: DSText(label, role: DSTextRole.title)),
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
          color: ds.colors.primary.withValues(alpha: 0.1),
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
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    const en = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
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

      final bonusData = await hr.fetchMyBonuses(
        month: now.month,
        year: now.year,
      );
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
        context,
        DateTime.now().month,
        DateTime.now().year,
      );

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
                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
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
                            color: const Color(
                              0xFFFFFFFF,
                            ).withValues(alpha: 0.9),
                          ),
                          Container(
                            padding: EdgeInsetsDirectional.symmetric(
                              horizontal: ds.spacing.sm,
                              vertical: ds.spacing.xs / 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFFFFFFF,
                              ).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(
                                ds.radii.pill,
                              ),
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
                  title: t('المكافآت والخصومات', 'Bonuses & Deductions'),
                ),
              ],
            ),
          ),
          if (_bonuses.isEmpty)
            SliverToBoxAdapter(
              child: _EmptyCard(
                message: t(
                  'لا توجد مكافآت أو خصومات هذا الشهر',
                  'No bonuses or deductions this month',
                ),
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
              child: SectionHeader(
                title: t('سجل المدفوعات', 'Payment History'),
              ),
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
                final period = item.month != null
                    ? _SpecialistMonths.label(
                        context,
                        item.month!,
                        item.year ?? DateTime.now().year,
                      )
                    : t('راتب', 'Salary');
                return _PaymentHistoryRow(
                  label: period,
                  subtitle: item.employeeName,
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
              color: color.withValues(alpha: 0.12),
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
  final String? subtitle;
  final String amount;

  const _PaymentHistoryRow({
    required this.label,
    this.subtitle,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    return DSCard(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DSText(label, role: DSTextRole.title),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  SizedBox(height: 2),
                  DSText(
                    subtitle!,
                    role: DSTextRole.caption,
                    color: ds.colors.textMuted,
                  ),
                ],
              ],
            ),
          ),
          DSText(amount, role: DSTextRole.title),
          SizedBox(width: ds.spacing.sm),
          Container(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: ds.spacing.sm,
              vertical: ds.spacing.xs / 2,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
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
        SliverToBoxAdapter(child: SectionHeader(title: t('الوارد', 'Inbox'))),
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
                    if (note.attachmentUrl != null)
                      NoteAttachmentChip(
                        url: note.attachmentUrl!,
                        name: note.attachmentName,
                        isImage: note.attachmentIsImage,
                      ),
                    // Admin replies threaded under the note.
                    if (note.replies.isNotEmpty) ...[
                      SizedBox(height: ds.spacing.sm),
                      DSText(
                        t('رد الإدارة', 'Admin reply'),
                        role: DSTextRole.label,
                        color: const Color(0xFF10B981),
                      ),
                      for (final reply in note.replies)
                        _NoteReplyTile(reply: reply),
                    ],
                  ],
                ),
              );
            },
            itemCount: _outbox.length,
            spacing: ds.spacing.sm,
          ),
        SliverToBoxAdapter(child: SizedBox(height: ds.spacing.lg)),
      ],
    );
  }
}

/// A single admin reply threaded under an employee's note. Indented with a
/// start accent so it reads as a response within the conversation.
class _NoteReplyTile extends StatelessWidget {
  final EmployeeNote reply;

  const _NoteReplyTile({required this.reply});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    // Distinct green accent so the admin's reply clearly stands out from the
    // employee's own message.
    const accent = Color(0xFF059669);
    const white = Color(0xFFFFFFFF);
    return Container(
      margin: EdgeInsetsDirectional.only(top: ds.spacing.sm, start: ds.spacing.lg),
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      decoration: BoxDecoration(
        // Solid green bubble with white text — unmistakably the admin's reply.
        color: accent,
        borderRadius: BorderRadius.circular(ds.radii.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DSLineIcon(
                type: LineIconType.chat,
                color: white,
                size: ds.spacing.md,
              ),
              SizedBox(width: ds.spacing.xs),
              Expanded(
                child: DSText(
                  reply.creatorName ?? tr(context, ar: 'رد الإدارة', en: 'Admin reply'),
                  role: DSTextRole.label,
                  color: white,
                ),
              ),
              DSText(
                _formatDate(reply.createdAt),
                role: DSTextRole.caption,
                color: white.withValues(alpha: 0.8),
              ),
            ],
          ),
          SizedBox(height: ds.spacing.xs),
          DSText(
            reply.note,
            role: DSTextRole.title,
            color: white,
          ),
          if (reply.attachmentUrl != null)
            NoteAttachmentChip(
              url: reply.attachmentUrl!,
              name: reply.attachmentName,
              isImage: reply.attachmentIsImage,
            ),
        ],
      ),
    );
  }
}

// ==================== SHARED HELPERS ====================

String _formatCurrency(BuildContext context, double amount) {
  String t(String ar, String en) => tr(context, ar: ar, en: en);
  final formatted = amount
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
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
  final VoidCallback? onTap;

  const _SpecialistStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final card = Container(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ds.radii.large),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            width: ds.spacing.xl,
            height: ds.spacing.xl,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(ds.radii.medium),
            ),
            child: Center(
              child: DSLineIcon(type: icon, color: color, size: ds.spacing.md),
            ),
          ),
          SizedBox(height: ds.spacing.sm),
          DSText(value, role: DSTextRole.headline, color: color),
          SizedBox(height: ds.spacing.xs / 2),
          DSText(
            title,
            role: DSTextRole.caption,
            color: ds.colors.textSecondary,
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
          colors: [color, color.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(ds.radii.xLarge),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
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
                  color: const Color(0xFFFFFFFF).withValues(alpha: 0.2),
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
                color: const Color(0xFFFFFFFF).withValues(alpha: 0.8),
                size: 14,
              ),
              SizedBox(width: ds.spacing.xs),
              Flexible(
                child: DSText(
                  appointment.locationNotes ??
                      appointment.serviceName ??
                      t('عيادة', 'Clinic'),
                  role: DSTextRole.body,
                  color: const Color(0xFFFFFFFF).withValues(alpha: 0.9),
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ds.radii.large),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          DSText(value, role: DSTextRole.headline, color: color),
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
  final VoidCallback? onPickRoom;

  const _SessionListCard({
    required this.appointment,
    this.onTap,
    this.onPickRoom,
  });

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
            color: statusColor.withValues(alpha: 0.08),
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
              color: statusColor.withValues(alpha: 0.12),
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
                DSText(appointment.patientName ?? '-', role: DSTextRole.title),
                SizedBox(height: ds.spacing.xs / 2),
                Row(
                  children: [
                    DSText(
                      _formatTime(context, appointment.startTime),
                      role: DSTextRole.caption,
                      color: ds.colors.textSecondary,
                    ),
                    if (appointment.serviceName != null) ...[
                      DSText(
                        ' \u2022 ',
                        role: DSTextRole.caption,
                        color: ds.colors.textMuted,
                      ),
                      Flexible(
                        child: DSText(
                          appointment.serviceName ?? '',
                          role: DSTextRole.caption,
                          color: ds.colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: ds.spacing.xs),
                // Appointment number, session type and session progress.
                Wrap(
                  spacing: ds.spacing.xs,
                  runSpacing: ds.spacing.xs,
                  children: [
                    _SessionMetaChip(
                      icon: LineIconType.bookmark,
                      label:
                          '${tr(context, ar: '\u0645\u0648\u0639\u062f #', en: 'Appt #')}${appointment.id}',
                      color: ds.colors.primary,
                    ),
                    _SessionMetaChip(
                      icon: appointment.isHomeVisit
                          ? LineIconType.home
                          : LineIconType.heart,
                      label: appointment.isHomeVisit
                          ? tr(context, ar: '\u0645\u0646\u0632\u0644\u064a', en: 'Home')
                          : tr(context, ar: '\u0641\u064a \u0627\u0644\u0645\u0631\u0643\u0632', en: 'At Center'),
                      color: appointment.isHomeVisit
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF06B6D4),
                    ),
                    if (appointment.sessionProgress != null)
                      _SessionMetaChip(
                        icon: LineIconType.chart,
                        label:
                            '${tr(context, ar: '\u0627\u0644\u062c\u0644\u0633\u0629 ', en: 'Session ')}${appointment.sessionProgress!}',
                        color: const Color(0xFF8B5CF6),
                      ),
                    // Room picker chip \u2014 inline next to the other chips (center
                    // sessions only; home visits need no room).
                    if (!appointment.isHomeVisit && onPickRoom != null)
                      _RoomChip(
                        room: appointment.roomNumber,
                        onTap: onPickRoom!,
                      ),
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
              color: statusColor.withValues(alpha: 0.1),
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

/// Small pill on a session card showing the chosen room, or a prompt to pick
/// one. Tapping opens the room picker.
class _RoomChip extends StatelessWidget {
  final int? room;
  final VoidCallback onTap;

  const _RoomChip({required this.room, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final has = room != null;
    final color = has ? const Color(0xFF6366F1) : ds.colors.textMuted;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: ds.spacing.sm,
          vertical: ds.spacing.xs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: has ? 0.12 : 0.06),
          borderRadius: BorderRadius.circular(ds.radii.pill),
          border: Border.all(color: color.withValues(alpha: has ? 0.5 : 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DSLineIcon(type: LineIconType.home, color: color, size: ds.spacing.md),
            SizedBox(width: ds.spacing.xs),
            DSText(
              has
                  ? tr(context, ar: 'غرفة ${room!}', en: 'Room ${room!}')
                  : tr(context, ar: 'اختر غرفة', en: 'Pick room'),
              role: DSTextRole.caption,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet to choose a treatment room (3–7) for a session. Rooms already
/// taken by another specialist in the same hour are shown disabled. Saving a
/// room that just got taken returns a 409 which is surfaced inline.
class _RoomPickerSheet extends StatefulWidget {
  final Appointment appointment;

  const _RoomPickerSheet({required this.appointment});

  @override
  State<_RoomPickerSheet> createState() => _RoomPickerSheetState();
}

class _RoomPickerSheetState extends State<_RoomPickerSheet> {
  RoomOptions? _options;
  bool _loading = true;
  bool _saving = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOptions());
  }

  Future<void> _loadOptions() async {
    final opts = await context.hrService.fetchRoomOptions(widget.appointment.id);
    if (!mounted) return;
    setState(() {
      _options = opts ?? const RoomOptions();
      _loading = false;
    });
  }

  Future<void> _select(int? room) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _message = null;
    });
    final res = await context.hrService.assignRoom(widget.appointment.id, room);
    if (!mounted) return;
    if (res.success) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _saving = false;
      _message = res.conflict
          ? (res.error ??
              tr(context,
                  ar: 'هذه الغرفة محجوزة في نفس الساعة',
                  en: 'This room is taken for the same hour'))
          : (res.error ?? tr(context, ar: 'تعذّر الحفظ', en: 'Could not save'));
    });
    await _loadOptions(); // refresh availability after a conflict
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    final opts = _options ?? const RoomOptions();
    final current = widget.appointment.roomNumber ?? opts.current;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        padding: EdgeInsetsDirectional.fromSTEB(
          ds.spacing.lg,
          ds.spacing.lg,
          ds.spacing.lg,
          ds.spacing.xl,
        ),
        decoration: BoxDecoration(
          color: ds.colors.background,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(ds.radii.xLarge),
            topRight: Radius.circular(ds.radii.xLarge),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DSText(t('اختر رقم الغرفة', 'Pick a room'), role: DSTextRole.headline),
              SizedBox(height: ds.spacing.xs),
              DSText(
                '${widget.appointment.patientName ?? ''} • ${_formatTime(context, widget.appointment.startTime)}',
                role: DSTextRole.caption,
                color: ds.colors.textSecondary,
              ),
              SizedBox(height: ds.spacing.lg),

              if (_loading)
                Padding(
                  padding: EdgeInsetsDirectional.all(ds.spacing.lg),
                  child: Center(
                    child: DSText(
                      t('جارٍ التحميل...', 'Loading...'),
                      role: DSTextRole.caption,
                      color: ds.colors.textSecondary,
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: ds.spacing.sm,
                  runSpacing: ds.spacing.sm,
                  children: [
                    for (final r in opts.rooms)
                      _RoomOptionButton(
                        room: r,
                        selected: r == current,
                        takenBy: (r != current) ? opts.taken[r] : null,
                        onTap: () => _select(r),
                      ),
                  ],
                ),

              if (_message != null) ...[
                SizedBox(height: ds.spacing.md),
                Container(
                  padding: EdgeInsetsDirectional.all(ds.spacing.sm),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(ds.radii.medium),
                  ),
                  child: DSText(
                    _message!,
                    role: DSTextRole.caption,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ],

              SizedBox(height: ds.spacing.lg),
              Row(
                children: [
                  if (current != null)
                    Expanded(
                      child: DSButton(
                        label: t('إزالة الغرفة', 'Clear room'),
                        variant: DSButtonVariant.ghost,
                        onPressed: _saving ? null : () => _select(null),
                      ),
                    ),
                  if (current != null) SizedBox(width: ds.spacing.sm),
                  Expanded(
                    child: DSButton(
                      label: t('إغلاق', 'Close'),
                      variant: DSButtonVariant.ghost,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One selectable room square inside the picker. Disabled (with the holder's
/// name) when another specialist already booked it this hour.
class _RoomOptionButton extends StatelessWidget {
  final int room;
  final bool selected;
  final String? takenBy;
  final VoidCallback onTap;

  const _RoomOptionButton({
    required this.room,
    required this.selected,
    required this.takenBy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final taken = takenBy != null;
    final Color color = selected
        ? const Color(0xFF6366F1)
        : taken
            ? const Color(0xFFEF4444)
            : ds.colors.textSecondary;

    return GestureDetector(
      onTap: taken ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: taken ? 0.5 : 1,
        child: Container(
          width: 92,
          padding: EdgeInsetsDirectional.symmetric(vertical: ds.spacing.md),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.14)
                : ds.colors.surface,
            borderRadius: BorderRadius.circular(ds.radii.large),
            border: Border.all(
              color: color.withValues(alpha: selected ? 0.9 : 0.4),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              DSText(
                tr(context, ar: 'غرفة $room', en: 'Room $room'),
                role: DSTextRole.title,
                color: color,
              ),
              if (taken) ...[
                SizedBox(height: 2),
                DSText(
                  takenBy!.isEmpty
                      ? tr(context, ar: 'محجوزة', en: 'Taken')
                      : takenBy!,
                  role: DSTextRole.caption,
                  color: const Color(0xFFEF4444),
                  maxLines: 1,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Prompts the specialist to acknowledge (confirm they reviewed) today's
/// schedule. Shows a warning state with a button until acknowledged, then a
/// green confirmed state with the acknowledgement time.
class _ScheduleAckCard extends StatelessWidget {
  final DateTime? acknowledgedAt;
  final int sessionsCount;
  final bool loading;
  final VoidCallback onAcknowledge;

  const _ScheduleAckCard({
    required this.acknowledgedAt,
    required this.sessionsCount,
    required this.loading,
    required this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    final done = acknowledgedAt != null;
    final color = done ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

    return Container(
      width: double.infinity,
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(ds.radii.large),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: ds.spacing.lg + ds.spacing.xs,
                height: ds.spacing.lg + ds.spacing.xs,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(ds.radii.medium),
                ),
                child: Center(
                  child: DSText(
                    done ? '✓' : '!',
                    role: DSTextRole.title,
                    color: color,
                  ),
                ),
              ),
              SizedBox(width: ds.spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DSText(
                      done
                          ? t('تم اعتماد جدول اليوم', 'Today\'s schedule confirmed')
                          : t('لم تعتمد جدول اليوم بعد', 'Today\'s schedule not confirmed'),
                      role: DSTextRole.title,
                    ),
                    SizedBox(height: 2),
                    DSText(
                      done
                          ? '${t('اعتُمد الساعة ', 'Confirmed at ')}${_formatTime(context, '${acknowledgedAt!.hour.toString().padLeft(2, '0')}:${acknowledgedAt!.minute.toString().padLeft(2, '0')}')}'
                          : t(
                              'راجع جلساتك ($sessionsCount) ثم اعتمدها',
                              'Review your $sessionsCount sessions, then confirm',
                            ),
                      role: DSTextRole.caption,
                      color: ds.colors.textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!done) ...[
            SizedBox(height: ds.spacing.md),
            GestureDetector(
              onTap: loading ? null : onAcknowledge,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: double.infinity,
                padding: EdgeInsetsDirectional.symmetric(
                  vertical: ds.spacing.sm + 2,
                ),
                decoration: BoxDecoration(
                  color: loading ? ds.colors.textMuted : color,
                  borderRadius: BorderRadius.circular(ds.radii.large),
                ),
                child: Center(
                  child: DSText(
                    loading
                        ? t('جاري الاعتماد...', 'Confirming...')
                        : t('اعتماد جلسات اليوم', 'Confirm Today\'s Sessions'),
                    role: DSTextRole.title,
                    color: const Color(0xFFFFFFFF),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Small labelled pill used on the session card for appointment number,
/// session type (home / at-center) and session progress.
class _SessionMetaChip extends StatelessWidget {
  final LineIconType icon;
  final String label;
  final Color color;

  const _SessionMetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: ds.spacing.sm,
        vertical: ds.spacing.xs / 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(ds.radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DSLineIcon(type: icon, color: color, size: ds.spacing.sm + 2),
          SizedBox(width: ds.spacing.xs),
          DSText(label, role: DSTextRole.caption, color: color),
        ],
      ),
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
            color: color.withValues(alpha: 0.08),
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
                colors: [color, color.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(ds.radii.medium),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
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

// ==================== INCOMING TRANSFERS (specialist accepts) ====================

/// Transfers directed to this specialist — they accept (→ goes to admin) or
/// reject with a reason (sent back to the requesting specialist).
class IncomingTransfersScreen extends StatefulWidget {
  const IncomingTransfersScreen({super.key});

  @override
  State<IncomingTransfersScreen> createState() =>
      _IncomingTransfersScreenState();
}

class _IncomingTransfersScreenState extends State<IncomingTransfersScreen> {
  bool _loading = true;
  List<IncomingTransfer> _items = [];
  final Set<int> _busy = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final items = await context.hrService.fetchIncomingTransfers();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _accept(IncomingTransfer t) async {
    setState(() => _busy.add(t.id));
    final ok = await context.hrService.acceptIncomingTransfer(t.id);
    if (!mounted) return;
    setState(() => _busy.remove(t.id));
    if (ok) _load();
  }

  Future<void> _reject(IncomingTransfer t) async {
    final reason = await promptForReason(
      context,
      title: tr(context, ar: 'سبب الرفض', en: 'Rejection Reason'),
      hint: tr(context,
          ar: 'اكتب سبب الرفض — يُرسل للأخصائي الطالب.',
          en: 'Write the reason — it is sent to the requester.'),
      confirmLabel: tr(context, ar: 'رفض', en: 'Reject'),
    );
    if (reason == null || !mounted) return;
    setState(() => _busy.add(t.id));
    final ok = await context.hrService.rejectIncomingTransfer(t.id, reason);
    if (!mounted) return;
    setState(() => _busy.remove(t.id));
    if (ok) _load();
  }

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
                        size: ds.spacing.lg),
                  ),
                  SizedBox(width: ds.spacing.md),
                  DSText(t('طلبات النقل الواردة', 'Incoming Transfers'),
                      role: DSTextRole.headline),
                ],
              ),
              SizedBox(height: ds.spacing.md),
              Expanded(
                child: _loading
                    ? const ShimmerLoading()
                    : _items.isEmpty
                        ? Center(
                            child: DSText(
                                t('لا توجد طلبات واردة', 'No incoming requests'),
                                role: DSTextRole.body,
                                color: ds.colors.textSecondary),
                          )
                        : ListView.separated(
                            itemCount: _items.length,
                            separatorBuilder: (_, _) =>
                                SizedBox(height: ds.spacing.sm),
                            itemBuilder: (context, i) {
                              final item = _items[i];
                              final busy = _busy.contains(item.id);
                              return DSCard(
                                padding: EdgeInsetsDirectional.all(ds.spacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        DSLineIcon(
                                            type: LineIconType.heart,
                                            color: const Color(0xFFF97316),
                                            size: ds.spacing.md),
                                        SizedBox(width: ds.spacing.sm),
                                        Expanded(
                                          child: DSText(item.patientName,
                                              role: DSTextRole.title,
                                              maxLines: 1),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: ds.spacing.xs),
                                    DSText(
                                      '${t('من', 'From')}: ${item.requesterName ?? '-'}',
                                      role: DSTextRole.caption,
                                      color: ds.colors.textSecondary,
                                    ),
                                    if (item.details != null &&
                                        item.details!.isNotEmpty) ...[
                                      SizedBox(height: ds.spacing.xs),
                                      DSText(item.details!,
                                          role: DSTextRole.body,
                                          color: ds.colors.textSecondary),
                                    ],
                                    SizedBox(height: ds.spacing.md),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: DSButton(
                                            label: busy
                                                ? t('...', '...')
                                                : t('قبول', 'Accept'),
                                            onPressed: busy
                                                ? null
                                                : () => _accept(item),
                                          ),
                                        ),
                                        SizedBox(width: ds.spacing.sm),
                                        Expanded(
                                          child: DSButton(
                                            label: t('رفض', 'Reject'),
                                            variant: DSButtonVariant.ghost,
                                            onPressed: busy
                                                ? null
                                                : () => _reject(item),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
