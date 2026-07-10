import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../data/app_branding.dart';

/// Compact brand logos for [SliverAppBar.actions] / [AppBar.actions] (no chip fill).
class AppBarBrandLogoAction extends StatelessWidget {
  const AppBarBrandLogoAction({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(start: 4.w, top: 10, bottom: 10),
      child: Center(
        child: AppBranding.compactDualLogos(size: 52, gap: 10),
      ),
    );
  }
}
