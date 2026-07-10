import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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

  /// Backend logos often include transparent margins; scale up slightly so they
  /// match the bundled MiCampus mark visually.
  static const double adminLogoVisualScale = 1.26;

  static int _logoCachePx(BuildContext context, double logicalSize, {double scale = 1}) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return (logicalSize * dpr * scale).round().clamp(72, 512);
  }

  /// MiCampus + admin for the orange Explore header (equal cell size).
  static Widget exploreHeaderLogos() {
    final w = 88.w;
    final h = 72.h;
    return logoBox(
      width: w,
      height: h,
      fit: BoxFit.contain,
      interLogoGap: 12.w,
      borderRadius: BorderRadius.circular(12),
    );
  }

  /// App bar / profile compact row (default + admin).
  static Widget compactDualLogos({
    double size = 52,
    double gap = 12,
    BorderRadius? borderRadius,
  }) {
    final s = size.w;
    final br = borderRadius ?? BorderRadius.circular(8);
    return logoBox(
      width: s,
      height: s,
      fit: BoxFit.contain,
      interLogoGap: gap.w,
      borderRadius: br,
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
  ///
  /// Defaults to [BoxFit.contain] with [adminLogoVisualScale] so wide marks with
  /// padding in the bitmap still read at a similar size to the default logo.
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
          fit: BoxFit.contain,
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
                      child: LayoutBuilder(
                        builder: (context, constraints) => _adminLogoContent(
                          context,
                          u,
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          fit: fit,
                          visualScale: adminLogoVisualScale,
                        ),
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

  /// Login / signup / forgot — consistent size, white circular plate, contained logos.
  static Widget authScreenMarks() {
    return dualAuthCircleMarks(
      diameter: 96.w,
      insetPadding: 4.w,
      innerLogoSize: 88.w,
      gap: 16,
      adminVisualScale: 1.2,
    );
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
    return Image.network(
      url,
      fit: fit,
      alignment: alignment,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
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
