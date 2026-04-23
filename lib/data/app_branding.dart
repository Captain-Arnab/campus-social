import 'package:flutter/material.dart';

import '../base/constant.dart';
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
  ///
  /// Defaults to [BoxFit.cover] so varied aspect ratios fill the cell; use
  /// [BoxFit.contain] if you must show the full bitmap without cropping.
  static Widget adminLogoSlot({
    required double width,
    required double height,
    double leadingGap = 10,
    BoxFit fit = BoxFit.cover,
    Alignment alignment = Alignment.center,
    BorderRadius? borderRadius,
    EdgeInsets imagePadding = EdgeInsets.zero,
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
              child: Padding(
                padding: imagePadding,
                child: Image.network(
                  u,
                  fit: fit,
                  alignment: alignment,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Toolbar / actions variant of [adminLogoSlot] (no filled chip — mark sits on the bar background).
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

  /// Default + optional admin side by side, each [width]×[height] (plus [interLogoGap] when admin is set).
  static Widget logoBox({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    BorderRadius? borderRadius,
    double interLogoGap = 12,
    EdgeInsets defaultImagePadding = EdgeInsets.zero,
    EdgeInsets adminImagePadding = EdgeInsets.zero,
  }) {
    final w = width;
    final h = height;
    if (w == null || h == null) {
      return defaultLogoBox(width: w, height: h, fit: fit, borderRadius: borderRadius);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          child: SizedBox(
            width: w,
            height: h,
            child: Padding(
              padding: defaultImagePadding,
              child: _assetLogo(fit: fit),
            ),
          ),
        ),
        adminLogoSlot(
          width: w,
          height: h,
          leadingGap: interLogoGap,
          fit: BoxFit.cover,
          borderRadius: borderRadius,
          imagePadding: adminImagePadding,
        ),
      ],
    );
  }

  /// Fits inside [outerWidth]×[outerHeight]: full default when no admin URL; split row when admin exists.
  ///
  /// Uses [Expanded] so the row never overflows; [BoxFit.contain] avoids cropping wide marks
  /// (cover previously made two "halves" look like overlapping duplicate text).
  static Widget boundedDualLogos({
    required double outerWidth,
    required double outerHeight,
    double gap = 10,
    double horizontalInset = 5,
    double verticalInset = 4,
    BoxFit fit = BoxFit.contain,
    BorderRadius? borderRadius,
  }) {
    final br = borderRadius ?? BorderRadius.circular(12);
    return ValueListenableBuilder<String?>(
      valueListenable: logoUrlNotifier,
      builder: (context, u, _) {
        final hasAdmin = u != null && u.isNotEmpty;
        if (!hasAdmin) {
          return ClipRRect(
            borderRadius: br,
            child: SizedBox(
              width: outerWidth,
              height: outerHeight,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalInset, vertical: verticalInset),
                child: Center(child: _assetLogo(fit: fit)),
              ),
            ),
          );
        }
        return SizedBox(
          width: outerWidth,
          height: outerHeight,
          child: ClipRRect(
            borderRadius: br,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalInset, vertical: verticalInset),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Center(child: _assetLogo(fit: fit)),
                    ),
                  ),
                  SizedBox(width: gap),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        u,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Login / signup / forgot: default + optional admin, clipped to circles on the gradient (no white plate).
  static Widget dualAuthCircleMarks({
    required double diameter,
    required double insetPadding,
    required double innerLogoSize,
    double gap = 24,
  }) {
    return ValueListenableBuilder<String?>(
      valueListenable: logoUrlNotifier,
      builder: (context, u, _) {
        final hasAdmin = u != null && u.isNotEmpty;
        return LayoutBuilder(
          builder: (context, constraints) {
            var d = diameter;
            var g = gap;
            if (hasAdmin && constraints.maxWidth.isFinite && constraints.maxWidth > 0) {
              final need = d * 2 + g;
              final cap = constraints.maxWidth * 0.92;
              if (need > cap) {
                final scale = cap / need;
                d = diameter * scale;
                g = gap * scale;
              }
            }
            final padScale = (d / diameter).clamp(0.75, 1.0).toDouble();
            final pad = insetPadding * padScale;
            final inner = innerLogoSize * padScale;

            Widget circle(Widget child) {
              return SizedBox(
                width: d,
                height: d,
                child: ClipOval(
                  child: Padding(
                    padding: EdgeInsets.all(pad),
                    child: child,
                  ),
                ),
              );
            }

            return Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                circle(
                  defaultLogoBox(
                    width: inner,
                    height: inner,
                    fit: BoxFit.contain,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                if (hasAdmin) ...[
                  SizedBox(width: g),
                  circle(
                    SizedBox.expand(
                      child: Image.network(
                        u,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
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

  static Widget _assetLogo({required BoxFit fit}) {
    return Image.asset(
      'assets/images/logo.jpeg',
      fit: fit,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.event, color: Constant.primaryColor, size: 28),
    );
  }
}
