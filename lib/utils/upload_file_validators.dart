import 'dart:io';

import 'package:image/image.dart' as img;

/// Size and dimension limits for event poster / banner uploads.
class UploadFileValidators {
  UploadFileValidators._();

  /// Soft target mentioned in product copy.
  static const int softTargetBytes = 2 * 1024 * 1024;

  /// Hard max allowed for poster/banner upload (5 MB).
  static const int maxPosterBytes = 5 * 1024 * 1024;

  /// Max poster width (px).
  static const int maxPosterWidth = 1080;

  /// Max poster height (px).
  static const int maxPosterHeight = 1920;

  static const String posterLimitMessage =
      'Poster must be ≤5MB and ≤1080×1920 px';

  static String formatMb(int bytes) {
    final mb = bytes / (1024 * 1024);
    if (mb < 0.1) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${mb.toStringAsFixed(1)} MB';
  }

  /// Returns an error message when [file] exceeds size or dimension limits.
  static Future<String?> posterSizeError(File file) async {
    try {
      if (!await file.exists()) {
        return 'Poster file was not found. Please select again.';
      }
      final len = await file.length();
      if (len > maxPosterBytes) {
        return '$posterLimitMessage. '
            'Your file is ${formatMb(len)}.';
      }

      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        return 'Could not read poster image. Please try another file.';
      }
      if (decoded.width > maxPosterWidth || decoded.height > maxPosterHeight) {
        return '$posterLimitMessage. '
            'Your image is ${decoded.width}×${decoded.height} px.';
      }
      return null;
    } catch (_) {
      return 'Could not validate poster file. Please try another image.';
    }
  }

  /// True when file exists and passes size + dimension checks.
  static Future<bool> isPosterSizeAllowed(File file) async {
    return (await posterSizeError(file)) == null;
  }
}
