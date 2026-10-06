import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../data/app_bootstrap.dart';
import '../theme/app_theme.dart';
import '../utils/app_navigation.dart';
import '../utils/event_image_helper.dart';
import '../utils/winner_display_helper.dart';
import '../utils/winner_feed_helper.dart';
import '../widgets/app_bar_title_with_brand_logo.dart';
import '../widgets/app_loading_screen.dart';
import '../widgets/event_poster_image.dart';
import 'event_detail_view.dart';

/// Full-screen list of winners by event (closed + ended approved events).
class WinnersView extends StatefulWidget {
  const WinnersView({super.key});

  @override
  State<WinnersView> createState() => _WinnersViewState();
}

class _WinnersViewState extends State<WinnersView> {
  static const int _limit = 200;

  List<WinnerEventGroup> _groups = [];
  bool _loading = true;
  String? _error;

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await WinnerFeedHelper.loadWinners(limit: _limit);
      if (!mounted) return;
      setState(() {
        _groups = WinnerFeedHelper.groupByEvent(rows);
        _loading = false;
      });
    } catch (e) {
      debugPrint('[WinnersView] load error: $e');
      if (mounted) {
        setState(() {
          _error = 'Could not load winners. Pull to retry.';
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
              : _groups.isEmpty
                  ? Center(
                      child: Text(
                        'No events with winners yet.',
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
                        itemCount: _groups.length,
                        itemBuilder: (context, index) {
                          final e = _groups[index].event;
                          return _WinnerEventCard(
                            event: e,
                            winners: _groups[index].winners,
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
    final startRaw = event is Map ? (event['event_date']?.toString() ?? '') : '';
    final start = DateTime.tryParse(startRaw.replaceAll(' ', 'T'));
    final date = start != null ? DateFormat('d MMM yyyy').format(start) : startRaw;
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
                final pos = winnerPosition(w);
                final name = winnerDisplayName(w);
                final affiliation = winnerAffiliation(w);
                return Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Row(
                    children: [
                      WinnerAvatar(winner: w, position: pos, size: 40),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppColors.navy,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (affiliation.isNotEmpty)
                              Text(
                                affiliation,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      if (pos > 0)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: winnerMedalColor(pos).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            winnerPositionLabel(pos),
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: pos <= 3
                                  ? winnerMedalColor(pos)
                                  : AppColors.textSecondary,
                            ),
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

  @override
  Widget build(BuildContext context) {
    final url = EventImageHelper.bannerUrl(event);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 64.w,
        height: 64.w,
        child: url != null && url.isNotEmpty
            ? EventPosterImage.fromUrl(url, category: category)
            : category.isEmpty
                ? ColoredBox(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    child: const Icon(Icons.emoji_events_rounded, color: AppColors.gold),
                  )
                : ColoredBox(
                    color: AppColors.categoryColor(category).withValues(alpha: 0.15),
                    child: Icon(
                      AppColors.categoryIcon(category),
                      color: AppColors.categoryColor(category),
                    ),
                  ),
      ),
    );
  }
}
