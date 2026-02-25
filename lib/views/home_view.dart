import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:art_sweetalert_new/art_sweetalert_new.dart';
import '../base/constant.dart';
import '../controllers/auth_controller.dart';
import '../controllers/event_controller.dart';
import '../controllers/profile_controller.dart';
import '../utils/sweetalert_helper.dart';
import 'create_event_view.dart';
import 'event_detail_view.dart';
import 'favorites_view.dart';
import 'winners_view.dart';
import 'edit_profile_view.dart';
import 'volunteer_dialog.dart';
import '../data/api_service.dart';
import '../data/pref_service.dart';

class HomeView extends StatefulWidget {
  final int initialBottomTabIndex;
  final int initialMyEventsTabIndex;

  const HomeView({
    super.key,
    this.initialBottomTabIndex = 0,
    this.initialMyEventsTabIndex = 0,
  });

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late int _currentIndex;
  
  final AuthController authController = Get.put(AuthController());
  final EventController eventController = Get.put(EventController());
  final ProfileController profileController = Get.put(ProfileController());

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialBottomTabIndex.clamp(0, 2);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const _ExploreTab(),
      _MyEventsTab(initialIndex: widget.initialMyEventsTabIndex),
      const _ProfileTab(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, -3))
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFFFF5F15),
          unselectedItemColor: Colors.grey[400],
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore), label: "Explore"),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), activeIcon: Icon(Icons.calendar_month), label: "My Events"),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: "Profile"),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 0
          ? SizedBox(
              height: 56,
              width: 56,
              child: FloatingActionButton(
                tooltip: "Host Event",
                onPressed: () => Get.to(
                  () => const CreateEventView(),
                  transition: Transition.rightToLeft,
                ),
                backgroundColor: const Color(0xFFFF5F15),
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18), // stylish rounded square
                ),
                child: const Icon(
                  Icons.add,
                  size: 28,
                  color: Colors.white,
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// --- Cracker burst painter: sparks bursting from a rounded rect border ---
class _CrackerBurstPainter extends CustomPainter {
  final double progress;
  final double borderRadius;

  _CrackerBurstPainter({required this.progress, required this.borderRadius});

  @override
  void paint(Canvas canvas, Size size) {
    const double inset = 14.0; // match burst padding so sparks start at button edge
    final center = Offset(size.width / 2, size.height / 2);
    final halfW = (size.width - inset * 2) / 2;
    final halfH = (size.height - inset * 2) / 2;
    const int sparkCount = 32;
    const double burstLength = 22.0;
    final colors = [
      const Color(0xFFFFD700), // gold
      const Color(0xFFFF8C00), // orange
      Colors.white,
      const Color(0xFFFFA500),
    ];

    for (var i = 0; i < sparkCount; i++) {
      final angle = (i / sparkCount) * 2 * math.pi;
      final cosA = math.cos(angle);
      final sinA = math.sin(angle);
      // Point on ellipse = button border (rounded rect approximated by ellipse)
      final start = Offset(
        center.dx + halfW * cosA,
        center.dy + halfH * sinA,
      );
      final unit = Offset(cosA, sinA);
      final end = start + unit * (burstLength * progress);
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final color = colors[i % colors.length].withOpacity(opacity * 0.95);
      final paint = Paint()
        ..color = color
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(start, end, paint);
      canvas.drawCircle(end, 2.0, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _CrackerBurstPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.borderRadius != borderRadius;
}

// --- Celebrating Winners button: cracker burst from border radius ---
class _CelebratingWinnersButton extends StatefulWidget {
  const _CelebratingWinnersButton();

  @override
  State<_CelebratingWinnersButton> createState() => _CelebratingWinnersButtonState();
}

class _CelebratingWinnersButtonState extends State<_CelebratingWinnersButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _burstAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat();

    _burstAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double borderRadius = 22.0;
    const double burstPadding = 14.0;

    return AnimatedBuilder(
      animation: _burstAnimation,
      builder: (context, child) {
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(120.w + burstPadding * 2, 40.h + burstPadding * 2),
              painter: _CrackerBurstPainter(
                progress: _burstAnimation.value,
                borderRadius: borderRadius,
              ),
            ),
            Material(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(borderRadius),
              child: InkWell(
                onTap: () => Get.to(() => const WinnersView(), transition: Transition.rightToLeft),
                borderRadius: BorderRadius.circular(borderRadius),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(borderRadius),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.8),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events, color: Colors.white, size: 20.w),
                      SizedBox(width: 6.w),
                      Text(
                        "Winners",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14.sp,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// --- EXPLORE TAB ---
class _ExploreTab extends StatefulWidget {
  const _ExploreTab();

  @override
  State<_ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<_ExploreTab> {
  final EventController controller = Get.find<EventController>();
  final TextEditingController searchCtrl = TextEditingController();
  String selectedCategory = "All";
  final List<String> categories = ["All", "IT/Tech", "Cultural", "Sports", "Academic", "Social"];
  List<MapEntry<dynamic, List<dynamic>>> _winnersSwiperData = [];
  bool _winnersLoading = false;
  Timer? _searchDebounce;

  Future<void> _refreshData() async {
    await controller.fetchEvents(
      search: searchCtrl.text.isEmpty ? null : searchCtrl.text,
      category: selectedCategory == "All" ? null : selectedCategory
    );
  }

  Future<void> _loadWinnersSwiper() async {
    if (_winnersLoading) return;
    setState(() => _winnersLoading = true);
    try {
      final response = await ApiService.getPastEvents();
      final data = response.data;
      if (data is! Map || data['status'] != 'success') {
        setState(() { _winnersLoading = false; return; });
      }
      final list = data['data'];
      final events = list is List ? list : [];
      final List<MapEntry<dynamic, List<dynamic>>> result = [];
      for (var i = 0; i < events.length && i < 8; i++) {
        final e = events[i];
        final idRaw = e is Map ? e['id'] : null;
        final id = idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '');
        if (id == null) continue;
        final winRes = await ApiService.getWinnersByEventId(id);
        if (winRes.data is Map && winRes.data['status'] == 'success') {
          final wList = winRes.data['data'];
          if (wList is List && wList.isNotEmpty) result.add(MapEntry(e, wList));
        }
      }
      if (mounted) setState(() { _winnersSwiperData = result; _winnersLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _winnersLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWinnersSwiper());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      controller.fetchEvents(
        search: val.isEmpty ? null : val,
        category: selectedCategory == "All" ? null : selectedCategory,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: const Color(0xFFFF5F15),
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          cacheExtent: 400,
        slivers: [
          // Header with gradient
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 15.h),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF5F15), Color(0xFFFF9068)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Logo
                          Container(
                            width: 60.w,
                            height: 50.w,
                            padding: EdgeInsets.all(0.5.w),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                'assets/images/logo.jpeg',
                                width: 40.w,
                                height: 60.w,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.event,
                                      size: 40.w,
                                      color: const Color(0xFFFF5F15),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _CelebratingWinnersButton(),
                          SizedBox(width: 8.w),
                          IconButton(
                            icon: const Icon(Icons.favorite_outline, color: Colors.white),
                            onPressed: () => Get.to(() => const FavoritesView(), transition: Transition.rightToLeft),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 5.h),
                  TextField(
                    controller: searchCtrl,
                    style: const TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: "Search events, venues...",
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 20.w)
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ],
              ),
            ),
          ),

          // Featured Events Slider
          SliverToBoxAdapter(
            child: Obx(() {
              if (controller.isLoading.value) {
                return SizedBox(
                  height: 280.h,
                  child: const Center(child: CircularProgressIndicator(color: Color(0xFFFF5F15))),
                );
              }
              
            // Get all events without filtering for featured slider
            final allEvents = controller.eventList;
            if (allEvents.isEmpty) return const SizedBox.shrink();

            final featuredEvents = allEvents.take(5).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 15.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Text(
                      "Featured Events",
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  CarouselSlider.builder(
                    itemCount: featuredEvents.length,
                    options: CarouselOptions(
                      height: 400.h,
                      autoPlay: true,
                      autoPlayInterval: const Duration(seconds: 4),
                      autoPlayCurve: Curves.easeInOutCubic,
                      enlargeCenterPage: true,
                      viewportFraction: 0.85,
                      enableInfiniteScroll: featuredEvents.length > 1,
                    ),
                    itemBuilder: (context, index, realIndex) {
                      return _FeaturedEventCard(event: featuredEvents[index]);
                    },
                  ),
                  SizedBox(height: 20.h),
                ],
              );
            }),
          ),

          // Winners section — horizontal swiper of winner cards
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Winners",
                        style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      TextButton(
                        onPressed: () => Get.to(() => const WinnersView(), transition: Transition.rightToLeft),
                        child: Text("See all", style: TextStyle(color: const Color(0xFFFF5F15), fontWeight: FontWeight.w600, fontSize: 14.sp)),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10.h),
                if (_winnersLoading)
                  SizedBox(
                    height: 200.h,
                    child: const Center(child: CircularProgressIndicator(color: Color(0xFFFF5F15))),
                  )
                else if (_winnersSwiperData.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: GestureDetector(
                      onTap: () => Get.to(() => const WinnersView(), transition: Transition.rightToLeft),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [const Color(0xFFFF5F15).withOpacity(0.15), const Color(0xFFFF9068).withOpacity(0.1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFF5F15).withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF5F15).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.emoji_events, color: Color(0xFFFF5F15), size: 36),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Event winners", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
                                  SizedBox(height: 4.h),
                                  Text("See who won past events", style: TextStyle(fontSize: 13.sp, color: Colors.grey[700])),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Color(0xFFFF5F15)),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 220.h,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemCount: _winnersSwiperData.length,
                      itemBuilder: (context, index) {
                        final entry = _winnersSwiperData[index];
                        final event = entry.key;
                        final winners = entry.value;
                        final title = (event is Map ? event['title'] : null)?.toString() ?? 'Event';
                        final date = (event is Map ? event['event_date'] : null)?.toString() ?? '';
                        return GestureDetector(
                          onTap: () => Get.to(() => EventDetailView(event: event), transition: Transition.rightToLeft),
                          child: Container(
                            width: 260.w,
                            margin: EdgeInsets.only(right: 12.w),
                            padding: EdgeInsets.all(14.w),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.emoji_events, color: const Color(0xFFFF5F15), size: 24.w),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                if (date.isNotEmpty) Text(date, style: TextStyle(fontSize: 11.sp, color: Colors.grey[600])),
                                SizedBox(height: 10.h),
                                ...winners.take(3).map<Widget>((w) {
                                  final pos = (w is Map ? w['position'] : null) ?? 0;
                                  final name = (w is Map ? w['full_name'] : null)?.toString() ?? '—';
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: 4.h),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 20.w,
                                          height: 20.w,
                                          decoration: BoxDecoration(
                                            color: pos == 1 ? const Color(0xFFFFD700) : (pos == 2 ? Colors.grey.shade400 : Colors.brown.shade300),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(child: Text('$pos', style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold))),
                                        ),
                                        SizedBox(width: 8.w),
                                        Expanded(child: Text(name, style: TextStyle(fontSize: 12.sp), overflow: TextOverflow.ellipsis)),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                SizedBox(height: 20.h),
              ],
            ),
          ),

          // Category Filter (Moved here - above All Events)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8.h),
                SizedBox(
                  height: 38.h,
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => SizedBox(width: 12.w),
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final isSelected = selectedCategory == cat;
                      return GestureDetector(
                        onTap: () {
                          setState(() => selectedCategory = cat);
                          controller.fetchEvents(
                            search: searchCtrl.text, 
                            category: cat == "All" ? null : cat
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            gradient: isSelected 
                              ? const LinearGradient(colors: [Color(0xFFFF5F15), Color(0xFFFF9068)])
                              : null,
                            color: isSelected ? null : Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: isSelected ? Colors.transparent : Colors.grey[300]!),
                            boxShadow: isSelected ? [
                              BoxShadow(color: const Color(0xFFFF5F15).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                            ] : null,
                          ),
                          child: Center(
                            child: Text(
                              cat,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey[700],
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                fontSize: 14.sp
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 20.h),
                
                // All Events Header
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Text(
                    "All Events",
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
              ],
            ),
          ),

          // All Events Horizontal Scrollable List
          Obx(() {
            if (controller.isLoading.value) {
              return SliverToBoxAdapter(
                child: SizedBox(
                  height: 300.h,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: Color(0xFFFF5F15)),
                        SizedBox(height: 16.h),
                        Text("Loading events...", style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ),
              );
            }
            if (controller.eventList.isEmpty) {
              return SliverToBoxAdapter(
                child: SizedBox(height: 300.h, child: _buildEmptyState()),
              );
            }

            return SliverToBoxAdapter(
              child: SizedBox(
                height: 350.h,
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  cacheExtent: 200,
                  itemCount: controller.eventList.length,
                  separatorBuilder: (_, __) => SizedBox(width: 16.w),
                  itemBuilder: (context, index) {
                    return RepaintBoundary(child: _AllEventCard(event: controller.eventList[index]));
                  },
                ),
              ),
            );
          }),

          // Bottom padding
          SliverToBoxAdapter(child: SizedBox(height: 30.h)),
        ],
      ),
      )
    );
  }

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(30.w),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.event_busy, size: 70.w, color: Colors.grey[400]),
        ),
        SizedBox(height: 20.h),
        Text("No events found", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.grey[700])),
        SizedBox(height: 8.h),
        Text("Try adjusting your filters", style: TextStyle(color: Colors.grey[500])),
      ],
    ),
  );
}

