import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../base/constant.dart';
import '../theme/app_theme.dart';
import 'app_network_image.dart';

/// Auto-scrolling winner photos strip for Explore (closed events).
/// Always shows a "Recent Winners" header; empty API results get a compact placeholder.
class WinnerPhotosCarousel extends StatelessWidget {
  final List<Map<String, dynamic>> photos;

  const WinnerPhotosCarousel({super.key, required this.photos});

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
        if (photos.isEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.emoji_events_outlined, color: AppColors.gold, size: 28.sp),
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
        else
          CarouselSlider.builder(
            itemCount: photos.length,
            options: CarouselOptions(
              height: 168.h,
              autoPlay: photos.length > 1,
              autoPlayInterval: const Duration(seconds: 4),
              autoPlayAnimationDuration: const Duration(milliseconds: 450),
              enlargeCenterPage: true,
              viewportFraction: 0.86,
              enableInfiniteScroll: photos.length > 1,
              scrollPhysics: const BouncingScrollPhysics(),
            ),
            itemBuilder: (context, index, realIndex) {
              final m = photos[index];
              final photoRaw =
                  (m['photo_url'] ?? m['photo'] ?? m['image'] ?? m['image_url'] ?? '')
                      .toString()
                      .trim();
              final winnerName =
                  (m['winner_name'] ?? m['full_name'] ?? m['name'] ?? 'Winner')
                      .toString();
              final eventName =
                  (m['event_name'] ?? m['event_title'] ?? m['title'] ?? '')
                      .toString();
              var url = '';
              if (photoRaw.isNotEmpty) {
                if (photoRaw.startsWith('http://') || photoRaw.startsWith('https://')) {
                  url = photoRaw.contains('://micampus.co.in/') &&
                          !photoRaw.contains('://www.micampus.co.in/')
                      ? photoRaw.replaceFirst(
                          '://micampus.co.in/',
                          '://www.micampus.co.in/',
                        )
                      : photoRaw;
                } else {
                  url = Constant.uploadPublicUrl(photoRaw);
                }
              }
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (url.isNotEmpty)
                        AppNetworkImage(
                          url: url,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorWidget: (_, __, ___) => ColoredBox(
                            color: AppColors.surfaceMuted,
                            child: Icon(
                              Icons.emoji_events_outlined,
                              color: AppColors.gold,
                              size: 40.sp,
                            ),
                          ),
                        )
                      else
                        ColoredBox(
                          color: AppColors.surfaceMuted,
                          child: Icon(
                            Icons.emoji_events_outlined,
                            color: AppColors.gold,
                            size: 40.sp,
                          ),
                        ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: EdgeInsets.fromLTRB(12.w, 28.h, 12.w, 10.h),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.72),
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
                                  fontSize: 14.sp,
                                ),
                              ),
                              if (eventName.isNotEmpty) ...[
                                SizedBox(height: 2.h),
                                Text(
                                  eventName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        SizedBox(height: 8.h),
      ],
    );
  }
}
