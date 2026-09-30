import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/app_empty_state.dart';
import '../../../widgets/app_network_image.dart';
import '../../../widgets/campus_app_bar.dart';
import '../controllers/orders_controller.dart';
import '../models/order.dart';
import '../models/pickup_point.dart';
import 'cart_screen.dart';
import 'order_tracking_screen.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<OrdersController>()
        ? Get.find<OrdersController>()
        : Get.put(OrdersController(), permanent: true);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: CampusAppBar(
          titleText: 'My Orders',
          showBrandLockup: false,
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.sp),
            tabs: const [
              Tab(text: 'Active'),
              Tab(text: 'Past'),
            ],
          ),
        ),
        body: Obx(() {
          return TabBarView(
            children: [
              _OrderList(
                orders: controller.activeOrders,
                emptyHeadline: 'No active orders',
                emptySupporting: 'Place an order from Food to track it here.',
                isActive: true,
              ),
              _OrderList(
                orders: controller.pastOrders,
                emptyHeadline: 'No past orders',
                emptySupporting: 'Completed orders will show up here.',
                isActive: false,
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final List<FoodOrder> orders;
  final String emptyHeadline;
  final String emptySupporting;
  final bool isActive;

  const _OrderList({
    required this.orders,
    required this.emptyHeadline,
    required this.emptySupporting,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return AppEmptyState(
        icon: Icons.receipt_long_outlined,
        headline: emptyHeadline,
        supporting: emptySupporting,
      );
    }
    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: orders.length,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (context, i) {
        final o = orders[i];
        return Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: AppNetworkImage(
                      url: o.restaurantImageUrl,
                      width: 52.w,
                      height: 52.w,
                      fit: BoxFit.cover,
                      cacheWidth: 140,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          o.restaurantName,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        Text(
                          o.id,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (isActive)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        o.status.label,
                        style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.sp,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 10.h),
              Text(
                '${o.itemCount} item${o.itemCount == 1 ? '' : 's'} · ₹${o.grandTotal.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 13.sp, color: AppColors.navyMuted),
              ),
              if (isActive) ...[
                SizedBox(height: 4.h),
                Text(
                  'ETA ~ ${o.etaMins} mins · ${o.pickupPoint.label}',
                  style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
                ),
                SizedBox(height: 12.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Get.to(
                      () => OrderTrackingScreen(orderId: o.id),
                      transition: Transition.rightToLeft,
                    ),
                    child: const Text('Track Order'),
                  ),
                ),
              ] else ...[
                SizedBox(height: 4.h),
                Text(
                  DateFormat('dd MMM yyyy, hh:mm a').format(o.placedAt),
                  style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
                ),
                SizedBox(height: 12.h),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Get.find<OrdersController>().reorder(o);
                      Get.to(() => const CartScreen(), transition: Transition.rightToLeft);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: const BorderSide(color: AppColors.accent),
                    ),
                    child: const Text('Reorder'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