// --- ALL EVENT CARD (Horizontal Scrollable - Poster Style) ---
class _AllEventCard extends StatelessWidget {
  final dynamic event;
  const _AllEventCard({required this.event});

  Future<bool> _canVolunteerOrParticipate() async {
    try {
      final userId = await PrefService.getUserId();
      if (userId == null) {
        debugPrint("❌ No user ID found");
        return false;
      }
      
      final userResponse = await ApiService.getUserProfile(userId);
      final userIsStudentValue = userResponse.data['data']['is_student'];
      
      // Get organizer's is_student value from event data
      final organizerIsStudentValue = event['organizer_is_student'];
      
      // Convert to int safely, handling both string and int types
      final int userIsStudentInt = userIsStudentValue is String 
          ? int.tryParse(userIsStudentValue) ?? 1 
          : (userIsStudentValue as int? ?? 1);
          
      final int organizerIsStudentInt = organizerIsStudentValue is String 
          ? int.tryParse(organizerIsStudentValue) ?? 1 
          : (organizerIsStudentValue as int? ?? 1);
      
      final bool userIsStudent = userIsStudentInt == 1;
      final bool organizerIsStudent = organizerIsStudentInt == 1;
      
      debugPrint("👤 User is student: $userIsStudent (raw: $userIsStudentValue, converted: $userIsStudentInt)");
      debugPrint("🎯 Organizer is student: $organizerIsStudent (raw: $organizerIsStudentValue, converted: $organizerIsStudentInt)");
      debugPrint("✅ Can volunteer/participate: ${userIsStudent == organizerIsStudent}");
      
      // Return true only if BOTH are students OR BOTH are faculty
      return userIsStudent == organizerIsStudent;
    } catch (e) {
      debugPrint("❌ Error checking permissions: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final EventController controller = Get.find<EventController>();
    final List banners = event['banners'] ?? [];
    final String imageUrl = banners.isNotEmpty 
        ? "https://exdeos.com/AS/campus_social/uploads/events/${banners[0]}" 
        : "";

    return GestureDetector(
      onTap: () => Get.to(() => EventDetailView(event: event), transition: Transition.rightToLeft),
      child: Container(
        width: 280.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 15,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image (Poster)
              imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
              
              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
              
              // Content
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top - Category and Favorite
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Category Badge
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5F15),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                              )
                            ]
                          ),
                          child: Text(
                            event['category'] ?? "Event",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        // Favorite Button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 8,
                              )
                            ]
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.favorite_border, color: Colors.red, size: 20),
                            padding: EdgeInsets.all(8.w),
                            constraints: const BoxConstraints(),
                            onPressed: () => controller.toggleFavorite(event['id'].toString()),
                          ),
                        ),
                      ],
                    ),
                    
                    // Bottom - Event Details
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Event Title
                        Text(
                          event['title'] ?? "Untitled Event",
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 8,
                              )
                            ]
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8.h),
                        
                        // Date
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 14, color: Colors.white70),
                            SizedBox(width: 6.w),
                            Text(
                              event['event_date'] ?? "Date TBD",
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        
                        // Location
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: Colors.white70),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                event['venue'] ?? "Venue TBD",
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: Obx(() {
                                final isJoined = controller.attendingList.any((e) => e['id'].toString() == event['id'].toString());
                                final status = (event['status'] ?? '').toString().toLowerCase();
                                final isApproved = status == 'approved' || status.isEmpty; // Live feed should be approved
                                return ElevatedButton(
                                  onPressed: (!isApproved || isJoined)
                                      ? null
                                      : () => controller.joinEvent(event['id'].toString()),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isJoined ? Colors.grey[300] : Colors.white,
                                    foregroundColor: isJoined ? Colors.grey[600] : const Color(0xFFFF5F15),
                                    disabledBackgroundColor: Colors.grey[300],
                                    disabledForegroundColor: Colors.grey[600],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: EdgeInsets.symmetric(vertical: 8.h),
                                    elevation: isJoined ? 0 : 2,
                                  ),
                                  child: Text(
                                    isJoined ? "Joined" : "Join",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                );
                              }),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              flex: 2, // Give more space to the buttons row
                              child: FutureBuilder<bool>(
                                future: _canVolunteerOrParticipate(),
                                builder: (context, snapshot) {
                                  final canAccess = snapshot.data ?? false;
                                  final isLoading = snapshot.connectionState == ConnectionState.waiting;
                                  
                                  // Don't show buttons at all if user can't access
                                  if (!isLoading && !canAccess) {
                                    return const SizedBox.shrink();
                                  }
                                  
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: Obx(() {
                                          final isVolunteering = controller.volunteeringList.any((e) => e['id'].toString() == event['id'].toString());
                                          final status = (event['status'] ?? '').toString().toLowerCase();
                                          final isApproved = status == 'approved' || status.isEmpty;
                                          return ElevatedButton(
                                            onPressed: (isLoading || isVolunteering || !isApproved)
                                                ? null 
                                                : () {
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) => VolunteerDialog(event: event),
                                                    );
                                                  },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: (isLoading || isVolunteering) 
                                                  ? Colors.grey[300]
                                                  : const Color(0xFFFF5F15),
                                              foregroundColor: (isLoading || isVolunteering)
                                                  ? Colors.grey[600]
                                                  : Colors.white,
                                              disabledBackgroundColor: Colors.grey[300],
                                              disabledForegroundColor: Colors.grey[600],
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              padding: EdgeInsets.symmetric(vertical: 8.h),
                                              elevation: (isLoading || isVolunteering) ? 0 : 2,
                                            ),
                                            child: isLoading
                                                ? SizedBox(
                                                    width: 14,
                                                    height: 14,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
                                                    ),
                                                  )
                                                : Text(
                                                    isVolunteering ? "Volunteered" : "Volunteer",
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                          );
                                        }),
                                      ),
                                      SizedBox(width: 6.w),
                                      Expanded(
                                        child: Obx(() {
                                          final isParticipating = controller.participatingList.any((e) => e['id'].toString() == event['id'].toString());
                                          final status = (event['status'] ?? '').toString().toLowerCase();
                                          final isApproved = status == 'approved' || status.isEmpty;
                                          return ElevatedButton(
                                            onPressed: (isLoading || isParticipating || !isApproved)
                                                ? null 
                                                : () {
                                                    // Show participate confirmation dialog
                                                    ArtSweetAlert.show(
                                                      context: context,
                                                      title: const Text("Participate"),
                                                      content: const Text("Do you want to participate in this event?"),
                                                      type: ArtAlertType.question,
                                                      actions: [
                                                        ArtAlertButton(
                                                          onPressed: () => Navigator.pop(context),
                                                          child: const Text("Cancel"),
                                                          backgroundColor: Colors.grey,
                                                        ),
                                                        ArtAlertButton(
                                                          onPressed: () {
                                                            Navigator.pop(context);
                                                            controller.participate(event['id'].toString());
                                                          },
                                                          child: const Text("Yes"),
                                                          backgroundColor: const Color(0xFFFF5F15),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: (isLoading || isParticipating) 
                                                  ? Colors.grey[300]
                                                  : const Color(0xFF4CAF50), // Blue color to differentiate
                                              foregroundColor: (isLoading || isParticipating)
                                                  ? Colors.grey[600]
                                                  : Colors.white,
                                              disabledBackgroundColor: Colors.grey[300],
                                              disabledForegroundColor: Colors.grey[600],
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              padding: EdgeInsets.symmetric(vertical: 8.h),
                                              elevation: (isLoading || isParticipating) ? 0 : 2,
                                            ),
                                            child: isLoading
                                                ? SizedBox(
                                                    width: 14,
                                                    height: 14,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
                                                    ),
                                                  )
                                                : Text(
                                                    isParticipating ? "Participating" : "Participate",
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                          );
                                        }),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
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
      ),
    );
  }

  Widget _buildPlaceholder() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          const Color(0xFFFF5F15).withOpacity(0.3), 
          const Color(0xFFFF9068).withOpacity(0.3)
        ],
      ),
    ),
    child: const Center(child: Icon(Icons.event, size: 80, color: Colors.white))
  );
}

