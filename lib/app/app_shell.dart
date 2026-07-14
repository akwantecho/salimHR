import 'package:flutter/widgets.dart';

import '../design_system/components/bottom_nav.dart';
import '../design_system/components/bottom_nav_with_fab.dart';
import '../design_system/components/line_icons.dart';
import '../design_system/components/top_bar.dart';
import '../design_system/ds_provider.dart';
import '../services/api_provider.dart';
import 'app_state.dart';
import 'i18n.dart';
import 'screens/common_screens.dart';
import 'screens/manager_screens.dart';
import 'screens/receptionist_billing.dart';
import 'screens/receptionist_patients.dart';
import 'screens/receptionist_screens.dart';
import 'screens/specialist_requests.dart';
import 'screens/specialist_screens.dart';

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) => const AppRouter();
}

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);

    final Widget child;
    if (app.showSplash) {
      child = SplashScreen(
        key: const ValueKey('splash'),
        onDone: app.finishSplash,
        onRestoreRole: app.setRole,
      );
    } else if (app.role == null) {
      child = LoginScreen(
        key: const ValueKey('login'),
        onRoleSelected: app.setRole,
        onLangChange: app.setLocale,
        currentLang: app.locale.languageCode,
      );
    } else {
      child = RoleShell(key: ValueKey('shell-${app.role!.name}'), role: app.role!);
    }

    // Cross-fade between splash / login / home so state swaps aren't abrupt.
    // The custom layoutBuilder expands children to fill — the default stacks
    // them with loose constraints, which collapses RoleShell's Positioned.fill
    // Stack to zero size (black screen).
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        fit: StackFit.expand,
        children: [
          ...previousChildren,
          if (currentChild != null) currentChild,
        ],
      ),
      child: child,
    );
  }
}

class RoleShell extends StatefulWidget {
  final UserRole role;

  const RoleShell({super.key, required this.role});

  @override
  State<RoleShell> createState() => _RoleShellState();
}

