import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';

/// Background message handler is defined in main.dart

/// Service for handling Firebase Cloud Messaging (FCM) push notifications
class FirebasePushService {
  final ApiClient _client;

  /// Lazy accessor — resolving FirebaseMessaging.instance in a field initializer
  /// throws on platforms where Firebase isn't configured (e.g. web). Accessing
  /// it lazily keeps the constructor safe; callers guard usage with [kIsWeb].
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  String? _fcmToken;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;

  // Callback for when a notification is received while app is in foreground
  void Function(RemoteMessage)? onForegroundMessage;

  // Callback for when user taps on a notification
  void Function(RemoteMessage)? onNotificationTapped;

  FirebasePushService(this._client);

  String? get fcmToken => _fcmToken;

  /// Initialize Firebase and request permissions
  Future<bool> initialize() async {
    if (kIsWeb) return false; // Push notifications are unavailable on web.
    try {
      // Background handler is set up in main.dart

      // Request permission (iOS and newer Android)
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('Push notification permission denied');
        return false;
      }

      // On iOS, wait for APNS token before getting FCM token
      if (Platform.isIOS) {
        String? apnsToken = await _messaging.getAPNSToken();
        int retries = 0;
        while (apnsToken == null && retries < 10) {
          await Future.delayed(const Duration(milliseconds: 500));
          apnsToken = await _messaging.getAPNSToken();
          retries++;
        }
        debugPrint('APNS Token available: ${apnsToken != null}');
      }

      // Get FCM token
      _fcmToken = await _messaging.getToken();
      debugPrint('FCM Token: $_fcmToken');

      // Listen for token refresh
      _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _registerTokenWithServer(newToken);
      });

      // Handle foreground messages
      _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
        debugPrint('Foreground message: ${message.notification?.title}');
        onForegroundMessage?.call(message);
      });

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        debugPrint('Notification tapped: ${message.notification?.title}');
        onNotificationTapped?.call(message);
      });

      // Check if app was opened from a notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        // Delay to allow app to fully initialize
        Future.delayed(const Duration(milliseconds: 500), () {
          onNotificationTapped?.call(initialMessage);
        });
      }

      return true;
    } catch (e) {
      debugPrint('Firebase initialization error: $e');
      return false;
    }
  }

  /// Register FCM token with the server
  Future<bool> registerToken() async {
    if (kIsWeb) return false; // No FCM token on web.
    if (_fcmToken == null) {
      // On iOS, ensure APNS token is available first
      if (Platform.isIOS) {
        String? apnsToken = await _messaging.getAPNSToken();
        int retries = 0;
        while (apnsToken == null && retries < 10) {
          await Future.delayed(const Duration(milliseconds: 500));
          apnsToken = await _messaging.getAPNSToken();
          retries++;
        }
        if (apnsToken == null) {
          debugPrint('APNS token not available after retries');
          return false;
        }
      }
      _fcmToken = await _messaging.getToken();
    }

    if (_fcmToken == null) {
      debugPrint('FCM token is null');
      return false;
    }

    debugPrint('Registering FCM token with server...');
    return _registerTokenWithServer(_fcmToken!);
  }

  Future<bool> _registerTokenWithServer(String token) async {
    try {
      await _client.post('/notifications/register-token', data: {
        'fcm_token': token,
        'device_type': Platform.isIOS ? 'ios' : 'android',
      });
      return true;
    } catch (e) {
      debugPrint('Failed to register FCM token: $e');
      return false;
    }
  }

  /// Unregister FCM token (call on logout)
  Future<bool> unregisterToken() async {
    if (kIsWeb) return false; // No FCM token registered on web.
    try {
      await _client.post('/notifications/unregister-token');
      return true;
    } catch (e) {
      debugPrint('Failed to unregister FCM token: $e');
      return false;
    }
  }

  /// Subscribe to a topic for group notifications
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  /// Get current notification settings
  Future<NotificationSettings> getSettings() async {
    return await _messaging.getNotificationSettings();
  }

  /// Dispose resources
  void dispose() {
    _foregroundSubscription?.cancel();
    _tokenRefreshSubscription?.cancel();
  }
}
