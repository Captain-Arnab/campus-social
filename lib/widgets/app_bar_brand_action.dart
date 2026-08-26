import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_logo_lockup.dart';

/// Compact brand lockup for [SliverAppBar.actions] / [AppBar.actions].
class AppBarBrandLogoAction extends StatelessWidget {
  final bool onPrimaryBackground;

  const AppBarBrandLogoAction({super.key, this.onPrimaryBackground = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(start: 4.w, top: 10, bottom: 10, end: 8.w),
      child: Center(
        child: AppLogoLockup.appBar(onPrimaryBackground: onPrimaryBackground),
      ),
    );
  }
}
