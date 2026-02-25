import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/event_controller.dart';
import '../controllers/profile_controller.dart';
import 'create_event_view.dart';
import 'event_detail_view.dart';
import 'favorites_view.dart';
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

  // Add refresh method
  Future<void> _refreshData() async {
    await controller.fetchEvents(
      search: searchCtrl.text.isEmpty ? null : searchCtrl.text,
      category: selectedCategory == "All" ? null : selectedCategory
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: const Color(0xFFFF5F15),
      child: SafeArea(
        child: CustomScrollView(
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
                      IconButton(
                        icon: const Icon(Icons.favorite_outline, color: Colors.white),
                        onPressed: () => Get.to(() => const FavoritesView(), transition: Transition.rightToLeft),
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
                    onChanged: (val) => controller.fetchEvents(
                      search: val, 
                      category: selectedCategory == "All" ? null : selectedCategory
                    ),
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
                  itemCount: controller.eventList.length,
                  separatorBuilder: (_, __) => SizedBox(width: 16.w),
                  itemBuilder: (context, index) {
                    return _AllEventCard(event: controller.eventList[index]);
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
                                                    Get.defaultDialog(
                                                      title: "Participate",
                                                      middleText: "Do you want to participate in this event?",
                                                      textConfirm: "Yes",
                                                      textCancel: "Cancel",
                                                      confirmTextColor: Colors.white,
                                                      buttonColor: const Color(0xFFFF5F15),
                                                      cancelTextColor: Colors.grey[700],
                                                      onConfirm: () {
                                                        Get.back();
                                                        controller.participate(event['id'].toString());
                                                      },
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
// --- MY EVENTS TAB ---
class _MyEventsTab extends StatelessWidget {
  final int initialIndex;
  const _MyEventsTab({this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5, // CHANGED FROM 4 TO 5
      initialIndex: initialIndex.clamp(0, 4),
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
              Tab(text: "Volunteering"),
              Tab(text: "Participating"),
              Tab(text: "Favorites"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _EventListWidget(type: 'attending'),
            _EventListWidget(type: 'hosted'),
            _EventListWidget(type: 'volunteering'),
            _EventListWidget(type: 'participating'),
            const FavoritesView(),
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

    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshProfile());

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
                    Get.defaultDialog(
                      title: "Logout",
                      middleText: "Are you sure you want to logout?",
                      textConfirm: "Yes",
                      textCancel: "Cancel",
                      confirmTextColor: Colors.white,
                      buttonColor: const Color(0xFFFF5F15),
                      cancelTextColor: Colors.grey[700],
                      onConfirm: () {
                        Get.back();
                        authController.logout();
                      },
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
                    Get.defaultDialog(
                      title: "Delete Event?",
                      middleText: "You can delete only pending events. Continue?",
                      textConfirm: "Delete",
                      textCancel: "Cancel",
                      confirmTextColor: Colors.white,
                      buttonColor: Colors.red,
                      onConfirm: () async {
                        Get.back();
                        await controller.deleteHostedEvent(event: event);
                      },
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