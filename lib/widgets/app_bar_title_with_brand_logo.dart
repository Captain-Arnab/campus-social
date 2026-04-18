import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../data/app_branding.dart';

/// App bar title row: admin-configured brand logo + [title] (same asset as login/home).
class AppBarTitleWithBrandLogo extends StatelessWidget {
  final Widget title;

  /// Use solid white behind the logo on orange app bars; light grey on white app bars.
  final bool onPrimaryBackground;

  /// Logical logo size before [.w] (toolbar-safe for dense bars).
  final double logoUnit;

  const AppBarTitleWithBrandLogo({
    super.key,
    required this.title,
    this.onPrimaryBackground = false,
    this.logoUnit = 32,
  });

  @override
  Widget build(BuildContext context) {
    final s = logoUnit.w;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Material(
          color: onPrimaryBackground ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.antiAlias,
          child: AppBranding.logoBox(
            width: s,
            height: s,
            fit: BoxFit.contain,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: DefaultTextStyle.merge(
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            child: title,
          ),
        ),
      ],
    );
  }
}
