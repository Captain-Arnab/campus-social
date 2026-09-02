import 'package:flutter/foundation.dart';

import '../data/api_service.dart';
import 'winner_display_helper.dart';

/// Shared loaders for Explore carousel + Winners screen.
class WinnerFeedHelper {
  WinnerFeedHelper._();

  /// Run [tasks] with at most [concurrency] in flight.
  static Future<List<T?>> mapPool<T>(
    List<Future<T?> Function()> tasks, {
    int concurrency = 8,
  }) async {
    final out = List<T?>.filled(tasks.length, null);
    var next = 0;
    Future<void> worker() async {
      while (true) {
        final i = next++;
        if (i >= tasks.length) return;
        try {
          out[i] = await tasks[i]();
        } catch (e) {
          debugPrint('[WinnerFeed] task $i failed: $e');
          out[i] = null;
        }
      }
    }

    final n = concurrency.clamp(1, tasks.isEmpty ? 1 : tasks.length);
    await Future.wait(List.generate(n, (_) => worker()));
    return out;
  }

  static List<dynamic> _eventsFromResponse(dynamic raw) {
    final body = ApiService.parseResponseBody(raw) ??
        ApiService.responseDataMap(raw);
    if (body == null || body['status']?.toString() != 'success') return [];
    final data = body['data'];
    return data is List ? List<dynamic>.from(data) : [];
  }

  /// Past + closed events (deduped by id). Closed first so recent closures win.
  static Future<List<dynamic>> loadPastAndClosedEvents() async {
    final results = await Future.wait([
      ApiService.getClosedEvents(),
      ApiService.getPastEvents(),
    ]);
    final closed = _eventsFromResponse(results[0].data);
    final past = _eventsFromResponse(results[1].data);
    final byId = <String, dynamic>{};
    for (final e in [...closed, ...past]) {
      if (e is! Map) continue;
      final id = e['id']?.toString();
      if (id == null || id.isEmpty) continue;
      byId.putIfAbsent(id, () => e);
    }
    return byId.values.toList();
  }

  static Future<Map<String, String?>> _profilePicsForUserIds(
    Iterable<String> userIds,
  ) async {
    final unique = userIds.where((id) => id.isNotEmpty).toSet().toList();
    final map = <String, String?>{};
    if (unique.isEmpty) return map;

    final tasks = unique.map((uid) {
      return () async {
        try {
          final r = await ApiService.getUserProfile(uid);
          final body = ApiService.parseResponseBody(r.data);
          final data = body?['data'];
          if (data is Map) {
            return MapEntry(uid, winnerProfileImageUrl(data));
          }
        } catch (_) {}
        return MapEntry(uid, null);
      };
    }).toList();

    final resolved = await mapPool(tasks, concurrency: 6);
    for (final e in resolved) {
      if (e != null) map[e.key] = e.value;
    }
    return map;
  }

  /// Enrich a winner row with `profile_pic` / `photo_url` when missing.
  static Future<List<Map<String, dynamic>>> enrichWinnersWithProfiles(
    List<dynamic> winners,
  ) async {
    final rows = <Map<String, dynamic>>[];
    final needIds = <String>[];
    for (final w in winners) {
      if (w is! Map) continue;
      final m =
          Map<String, dynamic>.from(w.map((k, v) => MapEntry(k.toString(), v)));
      rows.add(m);
      if (winnerProfileImageUrl(m) == null) {
        final uid = m['user_id']?.toString() ?? '';
        if (uid.isNotEmpty) needIds.add(uid);
      }
    }
    final pics = await _profilePicsForUserIds(needIds);
    for (final m in rows) {
      if (winnerProfileImageUrl(m) != null) continue;
      final uid = m['user_id']?.toString() ?? '';
      final pic = pics[uid];
      if (pic != null && pic.isNotEmpty) {
        m['profile_pic'] = pic;
        m['photo_url'] = pic;
      }
    }
    return rows;
  }

  static List<Map<String, dynamic>> _winnerRowsFromList(
    List list, {
    required String eventName,
    required int eventId,
  }) {
    return list.whereType<Map>().map((w) {
      final m =
          Map<String, dynamic>.from(w.map((k, v) => MapEntry(k.toString(), v)));
      return <String, dynamic>{
        'winner_name': winnerDisplayName(m),
        'event_name': eventName,
        'event_id': eventId,
        'user_id': m['user_id'],
        'position': m['position'],
        'profile_pic': m['profile_pic'] ?? m['image'] ?? m['avatar'],
        'photo_url': m['photo_url'] ?? m['photo'],
        'full_name': m['full_name'] ?? m['student_name'] ?? m['name'],
      };
    }).toList();
  }

