import 'package:flutter/services.dart';

/// Shared login / registration input rules for MiCampus auth screens.
class AuthInputValidators {
  AuthInputValidators._();

  static const String loginCredentialsHint =
      'Please enter the login credentials properly';

  /// Digits only (phone, OTP, etc.).
  static final List<TextInputFormatter> digitsOnly = [
    FilteringTextInputFormatter.digitsOnly,
  ];

  static final List<TextInputFormatter> phone10Digits = [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(10),
  ];

  static final List<TextInputFormatter> otp6Digits = [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(6),
  ];

  /// True when [value] looks like a usable email (must include `@` + domain).
  static bool isValidEmail(String value) {
    final email = value.trim();
    if (email.isEmpty || !email.contains('@')) return false;
    // Simple, practical check: local@domain.tld
    return RegExp(
      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
      caseSensitive: false,
    ).hasMatch(email);
  }

  /// Exactly 10 digits (mobile number fields).
  static bool isValidPhone10(String value) {
    final digits = value.trim().replaceAll(RegExp(r'\D'), '');
    return RegExp(r'^\d{10}$').hasMatch(digits);
  }

  static String phoneDigits(String value) =>
      value.trim().replaceAll(RegExp(r'\D'), '');

  /// Maps backend login errors to a clear credentials hint when appropriate.
  static String friendlyLoginError(String? apiMessage) {
    final msg = (apiMessage ?? '').trim();
    if (msg.isEmpty) return loginCredentialsHint;
    final lower = msg.toLowerCase();
    const credentialHints = [
      'invalid',
      'incorrect',
      'wrong',
      'not found',
      'does not exist',
      'password',
      'roll',
      'employee',
      'emp',
      'email',
      'phone',
      'mobile',
      'credential',
      'unauthorized',
      'otp',
    ];
    if (credentialHints.any(lower.contains)) {
      return loginCredentialsHint;
    }
    return msg;
  }
}
