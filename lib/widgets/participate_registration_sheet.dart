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
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
    builder: (ctx) {
      return _ParticipateRegistrationContent(
        sheetContext: ctx,
        eventId: eventId,
        eventTitle: eventTitle,
        organizerId: organizerId,
        eventSnapshot: eventSnapshot,
        userIsStudent: userIsStudent,
      );
    },
  );
}

class _ParticipateRegistrationContent extends StatefulWidget {
  final BuildContext sheetContext;
  final String eventId;
  final String eventTitle;
  final String? organizerId;
  final dynamic eventSnapshot;
  final bool? userIsStudent;

  const _ParticipateRegistrationContent({
    required this.sheetContext,
    required this.eventId,
    required this.eventTitle,
    this.organizerId,
    this.eventSnapshot,
    this.userIsStudent,
  });

  @override
  State<_ParticipateRegistrationContent> createState() =>
      _ParticipateRegistrationContentState();
}

class _ParticipateRegistrationContentState
    extends State<_ParticipateRegistrationContent> {
  late final TextEditingController _deptCtrl;

  @override
  void initState() {
    super.initState();
    _deptCtrl = TextEditingController();
    if (Get.isRegistered<ProfileController>()) {
      final pre = Get.find<ProfileController>().userData.value.departmentClass;
      if (pre != null && pre.isNotEmpty) {
        _deptCtrl.text = pre;
      }
    }
  }

  @override
  void dispose() {
    _deptCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventController = Get.find<EventController>();
    return Padding(
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 20.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
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
            widget.eventTitle,
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[700]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 16.h),
          TextField(
            controller: _deptCtrl,
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
                  onPressed: () => Navigator.pop(context),
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
                    final d = _deptCtrl.text.trim();
                    if (d.isEmpty) {
                      SweetAlertHelper.showWarning(context, 'Required', 'Please enter your department or class.');
                      return;
                    }
                    Navigator.pop(context);
                    eventController.participate(
                      widget.eventId,
                      d,
                      organizerId: widget.organizerId,
                      eventSnapshot: widget.eventSnapshot,
                      userIsStudent: widget.userIsStudent,
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
  }
}
