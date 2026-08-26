import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/inbox_notification_controller.dart';
import '../theme/app_theme.dart';

/// Custom bottom nav: Explore — My Events — elevated Host — Notifications — Profile.
class AppBottomNav extends StatelessWidget {
  /// Visual slot 0–4 (2 is the Host center button).
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onHostTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onHostTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: EdgeInsets.only(top: 6.h, bottom: 4.h),
        child: Row(
          children: [
            Expanded(
              child: _NavItem(
                selected: currentIndex == 0,
                icon: Icons.explore_outlined,
                activeIcon: Icons.explore_rounded,
                label: 'Explore',
                onTap: () => onTap(0),
              ),
            ),
            Expanded(
              child: _NavItem(
                selected: currentIndex == 1,
                icon: Icons.confirmation_number_outlined,
                activeIcon: Icons.confirmation_number_rounded,
                label: 'My Events',
                onTap: () => onTap(1),
              ),
            ),
            Expanded(child: _HostCenterButton(onTap: onHostTap)),
            Expanded(
              child: Obx(() {
                final unread = Get.isRegistered<InboxNotificationController>()
                    ? Get.find<InboxNotificationController>().unreadCount.value
                    : 0;
                return _NavItem(
                  selected: currentIndex == 3,
                  icon: Icons.notifications_outlined,
                  activeIcon: Icons.notifications_rounded,
                  label: 'Alerts',
                  badgeCount: unread,
                  onTap: () => onTap(3),
                );
              }),
            ),
            Expanded(
              child: _NavItem(
                selected: currentIndex == 4,
                icon: Icons.person_outline,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                onTap: () => onTap(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HostCenterButton extends StatefulWidget {
  final VoidCallback onTap;

  const _HostCenterButton({required this.onTap});

  @override
  State<_HostCenterButton> createState() => _HostCenterButtonState();
}

class _HostCenterButtonState extends State<_HostCenterButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
      lowerBound: 0.92,
      upperBound: 1,
      value: 1,
    );
    _scale = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _ctrl.reverse();
    await _ctrl.forward();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, -14.h),
      child: ScaleTransition(
        scale: _scale,
        child: GestureDetector(
          onTap: _handleTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56.w,
                height: 56.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.accent, AppColors.accentDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(color: AppColors.surface, width: 3),
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
              ),
              SizedBox(height: 2.h),
              Text(
                'Host',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final bool selected;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final VoidCallback onTap;
  final int badgeCount;

  const _NavItem({
    required this.selected,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      value: widget.selected ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(covariant _NavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected) {
      if (widget.selected) {
        _ctrl.forward(from: 0);
      } else {
        _ctrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.selected ? AppColors.accent : AppColors.textSecondary;
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(
            CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    widget.selected ? widget.activeIcon : widget.icon,
                    color: color,
                    size: 24.sp,
                  ),
                  if (widget.badgeCount > 0)
                    Positioned(
                      right: -8,
                      top: -4,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                        constraints: BoxConstraints(minWidth: 16.w),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.surface, width: 1.5),
                        ),
                        child: Text(
                          widget.badgeCount > 99 ? '99+' : '${widget.badgeCount}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 2.h),
              Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
