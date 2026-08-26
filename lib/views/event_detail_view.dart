import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../base/constant.dart';
import '../controllers/event_controller.dart';
import '../controllers/profile_controller.dart';
import '../utils/sweetalert_helper.dart';
import '../widgets/app_network_image.dart';
import '../widgets/event_poster_image.dart';
import 'volunteer_dialog.dart';
import 'edit_event_view.dart';
import '../data/api_service.dart';
import '../data/pref_service.dart';
import '../widgets/app_loading_screen.dart';
import '../widgets/participate_registration_sheet.dart';
import '../utils/event_participation_rules.dart';
import '../theme/app_theme.dart';

List<Map<String, dynamic>> reviewFilesFromEvent(dynamic ev) {
  if (ev is! Map) return [];
  final r = ev['review_files'];
  if (r is! List) return [];
  final out = <Map<String, dynamic>>[];
  for (final e in r) {
    if (e is Map<String, dynamic>) {
      out.add(e);
    } else if (e is Map) {
      out.add(Map<String, dynamic>.from(e.map((k, v) => MapEntry(k.toString(), v))));
    }
  }
  return out;
}

Future<void> openReviewFileUrl(BuildContext context, String path) async {
  final url = Constant.uploadPublicUrl(path);
  if (url.isEmpty) return;
  final u = Uri.tryParse(url);
  if (u == null) return;
  final ok = await launchUrl(u, mode: LaunchMode.externalApplication);
  if (!context.mounted) return;
  if (!ok) {
    SweetAlertHelper.showError(context, 'Open link', 'Could not open file URL.');
  }
}

class EventDetailView extends StatefulWidget {
  final dynamic event;
  const EventDetailView({super.key, required this.event});

  @override
  State<EventDetailView> createState() => _EventDetailViewState();
}

