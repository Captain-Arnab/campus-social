import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Cached, downsampled network image — replaces raw [Image.network] for Play
/// Console bitmap optimization and lower memory use on scroll-heavy screens.
class AppNetworkImage extends StatelessWidget {
  final String url;
  final BoxFit? fit;
  final Alignment alignment;
  final double? width;
  final double? height;
  final int? cacheWidth;
  final int? cacheHeight;
  final FilterQuality filterQuality;
  final Widget? placeholder;
  final LoadingErrorWidgetBuilder? errorWidget;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit,
    this.alignment = Alignment.center,
    this.width,
    this.height,
    this.cacheWidth,
    this.cacheHeight,
    this.filterQuality = FilterQuality.medium,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      alignment: alignment,
      width: width,
      height: height,
      memCacheWidth: cacheWidth,
      memCacheHeight: cacheHeight,
      filterQuality: filterQuality,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholder: placeholder != null ? (_, __) => placeholder! : null,
      errorWidget: errorWidget,
    );
  }
}

ImageProvider<Object> appNetworkImageProvider(String url) =>
    CachedNetworkImageProvider(url);
