import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_theme.dart';

/// Shows the first [initialCount] rows; a "See all (N)" toggle reveals the rest.
class SeeMoreList extends StatefulWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final int initialCount;
  final Color? linkColor;

  const SeeMoreList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.initialCount = 3,
    this.linkColor,
  });

  @override
  State<SeeMoreList> createState() => _SeeMoreListState();
}

class _SeeMoreListState extends State<SeeMoreList> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final canCollapse = widget.itemCount > widget.initialCount;
    final visible = _expanded || !canCollapse ? widget.itemCount : widget.initialCount;
    final color = widget.linkColor ?? AppColors.accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < visible; i++) widget.itemBuilder(context, i),
        if (canCollapse)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              style: TextButton.styleFrom(
                foregroundColor: color,
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0),
                minimumSize: Size(0, 36.h),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: Icon(
                _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                size: 20,
              ),
              label: Text(
                _expanded ? 'Show less' : 'See all (${widget.itemCount})',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ],
    );
  }
}
