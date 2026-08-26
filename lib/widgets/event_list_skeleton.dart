import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_theme.dart';
import 'ticket_perforation.dart';

/// Shimmer-free skeleton placeholders for event list loading.
class EventListSkeleton extends StatelessWidget {
  final int count;
  final bool horizontal;

  const EventListSkeleton({super.key, this.count = 3, this.horizontal = true});

  @override
  Widget build(BuildContext context) {
    if (horizontal) {
      return SizedBox(
        height: 320.h,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
          itemCount: count,
          separatorBuilder: (_, __) => SizedBox(width: AppSpacing.md.w),
          itemBuilder: (_, __) => const _SkeletonTicketCard(width: 260),
        ),
      );
    }
    return Column(
      children: List.generate(
        count,
        (i) => Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
          child: const _SkeletonTicketCard(),
        ),
      ),
    );
  }
}

class _SkeletonTicketCard extends StatefulWidget {
  final double? width;

  const _SkeletonTicketCard({this.width});

  @override
  State<_SkeletonTicketCard> createState() => _SkeletonTicketCardState();
}

class _SkeletonTicketCardState extends State<_SkeletonTicketCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = 0.35 + _pulse.value * 0.25;
        return Opacity(opacity: t.clamp(0.35, 0.65), child: child);
      },
      child: Container(
        width: widget.width,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 140.h,
              decoration: const BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.card),
                ),
              ),
            ),
            const TicketPerforation(),
            Padding(
              padding: EdgeInsets.all(AppSpacing.md.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs.h),
                  Container(
                    height: 12.h,
                    width: 120.w,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
