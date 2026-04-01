import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:art_sweetalert_new/art_sweetalert_new.dart';

/// Central SweetAlert helpers so the app uses SweetAlert for all alerts.
/// Use [context] when available (e.g. from a Widget); otherwise pass [Get.context].
class SweetAlertHelper {
  SweetAlertHelper._();

  /// Dismisses [ArtSweetAlert] (showGeneralDialog) without using the caller [BuildContext],
  /// which may already be unmounted after async work or parent rebuilds.
  static void _popAlertRoute() {
    final nav = Get.key.currentState;
    if (nav != null && nav.canPop()) {
      nav.pop();
      return;
    }
    final overlay = Get.overlayContext;
    if (overlay != null && overlay.mounted) {
      final n = Navigator.maybeOf(overlay, rootNavigator: true) ?? Navigator.maybeOf(overlay);
      if (n != null && n.canPop()) {
        n.pop();
      }
    }
  }

  static void _show(
    BuildContext? context,
    String title,
    String message, {
    required ArtAlertType type,
    VoidCallback? onConfirm,
  }) {
    BuildContext? ctx = context;
    if (ctx != null && !ctx.mounted) ctx = null;
    ctx ??= Get.context;
    if (ctx == null || !ctx.mounted) return;
    ArtSweetAlert.show(
      context: ctx,
      title: Text(title),
      content: Text(message),
      type: type,
      actions: [
        ArtAlertButton(
          onPressed: () {
            _popAlertRoute();
            final cb = onConfirm;
            if (cb != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) => cb());
            }
          },
          backgroundColor: const Color(0xFFFF5F15),
          child: const Text('OK'),
        ),
      ],
    );
  }

  /// Show success alert. [onConfirm] runs after user taps OK.
  static void showSuccess(BuildContext? context, String title, String message, {VoidCallback? onConfirm}) {
    _show(context, title, message, type: ArtAlertType.success, onConfirm: onConfirm);
  }

  /// Show error alert.
  static void showError(BuildContext? context, String title, String message, {VoidCallback? onConfirm}) {
    _show(context, title, message, type: ArtAlertType.error, onConfirm: onConfirm);
  }

  /// Show info alert.
  static void showInfo(BuildContext? context, String title, String message, {VoidCallback? onConfirm}) {
    _show(context, title, message, type: ArtAlertType.info, onConfirm: onConfirm);
  }

  /// Show warning alert.
  static void showWarning(BuildContext? context, String title, String message, {VoidCallback? onConfirm}) {
    _show(context, title, message, type: ArtAlertType.warning, onConfirm: onConfirm);
  }
}

