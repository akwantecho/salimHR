import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'api_client.dart';
import 'auth_service.dart';
import 'clinic_service.dart';
import 'diagnosis_service.dart';
import 'firebase_push_service.dart';
import 'hr_service.dart';
import 'inventory_service.dart';
import 'invoice_service.dart';
import 'notifications_service.dart';
import 'patient_service.dart';
import 'payroll_service.dart';
import 'reception_service.dart';
import 'schedule_service.dart';
import 'treatment_plan_service.dart';

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
              Provider<PatientService>(
                create: (_) => PatientService(apiClient),
              ),
              Provider<TreatmentPlanService>(
                create: (_) => TreatmentPlanService(apiClient),
              ),
              Provider<DiagnosisService>(
                create: (_) => DiagnosisService(apiClient),
              ),
              Provider<ScheduleService>(
                create: (_) => ScheduleService(apiClient),
              ),
              Provider<ClinicService>(
                create: (_) => ClinicService(apiClient),
              ),
              Provider<ReceptionService>(
                create: (_) => ReceptionService(apiClient),
              ),
              Provider<InvoiceService>(
                create: (_) => InvoiceService(apiClient),
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

  /// Get the patient records service
  PatientService get patientService => read<PatientService>();

  /// Get the treatment plan service
  TreatmentPlanService get treatmentPlanService => read<TreatmentPlanService>();

  /// Get the diagnosis service
  DiagnosisService get diagnosisService => read<DiagnosisService>();

  /// Get the schedule service
  ScheduleService get scheduleService => read<ScheduleService>();

  /// Get the clinic overview service
  ClinicService get clinicService => read<ClinicService>();

  /// Get the reception (front-desk) service
  ReceptionService get receptionService => read<ReceptionService>();

  /// Get the invoice collection service
  InvoiceService get invoiceService => read<InvoiceService>();

  /// Permission-driven gating — mirrors the admin panel's spatie gates.
  /// Returns false when there is no authenticated user.
  bool can(String permission) =>
      authService.currentUser?.hasPermission(permission) ?? false;

  /// True when the current user has any of [permissions].
  bool canAny(Iterable<String> permissions) =>
      authService.currentUser?.hasAnyPermission(permissions) ?? false;

  /// True when the current user has the given spatie role.
  bool hasRole(String role) =>
      authService.currentUser?.hasRole(role) ?? false;
}
