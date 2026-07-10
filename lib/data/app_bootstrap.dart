import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/event_controller.dart';
import '../controllers/inbox_notification_controller.dart';
import '../controllers/profile_controller.dart';
import 'app_branding.dart';

/// Preloads branding, assets, and first-screen API data before showing UI.
class AppBootstrap {
  AppBootstrap._();

  static Future<void> refreshBranding(BuildContext context) async {
    await Future.wait([
      AppBranding.refresh(),
      precacheImage(const AssetImage('assets/images/logo.jpeg'), context),
    ]);
  }

  static Future<void> _precacheOptionalAsset(BuildContext context, String path) async {
    try {
      await precacheImage(AssetImage(path), context);
    } catch (_) {}
  }

  static Future<void> prepareOnboarding(BuildContext context) async {
    await Future.wait([
      refreshBranding(context),
      _precacheOptionalAsset(context, 'assets/images/intro1.png'),
      _precacheOptionalAsset(context, 'assets/images/intro2.png'),
      _precacheOptionalAsset(context, 'assets/images/intro3.png'),
    ]);
  }

  static Future<void> prepareLogin(BuildContext context) async {
    await refreshBranding(context);
  }

  static Future<void> prepareHome(BuildContext context) async {
    final eventController = Get.isRegistered<EventController>()
        ? Get.find<EventController>()
        : Get.put(EventController());
    if (!Get.isRegistered<ProfileController>()) {
      Get.put(ProfileController());
    }
    if (!Get.isRegistered<InboxNotificationController>()) {
      Get.put(InboxNotificationController(), permanent: true);
    }

    await Future.wait([
      refreshBranding(context),
      if (eventController.liveEventCatalog.isEmpty) eventController.fetchLiveEventCatalog(),
    ]);
  }

  static Future<void> prepareWinners(BuildContext context) async {
    await refreshBranding(context);
  }

  static Future<void> prepareNotifications(BuildContext context) async {
    await refreshBranding(context);
    if (Get.isRegistered<InboxNotificationController>()) {
      await Get.find<InboxNotificationController>().fetchNotifications();
    }
  }

  static Future<void> prepareEventDetail(BuildContext context, dynamic event) async {
    await refreshBranding(context);
    final idRaw = event is Map ? event['id'] : null;
    final id = idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '');
    if (id == null || id <= 0) return;
    if (!Get.isRegistered<EventController>()) return;
    await Get.find<EventController>().fetchEventById(id);
  }

  static Future<void> prepareCreateEvent(BuildContext context) async {
    await refreshBranding(context);
  }

  static Future<void> prepareEditProfile(BuildContext context) async {
    await refreshBranding(context);
    if (Get.isRegistered<ProfileController>()) {
      await Get.find<ProfileController>().loadProfile();
    }
  }
}
