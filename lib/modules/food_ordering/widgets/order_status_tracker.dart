import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../theme/app_theme.dart';
import '../models/order.dart';

class OrderStatusTracker extends StatelessWidget {
  final OrderStatus status;

  const OrderStatusTracker({super.key, required this.status});

  static const _stages = [
    OrderStatus.placed,
    OrderStatus.accepted,
    OrderStatus.preparing,
    OrderStatus.readyForPickup,
    OrderStatus.pickedUp,
  ];

  @override
  Widget build(BuildContext context) {
    final current = status.stageIndex;
    return Column(
      children: List.generate(_stages.length, (i) {
        final stage = _stages[i];
        final done = i <= current;
        final isCurrent = i == current;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 28.w,
                  height: 28.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? AppColors.accent : AppColors.surfaceMuted,
                    border: Border.all(
                      color: done ? AppColors.accent : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    done ? Icons.check_rounded : Icons.circle,
                    size: done ? 16.sp : 8.sp,
                    color: done ? Colors.white : AppColors.border,
                  ),
                ),
                if (i < _stages.length - 1)
                  Container(
                    width: 2,
                    height: 28.h,
                    color: i < current ? AppColors.accent : AppColors.border,
                  ),
              ],
            ),
            SizedBox(width: 12.w),
            Padding(
              padding: EdgeInsets.only(top: 4.h, bottom: 16.h),
              child: Text(
                stage.label,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                  color: done ? AppColors.navy : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
