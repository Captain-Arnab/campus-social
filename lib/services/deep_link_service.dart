import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../controllers/event_controller.dart';
import '../views/event_detail_view.dart';

/// Handles `https://micampus.co.in/event?id=…` and `micampus://event?id=…` so taps
/// can open [EventDetailView] instead of only the browser.
///
/// **Android App Links** require `https://micampus.co.in/.well-known/assetlinks.json`
/// (package `co.micampus.app`, release signing SHA-256). Until that file is live,
/// users may still get Chrome; the custom `micampus://` scheme works without the server.
class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  int? _pendingEventId;

  /// Parse supported URIs; returns null if not an event deep link.
  static int? parseMicampusEventId(Uri uri) {
    final host = uri.host.toLowerCase();
    final isHttpsEvent = uri.scheme == 'https' &&
        (host == 'micampus.co.in' || host == 'www.micampus.co.in') &&
        (uri.path == '/event' || uri.path.startsWith('/event/'));

    final isCustomScheme =
        uri.scheme == 'micampus' && (uri.host.toLowerCase() == 'event' || uri.pathSegments.any((s) => s.toLowerCase() == 'event'));

    if (!isHttpsEvent && !isCustomScheme) return null;

    final fromQuery = int.tryParse(uri.queryParameters['id'] ?? '');
    if (fromQuery != null && fromQuery > 0) return fromQuery;

    final segs = uri.pathSegments;
    final i = segs.indexWhere((s) => s.toLowerCase() == 'event');
    if (i >= 0 && i + 1 < segs.length) {
      final fromPath = int.tryParse(segs[i + 1]);
      if (fromPath != null && fromPath > 0) return fromPath;
    }
    return null;
  }

  Future<void> init() async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _onUri(initial);
    } catch (e, st) {
      debugPrint('DeepLinkService initial link: $e\n$st');
    }
    await _sub?.cancel();
    _sub = _appLinks.uriLinkStream.listen(
      (Uri uri) => _onUri(uri),
      onError: (Object e, StackTrace st) => debugPrint('DeepLinkService stream: $e\n$st'),
    );
  }

  void _onUri(Uri uri) {
    final id = parseMicampusEventId(uri);
    if (id == null) return;
    _pendingEventId = id;
    tryNavigateToPendingEvent();
  }

  /// Call when [HomeView] is ready so [EventController] exists and [Get] navigation works.
  void tryNavigateToPendingEvent() {
    final id = _pendingEventId;
    if (id == null) return;
    if (!Get.isRegistered<EventController>()) return;

    _pendingEventId = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!Get.isRegistered<EventController>()) return;
      Get.to(
        () => EventDetailView(event: {'id': id}),
        transition: Transition.rightToLeft,
      );
    });
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}
