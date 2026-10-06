import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

/// Shared list of interest suggestions (built-in + server catalog + new
/// interests contributed from this device).
///
/// New interests are queued locally and pushed to `interests.php` so other
/// users see them; the queue is retried on every [load] until the server
/// accepts it (e.g. before the endpoint is deployed).
class InterestCatalog {
  InterestCatalog._();

  static const List<String> builtIn = [
    'IT/Tech', 'Coding', 'Open Source', 'Cultural', 'Dance', 'Art',
    'Sports', 'Fitness', 'Cricket', 'Football', 'Basketball', 'Social',
    'Volunteering', 'Photography', 'Academic', 'Literature', 'Debate',
    'Music', 'Singing', 'Entertainment', 'Drama', 'Fashion', 'History',
    'Swimming', 'Wrestling', 'Astronomy', 'Physics', 'Gaming',
  ];

  static const int maxLength = 30;

  static const _cacheKey = 'interest_catalog_cache_v1';
  static const _pendingKey = 'interest_catalog_pending_v1';

  static List<String>? _memCache;

  /// Trims, collapses whitespace and rejects empty / overly long / symbol-only values.
  static String? normalize(String raw) {
    final v = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (v.length < 2 || v.length > maxLength) return null;
    if (!RegExp(r'[A-Za-z0-9]').hasMatch(v)) return null;
    return v;
  }

  static bool containsIgnoreCase(Iterable<String> list, String value) {
    final q = value.toLowerCase();
    return list.any((e) => e.toLowerCase() == q);
  }

  static List<String> _merge(Iterable<Iterable<String>> sources) {
    final out = <String>[];
    for (final src in sources) {
      for (final e in src) {
        final n = normalize(e);
        if (n != null && !containsIgnoreCase(out, n)) out.add(n);
      }
    }
    return out;
  }

  /// Best list available without waiting on the network.
  static List<String> get current => _memCache ?? builtIn;

  /// Loads the catalog (server first, falling back to the last cached copy),
  /// and retries pushing any queued contributions.
  static Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getStringList(_cacheKey) ?? const <String>[];
    final pending = prefs.getStringList(_pendingKey) ?? const <String>[];

    List<String>? server;
    try {
      final r = await ApiService.getInterestCatalog();
      final body = ApiService.parseResponseBody(r.data);
      if (body != null && body['status']?.toString() == 'success' && body['data'] is List) {
        server = (body['data'] as List)
            .map((e) => e is Map ? (e['name'] ?? '').toString() : e.toString())
            .toList();
      }
    } catch (e) {
      debugPrint('[InterestCatalog] list failed: $e');
    }

    final merged = _merge([builtIn, server ?? cached, pending]);
    _memCache = merged;
    if (server != null) {
      await prefs.setStringList(_cacheKey, _merge([server]));
    }
    if (pending.isNotEmpty) unawaited(_flushPending());
    return merged;
  }

  /// Adds interests that are not yet in the catalog, so the next user finds
  /// them in suggestions instead of typing them again.
  static Future<void> contribute(Iterable<String> interests) async {
    final known = current;
    final fresh = <String>[];
    for (final raw in interests) {
      final n = normalize(raw);
      if (n == null || containsIgnoreCase(known, n) || containsIgnoreCase(fresh, n)) continue;
      fresh.add(n);
    }
    if (fresh.isEmpty) return;

    _memCache = _merge([known, fresh]);
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList(_pendingKey) ?? <String>[];
    await prefs.setStringList(_pendingKey, _merge([pending, fresh]));
    await _flushPending();
  }

  static bool _flushing = false;

  static Future<void> _flushPending() async {
    if (_flushing) return;
    _flushing = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final pending = List<String>.from(prefs.getStringList(_pendingKey) ?? const <String>[]);
      final remaining = <String>[];
      for (final name in pending) {
        try {
          final r = await ApiService.addInterestToCatalog(name);
          final body = ApiService.parseResponseBody(r.data);
          if (body?['status']?.toString() != 'success') remaining.add(name);
        } catch (_) {
          remaining.add(name);
        }
      }
      await prefs.setStringList(_pendingKey, remaining);
      if (remaining.length != pending.length) {
        debugPrint('[InterestCatalog] pushed ${pending.length - remaining.length} new interest(s)');
      }
    } catch (e) {
      debugPrint('[InterestCatalog] flush failed: $e');
    } finally {
      _flushing = false;
    }
  }
}
