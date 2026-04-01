import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/event_controller.dart';
import '../controllers/profile_controller.dart';
import '../utils/sweetalert_helper.dart';

/// Bottom sheet: required department/class before participant registration (API `department_class`).
Future<void> showParticipateRegistrationSheet(
  BuildContext context, {
  required String eventId,
  required String eventTitle,
  String? organizerId,
  dynamic eventSnapshot,
  bool? userIsStudent,
}) async {
  final deptCtrl = TextEditingController();
  if (Get.isRegistered<ProfileController>()) {
    final pre = Get.find<ProfileController>().userData.value.departmentClass;
    if (pre != null && pre.isNotEmpty) {
      deptCtrl.text = pre;
    }
  }
  final eventController = Get.find<EventController>();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          top: 20.h,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Register as participant',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.h),
            Text(
              eventTitle,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[700]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: deptCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Department / Class',
                hintText: 'e.g. CSE 3rd Year, Section A',
                prefixIcon: const Icon(Icons.school_outlined, color: Color(0xFFFF5F15)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'This is saved to your profile and used for this event.',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      final d = deptCtrl.text.trim();
                      if (d.isEmpty) {
                        SweetAlertHelper.showWarning(ctx, 'Required', 'Please enter your department or class.');
                        return;
                      }
                      Navigator.pop(ctx);
                      eventController.participate(
                        eventId,
                        d,
                        organizerId: organizerId,
                        eventSnapshot: eventSnapshot,
                        userIsStudent: userIsStudent,
                      );
                    },
                    child: const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
  deptCtrl.dispose();
}
