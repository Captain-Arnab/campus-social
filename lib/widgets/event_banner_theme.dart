import 'package:flutter/material.dart';

class EventBannerTheme extends StatelessWidget {
  final String title;
  final String date;
  final String venue;
  final Color accentColor;

  const EventBannerTheme({
    required this.title, required this.date, 
    required this.venue, this.accentColor = Colors.orange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400, height: 225, // 16:9 Aspect Ratio
      decoration: BoxDecoration(
        color: Colors.blueGrey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // Background Design Elements
          Positioned(
            right: -20, top: -20,
            child: CircleAvatar(radius: 60, backgroundColor: accentColor.withOpacity(0.3)),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(title.toUpperCase(), style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: accentColor, size: 16),
                    const SizedBox(width: 5),
                    Text(date, style: const TextStyle(color: Colors.white70)),
                    const Spacer(),
                    Text(venue, style: TextStyle(color: accentColor, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}