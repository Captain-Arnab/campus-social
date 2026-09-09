import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/app_empty_state.dart';
import '../../../widgets/app_network_image.dart';
import '../../../widgets/campus_app_bar.dart';
import '../controllers/cart_controller.dart';
import '../controllers/food_home_controller.dart';
import '../controllers/orders_controller.dart';
import '../data/dummy_data.dart';
import '../models/restaurant.dart';
import '../widgets/promo_banner.dart';
import '../widgets/restaurant_card.dart';
import '../widgets/sticky_cart_bar.dart';
import 'filter_sheet.dart';
import 'orders_screen.dart';
import 'restaurant_detail_screen.dart';

class FoodHomeScreen extends StatefulWidget {
  const FoodHomeScreen({super.key});

  @override
  State<FoodHomeScreen> createState() => _FoodHomeScreenState();
}

class _FoodHomeScreenState extends State<FoodHomeScreen>
    with AutomaticKeepAliveClientMixin {
  late final FoodHomeController controller;
  final _searchCtrl = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<FoodHomeController>()
        ? Get.find<FoodHomeController>()
        : Get.put(FoodHomeController());
    if (!Get.isRegistered<CartController>()) {
      Get.put(CartController(), permanent: true);
    }
    if (!Get.isRegistered<OrdersController>()) {
      Get.put(OrdersController(), permanent: true);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                CampusSliverAppBar(
                  automaticallyImplyLeading: false,
                  leadingWidth: 200,
                  leading: CampusSliverAppBar.logoLeading(),
                  actions: [
                    IconButton(
                      tooltip: 'My Orders',
                      icon: const Icon(Icons.receipt_long_rounded, color: Colors.white),
                      onPressed: () => Get.to(
                        () => const OrdersScreen(),
                        transition: Transition.rightToLeft,
                      ),
                    ),
                  ],
                  bottom: PreferredSize(
                    preferredSize: Size.fromHeight(72.h),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_rounded, color: Colors.white, size: 22.sp),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Main Campus',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15.sp,
                                  ),
                                ),
                                Text(
                                  'Order food on campus',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: controller.setSearch,
                            decoration: InputDecoration(
                              hintText: 'Search restaurants or cuisines',
                              hintStyle: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13.sp,
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: AppColors.textSecondary,
                              ),
                              filled: true,
                              fillColor: AppColors.surface,
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 0, horizontal: 12.w),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.card),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Obx(() {
                          final active = controller.filter.value.hasActiveFilters;
                          return Material(
                            color: active ? AppColors.accent : AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              onTap: () => showFoodFilterSheet(context, controller),
                              borderRadius: BorderRadius.circular(14),
                              child: SizedBox(
                                width: 48.w,
                                height: 48.w,
                                child: Icon(
                                  Icons.tune_rounded,
                                  color: active ? Colors.white : AppColors.navy,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                Obx(() {
                  final selected = controller.selectedCuisine.value;
                  return SliverToBoxAdapter(
                    child: SizedBox(
                      height: 108.h,
                      child: ListView.separated(
                        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                        scrollDirection: Axis.horizontal,
                        itemCount: FoodDummyData.categories.length,
                        separatorBuilder: (_, __) => SizedBox(width: 12.w),
                        itemBuilder: (context, i) {
                          final cat = FoodDummyData.categories[i];
                          final isSelected = selected == cat.id;
                          return GestureDetector(
                            onTap: () => controller.setCuisine(cat.id),
                            child: SizedBox(
                              width: 72.w,
                              child: Column(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    width: 58.w,
                                    height: 58.w,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color:
                                            isSelected ? AppColors.accent : AppColors.border,
                                        width: isSelected ? 2.5 : 1,
                                      ),
                                      boxShadow: isSelected ? AppShadows.card : null,
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: AppNetworkImage(
                                      url: cat.imageUrl,
                                      fit: BoxFit.cover,
                                      cacheWidth: 160,
                                      errorWidget: (_, __, ___) => Container(
                                        color: AppColors.surfaceMuted,
                                        child: Icon(Icons.restaurant, size: 22.sp),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 6.h),
                                  Text(
                                    cat.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      fontWeight:
                                          isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected
                                          ? AppColors.accent
                                          : AppColors.navyMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: PromoBannerCarousel(banners: FoodDummyData.promos),
                  ),
                ),
                Obx(() {
                  final List<Restaurant> list = controller.restaurants.toList();
                  if (list.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: AppEmptyState(
                        icon: Icons.restaurant_outlined,
                        headline: 'No restaurants found',
                        supporting: 'Try another cuisine or clear filters.',
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 100.h),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final r = list[index];
                          return RestaurantCard(
                            restaurant: r,
                            onTap: () => Get.to(
                              () => RestaurantDetailScreen(restaurant: r),
                              transition: Transition.rightToLeft,
                            ),
                          );
                        },
                        childCount: list.length,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const StickyCartBar(),
        ],
      ),
    );
  }
}
