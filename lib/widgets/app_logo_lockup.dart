import 'package:flutter/material.dart';

import '../data/app_branding.dart';
import '../theme/app_theme.dart';
import 'content_cropped_logo.dart';

/// Horizontal brand lockup: MiCampus mark — thin divider — university/admin logo.
///
/// Both logos share the same **slot height**. Widths follow each logo's ink
/// aspect after whitespace is cropped (university assets are often tall canvases
/// with a short crest band — equal square + [BoxFit.contain] made them a sliver).
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

  /// MiCampus asset is ~1.9:1 landscape with high ink fill → wider than tall.
  double get _miCampusWidth => size * 1.85;

  /// After cropping, uni crest is ~3.2:1; cap width so app bars stay compact.
  double get _uniWidth => (size * 2.35).clamp(size * 1.6, size * 2.6);

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

        return SizedBox(
          height: size,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ContentCroppedLogo(
                assetPath: 'assets/images/logo.jpeg',
                width: _miCampusWidth,
                height: size,
                fit: BoxFit.contain,
                borderRadius: br,
                placeholder: SizedBox(width: _miCampusWidth, height: size),
                errorWidget: Icon(
                  Icons.event_rounded,
                  color: onPrimaryBackground ? Colors.white : AppColors.accent,
                  size: size * 0.72,
                ),
              ),
              if (hasAdmin) ...[
                SizedBox(width: gap),
                Container(
                  width: 1,
                  height: size * 0.58,
                  color: dividerColor,
                ),
                SizedBox(width: gap),
                ContentCroppedLogo(
                  networkUrl: adminUrl,
                  width: _uniWidth,
                  height: size,
                  fit: BoxFit.contain,
                  borderRadius: br,
                  placeholder: SizedBox(width: _uniWidth, height: size),
                  errorWidget: const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
