import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../widgets/poster_themes.dart';
import 'poster_editor_view.dart';

class TemplateGalleryView extends StatefulWidget {
  const TemplateGalleryView({super.key});

  @override
  State<TemplateGalleryView> createState() => _TemplateGalleryViewState();
}

class _TemplateGalleryViewState extends State<TemplateGalleryView> {
  int currentIndex = 0;
  final CarouselSliderController carouselController = CarouselSliderController();

  final List<Map<String, String>> templates = [
    {
      'title': 'Graduation Party',
      'subtitle': 'Classic University Style',
      'image': 'assets/images/graduation_poster.jpeg',
    },
    {
      'title': 'Tech & Innovation',
      'subtitle': 'Modern Dark Blue Gradient',
      'image': 'assets/images/tech_poster.jpeg',
    },
    {
      'title': 'Online Course',
      'subtitle': 'Professional Split Layout',
      'image': 'assets/images/online_course_poster.jpeg',
    },
    {
      'title': 'Music Festival',
      'subtitle': 'Vibrant Blue Event Design',
      'image': 'assets/images/music_poster.jpeg',
    },
    {
      'title': 'Basketball Tournament',
      'subtitle': 'Sports Event Design',
      'image': 'assets/images/sports_poster.jpeg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text(
          "Select Template",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          // Header Text
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 10.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Choose Your Style",
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  "Swipe to explore different poster templates",
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20.h),

          // Carousel Slider
          Expanded(
            child: CarouselSlider.builder(
              carouselController: carouselController,
              itemCount: templates.length,
              options: CarouselOptions(
                height: double.infinity,
                autoPlay: false,
                enlargeCenterPage: true,
                viewportFraction: 0.85,
                enableInfiniteScroll: false,
                onPageChanged: (index, reason) {
                  setState(() => currentIndex = index);
                },
              ),
              itemBuilder: (context, index, realIndex) {
                return _buildTemplateCard(index);
              },
            ),
          ),

          // Page Indicator
          Padding(
            padding: EdgeInsets.symmetric(vertical: 20.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                templates.length,
                (index) => Container(
                  width: currentIndex == index ? 24.w : 8.w,
                  height: 8.h,
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: currentIndex == index
                        ? const Color(0xFFFF5F15)
                        : Colors.grey[300],
                  ),
                ),
              ),
            ),
          ),

          // Bottom Action Button
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 30.h),
            child: SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: () async {
                  final File? posterFile = await Get.to(
                    () => PosterEditorView(themeIndex: currentIndex),
                    transition: Transition.rightToLeft,
                  );
                  
                  if (posterFile != null) {
                    Get.back(result: posterFile);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5F15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.edit, color: Colors.white, size: 20),
                    SizedBox(width: 8.w),
                    const Text(
                      "Customize This Template",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(int index) {
    final template = templates[index];
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5.w, vertical: 10.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            Image.asset(
              template['image']!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFF5F15).withOpacity(0.3),
                        const Color(0xFFFF9068).withOpacity(0.3)
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.event, size: 80, color: Colors.white),
                  ),
                );
              },
            ),
            
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top - Template Label
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Template Label
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                            )
                          ],
                        ),
                        child: Text(
                          template['title']!,
                          style: const TextStyle(
                            color: Color(0xFFFF5F15),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      
                      // Edit Button
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5F15),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF5F15).withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              final File? posterFile = await Get.to(
                                () => PosterEditorView(themeIndex: index),
                                transition: Transition.rightToLeft,
                              );
                              
                              if (posterFile != null) {
                                Get.back(result: posterFile);
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: EdgeInsets.all(12.w),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Bottom - Template Details
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subtitle
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          template['subtitle']!,
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 12.h),
                      
                      // Features
                      Row(
                        children: [
                          _buildFeatureChip(Icons.auto_awesome, "Professional"),
                          SizedBox(width: 8.w),
                          _buildFeatureChip(Icons.palette, "Customizable"),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          SizedBox(width: 4.w),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}