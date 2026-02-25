import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:art_sweetalert_new/art_sweetalert_new.dart';

/// Central SweetAlert helpers so the app uses SweetAlert for all alerts.
/// Use [context] when available (e.g. from a Widget); otherwise pass [Get.context].
class SweetAlertHelper {
  SweetAlertHelper._();

  static void _show(
    BuildContext? context,
    String title,
    String message, {
    required ArtAlertType type,
    VoidCallback? onConfirm,
  }) {
    final ctx = context ?? Get.context;
    if (ctx == null) return;
    ArtSweetAlert.show(
      context: ctx,
      title: Text(title),
      content: Text(message),
      type: type,
      actions: [
        ArtAlertButton(
          onPressed: () {
            Navigator.pop(ctx);
            onConfirm?.call();
          },
          child: const Text('OK'),
          backgroundColor: const Color(0xFFFF5F15),
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

