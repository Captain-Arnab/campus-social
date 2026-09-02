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

  const WinnerPhotosCarousel({super.key, required this.photos});

  @override
  State<WinnerPhotosCarousel> createState() => _WinnerPhotosCarouselState();
}

class _WinnerPhotosCarouselState extends State<WinnerPhotosCarousel> {
  late final PageController _pageController;
  int _index = 0;
  Timer? _autoScrollTimer;

  static const double _viewportFraction = 0.76;
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
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 8.h),
          child: Text(
            'Recent Winners',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        if (widget.photos.isEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.emoji_events_outlined, color: AppColors.gold, size: 24.sp),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Winner photos from closed events will appear here.',
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
            height: 152.h,
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
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                  child: _WinnerPhotoCard(data: widget.photos[i]),
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

class _WinnerPhotoCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _WinnerPhotoCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final winnerName = winnerDisplayName(data);
    final eventName =
        (data['event_name'] ?? data['event_title'] ?? data['title'] ?? '')
            .toString();
    final url = winnerProfileImageUrl(data) ?? '';

    return Material(
      elevation: 0,
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(AppRadius.card),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (url.isNotEmpty)
            AppNetworkImage(
              url: url,
              fit: BoxFit.cover,
              width: double.infinity,
              errorWidget: (_, __, ___) => _fallbackIcon(),
            )
          else
            _fallbackIcon(),
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
                    winnerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.sp,
                    ),
                  ),
                  if (eventName.isNotEmpty) ...[
                    SizedBox(height: 1.h),
                    Text(
                      eventName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackIcon() {
    return ColoredBox(
      color: AppColors.surfaceMuted,
      child: Center(
        child: Icon(
          Icons.emoji_events_outlined,
          color: AppColors.gold,
          size: 32.sp,
        ),
      ),
    );
  }
}
