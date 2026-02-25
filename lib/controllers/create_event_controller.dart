import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../data/api_service.dart';
import '../data/pref_service.dart';
import '../utils/sweetalert_helper.dart';
import 'event_controller.dart';

class CreateEventController extends GetxController {
  // Loading state
  var isLoading = false.obs;

  // Text Controllers
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController venueController = TextEditingController();
  
  // Image Management
  final ImagePicker _picker = ImagePicker();
  // We allow up to 5 images for the 'banners[]' array
  RxList<File?> selectedImages = RxList<File?>.filled(5, null);

  // --- Image Handling ---
  Future<void> pickImage(int index) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Compressing for faster upload
      );
      
      if (image != null) {
        selectedImages[index] = File(image.path);
        update();
      }
    } catch (e) {
      SweetAlertHelper.showError(Get.context, "Error", "Failed to pick image");
    }
  }

  void removeImage(int index) {
    selectedImages[index] = null;
    update();
  }

  // --- Publish Logic ---
  // FIXED: Renamed from publishEvent to createEvent to match UI calls
  Future<bool> createEvent(String category) async {
    // Validation
    if (titleController.text.isEmpty || 
        dateController.text.isEmpty || 
        venueController.text.isEmpty) {
      SweetAlertHelper.showError(Get.context, "Required Fields", "Please fill in Title, Date, and Venue");
      return false;
    }

    String? userId = await PrefService.getUserId();
    if (userId == null) {
      SweetAlertHelper.showError(Get.context, "Session Error", "Please log in again");
      return false;
    }

    // Prepare files (remove null entries)
    List<File> imagesToUpload = selectedImages.whereType<File>().toList();

    isLoading.value = true;
    try {
      final response = await ApiService.createEvent({
        "user_id": userId,
        "title": titleController.text.trim(),
        "description": descController.text.trim(),
        "event_date": dateController.text.trim(),
        "category": category,
        "venue": venueController.text.trim(),
      }, imagesToUpload);

      if (response.data['status'] == 'success') {
        SweetAlertHelper.showSuccess(Get.context, "Success 🎉", "Event submitted for admin approval!");
        
        _resetForm();
        
        // Refresh the main event list if the EventController is in memory
        if (Get.isRegistered<EventController>()) {
          Get.find<EventController>().fetchEvents();
        }
        
        return true;
      } else {
        SweetAlertHelper.showError(Get.context, "Error", response.data['message'] ?? "Failed to create event");
        return false;
      }
    } catch (e) {
      debugPrint("Create Event API Error: $e");
      SweetAlertHelper.showError(Get.context, "Connection Error", "Could not reach the server");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void _resetForm() {
    titleController.clear();
    descController.clear();
    dateController.clear();
    venueController.clear();
    selectedImages.value = List.filled(5, null);
    update();
  }

  @override
  void onClose() {
    titleController.dispose();
    descController.dispose();
    dateController.dispose();
    venueController.dispose();
    super.onClose();
  }
}