import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../data/api_service.dart';
import '../data/app_bootstrap.dart';
import '../theme/app_theme.dart';
import '../utils/app_navigation.dart';
import '../utils/event_image_helper.dart';
import '../widgets/app_bar_title_with_brand_logo.dart';
import '../widgets/app_loading_screen.dart';
import '../widgets/event_poster_image.dart';
import 'event_detail_view.dart';

/// Full-screen list of winners by event (past events).
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
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      _winnersByEvent.clear();
    });
    try {
      final response = await ApiService.getPastEvents();
      if (!mounted) return;
      final data = response.data;
      if (data is! Map || data['status'] != 'success') {
        setState(() {
          _loading = false;
          _pastEvents = [];
          _error = 'Failed to load events.';
        });
        return;
      }
      final list = data['data'];
      final events = list is List ? list : <dynamic>[];

      final pending = <Future<MapEntry<int, List<dynamic>>?>>[];
      for (final e in events) {
        final idRaw = e is Map ? e['id'] : null;
        final id = idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '');
        if (id == null) continue;
        pending.add(() async {
          try {
            final winRes = await ApiService.getWinnersByEventId(id);
            if (winRes.data is Map && winRes.data['status'] == 'success') {
              final wList = winRes.data['data'];
              if (wList is List && wList.isNotEmpty) {
                return MapEntry<int, List<dynamic>>(
                  id,
                  List<dynamic>.from(wList),
                );
              }
            }
          } catch (_) {}
          return null;
        }());
      }

      final resolved = await Future.wait(pending);
      final winners = <int, List<dynamic>>{};
      for (final entry in resolved) {
        if (entry != null) winners[entry.key] = entry.value;
      }

      if (!mounted) return;
      setState(() {
        _pastEvents = events;
        _winnersByEvent
          ..clear()
          ..addAll(winners);
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Network error.';
          _loading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final eventsWithWinners = _pastEvents.where((e) {
      final idRaw = e is Map ? e['id'] : null;
      final id = idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '');
      if (id == null) return false;
      final w = _winnersByEvent[id];
      return w != null && w.isNotEmpty;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const AppBarTitleWithBrandLogo(
          onPrimaryBackground: false,
          title: Text(
            'Winners',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const AppLoadingScreen(message: 'Loading winners...')
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: TextStyle(color: Colors.grey[600])),
                      SizedBox(height: 16.h),
                      ElevatedButton(
                        onPressed: _load,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : eventsWithWinners.isEmpty
                  ? Center(
                      child: Text(
                        'No past events with winners.',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16.sp,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.accent,
                      child: ListView.builder(
                        padding: EdgeInsets.all(16.w),
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        cacheExtent: 300,
                        itemCount: eventsWithWinners.length,
                        itemBuilder: (context, index) {
                          final e = eventsWithWinners[index];
                          final idRaw = e['id'];
                          final id = idRaw is int
                              ? idRaw
                              : int.tryParse(idRaw?.toString() ?? '');
                          final winners =
                              id != null ? _winnersByEvent[id]! : <dynamic>[];
                          return _WinnerEventCard(
                            event: e,
                            winners: winners,
                            onTap: () => AppNavigation.to(
                              () => EventDetailView(event: e),
                              prepare: (ctx) =>
                                  AppBootstrap.prepareEventDetail(ctx, e),
                              loadingMessage: 'Loading event...',
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _WinnerEventCard extends StatelessWidget {
  final dynamic event;
  final List<dynamic> winners;
  final VoidCallback onTap;

  const _WinnerEventCard({
    required this.event,
    required this.winners,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = event is Map
        ? (event['title']?.toString() ?? 'Event')
        : 'Event';
    final endDateRaw =
        event is Map ? (event['event_end_date']?.toString() ?? '') : '';
    final startDate =
        event is Map ? (event['event_date']?.toString() ?? '') : '';
    final date = (endDateRaw.isNotEmpty && endDateRaw != '0000-00-00 00:00:00')
        ? '$startDate → $endDateRaw'
        : startDate;
    final venue = event is Map ? (event['venue']?.toString() ?? '') : '';
    final category =
        event is Map ? (event['category']?.toString() ?? '') : '';

    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _EventThumb(event: event, category: category),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16.sp,
                            color: AppColors.navy,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                        ),
                        if (date.isNotEmpty) ...[
                          SizedBox(height: 4.h),
                          Text(
                            date,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (venue.isNotEmpty) ...[
                          SizedBox(height: 2.h),
                          Text(
                            venue,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.textSecondary,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                          ),
                        ],
                        if (category.isNotEmpty) ...[
                          SizedBox(height: 6.h),
                          Text(
                            category,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppColors.categoryColor(category),
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: const Divider(height: 1, color: AppColors.border),
              ),
              Text(
                'Winners',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navyMuted,
                ),
              ),
              SizedBox(height: 8.h),
              ...winners.map<Widget>((w) {
                final posRaw = w is Map ? w['position'] : null;
                final pos = posRaw is int
                    ? posRaw
                    : int.tryParse(posRaw?.toString() ?? '') ?? 0;
                final name =
                    (w is Map ? w['full_name'] : null)?.toString() ?? '—';
                return Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Row(
                    children: [
                      _RankBadge(position: pos),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.navy,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventThumb extends StatelessWidget {
  final dynamic event;
  final String category;

  const _EventThumb({required this.event, required this.category});

  static const double _side = 56;

  @override
  Widget build(BuildContext context) {
    final hasImage = EventImageHelper.bannerUrl(event)?.isNotEmpty == true;
    final color = AppColors.categoryColor(category);
    final radius = BorderRadius.circular(12);

    if (hasImage) {
      return ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          width: _side.w,
          height: _side.w,
          child: EventPosterImage(
            event: event,
            preserveFullPoster: true,
          ),
        ),
      );
    }

    return Container(
      width: _side.w,
      height: _side.w,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: radius,
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Icon(
        AppColors.categoryIcon(category.isEmpty ? null : category),
        color: color,
        size: 28.w,
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int position;

  const _RankBadge({required this.position});

  static const _gold = Color(0xFFFFD700);
  static const _silver = Color(0xFFC0C0C0);
  static const _bronze = Color(0xFFCD7F32);

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final bool isMedal;
    switch (position) {
      case 1:
        bg = _gold;
        fg = Colors.white;
        isMedal = true;
        break;
      case 2:
        bg = _silver;
        fg = const Color(0xFF2F2F2F);
        isMedal = true;
        break;
      case 3:
        bg = _bronze;
        fg = Colors.white;
        isMedal = true;
        break;
      default:
        bg = AppColors.surfaceMuted;
        fg = AppColors.navyMuted;
        isMedal = false;
    }

    return Container(
      width: 30.w,
      height: 30.w,
      decoration: BoxDecoration(
        gradient: isMedal
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(bg, Colors.white, 0.28)!,
                  bg,
                  Color.lerp(bg, Colors.black, 0.12)!,
                ],
              )
            : null,
        color: isMedal ? null : bg,
        shape: BoxShape.circle,
        boxShadow: isMedal
            ? [
                BoxShadow(
                  color: bg.withValues(alpha: 0.4),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
        border: Border.all(
          color: isMedal
              ? Colors.white.withValues(alpha: 0.65)
              : AppColors.border,
          width: isMedal ? 1.5 : 1,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (position == 1)
            Positioned(
              top: 2.h,
              child: Icon(
                Icons.star_rounded,
                size: 8.w,
                color: Colors.white.withValues(alpha: 0.95),
              ),
            ),
          Padding(
            padding: EdgeInsets.only(top: position == 1 ? 4.h : 0),
            child: Text(
              '$position',
              style: TextStyle(
                fontSize: position == 1 ? 11.sp : 12.sp,
                fontWeight: FontWeight.w800,
                color: fg,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
