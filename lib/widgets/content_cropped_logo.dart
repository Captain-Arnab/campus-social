import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

/// Finds the ink bounding box of a logo (non-transparent, non-near-white pixels)
/// and caches the result so wide/tall padded assets don't shrink to a sliver.
class LogoContentBounds {
  LogoContentBounds._();

  /// Relative crop rect in 0..1 of the source image (left, top, right, bottom).
  static final Map<String, Rect> _cache = {};

  /// Probe pixel size of the last resolved source (for diagnostics).
  static final Map<String, Size> _sourceSize = {};

  /// Cached raw bytes so we don't download twice (bounds + decode).
  static final Map<String, Uint8List> _bytesCache = {};

  static Size? sourceSize(String key) => _sourceSize[key];

  static Rect? cached(String key) => _cache[key];

  /// Best-effort native pixel size from PNG/JPEG headers (no full decode).
  static Size? peekNativeSize(Uint8List bytes) {
    if (bytes.length >= 24 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      final w = (bytes[16] << 24) | (bytes[17] << 16) | (bytes[18] << 8) | bytes[19];
      final h = (bytes[20] << 24) | (bytes[21] << 16) | (bytes[22] << 8) | bytes[23];
      return Size(w.toDouble(), h.toDouble());
    }
    // JPEG: scan for SOF0/SOF2
    if (bytes.length > 4 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
      var i = 2;
      while (i + 9 < bytes.length) {
        if (bytes[i] != 0xFF) {
          i++;
          continue;
        }
        final marker = bytes[i + 1];
        if (marker == 0xC0 || marker == 0xC2) {
          final h = (bytes[i + 5] << 8) | bytes[i + 6];
          final w = (bytes[i + 7] << 8) | bytes[i + 8];
          return Size(w.toDouble(), h.toDouble());
        }
        if (marker == 0xD9 || marker == 0xDA) break;
        final len = (bytes[i + 2] << 8) | bytes[i + 3];
        i += 2 + len;
      }
    }
    return null;
  }

  static Future<Uint8List> bytesFor(String key) async {
    final hit = _bytesCache[key];
    if (hit != null) return hit;
    if (key.startsWith('http://') || key.startsWith('https://')) {
      final resp = await http.get(Uri.parse(key));
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw StateError('HTTP ${resp.statusCode} for $key');
      }
      return _bytesCache[key] = resp.bodyBytes;
    }
    final data = await rootBundle.load(key);
    return _bytesCache[key] = data.buffer.asUint8List();
  }

  /// Loads image bytes, measures dimensions + content bounds, caches relative [Rect].
  static Future<Rect> resolve(String key) async {
    final hit = _cache[key];
    if (hit != null) return hit;
    final bytes = await bytesFor(key);
    return _resolveBytes(key, bytes);
  }

  static Future<Rect> resolveNetwork(String url) => resolve(url);

  static Future<Rect> resolveAsset(String assetPath) => resolve(assetPath);

  static Future<Rect> _resolveBytes(String key, Uint8List bytes) async {
    final native = peekNativeSize(bytes);
    if (native != null) {
      debugPrint(
        '[LogoContentBounds] $key NATIVE ${native.width.toInt()}x${native.height.toInt()} '
        'aspect=${(native.width / native.height).toStringAsFixed(3)}',
      );
    }

    // Downsample for fast bounds scan (full 4830×6250 is too heavy on UI isolate).
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: 480,
    );
    final frame = await codec.getNextFrame();
    final img = frame.image;
    final w = img.width;
    final h = img.height;
    _sourceSize[key] = Size(w.toDouble(), h.toDouble());

    final bd = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    img.dispose();
    if (bd == null) {
      return _cache[key] = const Rect.fromLTRB(0, 0, 1, 1);
    }

    final pixels = bd.buffer.asUint8List();
    var minX = w;
    var minY = h;
    var maxX = -1;
    var maxY = -1;
    // Sample every 2nd pixel — enough for logo whitespace detection.
    for (var y = 0; y < h; y += 2) {
      for (var x = 0; x < w; x += 2) {
        final i = (y * w + x) * 4;
        final a = pixels[i + 3];
        final r = pixels[i];
        final g = pixels[i + 1];
        final b = pixels[i + 2];
        final nearWhite = r > 245 && g > 245 && b > 245;
        if (a > 20 && !nearWhite) {
          if (x < minX) minX = x;
          if (y < minY) minY = y;
          if (x > maxX) maxX = x;
          if (y > maxY) maxY = y;
        }
      }
    }

    if (maxX < 0) {
      debugPrint(
        '[LogoContentBounds] $key → empty content, using full frame ${w}x$h',
      );
      return _cache[key] = const Rect.fromLTRB(0, 0, 1, 1);
    }

    // Small padding so edges aren't clipped hard.
    const pad = 0.02;
    final left = (minX / w - pad).clamp(0.0, 1.0);
    final top = (minY / h - pad).clamp(0.0, 1.0);
    final right = ((maxX + 1) / w + pad).clamp(0.0, 1.0);
    final bottom = ((maxY + 1) / h + pad).clamp(0.0, 1.0);
    final rect = Rect.fromLTRB(left, top, right, bottom);

    final fillW = ((right - left) * 100).toStringAsFixed(1);
    final fillH = ((bottom - top) * 100).toStringAsFixed(1);
    debugPrint(
      '[LogoContentBounds] $key source≈${w}x$h '
      'contentRel=${rect.left.toStringAsFixed(3)},${rect.top.toStringAsFixed(3)}'
      '-${rect.right.toStringAsFixed(3)},${rect.bottom.toStringAsFixed(3)} '
      'fill≈$fillW%x$fillH%',
    );

    return _cache[key] = rect;
  }
}