// --- FEATURED EVENT CARD (Slider) ---
class _FeaturedEventCard extends StatelessWidget {
  final dynamic event;
  const _FeaturedEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final List banners = event['banners'] ?? [];
    final String imageUrl = banners.isNotEmpty 
        ? "https://exdeos.com/AS/campus_social/uploads/events/${banners[0]}" 
        : "";

    return GestureDetector(
      onTap: () => Get.to(() => EventDetailView(event: event), transition: Transition.rightToLeft),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 5.w),
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
              imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
              
              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
              
              // Content
              Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5F15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        event['category'] ?? "Event",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    
                    // Event Title
                    Text(
                      event['title'] ?? "Untitled Event",
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h),
                    
                    // Date & Location
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Colors.white70),
                        SizedBox(width: 6.w),
                        Text(
                          event['event_date'] ?? "Date TBD",
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.white70),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            event['venue'] ?? "Venue TBD",
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [const Color(0xFFFF5F15).withOpacity(0.3), const Color(0xFFFF9068).withOpacity(0.3)],
      ),
    ),
    child: const Center(child: Icon(Icons.event, size: 80, color: Colors.white))
  );
}
// --- Certificates tab (user-wise, from My Events) ---
class _CertificatesTab extends StatefulWidget {
  const _CertificatesTab();

