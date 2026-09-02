import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../data/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/sweetalert_helper.dart';
import '../widgets/app_bar_title_with_brand_logo.dart';

/// Submit / view meeting minutes for an event (separate from Event Report).
class MeetingMinutesView extends StatefulWidget {
  final Map<String, dynamic> event;

  const MeetingMinutesView({super.key, required this.event});

  @override
  State<MeetingMinutesView> createState() => _MeetingMinutesViewState();
}

class _MeetingMinutesViewState extends State<MeetingMinutesView> {
  final _contentCtrl = TextEditingController();
  PlatformFile? _attachment;
  bool _loading = true;
  bool _saving = false;
  String? _status;
  String? _existingContent;
  String? _error;

  int? get _eventId => int.tryParse(widget.event['id']?.toString() ?? '');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final eid = _eventId;
    if (eid == null) {
      setState(() {
        _loading = false;
        _error = 'Invalid event';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService.getMeetingMinutes(eid);
      final data = ApiService.parseResponseBody(res.data);
      if (data != null && data['status'] == 'success') {
        final payload = data['data'] is Map
            ? Map<String, dynamic>.from(data['data'] as Map)
            : data;
        final content = (payload['content'] ?? payload['minutes'] ?? '')
            .toString();
        final status = (payload['status'] ?? '').toString().toLowerCase();
        setState(() {
          _existingContent = content;
          _status = status.isEmpty ? null : status;
          if (content.isNotEmpty) _contentCtrl.text = content;
        });
      } else if (data != null && data['status'] == 'error') {
        // No minutes yet is OK
        final msg = data['message']?.toString().toLowerCase() ?? '';
        if (!msg.contains('not found') && !msg.contains('no minutes')) {
          _error = data['message']?.toString();
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickAttachment() async {
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'pdf', 'doc', 'docx'],
    );
    if (res == null || !mounted) return;
    final f = res.files.isNotEmpty ? res.files.first : null;
    if (f != null && f.path != null) {
      setState(() => _attachment = f);
    }
  }

  Future<void> _submit() async {
    final text = _contentCtrl.text.trim();
    if (text.isEmpty) {
      SweetAlertHelper.showWarning(context, 'Required', 'Please enter the meeting minutes.');
      return;
    }
    final eid = _eventId;
    if (eid == null) return;
    setState(() => _saving = true);
    try {
      File? file;
      final path = _attachment?.path;
      if (path != null && path.isNotEmpty) {
        file = File(path);
        if (!await file.exists()) file = null;
      }
      final r = await ApiService.submitMeetingMinutes(
        eventId: eid,
        content: text,
        attachment: file,
      );
      final data = ApiService.parseResponseBody(r.data);
      if (data?['status'] == 'success') {
        if (!mounted) return;
        SweetAlertHelper.showSuccess(
          context,
          'Submitted',
          data?['message']?.toString() ?? 'Meeting minutes submitted.',
          onConfirm: () {
            Get.back(result: true);
          },
        );
      } else {
        if (!mounted) return;
        SweetAlertHelper.showError(
          context,
          'Error',
          data?['message']?.toString() ?? ApiService.responseErrorHint(r),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'approved':
        return Colors.green.shade700;
      case 'rejected':
        return Colors.red.shade700;
      case 'pending':
      default:
        return Colors.amber.shade800;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'pending':
        return 'Pending approval';
      default:
        return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title =
        (widget.event['title'] ?? 'Event').toString();
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const AppBarTitleWithBrandLogo(
          onPrimaryBackground: false,
          title: Text(
            'Meeting Minutes',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Submit meeting minutes separately from the event report.',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (_status != null) ...[
                    SizedBox(height: 16.h),
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: _statusColor(_status!).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _statusColor(_status!)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.pending_actions,
                            color: _statusColor(_status!),
                            size: 22,
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              'Minutes status: ${_statusLabel(_status!)}',
                              style: TextStyle(
                                color: _statusColor(_status!),
                                fontWeight: FontWeight.w700,
                                fontSize: 13.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    SizedBox(height: 12.h),
                    Text(_error!, style: TextStyle(color: AppColors.error, fontSize: 13.sp)),
                  ],
                  SizedBox(height: 20.h),
                  TextField(
                    controller: _contentCtrl,
                    maxLines: 10,
                    decoration: InputDecoration(
                      labelText: 'Minutes content',
                      hintText: 'Record decisions, attendees, action items…',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  OutlinedButton.icon(
                    onPressed: _pickAttachment,
                    icon: const Icon(Icons.attach_file),
                    label: Text(
                      _attachment != null
                          ? _attachment!.name
                          : 'Attach file (optional)',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: const BorderSide(color: AppColors.accent),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                    ),
                  ),
                  if (_existingContent != null &&
                      _existingContent!.isNotEmpty &&
                      _status == 'approved') ...[
                    SizedBox(height: 12.h),
                    Text(
                      'Current approved minutes are loaded above. Submitting again may replace or create a new pending version (per server rules).',
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                    ),
                  ],
                  SizedBox(height: 24.h),
                  ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Submit Minutes',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
