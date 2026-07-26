import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'api_client.dart';
import 'api_exceptions.dart';

/// Service for notifications operations
class NotificationsService extends ChangeNotifier {
  final ApiClient _client;

  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  NotificationsService(this._client);

  // Getters
  List<AppNotification> get notifications => _notifications;
  List<AppNotification> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasUnread => _unreadCount > 0;

  /// Fetch all notifications
  Future<void> fetchNotifications({NotificationType? type}) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/notifications',
        queryParameters: {
          if (type != null) 'type': _typeToString(type),
        },
      );

      final notificationsResponse = NotificationsResponse.fromJson(response.data!);
      _notifications = notificationsResponse.notifications;
      _unreadCount = notificationsResponse.unreadCount;

      _setLoading(false);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  /// Fetch unread count only
  Future<void> fetchUnreadCount() async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/notifications/unread-count',
      );

      _unreadCount = response.data!['count'] as int? ?? 0;
      notifyListeners();
    } on DioException {
      // Silently fail for count updates
    }
  }

  /// Mark a notification as read
  Future<bool> markAsRead(int notificationId) async {
    try {
      await _client.post('/notifications/$notificationId/read');

      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1 && !_notifications[index].isRead) {
        _notifications[index] = _notifications[index].markAsRead();
        _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
        notifyListeners();
      }

      return true;
    } on DioException {
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead() async {
    _setLoading(true);

    try {
      await _client.post('/notifications/mark-all-read');

      // Update local state
      _notifications = _notifications.map((n) => n.markAsRead()).toList();
      _unreadCount = 0;

      _setLoading(false);
      return true;
    } on DioException catch (e) {
      _handleError(e);
      return false;
    }
  }

  /// Delete a notification
  Future<bool> deleteNotification(int notificationId) async {
    try {
      await _client.delete('/notifications/$notificationId');

      // Update local state
      final notification = _notifications.firstWhere(
        (n) => n.id == notificationId,
        orElse: () => throw Exception('Not found'),
      );

      _notifications.removeWhere((n) => n.id == notificationId);
      if (!notification.isRead) {
        _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
      }

      notifyListeners();
      return true;
    } on DioException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Clear all notifications
  Future<bool> clearAll() async {
    _setLoading(true);

    try {
      await _client.delete('/notifications');

      _notifications = [];
      _unreadCount = 0;

      _setLoading(false);
      return true;
    } on DioException catch (e) {
      _handleError(e);
      return false;
    }
  }

  /// Filter notifications by type
  List<AppNotification> filterByType(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  /// Get notifications from today
  List<AppNotification> get todayNotifications {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _notifications.where((n) {
      final notifDate = DateTime(
        n.createdAt.year,
        n.createdAt.month,
        n.createdAt.day,
      );
      return notifDate.isAtSameMomentAs(today);
    }).toList();
  }

  /// Get notifications from this week
  List<AppNotification> get thisWeekNotifications {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return _notifications.where((n) => n.createdAt.isAfter(weekAgo)).toList();
  }

  String _typeToString(NotificationType type) {
    switch (type) {
      case NotificationType.leaveRequest:
        return 'leave_request';
      case NotificationType.medicalExcuse:
        return 'medical_excuse';
      case NotificationType.payrollPending:
        return 'payroll_pending';
      case NotificationType.inventoryLow:
        return 'inventory_low';
      case NotificationType.bonus:
        return 'bonus';
      case NotificationType.noteReply:
        return 'employee_note_reply';
      case NotificationType.general:
        return 'general';
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _handleError(DioException e) {
    final apiError = e.error;
    if (apiError is ApiException) {
      _error = apiError.message;
    } else {
      _error = 'An error occurred';
    }
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
