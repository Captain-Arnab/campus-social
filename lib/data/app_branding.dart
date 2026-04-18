import 'package:flutter/material.dart';

import '../base/constant.dart';
import 'api_service.dart';

/// Remote app logo from admin `app_settings` (e.g. `android_app_logo`, `app_logo`).
///
/// [logoUrlNotifier] lets every [logoBox] rebuild when [refresh] completes, so
/// onboarding/login are not stuck on the asset fallback until a manual rebuild.
class AppBranding {
  AppBranding._();

  /// Full URL to the logo image, or null to use the bundled asset fallback.
  static final ValueNotifier<String?> logoUrlNotifier = ValueNotifier<String?>(null);

  static String? get networkLogoUrl => logoUrlNotifier.value;

  static Future<void> refresh() async {
    try {
      // Dio already decodes JSON asynchronously from the socket; the settings
      // map is tiny, so moving map iteration to [compute] would cost an isolate
      // hop without measurable benefit (unlike very large list payloads).
      final r = await ApiService.getAppSettings();
      final m = ApiService.responseDataMap(r.data);
      if (m == null || m['status']?.toString() != 'success') return;
      final raw = m['data'];
      if (raw is! Map) return;
      final map = Map<String, dynamic>.from(raw.map((k, v) => MapEntry(k.toString(), v)));
      String? path;
      for (final e in map.entries) {
        final k = e.key.toString().toLowerCase();
        if (k.contains('logo') || k == 'android_app_icon' || k == 'app_icon') {
          final v = e.value?.toString().trim();
          if (v != null && v.isNotEmpty) {
            path = v;
            break;
          }
        }
      }
      if (path == null || path.isEmpty) return;
      final url = Constant.uploadPublicUrl(path);
      if (url.isNotEmpty && logoUrlNotifier.value != url) {
        logoUrlNotifier.value = url;
      }
    } catch (_) {}
  }

  static Widget logoBox({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    BorderRadius? borderRadius,
  }) {
    final br = borderRadius ?? BorderRadius.circular(12);
    return ValueListenableBuilder<String?>(
      valueListenable: logoUrlNotifier,
      builder: (context, u, _) {
        Widget child;
        if (u != null && u.isNotEmpty) {
          child = Image.network(
            u,
            fit: fit,
            errorBuilder: (_, __, ___) => _assetLogo(fit: fit),
          );
        } else {
          child = _assetLogo(fit: fit);
        }
        return ClipRRect(
          borderRadius: br,
          child: SizedBox(width: width, height: height, child: child),
        );
      },
    );
  }

  static Widget _assetLogo({required BoxFit fit}) {
    return Image.asset(
      'assets/images/logo.jpeg',
      fit: fit,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.event, color: Constant.primaryColor, size: 28),
    );
  }
}
