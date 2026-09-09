import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../base/constant.dart';
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
  String? _fileUrl;
  String? _filePath;
  String? _submittedAt;
  /// Only set when the current load/submit request fails — never left over from prior opens.
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
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Invalid event';
        _status = null;
        _existingContent = null;
        _fileUrl = null;
        _filePath = null;
        _submittedAt = null;
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      _status = null;
      _existingContent = null;
      _fileUrl = null;
      _filePath = null;
      _submittedAt = null;
    });
    try {
      final res = await ApiService.getMeetingMinutes(eid);
      final data = ApiService.parseResponseBody(res.data);
      if (!mounted) return;

      if (data == null) {
        setState(() => _error = ApiService.responseErrorHint(res));
        return;
      }

      final statusStr = data['status']?.toString().toLowerCase() ?? '';
      if (statusStr == 'success') {
        final record = ApiService.meetingMinutesRecordFromResponse(res.data);
        if (record == null) {
          // Empty list — no minutes yet; not an error.
          setState(() {
            _error = null;
            _status = null;
            _existingContent = null;
          });
          return;
        }
        final content = (record['content'] ?? record['minutes'] ?? '').toString();
        final status = (record['status'] ?? '').toString().toLowerCase();
        setState(() {
          _error = null;
          _existingContent = content;
          _status = status.isEmpty ? null : status;
          _fileUrl = (record['file_url'] ?? '').toString().trim();
          _filePath = (record['file_path'] ?? '').toString().trim();
          _submittedAt = (record['created_at'] ?? record['updated_at'] ?? '')
              .toString()
              .trim();
          if (content.isNotEmpty) _contentCtrl.text = content;
        });
        return;
      }

      // Error responses: treat "not found" / empty as no minutes; ignore stale
      // "id required" from the old action=get shape if the server still returns it.
      final msg = (data['message'] ?? '').toString();
      final lower = msg.toLowerCase();
      final benign = lower.contains('not found') ||
          lower.contains('no minutes') ||
          lower.contains('id required') ||
          lower.trim().isEmpty;
      setState(() {
        _error = benign ? null : msg;
        _status = null;
        _existingContent = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
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

  Future<void> _openExistingFile() async {
    final direct = (_fileUrl ?? '').trim();
    final path = (_filePath ?? '').trim();
    final url = direct.isNotEmpty
        ? (direct.startsWith('http') ? direct : Constant.uploadPublicUrl(direct))
        : (path.isNotEmpty ? Constant.uploadPublicUrl(path) : '');
    if (url.isEmpty) return;
    final u = Uri.tryParse(url);
    if (u == null) return;
    await launchUrl(u, mode: LaunchMode.externalApplication);
  }

  Future<void> _submit() async {
    final text = _contentCtrl.text.trim();
    if (text.isEmpty) {
      SweetAlertHelper.showWarning(context, 'Required', 'Please enter the meeting minutes.');
      return;
    }
    final eid = _eventId;
    if (eid == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
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

  String? _formatSubmittedAt() {
    final raw = _submittedAt;
    if (raw == null || raw.isEmpty) return null;
    final dt = DateTime.tryParse(raw.replaceAll(' ', 'T'));
    if (dt == null) return raw;
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final title = (widget.event['title'] ?? 'Event').toString();
    final hasExistingFile =
        (_fileUrl != null && _fileUrl!.isNotEmpty) ||
        (_filePath != null && _filePath!.isNotEmpty);
    final submittedLabel = _formatSubmittedAt();

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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Minutes status: ${_statusLabel(_status!)}',
                                  style: TextStyle(
                                    color: _statusColor(_status!),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.sp,
                                  ),
                                ),
                                if (submittedLabel != null) ...[
                                  SizedBox(height: 2.h),
                                  Text(
                                    'Submitted $submittedLabel',
                                    style: TextStyle(
                                      color: _statusColor(_status!),
                                      fontSize: 11.sp,
                                    ),
                                  ),
                                ],
                              ],
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
                  if (hasExistingFile) ...[
                    OutlinedButton.icon(
                      onPressed: _openExistingFile,
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Open current attachment'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.teal,
                        side: const BorderSide(color: AppColors.teal),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                    ),
                    SizedBox(height: 8.h),
                  ],
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
