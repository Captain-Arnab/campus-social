import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_theme.dart';
import '../utils/winner_display_helper.dart';
import 'app_network_image.dart';

/// Compact auto-scrolling winner photos strip for Explore.
/// Matches [HomeAdCarousel] PageView spacing / peek pattern.
class WinnerPhotosCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> photos;

  /// While true and [photos] is empty, placeholder cards are shown instead of the empty message.
  final bool loading;
  final void Function(Map<String, dynamic> winner)? onWinnerTap;

  /// Opens the full Winners list; shown as a "See all" link beside the title.
  final VoidCallback? onSeeAll;

  const WinnerPhotosCarousel({
    super.key,
    required this.photos,
    this.loading = false,
    this.onWinnerTap,
    this.onSeeAll,
  });

  @override
  State<WinnerPhotosCarousel> createState() => _WinnerPhotosCarouselState();
}

class _WinnerPhotosCarouselState extends State<WinnerPhotosCarousel> {
  late final PageController _pageController;
  int _index = 0;
  Timer? _autoScrollTimer;

  static const double _viewportFraction = 0.84;
  static const Duration _autoInterval = Duration(seconds: 4);
  static const Duration _animDuration = Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: _viewportFraction);
    _startAutoScroll();
  }

  @override
  void didUpdateWidget(covariant WinnerPhotosCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photos.length != widget.photos.length) {
      _restartAutoScroll();
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (widget.photos.length <= 1) return;
    _autoScrollTimer = Timer.periodic(_autoInterval, (_) => _advanceSlide());
  }

  void _restartAutoScroll() {
    _autoScrollTimer?.cancel();
    if (!mounted || widget.photos.length <= 1) return;
    _startAutoScroll();
  }

  Future<void> _advanceSlide() async {
    if (!mounted || widget.photos.length <= 1) return;
    if (!_pageController.hasClients) return;
    final next = (_index + 1) % widget.photos.length;
    await _pageController.animateToPage(
      next,
      duration: _animDuration,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 14.w, 8.h),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Recent Winners',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              if (widget.onSeeAll != null &&
                  (widget.photos.isNotEmpty || widget.loading))
                _SeeAllChip(onTap: widget.onSeeAll!),
            ],
          ),
        ),
        if (widget.photos.isEmpty && widget.loading)
          SizedBox(
            height: 168.h,
            child: PageView.builder(
              controller: _pageController,
              itemCount: 3,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, i) => Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                child: const _WinnerCardSkeleton(),
              ),
            ),
          )
        else if (widget.photos.isEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border:
                    Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.emoji_events_outlined,
                      color: AppColors.gold, size: 24.sp),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Winners from recent events will appear here.',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          SizedBox(
            height: 168.h,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.photos.length,
              padEnds: true,
              onPageChanged: (i) {
                setState(() => _index = i);
                // Manual swipe resets the auto-scroll timer.
                _restartAutoScroll();
              },
              itemBuilder: (context, i) {
                final data = widget.photos[i];
                final onTap = widget.onWinnerTap;
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                  child: _WinnerPhotoCard(
                    data: data,
                    onTap: onTap == null || data['event_id'] == null
                        ? null
                        : () => onTap(data),
                  ),
                );
              },
            ),
          ),
          if (widget.photos.length > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.photos.length, (i) {
                final on = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 4.h),
                  width: on ? 18.w : 6.w,
                  height: 6.h,
                  decoration: BoxDecoration(
                    color: on ? AppColors.gold : AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
        ],
        SizedBox(height: 8.h),
      ],
    );
  }
}

class _SeeAllChip extends StatelessWidget {
  final VoidCallback onTap;

  const _SeeAllChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accent.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: EdgeInsets.fromLTRB(12.w, 6.h, 6.w, 6.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'See all',
                style: TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.sp,
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 18.sp, color: AppColors.accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _WinnerCardSkeleton extends StatefulWidget {
  const _WinnerCardSkeleton();

  @override
  State<_WinnerCardSkeleton> createState() => _WinnerCardSkeletonState();
}

class _WinnerCardSkeletonState extends State<_WinnerCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) =>
          Opacity(opacity: 0.45 + _pulse.value * 0.35, child: child),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        padding: EdgeInsets.all(12.w),
        alignment: Alignment.bottomLeft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 12.h,
              width: 110.w,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            SizedBox(height: 6.h),
            Container(
              height: 10.h,
              width: 70.w,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WinnerPhotoCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onTap;

  const _WinnerPhotoCard({required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    final photoUrl = winnerEventPhotoUrl(data);
    final position = winnerPosition(data);

    return Material(
      elevation: 0,
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (photoUrl != null)
              _PhotoLayout(
                data: data,
                url: photoUrl,
                fallback: _AvatarLayout(data: data, position: position),
              )
            else
              _AvatarLayout(data: data, position: position),
            if (position > 0)
              Positioned(
                top: 10.h,
                right: 10.w,
                child: _PositionBadge(position: position),
              ),
          ],
        ),
      ),
    );
  }
}

