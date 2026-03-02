import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:art_sweetalert_new/art_sweetalert_new.dart';
import '../controllers/event_controller.dart';
import '../controllers/profile_controller.dart';
import '../utils/sweetalert_helper.dart';
import 'volunteer_dialog.dart';
import 'edit_event_view.dart';
import '../data/api_service.dart';
import '../data/pref_service.dart';

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
      // Fetch winners from event_winners.php (winners may not be in events.php response)
      final winRes = await ApiService.getWinnersByEventId(id);
      if (mounted && winRes.data is Map && winRes.data['status'] == 'success') {
        final data = winRes.data['data'];
        final list = data is List ? data : (full['winners'] is List ? full['winners'] as List : <dynamic>[]);
        setState(() => _winnersList = list);
      } else if (full['winners'] is List && (full['winners'] as List).isNotEmpty) {
        setState(() => _winnersList = full['winners'] as List);
      }
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
    final dateStr = (_event is Map ? _event['event_date'] : null)?.toString() ?? '';
    if (dateStr.isEmpty) return false;
    final d = DateTime.tryParse(dateStr.replaceAll(' ', 'T'));
    return d != null && d.isBefore(DateTime.now());
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
        return {'isStudent': false, 'organizerIsStudent': false}; // Default to faculty
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
      
      return {
        'isStudent': isStudent,
        'organizerIsStudent': organizerIsStudent,
      };
    } catch (e) {
      debugPrint("❌ Error getting roles: $e");
      return {'isStudent': false, 'organizerIsStudent': false}; // Default to faculty on error
    }
  }

  void _showAddEditorDialog(BuildContext context) {
    final id = int.tryParse((_event['id']).toString());
    if (id == null) return;
    final userIdCtrl = TextEditingController();
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
              if (r.data is Map && r.data['status'] == 'success') {
                SweetAlertHelper.showSuccess(context, "Success", "Editor added.");
                await _loadFullEvent();
              } else {
                SweetAlertHelper.showError(context, "Error", (r.data is Map ? r.data['message'] : null)?.toString() ?? "Failed");
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
      SweetAlertHelper.showInfo(context, "Info", "No volunteers or participants for this event.");
      return;
    }
    String? selectedUserId = allUsers.first['user_id']?.toString();
    String selectedType = 'volunteer';
    File? selectedFile;
    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setModalState) {
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
                            if (r.data is Map && r.data['status'] == 'success') {
                              SweetAlertHelper.showSuccess(context, "Success", "Certificate uploaded.");
                            } else {
                              SweetAlertHelper.showError(context, "Error", (r.data is Map ? r.data['message'] : null)?.toString() ?? "Failed");
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

  void _showParticipateDialog(BuildContext context) {
    final EventController controller = Get.find<EventController>();

    if (!_isApprovedEvent()) {
      final st = _eventStatus();
      final label = st.isEmpty ? "pending" : st;
      SweetAlertHelper.showWarning(context, "Not Available", "This event is $label. You can participate only after approval.");
      return;
    }
    
    ArtSweetAlert.show(
      context: context,
      title: const Text("Participate in Event"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.groups, size: 60, color: Color(0xFF4CAF50)),
          const SizedBox(height: 16),
          Text("Join as a participant for:", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(height: 8),
          Text(_event['title'] ?? "this event", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center),
        ],
      ),
      type: ArtAlertType.question,
      actions: [
        ArtAlertButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
          backgroundColor: Colors.grey,
        ),
        ArtAlertButton(
          onPressed: () {
            Navigator.pop(context);
            controller.participate(_event['id'].toString());
          },
          child: const Text("Confirm"),
          backgroundColor: const Color(0xFF4CAF50),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final EventController controller = Get.find<EventController>();
    if (_loadingFull) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(backgroundColor: const Color(0xFFFF5F15), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Get.back())),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFFFF5F15))),
      );
    }
    final List banners = _event['banners'] ?? [];
    final String organizerName = _event['organizer_name'] ?? _event['organizer'] ?? 'Campus Social';
    final String organizerAvatar = _event['organizer_avatar'] ?? 'default_avatar.png';
    final dynamic pendingEdit = _event['pending_edit'];
    final List winners = _winnersList.isNotEmpty ? _winnersList : (_event['winners'] is List ? _event['winners'] as List : []);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _loadFullEvent,
        color: const Color(0xFFFF5F15),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          cacheExtent: 400,
          slivers: [
          SliverAppBar(
            expandedHeight: 400.h,
            pinned: true,
            backgroundColor: const Color(0xFFFF5F15),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.black87),
              ),
              onPressed: () => Get.back(),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share, color: Colors.black87),
                ),
                onPressed: () => SweetAlertHelper.showInfo(context, "Share", "Share feature coming soon!"),
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite_border, color: Colors.red),
                ),
                onPressed: () => controller.toggleFavorite(_event['id'].toString()),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: banners.isNotEmpty
                ? PageView.builder(
                    itemCount: banners.length,
                    itemBuilder: (context, index) {
                      return Image.network(
                        "https://exdeos.com/AS/campus_social/uploads/events/${banners[index]}",
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => _buildPlaceholder(),
                      );
                    },
                  )
                : _buildPlaceholder(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color(0xFFFF5F15).withOpacity(0.2), const Color(0xFFE04E0B).withOpacity(0.2)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _event['category'] ?? "Event",
                      style: const TextStyle(color: Color(0xFFFF5F15), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  
                  Text(
                    _event['title'] ?? "Untitled Event",
                    style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  
                  SizedBox(height: 24.h),
                  
                  _buildInfoTile(
                    Icons.calendar_today,
                    "Date & Time",
                    _event['event_date'] ?? "Date TBD",
                  ),
                  
                  SizedBox(height: 16.h),
                  
                  _buildInfoTile(
                    Icons.location_on,
                    "Venue",
                    _event['venue'] ?? "Venue TBD",
                  ),
                  
                  SizedBox(height: 24.h),
                  Divider(color: Colors.grey[300]),
                  SizedBox(height: 24.h),
                  
                  Text(
                    "About Event",
                    style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  SizedBox(height: 12.h),
                  
                  Text(
                    _event['description'] ?? "No description available for this event.",
                    style: TextStyle(fontSize: 15.sp, color: Colors.grey[700], height: 1.6),
                  ),

                  SizedBox(height: 24.h),

                  // Pending edit banner
                  if (pendingEdit != null && pendingEdit is Map) ...[
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
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
                  Text(
                    "Winners",
                    style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  SizedBox(height: 12.h),
                  if (winners.isNotEmpty)
                    ...winners.map<Widget>((w) {
                      final pos = (w is Map ? w['position'] : null) ?? 0;
                      final name = (w is Map ? w['full_name'] : null)?.toString() ?? '—';
                      return Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: Row(
                          children: [
                            Container(
                              width: 28.w,
                              height: 28.w,
                              decoration: BoxDecoration(
                                color: pos == 1 ? const Color(0xFFFFD700) : (pos == 2 ? Colors.grey.shade400 : Colors.brown.shade300),
                                shape: BoxShape.circle,
                              ),
                              child: Center(child: Text('$pos', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold))),
                            ),
                            SizedBox(width: 12.w),
                            Text(name, style: TextStyle(fontSize: 15.sp)),
                          ],
                        ),
                      );
                    })
                  else
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.emoji_events_outlined, size: 24.w, color: Colors.grey.shade500),
                          SizedBox(width: 12.w),
                          Text(
                            "No winners are announced yet.",
                            style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: 24.h),

                  // Edit button (organizer or editor)
                  if (_isApprovedEvent())
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

                  // Organizer: Send notification to volunteers & participants
                  if (_isApprovedEvent())
                    FutureBuilder<bool>(
                      future: _canEditEvent(),
                      builder: (context, snap) {
                        if (snap.data != true) return const SizedBox.shrink();
                        return Padding(
                          padding: EdgeInsets.only(bottom: 16.h),
                          child: _SendNotificationCard(
                            event: _event,
                            onSent: () {},
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
                          Text("Manage editors", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
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
                            style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFFF5F15), side: const BorderSide(color: Color(0xFFFF5F15))),
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
                            Text("Upload e-certificate", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
                            SizedBox(height: 8.h),
                            OutlinedButton.icon(
                              onPressed: () => _showUploadCertificateSheet(context),
                              icon: const Icon(Icons.upload_file),
                              label: const Text("Upload for volunteer/participant"),
                              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFFF5F15), side: const BorderSide(color: Color(0xFFFF5F15))),
                            ),
                          ],
                        ),
                      );
                    }),
                  
                  SizedBox(height: 32.h),
                  
                  Text(
                    "Hosted By",
                    style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  SizedBox(height: 12.h),
                  
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 25.w,
                          backgroundColor: const Color(0xFFFF5F15),
                          backgroundImage: organizerAvatar != 'default_avatar.png'
                            ? NetworkImage("https://exdeos.com/AS/campus_social/uploads/profiles/$organizerAvatar")
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
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 16.sp,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                maxLines: 1,
                              ),
                              Text(
                                "Event Organizer",
                                style: TextStyle(color: Colors.grey[600], fontSize: 13.sp),
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
          if (!snapshot.hasData) {
            return Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -3))
                ],
              ),
              child: const Center(child: CircularProgressIndicator(color: Color(0xFFFF5F15))),
            );
          }
          
          final roles = snapshot.data!;
          final bool isStudent = roles['isStudent'] as bool;
          final bool organizerIsStudent = roles['organizerIsStudent'] as bool;
          final bool rolesMatch = isStudent == organizerIsStudent;
          
          debugPrint("🔍 Final check - User: $isStudent, Organizer: $organizerIsStudent, Match: $rolesMatch");
          
          return Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -3))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Approval status banner
                if (!_isApprovedEvent()) ...[
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule, color: Colors.orange, size: 20),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            "This event is ${_eventStatus().isEmpty ? 'pending' : _eventStatus()}. "
                            "Join/Volunteer/Participate will be enabled after admin approval.",
                            style: TextStyle(
                              color: Colors.orange[800],
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

                // Role restriction info banner (only show if roles don't match)
                if (!rolesMatch) ...[
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            "This is a ${organizerIsStudent ? 'student' : 'faculty'} event. You can only attend.",
                            style: TextStyle(
                              color: Colors.orange[800],
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
                    // Attend Button (always visible)
                    Expanded(
                      child: Obx(() {
                        final isJoined = controller.attendingList.any((e) => e['id'].toString() == _event['id'].toString());
                        return ElevatedButton(
                          onPressed: (!_isApprovedEvent() || isJoined)
                              ? null
                              : () => controller.joinEvent(_event['id'].toString()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isJoined ? Colors.grey[300] : const Color(0xFFFF5F15),
                            foregroundColor: isJoined ? Colors.grey[600] : Colors.white,
                            disabledBackgroundColor: Colors.grey[300],
                            disabledForegroundColor: Colors.grey[600],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            elevation: 0,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(isJoined ? Icons.check : Icons.check_circle, size: 18),
                              SizedBox(height: 4.h),
                              Text(
                                isJoined ? "Joined" : (rolesMatch ? "Attend" : "Attend Only"),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                    
                    // Only show Volunteer and Participate buttons if roles match
                    if (rolesMatch) ...[
                      SizedBox(width: 10.w),
                      
                      // Volunteer Button
                      Expanded(
                        child: Obx(() {
                          final isVolunteering = controller.volunteeringList.any((e) => e['id'].toString() == _event['id'].toString());
                          return OutlinedButton(
                            onPressed: (!_isApprovedEvent() || isVolunteering)
                                ? null
                                : () => showDialog(
                                      context: context,
                                      builder: (context) => VolunteerDialog(event: _event),
                                    ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isVolunteering ? Colors.grey[600] : const Color(0xFFFF5F15),
                              side: BorderSide(color: isVolunteering ? Colors.grey[400]! : const Color(0xFFFF5F15), width: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.volunteer_activism, size: 18),
                                SizedBox(height: 4.h),
                                Text(isVolunteering ? "Volunteered" : "Volunteer", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                              ],
                            ),
                          );
                        }),
                      ),
                      SizedBox(width: 10.w),
                      
                      // Participate Button
                      Expanded(
                        child: Obx(() {
                          final isParticipating = controller.participatingList.any((e) => e['id'].toString() == _event['id'].toString());
                          return OutlinedButton(
                            onPressed: (!_isApprovedEvent() || isParticipating) ? null : () => _showParticipateDialog(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isParticipating ? Colors.grey[600] : const Color(0xFF4CAF50),
                              side: BorderSide(color: isParticipating ? Colors.grey[400]! : const Color(0xFF4CAF50), width: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.groups, size: 18),
                                SizedBox(height: 4.h),
                                Text(isParticipating ? "Participating" : "Participate", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
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

  Widget _buildPlaceholder() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [const Color(0xFFFF5F15).withOpacity(0.3), const Color(0xFFE04E0B).withOpacity(0.3)],
      ),
    ),
    child: const Center(child: Icon(Icons.event, size: 80, color: Colors.white)),
  );

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF5F15).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFFFF5F15), size: 24),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12.sp)),
                SizedBox(height: 4.h),
                Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp)),
              ],
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
        if (res.data is Map && (res.data as Map)['status'] == 'success') {
          _messageController.clear();
          final sent = res.data['push_sent'] ?? 0;
          SweetAlertHelper.showSuccess(context, "Sent", "Notification sent to $sent recipient(s).");
          widget.onSent();
        } else {
          SweetAlertHelper.showError(context, "Error", (res.data is Map ? res.data['message'] : null)?.toString() ?? "Failed to send.");
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
                    Text("Send notification to volunteers & participants", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                    SizedBox(height: 2.h),
                    Text("As the organizer, you can send meeting updates or reminders. They will receive a push notification.", style: TextStyle(fontSize: 12.sp, color: Colors.blue.shade800)),
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
              label: Text(_sending ? "Sending..." : "Send notification"),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5F15), foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}