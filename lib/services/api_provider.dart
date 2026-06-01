import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'api_client.dart';
import 'auth_service.dart';
import 'firebase_push_service.dart';
import 'hr_service.dart';
import 'inventory_service.dart';
import 'notifications_service.dart';
import 'payroll_service.dart';

/// Provider widget that injects all API services into the widget tree
class ApiProvider extends StatelessWidget {
  final Widget child;

  const ApiProvider({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Provider<ApiClient>(
      create: (_) => ApiClient(),
      dispose: (_, client) {
        // Cleanup if needed
      },
      child: Consumer<ApiClient>(
        builder: (context, apiClient, _) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthService>(
                create: (_) => AuthService(apiClient),
              ),
              Provider<FirebasePushService>(
                create: (_) => FirebasePushService(apiClient),
                dispose: (_, service) => service.dispose(),
              ),
              ChangeNotifierProvider<HRService>(
                create: (_) => HRService(apiClient),
              ),
              ChangeNotifierProvider<PayrollService>(
                create: (_) => PayrollService(apiClient),
              ),
              ChangeNotifierProvider<InventoryService>(
                create: (_) => InventoryService(apiClient),
              ),
              ChangeNotifierProvider<NotificationsService>(
                create: (_) => NotificationsService(apiClient),
              ),
            ],
            child: child,
          );
        },
      ),
    );
  }
}

/// Extension methods for easy service access
extension ApiServiceContext on BuildContext {
  /// Get the API client
  ApiClient get apiClient => read<ApiClient>();

  /// Get the auth service
  AuthService get authService => read<AuthService>();

  /// Watch the auth service for changes
  AuthService get watchAuth => watch<AuthService>();

  /// Get the HR service
  HRService get hrService => read<HRService>();

  /// Watch the HR service for changes
  HRService get watchHR => watch<HRService>();

  /// Get the payroll service
  PayrollService get payrollService => read<PayrollService>();

  /// Watch the payroll service for changes
  PayrollService get watchPayroll => watch<PayrollService>();

  /// Get the inventory service
  InventoryService get inventoryService => read<InventoryService>();

  /// Watch the inventory service for changes
  InventoryService get watchInventory => watch<InventoryService>();

  /// Get the notifications service
  NotificationsService get notificationsService => read<NotificationsService>();

  /// Watch the notifications service for changes
  NotificationsService get watchNotifications => watch<NotificationsService>();

  /// Get the Firebase push service
  FirebasePushService get firebasePushService => read<FirebasePushService>();
}