  /// Carousel cards: prefer `winner_photos.php`, else build from event winners + profiles.
  static Future<List<Map<String, dynamic>>> loadCarouselPhotos({
    int limit = 20,
  }) async {
    try {
      final r = await ApiService.getWinnerPhotos(limit: limit);
      final m = ApiService.parseResponseBody(r.data);
      if (m != null && m['status']?.toString() == 'success') {
        final list = m['data'] ?? m['photos'] ?? m['winners'];
        if (list is List && list.isNotEmpty) {
          final out = <Map<String, dynamic>>[];
          for (final e in list) {
            if (e is Map) {
              out.add(Map<String, dynamic>.from(
                  e.map((k, v) => MapEntry(k.toString(), v))));
            }
          }
          if (out.isNotEmpty) {
            final enriched = await enrichWinnersWithProfiles(out);
            return enriched.take(limit).map((w) {
              final photo = winnerProfileImageUrl(w) ?? '';
              return <String, dynamic>{
                ...w,
                'photo_url': photo.isNotEmpty ? photo : (w['photo_url'] ?? ''),
                'winner_name': winnerDisplayName(w),
              };
            }).toList();
          }
        }
      }
    } catch (e) {
      debugPrint('[WinnerFeed] winner_photos.php failed: $e');
    }

    // Fallback: scan past + closed in waves; stop once we have [limit] winners.
    final events = await loadPastAndClosedEvents();
    final collected = <Map<String, dynamic>>[];
    final tasks = <Future<List<Map<String, dynamic>>> Function()>[];

    for (final e in events) {
      if (e is! Map) continue;
      final id = int.tryParse(e['id']?.toString() ?? '');
      if (id == null) continue;
      final eventName = (e['title'] ?? 'Event').toString();
      tasks.add(() async {
        try {
          final winRes = await ApiService.getWinnersByEventId(id);
          final body = ApiService.parseResponseBody(winRes.data);
          var list = body?['data'];
          if (list is! List || list.isEmpty) {
            list = e['winners'];
          }
          if (list is! List || list.isEmpty) return <Map<String, dynamic>>[];
          return _winnerRowsFromList(list, eventName: eventName, eventId: id);
        } catch (_) {
          return <Map<String, dynamic>>[];
        }
      });
    }

    const wave = 12;
    for (var i = 0; i < tasks.length && collected.length < limit; i += wave) {
      final end = (i + wave).clamp(0, tasks.length);
      final slice = tasks.sublist(i, end);
      final batches = await mapPool(slice, concurrency: 6);
      for (final batch in batches) {
        if (batch == null) continue;
        collected.addAll(batch);
        if (collected.length >= limit) break;
      }
    }

    final trimmed = collected.take(limit).toList();
    final enriched = await enrichWinnersWithProfiles(trimmed);
    return enriched.map((w) {
      final photo = winnerProfileImageUrl(w) ?? '';
      return <String, dynamic>{
        ...w,
        'photo_url': photo.isNotEmpty ? photo : (w['photo_url'] ?? ''),
        'winner_name': winnerDisplayName(w),
        'event_name': w['event_name'] ?? '',
      };
    }).toList();
  }

  /// Map eventId → winners for the Winners screen (batched, includes closed).
  static Future<({List<dynamic> events, Map<int, List<dynamic>> winnersByEvent})>
      loadEventsWithWinners() async {
    final events = await loadPastAndClosedEvents();
    final winnersByEvent = <int, List<dynamic>>{};
    final tasks = <Future<MapEntry<int, List<dynamic>>?> Function()>[];

    for (final e in events) {
      if (e is! Map) continue;
      final id = int.tryParse(e['id']?.toString() ?? '');
      if (id == null) continue;
      tasks.add(() async {
        try {
          final winRes = await ApiService.getWinnersByEventId(id);
          final body = ApiService.parseResponseBody(winRes.data);
          final list = body?['data'];
          if (list is List && list.isNotEmpty) {
            return MapEntry(id, List<dynamic>.from(list));
          }
          final embedded = e['winners'];
          if (embedded is List && embedded.isNotEmpty) {
            return MapEntry(id, List<dynamic>.from(embedded));
          }
        } catch (_) {}
        return null;
      });
    }

    final resolved = await mapPool(tasks, concurrency: 8);
    final allWinnerRows = <dynamic>[];
    for (final entry in resolved) {
      if (entry == null) continue;
      winnersByEvent[entry.key] = entry.value;
      allWinnerRows.addAll(entry.value);
    }

    // One pooled profile enrich (avoids nested N×M profile calls per event).
    final enrichedAll = await enrichWinnersWithProfiles(allWinnerRows);
    final byUser = <String, Map<String, dynamic>>{};
    for (final w in enrichedAll) {
      final uid = w['user_id']?.toString() ?? '';
      if (uid.isNotEmpty) byUser[uid] = w;
    }
    for (final id in winnersByEvent.keys.toList()) {
      winnersByEvent[id] = winnersByEvent[id]!.map((w) {
        if (w is! Map) return w;
        final uid = w['user_id']?.toString() ?? '';
        final enriched = byUser[uid];
        if (enriched == null) {
          return Map<String, dynamic>.from(
              w.map((k, v) => MapEntry(k.toString(), v)));
        }
        return <String, dynamic>{
          ...Map<String, dynamic>.from(
              w.map((k, v) => MapEntry(k.toString(), v))),
          if (enriched['profile_pic'] != null)
            'profile_pic': enriched['profile_pic'],
          if (enriched['photo_url'] != null) 'photo_url': enriched['photo_url'],
        };
      }).toList();
    }

    return (events: events, winnersByEvent: winnersByEvent);
  }
}
