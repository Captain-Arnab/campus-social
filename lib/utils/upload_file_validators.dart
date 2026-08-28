import 'dart:io';

/// Size limits for event poster / banner uploads.
class UploadFileValidators {
  UploadFileValidators._();

  /// Soft target mentioned in product copy (~2–3 MB).
  static const int softTargetBytes = 2 * 1024 * 1024;

  /// Hard max allowed for poster/banner upload.
  static const int maxPosterBytes = 3 * 1024 * 1024;

  static String formatMb(int bytes) {
    final mb = bytes / (1024 * 1024);
    if (mb < 0.1) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${mb.toStringAsFixed(1)} MB';
  }

  /// Returns an error message when [file] exceeds [maxPosterBytes], else null.
  static Future<String?> posterSizeError(File file) async {
    try {
      if (!await file.exists()) {
        return 'Poster file was not found. Please select again.';
      }
      final len = await file.length();
      if (len > maxPosterBytes) {
        return 'Poster size must be within 2–3 MB '
            '(maximum ${formatMb(maxPosterBytes)}). '
            'Your file is ${formatMb(len)}. '
            'Please choose a smaller image or compress it.';
      }
      return null;
    } catch (_) {
      return 'Could not read poster file size. Please try another image.';
    }
  }

  /// True when file exists and is ≤ [maxPosterBytes].
  static Future<bool> isPosterSizeAllowed(File file) async {
    return (await posterSizeError(file)) == null;
  }
}
