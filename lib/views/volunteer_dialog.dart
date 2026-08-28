import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../controllers/event_controller.dart';
import '../utils/sweetalert_helper.dart';

class VolunteerDialog extends StatefulWidget {
  final dynamic event;
  /// From profile; used with event organiser type for participation rules.
  final bool? userIsStudent;
  final bool switchFromParticipant;
  final VoidCallback? onSwitchSuccess;

  const VolunteerDialog({
    super.key,
    required this.event,
    this.userIsStudent,
    this.switchFromParticipant = false,
    this.onSwitchSuccess,
  });

  @override
  State<VolunteerDialog> createState() => _VolunteerDialogState();
}

class _VolunteerDialogState extends State<VolunteerDialog> {
  final EventController controller = Get.find<EventController>();
  final roleCtrl = TextEditingController();
  final List<String> roles = [
    "Stage Manager",
    "Tech Support",
    "Crowd Management",
    "Registration",
    "Catering",
    "Decoration",
    "Photography",
    "Other"
  ];
  String? selectedRole;

  void _closeDialog() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 10,
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with close button — title must flex so it doesn't overflow the X.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.switchFromParticipant
                              ? "Switch to volunteer"
                              : "Volunteer Signup",
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          widget.switchFromParticipant
                              ? "Choose your volunteer role for this event"
                              : "Help make this event amazing!",
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Material(
                    color: Colors.grey[100],
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _closeDialog,
                      child: Padding(
                        padding: EdgeInsets.all(8.w),
                        child: Icon(Icons.close, color: Colors.black87, size: 22.sp),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24.h),

              // Event Card
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5F15).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFF5F15).withValues(alpha: 0.2), width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50.w,
                      height: 50.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5F15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.event, color: Colors.white),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Event",
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            widget.event['title'] ?? "Campus Event",
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Role Selection Section — chips stay inside the dialog (no Material dropdown overlay).
              Text(
                "Select Your Role",
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              SizedBox(height: 12.h),

              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: roles.map((role) {
                  final selected = selectedRole == role;
                  return ChoiceChip(
                    label: Text(
                      role,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                        color: selected ? Colors.white : Colors.black87,
                      ),
                    ),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        selectedRole = role;
                        if (role != "Other") {
                          roleCtrl.clear();
                        }
                      });
                    },
                    selectedColor: const Color(0xFFFF5F15),
                    backgroundColor: Colors.grey[100],
                    checkmarkColor: Colors.white,
                    side: BorderSide(
                      color: selected ? const Color(0xFFFF5F15) : Colors.grey[300]!,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  );
                }).toList(),
              ),

              if (selectedRole == "Other") ...[
                SizedBox(height: 14.h),
                TextField(
                  controller: roleCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: "Specify Your Role",
                    hintText: "Enter your preferred role",
                    prefixIcon: const Icon(Icons.create_outlined, color: Color(0xFFFF5F15)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFF5F15), width: 2),
                    ),
                  ),
                ),
              ],

              SizedBox(height: 24.h),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _closeDialog,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                      ),
                      child: Text(
                        "Cancel",
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Obx(
                      () => ElevatedButton(
                        onPressed: controller.isLoading.value ? null : _submitVolunteer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5F15),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                        ),
                        child: controller.isLoading.value
                            ? SizedBox(
                                width: 20.w,
                                height: 20.h,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                widget.switchFromParticipant ? "Switch role" : "Submit",
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitVolunteer() {
    final status = (widget.event['status'] ?? '').toString().toLowerCase();
    if (status != 'approved') {
      SweetAlertHelper.showWarning(context, "Not Available", "You can volunteer only after admin approval.");
      return;
    }

    if (selectedRole == null || selectedRole!.isEmpty) {
      SweetAlertHelper.showError(context, "Required", "Please select a role");
      return;
    }

    String role = selectedRole == "Other" ? roleCtrl.text.trim() : selectedRole!;

    if (role.isEmpty) {
      SweetAlertHelper.showError(context, "Required", "Please specify your role");
      return;
    }

    if (widget.switchFromParticipant) {
      // Close first so the success alert is not dismissed by this pop.
      _closeDialog();
      controller
          .switchStaffRole(
            eventId: widget.event['id'].toString(),
            toRole: 'volunteer',
            volunteerRole: role,
          )
          .then((ok) {
        if (ok) widget.onSwitchSuccess?.call();
      });
      return;
    }

    controller.volunteer(
      widget.event['id'].toString(),
      role,
      "", // Empty contact since DB doesn't store it
      organizerId: widget.event['organizer_id']?.toString(),
      eventSnapshot: widget.event,
      userIsStudent: widget.userIsStudent,
    );
  }

  @override
  void dispose() {
    roleCtrl.dispose();
    super.dispose();
  }
}