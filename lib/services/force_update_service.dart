import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';

import '../base/constant.dart';
import '../theme/app_theme.dart';

/// Forces users onto the latest Play Store build whenever one is available.
///
/// Uses Google Play **immediate** in-app updates — no manual min-version to set.
/// Only works for installs from Play Store (not debug / sideload / emulator).
class ForceUpdateService with WidgetsBindingObserver {
  ForceUpdateService._();
  static final ForceUpdateService instance = ForceUpdateService._();

  bool _checking = false;
  bool _blockingDialogOpen = false;
  bool _observerAttached = false;

  /// Call once after [runApp] so resume also re-checks.
  void startLifecycleWatcher() {
    if (_observerAttached) return;
    WidgetsBinding.instance.addObserver(this);
    _observerAttached = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ensureUpToDate());
    }
  }

  /// Blocks until Play reports no update, or until the OS restarts into a new build.
  Future<void> ensureUpToDate() async {
    if (kIsWeb || !Platform.isAndroid) return;
    if (_checking) return;
    _checking = true;
    try {
      while (true) {
        final info = await InAppUpdate.checkForUpdate();
        final available =
            info.updateAvailability == UpdateAvailability.updateAvailable;
        if (!available) return;

        // Prefer Play's full-screen immediate update (cannot skip casually).
        if (info.immediateUpdateAllowed) {
          final result = await InAppUpdate.performImmediateUpdate();
          if (result == AppUpdateResult.success) {
            // Process usually restarts; if not, loop and re-check.
            continue;
          }
          // User backed out / failed — keep them on a blocking screen.
          await _showBlockingUpdateUi();
          continue;
        }

        // Immediate not allowed for this device/track — still block + open Play.
        await _showBlockingUpdateUi();
      }
    } catch (e, st) {
      // Expected on debug builds, emulators, and non-Play installs.
      debugPrint('ForceUpdateService: $e\n$st');
    } finally {
      _checking = false;
    }
  }

  Future<void> _showBlockingUpdateUi() async {
    if (_blockingDialogOpen) {
      await _openPlayStore();
      await Future<void>.delayed(const Duration(seconds: 2));
      return;
    }

    final ctx = Get.context ?? Get.overlayContext;
    if (ctx == null || !ctx.mounted) {
      await _openPlayStore();
      await Future<void>.delayed(const Duration(seconds: 2));
      return;
    }

    _blockingDialogOpen = true;
    try {
      await showDialog<void>(
        context: ctx,
        barrierDismissible: false,
        builder: (dialogContext) {
          return PopScope(
            canPop: false,
            child: AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text('Update required'),
              content: const Text(
                'A new version of MiCampus is available on the Play Store. '
                'Please update to continue using the app.',
              ),
              actions: [
                FilledButton(
                  onPressed: () async {
                    await _openPlayStore();
                    try {
                      await InAppUpdate.performImmediateUpdate();
                    } catch (_) {}
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Constant.primaryColor,
                  ),
                  child: const Text('Update now'),
                ),
              ],
            ),
          );
        },
      );
    } finally {
      _blockingDialogOpen = false;
    }
  }

  Future<void> _openPlayStore() async {
    final market = Uri.parse('market://details?id=${Constant.androidPackageId}');
    final web = Uri.parse(
      'https://play.google.com/store/apps/details?id=${Constant.androidPackageId}',
    );
    try {
      if (await canLaunchUrl(market)) {
        await launchUrl(market, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}
    await launchUrl(web, mode: LaunchMode.externalApplication);
  }
}
