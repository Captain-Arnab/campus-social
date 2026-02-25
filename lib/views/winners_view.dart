import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../data/api_service.dart';
import 'event_detail_view.dart';

/// Full-screen list of winners by event (past events). Scroll to see who won which event.
class WinnersView extends StatefulWidget {
  const WinnersView({super.key});

  @override
  State<WinnersView> createState() => _WinnersViewState();
}

class _WinnersViewState extends State<WinnersView> {
  List<dynamic> _pastEvents = [];
  final Map<int, List<dynamic>> _winnersByEvent = {};
  bool _loading = true;
  String? _error;

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; _winnersByEvent.clear(); });
    try {
      final response = await ApiService.getPastEvents();
      final data = response.data;
      if (data is! Map || data['status'] != 'success') {
        setState(() { _loading = false; _pastEvents = []; _error = 'Failed to load events.'; });
        return;
      }
      final list = data['data'];
      final events = list is List ? list : [];
      setState(() { _pastEvents = events; });

      // Fetch winners from event_winners.php for each event
      for (final e in events) {
        final idRaw = e is Map ? e['id'] : null;
        final id = idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '');
        if (id == null) continue;
        final winRes = await ApiService.getWinnersByEventId(id);
        if (winRes.data is Map && winRes.data['status'] == 'success') {
          final wList = winRes.data['data'];
          if (wList is List && wList.isNotEmpty && mounted) {
            setState(() => _winnersByEvent[id] = wList);
          }
        }
      }
    } catch (e) {
      setState(() { _error = 'Network error.'; });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("Winners", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Get.back()),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF5F15)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: TextStyle(color: Colors.grey[600])),
                      SizedBox(height: 16.h),
                      ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5F15), foregroundColor: Colors.white), child: const Text("Retry")),
                    ],
                  ),
                )
              : _pastEvents.isEmpty
                  ? Center(child: Text("No past events with winners.", style: TextStyle(color: Colors.grey[600], fontSize: 16.sp)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: const Color(0xFFFF5F15),
                      child: ListView.builder(
                        padding: EdgeInsets.all(16.w),
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        cacheExtent: 300,
                        itemCount: _pastEvents.length,
                        itemBuilder: (context, index) {
                          final e = _pastEvents[index];
                          final idRaw = e['id'];
                          final id = idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '');
                          final winners = id != null ? _winnersByEvent[id] : null;
                          if (winners == null || winners.isEmpty) return const SizedBox.shrink();
                          final title = e['title']?.toString() ?? 'Event';
                          final date = e['event_date']?.toString() ?? '';
                          final venue = e['venue']?.toString() ?? '';
                          final category = e['category']?.toString() ?? '';
                          return Card(
                            margin: EdgeInsets.only(bottom: 16.h),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: InkWell(
                              onTap: () => Get.to(() => EventDetailView(event: e), transition: Transition.rightToLeft),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: EdgeInsets.all(16.w),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(10.w),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF5F15).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(Icons.emoji_events, color: const Color(0xFFFF5F15), size: 28.w),
                                        ),
                                        SizedBox(width: 12.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17.sp)),
                                              if (date.isNotEmpty) Text(date, style: TextStyle(fontSize: 12.sp, color: Colors.grey[600])),
                                              if (venue.isNotEmpty) Text(venue, style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]), maxLines: 1, overflow: TextOverflow.ellipsis),
                                              if (category.isNotEmpty) Text(category, style: TextStyle(fontSize: 11.sp, color: const Color(0xFFFF5F15), fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 14.h),
                                    Text("Winners", style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                                    SizedBox(height: 6.h),
                                    ...winners.map<Widget>((w) {
                                      final pos = (w is Map ? w['position'] : null) ?? 0;
                                      final name = (w is Map ? w['full_name'] : null)?.toString() ?? '—';
                                      return Padding(
                                        padding: EdgeInsets.only(bottom: 6.h),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 26.w,
                                              height: 26.w,
                                              decoration: BoxDecoration(
                                                color: pos == 1 ? const Color(0xFFFFD700) : (pos == 2 ? Colors.grey.shade400 : Colors.brown.shade300),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(child: Text('$pos', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold))),
                                            ),
                                            SizedBox(width: 12.w),
                                            Text(name, style: TextStyle(fontSize: 14.sp)),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
