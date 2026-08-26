import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_theme.dart';

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String headline;
  final String? supporting;
  final Color? accentColor;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.headline,
    this.supporting,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.accent;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w, vertical: AppSpacing.md.h),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(22.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, size: 44.sp, color: color),
          ),
          SizedBox(height: AppSpacing.md.h),
          Text(
            headline,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          if (supporting != null && supporting!.isNotEmpty) ...[
            SizedBox(height: AppSpacing.xs.h),
            Text(
              supporting!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