  @override
  State<_CertificatesTab> createState() => _CertificatesTabState();
}

class _CertificatesTabState extends State<_CertificatesTab> {
  List<dynamic> _list = [];
  bool _loading = true;
  String? _error;

  Future<void> _load() async {
    final userId = await PrefService.getUserId();
    if (userId == null) {
      setState(() { _loading = false; _error = 'Please log in.'; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final response = await ApiService.getCertificatesByUserId(userId);
      final data = response.data;
      if (data is Map && data['status'] == 'success') {
        final raw = data['data'];
        final list = raw is List ? raw : <dynamic>[];
        setState(() { _list = list; _loading = false; _error = null; });
      } else {
        final msg = (data is Map ? data['message'] : null)?.toString();
        setState(() { _list = []; _loading = false; _error = msg; });
      }
    } catch (e) {
      setState(() { _list = []; _loading = false; _error = 'Network error.'; });
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFFFF5F15)),
          SizedBox(height: 16.h),
          Text("Loading certificates...", style: TextStyle(color: Colors.grey[600])),
        ],
      ));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64.w, color: Colors.grey),
              SizedBox(height: 16.h),
              Text(_error!, textAlign: TextAlign.center),
              SizedBox(height: 16.h),
              ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5F15), foregroundColor: Colors.white), child: const Text("Retry")),
            ],
          ),
        ),
      );
    }
    if (_list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_membership, size: 80.w, color: Colors.grey[300]),
            SizedBox(height: 16.h),
            Text("No certificates yet", style: TextStyle(fontSize: 16.sp, color: Colors.grey[600])),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Text("Certificates for past events are uploaded by admin. You will see them here when available.", textAlign: TextAlign.center, style: TextStyle(fontSize: 13.sp, color: Colors.grey[500])),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFFFF5F15),
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        cacheExtent: 200,
        itemCount: _list.length,
        itemBuilder: (context, index) {
          final c = _list[index];
          final eventTitle = (c is Map ? c['event_title'] : null)?.toString() ?? 'Event';
          final eventDate = (c is Map ? c['event_date'] : null)?.toString() ?? '';
          final type = (c is Map ? c['type'] : null)?.toString() ?? 'certificate';
          final filePath = (c is Map ? c['file_path'] : null)?.toString() ?? '';
          final path = filePath.startsWith('http') ? filePath : filePath.replaceFirst(RegExp(r'^certificates[/\\]'), '');
          final url = filePath.startsWith('http') ? filePath : '${Constant.uploadsBaseUrl}${Constant.certificatesPath}$path';
          return Card(
            margin: EdgeInsets.only(bottom: 12.h),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              leading: CircleAvatar(backgroundColor: const Color(0xFFFF5F15).withOpacity(0.2), child: const Icon(Icons.card_membership, color: Color(0xFFFF5F15))),
              title: Text(eventTitle, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp)),
              subtitle: Text('${type.toUpperCase()} • $eventDate', style: TextStyle(fontSize: 12.sp, color: Colors.grey[600])),
              trailing: const Icon(Icons.open_in_new),
              onTap: () async {
                final uri = Uri.tryParse(url);
                if (uri != null) {
                  try {
                    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } catch (_) {
                    SweetAlertHelper.showError(context, "Certificate", "Could not open link.");
                  }
                }
              },
            ),
          );
        },
      ),
    );
  }
}

