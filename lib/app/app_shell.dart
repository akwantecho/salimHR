import 'package:flutter/services.dart' show SystemNavigator;
import 'package:flutter/widgets.dart';

import '../design_system/components/bottom_nav.dart';
import '../design_system/components/bottom_nav_with_fab.dart';
import '../design_system/components/line_icons.dart';
import '../design_system/components/top_bar.dart';
import '../design_system/ds_provider.dart';
import '../design_system/primitives/ds_button.dart';
import '../design_system/primitives/ds_card.dart';
import '../design_system/primitives/ds_text.dart';
import '../services/api_provider.dart';
import 'app_state.dart';
import 'i18n.dart';
import 'screens/common_screens.dart';
import 'screens/inventory_request_screen.dart';
import 'screens/manager_screens.dart';
import 'screens/reception_screens.dart';
import 'screens/specialist_requests.dart';
import 'screens/specialist_screens.dart';
import 'screens/worker_screens.dart';

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
    if (app.showSplash) {
      return SplashScreen(
        onDone: app.finishSplash,
        onRestoreRole: app.setRole,
      );
    }
    if (app.role == null) {
      return LoginScreen(
        onRoleSelected: app.setRole,
        onLangChange: app.setLocale,
        currentLang: app.locale.languageCode,
      );
    }
    return RoleShell(role: app.role!);
  }
}

class RoleShell extends StatefulWidget {
  final UserRole role;

  const RoleShell({super.key, required this.role});

  @override
  State<RoleShell> createState() => _RoleShellState();
}

