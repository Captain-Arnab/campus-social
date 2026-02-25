import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../controllers/event_controller.dart';

class VolunteerDialog extends StatefulWidget {
  final dynamic event;
  const VolunteerDialog({super.key, required this.event});

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
              // Header with close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Volunteer Signup",
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        "Help make this event amazing!",
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.black87),
                      onPressed: () => Get.back(),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24.h),

              // Event Card
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5F15).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFF5F15).withOpacity(0.2), width: 1.5),
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

              // Role Selection Section
              Text(
                "Select Your Role",
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              SizedBox(height: 10.h),

              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: InputDecoration(
                    labelText: "Choose a role",
                    prefixIcon: const Icon(Icons.work_outline, color: Color(0xFFFF5F15)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  ),
                  items: roles
                      .map((role) => DropdownMenuItem(
                            value: role,
                            child: Text(role),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => selectedRole = value);
                    if (value != "Other") {
                      roleCtrl.text = value ?? "";
                    }
                  },
                ),
              ),

              SizedBox(height: 16.h),

              // Custom Role (if Other is selected)
              if (selectedRole == "Other")
                TextField(
                  controller: roleCtrl,
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

              if (selectedRole == "Other") SizedBox(height: 16.h),

              SizedBox(height: 24.h),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
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
                                "Submit",
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
      Get.snackbar(
        "Not Available",
        "You can volunteer only after admin approval.",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    if (selectedRole == null || selectedRole!.isEmpty) {
      Get.snackbar("Required", "Please select a role",
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    String role = selectedRole == "Other" ? roleCtrl.text.trim() : selectedRole!;

    if (role.isEmpty) {
      Get.snackbar("Required", "Please specify your role",
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    controller.volunteer(
      widget.event['id'].toString(),
      role,
      "", // Empty contact since DB doesn't store it
    );
  }

  @override
  void dispose() {
    roleCtrl.dispose();
    super.dispose();
  }
}