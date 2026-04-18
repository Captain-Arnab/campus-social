import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../controllers/inbox_notification_controller.dart';
import '../data/api_service.dart';
import '../data/pref_service.dart';
import '../views/event_detail_view.dart';

// Top-level background handler — must stay here, not inside the class
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background message: ${message.messageId}');
}

// Android notification channel — ID must match AndroidManifest meta-data
const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'high_importance_channel',
  'MiCampus Notifications',
  description: 'Event alerts and organizer messages',
  importance: Importance.high,
  playSound: true,
);

class NotificationService {
  static String? _cachedToken;
  static bool _initialized = false;
  static final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  static FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  static Future<void> init() async {
    if (!_initialized) {
      try {
        // 1. Request permission (Android 13+)
        final settings = await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        debugPrint('FCM permission: ${settings.authorizationStatus}');

        // 2. Create Android notification channel
        await _localNotif
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(_channel);

        // 3. Initialize flutter_local_notifications (for foreground display)
        const initSettings = InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        );
        await _localNotif.initialize(
          initSettings,
          onDidReceiveNotificationResponse: (response) {
            _handleNotificationTap(response.payload);
          },
        );

        // 4. Set foreground presentation options
        await _messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

        // 5. Listen for token refresh
        _messaging.onTokenRefresh.listen(_onTokenRefresh);

        // 6. Foreground messages — show via local notifications
        FirebaseMessaging.onMessage.listen(_onForegroundMessage);

        // 7. Background tap (app was minimized)
        FirebaseMessaging.onMessageOpenedApp.listen((message) {
          _refreshInbox();
          _handleNotificationPayload(message.data);
        });

        // 8. Terminated state tap (app was fully closed)
        final initial = await _messaging.getInitialMessage();
        if (initial != null) {
          Future.delayed(const Duration(seconds: 1), () {
            _refreshInbox();
            _handleNotificationPayload(initial.data);
          });
        }

        _initialized = true;
        debugPrint('[FCM] NotificationService initialized');
      } catch (e, stack) {
        debugPrint('NotificationService.init error: $e\n$stack');
      }
    }