String _eventName(Map<String, dynamic> data) =>
    (data['event_name'] ?? data['event_title'] ?? data['title'] ?? '')
        .toString();

/// Uploaded winner photo, full-bleed with name over a gradient.
class _PhotoLayout extends StatelessWidget {
  final Map<String, dynamic> data;
  final String url;
  final Widget fallback;

  const _PhotoLayout(
      {required this.data, required this.url, required this.fallback});

  @override
  Widget build(BuildContext context) {
    final eventName = _eventName(data);
    final affiliation = winnerAffiliation(data);
    return Stack(
      fit: StackFit.expand,
      children: [
        AppNetworkImage(
          url: url,
          fit: BoxFit.cover,
          width: double.infinity,
          errorWidget: (_, __, ___) => fallback,
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(12.w, 16.h, 12.w, 8.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  winnerDisplayName(data),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.sp,
                  ),
                ),
                if (affiliation.isNotEmpty)
                  Text(
                    affiliation,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white70, fontSize: 10.sp),
                  ),
                if (eventName.isNotEmpty) ...[
                  SizedBox(height: 1.h),
                  Text(
                    eventName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11.sp,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// No uploaded photo: profile picture (or initials) beside the winner details.
class _AvatarLayout extends StatelessWidget {
  final Map<String, dynamic> data;
  final int position;

  const _AvatarLayout({required this.data, required this.position});

  @override
  Widget build(BuildContext context) {
    final tone = winnerMedalColor(position);
    final eventName = _eventName(data);
    final affiliation = winnerAffiliation(data);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tone.withValues(alpha: 0.16), AppColors.surface],
        ),
        border: Border.all(color: tone.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: AppShadows.card,
              ),
              child: WinnerAvatar(winner: data, position: position, size: 50),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Padding(
                // Keeps the text clear of the top-right position badge.
                padding: EdgeInsets.only(top: position > 0 ? 22.h : 0),
                child: LayoutBuilder(builder: (context, constraints) {
                  final base = DefaultTextStyle.of(context).style;
                  final scaler = MediaQuery.textScalerOf(context);
                  final nameStyle = base.merge(TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.sp,
                    height: 1.25,
                  ));
                  final affiliationStyle = base.merge(TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.sp,
                  ));
                  final eventStyle = base.merge(TextStyle(
                    color: AppColors.navyMuted,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ));
                  final iconSize = 14.sp;
                  final eventWidth = constraints.maxWidth - iconSize - 4.w;

                  double measure(
                      String text, TextStyle style, int lines, double width) {
                    if (text.isEmpty) return 0;
                    final tp = TextPainter(
                      text: TextSpan(text: text, style: style),
                      maxLines: lines,
                      ellipsis: '…',
                      textDirection: Directionality.of(context),
                      textScaler: scaler,
                    )..layout(maxWidth: width);
                    return tp.height;
                  }

                  double heightFor(
                          int nameLines, int affLines, int eventLines) =>
                      measure(winnerDisplayName(data), nameStyle, nameLines,
                          constraints.maxWidth) +
                      (affiliation.isEmpty || affLines == 0
                          ? 0
                          : 2.h +
                              measure(affiliation, affiliationStyle, affLines,
                                  constraints.maxWidth)) +
                      (eventName.isEmpty
                          ? 0
                          : 6.h +
                              measure(eventName, eventStyle, eventLines,
                                  eventWidth));

                  // Most generous (name, department, event) line counts that fit;
                  // short cards (landscape / split screen) step down.
                  const layouts = [
                    (2, 2, 2),
                    (1, 2, 2),
                    (2, 1, 2),
                    (1, 1, 2),
                    (1, 1, 1),
                    (1, 0, 1),
                  ];
                  final (nameLines, affLines, eventLines) = layouts.firstWhere(
                    (l) => heightFor(l.$1, l.$2, l.$3) <= constraints.maxHeight,
                    orElse: () => layouts.last,
                  );
                  final showAffiliation =
                      affiliation.isNotEmpty && affLines > 0;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        winnerDisplayName(data),
                        maxLines: nameLines,
                        overflow: TextOverflow.ellipsis,
                        style: nameStyle,
                      ),
                      if (showAffiliation) ...[
                        SizedBox(height: 2.h),
                        Text(
                          affiliation,
                          maxLines: affLines,
                          overflow: TextOverflow.ellipsis,
                          style: affiliationStyle,
                        ),
                      ],
                      if (eventName.isNotEmpty) ...[
                        SizedBox(height: 6.h),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(top: 1.h),
                              child: Icon(Icons.emoji_events_outlined,
                                  size: iconSize, color: AppColors.navyMuted),
                            ),
                            SizedBox(width: 4.w),
                            Expanded(
                              child: Text(
                                eventName,
                                maxLines: eventLines,
                                overflow: TextOverflow.ellipsis,
                                style: eventStyle,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PositionBadge extends StatelessWidget {
  final int position;

  const _PositionBadge({required this.position});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: winnerMedalColor(position),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events, size: 12.sp, color: Colors.white),
          SizedBox(width: 3.w),
          Text(
            winnerPositionLabel(position),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }
}
