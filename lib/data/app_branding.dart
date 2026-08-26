import 'package:flutter/material.dart';

import '../base/constant.dart';
import '../widgets/app_logo_lockup.dart';
import '../widgets/app_network_image.dart';
import 'api_service.dart';

/// Default app mark (`assets/images/logo.jpeg`) plus optional admin URL from
/// `app_settings` (e.g. `android_app_logo`, `app_logo`).
///
/// [logoUrlNotifier] lets every listener rebuild when [refresh] completes.
class AppBranding {
  AppBranding._();

  /// Full URL to the admin logo image, or null when unset / unavailable.
  static final ValueNotifier<String?> logoUrlNotifier = ValueNotifier<String?>(null);

  static String? get networkLogoUrl => logoUrlNotifier.value;

  static Future<void> refresh() async {
    try {
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
      if (path == null || path.isEmpty) {
        if (logoUrlNotifier.value != null) logoUrlNotifier.value = null;
        return;
      }
      final url = Constant.uploadPublicUrl(path);
      if (url.isNotEmpty && logoUrlNotifier.value != url) {
        logoUrlNotifier.value = url;
      }
    } catch (_) {}
  }

  /// Backend logos often include transparent margins; scale up slightly so they
  /// match the bundled MiCampus mark visually.
  static const double adminLogoVisualScale = 1.26;

