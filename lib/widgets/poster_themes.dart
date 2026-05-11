import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';

class PosterTheme {
  /// Keeps dynamic poster copy inside layout; use for titles and body on fixed regions.
  static Widget boundedText(
    String text,
    TextStyle style, {
    int maxLines = 4,
    TextAlign textAlign = TextAlign.start,
  }) {
    return Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
      softWrap: true,
    );
  }

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
  /// Dates + start/end times (e.g. first day + start through last day + end).
  required String scheduleCaption,
  required String venue,
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
                child: boundedText(
                  description,
                  TextStyle(
                    fontSize: 16.sp,
                    color: gradBlue,
                    fontFamily: 'Robotoslab',
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                  maxLines: 4,
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
                child: boundedText(
                  "DANCE • LIVE MUSIC • DINNER",
                  TextStyle(
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Times New Roman',
                    fontSize: 14.sp,
                    color: gradBlue,
                    letterSpacing: 1.8,
                  ),
                  maxLines: 2,
                  textAlign: TextAlign.center,
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
                          _infoRowMultilineDate(Icons.event, scheduleCaption.toUpperCase(), maxLines: 5),
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

  /// Date range on graduation poster (may span two lines).
  static Widget _infoRowMultilineDate(IconData icon, String text, {int maxLines = 4}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 2.h),
          child: Icon(icon, color: gradBlue, size: 16.sp),
        ),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: gradBlue,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w600,
              fontSize: 10.sp,
              height: 1.25,
            ),
            maxLines: maxLines,
            softWrap: true,
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
    required String scheduleCaption,
    required String techTagline,
    required String venue,
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
                  boundedText(
                    _getTitleFirstWord(title),
                    TextStyle(
                      fontFamily: 'Aerial',
                      fontSize: 30.sp,
                      fontWeight: FontWeight.w700,
                      color: techOrange,
                      height: 0.9,
                      letterSpacing: 1,
                    ),
                    maxLines: 2,
                  ),
                  // Title Line 2 (White)
                  boundedText(
                    _getTitleRestWords(title),
                    TextStyle(
                      fontFamily: 'Aerial',
                      fontSize: 25.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 0.9,
                      letterSpacing: 1,
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),

            // Editable tagline (replaces fixed "Let's talk about" / "The future" copy)
            Positioned(
              top: 100.h,
              left: 115.w,
              right: 25.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 60.w,
                        height: 2.h,
                        color: Colors.cyanAccent,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: boundedText(
                          techTagline.trim().toUpperCase(),
                          TextStyle(
                            fontSize: 10.sp,
                            fontFamily: 'Aerial',
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1.1,
                            height: 1.15,
                          ),
                          maxLines: 4,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ],
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
              left: 120.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  boundedText(
                    scheduleCaption.toUpperCase(),
                    TextStyle(
                      fontSize: 14.sp,
                      fontFamily: 'RobotoSlab',
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.2,
                      height: 1.15,
                    ),
                    maxLines: 5,
                    textAlign: TextAlign.right,
                  ),
                  boundedText(
                    "MODE: ${mode.toUpperCase()}",
                    TextStyle(
                      fontSize: 16.sp,
                      fontFamily: 'Aerial',
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),

            // TRAINER SECTION (Bottom Left) - Only if trainer name provided
            // Must bound width: Row + Expanded requires finite maxWidth (Positioned with only `left` is unbounded).
            if (trainerName.isNotEmpty)
              Positioned(
                bottom: 25.h,
                left: 25.w,
                right: 120.w,
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
                    Expanded(
                      child: Column(
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
                          boundedText(
                            trainerName,
                            TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                          ),
                          boundedText(
                            "Speaker",
                            TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                            ),
                            maxLines: 1,
                          ),
                        ],
                      ),
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
  required String scheduleCaption,
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
            right: 100.w,
            child: boundedText(
              subtitle,
              TextStyle(
                fontFamily: 'Cursive',
                fontSize: 32.sp,
                color: engBlue,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
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

          // Schedule (dates + times; width capped so text does not run under the image)
          Positioned(
            top: 132.h,
            left: 20.w,
            right: 92.w,
            child: boundedText(
              scheduleCaption,
              TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w900,
                color: engBlue,
                height: 1.2,
              ),
              maxLines: 4,
            ),
          ),

          // Our Course Section (Blue button style)
          Positioned(
            top: 198.h,
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
              top: 228.h,
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
                          child: boundedText(
                            point,
                            TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: engBlue,
                              height: 1.3,
                            ),
                            maxLines: 3,
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
            right: 12.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                boundedText(
                  "www.gnuindia.org",
                  TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: engBlue,
                  ),
                  maxLines: 1,
                ),
                boundedText(
                  "Admissions Helpline:",
                  TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: engBlue,
                  ),
                  maxLines: 1,
                ),
                boundedText(
                  phoneNumber,
                  TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    color: engBlue,
                  ),
                  maxLines: 2,
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
    /// Extra when line when the event spans multiple calendar days (dates + times).
    String scheduleDetail = "",
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
              child: boundedText(
                "GURU NANAK UNIVERSITY",
                GoogleFonts.raleway(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                  letterSpacing: 0.05,
                ),
                maxLines: 2,
                textAlign: TextAlign.center,
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
                  clipBehavior: Clip.hardEdge,
                  children: [
                    // MUSIC
                    Positioned(
                      top: -12.h,
                      left: 10.w,
                      right: 8.w,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          title.split(' ').first.toUpperCase(),
                          style: GoogleFonts.leagueSpartan(
                            fontSize: 59.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.05,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),

                    // FESTIVAL
                    if (title.split(' ').length > 1)
                      Positioned(
                        top: 32.h,
                        left: 10.w,
                        right: 8.w,
                        child: boundedText(
                          title.split(' ').skip(1).join(' ').toUpperCase(),
                          GoogleFonts.leagueSpartan(
                            fontSize: 41.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withOpacity(0.9),
                            letterSpacing: 1.5,
                          ),
                          maxLines: 2,
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
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0D2847),
                        letterSpacing: 0.5,
                        height: 1.2,
                      ),
                      maxLines: 3,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (scheduleDetail.trim().isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      boundedText(
                        scheduleDetail,
                        GoogleFonts.nunito(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0D2847),
                          letterSpacing: 0.3,
                          height: 1.2,
                        ),
                        maxLines: 3,
                      ),
                    ],
                    boundedText(
                      "LOCATION : $location",
                      GoogleFonts.nunito(
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

            // Timings, contact, QR — bounded row (replaces broken 60.w clip)
            Positioned(
              bottom: 28.h,
              left: 16.w,
              right: 16.w,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
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
                          "$startTime — $endTime",
                          style: GoogleFonts.nunito(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (qrCodeImage != null) ...[
                    SizedBox(width: 8.w),
                    Column(
                      mainAxisSize: MainAxisSize.min,
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
                        SizedBox(height: 4.h),
                        SizedBox(
                          width: 40.w,
                          height: 40.w,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4.r),
                            child: Image.file(qrCodeImage, fit: BoxFit.contain),
                          ),
                        ),
                      ],
                    ),
                  ] else
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                          ),
                        ],
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
  // 5. Sports Basketball Tournament
  // ==========================================================
  static Widget basketballTheme({
    required String title,
    required String stadiumName,
    required String address,
    required String date,
    required String startTime,
    required String endTime,
    String scheduleDetail = "",
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
            child: boundedText(
              "GURU NANAK UNIVERSITY",
              GoogleFonts.roboto(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
              maxLines: 2,
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
                boundedText(
                  title.split(' ').first.toUpperCase(),
                  GoogleFonts.anton(
                    fontSize: 54.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 2,
                ),
                if (title.split(' ').length > 1)
                  boundedText(
                    title.split(' ').skip(1).join(' ').toUpperCase(),
                    GoogleFonts.anton(
                      fontSize: 50.sp,
                      fontWeight: FontWeight.w900,
                      color: const Color.fromARGB(255, 241, 129, 88),
                      height: 1,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 2,
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
                  boundedText(
                    stadiumName.toUpperCase(),
                    GoogleFonts.anton(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                  ),
                  // SizedBox(height: -10.h),
                  boundedText(
                    address,
                    GoogleFonts.roboto(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                    maxLines: 3,
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
            right: 130.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date.toUpperCase(),
                  style: GoogleFonts.roboto(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.8,
                    height: 1.1,
                  ),
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                ),
                if (scheduleDetail.trim().isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    scheduleDetail,
                    style: GoogleFonts.roboto(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.15,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
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
            left: 140.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                boundedText(
                  "$startTime — $endTime",
                  GoogleFonts.roboto(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1.0,
                  ),
                  maxLines: 2,
                  textAlign: TextAlign.right,
                ),
                boundedText(
                  "www.gnuindia.org",
                  GoogleFonts.roboto(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    letterSpacing: -0.1,
                  ),
                  maxLines: 1,
                  textAlign: TextAlign.right,
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