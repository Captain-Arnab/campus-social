import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../data/app_bootstrap.dart';
import '../theme/app_theme.dart';
import 'animated_favorite_button.dart';
import 'event_poster_image.dart';
import 'pressable_scale.dart';
import 'ticket_perforation.dart';

/// Campus event ticket-stub card — wraps to content height (no reserved blank footer).
class TicketEventCard extends StatelessWidget {
  final dynamic event;
  final VoidCallback onTap;
  final double? width;
  final double posterHeight;
  final bool showFavorite;
  final bool showRegistrationOpenTag;
  final bool compact;

  /// When true (My Activity grid), fill parent height.
  final bool expandToFit;
  final Widget? footer;
  final String Function(dynamic, dynamic)? dateLineBuilder;
  final String Function(dynamic)? venueLineBuilder;
  final int? posterCacheWidth;

  const TicketEventCard({
    super.key,
    required this.event,
    required this.onTap,
    this.width,
    this.posterHeight = 140,
    this.showFavorite = true,
    this.showRegistrationOpenTag = false,
    this.compact = false,
    this.expandToFit = false,
    this.footer,
    this.dateLineBuilder,
    this.venueLineBuilder,
    this.posterCacheWidth,
  });

  String get _category =>
      event is Map ? (event as Map)['category']?.toString() ?? 'Event' : 'Event';

  String get _title =>
      event is Map
          ? (event as Map)['title']?.toString() ?? 'Untitled Event'
          : 'Untitled Event';

  @override
  Widget build(BuildContext context) {
    final categoryColor = AppColors.categoryColor(_category);
    final textTheme = Theme.of(context).textTheme;

    final details = Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? AppSpacing.sm.w : AppSpacing.md.w,
        compact ? 8.h : 12.h,
        compact ? AppSpacing.sm.w : AppSpacing.md.w,
        compact ? 10.h : 14.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _title,
            style: (compact ? textTheme.titleSmall : textTheme.titleMedium)
                ?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.22,
              color: AppColors.navy,
              fontSize: compact ? 13.sp : 16.sp,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
          ),
          SizedBox(height: compact ? 6.h : 8.h),
          _MetaRow(
            icon: Icons.calendar_today_rounded,
            text: dateLineBuilder != null
                ? dateLineBuilder!(event['event_date'], event['event_end_date'])
                : (event is Map
                    ? event['event_date']?.toString() ?? 'Date TBD'
                    : 'Date TBD'),
            compact: compact,
          ),
          SizedBox(height: compact ? 3.h : 4.h),
          _MetaRow(
            icon: Icons.location_on_rounded,
            text: venueLineBuilder != null
                ? venueLineBuilder!(event is Map ? event['venue'] : null)
                : (event is Map
                    ? event['venue']?.toString() ?? 'Venue TBD'
                    : 'Venue TBD'),
            compact: compact,
            maxLines: compact ? 1 : 2,
          ),
          if (footer != null) ...[
            SizedBox(height: compact ? 8.h : 10.h),
            footer!,
          ],
        ],
      ),
    );

    final posterStack = Stack(
      fit: StackFit.expand,
      children: [
        EventPosterImage(
          event: event,
          cacheWidth: posterCacheWidth,
        ),
        // Top scrim — category + favorite legibility.
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: 64.h,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66000000),
                  Color(0x00000000),
                ],
              ),
            ),
          ),
        ),
        // Bottom scrim — soft transition into content / perforation.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 40.h,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Color(0x33000000),
                  Color(0x00000000),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: AppSpacing.sm.w,
          top: AppSpacing.sm.h,
          right: showFavorite ? 48.w : AppSpacing.sm.w,
          child: Wrap(
            spacing: 6.w,
            runSpacing: 4.h,
            children: [
              _CategoryChip(label: _category, color: categoryColor),
              if (showRegistrationOpenTag)
                const _CategoryChip(
                  label: 'Registration open',
                  color: AppColors.success,
                ),
            ],
          ),
        ),
        if (showFavorite)
          Positioned(
            top: 4.h,
            right: 4.w,
            child: _FavoriteToggle(event: event),
          ),
      ],
    );

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: expandToFit ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (expandToFit)
          Expanded(flex: 5, child: posterStack)
        else
          SizedBox(height: posterHeight.h, child: posterStack),
        const TicketPerforation(),
        if (expandToFit)
          Flexible(
            flex: 4,
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: details,
            ),
          )
        else
          details,
      ],
    );

    return PressableScale(
      onTap: onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppShadows.cardLifted,
        ),
        clipBehavior: Clip.antiAlias,
        child: column,
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final Color color;

  const _CategoryChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 10.sp,
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool compact;
  final int maxLines;

  const _MetaRow({
    required this.icon,
    required this.text,
    this.compact = false,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 1.h),
          child: Icon(
            icon,
            size: compact ? 12 : 14,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: compact ? 10.sp : 12.sp,
              color: AppColors.textSecondary,
              height: 1.3,
              fontWeight: FontWeight.w400,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
          ),
        ),
      ],
    );
  }
}

class _FavoriteToggle extends StatelessWidget {
  final dynamic event;

  const _FavoriteToggle({required this.event});

  @override
  Widget build(BuildContext context) {
    final controller = AppBootstrap.ensureEventController();
    final eid = event is Map ? event['id']?.toString() ?? '' : '';
    return Obx(() {
      final isFav = controller.favoriteList.any(
        (e) => e is Map && e['id']?.toString() == eid,
      );
      return AnimatedFavoriteButton(
        isFavorite: isFav,
        onToggle: () => controller.toggleFavorite(eid),
      );
    });
  }
}
