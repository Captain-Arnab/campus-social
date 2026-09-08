import 'package:intl/intl.dart';

import '../data/api_service.dart';

DateTime? _parseEventDateTime(String? raw) {
  if (raw == null) return null;
  final s = raw.trim();
  if (s.isEmpty || s == 'null' || s == '0000-00-00 00:00:00') return null;
  return DateTime.tryParse(s.replaceAll(' ', 'T'));
}

bool? _asBoolFlag(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = v.toString().trim().toLowerCase();
  if (s == '1' || s == 'true' || s == 'yes') return true;
  if (s == '0' || s == 'false' || s == 'no') return false;
  return null;
}

/// Effective registration cutoff: [registration_deadline] if set, else event start.
DateTime? registrationCutoffFromEvent(dynamic event) {
  if (event is! Map) return null;
  final deadline = _parseEventDateTime(event['registration_deadline']?.toString());
  if (deadline != null) return deadline;
  return _parseEventDateTime(
    (event['event_date'] ?? event['date'])?.toString(),
  );
}

/// Prefer API [registration_closed] / [registration_open]; fall back to date math.
bool isEventRegistrationClosed(dynamic event, {DateTime? now}) {
  if (event is Map) {
    final closed = _asBoolFlag(event['registration_closed']);
    if (closed != null) return closed;
    final open = _asBoolFlag(event['registration_open']);
    if (open != null) return !open;
  }
  final cutoff = registrationCutoffFromEvent(event);
  if (cutoff == null) return false;
  final clock = now ?? ApiService.lastServerTime ?? DateTime.now();
  return !clock.isBefore(cutoff);
}

bool isEventRegistrationOpen(dynamic event, {DateTime? now}) =>
    !isEventRegistrationClosed(event, now: now);

/// User-facing line like "Registration closes on 12 Sep 2026 at 5:30 PM".
String? registrationClosesLabel(dynamic event) {
  if (event is! Map) return null;
  final deadline = _parseEventDateTime(event['registration_deadline']?.toString());
  if (deadline == null) return null;
  final datePart = DateFormat('dd MMM yyyy').format(deadline);
  final timePart = DateFormat('h:mm a').format(deadline);
  return 'Registration closes on $datePart at $timePart';
}
