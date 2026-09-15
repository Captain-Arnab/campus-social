import 'package:flutter/material.dart';

import '../data/app_branding.dart';
import '../theme/app_theme.dart';
import 'content_cropped_logo.dart';

/// Horizontal brand lockup: MiCampus mark — thin divider — university/admin logo.
///
/// Both logos share the same **slot height**. Widths follow each logo's ink
/// aspect after whitespace is cropped (university assets are often tall canvases
/// with a short crest band — equal square + [BoxFit.contain] made them a sliver).
///
/// When the parent offers a finite max width smaller than the natural lockup,
/// [size] is scaled down so the [Row] never overflows.
class AppLogoLockup extends StatelessWidget {
  /// Shared slot height (logical pixels).
  final double size;

  /// Gap between logo and divider.
  final double gap;

  /// Corner radius for each logo clip.
  final double borderRadius;

  /// When true, divider uses light colors for orange/gradient bars.
  final bool onPrimaryBackground;

  const AppLogoLockup({
    super.key,
    this.size = 34,
    this.gap = 10,
    this.borderRadius = 8,
    this.onPrimaryBackground = false,
  });

  /// Compact toolbar / app-bar — height **34**.
  const AppLogoLockup.appBar({
    super.key,
    this.onPrimaryBackground = false,
  })  : size = 34,
        gap = 10,
        borderRadius = 8;

  /// Explore header — height **36**.
  const AppLogoLockup.header({
    super.key,
    this.onPrimaryBackground = false,
  })  : size = 36,
        gap = 12,
        borderRadius = 8;

  /// Auth screens — height **48**.
  const AppLogoLockup.auth({
    super.key,
    this.onPrimaryBackground = true,
  })  : size = 48,
        gap = 12,
        borderRadius = 8;

  double get height => size;

  static double _miCampusWidthFor(double slot) => slot * 1.85;

  static double _uniWidthFor(double slot) =>
      (slot * 2.35).clamp(slot * 1.6, slot * 2.6);

  static double _naturalWidth({
    required double slot,
    required double gap,
    required bool hasAdmin,
  }) {
    final mi = _miCampusWidthFor(slot);
    if (!hasAdmin) return mi;
    return mi + gap + 1 + gap + _uniWidthFor(slot);
  }

  @override
  Widget build(BuildContext context) {
    final dividerColor = onPrimaryBackground
        ? Colors.white.withValues(alpha: 0.35)
        : AppColors.navy.withValues(alpha: 0.18);
    final br = BorderRadius.circular(borderRadius);

    return ValueListenableBuilder<String?>(
      valueListenable: AppBranding.logoUrlNotifier,
      builder: (context, adminUrl, _) {
        final hasAdmin = adminUrl != null && adminUrl.isNotEmpty;

        return LayoutBuilder(
          builder: (context, constraints) {
            var slot = size;
            var g = gap;
            final maxW = constraints.maxWidth;
            if (maxW.isFinite && maxW > 0) {
              final natural = _naturalWidth(
                slot: slot,
                gap: g,
                hasAdmin: hasAdmin,
              );
              if (natural > maxW) {
                // Slight under-scale avoids sub-pixel RenderFlex overflows.
                final scale = (maxW / natural) * 0.98;
                slot = size * scale;
                g = gap * scale;
              }
            }

            return SizedBox(
              height: slot,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ContentCroppedLogo(
                    assetPath: 'assets/images/logo.jpeg',
                    width: _miCampusWidthFor(slot),
                    height: slot,
                    fit: BoxFit.contain,
                    borderRadius: br,
                    placeholder: SizedBox(
                      width: _miCampusWidthFor(slot),
                      height: slot,
                    ),
                    errorWidget: Icon(
                      Icons.event_rounded,
                      color: onPrimaryBackground
                          ? Colors.white
                          : AppColors.accent,
                      size: slot * 0.72,
                    ),
                  ),
                  if (hasAdmin) ...[
                    SizedBox(width: g),
                    Container(
                      width: 1,
                      height: slot * 0.58,
                      color: dividerColor,
                    ),
                    SizedBox(width: g),
                    ContentCroppedLogo(
                      networkUrl: adminUrl,
                      width: _uniWidthFor(slot),
                      height: slot,
                      fit: BoxFit.contain,
                      borderRadius: br,
                      placeholder: SizedBox(
                        width: _uniWidthFor(slot),
                        height: slot,
                      ),
                      errorWidget: const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
