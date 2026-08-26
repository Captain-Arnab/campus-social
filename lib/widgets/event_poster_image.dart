import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/event_image_helper.dart';
import 'app_network_image.dart';

/// Event banner that never crops poster text.
///
/// Fills the slot with a **blurred [BoxFit.cover]** backdrop, then draws the
/// full poster with **[BoxFit.contain]** on top so portrait/landscape/square
/// assets stay fully readable.
class EventPosterImage extends StatelessWidget {
  final dynamic event;
  final int? cacheWidth;
  final double? width;
  final double? height;

  /// When false, falls back to plain [BoxFit.cover] (rare escape hatch).
  final bool preserveFullPoster;

  const EventPosterImage({
    super.key,
    required this.event,
    this.cacheWidth,
    this.width,
    this.height,
    this.preserveFullPoster = true,
  });

  /// Same treatment for a raw banner URL (favorites, detail hero, etc.).
  static Widget fromUrl(
    String? url, {
    Key? key,
    String? category,
    int? cacheWidth,
    double? width,
    double? height,
    bool preserveFullPoster = true,
  }) {
    return _PosterFill(
      key: key,
      url: url,
      category: category,
      cacheWidth: cacheWidth,
      width: width,
      height: height,
      preserveFullPoster: preserveFullPoster,
    );
  }

  String? get _category =>
      event is Map ? (event as Map)['category']?.toString() : null;

  @override
  Widget build(BuildContext context) {
    return _PosterFill(
      url: EventImageHelper.bannerUrl(event),
      category: _category,
      cacheWidth: cacheWidth,
      width: width,
      height: height,
      preserveFullPoster: preserveFullPoster,
    );
  }
}

class _PosterFill extends StatelessWidget {
  final String? url;
  final String? category;
  final int? cacheWidth;
  final double? width;
  final double? height;
  final bool preserveFullPoster;

  const _PosterFill({
    super.key,
    required this.url,
    this.category,
    this.cacheWidth,
    this.width,
    this.height,
    this.preserveFullPoster = true,
  });

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return SizedBox(
        width: width,
        height: height,
        child: _PosterPlaceholder(category: category),
      );
    }

    if (!preserveFullPoster) {
      return AppNetworkImage(
        url: url!,
        fit: BoxFit.cover,
        width: width,
        height: height,
        cacheWidth: cacheWidth,
        filterQuality: FilterQuality.medium,
        placeholder: _PosterPlaceholder(category: category, loading: true),
        errorWidget: (_, __, ___) => _PosterPlaceholder(category: category),
      );
    }

    final placeholder = _PosterPlaceholder(category: category, loading: true);
    final error = _PosterPlaceholder(category: category);

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Soft category wash under blur (visible at letterbox edges briefly).
          ColoredBox(color: AppColors.categoryColor(category).withValues(alpha: 0.18)),
          // Blurred cover backdrop — fills the card without defining readable crop.
          ClipRect(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: Transform.scale(
                scale: 1.12,
                child: AppNetworkImage(
                  url: url!,
                  fit: BoxFit.cover,
                  cacheWidth: cacheWidth,
                  filterQuality: FilterQuality.low,
                  placeholder: placeholder,
                  errorWidget: (_, __, ___) => error,
                ),
              ),
            ),
          ),
          // Slight dim so the sharp contain layer reads clearly.
          ColoredBox(color: Colors.black.withValues(alpha: 0.18)),
          // Full uncropped poster.
          AppNetworkImage(
            url: url!,
            fit: BoxFit.contain,
            alignment: Alignment.center,
            cacheWidth: cacheWidth,
            filterQuality: FilterQuality.medium,
            placeholder: const SizedBox.shrink(),
            errorWidget: (_, __, ___) => error,
          ),
        ],
      ),
    );
  }
}

class _PosterPlaceholder extends StatelessWidget {
  final String? category;
  final bool loading;

  const _PosterPlaceholder({this.category, this.loading = false});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.categoryColor(category);
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.28),
            color.withValues(alpha: 0.14),
            AppColors.surfaceMuted,
          ],
        ),
      ),
      child: loading
          ? Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color.withValues(alpha: 0.7),
                ),
              ),
            )
          : null,
    );
  }
}
