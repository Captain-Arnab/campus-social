import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/api_service.dart';
import '../data/pref_service.dart';
import '../base/constant.dart';
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

  /// Explore search box: mirrors typed text (drives dropdown visibility).
  final exploreSearchQuery = ''.obs;
  /// Server-side matches from `events.php?type=live&search=...` (same rules as PHP).
  final exploreSearchResults = <dynamic>[].obs;
  var exploreSearchLoading = false.obs;
  CancelToken? _exploreSearchCancelToken;

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

  @override
  void onClose() {
    _eventsCancelToken?.cancel();
    _exploreSearchCancelToken?.cancel();
    super.onClose();
  }

  /// Clears Explore search dropdown state (search field text is owned by the widget).
  void clearExploreSearch() {
    _exploreSearchCancelToken?.cancel();
    exploreSearchQuery.value = '';
    exploreSearchResults.clear();
    exploreSearchLoading.value = false;
  }

  /// GET live events with `search` query param (backend: title, description, venue, category, rules, organizer).
  Future<void> fetchExploreLiveSearch(String rawQuery) async {
    final q = rawQuery.trim();
    if (q.isEmpty) {
      clearExploreSearch();
      return;
    }
    _exploreSearchCancelToken?.cancel('New search');
    _exploreSearchCancelToken = CancelToken();
    exploreSearchLoading.value = true;
    try {
      final response = await ApiService.getEvents(
        search: q,
        cancelToken: _exploreSearchCancelToken,
      );
      final body = response.data;
      if (body is! Map) {
        exploreSearchResults.clear();
        return;
      }
      if (body['status']?.toString() != 'success') {
        exploreSearchResults.clear();
        return;
      }
      final data = body['data'];
      if (data is List) {
        exploreSearchResults
          ..clear()
          ..addAll(List<dynamic>.from(data));
      } else {
        exploreSearchResults.clear();
      }
    } catch (e) {
      if (e is! DioException || !CancelToken.isCancel(e)) {
        debugPrint('✗ Explore search error: $e');
      }
      exploreSearchResults.clear();
    } finally {
      exploreSearchLoading.value = false;
    }
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
      final body = ApiService.parseResponseBody(response.data);
      if (body != null && body['status']?.toString() == 'success') {
        final data = body['data'];
        if (data is! List) {
          editingList.value = [];
          return;
        }
        // Backend `type=editing` currently falls through to live feed (no editor_ids).
        // Only keep rows where this user is explicitly marked as an editor.
        final filtered = data.where((e) {
          if (e is! Map) return false;
          final editors = e['editor_ids'];
          if (editors is List &&
              editors.any((id) => id.toString() == userId.toString())) {
            return true;
          }
          final flag = e['is_editor'] ?? e['can_edit'];
          return flag == 1 || flag == true || flag == '1';
        }).toList();
        editingList.value = filtered;
        debugPrint(
          "✓ Editing events: API=${data.length}, editable_for_user=$userId → ${filtered.length}",
        );
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
        // An attendee may upgrade directly to volunteer; the backend clears the
        // attendee row on success, so don't block it here.
        if (_inParticipatingList(id) || EventParticipationRules.userInParticipantList(eventSnapshot, userId)) {
          _warnSingleRoleConflict('registered as a participant');
          return false;
        }
        return true;
      case 'participant':
        // An attendee may upgrade directly to participant; the backend clears the
        // attendee row on success, so don't block it here.
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

      final data = ApiService.parseResponseBody(response.data);
      if (data == null) {
        SweetAlertHelper.showError(Get.context, "Error", "Invalid response from server. Please try again.");
        isLoading.value = false;
        return;
      }

      final status = data['status']?.toString() ?? 'error';
      final message = data['message']?.toString() ?? 'Unknown error occurred';
      
      if (status == 'success') {
        fetchParticipatingEvents();
        // Attendee → participant clears the attendee row on the backend; refresh so
        // the local attending state (and the "Viewer" button) updates immediately.
        fetchAttendingEvents();
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
          final url = "${Constant.uploadsBaseUrl}events/$existingBannerName";
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

      final createData = ApiService.parseResponseBody(createResp.data);
      if (createData == null || createData['status']?.toString() != 'success') {
        SweetAlertHelper.showError(
          Get.context,
          "Error",
          ApiService.formatFieldError(createData, fallback: "Failed to update event"),
        );
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

      final data = ApiService.parseResponseBody(response.data);
      if (data != null && data['status']?.toString() == 'success') {
        // Success UI and navigation are handled by CreateEventView (avoids duplicate dialogs).
        await fetchEvents();
        await fetchHostedEvents();
        return true;
      } else {
        SweetAlertHelper.showError(
          Get.context,
          "Error",
          ApiService.formatFieldError(data, fallback: "Failed to create event"),
        );
        return false;
      }
    } catch (e) {
      debugPrint("Create event error: $e");
      SweetAlertHelper.showError(
        Get.context,
        "Error",
        ApiService.formatFieldError(null, fallback: "Failed to create event. Please try again."),
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
      final data = ApiService.parseResponseBody(response.data) ?? {};
      ApiService.rememberServerTimeFromBody(data);
      final isSuccess = data['status'] == 'success';
      final msg = data['message']?.toString() ?? '';
      if (isSuccess) {
        _applyParticipationResponse(eventId, data: data, roleJoined: 'attendee');
        SweetAlertHelper.showSuccess(Get.context, "Success", msg.isNotEmpty ? msg : "Registration successful.");
      } else {
        SweetAlertHelper.showInfo(Get.context, "Notice", msg);
      }
    } catch (e) {
      debugPrint("✗ joinEvent error: $e");
      SweetAlertHelper.showError(Get.context, "Error", "Registration failed");
    }
  }

  /// Leave attendee/viewer role. Allowed after registration deadline.
  /// Returns parsed response data on success (for local UI count refresh).
  Future<Map<String, dynamic>?> leaveEvent(String eventId) async {
    try {
      final response = await ApiService.leaveEvent(eventId);
      final data = ApiService.parseResponseBody(response.data);
      if (data == null) {
        SweetAlertHelper.showError(Get.context, 'Error', 'Invalid response from server.');
        return null;
      }
      ApiService.rememberServerTimeFromBody(data);
      if (data['status']?.toString() == 'success') {
        _applyParticipationResponse(eventId, data: data, roleLeft: 'attendee');
        final msg = data['message']?.toString().trim() ?? '';
        SweetAlertHelper.showSuccess(
          Get.context,
          'Left',
          msg.isNotEmpty ? msg : 'You left this event.',
        );
        return data;
      }
      SweetAlertHelper.showError(
        Get.context,
        'Error',
        data['message']?.toString() ?? 'Could not leave event.',
      );
      return null;
    } catch (e) {
      debugPrint('✗ leaveEvent error: $e');
      SweetAlertHelper.showError(Get.context, 'Error', 'Could not leave event.');
      return null;
    }
  }

  /// Leave volunteer role. Allowed anytime (including after deadline).
  Future<Map<String, dynamic>?> leaveVolunteer(String eventId) async {
    try {
      final response = await ApiService.leaveVolunteer(eventId);
      final data = ApiService.parseResponseBody(response.data);
      if (data == null) {
        SweetAlertHelper.showError(Get.context, 'Error', 'Invalid response from server.');
        return null;
      }
      ApiService.rememberServerTimeFromBody(data);
      if (data['status']?.toString() == 'success') {
        _applyParticipationResponse(eventId, data: data, roleLeft: 'volunteer');
        final msg = data['message']?.toString().trim() ?? '';
        SweetAlertHelper.showSuccess(
          Get.context,
          'Left',
          msg.isNotEmpty ? msg : 'You are no longer a volunteer for this event.',
        );
        return data;
      }
      SweetAlertHelper.showError(
        Get.context,
        'Error',
        data['message']?.toString() ?? 'Could not leave volunteer role.',
      );
      return null;
    } catch (e) {
      debugPrint('✗ leaveVolunteer error: $e');
      SweetAlertHelper.showError(Get.context, 'Error', 'Could not leave volunteer role.');
      return null;
    }
  }

  /// Leave participant role. Backend may reject if user is a winner.
  Future<Map<String, dynamic>?> leaveParticipant(String eventId) async {
    try {
      final response = await ApiService.leaveParticipant(eventId);
      final data = ApiService.parseResponseBody(response.data);
      if (data == null) {
        SweetAlertHelper.showError(Get.context, 'Error', 'Invalid response from server.');
        return null;
      }
      ApiService.rememberServerTimeFromBody(data);
      if (data['status']?.toString() == 'success') {
        _applyParticipationResponse(eventId, data: data, roleLeft: 'participant');
        final msg = data['message']?.toString().trim() ?? '';
        SweetAlertHelper.showSuccess(
          Get.context,
          'Left',
          msg.isNotEmpty ? msg : 'You are no longer a participant for this event.',
        );
        return data;
      }
      final raw = data['message']?.toString() ?? '';
      final lower = raw.toLowerCase();
      final winnerBlock = lower.contains('winner') ||
          lower.contains('event_winners') ||
          (data['code']?.toString().toLowerCase().contains('winner') ?? false) ||
          (data['error_code']?.toString().toLowerCase().contains('winner') ?? false);
      SweetAlertHelper.showError(
        Get.context,
        winnerBlock ? "Can't leave" : 'Error',
        winnerBlock
            ? (raw.isNotEmpty
                ? raw
                : "Can't leave — you're marked as a winner for this event. Contact the organizer.")
            : (raw.isNotEmpty ? raw : 'Could not leave participant role.'),
      );
      return null;
    } catch (e) {
      debugPrint('✗ leaveParticipant error: $e');
      SweetAlertHelper.showError(Get.context, 'Error', 'Could not leave participant role.');
      return null;
    }
  }

  /// Apply leave/join response counts + optional event mini-object without a full refetch.
  void _applyParticipationResponse(
    String eventId, {
    required Map<String, dynamic> data,
    String? roleLeft,
    String? roleJoined,
  }) {
    void removeFrom(RxList<dynamic> list) {
      list.removeWhere((e) => e is Map && e['id']?.toString() == eventId);
      list.refresh();
    }

    void ensureIn(RxList<dynamic> list, Map<String, dynamic>? mini) {
      final exists = list.any((e) => e is Map && e['id']?.toString() == eventId);
      if (exists) return;
      if (mini != null) {
        list.add(Map<String, dynamic>.from(mini));
      } else {
        list.add({'id': eventId});
      }
      list.refresh();
    }

    Map<String, dynamic>? mini;
    final ev = data['event'];
    if (ev is Map) {
      mini = Map<String, dynamic>.from(ev.map((k, v) => MapEntry(k.toString(), v)));
    }

    if (roleLeft == 'attendee') removeFrom(attendingList);
    if (roleLeft == 'volunteer') removeFrom(volunteeringList);
    if (roleLeft == 'participant') removeFrom(participatingList);

    if (roleJoined == 'attendee') {
      ensureIn(attendingList, mini);
      removeFrom(volunteeringList);
      removeFrom(participatingList);
    }

    void patchCounts(RxList<dynamic> list) {
      for (var i = 0; i < list.length; i++) {
        final e = list[i];
        if (e is! Map || e['id']?.toString() != eventId) continue;
        final m = Map<String, dynamic>.from(e);
        if (mini != null) m.addAll(mini);
        for (final key in [
          'attendee_count',
          'volunteer_count',
          'participant_count',
          'viewer_count',
        ]) {
          if (data.containsKey(key)) m[key] = data[key];
        }
        list[i] = m;
      }
      list.refresh();
    }

    patchCounts(liveEventCatalog);
    patchCounts(eventList);
    patchCounts(attendingList);
    patchCounts(volunteeringList);
    patchCounts(participatingList);
    patchCounts(favoriteList);
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

      final data = ApiService.parseResponseBody(response.data);
      if (data == null) {
        SweetAlertHelper.showError(Get.context, "Error", "Invalid response from server. Please try again.");
        isLoading.value = false;
        return;
      }

      final status = data['status']?.toString() ?? 'error';
      final message = data['message']?.toString() ?? 'Unknown error occurred';
      
      if (status == 'success') {
        if (Get.context != null) {
          Navigator.of(Get.context!, rootNavigator: true).maybePop();
        }
        fetchVolunteeringEvents();
        // Attendee → volunteer clears the attendee row on the backend; refresh so
        // the local attending state (and the "Viewer" button) updates immediately.
        fetchAttendingEvents();
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

  /// Switch between volunteer and participant for an approved event (API `event_staff_switch.php`).
  Future<bool> switchStaffRole({
    required String eventId,
    required String toRole,
    String? volunteerRole,
    String? departmentClass,
  }) async {
    isLoading.value = true;
    try {
      final userId = await PrefService.getUserId();
      if (userId == null) {
        SweetAlertHelper.showError(Get.context, 'Error', 'User not found. Please login again.');
        return false;
      }
      final body = <String, dynamic>{
        'event_id': int.tryParse(eventId) ?? eventId,
        'user_id': int.tryParse(userId) ?? userId,
        'to_role': toRole,
      };
      if (toRole == 'volunteer' && volunteerRole != null && volunteerRole.trim().isNotEmpty) {
        body['role'] = volunteerRole.trim();
      }
      if (toRole == 'participant' && departmentClass != null && departmentClass.trim().isNotEmpty) {
        body['department_class'] = departmentClass.trim();
      }
      final response = await ApiService.switchEventStaffRole(body);
      if (response.statusCode != null && response.statusCode! >= 400) {
        SweetAlertHelper.showError(
          Get.context,
          'Server Error',
          'Server returned error ${response.statusCode}. Please try again.',
        );
        return false;
      }
      final data = ApiService.parseResponseBody(response.data);
      if (data == null) {
        SweetAlertHelper.showError(Get.context, 'Error', 'Invalid response from server.');
        return false;
      }
      if (data['status']?.toString() == 'success') {
        await fetchVolunteeringEvents();
        await fetchParticipatingEvents();
        await fetchAttendingEvents();
        if (Get.isRegistered<ProfileController>()) {
          await Get.find<ProfileController>().loadProfile();
        }
        final serverMsg = data['message']?.toString().trim() ?? '';
        final fallback = toRole == 'volunteer'
            ? 'You have successfully switched to volunteer for this event.'
            : 'You have successfully switched to participant for this event.';
        SweetAlertHelper.showSuccess(
          Get.context,
          'Success',
          serverMsg.isNotEmpty ? serverMsg : fallback,
        );
        return true;
      }
      SweetAlertHelper.showError(
        Get.context,
        'Error',
        data['message']?.toString() ?? 'Could not switch role.',
      );
      return false;
    } catch (e) {
      debugPrint('switchStaffRole: $e');
      SweetAlertHelper.showError(Get.context, 'Error', 'Role switch failed.');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}