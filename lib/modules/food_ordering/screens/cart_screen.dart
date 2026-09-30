import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/app_empty_state.dart';
import '../../../widgets/app_network_image.dart';
import '../../../widgets/campus_app_bar.dart';
import '../controllers/cart_controller.dart';
import '../models/pickup_point.dart';
import 'order_tracking_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Get.find<CartController>();
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: const CampusAppBar(
        titleText: 'Cart',
        showBrandLockup: false,
      ),
      body: Obx(() {
        if (cart.isEmpty) {
          return const AppEmptyState(
            icon: Icons.shopping_bag_outlined,
            headline: 'Your cart is empty',
            supporting: 'Add items from a restaurant to continue.',
          );
        }
        final r = cart.restaurant.value!;
        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      boxShadow: AppShadows.card,
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: AppNetworkImage(
                            url: r.imageUrl,
                            width: 56.w,
                            height: 56.w,
                            fit: BoxFit.cover,
                            cacheWidth: 160,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                r.pickupPointLabel,
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
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: Column(
                      children: cart.items.map((item) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.menuItem.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                    Text(
                                      '₹${item.menuItem.price.toStringAsFixed(0)}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              _Stepper(
                                qty: item.quantity,
                                onMinus: () => cart.decrement(item.menuItem.id),
                                onPlus: () => cart.increment(item.menuItem.id),
                              ),
                              SizedBox(width: 12.w),
                              SizedBox(
                                width: 56.w,
                                child: Text(
                                  '₹${item.lineTotal.toStringAsFixed(0)}',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text('Pickup point', style: Theme.of(context).textTheme.titleSmall),
                  SizedBox(height: 8.h),
                  ...PickupPoint.values.map((p) {
                    final selected = cart.pickupPoint.value == p;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Material(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => cart.setPickupPoint(p),
                          child: Container(
                            padding: EdgeInsets.all(14.w),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected ? AppColors.accent : AppColors.border,
                                width: selected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  selected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  color: selected ? AppColors.accent : AppColors.textSecondary,
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.label,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14.sp,
                                        ),
                                      ),
                                      Text(
                                        p.subtitle,
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: Column(
                      children: [
                        _billRow('Item Total', '₹${cart.itemTotal.toStringAsFixed(2)}'),
                        _billRow('Taxes (5%)', '₹${cart.taxes.toStringAsFixed(2)}'),
                        _billRow('Platform Fee', '₹${CartController.platformFee.toStringAsFixed(2)}'),
                        const Divider(height: 20),
                        _billRow(
                          'Grand Total',
                          '₹${cart.grandTotal.toStringAsFixed(2)}',
                          bold: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final order = cart.placeOrder();
                      Get.off(() => OrderTrackingScreen(orderId: order.id));
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                    ),
                    child: Text(
                      'Proceed to Pay · ₹${cart.grandTotal.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _billRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              fontSize: bold ? 15.sp : 13.sp,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              fontSize: bold ? 15.sp : 13.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final int qty;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _Stepper({
    required this.qty,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.accent),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onMinus,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
              child: Icon(Icons.remove, size: 16.sp, color: AppColors.accent),
            ),
          ),
          Text(
            '$qty',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.accent,
              fontSize: 13.sp,
            ),
          ),
          InkWell(
            onTap: onPlus,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
              child: Icon(Icons.add, size: 16.sp, color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}
