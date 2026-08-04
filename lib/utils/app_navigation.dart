import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../widgets/app_loading_screen.dart';

/// Navigate after optional data/asset preparation with a blocking loader.
class AppNavigation {
  AppNavigation._();

  static const Duration _prepareTimeout = Duration(seconds: 30);

  static Future<void> _withLoader(
    BuildContext? ctx,
    String loadingMessage,
    Future<void> Function(BuildContext context) prepare,
  ) async {
    final context = ctx ?? Get.overlayContext ?? Get.context;
    if (context == null) {
      debugPrint('[Nav] _withLoader: no context — running prepare without dialog');
      final fallback = Get.context;
      if (fallback == null) return;
      try {
        await prepare(fallback).timeout(_prepareTimeout);
      } catch (e, st) {
        debugPrint('[Nav] prepare (no dialog) failed: $e\n$st');
      }
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
      debugPrint('[Nav] prepare start: $loadingMessage');
      await prepare(context).timeout(
        _prepareTimeout,
        onTimeout: () {
          debugPrint('[Nav] prepare timed out after ${_prepareTimeout.inSeconds}s: $loadingMessage');
        },
      );
      debugPrint('[Nav] prepare done: $loadingMessage');
    } catch (e, st) {
      debugPrint('[Nav] prepare error: $e\n$st');
    } finally {
      if (context.mounted) {
        final nav = Navigator.of(context, rootNavigator: true);
        if (nav.canPop()) {
          nav.pop();
        }
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
