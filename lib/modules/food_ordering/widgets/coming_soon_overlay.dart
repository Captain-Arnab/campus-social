import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../theme/app_theme.dart';

/// Fades and locks [child] behind a centered "Coming Soon" card.
class FoodComingSoonOverlay extends StatelessWidget {
  final Widget child;

  const FoodComingSoonOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          child: ExcludeSemantics(
            child: Opacity(opacity: 0.3, child: child),
          ),
        ),
        Container(color: AppColors.cream.withValues(alpha: 0.35)),
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navy.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.restaurant_menu_rounded,
                      color: AppColors.accent,
                      size: 32.sp,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  const ComingSoonBadge(large: true),
                  SizedBox(height: 12.h),
                  Text(
                    'Food Ordering',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Order from campus canteens and pick up at your gate. '
                    'This feature is on its way!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.sp,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Small accent pill reading "Coming Soon".
class ComingSoonBadge extends StatelessWidget {
  final bool large;

  const ComingSoonBadge({super.key, this.large = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 12.w : 5.w,
        vertical: large ? 4.h : 1.h,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.accent, AppColors.accentDark],
        ),
        borderRadius: BorderRadius.circular(20),
        border: large ? null : Border.all(color: AppColors.surface, width: 1.2),
      ),
      child: Text(
        large ? 'COMING SOON' : 'Coming soon',
        maxLines: 1,
        softWrap: false,
        style: TextStyle(
          color: Colors.white,
          fontSize: large ? 11.sp : 7.sp,
          fontWeight: FontWeight.w800,
          letterSpacing: large ? 1.2 : 0.2,
        ),
      ),
    );
  }
}
