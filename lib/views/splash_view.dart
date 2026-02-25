import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../data/pref_service.dart';
import 'login_view.dart';
import 'home_view.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Updated to 3 screens with your provided image assets
  final List<OnboardingData> _pages = [
    OnboardingData(
      title: "Welcome to Campus Social",
      description: "Your ultimate platform to discover and join exciting campus events and celebrations.",
      imagePath: 'assets/images/intro1.png', 
      color: const Color(0xFFFF5F15),
    ),
    OnboardingData(
      title: "Showcase Your Talent",
      description: "From live concerts to cultural fests, find your stage and shine with the community.",
      imagePath: 'assets/images/intro2.png', 
      color: const Color(0xFFE91E63),
    ),
    OnboardingData(
      title: "Tech & Innovation",
      description: "Stay ahead with tech talks, workshops, and hackathons hosted right on your campus.",
      imagePath: 'assets/images/intro3.png', 
      color: const Color(0xFF673AB7),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    bool isLoggedIn = await PrefService.isLoggedIn();
    if (mounted) {
      Get.off(
        () => isLoggedIn ? const HomeView() : const LoginView(),
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 500),
      );
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCirc,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _pages[_currentPage].color,
              _pages[_currentPage].color.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLogo(),
                    TextButton(
                      onPressed: _finishOnboarding,
                      child: Text("Skip", style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),

              // Content - Use Expanded to prevent overflow
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _OnboardingPage(data: _pages[index]);
                  },
                ),
              ),

              // Footer
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 100.w, height: 60.w,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset('assets/images/logo.jpeg', fit: BoxFit.cover, 
          errorBuilder: (_, __, ___) => Icon(Icons.school, color: _pages[_currentPage].color)),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: EdgeInsets.only(bottom: 30.h, left: 40.w, right: 40.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pages.length, (index) => _buildIndicator(index)),
          ),
          SizedBox(height: 25.h),
          SizedBox(
            width: double.infinity,
            height: 56.h,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _pages[_currentPage].color,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 4,
              ),
              child: Text(
                _currentPage == _pages.length - 1 ? "GET STARTED" : "NEXT",
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, letterSpacing: 1.1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      width: _currentPage == index ? 24.w : 8.w,
      height: 8.h,
      decoration: BoxDecoration(
        color: _currentPage == index ? Colors.white : Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final OnboardingData data;
  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView( // Allows scrolling on very small phones
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 20.h),
              // Image Container with dynamic sizing
              Container(
                margin: EdgeInsets.symmetric(horizontal: 30.w),
                height: constraints.maxHeight * 0.5, // 50% of available height
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: Image.asset(data.imagePath, fit: BoxFit.cover),
                ),
              ),
              SizedBox(height: 30.h),
              // Animated Text Section
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 800),
                builder: (context, double value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40.w),
                  child: Column(
                    children: [
                      Text(
                        data.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        data.description,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15.sp, color: Colors.white.withOpacity(0.85), height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        );
      }
    );
  }
}

class OnboardingData {
  final String title, description, imagePath;
  final Color color;
  OnboardingData({required this.title, required this.description, required this.imagePath, required this.color});
}