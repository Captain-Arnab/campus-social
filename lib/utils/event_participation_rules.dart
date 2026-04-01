/// Shared rules: the event organiser cannot attend / volunteer / participate;
/// a user may have only one of: attendee, volunteer, or participant per event.
///
/// Anyone may join as an attendee for student- or staff-organised events.
/// Volunteer / participant only when the user type matches the organiser type
/// (students with student organisers, staff with staff organisers).
class EventParticipationRules {
  EventParticipationRules._();

  /// `true` = student, `false` = faculty/staff, `null` if unknown.
  static bool? parseIsStudentFlag(dynamic raw) {
    if (raw == null) return null;
    if (raw is bool) return raw;
    if (raw is int) return raw == 1;
    if (raw is String) return (int.tryParse(raw) ?? 0) == 1;
    return null;
  }

  static bool? organizerIsStudentFromEvent(dynamic event) {
    if (event is! Map) return null;
    return parseIsStudentFlag(event['organizer_is_student']);
  }

  /// Volunteer or participant allowed only when user and organiser are the same type.
  static bool volunteerOrParticipantAllowed(bool userIsStudent, bool organizerIsStudent) {
    return userIsStudent == organizerIsStudent;
  }

  static String? organizerIdFromEvent(dynamic event) {
    if (event is! Map) return null;
    final o = event['organizer_id'] ?? event['hostId'];
    if (o == null) return null;
    final s = o.toString();
    return s.isEmpty ? null : s;
  }

  static bool isUserEventOrganizer(dynamic event, String? userId) {
    if (userId == null || userId.isEmpty) return false;
    final oid = organizerIdFromEvent(event);
    return oid != null && oid == userId;
  }

  static bool userInVolunteerList(dynamic event, String? userId) {
    if (userId == null) return false;
    final vl = event is Map ? event['volunteer_list'] : null;
    if (vl is! List) return false;
    for (final x in vl) {
      if (x is Map && x['user_id']?.toString() == userId) return true;
    }
    return false;
  }

  static bool userInParticipantList(dynamic event, String? userId) {
    if (userId == null) return false;
    final pl = event is Map ? event['participant_list'] : null;
    if (pl is! List) return false;
    for (final x in pl) {
      if (x is Map && x['user_id']?.toString() == userId) return true;
    }
    return false;
  }
}
