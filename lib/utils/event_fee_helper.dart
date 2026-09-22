/// Participation fee / mode helpers for event detail join buttons.
class EventFeeHelper {
  EventFeeHelper._();

  static const disabledMessage =
      'This option is not available for this event';

  /// `attend` | `volunteer` | `participate`
  static String modeFor(Map? event, String role) {
    if (event == null) return 'without_fee';
    final key = switch (role) {
      'attend' => 'attend_mode',
      'volunteer' => 'volunteer_mode',
      'participate' => 'participate_mode',
      _ => '',
    };
    if (key.isEmpty) return 'without_fee';
    final raw = (event[key] ?? 'without_fee').toString().trim().toLowerCase();
    if (raw == 'disabled' || raw == 'with_fee' || raw == 'without_fee') {
      return raw;
    }
    return 'without_fee';
  }

  static bool isDisabled(Map? event, String role) =>
      modeFor(event, role) == 'disabled';

  static bool isWithFee(Map? event, String role) =>
      modeFor(event, role) == 'with_fee';

  static num? feeAmount(Map? event, String role) {
    if (event == null) return null;
    final key = switch (role) {
      'attend' => 'attend_fee',
      'participate' => 'participate_fee',
      _ => null,
    };
    if (key == null) return null;
    final raw = event[key];
    if (raw == null) return null;
    if (raw is num) return raw;
    return num.tryParse(raw.toString().trim());
  }

  /// e.g. ₹500 (no decimals for whole numbers).
  static String formatFee(num? amount) {
    if (amount == null) return '₹0';
    if (amount == amount.roundToDouble()) {
      return '₹${amount.toInt()}';
    }
    return '₹$amount';
  }

  static String joinButtonLabel({
    required Map? event,
    required String role,
    required String freeLabel,
    required bool regClosed,
  }) {
    if (regClosed) return 'Closed';
    if (isDisabled(event, role)) return 'Unavailable';
    if (isWithFee(event, role) && (role == 'attend' || role == 'participate')) {
      final fee = formatFee(feeAmount(event, role));
      return role == 'attend' ? 'Attend — $fee' : 'Participate — $fee';
    }
    return freeLabel;
  }
}
