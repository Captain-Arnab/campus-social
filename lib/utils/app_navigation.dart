import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../widgets/app_loading_screen.dart';

/// Navigate after optional data/asset preparation with a blocking loader.
class AppNavigation {
  AppNavigation._();

  static Future<void> _withLoader(
    BuildContext? ctx,
    String loadingMessage,
    Future<void> Function(BuildContext context) prepare,
  ) async {
    final context = ctx ?? Get.context;
    if (context == null) {
      await prepare(Get.context!);
      return;
    }
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => PopScope(
        canPop: false,
        child: AppLoadingScreen(message: loadingMessage),
      ),
    );
    try {
      await prepare(context);
    } finally {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  static Future<T?> to<T>(
    Widget Function() page, {
    Future<void> Function(BuildContext context)? prepare,
    String loadingMessage = 'Loading...',
    Transition transition = Transition.rightToLeft,
  }) async {
    if (prepare != null) {
      await _withLoader(Get.overlayContext ?? Get.context, loadingMessage, prepare);
    }
    return Get.to<T>(page, transition: transition);
  }

  static Future<T?> off<T>(
    Widget Function() page, {
    Future<void> Function(BuildContext context)? prepare,
    String loadingMessage = 'Loading...',
    Transition transition = Transition.fadeIn,
  }) async {
    if (prepare != null) {
      await _withLoader(Get.overlayContext ?? Get.context, loadingMessage, prepare);
    }
    return Get.off<T>(page, transition: transition);
  }

  static Future<T?> offAll<T>(
    Widget Function() page, {
    Future<void> Function(BuildContext context)? prepare,
    String loadingMessage = 'Loading...',
    Transition transition = Transition.fadeIn,
  }) async {
    if (prepare != null) {
      await _withLoader(Get.overlayContext ?? Get.context, loadingMessage, prepare);
    }
    return Get.offAll<T>(page, transition: transition);
  }
}
