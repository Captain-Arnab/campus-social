import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/app_network_image.dart';
import '../../../widgets/pressable_scale.dart';
import '../models/restaurant.dart';

class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onTap;

  const RestaurantCard({
    super.key,
    required this.restaurant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppShadows.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: AppNetworkImage(
                    url: restaurant.imageUrl,
                    fit: BoxFit.cover,
                    cacheWidth: 800,
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.surfaceMuted,
                      child: Icon(Icons.restaurant, color: AppColors.textSecondary, size: 40.sp),
                    ),
                  ),
                ),
                Positioned(
                  left: 12.w,
                  bottom: 12.h,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.navy.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, color: AppColors.gold, size: 14.sp),
                        SizedBox(width: 4.w),
                        Text(
                          restaurant.rating.toStringAsFixed(1),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.sp,
                          ),
                        ),
                        Text(
                          ' (${restaurant.ratingCount})',
                          style: TextStyle(color: Colors.white70, fontSize: 10.sp),
                        ),
                      ],
                    ),
                  ),
                ),
                if (restaurant.hasOffer && restaurant.offerText != null)
                  Positioned(
                    top: 12.h,
                    left: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.horizontal(right: Radius.circular(8)),
                      ),
                      child: Text(
                        restaurant.offerText!,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                if (restaurant.isVegOnly)
                  Positioned(
                    top: 12.h,
                    right: 12.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.eco, color: AppColors.success, size: 14.sp),
                          SizedBox(width: 2.w),
                          Text(
                            'Pure Veg',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 14.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    restaurant.cuisineLine,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 14.sp, color: AppColors.textSecondary),
                      SizedBox(width: 4.w),
                      Text(
                        '${restaurant.pickupMins} mins',
                        style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
                      ),
                      _dot(),
                      Icon(Icons.near_me_outlined, size: 14.sp, color: AppColors.textSecondary),
                      SizedBox(width: 4.w),
                      Text(
                        '${restaurant.distanceKm.toStringAsFixed(1)} km',
                        style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
                      ),
                      _dot(),
                      Icon(Icons.place_outlined, size: 14.sp, color: AppColors.accent),
                      SizedBox(width: 2.w),
                      Flexible(
                        child: Text(
                          restaurant.pickupPointLabel,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '₹${restaurant.costForTwo} for two',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.navyMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot() => Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.w),
        child: Text('•', style: TextStyle(color: AppColors.border, fontSize: 12.sp)),
      );
}
