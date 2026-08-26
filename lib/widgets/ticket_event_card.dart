import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../data/app_bootstrap.dart';
import '../theme/app_theme.dart';
import 'animated_favorite_button.dart';
import 'event_poster_image.dart';
import 'pressable_scale.dart';

/// Full-bleed event preview card: poster fills the card; title/meta overlay the
/// bottom gradient. Tap opens event detail — no action buttons on the card.
class TicketEventCard extends StatelessWidget {
  final dynamic event;
  final VoidCallback onTap;
  final double? width;

  /// Used when [expandToFit] is false (Featured / Upcoming).
  final double posterHeight;
  final bool showFavorite;
  final bool showRegistrationOpenTag;
  final bool compact;

  /// When true (My Activity grid), fill the parent cell.
  final bool expandToFit;

  final String Function(dynamic, dynamic)? dateLineBuilder;
  final String Function(dynamic)? venueLineBuilder;
  final int? posterCacheWidth;

  const TicketEventCard({
    super.key,
    required this.event,
    required this.onTap,
    this.width,
    this.posterHeight = 280,
    this.showFavorite = true,
    this.showRegistrationOpenTag = false,
    this.compact = false,
    this.expandToFit = false,
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

  String get _dateText {
    if (dateLineBuilder != null) {
      return dateLineBuilder!(
        event is Map ? event['event_date'] : null,
        event is Map ? event['event_end_date'] : null,
      );
    }
    return event is Map
        ? event['event_date']?.toString() ?? 'Date TBD'
        : 'Date TBD';
  }

  String get _venueText {
    if (venueLineBuilder != null) {
      return venueLineBuilder!(event is Map ? event['venue'] : null);
    }
    return event is Map
        ? event['venue']?.toString() ?? 'Venue TBD'
        : 'Venue TBD';
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = AppColors.categoryColor(_category);
    final h = compact ? 220.0 : posterHeight;

    final card = Container(
      width: width,
      height: expandToFit ? null : h.h,
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.cardLifted,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          EventPosterImage(
            event: event,
            cacheWidth: posterCacheWidth,
          ),
          // Light top scrim for category / favorite.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 72.h,
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
          // Bottom ~half scrim: transparent → ~75% black for overlay text.
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x00000000),
                      Color(0x00000000),
                      Color(0x99000000),
                      Color(0xBF000000),
                    ],
                    stops: [0.0, 0.42, 0.72, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // Category + registration (top-left).
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
          // Title + meta overlay (bottom).
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 10.w : 14.w,
                0,
                compact ? 10.w : 14.w,
                compact ? 12.h : 14.h,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: compact ? 13.sp : 16.sp,
                      height: 1.2,
                      shadows: const [
                        Shadow(
                          color: Color(0x66000000),
                          blurRadius: 6,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                  SizedBox(height: compact ? 5.h : 7.h),
                  _OverlayMetaRow(
                    icon: Icons.calendar_today_rounded,
                    text: _dateText,
                    compact: compact,
                  ),
                  SizedBox(height: compact ? 3.h : 4.h),
                  _OverlayMetaRow(
                    icon: Icons.location_on_rounded,
                    text: _venueText,
                    compact: compact,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return PressableScale(
      onTap: onTap,
      child: expandToFit ? SizedBox.expand(child: card) : card,
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
            color: Colors.black.withValues(alpha: 0.25),
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

class _OverlayMetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool compact;
  final int maxLines;

  const _OverlayMetaRow({
    required this.icon,
    required this.text,
    this.compact = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: compact ? 11 : 13,
          color: Colors.white.withValues(alpha: 0.82),
        ),
        SizedBox(width: 5.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: compact ? 10.sp : 12.sp,
              color: Colors.white.withValues(alpha: 0.88),
              fontWeight: FontWeight.w400,
              height: 1.25,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
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
