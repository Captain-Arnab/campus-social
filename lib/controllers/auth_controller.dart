import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/api_service.dart';
import '../data/app_bootstrap.dart';
import '../data/otp_service.dart';
import '../data/pref_service.dart';
import '../services/notification_service.dart';
import '../utils/app_navigation.dart';
import '../utils/auth_input_validators.dart';
import '../utils/network_error_helper.dart';
import '../utils/sweetalert_helper.dart';
import '../views/bootstrap_views.dart';
import 'profile_controller.dart';

class _PendingLoginOtp {
  final String identifier;
  final String emailOrPhone;
  final bool isStudent;

  const _PendingLoginOtp({
    required this.identifier,
    required this.emailOrPhone,
    required this.isStudent,
  });
}

class _PendingLogin {
  final String identifier;
  final String emailOrPhone;
  final bool isStudent;
  final bool byMobile;
  final String password;
  final String? otp;

  const _PendingLogin({
    required this.identifier,
    required this.emailOrPhone,
    required this.isStudent,
    required this.byMobile,
    required this.password,
    this.otp,
  });
}

class _PendingRegister {
  final String name;
  final String email;
  final String phone;
  final String password;
  final String bio;
  final String interests;
  final bool isStudent;
  final String? rollNumber;
  final String? empNumber;
  final String? departmentClass;

  const _PendingRegister({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.bio,
    required this.interests,
    required this.isStudent,
    this.rollNumber,
    this.empNumber,
    this.departmentClass,
  });
}

class AuthController extends GetxController {
  var isLoading = false.obs;
  var isSendingLoginOtp = false.obs;
  var sentOtp = ''.obs;
  var otpSentTime = DateTime.now().obs;

  /// API `field` from the last failed register call
  /// (`email`, `mobile_number`, `roll_number`, `employee_id`).
  final registerErrorField = RxnString();

  /// Bumped on logout so a pending post-login "Welcome back" alert cannot fire late.
  int _authSessionEpoch = 0;

  _PendingLoginOtp? _pendingLoginOtp;
  _PendingLogin? _pendingLogin;
  _PendingRegister? _pendingRegister;

  void _showRequestFailure(
    String title,
    String rawMessage, {
    Object? error,
    VoidCallback? onRetry,
  }) {
    final message = NetworkErrorHelper.userMessage(error, apiMessage: rawMessage);
    final retry = onRetry;
    if (retry != null && NetworkErrorHelper.isRetryable(error, apiMessage: rawMessage)) {
      SweetAlertHelper.showErrorWithRetry(
        Get.context,
        title,
        message,
        onRetry: retry,
      );
      return;
    }
    SweetAlertHelper.showError(Get.context, title, message);
  }

