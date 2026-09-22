import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/event_controller.dart';
import '../controllers/profile_controller.dart';
import '../utils/event_fee_helper.dart';
import '../utils/sweetalert_helper.dart';
import 'event_payment_flow.dart';

/// Bottom sheet: required department/class before participant registration (API `department_class`).
Future<void> showParticipateRegistrationSheet(
  BuildContext context, {
  required String eventId,
  required String eventTitle,
  String? organizerId,
  dynamic eventSnapshot,
  bool? userIsStudent,
  bool switchFromVolunteer = false,
  VoidCallback? onSwitchSuccess,
  /// Called after a successful paid verify (before/alongside refresh).
  VoidCallback? onPaidSuccess,
}) async {
  final eventMap = eventSnapshot is Map ? Map<String, dynamic>.from(
    eventSnapshot.map((k, v) => MapEntry(k.toString(), v)),
  ) : <String, dynamic>{'id': eventId, 'title': eventTitle};

  if (EventFeeHelper.isDisabled(eventMap, 'participate')) {
    SweetAlertHelper.showWarning(
      context,
      'Not Available',
      EventFeeHelper.disabledMessage,
    );
    return;
  }

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
        eventSnapshot: eventMap,
        userIsStudent: userIsStudent,
        switchFromVolunteer: switchFromVolunteer,
        onSwitchSuccess: onSwitchSuccess,
        onPaidSuccess: onPaidSuccess,
      );
    },
  );
}

class _ParticipateRegistrationContent extends StatefulWidget {
  final BuildContext sheetContext;
  final String eventId;
  final String eventTitle;
  final String? organizerId;
  final Map eventSnapshot;
  final bool? userIsStudent;
  final bool switchFromVolunteer;
  final VoidCallback? onSwitchSuccess;
  final VoidCallback? onPaidSuccess;

  const _ParticipateRegistrationContent({
    required this.sheetContext,
    required this.eventId,
    required this.eventTitle,
    required this.eventSnapshot,
    this.organizerId,
    this.userIsStudent,
    this.switchFromVolunteer = false,
    this.onSwitchSuccess,
    this.onPaidSuccess,
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

  Future<void> _onConfirm() async {
    final d = _deptCtrl.text.trim();
    if (d.isEmpty) {
      SweetAlertHelper.showWarning(
        context,
        'Required',
        'Please enter your department or class.',
      );
      return;
    }

    final parentContext = widget.sheetContext;
    Navigator.pop(context);

    final withFee = EventFeeHelper.isWithFee(widget.eventSnapshot, 'participate');
    if (withFee) {
      await EventPaymentFlow.start(
        context: parentContext,
        event: widget.eventSnapshot,
        role: 'participate',
        departmentClass: d,
        onSuccess: () {
          widget.onPaidSuccess?.call();
          widget.onSwitchSuccess?.call();
        },
      );
      return;
    }

    final eventController = Get.find<EventController>();
    await eventController.participate(
      widget.eventId,
      d,
      organizerId: widget.organizerId,
      eventSnapshot: widget.eventSnapshot,
      userIsStudent: widget.userIsStudent,
    );
    if (widget.switchFromVolunteer) {
      widget.onSwitchSuccess?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final withFee = EventFeeHelper.isWithFee(widget.eventSnapshot, 'participate');
    final feeLabel = EventFeeHelper.formatFee(
      EventFeeHelper.feeAmount(widget.eventSnapshot, 'participate'),
    );

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
            widget.switchFromVolunteer
                ? 'Switch to participant'
                : 'Register as participant',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          Text(
            widget.eventTitle,
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[700]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (withFee) ...[
            SizedBox(height: 10.h),
            Text(
              'Fee: $feeLabel — you’ll confirm payment on the next step',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFFF5F15),
              ),
            ),
          ],
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
                  onPressed: _onConfirm,
                  child: Text(
                    withFee
                        ? 'Continue'
                        : (widget.switchFromVolunteer ? 'Switch role' : 'Confirm'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
