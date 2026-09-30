import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../theme/app_theme.dart';
import '../controllers/food_home_controller.dart';

Future<void> showFoodFilterSheet(
  BuildContext context,
  FoodHomeController controller,
) async {
  final draft = controller.filter.value.copy();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          void touch() => setModalState(() {});
          final preview = controller.previewResultCount(draft);
          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.88),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            ),
            child: Column(
              children: [
                SizedBox(height: 10.h),
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
                  child: Row(
                    children: [
                      Text(
                        'Filter & Sort',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sort By', style: _sectionStyle(context)),
                        SizedBox(height: 10.h),
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: [
                            _sortChip('Relevance', FoodSortBy.relevance, draft, touch),
                            _sortChip('Rating', FoodSortBy.rating, draft, touch),
                            _sortChip('Pickup Time', FoodSortBy.pickupTime, draft, touch),
                            _sortChip('Cost: Low–High', FoodSortBy.costLowHigh, draft, touch),
                            _sortChip('Cost: High–Low', FoodSortBy.costHighLow, draft, touch),
                          ],
                        ),
                        SizedBox(height: 20.h),
                        Text('Filter', style: _sectionStyle(context)),
                        SizedBox(height: 10.h),
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: [
                            _filterChip('Veg', draft.veg, (v) {
                              draft.veg = v;
                              if (v) draft.pureVeg = false;
                              touch();
                            }),
                            _filterChip('Non-Veg', draft.nonVeg, (v) {
                              draft.nonVeg = v;
                              if (v) draft.pureVeg = false;
                              touch();
                            }),
                            _filterChip('Pure Veg', draft.pureVeg, (v) {
                              draft.pureVeg = v;
                              if (v) {
                                draft.veg = false;
                                draft.nonVeg = false;
                              }
                              touch();
                            }),
                            _filterChip('Fast Pickup', draft.fastPickup, (v) {
                              draft.fastPickup = v;
                              touch();
                            }),
                            _filterChip('Offers', draft.offers, (v) {
                              draft.offers = v;
                              touch();
                            }),
                            _filterChip('Rating 4.0+', draft.rating4Plus, (v) {
                              draft.rating4Plus = v;
                              touch();
                            }),
                          ],
                        ),
                        SizedBox(height: 20.h),
                        Text(
                          'Price for two (₹${draft.priceMin.round()} – ₹${draft.priceMax.round()})',
                          style: _sectionStyle(context),
                        ),
                        RangeSlider(
                          values: RangeValues(draft.priceMin, draft.priceMax),
                          min: 0,
                          max: 500,
                          divisions: 10,
                          activeColor: AppColors.accent,
                          labels: RangeLabels(
                            '₹${draft.priceMin.round()}',
                            '₹${draft.priceMax.round()}',
                          ),
                          onChanged: (v) {
                            draft.priceMin = v.start;
                            draft.priceMax = v.end;
                            touch();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              draft.clear();
                              controller.applyFilterState(draft);
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.navy,
                              side: const BorderSide(color: AppColors.border),
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.button),
                              ),
                            ),
                            child: const Text('Clear All'),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              controller.applyFilterState(draft);
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                            ),
                            child: Text('Apply ($preview results)'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

TextStyle? _sectionStyle(BuildContext context) =>
    Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700);

Widget _sortChip(
  String label,
  FoodSortBy value,
  FoodFilterState draft,
  VoidCallback touch,
) {
  final selected = draft.sortBy == value;
  return ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: (_) {
      draft.sortBy = value;
      touch();
    },
    selectedColor: AppColors.accent.withValues(alpha: 0.15),
    labelStyle: TextStyle(
      color: selected ? AppColors.accent : AppColors.navy,
      fontWeight: FontWeight.w600,
      fontSize: 12.sp,
    ),
    side: BorderSide(color: selected ? AppColors.accent : AppColors.border),
  );
}

Widget _filterChip(String label, bool selected, ValueChanged<bool> onChanged) {
  return FilterChip(
    label: Text(label),
    selected: selected,
    onSelected: onChanged,
    selectedColor: AppColors.accent.withValues(alpha: 0.15),
    checkmarkColor: AppColors.accent,
    labelStyle: TextStyle(
      color: selected ? AppColors.accent : AppColors.navy,
      fontWeight: FontWeight.w600,
      fontSize: 12.sp,
    ),
    side: BorderSide(color: selected ? AppColors.accent : AppColors.border),
  );
}
