import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../theme/app_theme.dart';
import '../controllers/cart_controller.dart';
import '../screens/cart_screen.dart';

class StickyCartBar extends StatelessWidget {
  const StickyCartBar({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Get.find<CartController>();
    return Obx(() {
      if (cart.isEmpty) return const SizedBox.shrink();
      return SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
          child: Material(
            elevation: 8,
            shadowColor: AppColors.navy.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(14),
            color: AppColors.navy,
            child: InkWell(
              onTap: () => Get.to(() => const CartScreen(), transition: Transition.rightToLeft),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${cart.totalQty} ITEM${cart.totalQty == 1 ? '' : 'S'}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      '₹${cart.itemTotal.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15.sp,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'View Cart',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14.sp),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
