import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../data/api_service.dart';
import '../data/pref_service.dart';

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
          _handleNotificationPayload(message.data);
        });

        // 8. Terminated state tap (app was fully closed)
        final initial = await _messaging.getInitialMessage();
        if (initial != null) {
          Future.delayed(const Duration(seconds: 1), () {
            _handleNotificationPayload(initial.data);
          });
        }

        _initialized = true;
        debugPrint('[FCM] NotificationService initialized');
      } catch (e, stack) {
        debugPrint('NotificationService.init error: $e\n$stack');
      }
    }

    // Always register FCM token + topics on every launch (outside _initialized guard)
    await ensureTokenRegistered();
  }

  // ── Token refresh ─────────────────────────────────────────────────────────
  static void _onTokenRefresh(String token) async {
    _cachedToken = token;
    debugPrint('[FCM] Token refreshed');
    final deviceId = await _getDeviceId();
    registerTokenWithBackend(token, deviceId: deviceId);
  }

  // ── Foreground message — show as local notification ───────────────────────
  static void _onForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Foreground: ${message.notification?.title}');

    final notification = message.notification;
    if (notification == null) return;

    // Show as a proper heads-up notification (not just a snackbar)
    _localNotif.show(
      message.hashCode,
      notification.title,
      notification.body,
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
      // Payload carries data so tap handler knows where to navigate
      payload: _buildPayloadString(message.data),
    );

    // Also show a GetX snackbar for in-app awareness
    _showInAppSnackbar(
      notification.title ?? 'Notification',
      notification.body ?? '',
    );
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
    // Add your navigation logic here as you build screens:
    // Example:
    // if (type == 'organizer_message' && eventId.isNotEmpty) {
    //   Get.toNamed('/event_detail', arguments: eventId);
    // }
  }

  static String _buildPayloadString(Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? '';
    final eventId = data['event_id']?.toString() ?? '';
    return '$type|$eventId';
  }

  // ── Get FCM token ─────────────────────────────────────────────────────────
  static Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    try {
      _cachedToken = await _messaging.getToken();
      if (_cachedToken == null) {
        debugPrint('[FCM] getToken returned null — check notification permission');
      }
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
      final androidInfo = await info.androidInfo;
      return androidInfo.id; // unique Android device ID
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