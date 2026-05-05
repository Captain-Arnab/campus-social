import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../controllers/inbox_notification_controller.dart';
import '../modal/model_inbox_notification.dart';
import 'event_detail_view.dart';
import '../data/api_service.dart';
import '../widgets/app_bar_title_with_brand_logo.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<InboxNotificationController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchNotifications();
    });

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: AppBarTitleWithBrandLogo(
          onPrimaryBackground: true,
          logoUnit: 44,
          titleMaxLines: 1,
          title: Text(
            'Notifications',
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 17.sp),
          ),
        ),
        backgroundColor: const Color(0xFFFF5F15),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          Obx(() {
            if (controller.unreadCount.value == 0) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.done_all, color: Colors.white),
              tooltip: "Mark all as read",
              onPressed: () => controller.markAllAsRead(),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.notifications.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF5F15)),
          );
        }

        if (controller.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(40.w),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.notifications_off_outlined,
                      size: 80.w, color: Colors.grey[400]),
                ),
                SizedBox(height: 24.h),
                Text(
                  "No notifications yet",
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  "Notifications from the last 24 hours\nwill appear here",
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32.h),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5F15),
                    foregroundColor: Colors.white,
                    padding:
                        EdgeInsets.symmetric(horizontal: 32.w, vertical: 14.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    "Go Back",
                    style:
                        TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchNotifications(),
          color: const Color(0xFFFF5F15),
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            itemCount: controller.notifications.length,
            itemBuilder: (context, index) {
              final notification = controller.notifications[index];
              return _NotificationTile(
                notification: notification,
                controller: controller,
              );
            },
          ),
        );
      }),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final ModelInboxNotification notification;
  final InboxNotificationController controller;

  const _NotificationTile({
    required this.notification,
    required this.controller,
  });

  IconData _iconForType(String? type) {
    switch (type) {
      case 'event_created':
        return Icons.celebration;
      case 'event_approved':
        return Icons.check_circle;
      case 'event_rejected':
        return Icons.cancel;
      case 'event_hold':
        return Icons.pause_circle_filled;
      case 'event_rescheduled':
        return Icons.schedule;
      case 'organizer_message':
        return Icons.message;
      default:
        return Icons.notifications;
    }
  }

  Color _colorForType(String? type) {
    switch (type) {
      case 'event_created':
        return const Color(0xFFFF5F15);
      case 'event_approved':
        return const Color(0xFF10B981);
      case 'event_rejected':
        return const Color(0xFFEF4444);
      case 'event_hold':
        return const Color(0xFFF59E0B);
      case 'event_rescheduled':
        return const Color(0xFF3B82F6);
      case 'organizer_message':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      var dt = DateTime.parse(dateStr);
      if (!dt.isUtc) dt = DateTime.utc(dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second, dt.millisecond, dt.microsecond);
      final now = DateTime.now().toUtc();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return DateFormat('MMM d, h:mm a').format(dt.toLocal());
    } catch (_) {
      return dateStr;
    }
  }

  void _onTap(BuildContext context) {
    if (!notification.isRead && notification.id != null) {
      controller.markAsRead([notification.id!]);
    }

    final eventId = notification.eventId;
    if (eventId != null && eventId > 0) {
      _navigateToEvent(eventId);
    }
  }

  Future<void> _navigateToEvent(int eventId) async {
    try {
      final res = await ApiService.getEventById(eventId);
      final data = res.data;
      if (data is Map && data['status'] == 'success' && data['data'] != null) {
        Get.to(
          () => EventDetailView(event: data['data']),
          transition: Transition.rightToLeft,
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForType(notification.notificationType);
    final isUnread = !notification.isRead;

    return GestureDetector(
      onTap: () => _onTap(context),
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        decoration: BoxDecoration(
          color: isUnread ? color.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUnread ? color.withOpacity(0.2) : Colors.grey.shade200,
            width: isUnread ? 1.2 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(14.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _iconForType(notification.notificationType),
                  color: color,
                  size: 22.w,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title ?? 'Notification',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight:
                                  isUnread ? FontWeight.w700 : FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8.w,
                            height: 8.w,
                            margin: EdgeInsets.only(left: 8.w),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    if (notification.body != null &&
                        notification.body!.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        notification.body!,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey[700],
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    SizedBox(height: 6.h),
                    Text(
                      _formatTime(notification.createdAt),
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              if (notification.eventId != null)
                Padding(
                  padding: EdgeInsets.only(left: 4.w, top: 4.h),
                  child: Icon(Icons.chevron_right,
                      size: 20.w, color: Colors.grey[400]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
