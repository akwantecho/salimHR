import 'package:equatable/equatable.dart';

/// Notification types matching Laravel's AdminNotification types
enum NotificationType {
  leaveRequest,
  medicalExcuse,
  payrollPending,
  inventoryLow,
  bonus,
  noteReply,
  approved, // request approved/accepted (leave, loan, transfer, excuse)
  rejected, // request rejected (carries the reason)
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
      case 'employee_note_reply':
        return NotificationType.noteReply;
      case 'leave_approved':
      case 'loan_approved':
      case 'transfer_approved':
      case 'transfer_accepted':
      case 'excuse_approved':
      case 'inventory_approved':
      case 'request_approved':
        return NotificationType.approved;
      case 'leave_rejected':
      case 'loan_rejected':
      case 'transfer_rejected':
      case 'excuse_rejected':
      case 'inventory_rejected':
      case 'request_rejected':
        return NotificationType.rejected;
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
      case NotificationType.noteReply:
        return 'chat';
      case NotificationType.approved:
        return 'heart';
      case NotificationType.rejected:
        return 'bell';
      case NotificationType.general:
        return 'bell';
    }
  }

  /// True when this notification is a reply/decision that carries content the
  /// user should clearly read (a reply, or an approve/reject with a reason).
  bool get isReplyOrDecision =>
      type == NotificationType.noteReply ||
      type == NotificationType.approved ||
      type == NotificationType.rejected;

  /// Splits a reply/decision [message] into the quoted original (what the
  /// user wrote / requested) and the actual reply or reason. Backend sends
  /// e.g. «رد على ملاحظتك: «النص» — الرد». Returns (original, reply); either
  /// may be null if the message doesn't follow the pattern.
  (String?, String?) get splitReply {
    final m = message?.trim();
    if (m == null || m.isEmpty) return (null, null);
    final open = m.indexOf('«');
    final close = open >= 0 ? m.indexOf('»', open + 1) : -1;
    if (open < 0 || close < 0) return (null, m); // no quote → all is the reply
    final original = m.substring(open + 1, close).trim();
    var rest = m.substring(close + 1).trim();
    // Strip a leading separator (— , - , :) before the reply text.
    rest = rest.replaceFirst(RegExp(r'^[—\-:\s]+'), '').trim();
    return (original.isEmpty ? null : original, rest.isEmpty ? null : rest);
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
