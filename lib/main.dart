import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';

import 'app/app_shell.dart';
import 'app/app_state.dart';
import 'design_system/ds_provider.dart';
import 'services/api_provider.dart';

/// Handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Handle background message if needed
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const SalimApp());
}

class SalimApp extends StatefulWidget {
  const SalimApp({super.key});

  @override
  State<SalimApp> createState() => _SalimAppState();
}

class _SalimAppState extends State<SalimApp> {
  final AppState _appState = AppState();

  @override
  void initState() {
    super.initState();
    _appState.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = DSTheme.light(
      direction: _appState.direction,
      locale: _appState.locale,
    );

    return ApiProvider(
      child: AppScope(
        notifier: _appState,
        child: DSProvider(
        theme: theme,
        child: WidgetsApp(
          color: theme.colors.background,
          locale: _appState.locale,
          textStyle: theme.typography.body,
          debugShowCheckedModeBanner: false,
          supportedLocales: [_appState.locale],
          pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
            return PageRouteBuilder<T>(
              settings: settings,
              transitionDuration: theme.animation.normal,
              reverseTransitionDuration: theme.animation.fast,
              pageBuilder: (context, animation, secondaryAnimation) =>
                  builder(context),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                final curved = CurvedAnimation(
                  parent: animation,
                  curve: theme.animation.curve,
                );
                return FadeTransition(
                  opacity: curved,
                  child: child,
                );
              },
            );
          },
          builder: (context, child) {
            final ds = DSProvider.of(context);
            return Directionality(
              textDirection: ds.textDirection,
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const AppRoot(),
        ),
      ),
      ),
    );
  }
}
