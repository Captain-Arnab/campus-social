import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../data/api_service.dart';
import '../data/pref_service.dart';

/// Top-level handler for background FCM messages (must be top-level).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background message: ${message.messageId}');
}

class NotificationService {
  static String? _cachedToken;
  static bool _initialized = false;

  static FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  /// Initialize FCM (called after runApp so platform channel is ready).
  static Future<void> init() async {
    if (_initialized) return;
    try {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Request permission (Android 13+)
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('FCM permission: ${settings.authorizationStatus}');

      // Create Android notification channel (for display)
      if (Platform.isAndroid) {
        await _messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen(_onTokenRefresh);

      // Foreground messages
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);

      // User tapped notification (app in background)
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

      // Get initial message (app opened from terminated state via notification)
      final initial = await _messaging.getInitialMessage();
      if (initial != null) _handleNotificationPayload(initial);

      // Get and optionally register token
      await getTokenAndRegisterIfLoggedIn();

      _initialized = true;
    } catch (e, stack) {
      debugPrint('NotificationService.init error: $e');
      debugPrint('$stack');
    }
  }

  static void _onTokenRefresh(String token) {
    _cachedToken = token;
    debugPrint('FCM token refreshed');
    registerTokenWithBackend(token);
  }

  static void _onForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground: ${message.notification?.title}');
    // Optionally show in-app banner; notification may still show per platform.
  }

  static void _onMessageOpenedApp(RemoteMessage message) {
    _handleNotificationPayload(message);
  }

  static void _handleNotificationPayload(RemoteMessage message) {
    final data = message.data;
    if (data['type'] == 'organizer_message' && data['event_id'] != null) {
      // Could navigate to event detail: Get.to(EventDetailView(eventId: data['event_id']));
      debugPrint('Open event: ${data['event_id']}');
    }
  }

  /// Get current FCM token (cached after first fetch).
  static Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    try {
      _cachedToken = await _messaging.getToken();
      return _cachedToken;
    } catch (e) {
      debugPrint('FCM getToken error: $e');
      return null;
    }
  }

  /// Register token with backend if user is logged in. Call after login.
  static Future<void> registerTokenWithBackend([String? token]) async {
    final userId = await PrefService.getUserId();
    if (userId == null) return;
    final t = token ?? await getToken();
    if (t == null || t.isEmpty) return;
    try {
      final res = await ApiService.registerFcmToken(userId: userId, fcmToken: t);
      if (res.data is Map && (res.data as Map)['status'] == 'success') {
        debugPrint('FCM token registered with backend');
      }
    } catch (e) {
      debugPrint('Register FCM token error: $e');
    }
  }

  /// Fetch token and register with API when user is already logged in (e.g. app startup).
  static Future<void> getTokenAndRegisterIfLoggedIn() async {
    final t = await getToken();
    if (t != null) await registerTokenWithBackend(t);
  }
}
