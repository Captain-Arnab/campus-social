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
  ///
  /// Pass [sessionUserId]/[sessionName] on the post-login path so seeding does not
  /// depend on a SharedPreferences read that could race with a prior user.
  static Future<void> prepareHome(
    BuildContext context, {
    String? sessionUserId,
    String? sessionName,
  }) async {
    // Fresh EventController per session — avoids empty My Activity lists from a
    // pre-login onInit (no user_id) or a previous account's cached RxLists.
    if (Get.isRegistered<EventController>()) {
      await Get.delete<EventController>(force: true);
    }
    ensureEventController();
    // Always a fresh ProfileController — never reuse in-memory data across users.
    if (Get.isRegistered<ProfileController>()) {
      Get.find<ProfileController>().resetProfileState();
      await Get.delete<ProfileController>(force: true);
    }
    final profile = Get.put(ProfileController());
    if (!Get.isRegistered<InboxNotificationController>()) {
      Get.put(InboxNotificationController(), permanent: true);
    }
    // Session name must be visible before first profile-tab paint (post-login race).
    await profile.seedFromSession(userId: sessionUserId, name: sessionName);
    unawaited(AppBranding.refresh());
  }

  /// Safe accessor — never throws if a prior logout deleted the controller.
  static EventController ensureEventController() {
    if (Get.isRegistered<EventController>()) {
      return Get.find<EventController>();
    }
    return Get.put(EventController());
  }

  /// Drop cached home controllers so the next login gets a fresh profile fetch.
  /// Call only AFTER navigating away from Home (Home widgets Get.find EventController).
  static Future<void> clearHomeControllers() async {
    if (Get.isRegistered<ProfileController>()) {
      Get.find<ProfileController>().resetProfileState();
      await Get.delete<ProfileController>(force: true);
    }
    if (Get.isRegistered<EventController>()) {
      await Get.delete<EventController>(force: true);
    }
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
    ensureEventController();
  }

  static Future<void> prepareEditProfile(BuildContext context) async {
    unawaited(AppBranding.refresh());
    if (Get.isRegistered<ProfileController>()) {
      await Get.find<ProfileController>().loadProfile();
    }
  }
}