  /// FCM registration must never block auth navigation.
  void _registerFcmInBackground({required String reason}) {
    unawaited(() async {
      try {
        debugPrint('[Auth] FCM ensureTokenRegistered start ($reason)');
        await NotificationService.ensureTokenRegistered().timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            debugPrint('[Auth] FCM ensureTokenRegistered timed out ($reason)');
          },
        );
        debugPrint('[Auth] FCM ensureTokenRegistered done ($reason)');
      } catch (e, st) {
        debugPrint('[Auth] FCM ensureTokenRegistered error ($reason): $e\n$st');
      }
    }());
  }

  Future<bool> sendRegistrationOtp(String emailOrPhone, bool isMobile) async {
    // OTP disabled (SMS + Email) temporarily.
    SweetAlertHelper.showWarning(Get.context, "OTP Disabled", "OTP verification is temporarily turned off.");
    return false;
  }

  /// Sends SMS OTP via backend (`send_login_otp`). Mobile login only.
  Future<bool> sendLoginOtp(
    String identifier,
    String emailOrPhone,
    bool isStudent,
  ) async {
    _pendingLoginOtp = _PendingLoginOtp(
      identifier: identifier,
      emailOrPhone: emailOrPhone,
      isStudent: isStudent,
    );
    isSendingLoginOtp.value = true;
    try {
      final response = await ApiService.sendLoginOtp(
        identifier: identifier,
        emailOrPhone: emailOrPhone,
        isStudent: isStudent,
      );
      final data = response.data;
      if (data == null || data is! Map) {
        _showRequestFailure(
          "Error",
          "No response from server",
          onRetry: _retrySendLoginOtp,
        );
        return false;
      }
      if (data['status'] == 'success') {
        final msg = data['message']?.toString() ?? "OTP sent";
        SweetAlertHelper.showSuccess(Get.context, "OTP", msg);
        return true;
      }
      final err = AuthInputValidators.friendlyLoginError(
        data['message']?.toString() ?? "Could not send OTP",
      );
      _showRequestFailure("OTP", err, onRetry: _retrySendLoginOtp);
      return false;
    } catch (e) {
      _showRequestFailure("Error", e.toString(), error: e, onRetry: _retrySendLoginOtp);
      return false;
    } finally {
      isSendingLoginOtp.value = false;
    }
  }

  void _retrySendLoginOtp() {
    final pending = _pendingLoginOtp;
    if (pending == null) return;
    unawaited(sendLoginOtp(
      pending.identifier,
      pending.emailOrPhone,
      pending.isStudent,
    ));
  }

  //Verify OTP
  bool verifyOtp(String enteredOtp) {
    // Check if OTP is expired (5 minutes)
    final now = DateTime.now();
    final difference = now.difference(otpSentTime.value);
    
    if (difference.inMinutes > 5) {
      SweetAlertHelper.showError(Get.context, "Expired", "OTP has expired. Please request a new one.");
      return false;
    }
    
    if (OtpService.verifyOtp(enteredOtp, sentOtp.value)) {
      return true;
    } else {
      SweetAlertHelper.showError(
        Get.context,
        "Invalid OTP",
        AuthInputValidators.loginCredentialsHint,
      );
      return false;
    }
  }

  // Updated Register with all fields
  Future<void> register(
    String name,
    String email,
    String phone,
    String password,
    String bio,
    String interests,
    bool isStudent,
    String? rollNumber,
    String? empNumber, {
    String? departmentClass,
  }) async {
    _pendingRegister = _PendingRegister(
      name: name,
      email: email,
      phone: phone,
      password: password,
      bio: bio,
      interests: interests,
      isStudent: isStudent,
      rollNumber: rollNumber,
      empNumber: empNumber,
      departmentClass: departmentClass,
    );
    isLoading.value = true;
    try {
      debugPrint('[Auth] register start');
      final response = await ApiService.register(
        name,
        email,
        phone,
        password,
        bio,
        interests,
        isStudent,
        rollNumber,
        empNumber,
        departmentClass: departmentClass,
      );
      
      final data = response.data;
      if (data == null) {
        _showRequestFailure("Error", "No response from server", onRetry: _retryRegister);
        return;
      }

      if (data is! Map) {
        _showRequestFailure("Error", "Invalid response format", onRetry: _retryRegister);
        return;
      }
      
      if (data['status'] == 'success') {
        registerErrorField.value = null;
        // Clear loading before any dialogs/navigation so the shared AuthController
        // is not left with isLoading=true under a stacked login route.
        isLoading.value = false;
        debugPrint('[Auth] register success — waiting for alert confirm before login');
        // Navigate only after the alert is dismissed, and clear the full stack
        // (Get.off left the previous Login under LoginBootstrap).
        SweetAlertHelper.showSuccess(
          Get.context,
          "Success",
          "Account created! Please login.",
          onConfirm: () {
            unawaited(
              AppNavigation.offAll(
                () => const LoginBootstrapView(),
                prepare: AppBootstrap.prepareLogin,
                loadingMessage: 'Preparing login...',
              ).catchError((Object e, StackTrace st) {
                debugPrint('[Auth] post-register navigation error: $e\n$st');
              }),
            );
          },
        );
      } else {
        // Prefer exact server message (field-specific duplicates, validation, etc.).
        final errorMsg =
            data['message']?.toString().trim().isNotEmpty == true
                ? data['message'].toString().trim()
                : "Registration failed";
        final field = data['field']?.toString().trim();
        registerErrorField.value =
            (field != null && field.isNotEmpty) ? field : null;
        final lower = errorMsg.toLowerCase();
        final isConflict = lower.contains('already') ||
            lower.contains('exist') ||
            (field != null && field.isNotEmpty);
        // Duplicates need a different input — retrying the same payload is useless.
        _showRequestFailure(
          "Registration Failed",
          errorMsg,
          onRetry: isConflict ? null : _retryRegister,
        );
      }
    } catch (e, st) {
      debugPrint("Registration error: $e\n$st");
      _showRequestFailure("Error", e.toString(), error: e, onRetry: _retryRegister);
    } finally {
      isLoading.value = false;
    }
  }

  void _retryRegister() {
    final pending = _pendingRegister;
    if (pending == null) return;
    unawaited(register(
      pending.name,
      pending.email,
      pending.phone,
      pending.password,
      pending.bio,
      pending.interests,
      pending.isStudent,
      pending.rollNumber,
      pending.empNumber,
      departmentClass: pending.departmentClass,
    ));
  }

  /// [otp]: when non-empty, backend uses SMS OTP (requires [byMobile] true). Otherwise [password] is used.
  Future<void> loginWithIdentifier(
    String identifier,
    String emailOrPhone,
    bool isStudent,
    bool byMobile, {
    String password = '',
    String? otp,
  }) async {
    _pendingLogin = _PendingLogin(
      identifier: identifier,
      emailOrPhone: emailOrPhone,
      isStudent: isStudent,
      byMobile: byMobile,
      password: password,
      otp: otp,
    );
    isLoading.value = true;
    try {
      debugPrint(
        '[Auth] login start byMobile=$byMobile isStudent=$isStudent '
        'hasOtp=${otp != null && otp.isNotEmpty}',
      );
      final response = await ApiService.loginWithIdentifier(
        identifier,
        emailOrPhone,
        isStudent,
        byMobile,
        password: password,
        otp: otp,
      );
      
      final data = response.data;
      debugPrint('[Auth] login response statusCode=${response.statusCode} data=$data');
      if (data == null) {
        _showRequestFailure("Error", "No response from server", onRetry: _retryLogin);
        return;
      }

      final parsed = ApiService.parseResponseBody(data);
      if (parsed == null) {
        _showRequestFailure("Error", "Invalid response format", onRetry: _retryLogin);
        return;
      }

      if (parsed['status']?.toString() == 'success') {
        final userIdRaw = parsed['user_id'];
        String userId = userIdRaw?.toString() ?? '';
        if (userId.isEmpty) {
          _showRequestFailure("Error", "Login response missing user_id", onRetry: _retryLogin);
          return;
        }
        String name = parsed['user_name']?.toString() ?? "User";
        String token = parsed['token']?.toString() ?? "";
        final isStudRaw = parsed['is_student'];
        final isStudentFromApi =
            isStudRaw == 1 || isStudRaw == true || isStudRaw == '1';

        // Fresh session prefs, then navigate; prepareHome registers controllers.
        await PrefService.clearProfileSession();
        await PrefService.saveUserSession(
          userId,
          name,
          token,
          isStudent: isStudentFromApi,
        );
        debugPrint('[Auth] session saved userId=$userId tokenLen=${token.length} isStudent=$isStudentFromApi');

        // Clear spinner before FCM / home prep — those must not block UI forever.
        isLoading.value = false;

        // FCM getToken()/topics can hang indefinitely on first cold path;
        // never await on the login critical path (force-close "fixes" it because
        // the token is then cached / init finished).
        _registerFcmInBackground(reason: 'post-login');

        final sessionEpoch = ++_authSessionEpoch;
        debugPrint('[Auth] navigating to home');
        await AppNavigation.offAll(
          () => const HomeBootstrapView(),
          prepare: (ctx) => AppBootstrap.prepareHome(ctx, sessionUserId: userId, sessionName: name),
          loadingMessage: 'Loading MiCampus...',
        );
        // Skip if logout (or another login) already invalidated this session.
        if (sessionEpoch != _authSessionEpoch) return;
        if (!(await PrefService.isLoggedIn())) return;
        SweetAlertHelper.showSuccess(Get.context, "Success", "Welcome back, $name!");
      } else {
        // Show the server message as-is (e.g. wrong credentials).
        final apiMsg = parsed['message']?.toString().trim();
        final errorMsg = (apiMsg != null && apiMsg.isNotEmpty)
            ? apiMsg
            : AuthInputValidators.loginCredentialsHint;
        _showRequestFailure("Login Failed", errorMsg, onRetry: _retryLogin);
      }
    } catch (e, st) {
      debugPrint("Login error: $e\n$st");
      _showRequestFailure("Error", e.toString(), error: e, onRetry: _retryLogin);
    } finally {
      isLoading.value = false;
    }
  }

  void _retryLogin() {
    final pending = _pendingLogin;
    if (pending == null) return;
    unawaited(loginWithIdentifier(
      pending.identifier,
      pending.emailOrPhone,
      pending.isStudent,
      pending.byMobile,
      password: pending.password,
      otp: pending.otp,
    ));
  }

  var isSendingForgotOtp = false.obs;

  /// Inline / step error from the last forgot-password API call.
  final forgotPasswordError = RxnString();

  /// Channel + masked destination from request_otp (for UI).
  final forgotOtpChannel = RxnString();
  final forgotOtpMasked = RxnString();
  final forgotResetToken = RxnString();

  void clearForgotPasswordState() {
    forgotPasswordError.value = null;
    forgotOtpChannel.value = null;
    forgotOtpMasked.value = null;
    forgotResetToken.value = null;
    isSendingForgotOtp.value = false;
  }

  /// Step 1 — request OTP. Returns true on success.
  Future<bool> requestForgotPasswordOtp(String identifier) async {
    forgotPasswordError.value = null;
    isLoading.value = true;
    try {
      final response = await ApiService.requestForgotPasswordOtp(identifier);
      final data = ApiService.parseResponseBody(response.data);
      if (data == null) {
        forgotPasswordError.value = 'No response from server';
        _showRequestFailure('Error', forgotPasswordError.value!);
        return false;
      }
      if (data['status'] == 'success') {
        forgotOtpChannel.value = data['channel']?.toString();
        forgotOtpMasked.value = data['masked']?.toString();
        otpSentTime.value = DateTime.now();
        return true;
      }
      final err = data['message']?.toString() ?? 'Failed to send OTP';
      forgotPasswordError.value = err;
      _showRequestFailure('Error', err);
      return false;
    } catch (e, st) {
      debugPrint('Forgot password request OTP error: $e\n$st');
      forgotPasswordError.value = e.toString();
      _showRequestFailure('Error', e.toString(), error: e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Resend OTP (same as request) — uses [isSendingForgotOtp] for cooldown UI.
  Future<bool> resendForgotPasswordOtp(String identifier) async {
    forgotPasswordError.value = null;
    isSendingForgotOtp.value = true;
    try {
      final response = await ApiService.requestForgotPasswordOtp(identifier);
      final data = ApiService.parseResponseBody(response.data);
      if (data == null) {
        forgotPasswordError.value = 'No response from server';
        _showRequestFailure('Error', forgotPasswordError.value!);
        return false;
      }
      if (data['status'] == 'success') {
        forgotOtpChannel.value = data['channel']?.toString();
        forgotOtpMasked.value = data['masked']?.toString();
        otpSentTime.value = DateTime.now();
        final msg = data['message']?.toString() ?? 'OTP resent';
        SweetAlertHelper.showSuccess(Get.context, 'OTP', msg);
        return true;
      }
      final err = data['message']?.toString() ?? 'Could not resend OTP';
      forgotPasswordError.value = err;
      _showRequestFailure('OTP', err);
      return false;
    } catch (e, st) {
      debugPrint('Forgot password resend OTP error: $e\n$st');
      forgotPasswordError.value = e.toString();
      _showRequestFailure('Error', e.toString(), error: e);
      return false;
    } finally {
      isSendingForgotOtp.value = false;
    }
  }

  /// Step 2 — verify OTP. Returns true and stores [forgotResetToken] on success.
  Future<bool> verifyForgotPasswordOtp({
    required String identifier,
    required String otp,
  }) async {
    forgotPasswordError.value = null;
    isLoading.value = true;
    try {
      final response = await ApiService.verifyForgotPasswordOtp(
        identifier: identifier,
        otp: otp,
      );
      final data = ApiService.parseResponseBody(response.data);
      if (data == null) {
        forgotPasswordError.value = 'No response from server';
        _showRequestFailure('Error', forgotPasswordError.value!);
        return false;
      }
      if (data['status'] == 'success') {
        final token = data['reset_token']?.toString();
        if (token == null || token.isEmpty) {
          forgotPasswordError.value = 'Reset token missing from server';
          _showRequestFailure('Error', forgotPasswordError.value!);
          return false;
        }
        forgotResetToken.value = token;
        return true;
      }
      final err = data['message']?.toString() ?? 'Invalid OTP';
      forgotPasswordError.value = err;
      _showRequestFailure('Error', err);
      return false;
    } catch (e, st) {
      debugPrint('Forgot password verify OTP error: $e\n$st');
      forgotPasswordError.value = e.toString();
      _showRequestFailure('Error', e.toString(), error: e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Step 3 — set new password. On success navigates back to login.
  Future<bool> resetPasswordWithToken({
    required String password,
    required String passwordConfirm,
  }) async {
    forgotPasswordError.value = null;
    final token = forgotResetToken.value;
    if (token == null || token.isEmpty) {
      forgotPasswordError.value = 'Session expired. Please request a new OTP.';
      _showRequestFailure('Error', forgotPasswordError.value!);
      return false;
    }
    isLoading.value = true;
    try {
      final response = await ApiService.resetPasswordWithToken(
        resetToken: token,
        password: password,
        passwordConfirm: passwordConfirm,
      );
      final data = ApiService.parseResponseBody(response.data);
      if (data == null) {
        forgotPasswordError.value = 'No response from server';
        _showRequestFailure('Error', forgotPasswordError.value!);
        return false;
      }
      if (data['status'] == 'success') {
        final msg = data['message']?.toString() ?? 'Password reset successfully';
        clearForgotPasswordState();
        Get.back();
        final ctx = Get.context;
        if (ctx != null) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          SweetAlertHelper.showSuccess(Get.context, 'Success', msg);
        }
        return true;
      }
      final err = data['message']?.toString() ?? 'Failed to reset password';
      forgotPasswordError.value = err;
      _showRequestFailure('Error', err);
      return false;
    } catch (e, st) {
      debugPrint('Forgot password reset error: $e\n$st');
      forgotPasswordError.value = e.toString();
      _showRequestFailure('Error', e.toString(), error: e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Logout — clear session first, show loader, leave Home, THEN delete controllers.
  Future<void> logout() async {
    // Invalidate any pending post-login "Welcome back" before navigation.
    _authSessionEpoch++;
    // Never leave isLoading=true across logout → login. LoginView reuses this
    // AuthController and binds the submit button to the same flag; AppNavigation
    // already shows the "Logging out..." overlay.
    isLoading.value = false;
    isSendingLoginOtp.value = false;

    // Drop leftover snackbars / dialogs from the previous session.
    try {
      Get.closeAllSnackbars();
      while (Get.isDialogOpen == true) {
        Get.back();
      }
    } catch (e) {
      debugPrint('[Auth] logout overlay cleanup: $e');
    }

    // Wipe in-memory + persisted session BEFORE navigating to login.
    if (Get.isRegistered<ProfileController>()) {
      Get.find<ProfileController>().resetProfileState();
    }
    await PrefService.clearProfileSession();

    // FCM token delete / topic unsubscribe can hang — never block logout UI on it.
    unawaited(() async {
      try {
        await NotificationService.onLogout().timeout(
          const Duration(seconds: 8),
          onTimeout: () {
            debugPrint('[Auth] NotificationService.onLogout timed out');
          },
        );
      } catch (e, st) {
        debugPrint('[Auth] logout FCM cleanup error: $e\n$st');
      }
    }());

    try {
      await AppNavigation.offAll(
        () => const LoginBootstrapView(),
        prepare: AppBootstrap.prepareLogin,
        loadingMessage: 'Logging out...',
      );
      // Home is gone — safe to drop GetX home controllers.
      await AppBootstrap.clearHomeControllers();
    } finally {
      isLoading.value = false;
      isSendingLoginOtp.value = false;
    }
  }
}
