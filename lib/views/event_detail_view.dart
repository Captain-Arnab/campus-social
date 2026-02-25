import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../controllers/event_controller.dart';
import 'volunteer_dialog.dart';
import '../data/api_service.dart';
import '../data/pref_service.dart';

class EventDetailView extends StatelessWidget {
  final dynamic event;
  const EventDetailView({super.key, required this.event});

  bool _isApprovedEvent() {
    final status = (event is Map ? event['status'] : null)?.toString().toLowerCase() ?? '';
    return status == 'approved';
  }

  String _eventStatus() {
    return (event is Map ? event['status'] : null)?.toString().toLowerCase() ?? '';
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
      final dynamic organizerIsStudentRaw = event['organizer_is_student'];
      
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

  void _showParticipateDialog(BuildContext context) {
    final EventController controller = Get.find<EventController>();

    if (!_isApprovedEvent()) {
      final st = _eventStatus();
      final label = st.isEmpty ? "pending" : st;
      Get.snackbar(
        "Not Available",
        "This event is $label. You can participate only after approval.",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }
    
    Get.defaultDialog(
      title: "Participate in Event",
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const Icon(Icons.groups, size: 60, color: Color(0xFF4CAF50)),
            const SizedBox(height: 16),
            Text(
              "Join as a participant for:",
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              event['title'] ?? "this event",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      textConfirm: "Confirm",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: const Color(0xFF4CAF50),
      cancelTextColor: Colors.grey[700],
      onConfirm: () {
        Get.back();
        controller.participate(event['id'].toString());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final EventController controller = Get.find<EventController>();
    final List banners = event['banners'] ?? [];
    
    // FIXED: Get organizer info from event data
    final String organizerName = event['organizer_name'] ?? event['organizer'] ?? 'Campus Social';
    final String organizerAvatar = event['organizer_avatar'] ?? 'default_avatar.png';
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
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
                onPressed: () => Get.snackbar("Share", "Share feature coming soon!"),
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
                onPressed: () => controller.toggleFavorite(event['id'].toString()),
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
                      event['category'] ?? "Event",
                      style: const TextStyle(color: Color(0xFFFF5F15), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  
                  Text(
                    event['title'] ?? "Untitled Event",
                    style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  
                  SizedBox(height: 24.h),
                  
                  _buildInfoTile(
                    Icons.calendar_today,
                    "Date & Time",
                    event['event_date'] ?? "Date TBD",
                  ),
                  
                  SizedBox(height: 16.h),
                  
                  _buildInfoTile(
                    Icons.location_on,
                    "Venue",
                    event['venue'] ?? "Venue TBD",
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
                    event['description'] ?? "No description available for this event.",
                    style: TextStyle(fontSize: 15.sp, color: Colors.grey[700], height: 1.6),
                  ),
                  
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
                        // FIXED: Show actual organizer profile picture
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
                        final isJoined = controller.attendingList.any((e) => e['id'].toString() == event['id'].toString());
                        return ElevatedButton(
                          onPressed: (!_isApprovedEvent() || isJoined)
                              ? null
                              : () => controller.joinEvent(event['id'].toString()),
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
                          final isVolunteering = controller.volunteeringList.any((e) => e['id'].toString() == event['id'].toString());
                          return OutlinedButton(
                            onPressed: (!_isApprovedEvent() || isVolunteering)
                                ? null
                                : () => showDialog(
                                      context: context,
                                      builder: (context) => VolunteerDialog(event: event),
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
                          final isParticipating = controller.participatingList.any((e) => e['id'].toString() == event['id'].toString());
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