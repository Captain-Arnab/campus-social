import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/event_controller.dart';
import '../data/api_service.dart';
import '../data/event_payment_cache.dart';
import '../data/pref_service.dart';
import '../theme/app_theme.dart';
import '../utils/event_fee_helper.dart';
import '../utils/sweetalert_helper.dart';

/// Confirm step + mock/real checkout for paid attend/participate.
class EventPaymentFlow {
  EventPaymentFlow._();

  /// Returns true when registration is confirmed/paid.
  static Future<bool> start({
    required BuildContext context,
    required Map event,
    required String role, // attend | participate
    String? departmentClass,
    VoidCallback? onSuccess,
  }) async {
    final mode = EventFeeHelper.modeFor(event, role);
    if (mode == 'disabled') {
      SweetAlertHelper.showWarning(
        context,
        'Not Available',
        EventFeeHelper.disabledMessage,
      );
      return false;
    }
    if (mode != 'with_fee') return false;

    final fee = EventFeeHelper.feeAmount(event, role);
    final feeLabel = EventFeeHelper.formatFee(fee);
    final roleLabel = role == 'participate' ? 'Participate' : 'Attend';
    final title = (event['title'] ?? 'Event').toString();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20.w,
            20.h,
            20.w,
            MediaQuery.of(ctx).viewInsets.bottom + 24.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Confirm $roleLabel',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                title,
                style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.currency_rupee, color: AppColors.accent),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'Fee: $feeLabel',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (role == 'participate' &&
                  departmentClass != null &&
                  departmentClass.trim().isNotEmpty) ...[
                SizedBox(height: 10.h),
                Text(
                  'Department / Class: ${departmentClass.trim()}',
                  style: TextStyle(fontSize: 13.sp, color: AppColors.navyMuted),
                ),
              ],
              SizedBox(height: 8.h),
              Text(
                'You can go back and pick a different role before paying.',
                style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Change selection'),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text('Pay $feeLabel'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true || !context.mounted) return false;

    final userId = await PrefService.getUserId();
    if (userId == null || userId.isEmpty) {
      if (context.mounted) {
        SweetAlertHelper.showError(context, 'Error', 'Please log in again.');
      }
      return false;
    }

    // Loading overlay while confirming intent + verifying.
    if (!context.mounted) return false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
    );

    Map<String, dynamic> result = {};
    try {
      result = await ApiService.processEventPayment(
        role: role,
        eventId: event['id'].toString(),
        userId: userId,
        departmentClass: departmentClass,
        runCheckout: (confirmData) async {
          // Dismiss spinner while user interacts with checkout UI.
          if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

          final mock = confirmData['mock_gateway'] == true ||
              confirmData['mock_gateway'] == 1 ||
              confirmData['mock_gateway']?.toString() == '1';

          final pending = confirmData['payment_status']?.toString();
          if (pending != null && pending.isNotEmpty) {
            // Intent pending — do not lock Leave yet (only "paid" locks).
          }

          if (!context.mounted) return null;

          if (mock) {
            final simulate = await _showMockGatewaySheet(
              context,
              orderId: confirmData['order_id']?.toString() ?? '',
              feeLabel: feeLabel,
              roleLabel: roleLabel,
            );
            if (simulate == null) return null;
            // Re-show spinner for verify step.
            if (context.mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
              );
            }
            return {'simulate': simulate};
          }

          // Real Razorpay path placeholder — keys not wired yet.
          SweetAlertHelper.showWarning(
            context,
            'Payment unavailable',
            'Live payment is not configured yet. Please try again later.',
          );
          return null;
        },
      );
    } finally {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).maybePop();
      }
    }

    if (!context.mounted) return false;

    if (result['status']?.toString() == 'cancelled') {
      return false;
    }

    final payStatus = result['payment_status']?.toString();
    // payment_status from verify is applied via mergePaidIntoEvent on success.

    final confirmedReg = result['registration_confirmed'] == true ||
        result['registration_confirmed'] == 1 ||
        result['registration_confirmed']?.toString() == '1' ||
        payStatus?.toLowerCase() == 'paid';

    if (result['status']?.toString() == 'success' && confirmedReg) {
      // Instant lock: merge my_registration into the in-memory event map.
      EventPaymentCache.mergePaidIntoEvent(event, role);
      if (Get.isRegistered<EventController>()) {
        final ec = Get.find<EventController>();
        if (role == 'participate') {
          ec.fetchParticipatingEvents();
          ec.fetchAttendingEvents();
          ec.fetchVolunteeringEvents();
        } else {
          ec.fetchAttendingEvents();
          ec.fetchVolunteeringEvents();
          ec.fetchParticipatingEvents();
        }
      }
      final msg = result['message']?.toString().trim();
      SweetAlertHelper.showSuccess(
        context,
        'Payment successful',
        (msg != null && msg.isNotEmpty)
            ? msg
            : 'Registration confirmed. This paid registration cannot be changed or cancelled.',
      );
      onSuccess?.call();
      return true;
    }

    // Failure — no registration created; offer retry.
    final err = result['message']?.toString().trim();
    final retry = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Payment failed'),
        content: Text(
          (err != null && err.isNotEmpty)
              ? err
              : 'Payment was not completed. No registration was created.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Close'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
    if (retry == true && context.mounted) {
      return start(
        context: context,
        event: event,
        role: role,
        departmentClass: departmentClass,
        onSuccess: onSuccess,
      );
    }
    return false;
  }

  static Future<String?> _showMockGatewaySheet(
    BuildContext context, {
    required String orderId,
    required String feeLabel,
    required String roleLabel,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 28.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber.shade700),
                    ),
                    child: Text(
                      'TEST MODE',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.amber.shade900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                'Simulate Payment',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                '$roleLabel · $feeLabel',
                style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
              ),
              if (orderId.isNotEmpty) ...[
                SizedBox(height: 4.h),
                Text(
                  orderId,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.textSecondary,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
              SizedBox(height: 20.h),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                ),
                onPressed: () => Navigator.pop(ctx, 'success'),
                child: const Text('Simulate Success'),
              ),
              SizedBox(height: 10.h),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade300),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                ),
                onPressed: () => Navigator.pop(ctx, 'failure'),
                child: const Text('Simulate Failure'),
              ),
            ],
          ),
        );
      },
    );
  }
}