class _RoleShellState extends State<RoleShell>
    with SingleTickerProviderStateMixin {
  bool _showAddPopup = false;

  // Plays once when the shell first mounts (after login or session restore):
  // a deep cover with the centered logo scales up and fades out, revealing
  // the home screen — continuing the splash logo into the app.
  late final AnimationController _launch;

  @override
  void initState() {
    super.initState();
    _launch = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.notificationsService.fetchUnreadCount();
      _launch.forward();
    });
  }

  @override
  void dispose() {
    _launch.dispose();
    super.dispose();
  }

  UserRole get role => widget.role;

  double _navHeight(DSTheme ds) => ds.spacing.xl * 3;

  List<BottomNavItem> _items(BuildContext context, UserRole role) {
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    switch (role) {
      case UserRole.manager:
        return [
          BottomNavItem(label: t('الرئيسية', 'Home'), icon: LineIconType.home),
          BottomNavItem(label: t('الموافقات', 'Approvals'), icon: LineIconType.calendar),
          BottomNavItem(label: t('التقارير', 'Reports'), icon: LineIconType.chart),
          BottomNavItem(label: t('ملفي', 'Profile'), icon: LineIconType.bookmark),
        ];
      case UserRole.receptionist:
        return [
          BottomNavItem(label: t('المواعيد', 'Appointments'), icon: LineIconType.home),
          BottomNavItem(label: t('المرضى', 'Patients'), icon: LineIconType.bookmark),
          BottomNavItem(label: t('الفوترة', 'Billing'), icon: LineIconType.chart),
          BottomNavItem(label: t('ملفي', 'Profile'), icon: LineIconType.heart),
        ];
      case UserRole.specialist:
        return [
          BottomNavItem(label: t('الرئيسية', 'Home'), icon: LineIconType.home),
          BottomNavItem(label: t('جلساتي', 'Sessions'), icon: LineIconType.calendar),
          BottomNavItem(label: t('الحضور', 'Attendance'), icon: LineIconType.chart),
          BottomNavItem(label: t('ملفي', 'Profile'), icon: LineIconType.bookmark),
        ];
    }
  }

  Widget _screen(UserRole role, int index) {
    switch (role) {
      case UserRole.manager:
        return switch (index) {
          0 => const ManagerHomeScreen(),
          1 => const ManagerApprovalsScreen(),
          2 => const ManagerReportsScreen(),
          _ => const MoreScreen(),
        };
      case UserRole.receptionist:
        return switch (index) {
          0 => const ReceptionistHomeScreen(),
          1 => const ReceptionistPatientsScreen(),
          2 => const BillingScreen(),
          _ => const MoreScreen(),
        };
      case UserRole.specialist:
        return switch (index) {
          0 => const SpecialistHomeScreen(),
          1 => const SessionsScreen(),
          2 => const AttendanceScreen(),
          _ => const MoreScreen(),
        };
    }
  }

  /// Time-of-day greeting, locale-aware.
  String _greeting(BuildContext context) {
    final h = DateTime.now().hour;
    if (h < 12) return tr(context, ar: 'صباح الخير', en: 'Good morning');
    if (h < 17) return tr(context, ar: 'مساء الخير', en: 'Good afternoon');
    return tr(context, ar: 'مساء النور', en: 'Good evening');
  }


  Widget _specialistSubScreen(BuildContext context, AppState app) {
    final onBack = app.hideSpecialistSub;
    return switch (app.specialistSubScreen) {
      SpecialistSubScreen.leaveRequest =>
        LeaveRequestScreen(onBack: onBack),
      SpecialistSubScreen.noteRequest =>
        NoteRequestScreen(onBack: onBack),
      SpecialistSubScreen.patientTransferRequest =>
        PatientTransferRequestScreen(onBack: onBack),
      SpecialistSubScreen.loanRequest =>
        LoanRequestScreen(onBack: onBack),
      SpecialistSubScreen.salary =>
        SpecialistSalaryScreen(onBack: onBack),
      SpecialistSubScreen.none => const SizedBox.shrink(),
    };
  }

  Widget _profileSubScreen(BuildContext context, AppState app) {
    final onBack = app.hideProfileSub;
    return switch (app.profileSubScreen) {
      ProfileSubScreen.editProfile => EditProfileScreen(onBack: onBack),
      ProfileSubScreen.changePassword => ChangePasswordScreen(onBack: onBack),
      ProfileSubScreen.about => AboutAppScreen(
        onBack: onBack,
        onPrivacy: () => app.showProfileSub(ProfileSubScreen.privacyPolicy),
        onTerms: () => app.showProfileSub(ProfileSubScreen.termsOfService),
        onDeleteAccount: () => app.showProfileSub(ProfileSubScreen.deleteAccount),
      ),
      ProfileSubScreen.privacyPolicy => PrivacyPolicyScreen(onBack: onBack),
      ProfileSubScreen.termsOfService => TermsOfServiceScreen(onBack: onBack),
      ProfileSubScreen.deleteAccount => DeleteAccountScreen(
        onBack: onBack,
        onDeleted: () {
          app.hideProfileSub();
          context.firebasePushService.unregisterToken();
          app.logout();
        },
      ),
      ProfileSubScreen.none => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final app = AppScope.of(context);
    final items = _items(context, role);
    final current = app.tabIndexFor(role);
    final navHeight = _navHeight(ds);
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final isSpecialist = role == UserRole.specialist;

    final user = context.authService.currentUser;
    final displayName = user?.localizedName(app.locale.languageCode) ??
        tr(context, ar: 'مستخدم', en: 'User');

    // Show notifications screen if active
    if (app.showNotificationsScreen) {
      return NotificationsScreen(
        onBack: () => app.hideNotifications(),
      );
    }

    // Show profile sub-screens if active
    if (app.profileSubScreen != ProfileSubScreen.none) {
      return _profileSubScreen(context, app);
    }

    // Specialist sub-screens (leave form, salary, etc.) take over the canvas.
    if (isSpecialist &&
        app.specialistSubScreen != SpecialistSubScreen.none) {
      return _specialistSubScreen(context, app);
    }

    // Profile is always the last tab; it has its own hero header, so the
    // shared top bar (which repeats the user's name) is hidden there.
    final isProfile = current == items.length - 1;

    // The floating nav sits `viewPadding.bottom` above the screen edge and is
    // `navHeight` tall, so the body must clear both plus a small gap — otherwise
    // the last item (e.g. Logout) slides under the nav.
    final bottomReserve = viewPadding.bottom +
        navHeight +
        ds.spacing.md +
        (isSpecialist ? ds.spacing.xl : 0);

    return Container(
      color: ds.colors.background,
      child: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  ds.spacing.lg,
                  ds.spacing.lg,
                  ds.spacing.lg,
                  bottomReserve,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isProfile) ...[
                      ListenableBuilder(
                        listenable: context.notificationsService,
                        builder: (context, _) => TopBarCustom(
                          title: displayName,
                          subtitle: _greeting(context),
                          onNotifications: () {
                            app.showNotifications();
                          },
                          notificationCount:
                              context.notificationsService.unreadCount,
                        ),
                      ),
                      SizedBox(height: ds.spacing.md),
                    ],
                    Expanded(
                      child: _screen(role, current),
                    ),
                  ],
                ),
              ),
            ),
          ),
          PositionedDirectional(
            start: ds.spacing.lg,
            end: ds.spacing.lg,
            bottom: viewPadding.bottom,
            child: isSpecialist
                ? BottomNavWithFab(
                    items: items,
                    currentIndex: current,
                    onSelect: (index) => app.setTab(role, index),
                    onAddTap: () => setState(() => _showAddPopup = true),
                  )
                : BottomNavigationCustom(
                    items: items,
                    currentIndex: current,
                    onSelect: (index) => app.setTab(role, index),
                  ),
          ),
          if (isSpecialist && _showAddPopup)
            Positioned.fill(
              child: AddRequestPopup(
                onSelect: (kind) {
                  setState(() => _showAddPopup = false);
                  switch (kind) {
                    case RequestKind.leave:
                      app.showSpecialistSub(SpecialistSubScreen.leaveRequest);
                      break;
                    case RequestKind.note:
                      app.showSpecialistSub(SpecialistSubScreen.noteRequest);
                      break;
                    case RequestKind.patientTransfer:
                      app.showSpecialistSub(
                          SpecialistSubScreen.patientTransferRequest);
                      break;
                    case RequestKind.loan:
                      app.showSpecialistSub(SpecialistSubScreen.loanRequest);
                      break;
                  }
                },
                onDismiss: () => setState(() => _showAddPopup = false),
              ),
            ),

          // Launch reveal: logo cover that fades out over the home screen.
          _LaunchReveal(controller: _launch),
        ],
      ),
    );
  }
}

/// A deep-colored cover with the centered app logo that scales up and fades
/// out once, revealing the screen beneath. Ignores pointer input and removes
/// itself when the animation completes.
class _LaunchReveal extends StatelessWidget {
  final AnimationController controller;

  const _LaunchReveal({required this.controller});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final v = controller.value;
        if (v >= 1.0) return const SizedBox.shrink();
        // Cover fades out over the whole run; logo eases up and grows slightly.
        final coverOpacity = (1.0 - v).clamp(0.0, 1.0);
        final logoOpacity = (1.0 - (v * 1.4)).clamp(0.0, 1.0);
        final logoScale = 1.0 + (Curves.easeOut.transform(v) * 0.25);
        return IgnorePointer(
          child: Opacity(
            opacity: coverOpacity,
            child: Container(
              color: const Color(0xFF003C4B),
              alignment: Alignment.center,
              child: Opacity(
                opacity: logoOpacity,
                child: Transform.scale(
                  scale: logoScale,
                  child: Image.asset(
                    'assets/logo/salimhr bg.png',
                    width: ds.spacing.xl * 4,
                    height: ds.spacing.xl * 4,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
