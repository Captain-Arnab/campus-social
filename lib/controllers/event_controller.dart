import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/api_service.dart';
import '../data/pref_service.dart';
import '../utils/sweetalert_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

class EventController extends GetxController {
  var isLoading = false.obs;
  var isRefreshing = false.obs; // true during pull-to-refresh / search; list stays visible
  var eventList = <dynamic>[].obs;
  var favoriteList = <dynamic>[].obs;
  var attendingList = <dynamic>[].obs;
  var volunteeringList = <dynamic>[].obs;
  var participatingList = <dynamic>[].obs;
  var hostedList = <dynamic>[].obs;
  var editingList = <dynamic>[].obs;
  CancelToken? _eventsCancelToken;

  @override
  void onInit() {
    super.onInit();
    fetchEvents();
    fetchFavorites();
    fetchAttendingEvents();
    fetchVolunteeringEvents();
    fetchHostedEvents();
    fetchParticipatingEvents();
    fetchEditingEvents();
  }

  Future<void> fetchEvents({String? search, String? category}) async {
    _eventsCancelToken?.cancel('New request');
    _eventsCancelToken = CancelToken();
    final isInitialLoad = eventList.isEmpty;
    if (isInitialLoad) {
      isLoading.value = true;
    } else {
      isRefreshing.value = true;
    }
    try {
      final response = await ApiService.getEvents(
        search: search,
        category: category,
        cancelToken: _eventsCancelToken,
      );
      if (response.data['status'] == 'success') {
        final data = response.data['data'] as List?;
        if (data != null) {
          eventList.value = data;
          debugPrint("✓ Loaded ${data.length} events");
        }
      }
    } catch (e) {
      if (e is! DioException || !CancelToken.isCancel(e)) {
        debugPrint("✗ Fetch error: $e");
      }
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
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

  Future<void> fetchEditingEvents() async {
    try {
      String? userId = await PrefService.getUserId();
      if (userId == null) {
        debugPrint("✗ User ID not found for editing events");
        return;
      }
      final response = await ApiService.getEditingEvents();
      if (response.data['status'] == 'success') {
        final data = response.data['data'] as List?;
        if (data != null) {
          editingList.value = data;
          debugPrint("✓ Loaded ${data.length} events you can edit");
        } else {
          editingList.value = [];
        }
      } else {
        editingList.value = [];
      }
    } catch (e) {
      debugPrint("✗ Editing events fetch error: $e");
      editingList.value = [];
    }
  }

  Future<void> participate(String eventId) async {
    isLoading.value = true;
    try {
      String? userId = await PrefService.getUserId();
      
      if (userId == null) {
        SweetAlertHelper.showError(Get.context, "Error", "User not found. Please login again");
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
        SweetAlertHelper.showError(Get.context, "Server Error", "Server returned error ${response.statusCode}. Please contact support.");
        isLoading.value = false;
        return;
      }
      
      if (response.data == null) {
        SweetAlertHelper.showError(Get.context, "Error", "Invalid response from server. Please try again.");
        isLoading.value = false;
        return;
      }
      
      final status = response.data['status'] ?? 'error';
      final message = response.data['message'] ?? 'Unknown error occurred';
      
      if (status == 'success') {
        Get.back();
        fetchParticipatingEvents();
        SweetAlertHelper.showSuccess(Get.context, "Success", "Successfully registered as participant!");
      } else {
        SweetAlertHelper.showError(Get.context, "Error", message);
      }
    } catch (e) {
      debugPrint("Participant exception: $e");
      SweetAlertHelper.showError(Get.context, "Error", "Participation registration failed: ${e.toString()}");
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
    String? eventDate,
    String? category,
  }) async {
    final idRaw = (event is Map) ? event['id'] : null;
    final id = (idRaw is int) ? idRaw : int.tryParse(idRaw?.toString() ?? '');
    if (id == null) {
      SweetAlertHelper.showError(Get.context, "Error", "Invalid event id.");
      return;
    }

    // Pending events: only allow direct update (no pending-approval flow)
    final bool isPending = _isPending(event);
    if (isPending) {
      // Approved events with editors go to pending approval; pending events update directly
      final hasEditors = (event is Map && event['editor_ids'] is List) ? (event['editor_ids'] as List).isNotEmpty : false;
      if (hasEditors) {
        SweetAlertHelper.showInfo(Get.context, "Info", "Only pending events without editors can be edited here.");
        return;
      }
    }

    isLoading.value = true;
    try {
      final response = await ApiService.updateEvent(
        id: id,
        title: title,
        description: description,
        venue: venue,
        eventDate: eventDate,
        category: category,
      );

      final data = response.data;
      if (data is Map && data['status'] == 'success') {
        final bool pendingApproval = data['pending_approval'] == true;
        SweetAlertHelper.showSuccess(Get.context, "Success", pendingApproval ? "Edit submitted for admin approval." : (data['message']?.toString() ?? "Event updated"));
        await fetchHostedEvents(forceRefresh: true);
        await fetchEditingEvents();
        await fetchEvents();
      } else {
        SweetAlertHelper.showError(Get.context, "Error", (data is Map ? data['message'] : null)?.toString() ?? "Failed to update event");
      }
    } catch (e) {
      debugPrint("Update event error: $e");
      SweetAlertHelper.showError(Get.context, "Error", "Failed to update event.");
    } finally {
      isLoading.value = false;
    }
  }

  /// Update an approved event (organizer or editor). If event has editors, edit goes to admin approval.
  Future<void> updateApprovedEvent({
    required dynamic event,
    required String title,
    required String description,
    required String venue,
    String? eventDate,
    String? category,
  }) async {
    final idRaw = (event is Map) ? event['id'] : null;
    final id = (idRaw is int) ? idRaw : int.tryParse(idRaw?.toString() ?? '');
    if (id == null) {
      SweetAlertHelper.showError(Get.context, "Error", "Invalid event id.");
      return;
    }
    isLoading.value = true;
    try {
      final response = await ApiService.updateEvent(
        id: id,
        title: title,
        description: description,
        venue: venue,
        eventDate: eventDate,
        category: category,
      );
      final data = response.data;
      if (data is Map && data['status'] == 'success') {
        final bool pendingApproval = data['pending_approval'] == true;
        SweetAlertHelper.showSuccess(Get.context, "Success", pendingApproval ? "Edit submitted for admin approval." : (data['message']?.toString() ?? "Event updated"));
        await fetchHostedEvents(forceRefresh: true);
        await fetchEditingEvents();
        await fetchEvents();
      } else {
        SweetAlertHelper.showError(Get.context, "Error", (data is Map ? data['message'] : null)?.toString() ?? "Failed to update event");
      }
    } catch (e) {
      debugPrint("Update approved event error: $e");
      SweetAlertHelper.showError(Get.context, "Error", "Failed to update event.");
    } finally {
      isLoading.value = false;
    }
  }

  /// Update approved event with full form (including optional banner). Uses POST multipart; supports pending_approval.
  Future<bool> updateApprovedEventWithFormData({
    required dynamic event,
    required String title,
    required String description,
    required String venue,
    required String eventDate,
    required String category,
    List<File>? bannerFiles,
  }) async {
    final idRaw = (event is Map) ? event['id'] : null;
    final id = idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '');
    if (id == null) {
      SweetAlertHelper.showError(Get.context, "Error", "Invalid event id.");
      return false;
    }
    final userId = await PrefService.getUserId();
    if (userId == null) {
      SweetAlertHelper.showError(Get.context, "Error", "Please log in again.");
      return false;
    }
    isLoading.value = true;
    try {
      final response = await ApiService.updateEventWithFormData(
        eventId: id,
        userId: userId,
        title: title,
        description: description,
        venue: venue,
        eventDate: eventDate,
        category: category,
        bannerFiles: bannerFiles,
      );
      final data = response.data;
      if (data is Map && data['status'] == 'success') {
        await fetchHostedEvents(forceRefresh: true);
        await fetchEditingEvents();
        await fetchEvents();
        return true;
      } else {
        SweetAlertHelper.showError(
          Get.context,
          "Error",
          (data is Map ? data['message'] : null)?.toString() ?? "Failed to update event",
        );
        return false;
      }
    } catch (e) {
      debugPrint("Update approved event (form) error: $e");
      SweetAlertHelper.showError(Get.context, "Error", "Failed to update event.");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch single event by id (includes editor_ids, pending_edit, winners).
  Future<Map<String, dynamic>?> fetchEventById(int eventId) async {
    try {
      final response = await ApiService.getEventById(eventId);
      if (response.data is Map && response.data['status'] == 'success') {
        final d = response.data['data'];
        return d is Map ? Map<String, dynamic>.from(d) : null;
      }
      return null;
    } catch (e) {
      debugPrint("fetchEventById error: $e");
      return null;
    }
  }

  Future<void> deleteHostedEvent({required dynamic event}) async {
    // Only pending events can be deleted
    if (!_isPending(event)) {
      SweetAlertHelper.showError(Get.context, "Not Allowed", "Approved events cannot be deleted.");
      return;
    }

    final idRaw = (event is Map) ? event['id'] : null;
    final id = (idRaw is int) ? idRaw : int.tryParse(idRaw?.toString() ?? '');
    if (id == null) {
      SweetAlertHelper.showError(Get.context, "Error", "Invalid event id.");
      return;
    }

    isLoading.value = true;
    try {
      final response = await ApiService.deleteEvent(id: id);
      final data = response.data;
      if (data is Map && data['status'] == 'success') {
        SweetAlertHelper.showSuccess(Get.context, "Deleted", data['message']?.toString() ?? "Event deleted");
        await fetchHostedEvents(forceRefresh: true);
        await fetchEvents();
      } else {
        SweetAlertHelper.showError(Get.context, "Error", (data is Map ? data['message'] : null)?.toString() ?? "Failed to delete event");
      }
    } catch (e) {
      debugPrint("Delete event error: $e");
      SweetAlertHelper.showError(Get.context, "Error", "Failed to delete event.");
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
      SweetAlertHelper.showError(Get.context, "Not Allowed", "Only pending events can be edited.");
      return false;
    }

    final idRaw = (oldEvent is Map) ? oldEvent['id'] : null;
    final oldId = (idRaw is int) ? idRaw : int.tryParse(idRaw?.toString() ?? '');
    if (oldId == null) {
      SweetAlertHelper.showError(Get.context, "Error", "Invalid event id.");
      return false;
    }

    String? userId = await PrefService.getUserId();
    if (userId == null) {
      SweetAlertHelper.showError(Get.context, "Error", "User not found. Please login again");
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
        SweetAlertHelper.showError(Get.context, "Error", (createData is Map ? createData['message'] : null)?.toString() ?? "Failed to update event");
        return false;
      }

      // 2) Delete old pending event (uses existing API)
      final deleteResp = await ApiService.deleteEvent(id: oldId);
      final deleteData = deleteResp.data;
      if (deleteData is! Map || deleteData['status'] != 'success') {
        SweetAlertHelper.showWarning(Get.context, "Warning", "Updated event created, but old event could not be deleted. Please delete the old one manually.");
      }

      await fetchHostedEvents(forceRefresh: true);
      await fetchEvents();
      return true;
    } catch (e) {
      debugPrint("replacePendingHostedEvent error: $e");
      SweetAlertHelper.showError(Get.context, "Error", "Failed to update event. Please try again.");
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
        SweetAlertHelper.showError(Get.context, "Error", "Please login again");
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
        SweetAlertHelper.showSuccess(Get.context, "Success 🎉", "Event created successfully!");
        
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
        SweetAlertHelper.showError(Get.context, "Error", response.data['message'] ?? "Failed to create event");
        return false;
      }
    } catch (e) {
      debugPrint("Create event error: $e");
      SweetAlertHelper.showError(Get.context, "Error", "Failed to create event. Please try again.");
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
        SweetAlertHelper.showSuccess(Get.context, "Favorites", response.data['message']?.toString() ?? "Done");
      }
    } catch (e) {
      SweetAlertHelper.showError(Get.context, "Error", "Action failed");
    }
  }