// --- MY EVENTS TAB ---
class _MyEventsTab extends StatelessWidget {
  final int initialIndex;
  const _MyEventsTab({this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 7,
      initialIndex: initialIndex.clamp(0, 6),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FD),
        appBar: AppBar(
          title: const Text("My Activity", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: TabBar(
            labelColor: const Color(0xFFFF5F15),
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: const Color(0xFFFF5F15),
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            isScrollable: true,
            tabs: const [
              Tab(text: "Attending"),
              Tab(text: "Hosting"),
              Tab(text: "I can edit"),
              Tab(text: "Volunteering"),
              Tab(text: "Participating"),
              Tab(text: "Favorites"),
              Tab(text: "Certificates"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _EventListWidget(type: 'attending'),
            _EventListWidget(type: 'hosted'),
            _EventListWidget(type: 'editing'),
            _EventListWidget(type: 'volunteering'),
            _EventListWidget(type: 'participating'),
            const FavoritesView(),
            const _CertificatesTab(),
          ],
        ),
      ),
    );
  }
}

// Replace the _EventListWidget class with this version

class _EventListWidget extends StatefulWidget {
  final String type;
  const _EventListWidget({required this.type});

  @override
  State<_EventListWidget> createState() => _EventListWidgetState();
}

class _EventListWidgetState extends State<_EventListWidget> with AutomaticKeepAliveClientMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _hasInitialized = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    
    final EventController controller = Get.find<EventController>();
    switch(widget.type) {
      case 'attending':
        await controller.fetchAttendingEvents();
        break;
      case 'hosted':
        await controller.fetchHostedEvents();
        break;
      case 'editing':
        await controller.fetchEditingEvents();
        break;
      case 'volunteering':
        await controller.fetchVolunteeringEvents();
        break;
      case 'participating':
        await controller.fetchParticipatingEvents();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    final EventController controller = Get.find<EventController>();
    
    // Fetch data only once
    if (!_hasInitialized) {
      _hasInitialized = true;
      Future.microtask(() => _fetchData());
    }
    
    return Obx(() {
      // ... rest of the build method stays exactly the same
      List<dynamic> eventsList = [];
      String emptyMessage = "";
      IconData emptyIcon = Icons.event_available;
      
      switch(widget.type) {
        case 'attending':
          eventsList = controller.attendingList;
          emptyMessage = "You haven't joined any events yet";
          emptyIcon = Icons.event_available;
          break;
        case 'hosted':
          eventsList = controller.hostedList;
          emptyMessage = "You haven't hosted any events yet";
          emptyIcon = Icons.event_note;
          break;
        case 'editing':
          eventsList = controller.editingList;
          emptyMessage = "No events shared with you for editing yet. When an admin grants you permission to edit an event, it will appear here.";
          emptyIcon = Icons.edit_note;
          break;
        case 'volunteering':
          eventsList = controller.volunteeringList;
          emptyMessage = "You haven't volunteered for any events yet";
          emptyIcon = Icons.volunteer_activism;
          break;
        case 'participating':
          eventsList = controller.participatingList;
          emptyMessage = "You haven't participated in any events yet";
          emptyIcon = Icons.groups;
          break;
      }
      
      if (controller.isLoading.value) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFFFF5F15)),
              SizedBox(height: 16.h),
              Text(
                "Loading events...",
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        );
      }
      
