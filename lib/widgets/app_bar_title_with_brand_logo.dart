import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../data/app_branding.dart';

/// App bar title row: default MiCampus mark, optional admin logo from API, then [title].
/// Marks are drawn without a filled chip so they sit directly on the app bar background.
class AppBarTitleWithBrandLogo extends StatelessWidget {
  final Widget title;

  /// Reserved for callers that switch title contrast on orange vs white bars.
  final bool onPrimaryBackground;

  /// Logical logo square (before [.w]) for each mark.
  final double logoUnit;

  const AppBarTitleWithBrandLogo({
    super.key,
    required this.title,
    this.onPrimaryBackground = false,
    this.logoUnit = 46,
  });

  @override
  Widget build(BuildContext context) {
    final s = logoUnit.w;
    final br = BorderRadius.circular(8);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: br,
          child: SizedBox(
            width: s,
            height: s,
            child: AppBranding.defaultLogoBox(
              width: s,
              height: s,
              fit: BoxFit.contain,
              borderRadius: br,
            ),
          ),
        ),
        AppBranding.adminLogoChipSlot(
          width: s,
          height: s,
          leadingGap: 12.w,
          borderRadius: br,
        ),
        SizedBox(width: 12.w),
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
