import '../modal/model_event.dart';

/// Optimistic / helper utilities around event `my_registration`.
///
/// Source of truth after load/refetch is [ModelEvent.myRegistration] /
/// `event['my_registration']`. Local cache is only for instant UI right after
/// verify_payment before a refetch completes — and is applied by merging into
/// the in-memory event map, not as a long-lived lock authority.
class EventPaymentCache {
  EventPaymentCache._();

  static final Map<String, String> _optimisticByKey = {};

  static String _key(String eventId, String role) =>
      '${eventId.trim()}::${role.trim().toLowerCase()}';

  /// Mark paid optimistically for [eventId]+[role] until GET refreshes.
  static void setOptimisticPaid(String eventId, String role) {
    if (eventId.trim().isEmpty || role.trim().isEmpty) return;
    _optimisticByKey[_key(eventId, role)] = 'paid';
  }

  static void clearOptimisticForEvent(String eventId) {
    final prefix = '${eventId.trim()}::';
    _optimisticByKey.removeWhere((k, _) => k.startsWith(prefix));
  }

  /// Merge paid `my_registration` into the in-memory event map for instant UI.
  static void mergePaidIntoEvent(Map event, String role) {
    final apiRole = role == 'participate' ? 'participant' : 'attend';
    event['my_registration'] = {
      'role': apiRole,
      'payment_status': 'paid',
    };
    final eid = event['id']?.toString() ?? '';
    if (eid.isNotEmpty) setOptimisticPaid(eid, role);
  }

  /// Paid-lock from `my_registration` (source of truth). If null → not locked.
  /// Falls back to optimistic flag only when GET has not yet returned paid.
  static bool isPaidLocked({
    required String eventId,
    required String role,
    Map? event,
  }) {
    final fromEvent = ModelEvent.isPaidLockedForRole(
      ModelEvent.parseMyRegistration(event?['my_registration']),
      role,
    );
    if (fromEvent) return true;

    // Instant feedback window after verify_payment, before refetch lands.
    return _optimisticByKey[_key(eventId, role)] == 'paid';
  }
}