      if (eventsList.isEmpty) {
        return Center(
          child: Padding(
            padding: EdgeInsets.all(40.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(emptyIcon, size: 80.w, color: Colors.grey[300]),
                SizedBox(height: 20.h),
                Text(
                  emptyMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
                ),
                SizedBox(height: 16.h),
                ElevatedButton.icon(
                  onPressed: _fetchData,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Refresh"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5F15),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // --- Hosted events: show Approved vs Pending sections ---
      if (widget.type == 'hosted') {
        final approved = eventsList
            .where((e) => (e is Map ? e['status'] : null)?.toString().toLowerCase() == 'approved')
            .toList();
        final nonApproved = eventsList
            .where((e) => (e is Map ? e['status'] : null)?.toString().toLowerCase() != 'approved')
            .toList();

        Widget buildSection({
          required String title,
          required Color chipColor,
          required List<dynamic> items,
        }) {
          if (items.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                child: Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: chipColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: chipColor.withOpacity(0.35)),
                      ),
                      child: Text(
                        "${items.length}",
                        style: TextStyle(
                          color: chipColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: items.length,
                separatorBuilder: (_, __) => SizedBox(height: 10.h),
                itemBuilder: (context, index) {
                  return _HostedEventTile(event: items[index]);
                },
              ),
            ],
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _fetchData(),
          color: const Color(0xFFFF5F15),
          child: ListView(
            padding: EdgeInsets.only(bottom: 24.h),
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            cacheExtent: 300,
            children: [
              buildSection(
                title: "Pending",
                chipColor: Colors.orange,
                items: nonApproved,
              ),
              buildSection(
                title: "Approved",
                chipColor: Colors.green,
                items: approved,
              ),
              if (approved.isEmpty && nonApproved.isEmpty)
                Padding(
                  padding: EdgeInsets.all(40.w),
                  child: Center(
                    child: Text(
                      emptyMessage,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
            ],
          ),
        );
      }
      
      final totalPages = (eventsList.length / 4).ceil();
      
      return RefreshIndicator(
        onRefresh: () async => _fetchData(),
        color: const Color(0xFFFF5F15),
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  if (mounted) {
                    setState(() {
                      _currentPage = index;
                    });
                  }
                },
                itemCount: totalPages,
                itemBuilder: (context, pageIndex) {
                  final startIndex = pageIndex * 4;
                  final endIndex = (startIndex + 4).clamp(0, eventsList.length);
                  final pageEvents = eventsList.sublist(startIndex, endIndex);
                  
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                    child: Column(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              if (pageEvents.isNotEmpty)
                                Expanded(child: _EventCard(event: pageEvents[0]))
                              else
                                Expanded(child: Container()),
                              SizedBox(width: 12.w),
                              if (pageEvents.length > 1)
                                Expanded(child: _EventCard(event: pageEvents[1]))
                              else
                                Expanded(child: Container()),
                            ],
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Expanded(
                          child: Row(
                            children: [
                              if (pageEvents.length > 2)
                                Expanded(child: _EventCard(event: pageEvents[2]))
                              else
                                Expanded(child: Container()),
                              SizedBox(width: 12.w),
                              if (pageEvents.length > 3)
                                Expanded(child: _EventCard(event: pageEvents[3]))
                              else
                                Expanded(child: Container()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            if (totalPages > 1) ...[
              Container(
                padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 20.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Center(
                        child: Wrap(
                          spacing: 8.w,
                          alignment: WrapAlignment.center,
                          children: List.generate(
                            totalPages,
                            (index) => GestureDetector(
                              onTap: () {
                                _pageController.animateToPage(
                                  index,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: index == _currentPage ? 24.w : 8.w,
                                height: 8.w,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: index == _currentPage
                                      ? const Color(0xFFFF5F15)
                                      : Colors.grey[300],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}

// --- PROFILE TAB ---

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  Future<void> _refreshProfile() async {
    final ProfileController controller = Get.find<ProfileController>();
    final EventController eventController = Get.find<EventController>();
    
    await Future.wait([
      controller.loadProfile(),
      eventController.fetchHostedEvents(),
      eventController.fetchFavorites(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final ProfileController controller = Get.find<ProfileController>();
    final EventController eventController = Get.find<EventController>();
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFF5F15)));
        }
        
        final user = controller.userData.value;
        return RefreshIndicator(
          onRefresh: _refreshProfile,
          color: const Color(0xFFFF5F15),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            cacheExtent: 300,
            slivers: [
            SliverAppBar(
              expandedHeight: 50.h,
              floating: false,
              pinned: true,
              backgroundColor: const Color(0xFFFF5F15),

              leadingWidth: 80, // enough space for logo
              leading: Padding(
                padding: const EdgeInsets.all(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/logo.jpeg',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) {
                        return const Icon(
                          Icons.event,
                          color: Color(0xFFFF5F15),
                          size: 26,
                        );
                      },
                    ),
                  ),
                ),
              ),

              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF5F15), Color(0xFFFF9068)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),

              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 22),
                  onPressed: () => Get.to(
                    () => const EditProfileView(),
                    transition: Transition.rightToLeft,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_outlined, color: Colors.white, size: 22),
                  onPressed: () {
                    ArtSweetAlert.show(
                      context: context,
                      title: const Text("Logout"),
                      content: const Text("Are you sure you want to logout?"),
                      type: ArtAlertType.warning,
                      actions: [
                        ArtAlertButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                          backgroundColor: Colors.grey,
                        ),
                        ArtAlertButton(
                          onPressed: () {
                            Navigator.pop(context);
                            authController.logout();
                          },
                          child: const Text("Yes"),
                          backgroundColor: const Color(0xFFFF5F15),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    SizedBox(height: 10.h),
                    
                    // Profile Card - existing code
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 20.w),
                      padding: EdgeInsets.all(24.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 4)
                          )
                        ]
                      ),
                      child: Column(
                        children: [
                        // Avatar with gradient border
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF5F15), Color(0xFFFF9068)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF5F15).withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8)
                              )
                            ]
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(3),
                            child: CircleAvatar(
                              radius: 50.w,
                              backgroundColor: Colors.grey[100],
                              backgroundImage: user.image != null && user.image!.isNotEmpty 
                                ? NetworkImage("https://exdeos.com/AS/campus_social/uploads/profiles/${user.image}") 
                                : null,
                              child: user.image == null || user.image!.isEmpty 
                                ? Icon(Icons.person, size: 50.w, color: const Color(0xFFFF5F15)) 
                                : null,
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 16.h),
                        
                        Text(
                          user.fullName ?? "Guest User", 
                          style: TextStyle(
                            fontSize: 22.sp, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.black87
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        SizedBox(height: 8.h),
                        
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5F15).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.email_outlined, size: 14, color: const Color(0xFFFF5F15)),
                              SizedBox(width: 6.w),
                              Flexible(
                                child: Text(
                                  user.email ?? "", 
                                  style: TextStyle(
                                    color: const Color(0xFFFF5F15), 
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 20.h),
                  
                  // Stats Card
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 20.w),
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 4)
                          )
                        ]
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            Icons.event_rounded, 
                            eventController.hostedList.length.toString(), 
                            "Hosted"
                          ),
                          _buildDivider(),
                          _buildStatItem(
                            Icons.people_rounded, 
                            eventController.attendingList.length.toString(), 
                            "Attending"
                          ),
                          _buildDivider(),
                          _buildStatItem(
                            Icons.volunteer_activism, // Changed icon
                            eventController.volunteeringList.length.toString(), 
                            "Volunteer" // Changed label
                          ),
                          _buildDivider(),
                          _buildStatItem(
                            Icons.groups, // New stat
                            eventController.participatingList.length.toString(), 
                            "Participate" // New label
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: 20.h),
                  
                  // About Me Section
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20.w),
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 4)
                        )
                      ]
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF5F15).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.person_outline, color: Color(0xFFFF5F15), size: 20),
                            ),
                            SizedBox(width: 12.w),
                            Text("About Me", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          user.bio ?? "No bio added yet. Tap edit to add one!", 
                          style: TextStyle(
                            color: user.bio != null ? Colors.grey[700] : Colors.grey[400],
                            height: 1.5,
                            fontSize: 14.sp,
                            fontStyle: user.bio != null ? FontStyle.normal : FontStyle.italic,
                          )
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 20.h),
                  
                  // Interests Section
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20.w),
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 4)
                        )
                      ]
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF5F15).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.interests_outlined, color: Color(0xFFFF5F15), size: 20),
                            ),
                            SizedBox(width: 12.w),
                            Text("Interests", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        user.interests != null && user.interests!.isNotEmpty
                          ? Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: user.interests!.split(',')
                                .map((e) => Container(
                                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFFFF5F15).withOpacity(0.1),
                                        const Color(0xFFFF9068).withOpacity(0.1)
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFFFF5F15).withOpacity(0.2),
                                      width: 1
                                    )
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFFF5F15),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      SizedBox(width: 6.w),
                                      Text(
                                        e.trim(),
                                        style: const TextStyle(
                                          color: Color(0xFFFF5F15),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                                .toList(),
                            )
                          : Text(
                              "No interests added yet. Tap edit to add some!",
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14.sp,
                                fontStyle: FontStyle.italic,
                              )
                            ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 100.h),
                ],
              ),
            ),
          ],
          )
        );
      }),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF5F15), Color(0xFFFF9068)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF5F15).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4)
              )
            ]
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        SizedBox(height: 10.h),
        Text(value, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: const Color(0xFFFF5F15))),
        SizedBox(height: 4.h),
        Text(label, style: TextStyle(fontSize: 11.sp, color: Colors.grey[600], fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 50.h, color: Colors.grey[200]);
  }
}

