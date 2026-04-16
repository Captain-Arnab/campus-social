import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/api_service.dart';
import '../data/pref_service.dart';
import '../utils/sweetalert_helper.dart';
import '../utils/event_participation_rules.dart';
import 'profile_controller.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

class EventController extends GetxController {
  var isLoading = false.obs;
  var isRefreshing = false.obs; // true during pull-to-refresh / search; list stays visible
  /// Full approved live feed (no category/search). Home explore builds filtered views from this.
  var liveEventCatalog = <dynamic>[].obs;
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
    // Load catalog first so Explore can paint quickly; defer other lists to next event-loop turn.
    fetchLiveEventCatalog();
    scheduleMicrotask(() {
      fetchFavorites();
      fetchAttendingEvents();
      fetchVolunteeringEvents();
      fetchHostedEvents();
      fetchParticipatingEvents();
      fetchEditingEvents();
    });
  }

  /// Loads the full live events list (no server-side category or search). Home applies filters locally.
  Future<void> fetchLiveEventCatalog() async {
    _eventsCancelToken?.cancel('New request');
    _eventsCancelToken = CancelToken();
    final isInitialLoad = liveEventCatalog.isEmpty;
    if (isInitialLoad) {
      isLoading.value = true;
    } else {
      isRefreshing.value = true;
    }
    try {
      final response = await ApiService.getEvents(
        cancelToken: _eventsCancelToken,
      );
      if (response.data['status'] == 'success') {
        final data = response.data['data'] as List?;
        if (data != null) {
          liveEventCatalog.value = data;
          eventList.value = data;
          debugPrint("✓ Loaded ${data.length} events (catalog)");
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

  /// Refreshes the live catalog. [search] and [category] are ignored (filters are client-side on home).
  Future<void> fetchEvents({String? search, String? category}) async {
    await fetchLiveEventCatalog();
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

  bool _eventRowMatchesId(String eventId, dynamic row) {
    if (row is! Map) return false;
    return row['id']?.toString() == eventId.toString();
  }

  bool _inAttendingList(String eventId) => attendingList.any((e) => _eventRowMatchesId(eventId, e));
  bool _inVolunteeringList(String eventId) => volunteeringList.any((e) => _eventRowMatchesId(eventId, e));
  bool _inParticipatingList(String eventId) => participatingList.any((e) => _eventRowMatchesId(eventId, e));

  bool _isOrganiserForGuard(String userId, {String? organizerId, dynamic eventSnapshot}) {
    final oid = organizerId ?? EventParticipationRules.organizerIdFromEvent(eventSnapshot);
    return oid != null && oid == userId;
  }

  void _warnOrganiserCannotJoin() {
    SweetAlertHelper.showInfo(
      Get.context,
      'Not allowed',
      'Event organisers cannot attend, volunteer, or register as participants for their own event.',
    );
  }

  void _warnSingleRoleConflict(String description) {
    SweetAlertHelper.showInfo(
      Get.context,
      'Already registered',
      'You are already $description for this event. You can only have one role: attendee, volunteer, or participant.',
    );
  }

  void _warnVolunteerParticipantWrongOrganiserType() {
    SweetAlertHelper.showInfo(
      Get.context,
      'Not allowed',
      'You can only volunteer or participate in events organised by your own group '
      '(students with student organisers, staff with staff organisers). For the other group\'s events, you can only attend.',
    );
  }

  /// Returns false if the action must be blocked (and shows a message).
  bool guardParticipationAction(
    String eventId,
    String userId, {
    required String trying,
    String? organizerId,
    dynamic eventSnapshot,
    bool? userIsStudent,
  }) {
    if (_isOrganiserForGuard(userId, organizerId: organizerId, eventSnapshot: eventSnapshot)) {
      _warnOrganiserCannotJoin();
      return false;
    }

    final orgStudent = EventParticipationRules.organizerIsStudentFromEvent(eventSnapshot);
    if (userIsStudent != null && orgStudent != null) {
      if (trying == 'volunteer' || trying == 'participant') {
        if (!EventParticipationRules.volunteerOrParticipantAllowed(userIsStudent, orgStudent)) {
          _warnVolunteerParticipantWrongOrganiserType();
          return false;
        }
      }
    }

    final id = eventId.toString();
    switch (trying) {
      case 'attendee':
        if (_inVolunteeringList(id) || EventParticipationRules.userInVolunteerList(eventSnapshot, userId)) {
          _warnSingleRoleConflict('registered as a volunteer');
          return false;
        }
        if (_inParticipatingList(id) || EventParticipationRules.userInParticipantList(eventSnapshot, userId)) {
          _warnSingleRoleConflict('registered as a participant');
          return false;
        }
        return true;
      case 'volunteer':
        if (_inAttendingList(id)) {
          _warnSingleRoleConflict('registered as an attendee');
          return false;
        }
        if (_inParticipatingList(id) || EventParticipationRules.userInParticipantList(eventSnapshot, userId)) {
          _warnSingleRoleConflict('registered as a participant');
          return false;
        }
        return true;
      case 'participant':
        if (_inAttendingList(id)) {
          _warnSingleRoleConflict('registered as an attendee');
          return false;
        }
        if (_inVolunteeringList(id) || EventParticipationRules.userInVolunteerList(eventSnapshot, userId)) {
          _warnSingleRoleConflict('registered as a volunteer');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  Future<void> participate(
    String eventId,
    String departmentClass, {
    String? organizerId,
    dynamic eventSnapshot,
    bool? userIsStudent,
  }) async {
    isLoading.value = true;
    try {
      String? userId = await PrefService.getUserId();
      
      if (userId == null) {
        SweetAlertHelper.showError(Get.context, "Error", "User not found. Please login again");
        isLoading.value = false;
        return;
      }

      if (!guardParticipationAction(
        eventId,
        userId,
        trying: 'participant',
        organizerId: organizerId,
        eventSnapshot: eventSnapshot,
        userIsStudent: userIsStudent,
      )) {
        isLoading.value = false;
        return;
      }
      
      debugPrint("Participant data: event=$eventId, user=$userId, dept=$departmentClass");
      
      final response = await ApiService.joinParticipant({
        "event_id": eventId,
        "user_id": userId,
        "department_class": departmentClass.trim(),
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
        fetchParticipatingEvents();
        if (Get.isRegistered<ProfileController>()) {
          Get.find<ProfileController>().loadProfile();
        }
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
    String? rules,
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
        rules: rules,
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
    String? rules,
    String? eventEndDate,
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
        rules: rules,
        eventEndDate: eventEndDate,
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
    String? rules,
    String? eventEndDate,
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
        rules: rules,
        eventEndDate: eventEndDate,
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
    String rules = '',
    String? eventEndDate,
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
          final url = "https://micampus.co.in/admin/uploads/events/$existingBannerName";
          await Dio().download(url, tmpPath);
          bannerToUpload = File(tmpPath);
        } catch (e) {
          debugPrint("Banner preserve download failed: $e");
        }
      }

      // 1) Create a new pending event with updated details (uses existing API)
      final createFields = <String, dynamic>{
        "user_id": userId,
        "title": title,
        "description": desc,
        "event_date": date,
        "category": category,
        "venue": venue,
        "rules": rules,
      };
      if (eventEndDate != null && eventEndDate.isNotEmpty) {
        createFields["event_end_date"] = eventEndDate;
      }
      final createResp = await ApiService.createEvent(createFields, bannerToUpload != null ? [bannerToUpload] : []);

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
  Future<bool> createEvent(String title, String desc, String date, String category, String venue, File? image, {String rules = '', String? eventEndDate}) async {
    isLoading.value = true;
    try {
      String? userId = await PrefService.getUserId();
      if (userId == null) {
        SweetAlertHelper.showError(Get.context, "Error", "Please login again");
        isLoading.value = false;
        return false;
      }

      debugPrint("Creating event: $title");

      final fields = <String, dynamic>{
        "user_id": userId,
        "title": title,
        "description": desc,
        "event_date": date,
        "category": category,
        "venue": venue,
        "rules": rules,
      };
      if (eventEndDate != null && eventEndDate.isNotEmpty) {
        fields["event_end_date"] = eventEndDate;
      }
      
      final response = await ApiService.createEvent(fields, image != null ? [image] : []);

      debugPrint("Create event response: ${response.data}");

      if (response.data['status'] == 'success') {
        // Success UI and navigation are handled by CreateEventView (avoids duplicate dialogs).
        await fetchEvents();
        await fetchHostedEvents();
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

  Future<void> joinEvent(
    String eventId, {
    String? organizerId,
    dynamic eventSnapshot,
    bool? userIsStudent,
  }) async {
    try {
      final userId = await PrefService.getUserId();
      if (userId == null) {
        SweetAlertHelper.showError(Get.context, "Error", "User not found. Please login again");
        return;
      }
      if (!guardParticipationAction(
        eventId,
        userId,
        trying: 'attendee',
        organizerId: organizerId,
        eventSnapshot: eventSnapshot,
        userIsStudent: userIsStudent,
      )) {
        return;
      }
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

  Future<void> volunteer(
    String eventId,
    String role,
    String contact, {
    String? organizerId,
    dynamic eventSnapshot,
    bool? userIsStudent,
  }) async {
    isLoading.value = true;
    try {
      String? userId = await PrefService.getUserId();
      
      if (userId == null) {
        SweetAlertHelper.showError(Get.context, "Error", "User not found. Please login again");
        isLoading.value = false;
        return;
      }

      if (!guardParticipationAction(
        eventId,
        userId,
        trying: 'volunteer',
        organizerId: organizerId,
        eventSnapshot: eventSnapshot,
        userIsStudent: userIsStudent,
      )) {
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