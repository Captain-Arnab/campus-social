import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/api_service.dart';
import '../data/pref_service.dart';
import '../base/constant.dart';
import '../utils/sweetalert_helper.dart';

/// Lists e-certificates for the logged-in user (uploaded by admin for past events).
/// User sees only their own certificates.
class MyCertificatesView extends StatefulWidget {
  const MyCertificatesView({super.key});

  @override
  State<MyCertificatesView> createState() => _MyCertificatesViewState();
}

class _MyCertificatesViewState extends State<MyCertificatesView> {
  List<dynamic> _list = [];
  bool _loading = true;
  String? _error;

  Future<void> _load() async {
    final userId = await PrefService.getUserId();
    if (userId == null) {
      setState(() {
        _loading = false;
        _error = 'Please log in to view certificates.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiService.getCertificatesByUserId(userId);
      final data = response.data;
      if (data is Map && data['status'] == 'success') {
        final raw = data['data'];
        final list = raw is List ? raw : <dynamic>[];
        if (kDebugMode && list.isEmpty && (data['count'] == null || (data['count'] is int && (data['count'] as int) > 0))) {
          debugPrint('Certificates API: status=success but data/count mismatch. count=${data['count']} listLength=${list.length}');
        }
        setState(() {
          _list = list;
          _loading = false;
          _error = null;
        });
      } else {
        final msg = (data is Map ? data['message'] : null)?.toString() ?? 'Failed to load certificates.';
        setState(() {
          _list = [];
          _loading = false;
          _error = msg;
        });
      }
    } catch (e) {
      debugPrint('Certificates load error: $e');
      setState(() {
        _list = [];
        _loading = false;
        _error = 'Network error.';
      });
    }
  }

  String _certificateUrl(String filePath) {
    if (filePath.isEmpty) return '';
    if (filePath.startsWith('http')) return filePath;
    String path = filePath.replaceFirst(RegExp(r'^certificates[/\\]'), '');
    return '${Constant.uploadsBaseUrl}${Constant.certificatesPath}$path';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FD),
        appBar: AppBar(
          title: const Text("My Certificates", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Get.back()),
        ),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFFFF5F15))),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("My Certificates", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Get.back()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64.w, color: Colors.grey),
                    SizedBox(height: 16.h),
                    Text(_error!, textAlign: TextAlign.center, style: TextStyle(fontSize: 16.sp, color: Colors.grey[700])),
                    SizedBox(height: 16.h),
                    ElevatedButton(
                      onPressed: _load,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5F15), foregroundColor: Colors.white),
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              ),
            )
          : _list.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.card_membership, size: 80.w, color: Colors.grey[300]),
                      SizedBox(height: 16.h),
                      Text(
                        "No certificates yet",
                        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 8.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32.w),
                        child: Text(
                          "Certificates for past events (volunteer/participant) are uploaded by admin. You will see them here when available.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: const Color(0xFFFF5F15),
                  child: ListView.builder(
                    padding: EdgeInsets.all(16.w),
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    cacheExtent: 200,
                    itemCount: _list.length,
                    itemBuilder: (context, index) {
                      final c = _list[index];
                      final eventTitle = (c is Map ? c['event_title'] : null)?.toString() ?? 'Event';
                      final eventDate = (c is Map ? c['event_date'] : null)?.toString() ?? '';
                      final type = (c is Map ? c['type'] : null)?.toString() ?? 'certificate';
                      final filePath = (c is Map ? c['file_path'] : null)?.toString() ?? '';
                      final url = _certificateUrl(filePath);
                      return Card(
                        margin: EdgeInsets.only(bottom: 12.h),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFFF5F15).withOpacity(0.2),
                            child: const Icon(Icons.card_membership, color: Color(0xFFFF5F15)),
                          ),
                          title: Text(
                            eventTitle,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),
                          ),
                          subtitle: Text(
                            '${type.toUpperCase()} • $eventDate',
                            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                          ),
                          trailing: const Icon(Icons.open_in_new),
                          onTap: () async {
                            if (url.isEmpty) return;
                            final uri = Uri.tryParse(url);
                            if (uri != null && await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            } else {
                              SweetAlertHelper.showError(context, "Certificate", "Could not open link.");
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
