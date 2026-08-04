import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/api_service.dart';
import '../data/app_bootstrap.dart';
import '../data/otp_service.dart';
import '../data/pref_service.dart';
import '../services/notification_service.dart';
import '../utils/app_navigation.dart';
import '../utils/sweetalert_helper.dart';
import '../views/bootstrap_views.dart';

class AuthController extends GetxController {
  var isLoading = false.obs;
  var isSendingLoginOtp = false.obs;
  var sentOtp = ''.obs;
  var otpSentTime = DateTime.now().obs;

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
    isSendingLoginOtp.value = true;
    try {
      final response = await ApiService.sendLoginOtp(
        identifier: identifier,
        emailOrPhone: emailOrPhone,
        isStudent: isStudent,
      );
      final data = response.data;
      if (data == null || data is! Map) {
        SweetAlertHelper.showError(Get.context, "Error", "No response from server");
        return false;
      }
      if (data['status'] == 'success') {
        final msg = data['message']?.toString() ?? "OTP sent";
        SweetAlertHelper.showSuccess(Get.context, "OTP", msg);
        return true;
      }
      final err = data['message']?.toString() ?? "Could not send OTP";
      SweetAlertHelper.showError(Get.context, "OTP", err);
      return false;
    } catch (e, st) {
      debugPrint("sendLoginOtp error: $e\n$st");
      SweetAlertHelper.showError(Get.context, "Error", "Connection failed: ${e.toString()}");
      return false;
    } finally {
      isSendingLoginOtp.value = false;
    }
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
      SweetAlertHelper.showError(Get.context, "Invalid OTP", "The OTP you entered is incorrect.");
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
        SweetAlertHelper.showError(Get.context, "Error", "No response from server");
        return;
      }

      if (data is! Map) {
        SweetAlertHelper.showError(Get.context, "Error", "Invalid response format");
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
        String errorMsg = data['message']?.toString() ?? "Registration failed";
        SweetAlertHelper.showError(Get.context, "Registration Failed", errorMsg);
      }
    } catch (e, st) {
      debugPrint("Registration error: $e\n$st");
      SweetAlertHelper.showError(Get.context, "Error", "Connection failed: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
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
        SweetAlertHelper.showError(Get.context, "Error", "No response from server");
        return;
      }

      if (data is! Map) {
        SweetAlertHelper.showError(Get.context, "Error", "Invalid response format");
        return;
      }

      if (data['status'] == 'success') {
        String userId = data['user_id'].toString();
        String name = data['user_name']?.toString() ?? "User";
        String token = data['token']?.toString() ?? "";

        await PrefService.saveUserSession(userId, name, token, isStudent: isStudent);
        debugPrint('[Auth] session saved userId=$userId tokenLen=${token.length}');

        // Clear spinner before FCM / home prep — those must not block UI forever.
        isLoading.value = false;

        // FCM getToken()/topics can hang indefinitely on first cold path;
        // never await on the login critical path (force-close "fixes" it because
        // the token is then cached / init finished).
        _registerFcmInBackground(reason: 'post-login');

        debugPrint('[Auth] navigating to home');
        await AppNavigation.offAll(
          () => const HomeBootstrapView(),
          prepare: AppBootstrap.prepareHome,
          loadingMessage: 'Loading MiCampus...',
        );
        SweetAlertHelper.showSuccess(Get.context, "Success", "Welcome back, $name!");
      } else {
        String errorMsg = data['message']?.toString() ?? "Unknown error";
        SweetAlertHelper.showError(Get.context, "Login Failed", errorMsg);
      }
    } catch (e, st) {
      debugPrint("Login error: $e\n$st");
      SweetAlertHelper.showError(Get.context, "Error", "Connection failed: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
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
        SweetAlertHelper.showError(Get.context, "Error", errorMsg);
      }
    } catch (e, st) {
      debugPrint("Forgot password error: $e\n$st");
      SweetAlertHelper.showError(Get.context, "Error", "Failed to process request: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  // Logout
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
    await PrefService.clearSession();
    await AppNavigation.offAll(
      () => const LoginBootstrapView(),
      prepare: AppBootstrap.prepareLogin,
      loadingMessage: 'Preparing login...',
    );
  }
}