    // Token fetch, DeviceInfo, registerFcmToken HTTP, and topic subscribe are
    // async but were previously awaited here, so [init] did not return until
    // all finished — extending the critical path on the UI isolate and
    // contributing to jank when [main] awaited [init] before [runApp].
    // Login still calls [ensureTokenRegistered] and awaits it when needed.
    unawaited(ensureTokenRegistered());
  }

  // ── Token refresh ─────────────────────────────────────────────────────────
  static void _onTokenRefresh(String token) async {
    debugPrint('[FCM] Token refreshed (len=${token.length})');
    if (!_isValidFcmToken(token)) {
      debugPrint('[FCM] Refreshed token is invalid — ignoring');
      return;
    }
    _cachedToken = token;
    final deviceId = await _getDeviceId();
    registerTokenWithBackend(token, deviceId: deviceId);
  }

  // ── Foreground message — show as local notification ───────────────────────
  static void _onForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Foreground: ${message.notification?.title}');

    final notification = message.notification;

    // Resolve display title/body from notification payload OR data payload
    final displayTitle = notification?.title
        ?? message.data['title']?.toString()
        ?? 'Notification';
    final displayBody = notification?.body
        ?? message.data['body']?.toString()
        ?? '';

    // Show as a proper heads-up notification
    _localNotif.show(
      message.hashCode,
      displayTitle,
      displayBody,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: _buildPayloadString(message.data),
    );

    // Also show a GetX snackbar for in-app awareness
    _showInAppSnackbar(displayTitle, displayBody);

    // Refresh inbox so unread badge updates immediately
    _refreshInbox();
  }

  static void _refreshInbox() {
    try {
      if (Get.isRegistered<InboxNotificationController>()) {
        Get.find<InboxNotificationController>().fetchNotifications();
      }
    } catch (_) {}
  }

  // ── Navigation on notification tap ───────────────────────────────────────
  static void _handleNotificationTap(String? payload) {
    if (payload == null || payload.isEmpty) return;
    // payload is "type|event_id" format
    final parts = payload.split('|');
    final type = parts.isNotEmpty ? parts[0] : '';
    final eventId = parts.length > 1 ? parts[1] : '';
    _navigateFromNotification(type, eventId);
  }

  static void _handleNotificationPayload(Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? '';
    final eventId = data['event_id']?.toString() ?? '';
    _navigateFromNotification(type, eventId);
  }

  static void _navigateFromNotification(String type, String eventId) {
    debugPrint('[FCM] Tap — type: $type, event_id: $eventId');
    if (eventId.isNotEmpty) {
      final eid = int.tryParse(eventId);
      if (eid != null && eid > 0) {
        _openEventDetail(eid);
      }
    }
  }

  static Future<void> _openEventDetail(int eventId) async {
    try {
      final res = await ApiService.getEventById(eventId);
      final data = res.data;
      if (data is Map && data['status'] == 'success' && data['data'] != null) {
        Get.to(
          () => EventDetailView(event: data['data']),
          transition: Transition.rightToLeft,
        );
      }
    } catch (e) {
      debugPrint('[FCM] _openEventDetail error: $e');
    }
  }

  static String _buildPayloadString(Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? '';
    final eventId = data['event_id']?.toString() ?? '';
    return '$type|$eventId';
  }

  // ── FCM token format guard ────────────────────────────────────────────────
  // Real FCM v1 tokens look like "dXXXX:APA91bXXX..." — they contain a colon
  // and are typically 150+ characters.  Short hex strings (32-64 chars) are
  // APNs device tokens or device fingerprints, NOT valid FCM tokens.
  static bool _isValidFcmToken(String token) {
    return token.length >= 100 && token.contains(':');
  }

  // ── Get FCM token ─────────────────────────────────────────────────────────
  static Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    try {
      final token = await _messaging.getToken();
      if (token == null) {
        debugPrint('[FCM] getToken returned null — check notification permission');
        return null;
      }
      if (!_isValidFcmToken(token)) {
        debugPrint(
          '[FCM] getToken returned an invalid token '
          '(len=${token.length}, contains colon=${token.contains(":")}). '
          'This looks like an APNs/device token, not an FCM token. '
          'Ensure Firebase is configured with a valid APNs key.',
        );
        return null;
      }
      _cachedToken = token;
      return _cachedToken;
    } catch (e) {
      debugPrint('[FCM] getToken error: $e');
      return null;
    }
  }

  // ── Register token with your PHP server ──────────────────────────────────
  static Future<void> registerTokenWithBackend(
    String token, {
    String? deviceId,
  }) async {
    if (!_isValidFcmToken(token)) {
      debugPrint(
        '[FCM] Refusing to register invalid token with backend '
        '(len=${token.length}). Only real FCM tokens are accepted.',
      );
      return;
    }
    final userId = await PrefService.getUserId();
    if (userId == null) return;
    try {
      final res = await ApiService.registerFcmToken(
        userId: userId,
        fcmToken: token,
        deviceId: deviceId,
      );
      if (res.data is Map && res.data['status'] == 'success') {
        debugPrint('[FCM] Token registered with backend');
      } else {
        debugPrint('[FCM] Backend rejected token: ${res.data}');
      }
    } catch (e) {
      debugPrint('[FCM] Register token error: $e');
    }
  }

  /// Call on every app launch and after login to ensure the backend always
  /// has the latest FCM token for this device. Safe to call multiple times.
  static Future<void> ensureTokenRegistered() async {
    try {
      final token = await getToken();
      if (token == null) return;
      final deviceId = await _getDeviceId();
      await registerTokenWithBackend(token, deviceId: deviceId);
      await _subscribeTopics();
    } catch (e) {
      debugPrint('[FCM] ensureTokenRegistered error: $e');
    }
  }

  // ── Topic subscriptions ───────────────────────────────────────────────────
  static Future<void> _subscribeTopics() async {
    try {
      await _messaging.subscribeToTopic('all_users');
      final isStudent = await PrefService.getIsStudent();
      if (isStudent) {
        await _messaging.subscribeToTopic('students');
        await _messaging.unsubscribeFromTopic('faculty');
      } else {
        await _messaging.subscribeToTopic('faculty');
        await _messaging.unsubscribeFromTopic('students');
      }
      debugPrint('[FCM] Topics subscribed');
    } catch (e) {
      debugPrint('[FCM] Topic subscribe error: $e');
    }
  }

  // ── Call on logout ────────────────────────────────────────────────────────
  static Future<void> onLogout() async {
    try {
      await _messaging.deleteToken();
      await _messaging.unsubscribeFromTopic('all_users');
      await _messaging.unsubscribeFromTopic('students');
      await _messaging.unsubscribeFromTopic('faculty');
      _cachedToken = null;
      _initialized = false;
      debugPrint('[FCM] Token deleted and topics unsubscribed');
    } catch (e) {
      debugPrint('[FCM] Logout cleanup error: $e');
    }
  }

  // ── Get device ID ─────────────────────────────────────────────────────────
  static Future<String?> _getDeviceId() async {
    try {
      final info = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await info.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await info.iosInfo;
        return iosInfo.identifierForVendor;
      }
      return null;
    } catch (e) {
      debugPrint('[FCM] getDeviceId error: $e');
      return null;
    }
  }

  // ── In-app snackbar (GetX) ────────────────────────────────────────────────
  static void _showInAppSnackbar(String title, String body) {
    try {
      Get.snackbar(
        title,
        body,
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF1F2937),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(12),
      );
    } catch (_) {}
  }
}