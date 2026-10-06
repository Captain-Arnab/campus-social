import 'package:flutter/foundation.dart';

import '../data/api_service.dart';
import 'winner_display_helper.dart';

typedef WinnerEventGroup = ({
  Map<String, dynamic> event,
  List<Map<String, dynamic>> winners,
});

/// Shared loaders for Explore carousel, Winners screen and event detail winners.
class WinnerFeedHelper {
  WinnerFeedHelper._();

  /// user_id → profile details. Process-lifetime.
  static final Map<String, _WinnerProfile> _profileCache = {};

  /// Recent winners from `winner_photos.php` (closed + ended approved events,
  /// newest first). Throws when the server is unreachable or rejects the call.
  static Future<List<Map<String, dynamic>>> loadWinners({int limit = 20}) async {
    final sw = Stopwatch()..start();
    final r = await ApiService.getWinnerPhotos(limit: limit);
    final m = ApiService.parseResponseBody(r.data);
    if (m == null || m['status']?.toString() != 'success') {
      throw Exception('winner_photos.php failed (HTTP ${r.statusCode})');
    }
    final list = m['data'];
    final rows = list is! List
        ? <Map<String, dynamic>>[]
        : list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(
                e.map((k, v) => MapEntry(k.toString(), v))))
            .toList();
    debugPrint('[WinnerFeed] 1 request: winner_photos.php?limit=$limit '
        '→ ${rows.length} winners in ${sw.elapsedMilliseconds}ms');
    return rows;
  }

  /// Groups winner rows by `event_id`, keeping the API's event order and
  /// sorting each event's winners by position.
  static List<WinnerEventGroup> groupByEvent(List<Map<String, dynamic>> rows) {
    final groups = <String, WinnerEventGroup>{};
    for (final w in rows) {
      final id = w['event_id']?.toString() ?? '';
      if (id.isEmpty) continue;
      groups.putIfAbsent(
        id,
        () => (
          event: <String, dynamic>{
            'id': w['event_id'],
            'title': w['event_name'] ?? 'Event',
            'event_date': w['event_date'],
            'status': w['event_status'],
          },
          winners: <Map<String, dynamic>>[],
        ),
      ).winners.add(w);
    }
    for (final g in groups.values) {
      g.winners.sort((a, b) {
        final pa = winnerPosition(a), pb = winnerPosition(b);
        if (pa <= 0) return pb <= 0 ? 0 : 1;
        if (pb <= 0) return -1;
        return pa.compareTo(pb);
      });
    }
    return groups.values.toList();
  }

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

  static Future<Map<String, _WinnerProfile>> _profilesForUserIds(
    Iterable<String> userIds,
  ) async {
    final unique = userIds.where((id) => id.isNotEmpty).toSet().toList();
    final missing = unique.where((uid) => !_profileCache.containsKey(uid)).toList();

    final tasks = missing.map((uid) {
      return () async {
        try {
          final r = await ApiService.getUserProfile(uid);
          final body = ApiService.parseResponseBody(r.data);
          final data = body?['data'];
          if (data is Map) {
            _profileCache[uid] = _WinnerProfile(
              imageUrl: winnerProfileImageUrl(data),
              departmentClass: data['department_class']?.toString(),
              isStudent: data['is_student'],
            );
          }
        } catch (_) {}
        return null;
      };
    }).toList();
    await mapPool(tasks, concurrency: 8);

    return {
      for (final uid in unique)
        if (_profileCache[uid] != null) uid: _profileCache[uid]!,
    };
  }

  static bool _hasAffiliation(Map w) =>
      winnerAffiliation(w).isNotEmpty ||
      w.containsKey('winner_department_class') ||
      w.containsKey('winner_is_student');

  /// Event detail only: `event_winners.php` rows lack avatar and department
  /// fields, so they're filled from each winner's profile. Rows from
  /// [loadWinners] already carry them and must not go through this.
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
      if (winnerProfileImageUrl(m) == null || !_hasAffiliation(m)) {
        final uid = m['user_id']?.toString() ?? '';
        if (uid.isNotEmpty) needIds.add(uid);
      }
    }
    if (needIds.isEmpty) return rows;
    final profiles = await _profilesForUserIds(needIds);
    for (final m in rows) {
      final p = profiles[m['user_id']?.toString() ?? ''];
      if (p == null) continue;
      if (winnerProfileImageUrl(m) == null && p.imageUrl != null) {
        m['profile_pic'] = p.imageUrl;
      }
      if (!_hasAffiliation(m)) {
        m['department_class'] = p.departmentClass;
        m['is_student'] = p.isStudent;
      }
    }
    return rows;
  }
}

class _WinnerProfile {
  final String? imageUrl;
  final String? departmentClass;
  final dynamic isStudent;

  const _WinnerProfile({this.imageUrl, this.departmentClass, this.isStudent});
}
