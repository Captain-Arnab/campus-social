import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/api_service.dart';
import '../data/pref_service.dart';
import '../utils/sweetalert_helper.dart';
import '../modal/model_user.dart';

class ProfileController extends GetxController {
  var isLoading = false.obs;
  var userData = ModelUser().obs;
  var createdCount = 0.obs;
  var attendedCount = 0.obs;
  var favoritesCount = 0.obs; // ADDED: Favorites count
  var volunteeringCount = 0.obs; // ADDED: Volunteering count
  var participatingCount = 0.obs;

  @override
  void onInit() {
    loadProfile();
    super.onInit();
  }

  Future<void> loadProfile() async {
    String? userId = await PrefService.getUserId();
    if (userId == null) {
      debugPrint("✗ User ID not found in preferences");
      return;
    }
    
    isLoading.value = true;
    try {
      debugPrint("📱 Loading profile for user: $userId");
      final response = await ApiService.getUserProfile(userId);
      
      debugPrint("🔵 Profile API response: ${response.data}");
      
      if (response.data['status'] == 'success') {
        userData.value = ModelUser.fromJson(response.data['data']);
        
        // UPDATED: Parse all stats including favorites and volunteering
        if (response.data['stats'] != null) {
          createdCount.value = int.tryParse(response.data['stats']['created'].toString()) ?? 0;
          attendedCount.value = int.tryParse(response.data['stats']['attended'].toString()) ?? 0;
          favoritesCount.value = int.tryParse(response.data['stats']['favorites'].toString()) ?? 0;
          volunteeringCount.value = int.tryParse(response.data['stats']['volunteering'].toString()) ?? 0;
          participatingCount.value = int.tryParse(response.data['stats']['participating'].toString()) ?? 0;
        }
        
        debugPrint("✓ Profile loaded successfully");
        debugPrint("  - Name: ${userData.value.fullName}");
        debugPrint("  - Email: ${userData.value.email}");
        debugPrint("  - Image: ${userData.value.image}");
        debugPrint("  - Events Created: ${createdCount.value}");
        debugPrint("  - Events Attended: ${attendedCount.value}");
        debugPrint("  - Favorites: ${favoritesCount.value}");
        debugPrint("  - Volunteering: ${volunteeringCount.value}");
        debugPrint("  - Participating: ${participatingCount.value}");
      } else {
        debugPrint("✗ API error: ${response.data['message']}");
      }
    } catch (e) {
      debugPrint("✗ Profile fetch error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Switch student ↔ faculty (`users.php?action=switch_role`). Updates session role on success.
  Future<bool> switchAccountType({
    required String password,
    required bool becomeStudent,
    String? rollNumber,
    String? empNumber,
  }) async {
    final userId = await PrefService.getUserId();
    final token = await PrefService.getToken();
    if (userId == null || token == null || token.isEmpty) {
      SweetAlertHelper.showError(Get.context, "Error", "Please log in again.");
      return false;
    }
    isLoading.value = true;
    try {
      final r = await ApiService.switchUserRole(
        userId: userId,
        password: password,
        newIsStudent: becomeStudent ? 1 : 0,
        rollNumber: rollNumber,
        empNumber: empNumber,
      );
      final data = r.data;
      if (data is Map && data['status'] == 'success') {
        final name = userData.value.fullName ?? 'User';
        await PrefService.saveUserSession(userId, name, token, isStudent: becomeStudent);
        await loadProfile();
        SweetAlertHelper.showSuccess(
          Get.context,
          "Success",
          data['message']?.toString() ?? "Account type updated.",
        );
        return true;
      }
      final msg = data is Map ? (data['message']?.toString() ?? "Could not switch role") : "Could not switch role";
      SweetAlertHelper.showError(Get.context, "Error", msg);
      return false;
    } catch (e) {
      debugPrint("switchAccountType: $e");
      SweetAlertHelper.showError(Get.context, "Error", "Connection failed.");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateProfile(String name, String bio, String interests, File? image, {String? departmentClass}) async {
    isLoading.value = true;
    try {
      String? userId = await PrefService.getUserId();
      if (userId == null) {
        SweetAlertHelper.showError(Get.context, "Error", "User not found. Please login again");
        return false;
      }
      
      // Update details. The backend (users.php → update_details) saves only the
      // fields actually sent, so include full_name too — otherwise name edits were
      // silently dropped (issue: profile not saving).
      final Map<String, dynamic> body = {
        "user_id": userId,
        "full_name": name.trim(),
        "interests": interests,
        "bio": bio,
      };
      if (departmentClass != null) {
        body["department_class"] = departmentClass.trim();
      }
      await ApiService.updateProfile(body);
      
      // Update image if selected
      if (image != null) {
        await ApiService.uploadProfilePic(userId, image);
      }
      
      await loadProfile();
      SweetAlertHelper.showSuccess(Get.context, "Success", "Profile updated successfully!");
      // Delay slightly before navigating back so user can dismiss alert
      await Future.delayed(const Duration(milliseconds: 500));
      Get.back();
      return true;
    } catch (e) {
      SweetAlertHelper.showError(Get.context, "Error", "Failed to update profile. Please try again.");
      debugPrint("Profile update error: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}