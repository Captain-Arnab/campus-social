import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Perforated tear line between ticket image and details (campus ticket stub motif).
class TicketPerforation extends StatelessWidget {
  final Color backgroundColor;

  const TicketPerforation({super.key, this.backgroundColor = AppColors.surface});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      width: double.infinity,
      child: CustomPaint(
        painter: _TicketPerforationPainter(backgroundColor: backgroundColor),
      ),
    );
  }
}

class _TicketPerforationPainter extends CustomPainter {
  final Color backgroundColor;

  _TicketPerforationPainter({required this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    const notchRadius = 7.0;
    const dashWidth = 5.0;
    const gapWidth = 4.0;

    // Side notches (ticket stub cut-outs)
    final notchPaint = Paint()..color = AppColors.cream;
    canvas.drawCircle(Offset(0, midY), notchRadius, notchPaint);
    canvas.drawCircle(Offset(size.width, midY), notchRadius, notchPaint);

    // Dashed perforation line
    final dashPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    var x = notchRadius + 4;
    final endX = size.width - notchRadius - 4;
    while (x < endX) {
      final segEnd = (x + dashWidth).clamp(0.0, endX);
      canvas.drawLine(Offset(x, midY), Offset(segEnd, midY), dashPaint);
      x += dashWidth + gapWidth;
    }
  }

  @override
  bool shouldRepaint(covariant _TicketPerforationPainter oldDelegate) =>
      oldDelegate.backgroundColor != backgroundColor;
}