class _RoleShellState extends State<RoleShell> {
  bool _showAddPopup = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.notificationsService.fetchUnreadCount();
    });
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
      case UserRole.worker:
        return [
          BottomNavItem(label: t('الرئيسية', 'Home'), icon: LineIconType.home),
          BottomNavItem(label: t('المخزون', 'Inventory'), icon: LineIconType.chart),
          BottomNavItem(label: t('الرواتب', 'Salary'), icon: LineIconType.heart),
          BottomNavItem(label: t('ملفي', 'Profile'), icon: LineIconType.bookmark),
        ];
      case UserRole.specialist:
        return [
          BottomNavItem(label: t('الرئيسية', 'Home'), icon: LineIconType.home),
          BottomNavItem(label: t('جلساتي', 'Sessions'), icon: LineIconType.calendar),
          BottomNavItem(label: t('الحضور', 'Attendance'), icon: LineIconType.chart),
          BottomNavItem(label: t('ملفي', 'Profile'), icon: LineIconType.bookmark),
        ];
      case UserRole.reception:
        return [
          BottomNavItem(label: t('الرئيسية', 'Home'), icon: LineIconType.home),
          BottomNavItem(label: t('المواعيد', 'Appointments'), icon: LineIconType.calendar),
          BottomNavItem(label: t('المرضى', 'Patients'), icon: LineIconType.heart),
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
      case UserRole.worker:
        return switch (index) {
          0 => const WorkerHomeScreen(),
          1 => const InventoryScreen(),
          2 => const SalaryScreen(),
          _ => const MoreScreen(),
        };
      case UserRole.specialist:
        return switch (index) {
          0 => const SpecialistHomeScreen(),
          1 => const SessionsScreen(),
          2 => const AttendanceScreen(),
          _ => const MoreScreen(),
        };
      case UserRole.reception:
        return switch (index) {
          0 => const ReceptionHomeScreen(),
          1 => const ReceptionAppointmentsScreen(),
          2 => const ReceptionPatientsScreen(),
          _ => const MoreScreen(),
        };
    }
  }

  String _title(BuildContext context, UserRole role, int index) {
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    // Home tab greets each user by their first name, in the UI language.
    if (index == 0) {
      final lang = AppScope.of(context).locale.languageCode;
      final fullName = context.authService.currentUser?.localizedName(lang) ?? '';
      final first = fullName.trim().isEmpty
          ? ''
          : fullName.trim().split(RegExp(r'\s+')).first;
      return first.isEmpty
          ? t('أهلاً', 'Welcome')
          : t('أهلاً $first', 'Welcome $first');
    }

    switch (role) {
      case UserRole.manager:
        return [
          t('أهلاً مدير', 'Welcome Manager'),
          t('الموافقات', 'Approvals'),
          t('التقارير', 'Reports'),
          t('ملفي', 'Profile'),
        ][index];
      case UserRole.worker:
        return [
          t('أهلاً موظف', 'Welcome'),
          t('المخزون', 'Inventory'),
          t('راتبي', 'Salary'),
          t('ملفي', 'Profile'),
        ][index];
      case UserRole.specialist:
        return [
          t('أهلاً أخصائي', 'Welcome'),
          t('جلساتي', 'My Sessions'),
          t('الحضور', 'Attendance'),
          t('ملفي', 'Profile'),
        ][index];
      case UserRole.reception:
        return [
          t('أهلاً استقبال', 'Welcome Reception'),
          t('المواعيد', 'Appointments'),
          t('المرضى', 'Patients'),
          t('ملفي', 'Profile'),
        ][index];
    }
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
      SpecialistSubScreen.inventoryRequest =>
        InventoryRequestScreen(onBack: onBack),
      SpecialistSubScreen.none => const SizedBox.shrink(),
    };
  }

  Widget _profileSubScreen(BuildContext context, AppState app) {
    final onBack = app.hideProfileSub;
    return switch (app.profileSubScreen) {
      ProfileSubScreen.editProfile => EditProfileScreen(onBack: onBack),
      ProfileSubScreen.documents => DocumentsScreen(onBack: onBack),
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

  /// Android hardware/gesture back: step back inside the app (close overlays,
  /// return to the Home tab) and only ask to exit once already on Home.
  Future<void> _handleBack(BuildContext context, AppState app) async {
    if (_showAddPopup) {
      setState(() => _showAddPopup = false);
      return;
    }
    if (app.showNotificationsScreen) {
      app.hideNotifications();
      return;
    }
    if (app.profileSubScreen != ProfileSubScreen.none) {
      app.hideProfileSub();
      return;
    }
    if (app.specialistSubScreen != SpecialistSubScreen.none) {
      app.hideSpecialistSub();
      return;
    }
    if (app.tabIndexFor(role) != 0) {
      app.setTab(role, 0);
      return;
    }
    // Already on Home → confirm before leaving the app.
    final shouldExit = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        opaque: false,
        barrierColor: const Color(0x66000000),
        pageBuilder: (context, _, _) => const _ExitConfirmDialog(),
      ),
    );
    if (shouldExit == true) SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack(context, app);
      },
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final ds = DSProvider.of(context);
    final app = AppScope.of(context);
    final items = _items(context, role);
    final current = app.tabIndexFor(role);
    final navHeight = _navHeight(ds);
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final isSpecialist = role == UserRole.specialist;
    final isReception = role == UserRole.reception;

    // Show notifications screen if active
    if (app.showNotificationsScreen) {
      return NotificationsScreen(
        onBack: () => app.hideNotifications(),
        role: role,
      );
    }

    // Show profile sub-screens if active
    if (app.profileSubScreen != ProfileSubScreen.none) {
      return _profileSubScreen(context, app);
    }

    // Specialist/reception sub-screens (leave form, salary, etc.) take over.
    if ((isSpecialist || isReception) &&
        app.specialistSubScreen != SpecialistSubScreen.none) {
      return _specialistSubScreen(context, app);
    }

    // The FAB nav protrudes above the bar, so reserve a bit more bottom
    // padding for the body to keep content out from under it.
    final bottomReserve = isSpecialist ? navHeight + ds.spacing.xl : navHeight;

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
                    ListenableBuilder(
                      listenable: context.notificationsService,
                      builder: (context, _) => TopBarCustom(
                        title: _title(context, role, current),
                        subtitle: tr(context,
                            ar: 'مرحباً بك في تطبيق سالم لشؤون الموظفين',
                            en: 'Welcome to Salim staff affairs app'),
                        onNotifications: () {
                          app.showNotifications();
                        },
                        notificationCount: context.notificationsService.unreadCount,
                      ),
                    ),
                    SizedBox(height: ds.spacing.md),
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
        ],
      ),
    );
  }
}

/// Confirmation shown when the user presses Back on the Home tab. Pops `true`
/// to exit the app, `false`/null to stay.
class _ExitConfirmDialog extends StatelessWidget {
  const _ExitConfirmDialog();

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    return Center(
      child: Padding(
        padding: EdgeInsetsDirectional.all(ds.spacing.xl),
        child: DSCard(
          padding: EdgeInsetsDirectional.all(ds.spacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DSText(
                t('الخروج من التطبيق', 'Exit app'),
                role: DSTextRole.title,
              ),
              SizedBox(height: ds.spacing.xs),
              DSText(
                t('هل تريد الخروج من التطبيق؟', 'Do you want to exit the app?'),
                role: DSTextRole.body,
                color: ds.colors.textSecondary,
              ),
              SizedBox(height: ds.spacing.lg),
              Row(
                children: [
                  Expanded(
                    child: DSButton(
                      label: t('إلغاء', 'Cancel'),
                      variant: DSButtonVariant.ghost,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  SizedBox(width: ds.spacing.sm),
                  Expanded(
                    child: DSButton(
                      label: t('خروج', 'Exit'),
                      variant: DSButtonVariant.primary,
                      onPressed: () => Navigator.of(context).pop(true),
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