  static int _logoCachePx(BuildContext context, double logicalSize, {double scale = 1}) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return (logicalSize * dpr * scale).round().clamp(72, 512);
  }

  /// Explore / home header lockup (shared [AppLogoLockup]).
  static Widget exploreHeaderLogos({bool onPrimaryBackground = false}) {
    return AppLogoLockup.header(onPrimaryBackground: onPrimaryBackground);
  }

  /// App bar / profile compact lockup (shared [AppLogoLockup]).
  static Widget compactDualLogos({
    double size = 34,
    double gap = 10,
    BorderRadius? borderRadius,
    bool onPrimaryBackground = false,
  }) {
    // [size] kept for API compatibility; height is the visual constraint.
    final h = size.clamp(28.0, 40.0);
    return AppLogoLockup(
      size: h,
      gap: gap,
      borderRadius: borderRadius?.topLeft.x ?? 8,
      onPrimaryBackground: onPrimaryBackground,
    );
  }

  /// Bundled MiCampus mark only (no network).
  static Widget defaultLogoBox({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    BorderRadius? borderRadius,
  }) {
    final br = borderRadius ?? BorderRadius.circular(12);
    return ClipRRect(
      borderRadius: br,
      child: SizedBox(
        width: width,
        height: height,
        child: _assetLogo(fit: fit),
      ),
    );
  }

  /// Admin mark when [logoUrlNotifier] has a URL; otherwise nothing.
  static Widget adminLogoSlot({
    required double width,
    required double height,
    double leadingGap = 10,
    BoxFit fit = BoxFit.contain,
    Alignment alignment = Alignment.center,
    BorderRadius? borderRadius,
    EdgeInsets imagePadding = EdgeInsets.zero,
    double visualScale = adminLogoVisualScale,
  }) {
    final br = borderRadius ?? BorderRadius.circular(12);
    return ValueListenableBuilder<String?>(
      valueListenable: logoUrlNotifier,
      builder: (context, u, _) {
        if (u == null || u.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: EdgeInsets.only(left: leadingGap),
          child: ClipRRect(
            borderRadius: br,
            child: SizedBox(
              width: width,
              height: height,
              child: _adminLogoContent(
                context,
                u,
                width: width,
                height: height,
                fit: fit,
                alignment: alignment,
                padding: imagePadding,
                visualScale: visualScale,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Toolbar / actions variant of [adminLogoSlot].
  static Widget adminLogoChipSlot({
    required double width,
    required double height,
    double leadingGap = 10,
    BoxFit fit = BoxFit.cover,
    Alignment alignment = Alignment.center,
    BorderRadius? borderRadius,
    EdgeInsets imagePadding = EdgeInsets.zero,
  }) {
    return adminLogoSlot(
      width: width,
      height: height,
      leadingGap: leadingGap,
      fit: fit,
      alignment: alignment,
      borderRadius: borderRadius,
      imagePadding: imagePadding,
    );
  }

  /// Default + optional admin via shared [AppLogoLockup].
  static Widget logoBox({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    BorderRadius? borderRadius,
    double interLogoGap = 10,
    EdgeInsets defaultImagePadding = EdgeInsets.zero,
    EdgeInsets adminImagePadding = EdgeInsets.zero,
  }) {
    final h = height ?? width ?? 34;
    return AppLogoLockup(
      size: h,
      gap: interLogoGap,
      borderRadius: borderRadius?.topLeft.x ?? 8,
    );
  }

  /// Fits inside [outerWidth]×[outerHeight] using [AppLogoLockup].
  static Widget boundedDualLogos({
    required double outerWidth,
    required double outerHeight,
    double gap = 10,
    double horizontalInset = 5,
    double verticalInset = 4,
    BoxFit fit = BoxFit.contain,
    BorderRadius? borderRadius,
  }) {
    return SizedBox(
      width: outerWidth,
      height: outerHeight,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalInset, vertical: verticalInset),
        child: Center(
          child: AppLogoLockup(
            size: (outerHeight - verticalInset * 2).clamp(24.0, 48.0),
            gap: gap,
            borderRadius: borderRadius?.topLeft.x ?? 8,
          ),
        ),
      ),
    );
  }

  /// Login / signup / forgot — compact horizontal lockup (not dual circles).
  static Widget authScreenMarks() {
    return const AppLogoLockup.auth();
  }

  /// Login / signup / forgot: default + optional admin on white circles over the gradient.
  static Widget dualAuthCircleMarks({
    required double diameter,
    required double insetPadding,
    required double innerLogoSize,
    double gap = 24,
    double adminVisualScale = adminLogoVisualScale,
  }) {
    return ValueListenableBuilder<String?>(
      valueListenable: logoUrlNotifier,
      builder: (context, u, _) {
        final hasAdmin = u != null && u.isNotEmpty;
        final dpr = MediaQuery.devicePixelRatioOf(context);
        return LayoutBuilder(
          builder: (context, constraints) {
            var d = diameter;
            var g = gap;
            if (hasAdmin && constraints.maxWidth.isFinite && constraints.maxWidth > 0) {
              final need = d * 2 + g;
              final cap = constraints.maxWidth * 0.9;
              if (need > cap) {
                final scale = cap / need;
                d = diameter * scale;
                g = gap * scale;
              }
            }
            final padScale = (d / diameter).clamp(0.75, 1.0).toDouble();
            final pad = insetPadding * padScale;
            final inner = innerLogoSize * padScale;
            final cachePx = (d * dpr).round().clamp(96, 320);

            Widget circle(Widget child) {
              return Container(
                width: d,
                height: d,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Padding(
                    padding: EdgeInsets.all(pad),
                    child: Center(child: child),
                  ),
                ),
              );
            }

            return Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                circle(
                  SizedBox(
                    width: inner,
                    height: inner,
                    child: _assetLogo(
                      fit: BoxFit.contain,
                      cacheWidth: cachePx,
                    ),
                  ),
                ),
                if (hasAdmin) ...[
                  SizedBox(width: g),
                  circle(
                    _adminLogoContent(
                      context,
                      u,
                      width: inner,
                      height: inner,
                      fit: BoxFit.contain,
                      visualScale: adminVisualScale,
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  static Widget _adminLogoContent(
    BuildContext context,
    String url, {
    required double width,
    required double height,
    BoxFit fit = BoxFit.contain,
    Alignment alignment = Alignment.center,
    EdgeInsets padding = EdgeInsets.zero,
    double visualScale = adminLogoVisualScale,
  }) {
    final cachePx = _logoCachePx(context, width > height ? width : height, scale: visualScale);
    return Padding(
      padding: padding,
      child: SizedBox(
        width: width,
        height: height,
        child: Center(
          child: Transform.scale(
            scale: visualScale,
            child: SizedBox(
              width: width,
              height: height,
              child: _networkLogoImage(
                url,
                fit: fit,
                alignment: alignment,
                cacheWidth: cachePx,
                cacheHeight: cachePx,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _networkLogoImage(
    String url, {
    BoxFit fit = BoxFit.contain,
    Alignment alignment = Alignment.center,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    return AppNetworkImage(
      url: url,
      fit: fit,
      alignment: alignment,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      filterQuality: FilterQuality.medium,
      errorWidget: (_, __, ___) => const SizedBox.shrink(),
    );
  }

  static Widget _assetLogo({required BoxFit fit, int? cacheWidth}) {
    return Image.asset(
      'assets/images/logo.jpeg',
      fit: fit,
      cacheWidth: cacheWidth,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.event, color: Constant.primaryColor, size: 28),
    );
  }
}
