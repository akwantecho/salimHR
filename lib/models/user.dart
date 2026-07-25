import 'package:equatable/equatable.dart';

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
  final String? employeeNumber;
  final DateTime? createdAt;
  final DateTime? hireDate;
  final String? avatarUrl;

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
    this.employeeNumber,
    this.createdAt,
    this.hireDate,
    this.avatarUrl,
  });

  /// Name matching the UI language ('ar' → Arabic name when available).
  String localizedName(String lang) {
    if (lang == 'ar') {
      return (nameAr != null && nameAr!.trim().isNotEmpty) ? nameAr! : name;
    }
    return (nameEn != null && nameEn!.trim().isNotEmpty) ? nameEn! : name;
  }

  /// Official employee number to display (falls back to the internal id).
  String? get displayEmployeeNumber =>
      (employeeNumber != null && employeeNumber!.trim().isNotEmpty)
          ? employeeNumber
          : (employeeId != null ? '$employeeId' : null);

  /// Join date to show for "member since" (hire date preferred).
  DateTime? get memberSince => hireDate ?? createdAt;

  /// Get the primary role (first role in the list)
  String? get primaryRole => roles.isNotEmpty ? roles.first : null;

  /// Check if user has a specific role
  bool hasRole(String role) => roles.contains(role);

  /// Check if user has a specific permission
  bool hasPermission(String permission) => permissions.contains(permission);

  /// Check if user is an admin
  bool get isAdmin => hasRole('Admin');

  /// Check if user is a manager
  bool get isManager => hasRole('Admin') || hasRole('Manager') || hasPermission('hr.manage');

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

    DateTime? parseDate(dynamic v) =>
        (v is String && v.isNotEmpty) ? DateTime.tryParse(v) : null;

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
      employeeNumber:
          (json['employee_number'] ?? json['employee_no'])?.toString(),
      createdAt: parseDate(json['member_since'] ?? json['created_at']),
      hireDate: parseDate(json['hire_date'] ?? json['joined_at']),
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
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
