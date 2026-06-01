import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

enum UserRole { manager, worker, specialist }

enum ProfileSubScreen { none, editProfile, changePassword, about, privacyPolicy, termsOfService, deleteAccount }

/// Full-screen overlays reachable from the specialist tab bar / FAB popup.
/// Push these via [AppState.showSpecialistSub] and dismiss with
/// [AppState.hideSpecialistSub] — they take over the whole canvas like
/// profile sub-screens do.
enum SpecialistSubScreen {
  none,
  leaveRequest,
  noteRequest,
  patientTransferRequest,
  loanRequest,
  salary,
}

class AppState extends ChangeNotifier {
  UserRole? role;
  Locale locale = const Locale('ar');
  TextDirection direction = TextDirection.rtl;
  bool showSplash = true;
  bool showNotificationsScreen = false;
  ProfileSubScreen profileSubScreen = ProfileSubScreen.none;
  SpecialistSubScreen specialistSubScreen = SpecialistSubScreen.none;
  final Map<UserRole, int> _tabByRole = {
    UserRole.manager: 0,
    UserRole.worker: 0,
    UserRole.specialist: 0,
  };

  void setRole(UserRole value) {
    role = value;
    notifyListeners();
  }

  void setLocale(String code) {
    if (code == 'en') {
      locale = const Locale('en');
      direction = TextDirection.ltr;
    } else {
      locale = const Locale('ar');
      direction = TextDirection.rtl;
    }
    notifyListeners();
  }

  void finishSplash() {
    showSplash = false;
    notifyListeners();
  }

  void logout() {
    role = null;
    notifyListeners();
  }

  int tabIndexFor(UserRole value) => _tabByRole[value] ?? 0;

  void setTab(UserRole value, int index) {
    _tabByRole[value] = index;
    notifyListeners();
  }

  void showNotifications() {
    showNotificationsScreen = true;
    notifyListeners();
  }

  void hideNotifications() {
    showNotificationsScreen = false;
    notifyListeners();
  }

  void showProfileSub(ProfileSubScreen screen) {
    profileSubScreen = screen;
    notifyListeners();
  }

  void hideProfileSub() {
    profileSubScreen = ProfileSubScreen.none;
    notifyListeners();
  }

  void showSpecialistSub(SpecialistSubScreen screen) {
    specialistSubScreen = screen;
    notifyListeners();
  }

  void hideSpecialistSub() {
    specialistSubScreen = SpecialistSubScreen.none;
    notifyListeners();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({
    super.key,
    required AppState notifier,
    required Widget child,
  }) : super(notifier: notifier, child: child);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in context');
    return scope!.notifier!;
  }
}
