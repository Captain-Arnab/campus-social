import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../data/api_service.dart';
import '../data/pref_service.dart';
import '../modal/model_inbox_notification.dart';

class InboxNotificationController extends GetxController with WidgetsBindingObserver {
  var isLoading = false.obs;
  var notifications = <ModelInboxNotification>[].obs;
  var unreadCount = 0.obs;
  var hoursWindow = 24;

  Timer? _pollTimer;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    fetchNotifications();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => fetchNotifications());
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      fetchNotifications();
    }
  }

  Future<void> fetchNotifications() async {
    final userId = await PrefService.getUserId();
    if (userId == null) return;

    try {
      if (notifications.isEmpty) isLoading.value = true;
      final res = await ApiService.getInboxNotifications(
        userId: userId,
        hours: hoursWindow,
      );
      final data = res.data;
      if (data is Map && data['status'] == 'success') {
        final list = (data['data'] as List?) ?? [];
        notifications.value = list
            .map((e) => ModelInboxNotification.fromJson(
                e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e)))
            .toList();
        unreadCount.value = data['unread_count'] is int
            ? data['unread_count']
            : int.tryParse(data['unread_count']?.toString() ?? '0') ?? 0;
      }
    } catch (e) {
      debugPrint('[Inbox] fetch error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markAsRead(List<int> ids) async {
    final userId = await PrefService.getUserId();
    if (userId == null || ids.isEmpty) return;

    for (final n in notifications) {
      if (ids.contains(n.id)) n.isRead = true;
    }
    notifications.refresh();
    unreadCount.value = notifications.where((n) => !n.isRead).length;

    try {
      await ApiService.markNotificationsRead(userId: userId, notificationIds: ids);
    } catch (e) {
      debugPrint('[Inbox] markAsRead error: $e');
    }
  }

  Future<void> markAllAsRead() async {
    final userId = await PrefService.getUserId();
    if (userId == null) return;

    for (final n in notifications) {
      n.isRead = true;
    }
    notifications.refresh();
    unreadCount.value = 0;

    try {
      await ApiService.markAllNotificationsRead(userId: userId, hours: hoursWindow);
    } catch (e) {
      debugPrint('[Inbox] markAllAsRead error: $e');
    }
  }
}
