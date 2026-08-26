import '../base/constant.dart';

/// Resolves event banner/poster URLs from API payloads (handles multiple field names).
class EventImageHelper {
  EventImageHelper._();

  static const _eventUploadBase = 'https://micampus.co.in/admin/uploads/events/';

  static String? bannerUrl(dynamic event) {
    if (event is! Map) return null;
    final map = Map<String, dynamic>.from(event);

    final banners = map['banners'];
    if (banners is List && banners.isNotEmpty) {
      final url = _resolve(banners.first?.toString() ?? '');
      if (url != null) return url;
    }

    for (final key in [
      'banner',
      'poster',
      'image',
      'event_image',
      'thumbnail',
      'banner_image',
      'poster_url',
    ]) {
      final raw = map[key]?.toString().trim() ?? '';
      if (raw.isNotEmpty) {
        final url = _resolve(raw);
        if (url != null) return url;
      }
    }
    return null;
  }

  static String? _resolve(String raw) {
    if (raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    var path = raw.replaceAll('\\', '/');
    while (path.startsWith('/')) {
      path = path.substring(1);
    }
    if (path.toLowerCase().startsWith('uploads/events/')) {
      return Constant.uploadPublicUrl(path);
    }
    if (path.toLowerCase().startsWith('events/')) {
      return '${Constant.uploadsBaseUrl}$path';
    }
    return '$_eventUploadBase$path';
  }
}