/// Network (or asset) logo that crops away transparent/white padding, then
/// [BoxFit.contain]s the ink into [width]×[height].
class ContentCroppedLogo extends StatefulWidget {
  final String? networkUrl;
  final String? assetPath;
  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final FilterQuality filterQuality;
  final Widget? placeholder;
  final Widget? errorWidget;

  const ContentCroppedLogo({
    super.key,
    this.networkUrl,
    this.assetPath,
    required this.width,
    required this.height,
    this.fit = BoxFit.contain,
    this.borderRadius,
    this.filterQuality = FilterQuality.medium,
    this.placeholder,
    this.errorWidget,
  }) : assert(networkUrl != null || assetPath != null);

  @override
  State<ContentCroppedLogo> createState() => _ContentCroppedLogoState();
}

class _ContentCroppedLogoState extends State<ContentCroppedLogo> {
  ui.Image? _image;
  Rect _crop = const Rect.fromLTRB(0, 0, 1, 1);
  bool _failed = false;
  Object? _loadToken;

  String get _key => widget.networkUrl ?? widget.assetPath!;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant ContentCroppedLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.networkUrl != widget.networkUrl ||
        oldWidget.assetPath != widget.assetPath) {
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final token = Object();
    _loadToken = token;
    setState(() {
      _failed = false;
      _image?.dispose();
      _image = null;
    });

    try {
      final key = _key;
      final bytes = await LogoContentBounds.bytesFor(key);
      _crop = await LogoContentBounds.resolve(key);
      if (!mounted || _loadToken != token) return;

      final target = (widget.width * MediaQuery.devicePixelRatioOf(context) * 2)
          .round()
          .clamp(128, 512);
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: target);
      final frame = await codec.getNextFrame();
      if (!mounted || _loadToken != token) {
        frame.image.dispose();
        return;
      }

      final size = LogoContentBounds.sourceSize(key);
      debugPrint(
        '[ContentCroppedLogo] key=$key '
        'probeSize=${size?.width.toInt()}x${size?.height.toInt()} '
        'decoded=${frame.image.width}x${frame.image.height} '
        'slot=${widget.width.toStringAsFixed(0)}x${widget.height.toStringAsFixed(0)} '
        'crop=$_crop',
      );

      setState(() {
        _image?.dispose();
        _image = frame.image;
      });
    } catch (e, st) {
      debugPrint('[ContentCroppedLogo] failed: $e\n$st');
      if (mounted && _loadToken == token) {
        setState(() => _failed = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = _failed
        ? (widget.errorWidget ?? const SizedBox.shrink())
        : _image == null
            ? (widget.placeholder ??
                SizedBox(
                  width: widget.width,
                  height: widget.height,
                  child: const Center(
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ))
            : CustomPaint(
                size: Size(widget.width, widget.height),
                painter: _CroppedLogoPainter(
                  image: _image!,
                  crop: _crop,
                  fit: widget.fit,
                  filterQuality: widget.filterQuality,
                ),
              );

    final clipped = widget.borderRadius != null
        ? ClipRRect(borderRadius: widget.borderRadius!, child: child)
        : child;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: clipped,
    );
  }
}

class _CroppedLogoPainter extends CustomPainter {
  final ui.Image image;
  final Rect crop;
  final BoxFit fit;
  final FilterQuality filterQuality;

  _CroppedLogoPainter({
    required this.image,
    required this.crop,
    required this.fit,
    required this.filterQuality,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTRB(
      crop.left * image.width,
      crop.top * image.height,
      crop.right * image.width,
      crop.bottom * image.height,
    );
    if (src.width <= 0 || src.height <= 0) return;

    final fitted = applyBoxFit(fit, src.size, size);
    final outW = fitted.destination.width;
    final outH = fitted.destination.height;
    final dx = (size.width - outW) / 2;
    final dy = (size.height - outH) / 2;
    final dst = Rect.fromLTWH(dx, dy, outW, outH);

    final paint = Paint()..filterQuality = filterQuality;
    canvas.drawImageRect(image, src, dst, paint);
  }

  @override
  bool shouldRepaint(covariant _CroppedLogoPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.crop != crop ||
        oldDelegate.fit != fit;
  }
}
