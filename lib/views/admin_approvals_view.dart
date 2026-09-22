import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/profile_controller.dart';
import '../data/api_service.dart';
import '../data/pref_service.dart';
import '../theme/app_theme.dart';
import '../utils/sweetalert_helper.dart';
import '../widgets/app_calendar_theme.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_loading_screen.dart';
import '../widgets/campus_app_bar.dart';

class AdminApprovalsView extends StatefulWidget {
  const AdminApprovalsView({super.key});

  @override
  State<AdminApprovalsView> createState() => _AdminApprovalsViewState();
}

class _AdminApprovalsViewState extends State<AdminApprovalsView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  String? _userId;
  bool _canApprove = false;
  bool _gateLoading = true;

  bool _loadingEvents = true;
  bool _loadingEdits = true;
  List<Map<String, dynamic>> _pendingEvents = [];
  List<Map<String, dynamic>> _pendingEdits = [];
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initGate();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initGate() async {
    _userId = await PrefService.getUserId();
    if (Get.isRegistered<ProfileController>()) {
      _canApprove = Get.find<ProfileController>().userData.value.canApproveEvents;
    }
    if (!_canApprove && _userId != null) {
      if (Get.isRegistered<ProfileController>()) {
        await Get.find<ProfileController>().loadProfile();
        _canApprove = Get.find<ProfileController>().userData.value.canApproveEvents;
      }
    }
    if (!mounted) return;
    setState(() => _gateLoading = false);
    if (_userId != null && _userId!.isNotEmpty && _canApprove) {
      await _reloadAll();
    }
  }

  Future<void> _reloadAll() async {
    await Future.wait([_loadPendingEvents(), _loadPendingEdits()]);
  }

  List<Map<String, dynamic>> _extractList(dynamic root) {
    if (root is List) {
      return root
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (root is! Map) return [];
    for (final key in ['data', 'events', 'pending', 'list', 'items']) {
      final v = root[key];
      if (v is List) {
        return v
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      if (v is Map) {
        final nested = _extractList(v);
        if (nested.isNotEmpty) return nested;
      }
    }
    return [];
  }

  Future<void> _loadPendingEvents() async {
    final uid = _userId ?? await PrefService.getUserId();
    if (uid == null || uid.isEmpty) return;
    setState(() {
      _loadingEvents = true;
      _loadError = null;
    });
    try {
      final response = await ApiService.listPendingAdminEvents(uid);
      final data = response.data;
      if (data is Map && data['status'] == 'success') {
        _pendingEvents = _extractList(data);
      } else if (data is Map) {
        _loadError = data['message']?.toString();
        _pendingEvents = [];
      } else {
        _pendingEvents = [];
      }
    } catch (e) {
      _loadError = 'Could not load pending events.';
      _pendingEvents = [];
    } finally {
      if (mounted) setState(() => _loadingEvents = false);
    }
  }

  Future<void> _loadPendingEdits() async {
    final uid = _userId ?? await PrefService.getUserId();
    if (uid == null || uid.isEmpty) return;
    setState(() => _loadingEdits = true);
    try {
      final response = await ApiService.listPendingAdminEdits(uid);
      final data = response.data;
      if (data is Map && data['status'] == 'success') {
        _pendingEdits = _extractList(data);
      } else {
        _pendingEdits = [];
      }
    } catch (_) {
      _pendingEdits = [];
    } finally {
      if (mounted) setState(() => _loadingEdits = false);
    }
  }

  String _field(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty && s != 'null') return s;
    }
    return '';
  }

  String _eventId(Map<String, dynamic> m) =>
      _field(m, ['event_id', 'id']);

  String _descriptionSnippet(String raw) {
    final t = raw.trim();
    if (t.length <= 140) return t;
    return '${t.substring(0, 140)}…';
  }

  Future<String?> _pickDateTime({DateTime? initial}) async {
    final base = initial ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (ctx, child) => AppCalendarTheme.wrap(ctx, child),
    );
    if (date == null) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (time == null) return null;
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
  }

  Future<bool> _runAction({
    required String action,
    required String eventId,
    String? reason,
    String? rescheduleDate,
    String? newDate,
  }) async {
    final uid = _userId ?? await PrefService.getUserId();
    if (uid == null || uid.isEmpty) {
      SweetAlertHelper.showError(context, 'Error', 'Please log in again.');
      return false;
    }
    try {
      final response = await ApiService.adminEventAction(
        action: action,
        userId: uid,
        eventId: eventId,
        reason: reason,
        rescheduleDate: rescheduleDate,
        newDate: newDate,
      );
      final data = response.data;
      if (data is Map && data['status'] == 'success') {
        SweetAlertHelper.showSuccess(
          context,
          'Success',
          data['message']?.toString() ?? 'Done.',
        );
        await _reloadAll();
        return true;
      }
      final msg = data is Map
          ? (data['message']?.toString() ?? 'Action failed.')
          : 'Action failed.';
      SweetAlertHelper.showError(context, 'Error', msg);
      return false;
    } catch (_) {
      SweetAlertHelper.showError(context, 'Error', 'Connection failed.');
      return false;
    }
  }

  Future<void> _confirmApprove(String eventId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve event'),
        content: const Text('Publish this event for the campus?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Approve', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _runAction(action: 'approve', eventId: eventId);
    }
  }

  Future<String?> _promptReasonDialog({
    required String title,
    bool reasonRequired = true,
  }) async {
    final reasonCtrl = TextEditingController();
    return showDialog<String?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: reasonCtrl,
            decoration: const InputDecoration(
              labelText: 'Reason',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                if (reasonRequired && reasonCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Reason is required.')),
                  );
                  return;
                }
                Navigator.pop(ctx, reasonCtrl.text.trim());
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _rejectEvent(String eventId) async {
    final reason = await _promptReasonDialog(title: 'Reject event', reasonRequired: true);
    if (reason == null) return;
    await _runAction(action: 'reject', eventId: eventId, reason: reason);
  }

  Future<void> _holdEvent(String eventId) async {
    String? schedule;
    final reasonCtrl = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: const Text('Put on hold'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: reasonCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Reason (required)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 12.h),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await _pickDateTime();
                        if (picked != null) setLocal(() => schedule = picked);
                      },
                      icon: const Icon(Icons.schedule_outlined),
                      label: Text(
                        schedule == null ? 'Optional reschedule date' : schedule!,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                TextButton(
                  onPressed: () {
                    if (reasonCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Reason is required.')),
                      );
                      return;
                    }
                    Navigator.pop(ctx, true);
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
    if (submitted != true) return;
    await _runAction(
      action: 'hold',
      eventId: eventId,
      reason: reasonCtrl.text.trim(),
      rescheduleDate: schedule,
    );
  }

  Future<void> _rescheduleEvent(String eventId) async {
    final newDate = await _pickDateTime();
    if (newDate == null) return;
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reschedule event'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New date: $newDate', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp)),
            SizedBox(height: 12.h),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (ok != true) return;
    await _runAction(
      action: 'reschedule',
      eventId: eventId,
      newDate: newDate,
      reason: reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim(),
    );
  }

  Widget _pendingEventCard(Map<String, dynamic> event) {
    final eventId = _eventId(event);
    final title = _field(event, ['title', 'event_title']) ;
    final date = _field(event, ['event_date', 'date', 'start_date']);
    final venue = _field(event, ['venue', 'location']);
    final organizer = _field(event, ['host_name', 'organizer', 'organizer_name', 'created_by']);
    final description = _field(event, ['description', 'event_description']);

    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 14.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.isNotEmpty ? title : 'Untitled event',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          if (date.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary),
                SizedBox(width: 6.w),
                Expanded(child: Text(date, style: TextStyle(fontSize: 13.sp, color: Colors.grey[700]))),
              ],
            ),
          ],
          if (venue.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Row(
              children: [
                Icon(Icons.place_outlined, size: 16, color: AppColors.textSecondary),
                SizedBox(width: 6.w),
                Expanded(child: Text(venue, style: TextStyle(fontSize: 13.sp, color: Colors.grey[700]))),
              ],
            ),
          ],
          if (organizer.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
                SizedBox(width: 6.w),
                Expanded(child: Text(organizer, style: TextStyle(fontSize: 13.sp, color: Colors.grey[700]))),
              ],
            ),
          ],
          if (description.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Text(
              _descriptionSnippet(description),
              style: TextStyle(fontSize: 13.sp, color: Colors.grey[600], height: 1.4),
            ),
          ],
          SizedBox(height: 14.h),
          if (eventId.isEmpty)
            Text('Missing event id', style: TextStyle(color: AppColors.error, fontSize: 12.sp))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _actionChip('Approve', AppColors.success, () => _confirmApprove(eventId)),
                _actionChip('Reject', AppColors.error, () => _rejectEvent(eventId)),
                _actionChip('Hold', Colors.orange.shade800, () => _holdEvent(eventId)),
                _actionChip('Reschedule', AppColors.indigo, () => _rescheduleEvent(eventId)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _pendingEditCard(Map<String, dynamic> event) {
    final eventId = _eventId(event);
    final title = _field(event, ['title', 'event_title']);
    final date = _field(event, ['event_date', 'date']);
    final venue = _field(event, ['venue', 'location']);
    final description = _field(event, ['description', 'pending_description', 'edit_summary']);

    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 14.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.isNotEmpty ? title : 'Event edit',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          if (date.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Text(date, style: TextStyle(fontSize: 13.sp, color: Colors.grey[700])),
          ],
          if (venue.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(venue, style: TextStyle(fontSize: 13.sp, color: Colors.grey[700])),
          ],
          if (description.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              _descriptionSnippet(description),
              style: TextStyle(fontSize: 13.sp, color: Colors.grey[600], height: 1.4),
            ),
          ],
          SizedBox(height: 14.h),
          if (eventId.isEmpty)
            Text('Missing event id', style: TextStyle(color: AppColors.error, fontSize: 12.sp))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _actionChip('Approve edit', AppColors.success, () async {
                  await _runAction(action: 'approve_edit', eventId: eventId);
                }),
                _actionChip('Reject edit', AppColors.error, () async {
                  final reason = await _promptReasonDialog(
                    title: 'Reject edit',
                    reasonRequired: true,
                  );
                  if (reason == null) return;
                  await _runAction(action: 'reject_edit', eventId: eventId, reason: reason);
                }),
              ],
            ),
        ],
      ),
    );
  }

  Widget _actionChip(String label, Color color, VoidCallback onTap) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          child: Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12.sp),
          ),
        ),
      ),
    );
  }

  Widget _eventsTab() {
    if (_loadingEvents) {
      return const AppLoadingScreen(message: 'Loading pending events...');
    }
    if (_loadError != null && _pendingEvents.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Text(_loadError!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700])),
        ),
      );
    }
    if (_pendingEvents.isEmpty) {
      return const AppEmptyState(
        icon: Icons.event_busy_outlined,
        headline: 'No pending events',
        supporting: 'New submissions will appear here.',
      );
    }
    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _loadPendingEvents,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: EdgeInsets.only(top: 12.h, bottom: 24.h),
        itemCount: _pendingEvents.length,
        itemBuilder: (_, i) => _pendingEventCard(_pendingEvents[i]),
      ),
    );
  }

  Widget _editsTab() {
    if (_loadingEdits) {
      return const AppLoadingScreen(message: 'Loading pending edits...');
    }
    if (_pendingEdits.isEmpty) {
      return const AppEmptyState(
        icon: Icons.edit_note_outlined,
        headline: 'No pending edits',
        supporting: 'Editor changes awaiting approval will show here.',
      );
    }
    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _loadPendingEdits,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: EdgeInsets.only(top: 12.h, bottom: 24.h),
        itemCount: _pendingEdits.length,
        itemBuilder: (_, i) => _pendingEditCard(_pendingEdits[i]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_gateLoading) {
      return const Scaffold(
        backgroundColor: AppColors.cream,
        body: AppLoadingScreen(message: 'Loading...'),
      );
    }

    if (_userId == null || _userId!.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        appBar: const CampusAppBar(titleText: 'Admin approvals'),
        body: const AppEmptyState(
          icon: Icons.lock_outline,
          headline: 'Sign in required',
          supporting: 'Log in to manage approvals.',
        ),
      );
    }

    if (!_canApprove) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        appBar: const CampusAppBar(titleText: 'Admin approvals'),
        body: const AppEmptyState(
          icon: Icons.admin_panel_settings_outlined,
          headline: 'Not available',
          supporting: 'Your account cannot approve campus events.',
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: CampusAppBar(
        titleText: 'Admin approvals',
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Pending events'),
            Tab(text: 'Pending edits'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _eventsTab(),
          _editsTab(),
        ],
      ),
    );
  }
}
