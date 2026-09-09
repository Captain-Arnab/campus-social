import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/app_empty_state.dart';
import '../../../widgets/campus_app_bar.dart';
import '../controllers/orders_controller.dart';
import '../models/order.dart';
import '../models/pickup_point.dart';
import '../widgets/order_status_tracker.dart';

class OrderTrackingScreen extends StatelessWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OrdersController>();
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: const CampusAppBar(
        titleText: 'Track Order',
        showBrandLockup: false,
      ),
      body: Obx(() {
        final order = controller.byId(orderId);
        if (order == null) {
          return const AppEmptyState(
            icon: Icons.search_off_rounded,
            headline: 'Order not found',
          );
        }
        return ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.restaurantName, style: Theme.of(context).textTheme.titleMedium),
                  SizedBox(height: 4.h),
                  Text(
                    '${order.id} · ${DateFormat('dd MMM, hh:mm a').format(order.placedAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (order.status.isActive) ...[
                    SizedBox(height: 8.h),
                    Text(
                      'ETA ~ ${order.etaMins} mins',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.sp,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: OrderStatusTracker(status: order.status),
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.place_rounded, color: AppColors.accent, size: 28.sp),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pickup at ${order.pickupPoint.label}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14.sp,
                            color: AppColors.navy,
                          ),
                        ),
                        Text(
                          order.pickupPoint.subtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order items', style: Theme.of(context).textTheme.titleSmall),
                  SizedBox(height: 8.h),
                  ...order.items.map(
                    (i) => Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: Row(
                        children: [
                          Text(
                            '${i.quantity}×',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                              fontSize: 13.sp,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(child: Text(i.menuItem.name)),
                          Text('₹${i.lineTotal.toStringAsFixed(0)}'),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 24),
                  _row('Item Total', '₹${order.itemTotal.toStringAsFixed(2)}'),
                  _row('Taxes', '₹${order.taxes.toStringAsFixed(2)}'),
                  _row('Platform Fee', '₹${order.platformFee.toStringAsFixed(2)}'),
                  const Divider(height: 20),
                  _row('Grand Total', '₹${order.grandTotal.toStringAsFixed(2)}', bold: true),
                ],
              ),
            ),
            if (order.status.isActive) ...[
              SizedBox(height: 16.h),
              OutlinedButton.icon(
                onPressed: () => controller.advanceStatus(order.id),
                icon: const Icon(Icons.fast_forward_rounded),
                label: const Text('Simulate next stage (demo)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navyMuted,
                  side: const BorderSide(color: AppColors.border),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
              ),
            ],
            SizedBox(height: 24.h),
          ],
        );
      }),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              fontSize: bold ? 14.sp : 13.sp,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              fontSize: bold ? 14.sp : 13.sp,
            ),
          ),
        ],
      ),
    );
  }
}