class _EventDetailViewState extends State<EventDetailView> {
  dynamic _event;
  bool _loadingFull = true;
  List<dynamic> _winnersList = [];

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _loadFullEvent();
  }

  Future<void> _loadFullEvent() async {
    final idRaw = _event is Map ? _event['id'] : null;
    final id = idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '');
    if (id == null || id <= 0) {
      setState(() => _loadingFull = false);
      return;
    }
    final EventController controller = Get.find<EventController>();
    final full = await controller.fetchEventById(id);
    if (full != null && mounted) {
      setState(() => _event = full);
      // Merge winners: keep event payload if API returns empty list (avoid unlocking attendance by mistake).
      List<dynamic> winners = [];
      if (full['winners'] is List && (full['winners'] as List).isNotEmpty) {
        winners = List<dynamic>.from(full['winners'] as List);
      }
      final winRes = await ApiService.getWinnersByEventId(id);
      if (mounted && winRes.data is Map && winRes.data['status'] == 'success') {
        final data = winRes.data['data'];
        if (data is List && data.isNotEmpty) {
          winners = List<dynamic>.from(data);
        }
      }
      if (mounted) setState(() => _winnersList = winners);
    }
    if (mounted) setState(() => _loadingFull = false);
  }

  bool _isApprovedEvent() {
    final status = (_event is Map ? _event['status'] : null)?.toString().toLowerCase() ?? '';
    return status == 'approved';
  }

  String _eventStatus() {
    return (_event is Map ? _event['status'] : null)?.toString().toLowerCase() ?? '';
  }

  bool _isPastEvent() {
    final endDateStr = (_event is Map ? _event['event_end_date'] : null)?.toString() ?? '';
    if (endDateStr.isNotEmpty && endDateStr != '0000-00-00 00:00:00') {
      final ed = DateTime.tryParse(endDateStr.replaceAll(' ', 'T'));
      if (ed != null) return ed.isBefore(DateTime.now());
    }
    final dateStr = (_event is Map ? _event['event_date'] : null)?.toString() ?? '';
    if (dateStr.isEmpty) return false;
    final d = DateTime.tryParse(dateStr.replaceAll(' ', 'T'));
    return d != null && d.isBefore(DateTime.now());
  }

  /// Same rule as backend: attendance from event calendar day onward.
  bool _onOrAfterEventDay() {
    final dateStr = (_event is Map ? _event['event_date'] : null)?.toString() ?? '';
    if (dateStr.isEmpty) return false;
    final d = DateTime.tryParse(dateStr.replaceAll(' ', 'T'));
    if (d == null) return false;
    final eventDay = DateTime(d.year, d.month, d.day);
    final n = DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    return !today.isBefore(eventDay);
  }

  DateTime? _eventCalendarDayOnly() {
    final dateStr = (_event is Map ? _event['event_date'] : null)?.toString() ?? '';
    if (dateStr.isEmpty) return null;
    final d = DateTime.tryParse(dateStr.replaceAll(' ', 'T'));
    if (d == null) return null;
    return DateTime(d.year, d.month, d.day);
  }

  DateTime _todayDateOnly() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  String _formatEventDateRange() {
    final startStr = (_event is Map ? _event['event_date'] : null)?.toString() ?? '';
    if (startStr.isEmpty) return 'Date TBD';
    final start = DateTime.tryParse(startStr.replaceAll(' ', 'T'));
    if (start == null) return startStr;

    final endStr = (_event is Map ? _event['event_end_date'] : null)?.toString() ?? '';
    final dateFmt = DateFormat('dd MMM yyyy');
    final timeFmt = DateFormat('hh:mm a');

    if (endStr.isEmpty || endStr == '0000-00-00 00:00:00') {
      return '${dateFmt.format(start)}, ${timeFmt.format(start)}';
    }
    final end = DateTime.tryParse(endStr.replaceAll(' ', 'T'));
    if (end == null) return '${dateFmt.format(start)}, ${timeFmt.format(start)}';

    final sameDay = start.year == end.year && start.month == end.month && start.day == end.day;
    if (sameDay) {
      return '${dateFmt.format(start)}, ${timeFmt.format(start)} – ${timeFmt.format(end)}';
    }
    return '${dateFmt.format(start)}, ${timeFmt.format(start)}\n→ ${dateFmt.format(end)}, ${timeFmt.format(end)}';
  }

  /// Editing is allowed only before the event calendar day (not on or after).
  bool _canEditEventBySchedule() {
    final ed = _eventCalendarDayOnly();
    if (ed == null) return true;
    return _todayDateOnly().isBefore(ed);
  }

  /// Organizer notification card through the event day (inclusive); hidden after.
  bool _canShowOrganizerNotificationBySchedule() {
    final ed = _eventCalendarDayOnly();
    if (ed == null) return true;
    return !_todayDateOnly().isAfter(ed);
  }

  Future<bool> _isEventOrganizerOnly() async {
    final uid = await PrefService.getUserId();
    if (uid == null || _event is! Map) return false;
    final oid = _event['organizer_id']?.toString() ?? '';
    return oid.isNotEmpty && oid == uid;
  }

  /// True if current user is organizer or in editor_ids
  Future<bool> _canEditEvent() async {
    final userId = await PrefService.getUserId();
    if (userId == null || _event is! Map) return false;
    final organizerId = _event['organizer_id']?.toString() ?? _event['hostId']?.toString();
    if (organizerId == userId) return true;
    final editorIds = _event['editor_ids'];
    if (editorIds is List) {
      for (final e in editorIds) {
        if (e.toString() == userId) return true;
      }
    }
    return false;
  }

  // FIXED: Improved role checking to handle both int and string types
  Future<Map<String, dynamic>> _getUserAndOrganizerRoles() async {
    try {
      final userId = await PrefService.getUserId();
      if (userId == null) {
        debugPrint("❌ No user ID found");
        return {
          'isStudent': false,
          'organizerIsStudent': false,
          'userId': null,
          'isOrganizer': false,
        };
      }
      
      // Get user profile to check if they're a student
      final userResponse = await ApiService.getUserProfile(userId);
      final dynamic userIsStudentRaw = userResponse.data['data']['is_student'];
      
      // Get organizer role from event data - handle both int and string
      final dynamic organizerIsStudentRaw = _event['organizer_is_student'];
      
      // Convert to int safely (handle both int and string types)
      int userIsStudentValue = 0;
      if (userIsStudentRaw is int) {
        userIsStudentValue = userIsStudentRaw;
      } else if (userIsStudentRaw is String) {
        userIsStudentValue = int.tryParse(userIsStudentRaw) ?? 0;
      }
      
      int organizerIsStudentValue = 0;
      if (organizerIsStudentRaw is int) {
        organizerIsStudentValue = organizerIsStudentRaw;
      } else if (organizerIsStudentRaw is String) {
        organizerIsStudentValue = int.tryParse(organizerIsStudentRaw) ?? 0;
      }
      
      // Convert to boolean: 1 = student, 0 = faculty
      final bool isStudent = userIsStudentValue == 1;
      final bool organizerIsStudent = organizerIsStudentValue == 1;
      
      debugPrint("👤 User is_student raw: $userIsStudentRaw → value: $userIsStudentValue → isStudent: $isStudent");
      debugPrint("🎯 Organizer is_student raw: $organizerIsStudentRaw → value: $organizerIsStudentValue → organizerIsStudent: $organizerIsStudent");
      debugPrint("✅ Roles match: ${isStudent == organizerIsStudent}");
      
      final isOrganizer = EventParticipationRules.isUserEventOrganizer(_event, userId);
      return {
        'isStudent': isStudent,
        'organizerIsStudent': organizerIsStudent,
        'userId': userId,
        'isOrganizer': isOrganizer,
      };
    } catch (e) {
      debugPrint("❌ Error getting roles: $e");
      return {
        'isStudent': false,
        'organizerIsStudent': false,
        'userId': null,
        'isOrganizer': false,
      };
    }
  }

  void _showAddEditorDialog(BuildContext context) {
    final id = int.tryParse((_event['id']).toString());
    if (id == null) return;
    final userIdCtrl = TextEditingController();
    final parentContext = context;
    Get.dialog(
      AlertDialog(
        title: const Text("Add editor"),
        content: TextField(
          controller: userIdCtrl,
          decoration: const InputDecoration(labelText: "User ID"),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final uid = userIdCtrl.text.trim();
              if (uid.isEmpty) return;
              Get.back();
              final r = await ApiService.addEventEditor(eventId: id, userId: uid);
              if (!parentContext.mounted) return;
              if (r.data is Map && r.data['status'] == 'success') {
                SweetAlertHelper.showSuccess(
                  parentContext,
                  "Success",
                  "Editor added.",
                  onConfirm: _loadFullEvent,
                );
              } else {
                SweetAlertHelper.showError(parentContext, "Error", (r.data is Map ? r.data['message'] : null)?.toString() ?? "Failed");
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5F15), foregroundColor: Colors.white),
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _showUploadCertificateSheet(BuildContext context) {
    final eventId = int.tryParse((_event['id']).toString());
    if (eventId == null) return;
    final parentContext = context;
    final volunteers = _event['volunteer_list'] is List ? _event['volunteer_list'] as List : [];
    final participants = _event['participant_list'] is List ? _event['participant_list'] as List : [];
    final allUsers = <Map<String, dynamic>>[];
    for (final v in volunteers) {
      if (v is Map && v['user_id'] != null) allUsers.add({'user_id': v['user_id'], 'name': v['student_name'] ?? 'Volunteer', 'type': 'volunteer'});
    }
    for (final p in participants) {
      if (p is Map && p['user_id'] != null) allUsers.add({'user_id': p['user_id'], 'name': p['student_name'] ?? 'Participant', 'type': 'participant'});
    }
    if (allUsers.isEmpty) {
      SweetAlertHelper.showInfo(parentContext, "Info", "No volunteers or participants for this event.");
      return;
    }
    String? selectedUserId = allUsers.first['user_id']?.toString();
    String selectedType = 'volunteer';
    File? selectedFile;
    Get.bottomSheet(
      StatefulBuilder(
        builder: (sheetContext, setModalState) {
          return Container(
            padding: EdgeInsets.all(20.w),
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text("Upload e-certificate", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16.h),
                  DropdownButtonFormField<String>(
                    value: selectedUserId ?? allUsers.first['user_id']?.toString(),
                    decoration: const InputDecoration(labelText: "User"),
                    items: allUsers.map((u) => DropdownMenuItem(value: u['user_id']?.toString(), child: Text(u['name'] ?? '${u['user_id']}'))).toList(),
                    onChanged: (v) => setModalState(() => selectedUserId = v),
                  ),
                  SizedBox(height: 12.h),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: "Type"),
                    items: const [DropdownMenuItem(value: 'volunteer', child: Text("Volunteer")), DropdownMenuItem(value: 'participant', child: Text("Participant"))],
                    onChanged: (v) => setModalState(() => selectedType = v ?? selectedType),
                  ),
                  SizedBox(height: 12.h),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final x = await picker.pickImage(source: ImageSource.gallery);
                      if (x != null) setModalState(() => selectedFile = File(x.path));
                    },
                    icon: const Icon(Icons.attach_file),
                    label: Text(selectedFile != null ? selectedFile!.path.split(RegExp(r'[/\\]')).last : "Pick certificate file"),
                  ),
                  SizedBox(height: 20.h),
                  ElevatedButton(
                    onPressed: selectedFile == null || selectedUserId == null
                        ? null
                        : () async {
                            final uid = selectedUserId ?? allUsers.first['user_id']?.toString();
                            if (uid == null) return;
                            final r = await ApiService.uploadCertificate(eventId: eventId, userId: uid, type: selectedType, file: selectedFile!);
                            Get.back();
                            if (!parentContext.mounted) return;
                            if (r.data is Map && r.data['status'] == 'success') {
                              SweetAlertHelper.showSuccess(parentContext, "Success", "Certificate uploaded.");
                            } else {
                              SweetAlertHelper.showError(parentContext, "Error", (r.data is Map ? r.data['message'] : null)?.toString() ?? "Failed");
                            }
                          },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5F15), foregroundColor: Colors.white),
                    child: const Text("Upload"),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  bool _eventAttendanceLocked() {
    if (_event is! Map) return false;
    final m = _event as Map;
    final al = m['attendance_locked'];
    if (al == true || al == 1 || al == '1') return true;
    final w = m['winners'];
    if (w is List && w.isNotEmpty) return true;
    if (_winnersList.isNotEmpty) return true;
    return false;
  }

  Future<void> _shareEvent(BuildContext shareButtonContext) async {
    if (_event is! Map) return;
    final m = Map<String, dynamic>.from((_event as Map).map((k, v) => MapEntry(k.toString(), v)));
    final idRaw = m['id'];
    final id = idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '');
    if (id == null || id <= 0) {
      if (shareButtonContext.mounted) {
        SweetAlertHelper.showError(shareButtonContext, 'Share', 'This event has no valid ID yet.');
      }
      return;
    }
    var url = (m['share_url'] ?? '').toString().trim();
    var text = (m['share_text'] ?? '').toString().trim();
    final title = (m['title'] ?? 'Event').toString();
    if (url.isEmpty) {
      url = 'https://micampus.co.in/event?id=$id';
    }
    if (text.isEmpty) {
      text = '$title\n$url';
    }
    final appDeep = 'micampus://event?id=$id';
    if (!text.contains('micampus://')) {
      text = '$text\n\nOpen in MiCampus app: $appDeep';
    }
    Rect? origin;
    final box = shareButtonContext.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      origin = box.localToGlobal(Offset.zero) & box.size;
    }
    try {
      await Share.share(text, subject: title, sharePositionOrigin: origin);
    } catch (e) {
      debugPrint('Share failed: $e');
      if (!shareButtonContext.mounted) return;
      SweetAlertHelper.showError(shareButtonContext, 'Share', 'Could not open the share sheet.');
    }
  }

  Future<void> _promptEditVolunteerRole(BuildContext context, Map<String, dynamic> row) async {
    final uid = int.tryParse(row['user_id']?.toString() ?? '');
    final eid = int.tryParse(_event['id']?.toString() ?? '');
    final oid = int.tryParse(_event['organizer_id']?.toString() ?? '');
    if (uid == null || eid == null || oid == null) return;
    final c = TextEditingController(text: (row['role'] ?? '').toString());
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Volunteer role'),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(labelText: 'Role (max 100 characters)'),
          maxLength: 100,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF5F15)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (go != true || !context.mounted) return;
    final role = c.text.trim();
    if (role.isEmpty) {
      SweetAlertHelper.showError(context, 'Error', 'Role is required.');
      return;
    }
    final r = await ApiService.eventOrganiserAction({
      'action': 'update_volunteer_role',
      'event_id': eid,
      'organizer_id': oid,
      'target_user_id': uid,
      'role': role,
    });
    if (ApiService.responseDataMap(r.data)?['status'] == 'success') {
      await _loadFullEvent();
      if (context.mounted) SweetAlertHelper.showSuccess(context, 'Saved', 'Volunteer role updated.');
    } else if (context.mounted) {
      SweetAlertHelper.showError(context, 'Error', ApiService.responseErrorHint(r));
    }
  }

  Future<void> _promptEditParticipantDepartment(BuildContext context, Map<String, dynamic> row) async {
    final uid = int.tryParse(row['user_id']?.toString() ?? '');
    final eid = int.tryParse(_event['id']?.toString() ?? '');
    final oid = int.tryParse(_event['organizer_id']?.toString() ?? '');
    if (uid == null || eid == null || oid == null) return;
    final c = TextEditingController(text: (row['department_class'] ?? '').toString());
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Department / class'),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(labelText: 'Shown as participant role on the list'),
          maxLength: 255,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF5F15)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (go != true || !context.mounted) return;
    final dept = c.text.trim();
    if (dept.isEmpty) {
      SweetAlertHelper.showError(context, 'Error', 'Department or class is required.');
      return;
    }
    final r = await ApiService.eventOrganiserAction({
      'action': 'update_participant_department',
      'event_id': eid,
      'organizer_id': oid,
      'target_user_id': uid,
      'department_class': dept,
    });
    if (ApiService.responseDataMap(r.data)?['status'] == 'success') {
      await _loadFullEvent();
      if (context.mounted) SweetAlertHelper.showSuccess(context, 'Saved', 'Participant details updated.');
    } else if (context.mounted) {
      SweetAlertHelper.showError(context, 'Error', ApiService.responseErrorHint(r));
    }
  }

  void _showParticipateDialog(BuildContext context, {required bool userIsStudent, bool switchFromVolunteer = false}) {
    if (!_isApprovedEvent()) {
      final st = _eventStatus();
      final label = st.isEmpty ? "pending" : st;
      SweetAlertHelper.showWarning(context, "Not Available", "This event is $label. You can participate only after approval.");
      return;
    }
    showParticipateRegistrationSheet(
      context,
      eventId: _event['id'].toString(),
      eventTitle: (_event['title'] ?? 'Event').toString(),
      organizerId: _event['organizer_id']?.toString(),
      eventSnapshot: _event,
      userIsStudent: userIsStudent,
      switchFromVolunteer: switchFromVolunteer,
      onSwitchSuccess: () => _loadFullEvent(),
    );
  }

  void _showSwitchToVolunteerDialog(BuildContext context, {required bool userIsStudent}) {
    if (!_isApprovedEvent()) {
      SweetAlertHelper.showWarning(context, 'Not Available', 'Role switch is only allowed for approved events.');
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => VolunteerDialog(
        event: _event,
        userIsStudent: userIsStudent,
        switchFromParticipant: true,
        onSwitchSuccess: () => _loadFullEvent(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final EventController controller = Get.find<EventController>();
    if (_loadingFull) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFFF5F15),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Get.back(),
          ),
        ),
        body: const AppLoadingScreen(message: 'Loading event...'),
      );
    }
    final List banners = _event['banners'] ?? [];
    final String organizerName = _event['organizer_name'] ?? _event['organizer'] ?? 'MiCampus';
    final String organizerAvatar = _event['organizer_avatar'] ?? 'default_avatar.png';
    final dynamic pendingEdit = _event['pending_edit'];
    final List winners = _winnersList.isNotEmpty ? _winnersList : (_event['winners'] is List ? _event['winners'] as List : []);
    final String rulesText = (_event is Map ? (_event['rules'] ?? '').toString().trim() : '');
    final List volunteerList = _event is Map && _event['volunteer_list'] is List ? _event['volunteer_list'] as List : [];
    final List participantList = _event is Map && _event['participant_list'] is List ? _event['participant_list'] as List : [];
    final String existingOrganizerReview = (_event is Map ? (_event['organizer_review'] ?? '').toString().trim() : '');
    final List<Map<String, dynamic>> reviewFiles = reviewFilesFromEvent(_event);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: RefreshIndicator(
        onRefresh: _loadFullEvent,
        color: AppColors.accent,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          cacheExtent: 400,
          slivers: [
          SliverAppBar(
            expandedHeight: 400.h,
            pinned: true,
            backgroundColor: AppColors.accent,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.black87),
              ),
              onPressed: () => Get.back(),
            ),
            actions: [
              // Brand logos intentionally omitted here: on this screen the app bar
              // sits over the event poster, and the GNU/MiCampus marks overlapped the
              // artwork and reduced its visual quality. Keep only functional controls.
              Builder(
                builder: (btnContext) => IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.share, color: Colors.black87),
                  ),
                  onPressed: () => _shareEvent(btnContext),
                ),
              ),
              Obx(() {
                final eid = _event['id'].toString();
                final isFav = controller.favoriteList.any(
                  (e) => e is Map && e['id']?.toString() == eid,
                );
                return IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: Colors.red,
                    ),
                  ),
                  onPressed: () => controller.toggleFavorite(eid),
                );
              }),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: banners.isNotEmpty
                ? PageView.builder(
                    itemCount: banners.length,
                    itemBuilder: (context, index) {
                      return EventPosterImage.fromUrl(
                        "https://micampus.co.in/admin/uploads/events/${banners[index]}",
                        category: _event is Map ? _event['category']?.toString() : null,
                      );
                    },
                  )
                : _buildPlaceholder(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: AppColors.categoryColor(_event['category']?.toString())
                          .withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: Text(
                      _event['category'] ?? "Event",
                      style: TextStyle(
                        color: AppColors.categoryColor(_event['category']?.toString()),
                        fontWeight: FontWeight.w700,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  
                  Text(
                    _event['title'] ?? "Untitled Event",
                    style: TextStyle(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                      height: 1.2,
                    ),
                    softWrap: true,
                  ),
                  
                  SizedBox(height: 20.h),
                  
                  _buildInfoTile(
                    Icons.calendar_today_rounded,
                    "Date & Time",
                    _formatEventDateRange(),
                  ),
                  
                  SizedBox(height: 10.h),
                  
                  _buildInfoTile(
                    Icons.location_on_rounded,
                    "Venue",
                    _event['venue'] ?? "Venue TBD",
                  ),

                  SizedBox(height: 10.h),

                  _buildInfoTile(
                    Icons.category_outlined,
                    "Category",
                    (_event['category'] ?? 'Event').toString(),
                  ),

                  SizedBox(height: 16.h),
                  _buildEngagementCountsStrip(),
                  
                  SizedBox(height: 28.h),
                  _sectionHeading("About Event"),
                  SizedBox(height: 10.h),
                  
                  Text(
                    _event['description'] ?? "No description available for this event.",
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: AppColors.navyMuted,
                      height: 1.6,
                    ),
                    softWrap: true,
                  ),

                  SizedBox(height: 24.h),

                  if (rulesText.isNotEmpty) ...[
                    _sectionHeading("Event rules"),
                    SizedBox(height: 10.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        rulesText,
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: AppColors.navyMuted,
                          height: 1.6,
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],

                  _sectionHeading("Team"),
                  SizedBox(height: 6.h),
                  Text(
                    "Volunteers and participants. Contact numbers are private and visible only to the organizer, who can use the edit icon to set volunteer role or participant department/class.",
                    style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary, height: 1.4),
                  ),
                  SizedBox(height: 12.h),
                  if (volunteerList.isEmpty && participantList.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        "No team members listed yet.",
                        style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
                      ),
                    )
                  else
                    FutureBuilder<bool>(
                      future: _isEventOrganizerOnly(),
                      builder: (context, orgSnap) {
                        final org = orgSnap.data == true && _isApprovedEvent();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (volunteerList.isNotEmpty) ...[
                              Text("Volunteers", style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: AppColors.accent)),
                              SizedBox(height: 8.h),
                              ...volunteerList.map<Widget>((v) {
                                if (v is! Map) return const SizedBox.shrink();
                                return _TeamMemberTile(
                                  map: v,
                                  defaultRoleLabel: 'Volunteer',
                                  showContact: org,
                                  onEditMeta: org
                                      ? () => _promptEditVolunteerRole(
                                            context,
                                            Map<String, dynamic>.from(v.map((k, val) => MapEntry(k.toString(), val))),
                                          )
                                      : null,
                                );
                              }),
                              SizedBox(height: 16.h),
                            ],
                            if (participantList.isNotEmpty) ...[
                              Text("Participants", style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: AppColors.success)),
                              SizedBox(height: 8.h),
                              ...participantList.map<Widget>((p) {
                                if (p is! Map) return const SizedBox.shrink();
                                return _TeamMemberTile(
                                  map: p,
                                  defaultRoleLabel: 'Participant',
                                  showContact: org,
                                  onEditMeta: org
                                      ? () => _promptEditParticipantDepartment(
                                            context,
                                            Map<String, dynamic>.from(p.map((k, val) => MapEntry(k.toString(), val))),
                                          )
                                      : null,
                                );
                              }),
                            ],
                          ],
                        );
                      },
                    ),

                  SizedBox(height: 24.h),

                  if (_isApprovedEvent() && _onOrAfterEventDay())
                    FutureBuilder<bool>(
                      future: _isEventOrganizerOnly(),
                      builder: (context, snap) {
                        if (snap.data != true) return const SizedBox.shrink();
                        return Padding(
                          padding: EdgeInsets.only(bottom: 24.h),
                          child: _OrganizerAttendancePanel(
                            key: ValueKey(
                              'att_${_event['id']}_${volunteerList.length}_${participantList.length}_${_eventAttendanceLocked()}',
                            ),
                            event: Map<String, dynamic>.from(_event as Map),
                            onSaved: _loadFullEvent,
                            attendanceLocked: _eventAttendanceLocked(),
                          ),
                        );
                      },
                    ),

                  if (_isApprovedEvent() && _isPastEvent())
                    FutureBuilder<bool>(
                      future: _isEventOrganizerOnly(),
                      builder: (context, snap) {
                        if (snap.connectionState != ConnectionState.done) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: 16.h),
                            child: const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent))),
                          );
                        }
                        final isOrg = snap.data == true;
                        if (isOrg) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: 24.h),
                            child: _OrganizerReviewEditor(
                              key: ValueKey(
                                'rev_${_event['id']}_${existingOrganizerReview.hashCode}_${reviewFiles.length}',
                              ),
                              event: Map<String, dynamic>.from(_event as Map),
                              onSaved: _loadFullEvent,
                            ),
                          );
                        }
                        if (existingOrganizerReview.isEmpty && reviewFiles.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: EdgeInsets.only(bottom: 24.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionHeading("Organizer review"),
                              SizedBox(height: 12.h),
                              if (existingOrganizerReview.isNotEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(16.w),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Text(
                                    existingOrganizerReview,
                                    style: TextStyle(fontSize: 15.sp, color: AppColors.navyMuted, height: 1.5),
                                  ),
                                ),
                              if (reviewFiles.isNotEmpty) ...[
                                if (existingOrganizerReview.isNotEmpty) SizedBox(height: 12.h),
                                Text(
                                  'Attachments',
                                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: AppColors.navy),
                                ),
                                SizedBox(height: 8.h),
                                Wrap(
                                  spacing: 8.w,
                                  runSpacing: 8.h,
                                  children: reviewFiles.map((f) {
                                    final name = (f['original_name'] ?? 'File').toString();
                                    final path = (f['file_path'] ?? '').toString();
                                    final ft = (f['file_type'] ?? '').toString().toLowerCase();
                                    final isPdf = ft.contains('pdf') || name.toLowerCase().endsWith('.pdf');
                                    return ActionChip(
                                      avatar: Icon(isPdf ? Icons.picture_as_pdf : Icons.image, size: 18, color: isPdf ? Colors.red.shade700 : Colors.blue.shade700),
                                      label: Text(name, style: TextStyle(fontSize: 12.sp)),
                                      onPressed: path.isEmpty ? null : () => openReviewFileUrl(context, path),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),

                  // Pending edit banner
                  if (pendingEdit != null && pendingEdit is Map) ...[
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade700),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.pending_actions, color: Colors.amber.shade800, size: 24),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              "An edit is pending admin approval. The event will update in the list once approved.",
                              style: TextStyle(color: Colors.amber.shade900, fontSize: 13.sp),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],

                  // Winners section (always show; empty state when no winners)
                  _sectionHeading("Winners"),
                  SizedBox(height: 12.h),
                  if (winners.isNotEmpty)
                    ...winners.map<Widget>((w) {
                      final posRaw = w is Map ? w['position'] : null;
                      final pos = posRaw is int
                          ? posRaw
                          : int.tryParse(posRaw?.toString() ?? '') ?? 0;
                      final name = (w is Map ? w['full_name'] : null)?.toString() ?? '—';
                      return Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              _DetailRankBadge(position: pos),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.navy,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    })
                  else
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.emoji_events_outlined, size: 24.w, color: AppColors.textSecondary),
                          SizedBox(width: 12.w),
                          Text(
                            "No winners are announced yet.",
                            style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: 24.h),

                  // Edit button (organizer or editor) — only before the event day
                  if (_isApprovedEvent() && _canEditEventBySchedule())
                    FutureBuilder<bool>(
                      future: _canEditEvent(),
                      builder: (context, snap) {
                        if (snap.data != true) return const SizedBox.shrink();
                        return Padding(
                          padding: EdgeInsets.only(bottom: 16.h),
                          child: OutlinedButton.icon(
                            onPressed: () => Get.to(() => EditEventView(event: _event), transition: Transition.rightToLeft)?.then((_) => _loadFullEvent()),
                            icon: const Icon(Icons.edit),
                            label: const Text("Edit event"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFFF5F15),
                              side: const BorderSide(color: Color(0xFFFF5F15)),
                            ),
                          ),
                        );
                      },
                    ),

                  // Organizer: Send notification — through event day only
                  if (_isApprovedEvent() && _canShowOrganizerNotificationBySchedule())
                    FutureBuilder<bool>(
                      future: _canEditEvent(),
                      builder: (context, snap) {
                        if (snap.data != true) return const SizedBox.shrink();
                        return Padding(
                          padding: EdgeInsets.only(bottom: 16.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _SendNotificationCard(
                                event: _event,
                                onSent: () {},
                              ),
                              SizedBox(height: 12.h),
                              _OrganizerBroadcastAllCard(
                                event: _event,
                                onSent: () {},
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  if (_isPastEvent())
                    Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: Text(
                        "Certificates for this event (if uploaded by admin) are available in My Events → Certificates.",
                        style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
                      ),
                    ),

                  // Admin: Manage editors
                  Obx(() {
                    final isAdmin = Get.isRegistered<ProfileController>() && Get.find<ProfileController>().userData.value.isAdmin == true;
                    if (!isAdmin) return const SizedBox.shrink();
                    final editorIds = _event['editor_ids'] is List ? _event['editor_ids'] as List : [];
                    return Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeading("Manage editors"),
                          SizedBox(height: 8.h),
                          ...editorIds.map<Widget>((e) {
                            final uid = e.toString();
                            return ListTile(
                              dense: true,
                              title: Text("User ID: $uid"),
                              trailing: IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                onPressed: () async {
                                  final id = int.tryParse((_event['id']).toString());
                                  if (id == null) return;
                                  final r = await ApiService.removeEventEditor(eventId: id, userId: uid);
                                  if (r.data is Map && r.data['status'] == 'success') await _loadFullEvent();
                                },
                              ),
                            );
                          }),
                          OutlinedButton.icon(
                            onPressed: () => _showAddEditorDialog(context),
                            icon: const Icon(Icons.person_add),
                            label: const Text("Add editor"),
                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.accent, side: const BorderSide(color: AppColors.accent)),
                          ),
                        ],
                      ),
                    );
                  }),

                  // Admin: Upload certificate (past events only)
                  if (_isPastEvent())
                    Obx(() {
                      final isAdmin = Get.isRegistered<ProfileController>() && Get.find<ProfileController>().userData.value.isAdmin == true;
                      if (!isAdmin) return const SizedBox.shrink();
                      return Padding(
                        padding: EdgeInsets.only(bottom: 16.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionHeading("Upload e-certificate"),
                            SizedBox(height: 8.h),
                            OutlinedButton.icon(
                              onPressed: () => _showUploadCertificateSheet(context),
                              icon: const Icon(Icons.upload_file),
                              label: const Text("Upload for volunteer/participant"),
                              style: OutlinedButton.styleFrom(foregroundColor: AppColors.accent, side: const BorderSide(color: AppColors.accent)),
                            ),
                          ],
                        ),
                      );
                    }),
                  
                  SizedBox(height: 32.h),
                  
                  _sectionHeading("Hosted By"),
                  SizedBox(height: 12.h),
                  
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppShadows.card,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 25.w,
                          backgroundColor: AppColors.accent,
                          backgroundImage: organizerAvatar != 'default_avatar.png'
                            ? appNetworkImageProvider("https://micampus.co.in/admin/uploads/profiles/$organizerAvatar")
                            : null,
                          child: organizerAvatar == 'default_avatar.png'
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // FIXED: Show actual organizer name
                              Text(
                                organizerName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700, 
                                  fontSize: 16.sp,
                                  color: AppColors.navy,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                maxLines: 1,
                              ),
                              Text(
                                "Event Organizer",
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 120.h),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
      bottomSheet: FutureBuilder<Map<String, dynamic>>(
        future: _getUserAndOrganizerRoles(),
        builder: (context, snapshot) {
          Widget sheetShell({required Widget child}) {
            return Material(
              color: AppColors.surface,
              elevation: 12,
              shadowColor: AppColors.navy.withValues(alpha: 0.18),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
                  child: child,
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return sheetShell(
              child: SizedBox(
                height: 48.h,
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
              ),
            );
          }
          
          final roles = snapshot.data!;
          final bool isStudent = roles['isStudent'] as bool;
          final bool organizerIsStudent = roles['organizerIsStudent'] as bool;
          final bool rolesMatch = isStudent == organizerIsStudent;
          final String? userId = roles['userId'] as String?;
          final bool isOrganizer = roles['isOrganizer'] as bool? ?? false;
          
          debugPrint("🔍 Final check - User: $isStudent, Organizer: $organizerIsStudent, Match: $rolesMatch");
          
          if (isOrganizer) {
            return sheetShell(
              child: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.navyMuted, size: 22),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'As the organiser, you cannot attend, volunteer, or register as a participant for this event.',
                        style: TextStyle(color: AppColors.navy, fontSize: 13.sp, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          
          return sheetShell(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Approval status banner
                if (!_isApprovedEvent()) ...[
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule, color: AppColors.gold, size: 20),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            "This event is ${_eventStatus().isEmpty ? 'pending' : _eventStatus()}. "
                            "Join/Volunteer/Participate will be enabled after admin approval.",
                            style: TextStyle(
                              color: AppColors.navy,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),
                ],

                // Cross-type: volunteer/participant not available for this organiser group
                if (!rolesMatch) ...[
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.gold, size: 20),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            "Volunteer and participant registration is only for events organised by your own group. You can still join this event as a viewer.",
                            style: TextStyle(
                              color: AppColors.navy,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),
                ],

                // Buttons row
                Row(
                  children: [
                    Expanded(
                      child: Obx(() {
                        final eid = _event['id'].toString();
                        final attending = controller.attendingList.any((e) => e['id'].toString() == eid);
                        final volunteering = controller.volunteeringList.any((e) => e['id'].toString() == eid) ||
                            (userId != null && EventParticipationRules.userInVolunteerList(_event, userId));
                        final participating = controller.participatingList.any((e) => e['id'].toString() == eid) ||
                            (userId != null && EventParticipationRules.userInParticipantList(_event, userId));
                        final blockAttend = volunteering || participating;
                        return ElevatedButton(
                          onPressed: (!_isApprovedEvent() || attending || blockAttend)
                              ? null
                              : () => controller.joinEvent(
                                    eid,
                                    organizerId: _event['organizer_id']?.toString(),
                                    eventSnapshot: _event,
                                    userIsStudent: isStudent,
                                  ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: attending ? AppColors.surfaceMuted : AppColors.accent,
                            foregroundColor: attending ? AppColors.textSecondary : Colors.white,
                            disabledBackgroundColor: AppColors.surfaceMuted,
                            disabledForegroundColor: AppColors.textSecondary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            elevation: 0,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(attending ? Icons.check : Icons.check_circle, size: 18),
                              SizedBox(height: 4.h),
                              Text(
                                attending ? "Viewer" : (blockAttend ? "Attend" : "Join"),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),

                    if (rolesMatch) ...[
                      SizedBox(width: 10.w),
                      // Volunteer Button
                      Expanded(
                        child: Obx(() {
                          final eid = _event['id'].toString();
                          final volunteering = controller.volunteeringList.any((e) => e['id'].toString() == eid) ||
                              (userId != null && EventParticipationRules.userInVolunteerList(_event, userId));
                          final participating = controller.participatingList.any((e) => e['id'].toString() == eid) ||
                              (userId != null && EventParticipationRules.userInParticipantList(_event, userId));
                          final canSwitchToParticipant = volunteering && !participating && _isApprovedEvent();
                          return OutlinedButton(
                            // Attendees may switch straight to volunteer (backend
                            // removes the attendee row), so don't disable on `attending`.
                            onPressed: canSwitchToParticipant
                                ? () => _showParticipateDialog(context, userIsStudent: isStudent, switchFromVolunteer: true)
                                : (!_isApprovedEvent() || volunteering || participating)
                                    ? null
                                    : () => showDialog(
                                          context: context,
                                          builder: (context) => VolunteerDialog(
                                            event: _event,
                                            userIsStudent: isStudent,
                                          ),
                                        ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: canSwitchToParticipant
                                  ? AppColors.success
                                  : (volunteering ? AppColors.textSecondary : AppColors.accent),
                              side: BorderSide(
                                color: canSwitchToParticipant
                                    ? AppColors.success
                                    : (volunteering ? AppColors.border : AppColors.accent),
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  canSwitchToParticipant ? Icons.swap_horiz : Icons.volunteer_activism,
                                  size: 18,
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  canSwitchToParticipant
                                      ? "→ Participant"
                                      : (volunteering ? "Volunteered" : "Volunteer"),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                      SizedBox(width: 10.w),
                      
                      // Participate Button
                      Expanded(
                        child: Obx(() {
                          final eid = _event['id'].toString();
                          final volunteering = controller.volunteeringList.any((e) => e['id'].toString() == eid) ||
                              (userId != null && EventParticipationRules.userInVolunteerList(_event, userId));
                          final participating = controller.participatingList.any((e) => e['id'].toString() == eid) ||
                              (userId != null && EventParticipationRules.userInParticipantList(_event, userId));
                          final canSwitchToVolunteer = participating && !volunteering && _isApprovedEvent();
                          return OutlinedButton(
                            // Attendees may switch straight to participant (backend
                            // removes the attendee row), so don't disable on `attending`.
                            onPressed: canSwitchToVolunteer
                                ? () => _showSwitchToVolunteerDialog(context, userIsStudent: isStudent)
                                : (!_isApprovedEvent() || participating || volunteering)
                                    ? null
                                    : () => _showParticipateDialog(context, userIsStudent: isStudent),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: canSwitchToVolunteer
                                  ? AppColors.accent
                                  : (participating ? AppColors.textSecondary : AppColors.success),
                              side: BorderSide(
                                color: canSwitchToVolunteer
                                    ? AppColors.accent
                                    : (participating ? AppColors.border : AppColors.success),
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  canSwitchToVolunteer ? Icons.swap_horiz : Icons.groups,
                                  size: 18,
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  canSwitchToVolunteer
                                      ? "→ Volunteer"
                                      : (participating ? "Participating" : "Participate"),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionHeading(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.navy,
      ),
    );
  }

  Widget _buildPlaceholder() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [AppColors.accent.withValues(alpha: 0.3), AppColors.accentDark.withValues(alpha: 0.3)],
      ),
    ),
    child: const Center(child: Icon(Icons.event, size: 80, color: Colors.white)),
  );

  Widget _buildEngagementCountsStrip() {
    if (_event is! Map) return const SizedBox.shrink();
    final m = _event as Map;
    int n(dynamic x) {
      if (x == null) return 0;
      if (x is int) return x;
      return int.tryParse(x.toString()) ?? 0;
    }

    final viewers = n(m['viewer_count'] ?? m['attendee_count']);
    final vol = n(m['volunteer_count']);
    final part = n(m['participant_count']);

    Widget chip(IconData ic, String label, int count) {
      return Expanded(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 4.w),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(ic, size: 20, color: AppColors.accent),
              SizedBox(height: 6.h),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                    height: 1.1,
                  ),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                '$count',
                textAlign: TextAlign.center,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        chip(Icons.visibility_outlined, 'Viewers', viewers),
        SizedBox(width: 8.w),
        chip(Icons.volunteer_activism, 'Volunteers', vol),
        SizedBox(width: 8.w),
        chip(Icons.groups_outlined, 'Participants', part),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.accent, size: 22),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15.sp,
                    color: AppColors.navy,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRankBadge extends StatelessWidget {
  final int position;

  const _DetailRankBadge({required this.position});

  static const _gold = Color(0xFFFFD700);
  static const _silver = Color(0xFFC0C0C0);
  static const _bronze = Color(0xFFCD7F32);

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final bool isMedal;
    switch (position) {
      case 1:
        bg = _gold;
        fg = Colors.white;
        isMedal = true;
        break;
      case 2:
        bg = _silver;
        fg = const Color(0xFF2F2F2F);
        isMedal = true;
        break;
      case 3:
        bg = _bronze;
        fg = Colors.white;
        isMedal = true;
        break;
      default:
        bg = AppColors.surfaceMuted;
        fg = AppColors.navyMuted;
        isMedal = false;
    }

    return Container(
      width: 30.w,
      height: 30.w,
      decoration: BoxDecoration(
        gradient: isMedal
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(bg, Colors.white, 0.28)!,
                  bg,
                  Color.lerp(bg, Colors.black, 0.12)!,
                ],
              )
            : null,
        color: isMedal ? null : bg,
        shape: BoxShape.circle,
        boxShadow: isMedal
            ? [
                BoxShadow(
                  color: bg.withValues(alpha: 0.4),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
        border: Border.all(
          color: isMedal
              ? Colors.white.withValues(alpha: 0.65)
              : AppColors.border,
          width: isMedal ? 1.5 : 1,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (position == 1)
            Positioned(
              top: 2.h,
              child: Icon(
                Icons.star_rounded,
                size: 8.w,
                color: Colors.white.withValues(alpha: 0.95),
              ),
            ),
          Padding(
            padding: EdgeInsets.only(top: position == 1 ? 4.h : 0),
            child: Text(
              '$position',
              style: TextStyle(
                fontSize: position == 1 ? 11.sp : 12.sp,
                fontWeight: FontWeight.w800,
                color: fg,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamMemberTile extends StatelessWidget {
  final Map<dynamic, dynamic> map;
  final String defaultRoleLabel;
  final VoidCallback? onEditMeta;
  /// Contact numbers are private and shown only to the event organiser.
  final bool showContact;

  const _TeamMemberTile({
    required this.map,
    required this.defaultRoleLabel,
    this.onEditMeta,
    this.showContact = false,
  });

  @override
  Widget build(BuildContext context) {
    final name = (map['full_name'] ?? map['student_name'] ?? '—').toString();
    final role = (map['role'] ?? defaultRoleLabel).toString();
    final phone = showContact ? (map['phone'] ?? map['contact_number'] ?? '').toString() : '';
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        tileColor: Colors.grey.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        leading: const Icon(Icons.person_outline, color: Color(0xFFFF5F15)),
        title: Text(name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.sp)),
        subtitle: Text(
          '$role${phone.isNotEmpty ? ' · $phone' : ''}',
          style: TextStyle(fontSize: 13.sp, color: Colors.grey[700]),
        ),
        trailing: onEditMeta == null
            ? null
            : IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Edit',
                onPressed: onEditMeta,
              ),
      ),
    );
  }
}

bool _rowMarkedAttended(Map<dynamic, dynamic> m) {
  final a = m['attended'];
  if (a == true || a == 1 || a == '1') return true;
  return false;
}

class _OrganizerAttendancePanel extends StatefulWidget {
  final Map<String, dynamic> event;
  final VoidCallback onSaved;
  final bool attendanceLocked;

  const _OrganizerAttendancePanel({
    super.key,
    required this.event,
    required this.onSaved,
    this.attendanceLocked = false,
  });

  @override
  State<_OrganizerAttendancePanel> createState() => _OrganizerAttendancePanelState();
}

class _OrganizerAttendancePanelState extends State<_OrganizerAttendancePanel> {
  final Map<int, bool> _vol = {};
  final Map<int, bool> _part = {};
  bool _saving = false;

  void _loadAttendanceFromEvent() {
    _vol.clear();
    _part.clear();
    final vl = widget.event['volunteer_list'];
    if (vl is List) {
      for (final x in vl) {
        if (x is Map && x['user_id'] != null) {
          final id = int.tryParse(x['user_id'].toString());
          if (id != null) _vol[id] = _rowMarkedAttended(x);
        }
      }
    }
    final pl = widget.event['participant_list'];
    if (pl is List) {
      for (final x in pl) {
        if (x is Map && x['user_id'] != null) {
          final id = int.tryParse(x['user_id'].toString());
          if (id != null) _part[id] = _rowMarkedAttended(x);
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAttendanceFromEvent();
  }

  @override
  void didUpdateWidget(covariant _OrganizerAttendancePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.event['id'] != widget.event['id'] ||
        oldWidget.event['volunteer_list'] != widget.event['volunteer_list'] ||
        oldWidget.event['participant_list'] != widget.event['participant_list'] ||
        oldWidget.attendanceLocked != widget.attendanceLocked) {
      _loadAttendanceFromEvent();
      setState(() {});
    }
  }

  String _nameFromRow(Map<dynamic, dynamic> m) {
    return (m['full_name'] ?? m['student_name'] ?? 'User').toString();
  }

  Future<void> _submit() async {
    if (widget.attendanceLocked) {
      if (mounted) {
        SweetAlertHelper.showInfo(context, 'Locked', 'Attendance cannot be changed after winners are recorded.');
      }
      return;
    }
    final eid = int.tryParse(widget.event['id'].toString());
    final oid = int.tryParse(widget.event['organizer_id'].toString());
    if (eid == null || oid == null) return;
    if (_vol.isEmpty && _part.isEmpty) {
      SweetAlertHelper.showInfo(context, 'Info', 'No volunteers or participants to mark.');
      return;
    }
    setState(() => _saving = true);
    try {
      if (_vol.isNotEmpty) {
        final att = _vol.entries.map((e) => {'user_id': e.key, 'present': e.value ? 1 : 0}).toList();
        final r = await ApiService.eventOrganiserAction({
          'action': 'set_attendance',
          'event_id': eid,
          'organizer_id': oid,
          'role': 'volunteer',
          'attendance': att,
        });
        final ok = ApiService.responseDataMap(r.data)?['status'] == 'success';
        if (!ok) {
          if (mounted) {
            SweetAlertHelper.showError(context, 'Error', ApiService.responseErrorHint(r));
          }
          return;
        }
      }
      if (_part.isNotEmpty) {
        final att = _part.entries.map((e) => {'user_id': e.key, 'present': e.value ? 1 : 0}).toList();
        final r = await ApiService.eventOrganiserAction({
          'action': 'set_attendance',
          'event_id': eid,
          'organizer_id': oid,
          'role': 'participant',
          'attendance': att,
        });
        final ok = ApiService.responseDataMap(r.data)?['status'] == 'success';
        if (!ok) {
          if (mounted) {
            SweetAlertHelper.showError(context, 'Error', ApiService.responseErrorHint(r));
          }
          return;
        }
      }
      if (mounted) {
        SweetAlertHelper.showSuccess(
          context,
          'Saved',
          'Attendance updated.',
          onConfirm: widget.onSaved,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vl = widget.event['volunteer_list'];
    final pl = widget.event['participant_list'];
    final volRows = vl is List
        ? vl.whereType<Map>().map((e) => e).toList()
        : <Map<dynamic, dynamic>>[];
    final partRows = pl is List
        ? pl.whereType<Map>().map((e) => e).toList()
        : <Map<dynamic, dynamic>>[];

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fact_check, color: Colors.teal.shade800, size: 22),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Mark attendance (from event day onward)',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.teal.shade900),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'Check who was present for volunteers and participants.',
            style: TextStyle(fontSize: 12.sp, color: Colors.teal.shade900),
          ),
          if (widget.attendanceLocked) ...[
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade700),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_outline, color: Colors.amber.shade900, size: 22),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'Attendance is locked: winners have been recorded for this event.',
                      style: TextStyle(fontSize: 12.sp, color: Colors.amber.shade900, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 16.h),
          if (volRows.isEmpty && partRows.isEmpty)
            Text('No volunteers or participants yet.', style: TextStyle(color: Colors.grey[700]))
          else ...[
            if (volRows.isNotEmpty) ...[
              Text('Volunteers', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp)),
              ...volRows.map((m) {
                final uid = int.tryParse(m['user_id'].toString());
                if (uid == null) return const SizedBox.shrink();
                if (widget.attendanceLocked) {
                  final present = _rowMarkedAttended(m);
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      present ? Icons.check_circle : Icons.remove_circle_outline,
                      color: present ? Colors.teal.shade700 : Colors.grey,
                      size: 22,
                    ),
                    title: Text(_nameFromRow(m), style: TextStyle(fontSize: 14.sp)),
                    subtitle: Text((m['role'] ?? 'Volunteer').toString(), style: TextStyle(fontSize: 12.sp)),
                  );
                }
                return CheckboxListTile(
                  dense: true,
                  value: _vol[uid] ?? false,
                  onChanged: (v) => setState(() => _vol[uid] = v ?? false),
                  title: Text(_nameFromRow(m), style: TextStyle(fontSize: 14.sp)),
                  subtitle: Text((m['role'] ?? 'Volunteer').toString(), style: TextStyle(fontSize: 12.sp)),
                );
              }),
            ],
            if (partRows.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Text('Participants', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp)),
              ...partRows.map((m) {
                final uid = int.tryParse(m['user_id'].toString());
                if (uid == null) return const SizedBox.shrink();
                if (widget.attendanceLocked) {
                  final present = _rowMarkedAttended(m);
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      present ? Icons.check_circle : Icons.remove_circle_outline,
                      color: present ? Colors.teal.shade700 : Colors.grey,
                      size: 22,
                    ),
                    title: Text(_nameFromRow(m), style: TextStyle(fontSize: 14.sp)),
                    subtitle: Text((m['role'] ?? m['department_class'] ?? 'Participant').toString(), style: TextStyle(fontSize: 12.sp)),
                  );
                }
                return CheckboxListTile(
                  dense: true,
                  value: _part[uid] ?? false,
                  onChanged: (v) => setState(() => _part[uid] = v ?? false),
                  title: Text(_nameFromRow(m), style: TextStyle(fontSize: 14.sp)),
                  subtitle: Text((m['role'] ?? m['department_class'] ?? 'Participant').toString(), style: TextStyle(fontSize: 12.sp)),
                );
              }),
            ],
            if (!widget.attendanceLocked) ...[
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                  ),
                  child: _saving
                      ? SizedBox(width: 22.w, height: 22.h, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save attendance'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _OrganizerReviewEditor extends StatefulWidget {
  final Map<String, dynamic> event;
  final VoidCallback onSaved;

  const _OrganizerReviewEditor({super.key, required this.event, required this.onSaved});

  @override
  State<_OrganizerReviewEditor> createState() => _OrganizerReviewEditorState();
}

class _OrganizerReviewEditorState extends State<_OrganizerReviewEditor> {
  late final TextEditingController _ctrl;
  bool _saving = false;
  final List<PlatformFile> _pendingFiles = [];

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: (widget.event['organizer_review'] ?? '').toString());
  }

  @override
  void didUpdateWidget(covariant _OrganizerReviewEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = (widget.event['organizer_review'] ?? '').toString();
    final prev = (oldWidget.event['organizer_review'] ?? '').toString();
    if (next != prev && _ctrl.text == prev) {
      _ctrl.text = next;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _pickAttachments() async {
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'pdf'],
    );
    if (res == null || !mounted) return;
    setState(() {
      for (final f in res.files) {
        if (f.path != null && f.path!.isNotEmpty) _pendingFiles.add(f);
      }
    });
  }

  void _removePending(int i) {
    setState(() => _pendingFiles.removeAt(i));
  }

  Future<void> _submit() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) {
      SweetAlertHelper.showWarning(context, 'Required', 'Please write your review.');
      return;
    }
    final eid = int.tryParse(widget.event['id'].toString());
    final oid = int.tryParse(widget.event['organizer_id'].toString());
    if (eid == null || oid == null) return;
    setState(() => _saving = true);
    try {
      final files = <File>[];
      for (final p in _pendingFiles) {
        final path = p.path;
        if (path != null && path.isNotEmpty) {
          final f = File(path);
          if (await f.exists()) files.add(f);
        }
      }
      final r = await ApiService.eventOrganiserSetReviewMultipart(
        eventId: eid,
        organizerId: oid,
        organizerReview: text,
        reviewFiles: files,
      );
      final ok = ApiService.responseDataMap(r.data)?['status'] == 'success';
      if (ok) {
        if (mounted) {
          setState(() => _pendingFiles.clear());
          SweetAlertHelper.showSuccess(
            context,
            'Saved',
            'Review saved.',
            onConfirm: widget.onSaved,
          );
        }
      } else {
        if (mounted) {
          SweetAlertHelper.showError(context, 'Error', ApiService.responseErrorHint(r));
        }
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = reviewFilesFromEvent(widget.event);
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event Report',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.purple.shade900),
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: _ctrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Share how the event went, highlights, thanks...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            'Attachments (images or PDF)',
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: Colors.purple.shade900),
          ),
          SizedBox(height: 6.h),
          if (existing.isNotEmpty) ...[
            Text('Already uploaded', style: TextStyle(fontSize: 12.sp, color: Colors.purple.shade800)),
            SizedBox(height: 6.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: existing.map((f) {
                final name = (f['original_name'] ?? 'File').toString();
                final path = (f['file_path'] ?? '').toString();
                return InputChip(
                  label: Text(name, style: TextStyle(fontSize: 11.sp)),
                  onPressed: path.isEmpty ? null : () => openReviewFileUrl(context, path),
                );
              }).toList(),
            ),
            SizedBox(height: 8.h),
          ],
          OutlinedButton.icon(
            onPressed: _saving ? null : _pickAttachments,
            icon: const Icon(Icons.attach_file, size: 18),
            label: const Text('Add files'),
          ),
          if (_pendingFiles.isNotEmpty) ...[
            SizedBox(height: 8.h),
            ...List.generate(_pendingFiles.length, (i) {
              final name = _pendingFiles[i].name;
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.sp)),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: _saving ? null : () => _removePending(i),
                ),
              );
            }),
          ],
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade700,
                foregroundColor: Colors.white,
              ),
              child: _saving
                  ? SizedBox(width: 22.w, height: 22.h, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Post review'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card for organizer to send a push notification to volunteers and/or participants.
class _SendNotificationCard extends StatefulWidget {
  final dynamic event;
  final VoidCallback onSent;

  const _SendNotificationCard({required this.event, required this.onSent});

  @override
  State<_SendNotificationCard> createState() => _SendNotificationCardState();
}

class _SendNotificationCardState extends State<_SendNotificationCard> {
  final TextEditingController _messageController = TextEditingController();
  String _recipientType = 'both';
  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      SweetAlertHelper.showWarning(context, "Empty message", "Please type a message to send.");
      return;
    }
    final eventId = int.tryParse((widget.event['id']).toString());
    final organizerId = widget.event['organizer_id']?.toString() ?? widget.event['hostId']?.toString();
    if (eventId == null || organizerId == null) return;
    setState(() => _sending = true);
    try {
      final res = await ApiService.sendEventNotification(
        eventId: eventId,
        organizerId: organizerId,
        message: message,
        recipientType: _recipientType,
      );
      if (mounted) {
        setState(() => _sending = false);
        Map<String, dynamic>? data = ApiService.responseDataMap(res.data);
        if (data == null && res.data is String) {
          try {
            data = ApiService.responseDataMap(jsonDecode(res.data as String));
          } catch (_) {}
        }
        if (kDebugMode) {
          debugPrint(
            'sendEventNotification HTTP ${res.statusCode} '
            'rawData=${res.data} statusMessage=${res.statusMessage}',
          );
        }
        if (res.statusCode == 429) {
          final msg = (data != null && data['message'] != null && data['message'].toString().trim().isNotEmpty)
              ? data['message'].toString()
              : 'Too many notifications today for this event.';
          SweetAlertHelper.showWarning(context, "Limit reached", msg);
          return;
        }
        final statusOk =
            data != null && data['status']?.toString().toLowerCase().trim() == 'success';
        if (statusOk) {
          _messageController.clear();
          final pushSentRaw = data['push_sent'];
          final sent = pushSentRaw is int
              ? pushSentRaw
              : int.tryParse(pushSentRaw?.toString() ?? '') ?? 0;
          final serverMsg = data['message']?.toString().trim() ?? '';
          if (sent == 0 && serverMsg.isNotEmpty) {
            SweetAlertHelper.showInfo(context, "Notice", serverMsg);
          } else {
            SweetAlertHelper.showSuccess(
              context,
              "Sent",
              sent > 0
                  ? "Notification sent to $sent device(s)."
                  : (serverMsg.isNotEmpty ? serverMsg : "Request completed."),
            );
          }
          widget.onSent();
        } else {
          SweetAlertHelper.showError(
            context,
            "Error",
            ApiService.responseErrorHint(res),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        SweetAlertHelper.showError(context, "Error", "Failed to send: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active, color: Colors.blue.shade700, size: 22),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Notify volunteers & participants", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                    SizedBox(height: 2.h),
                    Text("Send updates only to people registered as volunteers or participants for this event.", style: TextStyle(fontSize: 12.sp, color: Colors.blue.shade800)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: _messageController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: "Type your message (e.g. meeting reminder, update...)",
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          SizedBox(height: 12.h),
          DropdownButtonFormField<String>(
            value: _recipientType,
            decoration: const InputDecoration(
              labelText: "Send to",
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            items: const [
              DropdownMenuItem(value: 'both', child: Text("Volunteers & Participants")),
              DropdownMenuItem(value: 'volunteers', child: Text("Volunteers only")),
              DropdownMenuItem(value: 'participants', child: Text("Participants only")),
            ],
            onChanged: (v) => setState(() => _recipientType = v ?? 'both'),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _sending ? null : _send,
              icon: _sending ? SizedBox(width: 18.w, height: 18.h, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send, size: 18),
              label: Text(_sending ? "Sending..." : "Send to volunteers / participants"),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5F15), foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// Broadcast to every active app user (inbox + push when tokens exist). Same daily cap as other organizer sends.
class _OrganizerBroadcastAllCard extends StatefulWidget {
  final dynamic event;
  final VoidCallback onSent;

  const _OrganizerBroadcastAllCard({required this.event, required this.onSent});

  @override
  State<_OrganizerBroadcastAllCard> createState() => _OrganizerBroadcastAllCardState();
}

class _OrganizerBroadcastAllCardState extends State<_OrganizerBroadcastAllCard> {
  final TextEditingController _messageController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      SweetAlertHelper.showWarning(context, "Empty message", "Please type a message to send.");
      return;
    }
    final eventId = int.tryParse((widget.event['id']).toString());
    final organizerId = widget.event['organizer_id']?.toString() ?? widget.event['hostId']?.toString();
    if (eventId == null || organizerId == null) return;
    setState(() => _sending = true);
    try {
      final res = await ApiService.sendEventNotification(
        eventId: eventId,
        organizerId: organizerId,
        message: message,
        recipientType: 'all',
      );
      if (mounted) {
        setState(() => _sending = false);
        Map<String, dynamic>? data = ApiService.responseDataMap(res.data);
        if (data == null && res.data is String) {
          try {
            data = ApiService.responseDataMap(jsonDecode(res.data as String));
          } catch (_) {}
        }
        if (res.statusCode == 429) {
          final msg = (data != null && data['message'] != null && data['message'].toString().trim().isNotEmpty)
              ? data['message'].toString()
              : 'Too many notifications today for this event.';
          SweetAlertHelper.showWarning(context, "Limit reached", msg);
          return;
        }
        final statusOk =
            data != null && data['status']?.toString().toLowerCase().trim() == 'success';
        if (statusOk) {
          _messageController.clear();
          final pushSentRaw = data['push_sent'];
          final sent = pushSentRaw is int
              ? pushSentRaw
              : int.tryParse(pushSentRaw?.toString() ?? '') ?? 0;
          final targeted = data['users_targeted'] ?? data['recipient_count'];
          final n = targeted is int
              ? targeted
              : int.tryParse(targeted?.toString() ?? '') ?? 0;
          final serverMsg = data['message']?.toString().trim() ?? '';
          if (sent == 0 && serverMsg.isNotEmpty && n == 0) {
            SweetAlertHelper.showInfo(context, "Notice", serverMsg);
          } else {
            SweetAlertHelper.showSuccess(
              context,
              "Sent",
              n > 0
                  ? "Message queued for $n user(s)${sent > 0 ? '; $sent push device(s).' : '.'}"
                  : (serverMsg.isNotEmpty ? serverMsg : "Request completed."),
            );
          }
          widget.onSent();
        } else {
          SweetAlertHelper.showError(
            context,
            "Error",
            ApiService.responseErrorHint(res),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        SweetAlertHelper.showError(context, "Error", "Failed to send: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.deepOrange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepOrange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.campaign, color: Colors.deepOrange.shade800, size: 22),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Notify all app users",
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.deepOrange.shade900),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      "Sends the same message to every active user (general notification in inbox + push). Use for important event-wide announcements.",
                      style: TextStyle(fontSize: 12.sp, color: Colors.deepOrange.shade900.withValues(alpha: 0.9)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: _messageController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: "Message to all MiCampus users about this event…",
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? SizedBox(
                      width: 18.w,
                      height: 18.h,
                      child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.public, size: 18),
              label: Text(_sending ? "Sending..." : "Send to all users"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange.shade800,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}