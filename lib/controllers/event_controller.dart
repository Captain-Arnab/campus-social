import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/api_service.dart';
import '../data/pref_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

class EventController extends GetxController {
  var isLoading = false.obs;
  var eventList = <dynamic>[].obs;
  var favoriteList = <dynamic>[].obs;
  var attendingList = <dynamic>[].obs;
  var volunteeringList = <dynamic>[].obs;
  var participatingList = <dynamic>[].obs;
  var hostedList = <dynamic>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchEvents();
    fetchFavorites();
    fetchAttendingEvents();
    fetchVolunteeringEvents();
    fetchHostedEvents();
    fetchParticipatingEvents();
  }

  Future<void> fetchEvents({String? search, String? category}) async {
    isLoading.value = true;
    try {
      final response = await ApiService.getEvents(search: search, category: category);
      if (response.data['status'] == 'success') {
        final data = response.data['data'] as List?;
        if (data != null) {
          eventList.value = data;
          debugPrint("✓ Loaded ${data.length} events");
        }
      }
    } catch (e) {
      debugPrint("✗ Fetch error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchFavorites() async {
    try {
      final response = await ApiService.getFavorites();
      if (response.data['status'] == 'success') {
        final data = response.data['data'] as List?;
        if (data != null) {
          favoriteList.value = data;
          debugPrint("✓ Loaded ${data.length} favorites");
        }
      }
    } catch (e) {
      debugPrint("✗ Favorites fetch error: $e");
    }
  }

  Future<void> fetchAttendingEvents() async {
    try {
      String? userId = await PrefService.getUserId();
      if (userId == null) {
        debugPrint("✗ User ID not found for attending events");
        return;
      }
      
      final response = await ApiService.getAttendingEvents();
      if (response.data['status'] == 'success') {
        final data = response.data['data'] as List?;
        if (data != null) {
          attendingList.value = data;
          debugPrint("✓ Loaded ${data.length} attending events for user $userId");
        } else {
          attendingList.value = [];
          debugPrint("✓ No attending events found");
        }
      } else {
        debugPrint("✗ API returned error: ${response.data['message']}");
      }
    } catch (e) {
      debugPrint("✗ Attending fetch error: $e");
      attendingList.value = [];
    }
  }

  Future<void> fetchVolunteeringEvents() async {
    try {
      String? userId = await PrefService.getUserId();
      if (userId == null) {
        debugPrint("✗ User ID not found for volunteering events");
        return;
      }
      
      final response = await ApiService.getVolunteeringEvents();
      if (response.data['status'] == 'success') {
        final data = response.data['data'] as List?;
        if (data != null) {
          volunteeringList.value = data;
          debugPrint("✓ Loaded ${data.length} volunteering events for user $userId");
        } else {
          volunteeringList.value = [];
          debugPrint("✓ No volunteering events found");
        }
      } else {
        debugPrint("✗ API returned error: ${response.data['message']}");
      }
    } catch (e) {
      debugPrint("✗ Volunteering fetch error: $e");
      volunteeringList.value = [];
    }
  }
  Future<void> fetchParticipatingEvents() async {
    try {
      String? userId = await PrefService.getUserId();
      if (userId == null) {
        debugPrint("✗ User ID not found for participating events");
        return;
      }
      
      final response = await ApiService.getParticipatingEvents();
      if (response.data['status'] == 'success') {
        final data = response.data['data'] as List?;
        if (data != null) {
          participatingList.value = data;
          debugPrint("✓ Loaded ${data.length} participating events for user $userId");
        } else {
          participatingList.value = [];
          debugPrint("✓ No participating events found");
        }
      } else {
        debugPrint("✗ API returned error: ${response.data['message']}");
      }
    } catch (e) {
      debugPrint("✗ Participating fetch error: $e");
      participatingList.value = [];
    }
  }

  Future<void> participate(String eventId) async {
    isLoading.value = true;
    try {
      String? userId = await PrefService.getUserId();
      
      if (userId == null) {
        Get.snackbar("Error", "User not found. Please login again", 
          backgroundColor: Colors.red, colorText: Colors.white);
        isLoading.value = false;
        return;
      }
      
      debugPrint("Participant data: event=$eventId, user=$userId");
      
      final response = await ApiService.joinParticipant({
        "event_id": eventId,
        "user_id": userId,
      });
      
      debugPrint("Participant response: ${response.data}");
      
      if (response.statusCode != null && response.statusCode! >= 400) {
        Get.snackbar(
          "Server Error",
          "Server returned error ${response.statusCode}. Please contact support.",
          backgroundColor: Colors.red,
          colorText: Colors.white
        );
        isLoading.value = false;
        return;
      }
      
      if (response.data == null) {
        Get.snackbar(
          "Error",
          "Invalid response from server. Please try again.",
          backgroundColor: Colors.red,
          colorText: Colors.white
        );
        isLoading.value = false;
        return;
      }
      
      final status = response.data['status'] ?? 'error';
      final message = response.data['message'] ?? 'Unknown error occurred';
      
      if (status == 'success') {
        Get.back();
        fetchParticipatingEvents();
        Get.snackbar(
          "Success", 
          "Successfully registered as participant!",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3)
        );
      } else {
        Get.snackbar(
          "Error",
          message,
          backgroundColor: Colors.red,
          colorText: Colors.white
        );
      }
    } catch (e) {
      debugPrint("Participant exception: $e");
      Get.snackbar(
        "Error",
        "Participation registration failed: ${e.toString()}",
        backgroundColor: Colors.red,
        colorText: Colors.white
      );
    } finally {
      isLoading.value = false;
    }
  }

Future<void> fetchHostedEvents({bool forceRefresh = false}) async {
  // Remove the isEmpty check or make it optional
  try {
    String? userId = await PrefService.getUserId();
    if (userId == null) {
      debugPrint("✗ User ID not found for hosted events");
      return;
    }
    
    final response = await ApiService.getHostedEvents();
    if (response.data['status'] == 'success') {
      final data = response.data['data'] as List?;
      if (data != null) {
        hostedList.value = data;
        debugPrint("✓ Loaded ${data.length} hosted events for user $userId");
        debugPrint("✓ FULL DATA: $data");
      } else {
        hostedList.value = [];
        debugPrint("✓ No hosted events found");
      }
    } else {
      debugPrint("✗ API returned error: ${response.data['message']}");
    }
  } catch (e) {
    debugPrint("✗ Hosted fetch error: $e");
    hostedList.value = [];
  }
}

  bool _isPending(dynamic event) {
    final status = (event is Map ? event['status'] : null)?.toString().toLowerCase() ?? '';
    return status == 'pending';
  }

  Future<void> updateHostedEvent({
    required dynamic event,
    required String title,
    required String description,
    required String venue,
  }) async {
    // Only pending events can be modified
    if (!_isPending(event)) {
      Get.snackbar(
        "Not Allowed",
        "Approved events cannot be modified.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final idRaw = (event is Map) ? event['id'] : null;
    final id = (idRaw is int) ? idRaw : int.tryParse(idRaw?.toString() ?? '');
    if (id == null) {
      Get.snackbar(
        "Error",
        "Invalid event id.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    try {
      final response = await ApiService.updateEvent(
        id: id,
        title: title,
        description: description,
        venue: venue,
      );

      final data = response.data;
      if (data is Map && data['status'] == 'success') {
        Get.snackbar(
          "Success",
          data['message']?.toString() ?? "Event updated",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        await fetchHostedEvents(forceRefresh: true);
        await fetchEvents();
      } else {
        Get.snackbar(
          "Error",
          (data is Map ? data['message'] : null)?.toString() ?? "Failed to update event",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint("Update event error: $e");
      Get.snackbar(
        "Error",
        "Failed to update event.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteHostedEvent({required dynamic event}) async {
    // Only pending events can be deleted
    if (!_isPending(event)) {
      Get.snackbar(
        "Not Allowed",
        "Approved events cannot be deleted.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final idRaw = (event is Map) ? event['id'] : null;
    final id = (idRaw is int) ? idRaw : int.tryParse(idRaw?.toString() ?? '');
    if (id == null) {
      Get.snackbar(
        "Error",
        "Invalid event id.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    try {
      final response = await ApiService.deleteEvent(id: id);
      final data = response.data;
      if (data is Map && data['status'] == 'success') {
        Get.snackbar(
          "Deleted",
          data['message']?.toString() ?? "Event deleted",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        await fetchHostedEvents(forceRefresh: true);
        await fetchEvents();
      } else {
        Get.snackbar(
          "Error",
          (data is Map ? data['message'] : null)?.toString() ?? "Failed to delete event",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint("Delete event error: $e");
      Get.snackbar(
        "Error",
        "Failed to delete event.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> replacePendingHostedEvent({
    required dynamic oldEvent,
    required String title,
    required String desc,
    required String date,
    required String category,
    required String venue,
    required File? newBanner,
    required String? existingBannerName,
  }) async {
    // Only pending events can be modified
    if (!_isPending(oldEvent)) {
      Get.snackbar(
        "Not Allowed",
        "Only pending events can be edited.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    final idRaw = (oldEvent is Map) ? oldEvent['id'] : null;
    final oldId = (idRaw is int) ? idRaw : int.tryParse(idRaw?.toString() ?? '');
    if (oldId == null) {
      Get.snackbar(
        "Error",
        "Invalid event id.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    String? userId = await PrefService.getUserId();
    if (userId == null) {
      Get.snackbar(
        "Error",
        "User not found. Please login again",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    isLoading.value = true;
    try {
      // If user didn't choose a new banner, try to preserve existing one by downloading it.
      File? bannerToUpload = newBanner;
      if (bannerToUpload == null && existingBannerName != null && existingBannerName.isNotEmpty) {
        try {
          final tmpDir = await getTemporaryDirectory();
          final tmpPath = "${tmpDir.path}/evt_banner_${oldId}_${DateTime.now().millisecondsSinceEpoch}.jpg";
          final url = "https://exdeos.com/AS/campus_social/uploads/events/$existingBannerName";
          await Dio().download(url, tmpPath);
          bannerToUpload = File(tmpPath);
        } catch (e) {
          debugPrint("Banner preserve download failed: $e");
        }
      }

      // 1) Create a new pending event with updated details (uses existing API)
      final createResp = await ApiService.createEvent({
        "user_id": userId,
        "title": title,
        "description": desc,
        "event_date": date,
        "category": category,
        "venue": venue,
      }, bannerToUpload != null ? [bannerToUpload] : []);

      final createData = createResp.data;
      if (createData is! Map || createData['status'] != 'success') {
        Get.snackbar(
          "Error",
          (createData is Map ? createData['message'] : null)?.toString() ?? "Failed to update event",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      // 2) Delete old pending event (uses existing API)
      final deleteResp = await ApiService.deleteEvent(id: oldId);
      final deleteData = deleteResp.data;
      if (deleteData is! Map || deleteData['status'] != 'success') {
        // Not fatal, but will cause duplicates.
        Get.snackbar(
          "Warning",
          "Updated event created, but old event could not be deleted. Please delete the old one manually.",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }

      await fetchHostedEvents(forceRefresh: true);
      await fetchEvents();
      return true;
    } catch (e) {
      debugPrint("replacePendingHostedEvent error: $e");
      Get.snackbar(
        "Error",
        "Failed to update event. Please try again.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Image is now optional - pass null if no image selected
  Future<bool> createEvent(String title, String desc, String date, String category, String venue, File? image) async {
    isLoading.value = true;
    try {
      String? userId = await PrefService.getUserId();
      if (userId == null) {
        Get.snackbar(
          "Error", 
          "Please login again",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
        isLoading.value = false;
        return false;
      }

      debugPrint("Creating event: $title");
      
      final response = await ApiService.createEvent({
        "user_id": userId,
        "title": title,
        "description": desc,
        "event_date": date,
        "category": category,
        "venue": venue,
      }, image != null ? [image] : []);

      debugPrint("Create event response: ${response.data}");

      if (response.data['status'] == 'success') {
        Get.snackbar(
          "Success 🎉", 
          "Event created successfully!",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(10),
        );
        
        // Refresh lists
        await fetchEvents();
        await fetchHostedEvents();
        
        // Navigate back after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (Get.currentRoute.contains('create')) {
            Get.back();
          }
        });
        
        return true;
      } else {
        Get.snackbar(
          "Error", 
          response.data['message'] ?? "Failed to create event",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(10),
        );
        return false;
      }
    } catch (e) {
      debugPrint("Create event error: $e");
      Get.snackbar(
        "Error", 
        "Failed to create event. Please try again.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(10),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleFavorite(String eventId) async {
    try {
      final response = await ApiService.toggleFavorite(eventId);
      if (response.data['status'] == 'success') {
        fetchFavorites();
        Get.snackbar("Favorites", response.data['message'], snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar("Error", "Action failed");
    }
  }

  Future<void> joinEvent(String eventId) async {
    try {
      final response = await ApiService.joinEvent(eventId);
      debugPrint("📱 joinEvent response status: ${response.data['status']}");
      Get.snackbar(response.data['status'] == 'success' ? "Success" : "Notice", response.data['message']);
      if (response.data['status'] == 'success') {
        debugPrint("🔄 Refreshing attending events...");
        await fetchAttendingEvents();
        await fetchEvents();
        debugPrint("✓ Lists refreshed");
      }
    } catch (e) {
      debugPrint("✗ joinEvent error: $e");
      Get.snackbar("Error", "Registration failed");
    }
  }

  Future<void> volunteer(String eventId, String role, String contact) async {
    isLoading.value = true;
    try {
      String? userId = await PrefService.getUserId();
      
      if (userId == null) {
        Get.snackbar("Error", "User not found. Please login again", backgroundColor: Colors.red, colorText: Colors.white);
        isLoading.value = false;
        return;
      }
      
      debugPrint("Volunteer data: event=$eventId, user=$userId, role=$role");
      
      final response = await ApiService.joinVolunteer({
        "event_id": eventId,
        "user_id": userId,
        "role": role,
      });
      
      debugPrint("Volunteer response: $response");
      debugPrint("Volunteer response.statusCode: ${response.statusCode}");
      debugPrint("Volunteer response.data: ${response.data}");
      debugPrint("Volunteer response type: ${response.runtimeType}");
      
      if (response.statusCode != null && response.statusCode! >= 400) {
        Get.snackbar(
          "Server Error",
          "Server returned error ${response.statusCode}. Please contact support.",
          backgroundColor: Colors.red,
          colorText: Colors.white
        );
        isLoading.value = false;
        return;
      }
      
      if (response.data == null) {
        Get.snackbar(
          "Error",
          "Invalid response from server. Please try again.",
          backgroundColor: Colors.red,
          colorText: Colors.white
        );
        isLoading.value = false;
        return;
      }
      
      final status = response.data['status'] ?? 'error';
      final message = response.data['message'] ?? 'Unknown error occurred';
      
      if (status == 'success') {
        Get.back();
        fetchVolunteeringEvents();
        Get.snackbar(
          "Success", 
          "Successfully registered as volunteer!",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3)
        );
      } else {
        Get.snackbar(
          "Error",
          message,
          backgroundColor: Colors.red,
          colorText: Colors.white
        );
      }
    } catch (e) {
      debugPrint("Volunteer exception: $e");
      Get.snackbar(
        "Error",
        "Volunteering registration failed: ${e.toString()}",
        backgroundColor: Colors.red,
        colorText: Colors.white
      );
    } finally {
      isLoading.value = false;
    }
  }
}