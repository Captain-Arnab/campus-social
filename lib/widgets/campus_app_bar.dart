import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_theme.dart';
import 'app_bar_title_with_brand_logo.dart';
import 'app_logo_lockup.dart';

/// Shared visual tokens for main-tab / primary accent app bars.
class CampusAppBarTokens {
  CampusAppBarTokens._();

  static const double bottomRadius = 22;
  static const double scrolledUnderElevation = 6;

  static const List<Color> gradientColors = [
    AppColors.accent,
    AppColors.accentDark,
    Color(0xFF2A1F18),
  ];

  static Color get shadowColor => AppColors.navy.withValues(alpha: 0.2);

  static ShapeBorder get shape => const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(bottomRadius)),
      );

  static Decoration gradientDecoration({bool roundedBottom = true}) {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: gradientColors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: [0.0, 0.55, 1.0],
      ),
      borderRadius: roundedBottom
          ? const BorderRadius.vertical(bottom: Radius.circular(bottomRadius))
          : null,
    );
  }

  /// Time-of-day greeting; uses first name when available.
  static String greeting(String displayName) {
    final hour = DateTime.now().hour;
    final period = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final first = displayName.trim().split(RegExp(r'\s+')).first;
    if (first.isEmpty || first.toLowerCase() == 'user') return period;
    return '$period, $first';
  }
}

/// Accent gradient app bar with rounded bottom + elevation when content scrolls under.
class CampusAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final String? titleText;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;
  final bool showBrandLockup;
  final double? leadingWidth;
  final bool centerTitle;

  const CampusAppBar({
    super.key,
    this.title,
    this.titleText,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.bottom,
    this.showBrandLockup = true,
    this.leadingWidth,
    this.centerTitle = false,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    Widget? titleWidget = title;
    if (titleWidget == null && titleText != null) {
      final label = Text(
        titleText!,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: Colors.white,
          fontSize: 17.sp,
        ),
      );
      titleWidget = showBrandLockup
          ? AppBarTitleWithBrandLogo(
              onPrimaryBackground: true,
              logoUnit: 34,
              titleMaxLines: 1,
              title: label,
            )
          : label;
    }

    return AppBar(
      title: titleWidget,
      actions: actions,
      leading: leading,
      leadingWidth: leadingWidth,
      automaticallyImplyLeading: automaticallyImplyLeading,
      centerTitle: centerTitle,
      elevation: 0,
      scrolledUnderElevation: CampusAppBarTokens.scrolledUnderElevation,
      shadowColor: CampusAppBarTokens.shadowColor,
      surfaceTintColor: Colors.transparent,
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
      shape: CampusAppBarTokens.shape,
      flexibleSpace: Container(
        decoration: CampusAppBarTokens.gradientDecoration(),
      ),
      bottom: bottom,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    );
  }
}

/// Pinned [SliverAppBar] matching [CampusAppBar] chrome (Profile / Explore).
class CampusSliverAppBar extends StatelessWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final double? leadingWidth;
  final PreferredSizeWidget? bottom;
  final double? expandedHeight;
  final bool automaticallyImplyLeading;
  final Widget? flexibleSpaceBackground;
  final double toolbarHeight;

  const CampusSliverAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.leadingWidth,
    this.bottom,
    this.expandedHeight,
    this.automaticallyImplyLeading = true,
    this.flexibleSpaceBackground,
    this.toolbarHeight = kToolbarHeight,
  });

  /// Compact leading logo used on Explore / Profile.
  static Widget logoLeading({EdgeInsetsGeometry padding = const EdgeInsets.only(left: 12)}) {
    return Padding(
      padding: padding,
      child: const Align(
        alignment: Alignment.centerLeft,
        child: AppLogoLockup.header(onPrimaryBackground: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      elevation: 0,
      scrolledUnderElevation: CampusAppBarTokens.scrolledUnderElevation,
      shadowColor: CampusAppBarTokens.shadowColor,
      surfaceTintColor: Colors.transparent,
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
      shape: CampusAppBarTokens.shape,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      toolbarHeight: toolbarHeight,
      expandedHeight: expandedHeight,
      leading: leading,
      leadingWidth: leadingWidth,
      automaticallyImplyLeading: automaticallyImplyLeading,
      title: title,
      actions: actions,
      centerTitle: false,
      flexibleSpace: flexibleSpaceBackground ??
          Container(decoration: CampusAppBarTokens.gradientDecoration()),
      bottom: bottom,
    );
  }
}