// --- EVENT CARD WIDGET ---
class _EventCard extends StatelessWidget {
  final dynamic event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final EventController controller = Get.find<EventController>();
    final List banners = event['banners'] ?? [];
    final String imageUrl = banners.isNotEmpty 
        ? "https://exdeos.com/AS/campus_social/uploads/events/${banners[0]}" 
        : "";

    return GestureDetector(
      onTap: () => Get.to(() => EventDetailView(event: event), transition: Transition.rightToLeft),
      child: Container(
        margin: EdgeInsets.zero,
        height: 350.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
              
              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
              
              // Content
              Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top - Category and Favorite
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5F15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            event['category'] ?? "Event",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 8,
                              )
                            ]
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.favorite_border, color: Colors.red, size: 20),
                            padding: EdgeInsets.all(8.w),
                            constraints: const BoxConstraints(),
                            onPressed: () => controller.toggleFavorite(event['id'].toString()),
                          ),
                        ),
                      ],
                    ),
                    
                    // Bottom - Event Details
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event['title'] ?? "Untitled Event",
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 6.h),
                        
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 12, color: Colors.white70),
                            SizedBox(width: 4.w),
                            Expanded(
                              child: Text(
                                event['event_date'] ?? "Date TBD",
                                style: const TextStyle(color: Colors.white70, fontSize: 10),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 3.h),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 12, color: Colors.white70),
                            SizedBox(width: 4.w),
                            Expanded(
                              child: Text(
                                event['venue'] ?? "Venue TBD",
                                style: const TextStyle(color: Colors.white70, fontSize: 10),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
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
      ),
    );
  }

  Widget _buildPlaceholder() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [const Color(0xFFFF5F15).withOpacity(0.3), const Color(0xFFFF9068).withOpacity(0.3)],
      ),
    ),
    child: const Center(child: Icon(Icons.event, size: 80, color: Colors.white))
  );
}

