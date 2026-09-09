import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../data/pref_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/campus_app_bar.dart';
import '../controllers/cart_controller.dart';
import '../models/pickup_point.dart';

class PickupPreferenceScreen extends StatefulWidget {
  const PickupPreferenceScreen({super.key});

  @override
  State<PickupPreferenceScreen> createState() => _PickupPreferenceScreenState();
}

class _PickupPreferenceScreenState extends State<PickupPreferenceScreen> {
  PickupPoint _selected = PickupPoint.mainGate;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final key = await PrefService.getFoodPickupPoint();
    if (!mounted) return;
    setState(() {
      _selected = PickupPointX.fromStorage(key);
      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await PrefService.setFoodPickupPoint(_selected.storageKey);
    if (Get.isRegistered<CartController>()) {
      await Get.find<CartController>().setPickupPoint(_selected);
    }
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pickup preference saved: ${_selected.label}'),
        backgroundColor: AppColors.navy,
      ),
    );
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: const CampusAppBar(
        titleText: 'Pickup Preference',
        showBrandLockup: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Where should we hand over your campus food orders?',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  SizedBox(height: 16.h),
                  ...PickupPoint.values.map((p) {
                    final selected = _selected == p;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: Material(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          onTap: () => setState(() => _selected = p),
                          child: Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppRadius.card),
                              border: Border.all(
                                color: selected ? AppColors.accent : AppColors.border,
                                width: selected ? 1.8 : 1,
                              ),
                              boxShadow: selected ? AppShadows.card : null,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44.w,
                                  height: 44.w,
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    p == PickupPoint.mainGate
                                        ? Icons.apartment_rounded
                                        : Icons.home_work_outlined,
                                    color: AppColors.accent,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.label,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15.sp,
                                        ),
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        p.subtitle,
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  selected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  color: selected ? AppColors.accent : AppColors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                      ),
                      child: _saving
                          ? SizedBox(
                              width: 22.w,
                              height: 22.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save Preference'),
                    ),
                  ),
                  SizedBox(height: 12.h),
                ],
              ),
            ),
    );
  }
}
