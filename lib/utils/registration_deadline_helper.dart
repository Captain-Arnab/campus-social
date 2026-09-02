import '../data/api_service.dart';

DateTime? _parseEventDateTime(String? raw) {
  if (raw == null) return null;
  final s = raw.trim();
  if (s.isEmpty || s == 'null' || s == '0000-00-00 00:00:00') return null;
  return DateTime.tryParse(s.replaceAll(' ', 'T'));
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

/// Prefers API [lastServerTime] (`server_time`); falls back to local [DateTime.now].
bool isEventRegistrationClosed(dynamic event, {DateTime? now}) {
  final cutoff = registrationCutoffFromEvent(event);
  if (cutoff == null) return false;
  final clock = now ?? ApiService.lastServerTime ?? DateTime.now();
  return !clock.isBefore(cutoff);
}
