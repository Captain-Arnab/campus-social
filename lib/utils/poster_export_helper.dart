import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import 'upload_file_validators.dart';

/// Renders a poster [RepaintBoundary] and encodes a JPEG kept under the upload size cap.
class PosterExportHelper {
  PosterExportHelper._();

  /// Capture + compress until ≤ [UploadFileValidators.maxPosterBytes] (5 MB).
  /// Returns a `.jpg` temp file, or null on failure.
  static Future<File?> saveJpegUnderMaxSize(
    GlobalKey key, {
    int maxBytes = UploadFileValidators.maxPosterBytes,
    String filePrefix = 'event_poster',
  }) async {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;

    // Prefer sharper first; step down if still too large.
    const ratios = <double>[2.5, 2.0, 1.75, 1.5, 1.25, 1.0];
    const qualities = <int>[90, 82, 72, 62, 52, 42];

    Uint8List? bestBytes;
    int bestLen = 1 << 30;

    for (final ratio in ratios) {
      try {
        final ui.Image raw = await boundary.toImage(pixelRatio: ratio);
        final ByteData? rgbaData =
            await raw.toByteData(format: ui.ImageByteFormat.rawRgba);
        if (rgbaData == null) continue;

        final decoded = img.Image.fromBytes(
          width: raw.width,
          height: raw.height,
          bytes: rgbaData.buffer,
          bytesOffset: rgbaData.offsetInBytes,
          order: img.ChannelOrder.rgba,
        );

        for (final quality in qualities) {
          final encoded = Uint8List.fromList(
            img.encodeJpg(decoded, quality: quality),
          );
          if (encoded.lengthInBytes < bestLen) {
            bestBytes = encoded;
            bestLen = encoded.lengthInBytes;
          }
          if (encoded.lengthInBytes <= maxBytes) {
            return _writeTempJpeg(filePrefix, encoded);
          }
        }
      } catch (e) {
        debugPrint('PosterExportHelper ratio=$ratio failed: $e');
      }
    }

    // Last resort: write the smallest we produced (caller may still validate).
    if (bestBytes != null) {
      debugPrint(
        'PosterExportHelper: smallest encode ${UploadFileValidators.formatMb(bestLen)} '
        '(target ${UploadFileValidators.formatMb(maxBytes)})',
      );
      return _writeTempJpeg(filePrefix, bestBytes);
    }
    return null;
  }

  /// Gallery / share export — same 3 MB budget, JPG.
  static Future<Uint8List?> encodeJpegBytesUnderMaxSize(
    GlobalKey key, {
    int maxBytes = UploadFileValidators.maxPosterBytes,
  }) async {
    final file = await saveJpegUnderMaxSize(
      key,
      maxBytes: maxBytes,
      filePrefix: 'gallery_poster',
    );
    if (file == null) return null;
    return file.readAsBytes();
  }

  static Future<File> _writeTempJpeg(String prefix, Uint8List bytes) async {
    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/${prefix}_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}
