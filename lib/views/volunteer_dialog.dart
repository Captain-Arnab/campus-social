import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../controllers/event_controller.dart';
import '../data/api_service.dart';
import '../utils/event_fee_helper.dart';
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
  final List<String> _committees = [];
  bool _loadingCommittees = true;
  String? _loadError;
  String? selectedRole;

  @override
  void initState() {
    super.initState();
    _loadCommittees();
  }

  Future<void> _loadCommittees() async {
    setState(() {
      _loadingCommittees = true;
      _loadError = null;
    });
    try {
      final eid = widget.event['id']?.toString() ?? '';
      final res = await ApiService.listVolunteerCommittees(eid);
      final data = ApiService.parseResponseBody(res.data);
      final names = <String>[];
      final raw = data?['committees'] ?? data?['data'] ?? data?['list'];
      if (raw is List) {
        for (final item in raw) {
          if (item is Map) {
            final name = (item['name'] ?? item['role'] ?? '').toString().trim();
            if (name.isNotEmpty) names.add(name);
          } else if (item is String && item.trim().isNotEmpty) {
            names.add(item.trim());
          }
        }
      }
      if (!mounted) return;
      if (names.isEmpty) {
        setState(() {
          _committees.clear();
          _loadingCommittees = false;
          _loadError = 'No committees available for this event';
        });
        return;
      }
      setState(() {
        _committees
          ..clear()
          ..addAll(names);
        _loadingCommittees = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingCommittees = false;
        _loadError = 'Could not load committees';
      });
    }
  }

  void _closeDialog() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    final eventMap = widget.event is Map ? widget.event as Map : null;
    if (EventFeeHelper.isDisabled(eventMap, 'volunteer')) {
      // Safety: should be blocked before opening; show message if reached.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _closeDialog();
        SweetAlertHelper.showWarning(
          context,
          'Not Available',
          EventFeeHelper.disabledMessage,
        );
      });
    }

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
                              ? "Choose your volunteer committee for this event"
                              : "Pick a committee, then join",
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

              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5F15).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFFF5F15).withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50.w,
                      height: 50.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5F15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.volunteer_activism, color: Colors.white),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        (widget.event['title'] ?? 'Event').toString(),
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              Text(
                "Select Committee",
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12.h),

              if (_loadingCommittees)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.h),
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF5F15)),
                  ),
                )
              else if (_loadError != null)
                Column(
                  children: [
                    Text(
                      _loadError!,
                      style: TextStyle(fontSize: 13.sp, color: Colors.red[700]),
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: _loadCommittees,
                      child: const Text('Retry'),
                    ),
                  ],
                )
              else
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: _committees.map((role) {
                    final selected = selectedRole == role;
                    return ChoiceChip(
                      label: Text(
                        role,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                          color: selected ? Colors.white : Colors.black87,
                        ),
                      ),
                      selected: selected,
                      onSelected: (_) => setState(() => selectedRole = role),
                      selectedColor: const Color(0xFFFF5F15),
                      backgroundColor: Colors.grey[100],
                      checkmarkColor: Colors.white,
                      side: BorderSide(
                        color: selected
                            ? const Color(0xFFFF5F15)
                            : Colors.grey[300]!,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 2.h,
                      ),
                    );
                  }).toList(),
                ),

              SizedBox(height: 24.h),

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
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Obx(
                      () => ElevatedButton(
                        onPressed: (_loadingCommittees ||
                                controller.isLoading.value)
                            ? null
                            : _submitVolunteer,
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
                                widget.switchFromParticipant
                                    ? "Switch role"
                                    : "Submit",
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
      SweetAlertHelper.showWarning(
        context,
        "Not Available",
        "You can volunteer only after admin approval.",
      );
      return;
    }

    if (EventFeeHelper.isDisabled(
      widget.event is Map ? widget.event as Map : null,
      'volunteer',
    )) {
      SweetAlertHelper.showWarning(
        context,
        'Not Available',
        EventFeeHelper.disabledMessage,
      );
      return;
    }

    final role = selectedRole?.trim() ?? '';
    if (role.isEmpty) {
      SweetAlertHelper.showError(context, "Required", "Please select a committee");
      return;
    }

    if (widget.switchFromParticipant) {
      _closeDialog();
      controller
          .volunteer(
            widget.event['id'].toString(),
            role,
            "",
            organizerId: widget.event['organizer_id']?.toString(),
            eventSnapshot: widget.event,
            userIsStudent: widget.userIsStudent,
          )
          .then((_) => widget.onSwitchSuccess?.call());
      return;
    }

    controller.volunteer(
      widget.event['id'].toString(),
      role,
      "",
      organizerId: widget.event['organizer_id']?.toString(),
      eventSnapshot: widget.event,
      userIsStudent: widget.userIsStudent,
    );
  }
}
