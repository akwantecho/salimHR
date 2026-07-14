import 'package:equatable/equatable.dart';

/// Spatie permission names as they arrive from the backend (`getAllPermissions`).
/// Keep these in sync with the Laravel `RoleController` / permission seeder so
/// mobile gating mirrors the admin panel exactly. See salimerp permission gates.
class Perms {
  Perms._();

  // Clinical (specialist work)
  static const patientsManage = 'patients.manage';
  static const appointmentsManage = 'appointments.manage';
  static const treatmentPlansManage = 'treatment_plans.manage';

  // Management / HR
  static const hrManage = 'hr.manage';
  static const approvalsView = 'approvals.view';
  static const payrollView = 'payroll.view';
  static const attendanceManage = 'attendance.manage';

  // Inventory
  static const inventoryView = 'inventory.view';
  static const inventoryManageItems = 'inventory.manage_items';
  static const inventoryRequestsCreate = 'inventory.requests.create';

  // Front desk (reception)
  static const invoicesCollect = 'invoices.collect';
  static const notificationsSend = 'notifications.send';

  /// Permissions that mark a user as doing clinical work.
  static const clinical = [
    patientsManage,
    appointmentsManage,
    treatmentPlansManage,
  ];

  /// Permissions that mark a user as a manager/HR persona.
  static const management = [hrManage, approvalsView, payrollView];
}

/// User model matching Laravel's User model
class User extends Equatable {
  final int id;
  final String name;
  final String? nameAr;
  final String? nameEn;
  final String email;
  final String? phone;
  final List<String> roles;
  final List<String> permissions;
  final int? clinicId;
  final String? clinicName;
  final int? employeeId;
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.name,
    this.nameAr,
    this.nameEn,
    required this.email,
    this.phone,
    this.roles = const [],
    this.permissions = const [],
    this.clinicId,
    this.clinicName,
    this.employeeId,
    this.createdAt,
  });

  /// Locale-aware display name. Uses the employee's Arabic/English name when
  /// available (falls through the other locale), else the base `name`.
  String localizedName(String localeCode) {
    final ar = nameAr?.trim() ?? '';
    final en = nameEn?.trim() ?? '';
    if (localeCode == 'ar') {
      return ar.isNotEmpty ? ar : (en.isNotEmpty ? en : name);
    }
    return en.isNotEmpty ? en : (ar.isNotEmpty ? ar : name);
  }

  /// Get the primary role (first role in the list)
  String? get primaryRole => roles.isNotEmpty ? roles.first : null;

  /// Check if user has a specific role
  bool hasRole(String role) => roles.contains(role);

  /// Check if user has a specific permission
  bool hasPermission(String permission) => permissions.contains(permission);

  /// Check if user has any of the given permissions
  bool hasAnyPermission(Iterable<String> perms) => perms.any(hasPermission);

  /// Check if user has any of the given roles
  bool hasAnyRole(Iterable<String> names) => names.any(hasRole);

  /// Check if user is an admin
  bool get isAdmin => hasRole('Admin');

  /// Check if user is a manager
  bool get isManager => hasRole('Admin') || hasRole('Manager') || hasPermission(Perms.hrManage);

  /// Front-desk user — drives the Receptionist shell.
  bool get isReceptionist => hasRole('Receptionist');

  /// True when the user performs clinical work (drives the specialist shell +
  /// gates the clinical tabs/actions). Mirrors the admin panel's clinical
  /// permission gates.
  bool get isClinical =>
      hasRole('Specialist') || hasAnyPermission(Perms.clinical);

  factory User.fromJson(Map<String, dynamic> json) {
    // Parse roles - can be an array from Spatie's getRoleNames()
    List<String> roles = [];
    if (json['roles'] != null) {
      if (json['roles'] is List) {
        roles = (json['roles'] as List).map((e) => e.toString()).toList();
      } else if (json['roles'] is String) {
        roles = [json['roles'] as String];
      }
    } else if (json['role'] != null) {
      roles = [json['role'] as String];
    }

    // Parse permissions
    List<String> permissions = [];
    if (json['permissions'] != null && json['permissions'] is List) {
      permissions = (json['permissions'] as List).map((e) => e.toString()).toList();
    }

    // Parse default clinic
    int? clinicId;
    String? clinicName;
    if (json['default_clinic'] != null) {
      final clinic = json['default_clinic'] as Map<String, dynamic>;
      clinicId = clinic['id'] as int?;
      clinicName = clinic['name'] as String?;
    } else {
      clinicId = json['clinic_id'] as int?;
    }

    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      nameAr: json['name_ar'] as String?,
      nameEn: json['name_en'] as String?,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      roles: roles,
      permissions: permissions,
      clinicId: clinicId,
      clinicName: clinicName,
      employeeId: json['employee_id'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'name_ar': nameAr,
    'name_en': nameEn,
    'email': email,
    'phone': phone,
    'roles': roles,
    'permissions': permissions,
    'clinic_id': clinicId,
    'employee_id': employeeId,
  };

  @override
  List<Object?> get props => [id, name, email, phone, roles, permissions, clinicId, employeeId];
}

/// Authentication response from login
class AuthResponse {
  final User user;
  final String token;

  const AuthResponse({
    required this.user,
    required this.token,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      token: json['token'] as String,
    );
  }
}
