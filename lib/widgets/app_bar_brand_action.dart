import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../data/app_branding.dart';

/// Compact brand logo for [SliverAppBar.actions] / [AppBar.actions] (read-only chip).
class AppBarBrandLogoAction extends StatelessWidget {
  const AppBarBrandLogoAction({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(start: 4.w, top: 10, bottom: 10),
      child: Center(
        child: Material(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.antiAlias,
          child: AppBranding.logoBox(
            width: 34.w,
            height: 34.w,
            fit: BoxFit.contain,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