class _HostedEventTile extends StatelessWidget {
  final dynamic event;
  const _HostedEventTile({required this.event});

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'hold':
        return Colors.blueGrey;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'pending':
        return 'Pending';
      case 'hold':
        return 'On Hold';
      case 'rejected':
        return 'Rejected';
      default:
        return status.isEmpty ? 'Pending' : status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final EventController controller = Get.find<EventController>();
    final status = (event is Map ? event['status'] : null)?.toString().toLowerCase() ?? '';
    final canEditDelete = status == 'pending';

    return InkWell(
      onTap: () => Get.to(() => EventDetailView(event: event), transition: Transition.rightToLeft),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 54.w,
              height: 54.w,
              decoration: BoxDecoration(
                color: const Color(0xFFFF5F15).withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.event, color: Color(0xFFFF5F15)),
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
                          (event is Map ? event['title'] : null)?.toString() ?? "Untitled Event",
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: _statusColor(status).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _statusColor(status).withOpacity(0.35)),
                        ),
                        child: Text(
                          _statusLabel(status),
                          style: TextStyle(
                            color: _statusColor(status),
                            fontWeight: FontWeight.w700,
                            fontSize: 11.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    (event is Map ? event['event_date'] : null)?.toString() ?? "",
                    style: TextStyle(color: Colors.grey[700], fontSize: 12.sp),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    (event is Map ? event['venue'] : null)?.toString() ?? "",
                    style: TextStyle(color: Colors.grey[700], fontSize: 12.sp),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            if (canEditDelete)
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit') {
                    Get.to(
                      () => CreateEventView(existingEvent: event),
                      transition: Transition.rightToLeft,
                    );
                  } else if (value == 'delete') {
                    ArtSweetAlert.show(
                      context: context,
                      title: const Text("Delete Event?"),
                      content: const Text("You can delete only pending events. Continue?"),
                      type: ArtAlertType.warning,
                      actions: [
                        ArtAlertButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                          backgroundColor: Colors.grey,
                        ),
                        ArtAlertButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await controller.deleteHostedEvent(event: event);
                          },
                          child: const Text("Delete"),
                          backgroundColor: Colors.red,
                        ),
                      ],
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
                icon: Icon(Icons.more_vert, color: Colors.grey[700]),
              )
            else
              Icon(Icons.lock_outline, color: Colors.grey[500], size: 20),
          ],
        ),
      ),
    );
  }
}