  Future<void> joinEvent(String eventId) async {
    try {
      final response = await ApiService.joinEvent(eventId);
      debugPrint("📱 joinEvent response status: ${response.data['status']}");
      final isSuccess = response.data['status'] == 'success';
      final msg = response.data['message']?.toString() ?? '';
      if (isSuccess) {
        SweetAlertHelper.showSuccess(Get.context, "Success", msg.isNotEmpty ? msg : "Registration successful.");
        debugPrint("🔄 Refreshing attending events...");
        await fetchAttendingEvents();
        await fetchEvents();
        debugPrint("✓ Lists refreshed");
      } else {
        SweetAlertHelper.showInfo(Get.context, "Notice", msg);
      }
    } catch (e) {
      debugPrint("✗ joinEvent error: $e");
      SweetAlertHelper.showError(Get.context, "Error", "Registration failed");
    }
  }

  Future<void> volunteer(String eventId, String role, String contact) async {
    isLoading.value = true;
    try {
      String? userId = await PrefService.getUserId();
      
      if (userId == null) {
        SweetAlertHelper.showError(Get.context, "Error", "User not found. Please login again");
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
        SweetAlertHelper.showError(Get.context, "Server Error", "Server returned error ${response.statusCode}. Please contact support.");
        isLoading.value = false;
        return;
      }
      
      if (response.data == null) {
        SweetAlertHelper.showError(Get.context, "Error", "Invalid response from server. Please try again.");
        isLoading.value = false;
        return;
      }
      
      final status = response.data['status'] ?? 'error';
      final message = response.data['message'] ?? 'Unknown error occurred';
      
      if (status == 'success') {
        Get.back();
        fetchVolunteeringEvents();
        SweetAlertHelper.showSuccess(Get.context, "Success", "Successfully registered as volunteer!");
      } else {
        SweetAlertHelper.showError(Get.context, "Error", message);
      }
    } catch (e) {
      debugPrint("Volunteer exception: $e");
      SweetAlertHelper.showError(Get.context, "Error", "Volunteering registration failed: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }
}