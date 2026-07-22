import 'package:equatable/equatable.dart';

/// Notification types matching Laravel's AdminNotification types
enum NotificationType {
  leaveRequest,
  medicalExcuse,
  payrollPending,
  inventoryLow,
  bonus,
  general,
}

/// Admin notification model
class AppNotification extends Equatable {
  final int id;
  final NotificationType type;
  final String title;
  final String? message;
  final String? imageUrl;
  final bool isRead;
  final String? actionUrl;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final DateTime? readAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    this.message,
    this.imageUrl,
    required this.isRead,
    this.actionUrl,
    this.data,
    required this.createdAt,
    this.readAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as int,
      type: _parseType(json['type'] as String?),
      title: json['title'] as String,
      message: json['message'] as String?,
      imageUrl: json['image_url'] as String?,
      isRead: json['is_read'] as bool? ?? json['read_at'] != null,
      actionUrl: json['action_url'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
    );
  }

  static NotificationType _parseType(String? type) {
    switch (type) {
      case 'leave_request':
        return NotificationType.leaveRequest;
      case 'medical_excuse':
        return NotificationType.medicalExcuse;
      case 'payroll_pending':
        return NotificationType.payrollPending;
      case 'inventory_low':
        return NotificationType.inventoryLow;
      case 'bonus':
      case 'employee_bonus':
        return NotificationType.bonus;
      default:
        return NotificationType.general;
    }
  }

  /// Get icon name based on notification type
  String get iconName {
    switch (type) {
      case NotificationType.leaveRequest:
        return 'calendar';
      case NotificationType.medicalExcuse:
        return 'heart';
      case NotificationType.payrollPending:
        return 'chart';
      case NotificationType.inventoryLow:
        return 'bookmark';
      case NotificationType.bonus:
        return 'heart';
      case NotificationType.general:
        return 'bell';
    }
  }

  /// Copy with read status updated
  AppNotification markAsRead() => AppNotification(
    id: id,
    type: type,
    title: title,
    message: message,
    imageUrl: imageUrl,
    isRead: true,
    actionUrl: actionUrl,
    data: data,
    createdAt: createdAt,
    readAt: DateTime.now(),
  );

  @override
  List<Object?> get props => [id, type, title, isRead, createdAt];
}

/// Notifications list response with metadata
class NotificationsResponse {
  final List<AppNotification> notifications;
  final int unreadCount;
  final int totalCount;

  const NotificationsResponse({
    required this.notifications,
    required this.unreadCount,
    required this.totalCount,
  });

  factory NotificationsResponse.fromJson(Map<String, dynamic> json) {
    // Handle Laravel paginated response: data can be a List or a pagination object
    List<dynamic> items = [];
    int total = 0;

    final dataField = json['data'];
    if (dataField is List) {
      // Direct list
      items = dataField;
      total = items.length;
    } else if (dataField is Map<String, dynamic>) {
      // Paginated response - actual data is in data.data
      items = dataField['data'] as List<dynamic>? ?? [];
      total = dataField['total'] as int? ?? items.length;
    }

    // Get unread count from stats if available
    final stats = json['stats'] as Map<String, dynamic>?;
    final unreadCount = stats?['unread'] as int? ?? json['unread_count'] as int? ?? 0;

    return NotificationsResponse(
      notifications: items
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList(),
      unreadCount: unreadCount,
      totalCount: total,
    );
  }
}
