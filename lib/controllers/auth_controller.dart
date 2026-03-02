import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../data/api_service.dart';
import '../data/pref_service.dart';
import '../services/notification_service.dart';
import '../utils/sweetalert_helper.dart';
import '../views/home_view.dart';
import '../views/login_view.dart';
import '../data/otp_service.dart';

class AuthController extends GetxController {
  var isLoading = false.obs;
  var sentOtp = ''.obs;
  var otpSentTime = DateTime.now().obs;

  Future<bool> sendRegistrationOtp(String emailOrPhone, bool isMobile) async {
    // OTP disabled (SMS + Email) temporarily.
    SweetAlertHelper.showWarning(Get.context, "OTP Disabled", "OTP verification is temporarily turned off.");
    return false;
  }

  //Send OTP for Login
  Future<bool> sendLoginOtp(String emailOrPhone, bool isMobile) async {
    // OTP disabled (SMS + Email) temporarily.
    SweetAlertHelper.showWarning(Get.context, "OTP Disabled", "OTP verification is temporarily turned off.");
    return false;
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
    String? empNumber,
  ) async {
    isLoading.value = true;
    try {
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
        SweetAlertHelper.showSuccess(Get.context, "Success", "Account created! Please login.");
        Get.off(() => const LoginView());
      } else {
        String errorMsg = data['message']?.toString() ?? "Registration failed";
        SweetAlertHelper.showError(Get.context, "Registration Failed", errorMsg);
      }
    } catch (e) {
      debugPrint("Registration error: $e");
      SweetAlertHelper.showError(Get.context, "Error", "Connection failed: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  // Updated Login with identifier (roll/emp), email/phone, and role
  Future<void> loginWithIdentifier(
    String identifier,
    String emailOrPhone,
    String password,
    bool isStudent,
    bool byMobile,
  ) async {
    isLoading.value = true;
    try {
      final response = await ApiService.loginWithIdentifier(
        identifier,
        emailOrPhone,
        password,
        isStudent,
        byMobile,
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
        String userId = data['user_id'].toString();
        String name = data['user_name']?.toString() ?? "User";
        String token = data['token']?.toString() ?? "";

        await PrefService.saveUserSession(userId, name, token);
        await NotificationService.registerTokenWithBackend();

        Get.offAll(() => const HomeView());
        SweetAlertHelper.showSuccess(Get.context, "Success", "Welcome back, $name!");
      } else {
        String errorMsg = data['message']?.toString() ?? "Unknown error";
        SweetAlertHelper.showError(Get.context, "Login Failed", errorMsg);
      }
    } catch (e) {
      debugPrint("Login error: $e");
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
    } catch (e) {
      debugPrint("Forgot password error: $e");
      SweetAlertHelper.showError(Get.context, "Error", "Failed to process request: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  // Logout
  Future<void> logout() async {
    await PrefService.clearSession();
    Get.offAll(() => const LoginView());
  }
}