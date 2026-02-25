import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';
import 'dart:math' as math;

class PosterTheme {
  // --- BRAND COLORS ---
  static const Color gradBg = Color(0xFFEEDCDC);
  static const Color gradBlue = Color(0xFF084883);
  static const Color gradYellow = Color(0xFFFFBE2D);
  
  static const Color techBlueGrad1 = Color(0xFF054C9D);
  static const Color techBlueGrad2 = Color(0xFF021B42);
  static const Color techOrange = Color(0xFFFD6E0E);
  
  static const Color engBlue = Color(0xFF1B4069);
  static const Color engOrange = Color(0xFFE86C26);
  
  static const Color trekOrange = Color(0xFFFF5F15);

  // ==========================================================
  // 1. GRADUATION PARTY - UNCHANGED
  // ==========================================================
static Widget graduationTheme({
  required String title, 
  required String date, 
  required String venue, 
  required String time,
  String description = "",
  File? image,
  File? logoImage,
  File? qrCodeImage, // NEW parameter
}) {
  return AspectRatio(
    aspectRatio: 3 / 4,
    child: Container(
      color: gradBg,
      child: Stack(
        children: [
          // Background Image
          if (image != null)
            Positioned(
              left: 100.w, right: 20.w, bottom: 40.h, top: 80.h,
              child: Opacity(
                opacity: 0.15,
                child: Image.file(image, fit: BoxFit.cover, width: 200.w),
              ),
            ),

          // Decorative Shapes
          Positioned(
            right: -50.w, top: -50.h,
            child: Container(
              width: 200.w, height: 200.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: gradBlue.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            left: -80.w, bottom: -80.h,
            child: Container(
              width: 250.w, height: 250.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: gradBlue.withOpacity(0.08),
              ),
            ),
          ),

          // LOGO
          Positioned(
            bottom: 300.h, right: 0.w, left: 230.w,
            child: logoImage != null 
              ? Container(
                    padding: EdgeInsets.all(3.r),
                    child: Image.file(logoImage, height: 100.h, width: 100.w, fit: BoxFit.contain),
                  )
              : Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2.r),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 2))],
                  ),
                  child: Icon(Icons.school, size: 55.sp, color: gradBlue),
                ),
          ),

          // MAIN CONTENT - Title Section
          Positioned(
            top: 60.h, left: 30.w, right: 30.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "GURU NANAK UNIVERSITY PRESENTS",
                  style: TextStyle(fontSize: 9.sp, fontFamily: 'Times New Roman', fontWeight: FontWeight.w800, color: gradBlue, letterSpacing: 1),
                ),
                
                // Event Title
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Times New Roman',
                    fontSize: 30.sp,
                    fontWeight: FontWeight.w900,
                    color: gradBlue,
                    height: 1.1,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // DESCRIPTION - MOVED HERE (below title)
          if (description.isNotEmpty)
            Positioned(
              top: 130.h, // Positioned after title
              left: 30.w, 
              right: 30.w,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 0.w),
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: 25.sp, 
                    color: gradBlue, 
                    fontFamily: 'Robotoslab', 
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

          // ACTIVITIES SECTION - adjusted position
          Positioned(
            top: description.isNotEmpty ? 200.h : 160.h,
            left: 30.w, 
            right: 30.w,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 10.h),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: gradBlue, width: 2),
                  bottom: BorderSide(color: gradBlue, width: 2),
                ),
              ),
              child: Center(
                child: Text(
                  "DANCE • LIVE MUSIC • DINNER",
                  style: TextStyle(
                    fontWeight: FontWeight.w800, 
                    fontFamily: 'Times New Roman',
                    fontSize: 14.sp, 
                    color: gradBlue, 
                    letterSpacing: 1.8
                  ),
                ),
              ),
            ),
          ),

          // BOTTOM INFO SECTION
          Positioned(
            bottom: 2.h, 
            left: 30.w, 
            right: 30.w,
            child: Column(
              children: [
                // Info Cards Row
                Row(
                  children: [
                    // Left Column - Date, Time, Venue
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date
                          _infoRow(Icons.calendar_today, date.toUpperCase()),
                          SizedBox(height: 10.h),
                          // Time
                          _infoRow(Icons.access_time, time),
                          SizedBox(height: 10.h),
                          // Venue
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.location_on, color: gradBlue, size: 16.sp),
                              SizedBox(width: 6.w),
                              Expanded(
                                child: Text(
                                  venue, 
                                  style: TextStyle(
                                    color: gradBlue, 
                                    fontFamily: 'Montserrat',
                                    fontSize: 11.sp, 
                                    fontWeight: FontWeight.w600,
                                    height: 1.3
                                  ), 
                                  maxLines: 2, 
                                  overflow: TextOverflow.ellipsis
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(width: 15.w),
                    
                    // Right Column - QR CODE (replaces Class of 2025)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // QR Code Container
                        Container(
                          width: 75.w,
                          height: 75.w,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: gradBlue, width: 2),
                          ),
                          child: qrCodeImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(6.r),
                                  child: Image.file(
                                    qrCodeImage,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Icon(
                                  Icons.qr_code_2,
                                  size: 60.sp,
                                  color: gradBlue.withOpacity(0.3),
                                ),
                        ),
                        SizedBox(height: 8.h),
                        // "Scan to Register" text
                        Text(
                          "SCAN TO",
                          style: TextStyle(
                            fontSize: 9.sp,
                            fontFamily: 'Times New Roman',
                            fontWeight: FontWeight.w700,
                            color: gradBlue,
                            letterSpacing: 1,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          "REGISTER",
                          style: TextStyle(
                            fontSize: 9.sp,
                            fontFamily: 'Times New Roman',
                            fontWeight: FontWeight.w700,
                            color: gradBlue,
                            letterSpacing: 1,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                // SizedBox(height: 12.h),
                
                // Website at bottom
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "www.gnuindia.org",
                    style: TextStyle(
                      color: gradBlue,
                      fontSize: 10.sp,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  // Helper method for info rows
  static Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: gradBlue, size: 16.sp),
        SizedBox(width: 6.w),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: gradBlue,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w600,
              fontSize: 11.sp,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // 2. TECH & INNOVATION - REDESIGNED TO MATCH REFERENCE
  // ==========================================================
  static Widget techTheme({
    required String title, 
    required String date, 
    required String venue,
    required String time,
    String mode = "Online", // New: Online/Offline
    String trainerName = "", // New: Trainer name
    String description = "",
    File? image, // Background robot image
    File? logoImage,
    File? trainerImage, // New: Trainer profile picture
  }) {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background1.png'),
            fit: BoxFit.contain,
          ),
        ),
        child: Stack(
          children: [
            // Decorative circles background
            Positioned.fill(child: CustomPaint(painter: TechCirclesPainter())),

            // Background Robot Image (left side)
            if (image != null)
              Positioned(
                left: -30.w, 
                bottom: 40.h,
                top: 80.h,
                child: Opacity(
                  opacity: 0.9,
                  child: Image.file(
                    image, 
                    fit: BoxFit.contain,
                    width: 220.w,
                  ),
                ),
              ),

            // LOGO (Top Right)
            if (logoImage != null)
              Positioned(
                bottom: 280.h, 
                left: 210.w,
                right: 0.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
                  child: Image.file(
                    logoImage, 
                    height: 100.h,
                    width: 100.w,
                    fit: BoxFit.contain
                  ),
                ),
              ),

            // TITLE (Top Left - Orange & White)
            Positioned(
              top: 50.h, 
              left: 25.w, 
              right: 25.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Line 1 (Orange)
                  Text(
                    _getTitleFirstWord(title),
                    style: TextStyle(
                      fontFamily: 'Aerial',
                      fontSize: 30.sp,
                      fontWeight: FontWeight.w700,
                      color: techOrange,
                      height: 0.9,
                      letterSpacing: 1,
                    ),
                  ),
                  // Title Line 2 (White)
                  Text(
                    _getTitleRestWords(title),
                    style: TextStyle(
                      fontFamily: 'Aerial',
                      fontSize: 25.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 0.9,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),

            // SUBTITLE (Right Side - Cyan/Teal)
            Positioned(
              top: 100.h,
              right: 25.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
                child: Row(
                  children: [
                    Container(
                      width: 60.w,
                      height: 2.h,
                      color: Colors.cyanAccent,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      "LET'S TALK ABOUT",
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontFamily: 'Aerial',
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              top: 112.h,
              right: 25.w,
              child: Text(
                "THE FUTURE",
                style: TextStyle(
                  fontSize: 10.sp,
                  fontFamily: 'Aerial',
                  fontWeight: FontWeight.w800,
                  color: Colors.white70,
                  letterSpacing: 1.5,
                ),
              ),
            ),

            // DESCRIPTION (Right Side)
            if (description.isNotEmpty)
              Positioned(
                top: 130.h,
                right: 25.w,
                left: 135.w,
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontFamily: 'Georgia',
                    color: Colors.white,
                    height: 1,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),

            // EVENT INFO SECTION (Right Side)
            Positioned(
              bottom: 100.h,
              right: 25.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Date & Time
                  Text(
                    date.toUpperCase(),
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontFamily: 'RobotoSlab',
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  // SizedBox(height: 4.h),
                  Text(
                    "LIVE $time",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontFamily: 'RobotoSlab',
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  // SizedBox(height: 8.h),
                  // Mode
                  Text(
                    "MODE: ${mode.toUpperCase()}",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontFamily: 'Aerial',
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // TRAINER SECTION (Bottom Left) - Only if trainer name provided
            if (trainerName.isNotEmpty)
              Positioned(
                bottom: 25.h,
                left: 25.w,
                child: Row(
                  children: [
                    // Trainer Image
                    Container(
                      width: 70.w,
                      height: 70.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        color: Colors.grey[800],
                      ),
                      child: ClipOval(
                        child: trainerImage != null
                            ? Image.file(
                                trainerImage,
                                fit: BoxFit.cover,
                              )
                            : Icon(
                                Icons.person,
                                size: 40.sp,
                                color: Colors.white54,
                              ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    // Trainer Info
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: techOrange,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            "Trainer",
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          trainerName,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "Speaker",
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // REGISTER NOW BUTTON (Bottom Right)
            Positioned(
              bottom: 30.h,
              right: 25.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: techOrange,
                  borderRadius: BorderRadius.circular(30.r),
                  boxShadow: [
                    BoxShadow(
                      color: techOrange.withOpacity(0.5),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Text(
                  "Register Now",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 10.sp,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            // WEBSITE (Bottom Left)
            Positioned(
              bottom: 12.h,
              right: 25.w,
              child: Text(
                "www.gnuindia.org",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to get first word of title
  static String _getTitleFirstWord(String title) {
    final words = title.trim().split(' ');
    return words.isNotEmpty ? words[0].toUpperCase() : '';
  }

  // Helper to get rest of title
  static String _getTitleRestWords(String title) {
    final words = title.trim().split(' ');
    if (words.length <= 1) return '';
    return words.sublist(1).join(' ').toUpperCase();
  }

// ==========================================================
// 3. SPOKEN ENGLISH
// ==========================================================
static Widget englishTheme({
  String title = "ONLINE COURSE",
  String subtitle = "Spoken English",
  required String startDay,
  required String endDay,
  required String startTime,
  required String endTime,
  List<String> coursePoints = const [],
  String phoneNumber = "800 829 5550 / 51",
  File? image,
  File? logoImage,
}) {
  return AspectRatio(
    aspectRatio: 3 / 4,
    child: Container(
      color: Colors.white,
      child: Stack(
        children: [
          // Blue right section
          Positioned(
            right: 20.w,
            top: 0,
            bottom: 0,
            child: Container(
              width: 80.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    engBlue,
                    engBlue.withOpacity(0.9),
                  ],
                ),
              ),
            ),
          ),
          
          // Student Image (Right side)
          if (image != null)
            Positioned(
              right: -25.w,
              bottom: 58.h,
              top: 100.h,
              child: ClipRect(
                child: Align(
                  alignment: Alignment.centerRight,
                  widthFactor: 0.9,
                  child: Image.file(
                    image,
                    fit: BoxFit.cover,
                    width: 180.w,
                  ),
                ),
              ),
            ),

          // blue decorative wave at bottom          
          Positioned(
            bottom: -30.h,
            left: 120.w,
            right: 0,
            child: CustomPaint(
              size: Size(200.w, 100.h),
              painter: EnglishWavePainter1(),
            ),
          ),

          // Orange decorative wave at bottom
          Positioned(
            bottom: 0,
            left: 150.w,
            right: 0,
            child: CustomPaint(
              size: Size(200.w, 100.h),
              painter: EnglishWavePainter(),
            ),
          ),

          // Logo (Top Left)
          if (logoImage != null)
            Positioned(
              bottom: 235.h,
              right: 130.w,
              child: Container(
                padding: EdgeInsets.all(10.r),
                // decoration: BoxDecoration(
                //   color: Colors.white,
                //   borderRadius: BorderRadius.circular(12.r),
                //   boxShadow: [
                //     BoxShadow(
                //       color: Colors.black12,
                //       blurRadius: 8,
                //       offset: const Offset(0, 2),
                //     )
                //   ],
                // ),
                child: Image.file(
                  logoImage,
                  height: 200.h,
                  width: 180.w,
                  fit: BoxFit.contain,
                ),
              ),
            ),

          // Subtitle (Handwritten style)
          Positioned(
            top: 40.h,
            left: 20.w,
            child: Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Cursive',
                fontSize: 32.sp,
                color: engBlue,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          // Title (Bold Orange)
          Positioned(
            top: 75.h,
            left: 20.w,
            right: 80.w,
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 42.sp,
                fontFamily: 'Aerial',
                height: 0.8,
                fontWeight: FontWeight.w900,
                color: engOrange,
                letterSpacing: 0.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Schedule (Day and Time)
          Positioned(
            top: 135.h,
            left: 20.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$startDay - $endDay",
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    color: engBlue,
                  ),
                ),
                // SizedBox(height: -2.h),
                Text(
                  "$startTime - $endTime",
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    color: engBlue,
                  ),
                ),
              ],
            ),
          ),

          // Our Course Section (Blue button style)
          Positioned(
            top: 180.h,
            left: 20.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: engBlue,
                borderRadius: BorderRadius.circular(30.r),
              ),
              child: Text(
                "Our Course",
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Course Points List
          if (coursePoints.isNotEmpty)
            Positioned(
              top: 210.h,
              left: 20.w,
              right: 100.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: coursePoints.map((point) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.only(top: 1.h, right: 8.w),
                          width: 20.w,
                          height: 20.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: engBlue,
                            border: Border.all(color: engBlue, width: 2),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.check,
                              size: 12.sp,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            point,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: engBlue,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),



          // JOIN NOW Button (Yellow/Orange)
          Positioned(
            bottom: 50.h,
            left: 12.5.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB93E),
                borderRadius: BorderRadius.circular(30.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFB93E).withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                "JOIN NOW",
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),

          // Website and Phone (Bottom Left on Orange Wave)
          Positioned(
            bottom: 5.h,
            left: 12.5.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "www.gnuindia.org",
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: engBlue,
                  ),
                ),
                // SizedBox(height: 4.h),
                Text(
                  "Admissions Helpline:",
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: engBlue,
                  ),
                ),
                Text(
                  phoneNumber,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    color: engBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
  
  // ==========================================================
  // 4. Music Festival
  // ==========================================================
  static Widget musicFestivalTheme({
    required String title,
    required String date,
    required String location,
    required String startTime,
    required String endTime,
    String description = "",
    File? image,
    File? logoImage,
    File? qrCodeImage,
  }) {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A4D7D), Color(0xFF0D2847)],
          ),
        ),
        child: Stack(
          children: [
            // Top Left Paint Stroke
            Positioned(
              top: -80.h,
              left: -85.w,
              child: Transform.rotate(
                angle: 0.005,
                child: Image.asset(
                  'assets/images/paint.png',
                  width: 150.w,
                  height: 200.h,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // Bottom Left Paint Stroke
            Positioned(
              bottom: -45.h,
              left: -95.w,
              child: Transform.rotate(
                angle: -0.1,
                child: Image.asset(
                  'assets/images/paint.png',
                  width: 250.w,
                  height: 100.h,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // Bottom Right Paint Stroke
            Positioned(
              bottom: 30.h,
              right: -132.w,
              child: Transform.rotate(
                angle: 0.1,
                child: Image.asset(
                  'assets/images/paint.png',
                  width: 200.w,
                  height: 200.h,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // Logo at top right
            if (logoImage != null)
              Positioned(
                top: -30.h,
                right: -14.5.w,
                child: Container(
                  padding: EdgeInsets.all(8.r),
                  // decoration: BoxDecoration(
                  //   color: Colors.white,
                  //   borderRadius: BorderRadius.circular(12.r),
                  // ),
                  child: Image.file(logoImage, height: 100.h, fit: BoxFit.contain),
                ),
              ),

            // University name at top
            Positioned(
              top: 35.h,
              left: 82.w,
              right: logoImage != null ? 75.w : 50.w,
              child: Text(
                "GURU NANAK UNIVERSITY",
                style: GoogleFonts.raleway(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                  letterSpacing: 0.05,
                ),
                maxLines: 1,
              ),
            ),

            // Main Title
            Positioned(
              top: 48.h,
              left: 65.w,
              right: 65.w,
              child: SizedBox(
                width: 400.w,   // HARD WIDTH (VERY IMPORTANT)
                height: 150.h,  // HARD HEIGHT
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // MUSIC
                    Positioned(
                      top: -12.h,
                      left: 10.w,
                      child: Text(
                        title.split(' ').first.toUpperCase(),
                        style: GoogleFonts.leagueSpartan(
                          fontSize: 60.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.05,
                        ),
                      ),
                    ),

                    // FESTIVAL
                    if (title.split(' ').length > 1)
                      Positioned(
                        top: 32.h,
                        left: 10.w,
                        child: Text(
                          title.split(' ').skip(1).join(' ').toUpperCase(),
                          style: GoogleFonts.leagueSpartan(
                            fontSize: 42.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withOpacity(0.9),
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Musical Stroke – Single Straight Segment
            Positioned(
              bottom: 20.h,
              left: -10.w,
              right: -25.w,
              child: SizedBox(
                width: 500.w,   //  bounded width
                height: 400.h,  //  bounded height
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Image.asset(
                    'assets/images/music_strokes.png',
                    width: 450.w,      // stretch straight
                    height: 350.h,
                    fit: BoxFit.fill,  // makes it a straight segment
                  ),
                ),
              ),
            ),

            // Celebration Characters (if image provided)
            if (image != null)
              Positioned(
                bottom: 46.h,
                left: 20.w,
                right: 20.w,
                child: SizedBox(
                  height: 290.h,
                  width: 500.w,
                  child: Image.file(image, fit: BoxFit.contain),
                ),
              ),

            // Info Box
            Positioned(
              bottom: 75.h,
              left: 50.w,
              right: 50.w,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                          20.w, // left
                          5.h, // top
                          5.w, // right
                          5.h, // bottom
                        ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "DATE : $date",
                      style: GoogleFonts.nunito(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0D2847),
                        letterSpacing: 0.5,
                        height: 0.8.h,
                      ),
                    ),
                    // SizedBox(height: 8.h),
                    Text(
                      "LOCATION : $location",
                      style: GoogleFonts.nunito(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0D2847),
                        letterSpacing: 0.5,
                        height: 0.8.h,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),

            // Timings and Contact Section
            Positioned(
              bottom: 35.h,
              left: 20.w,
              child: SizedBox(
                width: 60.w, //  bounded width
                height: 120.h,      //  bounded height
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [

                    // 🕒 TIMINGS (Bottom Left)
                    Positioned(
                      left: 0,
                      bottom: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "TIMINGS:",
                            style: GoogleFonts.nunito(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                              letterSpacing: 0.1,
                            ),
                          ),
                          Text(
                            "$startTime TO $endTime",
                            style: GoogleFonts.nunito(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 📞 CONTACT (Bottom Right – Text)
                    Positioned(
                      left: 185.w,
                      bottom: qrCodeImage != null ? 10.h : 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "CONTACT:",
                            style: GoogleFonts.nunito(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                              letterSpacing: 0.1,
                            ),
                          ),
                          Text(
                            "WWW.GNUINDIA.ORG",
                            style: GoogleFonts.nunito(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 📱 SCAN TO REGISTER (Bottom Right – QR)
                    if (qrCodeImage != null)
                      Positioned(
                        left: 210.w,
                        bottom: -19.h,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "SCAN TO",
                                  style: GoogleFonts.nunito(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  "REGISTER",
                                  style: GoogleFonts.nunito(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: 6.w),
                            Container(
                              width: 35.w,
                              height: 35.w,
                              padding: EdgeInsets.all(2.r),
                              child: Image.file(
                                qrCodeImage,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // ==========================================================
  // 5. Sports Basketball Tournament
  // ==========================================================
  static Widget basketballTheme({
    required String title,
    required String stadiumName,
    required String address,
    required String date,
    required String startTime,
    required String endTime,
    File? image, // Basketball court action image
    File? logoImage,
  }) {
    return AspectRatio(
    aspectRatio: 3 / 4,
    child: Container(
      // decoration: const BoxDecoration(
      //   gradient: LinearGradient(
      //     begin: Alignment.topLeft,
      //     end: Alignment.bottomRight,
      //     colors: [Color(0xFF2B5BA8), Color(0xFF1E4078)],
      //   ),
      // ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [

          // ===================== BACKGROUND LAYER =====================
          Positioned.fill(
            child: Align(
              alignment: Alignment.topLeft,
                // opacity: 0.15,
                child: Image.asset(
                  'assets/images/basketball.png',
                  width: 1000.w,
                  height: 1000.w,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          // ===================== FOREGROUND CONTENT =====================

          // Logo
          if (logoImage != null)
            Positioned(
              top: -20.h,
              right: -18.w,
              child: Container(
                padding: EdgeInsets.all(7.r),
                // decoration: BoxDecoration(
                //   color: Colors.white,
                //   borderRadius: BorderRadius.circular(12.r),
                //   boxShadow: [
                //     BoxShadow(
                //       color: Colors.black26,
                //       blurRadius: 8,
                //       offset: const Offset(0, 2),
                //     ),
                //   ],
                // ),
                child: Image.file(
                  logoImage,
                  height: 100.h,
                  width: 100.w,
                  fit: BoxFit.contain,
                ),
              ),
            ),

          // University Name
          Positioned(
            top: 55.h,
            left: 25.w,
            right: logoImage != null ? 80.w : 25.w,
            child: Text(
              "GURU NANAK UNIVERSITY",
              style: GoogleFonts.roboto(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),

          // Main Title
          Positioned(
            top: 70.h,
            left: 23.w,
            right: 25.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.split(' ').first.toUpperCase(),
                  style: GoogleFonts.anton(
                    fontSize: 54.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1,
                    letterSpacing: 0.2,
                  ),
                ),
                if (title.split(' ').length > 1)
                  Text(
                    title.split(' ').skip(1).join(' ').toUpperCase(),
                    style: GoogleFonts.anton(
                      fontSize: 50.sp,
                      fontWeight: FontWeight.w900,
                      color: const Color.fromARGB(255, 241, 129, 88),
                      height: 1,
                      letterSpacing: 0.2,
                    ),
                  ),
              ],
            ),
          ),
          // Action Image
          if (image != null)
            Positioned(
              left: 25.w,
              right: 30.w,
              top: 165.h,
              child: Container(
                height: 150.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2.r),
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2.r),
                  child: Image.file(
                    image,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          // Stadium Info
          Positioned(
            left: 30.w,
            right: 30.w,
            bottom: image != null ? 65.h : 90.h,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
              // decoration: BoxDecoration(
              //   color: Colors.white,
              //   borderRadius: BorderRadius.circular(8.r),
              //   boxShadow: [
              //     BoxShadow(
              //       color: Colors.black.withOpacity(0.2),
              //       blurRadius: 15,
              //       offset: const Offset(0, 5),
              //     ),
              //   ],
              // ),
              child: Column(
                children: [
                  Text(
                    stadiumName.toUpperCase(),
                    style: GoogleFonts.anton(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  // SizedBox(height: -10.h),
                  Text(
                    address,
                    style: GoogleFonts.roboto(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          // Date (Bottom Left)
          Positioned(
            bottom: 20.h,
            left: 20.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date.toUpperCase(),
                  style: GoogleFonts.roboto(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1.5,
                  ),
                ),
                Text(
                  "MORE INFORMATION:",
                  style: GoogleFonts.roboto(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          // Time & Website (Bottom Right)
          Positioned(
            bottom: 20.h,
            right: 20.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "$startTime - $endTime",
                  style: GoogleFonts.roboto(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1.5,
                  ),
                ),
                Text(
                  "www.gnuindia.org",
                  style: GoogleFonts.roboto(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  }
}



class TechCirclesPainter extends CustomPainter {
  @override void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.05)..style = PaintingStyle.stroke..strokeWidth = 1.0;
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.4), size.width * 0.35, paint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.4), size.width * 0.55, paint);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Wave Painter for English Theme
class EnglishWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE86C26) // engOrange
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(205, size.height * -0.5);
    
    // Create smooth wave
    // path.quadraticBezierTo(
    //   size.width * 0.25, size.height * 0.3,
    //   size.width * 0.5, size.height * 0.4,
    // );
    path.quadraticBezierTo(
      size.width * 1, size.height * 0.2,
      size.width, size.height * 0.2,
    );
    
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class EnglishWavePainter1 extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1B4069) // engOrange
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(100, size.height * -0.5);
    
    // Create smooth wave
    // path.quadraticBezierTo(
    //   size.width * 0.25, size.height * 0.3,
    //   size.width * 0.5, size.height * 0.4,
    // );
    path.quadraticBezierTo(
      size.width * 1, size.height * 0.2,
      size.width, size.height * 0.2,
    );
    
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}