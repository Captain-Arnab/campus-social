import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../data/api_service.dart';
import '../data/pref_service.dart';
import '../views/home_view.dart';
import '../views/login_view.dart';
import '../data/otp_service.dart';

class AuthController extends GetxController {
  var isLoading = false.obs;
  var sentOtp = ''.obs;
  var otpSentTime = DateTime.now().obs;

  Future<bool> sendRegistrationOtp(String emailOrPhone, bool isMobile) async {
    // OTP disabled (SMS + Email) temporarily.
    Get.snackbar(
      "OTP Disabled",
      "OTP verification is temporarily turned off.",
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
    return false;
  }

  //Send OTP for Login
  Future<bool> sendLoginOtp(String emailOrPhone, bool isMobile) async {
    // OTP disabled (SMS + Email) temporarily.
    Get.snackbar(
      "OTP Disabled",
      "OTP verification is temporarily turned off.",
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
    return false;
  }

  //Verify OTP
  bool verifyOtp(String enteredOtp) {
    // Check if OTP is expired (5 minutes)
    final now = DateTime.now();
    final difference = now.difference(otpSentTime.value);
    
    if (difference.inMinutes > 5) {
      Get.snackbar(
        "Expired",
        "OTP has expired. Please request a new one.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
    
    if (OtpService.verifyOtp(enteredOtp, sentOtp.value)) {
      return true;
    } else {
      Get.snackbar(
        "Invalid OTP",
        "The OTP you entered is incorrect.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
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
        Get.snackbar("Error", "No response from server");
        return;
      }

      if (data is! Map) {
        Get.snackbar("Error", "Invalid response format");
        return;
      }
      
      if (data['status'] == 'success') {
        Get.snackbar(
          "Success",
          "Account created! Please login.",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        Get.off(() => const LoginView());
      } else {
        String errorMsg = data['message']?.toString() ?? "Registration failed";
        Get.snackbar("Registration Failed", errorMsg, backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      debugPrint("Registration error: $e");
      Get.snackbar("Error", "Connection failed: ${e.toString()}", backgroundColor: Colors.red, colorText: Colors.white);
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
        Get.snackbar("Error", "No response from server");
        return;
      }

      if (data is! Map) {
        Get.snackbar("Error", "Invalid response format");
        return;
      }

      if (data['status'] == 'success') {
        String userId = data['user_id'].toString();
        String name = data['user_name']?.toString() ?? "User";
        String token = data['token']?.toString() ?? "";

        await PrefService.saveUserSession(userId, name, token);
        
        Get.offAll(() => const HomeView());
        Get.snackbar(
          "Success",
          "Welcome back, $name!",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        String errorMsg = data['message']?.toString() ?? "Unknown error";
        Get.snackbar("Login Failed", errorMsg, backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      debugPrint("Login error: $e");
      Get.snackbar("Error", "Connection failed: ${e.toString()}", backgroundColor: Colors.red, colorText: Colors.white);
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
        Get.snackbar("Error", "No response from server");
        return;
      }

      if (data is! Map) {
        Get.snackbar("Error", "Invalid response format");
        return;
      }

      if (data['status'] == 'success') {
        Get.back();
        String msg = data['message']?.toString() ?? "Password reset email sent";
        Get.snackbar("Success", msg, backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        String errorMsg = data['message']?.toString() ?? "Failed to process request";
        Get.snackbar("Error", errorMsg, backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      debugPrint("Forgot password error: $e");
      Get.snackbar("Error", "Failed to process request: ${e.toString()}", backgroundColor: Colors.red, colorText: Colors.white);
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