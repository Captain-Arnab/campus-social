import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/app_network_image.dart';
import '../controllers/cart_controller.dart';
import '../models/restaurant.dart';
import '../widgets/menu_item_card.dart';
import '../widgets/sticky_cart_bar.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final Restaurant restaurant;

  const RestaurantDetailScreen({super.key, required this.restaurant});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  String _menuQuery = '';
  String? _selectedCategory;
  bool _moreInfoOpen = false;

  late final List<String> _categories;

  Restaurant get r => widget.restaurant;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<CartController>()) {
      Get.put(CartController(), permanent: true);
    }
    _categories = r.menu.map((m) => m.category).toSet().toList();
    if (_categories.isNotEmpty) _selectedCategory = _categories.first;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  List get _filteredMenu {
    var list = r.menu.toList();
    if (_menuQuery.isNotEmpty) {
      final q = _menuQuery.toLowerCase();
      list = list
          .where((m) =>
              m.name.toLowerCase().contains(q) ||
              m.description.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  Map<String, List> _grouped(List items) {
    final map = <String, List>{};
    for (final m in items) {
      map.putIfAbsent(m.category, () => []).add(m);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final bannerH = 220.h;
    final overlap = 16.h;
    final filtered = _filteredMenu;
    final grouped = _grouped(filtered);
    final cats = _menuQuery.isEmpty
        ? _categories
        : grouped.keys.toList();

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              controller: _scrollCtrl,
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: bannerH + 120.h,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        SizedBox(
                          height: bannerH,
                          width: double.infinity,
                          child: AppNetworkImage(
                            url: r.imageUrl,
                            fit: BoxFit.cover,
                            cacheWidth: 1000,
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.surfaceMuted,
                              child: const Icon(Icons.restaurant, size: 48),
                            ),
                          ),
                        ),
                        Positioned(
                          top: MediaQuery.paddingOf(context).top + 8,
                          left: 8,
                          child: _CircleIconBtn(
                            icon: Icons.arrow_back_rounded,
                            onTap: () => Get.back(),
                          ),
                        ),
                        Positioned(
                          left: 16.w,
                          right: 16.w,
                          top: bannerH - overlap,
                          child: Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadius.card),
                              boxShadow: AppShadows.cardLifted,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                SizedBox(height: 6.h),
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.w,
                                        vertical: 3.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.success,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.star_rounded,
                                              color: Colors.white, size: 14.sp),
                                          SizedBox(width: 2.w),
                                          Text(
                                            r.rating.toStringAsFixed(1),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12.sp,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      '${r.ratingCount} ratings',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                SizedBox(height: 6.h),
                                Text(
                                  r.cuisineLine,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  '${r.pickupMins} mins · ${r.distanceKm.toStringAsFixed(1)} km · ${r.pickupPointLabel}',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: AppColors.navyMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                InkWell(
                                  onTap: () => setState(() => _moreInfoOpen = !_moreInfoOpen),
                                  child: Row(
                                    children: [
                                      Text(
                                        'More Info',
                                        style: TextStyle(
                                          color: AppColors.accent,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13.sp,
                                        ),
                                      ),
                                      Icon(
                                        _moreInfoOpen
                                            ? Icons.keyboard_arrow_up_rounded
                                            : Icons.keyboard_arrow_down_rounded,
                                        color: AppColors.accent,
                                      ),
                                    ],
                                  ),
                                ),
                                if (_moreInfoOpen) ...[
                                  SizedBox(height: 6.h),
                                  Text(
                                    r.moreInfo,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickySearchHeader(
                    child: Container(
                      color: AppColors.cream,
                      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _menuQuery = v.trim()),
                        decoration: InputDecoration(
                          hintText: 'Search in menu',
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                ),
                if (cats.isNotEmpty)
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickyCategoryHeader(
                      categories: cats,
                      selected: _selectedCategory ?? cats.first,
                      onSelect: (c) => setState(() => _selectedCategory = c),
                    ),
                  ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 100.h),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final entries = grouped.entries.toList();
                        if (entries.isEmpty) {
                          return Padding(
                            padding: EdgeInsets.only(top: 40.h),
                            child: const Center(child: Text('No matching menu items')),
                          );
                        }
                        // Flatten: category headers + items
                        final blocks = <Widget>[];
                        for (final e in entries) {
                          if (_selectedCategory != null &&
                              _menuQuery.isEmpty &&
                              e.key != _selectedCategory) {
                            continue;
                          }
                          blocks.add(
                            Padding(
                              padding: EdgeInsets.only(top: 12.h, bottom: 4.h),
                              child: Text(
                                e.key,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                          );
                          for (final item in e.value) {
                            blocks.add(
                              MenuItemCard(restaurant: r, item: item),
                            );
                          }
                        }
                        if (blocks.isEmpty) {
                          return Padding(
                            padding: EdgeInsets.only(top: 40.h),
                            child: const Center(child: Text('No items in this category')),
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: blocks,
                        );
                      },
                      childCount: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const StickyCartBar(),
        ],
      ),
    );
  }
}

class _CircleIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(10.w),
          child: Icon(icon, color: AppColors.navy, size: 22.sp),
        ),
      ),
    );
  }
}

class _StickySearchHeader extends SliverPersistentHeaderDelegate {
  final Widget child;
  _StickySearchHeader({required this.child});

  @override
  double get minExtent => 64;
  @override
  double get maxExtent => 64;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;

  @override
  bool shouldRebuild(covariant _StickySearchHeader oldDelegate) => true;
}

class _StickyCategoryHeader extends SliverPersistentHeaderDelegate {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelect;

  _StickyCategoryHeader({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  @override
  double get minExtent => 52;
  @override
  double get maxExtent => 52;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.cream,
      alignment: Alignment.centerLeft,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (context, i) {
          final c = categories[i];
          final active = c == selected;
          return ChoiceChip(
            label: Text(c),
            selected: active,
            onSelected: (_) => onSelect(c),
            selectedColor: AppColors.accent.withValues(alpha: 0.15),
            labelStyle: TextStyle(
              color: active ? AppColors.accent : AppColors.navy,
              fontWeight: FontWeight.w600,
              fontSize: 12.sp,
            ),
            side: BorderSide(color: active ? AppColors.accent : AppColors.border),
          );
        },
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyCategoryHeader oldDelegate) =>
      oldDelegate.selected != selected || oldDelegate.categories != categories;
}
