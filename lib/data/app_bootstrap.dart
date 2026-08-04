import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/event_controller.dart';
import '../controllers/inbox_notification_controller.dart';
import '../controllers/profile_controller.dart';
import 'app_branding.dart';

/// Lightweight screen prep. Network / FCM / heavy assets must not block first paint.
class AppBootstrap {
  AppBootstrap._();

  /// Branding HTTP is optional chrome — never gate navigation on it.
  static Future<void> refreshBranding(BuildContext context) async {
    unawaited(AppBranding.refresh());
    // Local asset only; skip if context is already gone.
    if (!context.mounted) return;
    try {
      await precacheImage(
        const AssetImage('assets/images/logo.jpeg'),
        context,
      ).timeout(const Duration(milliseconds: 400));
    } catch (_) {}
  }

  static Future<void> prepareOnboarding(BuildContext context) async {
    // Intro PNGs load via Image.asset when each page builds — do not precache all.
    unawaited(AppBranding.refresh());
  }

  static Future<void> prepareLogin(BuildContext context) async {
    await refreshBranding(context);
  }

  /// Register controllers so [onInit] starts fetches in the background.
  /// Do NOT await events / profile / inbox / branding HTTP here — that was the
  /// multi-second "Loading MiCampus..." splash after cold start.
  static Future<void> prepareHome(BuildContext context) async {
    if (!Get.isRegistered<EventController>()) {
      Get.put(EventController());
    }
    if (!Get.isRegistered<ProfileController>()) {
      Get.put(ProfileController());
    }
    if (!Get.isRegistered<InboxNotificationController>()) {
      Get.put(InboxNotificationController(), permanent: true);
    }
    unawaited(AppBranding.refresh());
  }

  static Future<void> prepareWinners(BuildContext context) async {
    unawaited(AppBranding.refresh());
  }

  static Future<void> prepareNotifications(BuildContext context) async {
    unawaited(AppBranding.refresh());
    if (Get.isRegistered<InboxNotificationController>()) {
      await Get.find<InboxNotificationController>().fetchNotifications();
    }
  }

  static Future<void> prepareEventDetail(BuildContext context, dynamic event) async {
    unawaited(AppBranding.refresh());
    final idRaw = event is Map ? event['id'] : null;
    final id = idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '');
    if (id == null || id <= 0) return;
    if (!Get.isRegistered<EventController>()) return;
    await Get.find<EventController>().fetchEventById(id);
  }

  static Future<void> prepareCreateEvent(BuildContext context) async {
    unawaited(AppBranding.refresh());
  }

  static Future<void> prepareEditProfile(BuildContext context) async {
    unawaited(AppBranding.refresh());
    if (Get.isRegistered<ProfileController>()) {
      await Get.find<ProfileController>().loadProfile();
    }
  }
}
