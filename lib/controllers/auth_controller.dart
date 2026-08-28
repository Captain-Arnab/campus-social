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
    } catch (e, st) {
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
        final rawMsg = data['message']?.toString() ?? "Registration failed";
        String errorMsg = rawMsg;
        final lower = rawMsg.toLowerCase();
        if (lower.contains('already') ||
            lower.contains('exist') ||
            (lower.contains('email') && lower.contains('phone'))) {
          // Disambiguate email vs phone when API returns a combined message.
          try {
            final check = await ApiService.checkRegistrationAvailability(
              email: email,
              phone: phone,
            );
            errorMsg = ApiService.friendlyRegisterConflictMessage(
              rawMsg,
              emailTaken: check.emailTaken,
              // Combined API message + email free ⇒ phone is the conflict.
              phoneTaken: check.phoneTaken ??
                  (check.emailTaken == false ? true : null),
            );
          } catch (_) {
            errorMsg = ApiService.friendlyRegisterConflictMessage(rawMsg);
          }
        }
        _showRequestFailure("Registration Failed", errorMsg, onRetry: _retryRegister);
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

        debugPrint('[Auth] navigating to home');
        await AppNavigation.offAll(
          () => const HomeBootstrapView(),
          prepare: (ctx) => AppBootstrap.prepareHome(ctx, sessionUserId: userId, sessionName: name),
          loadingMessage: 'Loading MiCampus...',
        );
        // Drop any leftover prior-user controllers only after Home is up with fresh ones.
        // prepareHome already replaced ProfileController; EventController was re-put.
        SweetAlertHelper.showSuccess(Get.context, "Success", "Welcome back, $name!");
      } else {
        String errorMsg = AuthInputValidators.friendlyLoginError(
          parsed['message']?.toString(),
        );
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

  // Forgot Password
  Future<void> forgotPassword(String email) async {
    isLoading.value = true;
    try {
      final response = await ApiService.forgotPassword(email);
      
      final data = response.data;
      if (data == null) {
        SweetAlertHelper.showError(Get.context, "Error", "No response from server");
        return;
      }

      if (data is! Map) {
        SweetAlertHelper.showError(Get.context, "Error", "Invalid response format");
        return;
      }

      if (data['status'] == 'success') {
        Get.back();
        String msg = data['message']?.toString() ?? "Password reset email sent";
        SweetAlertHelper.showSuccess(Get.context, "Success", msg);
      } else {
        String errorMsg = data['message']?.toString() ?? "Failed to process request";
        _showRequestFailure("Error", errorMsg);
      }
    } catch (e, st) {
      debugPrint("Forgot password error: $e\n$st");
      _showRequestFailure("Error", e.toString(), error: e);
    } finally {
      isLoading.value = false;
    }
  }

  // Logout — clear prefs, leave Home, THEN delete controllers (avoids Get.find crashes).
  Future<void> logout() async {
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
    await PrefService.clearProfileSession();
    await AppNavigation.offAll(
      () => const LoginBootstrapView(),
      prepare: AppBootstrap.prepareLogin,
      loadingMessage: 'Preparing login...',
    );
    // Home is gone — safe to drop GetX home controllers.
    await AppBootstrap.clearHomeControllers();
  }
}
