import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../data/app_branding.dart';

/// Compact brand logos for [SliverAppBar.actions] / [AppBar.actions] (no chip fill).
class AppBarBrandLogoAction extends StatelessWidget {
  const AppBarBrandLogoAction({super.key});

  @override
  Widget build(BuildContext context) {
    final s = 40.w;
    final br = BorderRadius.circular(8);
    return Padding(
      padding: EdgeInsetsDirectional.only(start: 4.w, top: 10, bottom: 10),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
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
              leadingGap: 10.w,
              borderRadius: br,
            ),
          ],
        ),
      ),
    );
  }
}
