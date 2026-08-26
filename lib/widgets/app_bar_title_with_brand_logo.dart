import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_logo_lockup.dart';

/// App bar title row: [AppLogoLockup] then [title].
class AppBarTitleWithBrandLogo extends StatelessWidget {
  final Widget title;

  /// When true, lockup uses light divider colors for orange bars.
  final bool onPrimaryBackground;

  /// Logical logo height (passed through to [AppLogoLockup]).
  final double logoUnit;

  /// Max lines for the title area (use 1 to avoid awkward wraps, e.g. "Notifications").
  final int titleMaxLines;

  const AppBarTitleWithBrandLogo({
    super.key,
    required this.title,
    this.onPrimaryBackground = false,
    this.logoUnit = 34,
    this.titleMaxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppLogoLockup(
          size: logoUnit.clamp(28, 40),
          gap: 10,
          onPrimaryBackground: onPrimaryBackground,
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: DefaultTextStyle.merge(
            overflow: TextOverflow.ellipsis,
            maxLines: titleMaxLines,
            child: title,
          ),
        ),
      ],
    );
  }
}
