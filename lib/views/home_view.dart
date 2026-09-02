import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:art_sweetalert_new/art_sweetalert_new.dart';
import '../base/constant.dart';
import '../controllers/auth_controller.dart';
import '../controllers/event_controller.dart';
import '../services/deep_link_service.dart';
import '../controllers/inbox_notification_controller.dart';
import '../controllers/profile_controller.dart';
import '../utils/certificate_helper.dart';
import '../utils/registration_deadline_helper.dart';
import '../utils/winner_feed_helper.dart';
import 'create_event_view.dart';
import 'event_detail_view.dart';
import 'favorites_view.dart';
import 'notifications_view.dart';
import 'winners_view.dart';
import 'edit_profile_view.dart';
import 'volunteer_dialog.dart';
import '../data/api_service.dart';
import '../data/app_branding.dart';
import '../data/app_bootstrap.dart';
import '../data/pref_service.dart';
import '../utils/app_navigation.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_loading_screen.dart';
import '../widgets/app_network_image.dart';
import '../widgets/home_ad_carousel.dart';
import '../widgets/winner_photos_carousel.dart';
import '../theme/app_theme.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/event_list_skeleton.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/ticket_event_card.dart';
import '../widgets/app_calendar_theme.dart';
import '../widgets/campus_app_bar.dart';
import '../widgets/participate_registration_sheet.dart';
import '../utils/event_participation_rules.dart';

/// Decode network posters at a capped pixel width for smoother lists/carousel (same on-screen layout).
int _eventPosterCacheWidth(BuildContext context, double widthFraction) {
  final logicalW = MediaQuery.sizeOf(context).width * widthFraction;
  final px = (logicalW * MediaQuery.devicePixelRatioOf(context)).round();
  return px.clamp(280, 1400);
}

void _openEventDetail(dynamic event) {
  AppNavigation.to(
    () => EventDetailView(event: event),
    prepare: (ctx) => AppBootstrap.prepareEventDetail(ctx, event),
    loadingMessage: 'Loading event...',
  );
}

void _openWinners() {
  AppNavigation.to(
    () => const WinnersView(),
    prepare: AppBootstrap.prepareWinners,
    loadingMessage: 'Loading winners...',
  );
}

void _openCreateEvent() {
  AppNavigation.to(
    () => const CreateEventView(),
    prepare: AppBootstrap.prepareCreateEvent,
    loadingMessage: 'Loading...',
  );
}

void _openEditProfile() {
  AppNavigation.to(
    () => const EditProfileView(),
    prepare: AppBootstrap.prepareEditProfile,
    loadingMessage: 'Loading profile...',
  );
}

/// Readable date/venue on cards when poster or API uses placeholder text.
String _cardEventDateLine(dynamic raw, [dynamic endRaw]) {
  final s = (raw ?? '').toString().trim();
  if (s.isEmpty) return 'Date TBD';
  final lower = s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  if (lower == 'date' || lower == 'date: date' || lower == 'date : date') return 'Date TBD';
  final endStr = (endRaw ?? '').toString().trim();
  if (endStr.isEmpty || endStr == '0000-00-00 00:00:00') return s;
  final startDt = DateTime.tryParse(s.replaceAll(' ', 'T'));
  final endDt = DateTime.tryParse(endStr.replaceAll(' ', 'T'));
  if (startDt == null || endDt == null) return s;
  final df = DateFormat('dd MMM yyyy');
  final tf = DateFormat('hh:mm a');
  if (startDt.year == endDt.year && startDt.month == endDt.month && startDt.day == endDt.day) {
    return '${df.format(startDt)}, ${tf.format(startDt)} - ${tf.format(endDt)}';
  }
  return '${df.format(startDt)} - ${df.format(endDt)}';
}

String _cardVenueLine(dynamic raw) {
  final s = (raw ?? '').toString().trim();
  if (s.isEmpty) return 'Venue TBD';
  final lower = s.toLowerCase();
  if (lower == 'location' || lower == 'location:' || lower == 'venue' || lower == 'venue:') return 'Venue TBD';
  return s;
}

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
  /// Visual bottom-nav index: 0 Explore, 1 My Events, 3 Notifications, 4 Profile (2 = Host action).
  late int _navIndex;
  late List<Widget> _tabs;

  final AuthController authController = Get.put(AuthController());
  late final EventController eventController;
  final InboxNotificationController inboxController = Get.put(InboxNotificationController(), permanent: true);

  /// Maps visual nav index → IndexedStack index (Host has no page).
  int get _stackIndex {
    switch (_navIndex) {
      case 0:
        return 0;
      case 1:
        return 1;
      case 3:
        return 2;
      case 4:
        return 3;
      default:
        return 0;
    }
  }

  /// Opens My Activity (bottom nav) on a specific sub-tab.
  /// 0 Viewing, 1 Hosting, 2 I can edit, 3 Volunteering, 4 Participating, 5 Favorites, 6 Certificates.
  void openMyActivityTab(int myEventsTabIndex) {
    final idx = myEventsTabIndex.clamp(0, 6);
    setState(() {
      _navIndex = 1;
      _tabs = [
        const _ExploreTab(),
        _MyEventsTab(key: ValueKey('my_events_$idx'), initialIndex: idx),
        const NotificationsView(asTab: true),
        const _ProfileTab(),
      ];
    });
  }

  @override
  void initState() {
    super.initState();
    eventController = AppBootstrap.ensureEventController();
    // Legacy initialBottomTabIndex: 0 Explore, 1 My Events, 2 Profile.
    final initial = widget.initialBottomTabIndex.clamp(0, 2);
    _navIndex = initial == 2 ? 4 : initial;
    final myIdx = widget.initialMyEventsTabIndex.clamp(0, 6);
    _tabs = [
      const _ExploreTab(),
      _MyEventsTab(key: ValueKey('my_events_$myIdx'), initialIndex: myIdx),
      const NotificationsView(asTab: true),
      const _ProfileTab(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinkService.instance.tryNavigateToPendingEvent();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: IndexedStack(
        index: _stackIndex,
        sizing: StackFit.expand,
        children: _tabs,
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _navIndex,
        onTap: (i) {
          if (i == 2) return;
          setState(() => _navIndex = i);
        },
        onHostTap: _openCreateEvent,
      ),
    );
  }
}

Future<void> _openMicampusWebsite(BuildContext context) async {
  final uri = Uri.parse(Constant.websiteUrl);
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open micampus.co.in')),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open micampus.co.in')),
      );
    }
  }
}

/// Explore header marks on the gradient - no filled plate behind the artwork.

enum _BrowseDatePreset { any, next7, next15, thisMonth, custom }

// --- EXPLORE TAB ---
class _ExploreTab extends StatefulWidget {
  const _ExploreTab();

  @override
  State<_ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<_ExploreTab> with AutomaticKeepAliveClientMixin {
  late final EventController controller;
  final TextEditingController searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  /// Category filter for "Live today" only (featured carousel ignores this).
  String liveTodayCategory = "All";
  /// Category + date range for upcoming list (and search bar).
  String browseCategory = "All";
  _BrowseDatePreset _browsePreset = _BrowseDatePreset.any;
  DateTime? _browseCustomStart;
  DateTime? _browseCustomEnd;
  final List<String> categories = ["All", "IT/Tech", "Cultural", "Sports", "Academic", "Social"];
  List<Map<String, dynamic>> _adPosts = [];
  List<Map<String, dynamic>> _winnerPhotos = [];
  Timer? _exploreSearchDebounce;

  @override
  bool get wantKeepAlive => true;

  Future<void> _refreshData() async {
    await Future.wait([
      controller.fetchLiveEventCatalog(),
      _loadAdPosts(),
      _loadWinnerPhotos(),
      AppBranding.refresh(),
    ]);
    if (mounted) setState(() {});
  }

  Future<void> _loadAdPosts() async {
    try {
      final r = await ApiService.getAdPosts();
      final m = ApiService.responseDataMap(r.data);
      if (m == null || m['status']?.toString() != 'success') return;
      final list = m['data'];
      if (list is! List) return;
      final next = <Map<String, dynamic>>[];
      for (final e in list) {
        if (e is Map<String, dynamic>) {
          next.add(e);
        } else if (e is Map) {
          next.add(Map<String, dynamic>.from(e.map((k, v) => MapEntry(k.toString(), v))));
        }
      }
      if (mounted) setState(() => _adPosts = next);
    } catch (_) {}
  }

  Future<void> _loadWinnerPhotos() async {
    try {
      final next = await WinnerFeedHelper.loadCarouselPhotos(limit: 20);
      debugPrint('[Explore] winner carousel items=${next.length}');
      if (mounted) setState(() => _winnerPhotos = next);
    } catch (e, st) {
      debugPrint('[Explore] winner carousel load failed: $e\n$st');
      if (mounted) setState(() => _winnerPhotos = []);
    }
  }

  @override
  void initState() {
    super.initState();
    controller = AppBootstrap.ensureEventController();
    // Paint Explore shell immediately. Catalog already loads from
    // EventController.onInit; ads are secondary chrome.
    if (controller.liveEventCatalog.isEmpty && !controller.isLoading.value) {
      unawaited(controller.fetchLiveEventCatalog());
    }
    unawaited(_loadAdPosts());
    unawaited(_loadWinnerPhotos());
  }

  @override
  void dispose() {
    _exploreSearchDebounce?.cancel();
    searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  DateTime? _eventDateOnly(dynamic event) {
    final s = (event is Map ? event['event_date'] : null)?.toString();
    if (s == null || s.isEmpty) return null;
    final d = DateTime.tryParse(s.replaceAll(' ', 'T'));
    if (d == null) return null;
    return DateTime(d.year, d.month, d.day);
  }

  bool _exploreApproved(dynamic e) {
    final st = (e is Map ? e['status'] : null)?.toString().toLowerCase() ?? '';
    if (st == 'closed') return false;
    return st == 'approved' || st.isEmpty;
  }

  bool _isLiveTodayEvent(dynamic e) {
    if (!_exploreApproved(e)) return false;
    final ed = _eventDateOnly(e);
    if (ed == null) return false;
    final n = DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    return ed.year == today.year && ed.month == today.month && ed.day == today.day;
  }

  /// Featured slider: "Registration open" when the event is not on today's date (and not already past).
  bool _showRegistrationOpenTagForFeatured(dynamic e) {
    if (!_exploreApproved(e)) return false;
    if (_isLiveTodayEvent(e)) return false;
    final ed = _eventDateOnly(e);
    if (ed == null) return true;
    final n = DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    return !ed.isBefore(today);
  }

  bool _isUpcomingFutureDay(dynamic e) {
    if (!_exploreApproved(e)) return false;
    final ed = _eventDateOnly(e);
    if (ed == null) return false;
    final n = DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    return ed.isAfter(today);
  }

  /// Today or later (used when the search box is non-empty so same-day events are not excluded).
  bool _categoryMatch(dynamic e, String selected) {
    if (selected == "All") return true;
    final c = (e is Map ? e['category'] : null)?.toString() ?? '';
    return c == selected;
  }

  (DateTime, DateTime)? _browseRangeBounds() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_browsePreset) {
      case _BrowseDatePreset.any:
        return null;
      case _BrowseDatePreset.next7:
        return (today, today.add(const Duration(days: 6)));
      case _BrowseDatePreset.next15:
        return (today, today.add(const Duration(days: 14)));
      case _BrowseDatePreset.thisMonth:
        final start = DateTime(today.year, today.month, 1);
        final end = DateTime(today.year, today.month + 1, 0);
        return (start, end);
      case _BrowseDatePreset.custom:
        if (_browseCustomStart == null || _browseCustomEnd == null) return null;
        final a = DateTime(_browseCustomStart!.year, _browseCustomStart!.month, _browseCustomStart!.day);
        final b = DateTime(_browseCustomEnd!.year, _browseCustomEnd!.month, _browseCustomEnd!.day);
        if (a.isAfter(b)) return (b, a);
        return (a, b);
    }
  }

  bool _browseRangeMatch(dynamic e) {
    final bounds = _browseRangeBounds();
    if (bounds == null) return true;
    final ed = _eventDateOnly(e);
    if (ed == null) return false;
    return !ed.isBefore(bounds.$1) && !ed.isAfter(bounds.$2);
  }

  Future<void> _pickCustomBrowseRange() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final range = await showDateRangePicker(
      context: context,
      firstDate: today.subtract(const Duration(days: 365)),
      lastDate: DateTime(now.year + 3),
      initialDateRange: _browseCustomStart != null && _browseCustomEnd != null
          ? DateTimeRange(start: _browseCustomStart!, end: _browseCustomEnd!)
          : DateTimeRange(start: today, end: today.add(const Duration(days: 7))),
      builder: (ctx, child) => AppCalendarTheme.wrap(ctx, child),
    );
    if (!mounted) return;
    if (range != null) {
      setState(() {
        _browsePreset = _BrowseDatePreset.custom;
        _browseCustomStart = range.start;
        _browseCustomEnd = range.end;
      });
    }
  }

  void _setBrowsePreset(_BrowseDatePreset p) {
    if (p == _BrowseDatePreset.custom) {
      _pickCustomBrowseRange();
      return;
    }
    setState(() {
      _browsePreset = p;
      _browseCustomStart = null;
      _browseCustomEnd = null;
    });
  }

  String _browseFilterSummary() {
    switch (_browsePreset) {
      case _BrowseDatePreset.any:
        return 'Any dates';
      case _BrowseDatePreset.next7:
        return 'Next 7 days';
      case _BrowseDatePreset.next15:
        return 'Next 15 days';
      case _BrowseDatePreset.thisMonth:
        return 'This month';
      case _BrowseDatePreset.custom:
        if (_browseCustomStart != null && _browseCustomEnd != null) {
          return '${DateFormat.yMMMd().format(_browseCustomStart!)} - ${DateFormat.yMMMd().format(_browseCustomEnd!)}';
        }
        return 'Custom range';
    }
  }

  Widget _exploreCategoryChips({
    required String selected,
    required ValueChanged<String> onSelect,
  }) {
    return SizedBox(
      height: 38.h,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, __) => SizedBox(width: 12.w),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = selected == cat;
          return GestureDetector(
            onTap: () => onSelect(cat),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                gradient: isSelected ? const LinearGradient(colors: [Color(0xFFFF5F15), Color(0xFFFF9068)]) : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: isSelected ? Colors.transparent : Colors.grey[300]!),
                boxShadow: isSelected
                    ? [BoxShadow(color: const Color(0xFFFF5F15).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]
                    : null,
              ),
              child: Center(
                child: Text(
                  cat,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _onSearchChanged(String val) {
    controller.exploreSearchQuery.value = val;
    if (val.trim().isEmpty) {
      _exploreSearchDebounce?.cancel();
      controller.clearExploreSearch();
      return;
    }
    _exploreSearchDebounce?.cancel();
    _exploreSearchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      controller.fetchExploreLiveSearch(val);
    });
  }

  Map<String, dynamic> _eventMapForDetail(dynamic e) {
    if (e is Map<String, dynamic>) return e;
    if (e is Map) {
      return Map<String, dynamic>.from(e.map((k, v) => MapEntry(k.toString(), v)));
    }
    return <String, dynamic>{};
  }

  String _exploreSearchResultSubtitle(dynamic e) {
    if (e is! Map) return '';
    final c = (e['category'] ?? '').toString();
    final v = (e['venue'] ?? '').toString();
    final d = (e['event_date'] ?? '').toString();
    final org = (e['organizer_name'] ?? '').toString();
    final parts = <String>[];
    if (c.isNotEmpty) parts.add(c);
    if (d.isNotEmpty) {
      final parsed = DateTime.tryParse(d.replaceAll(' ', 'T'));
      parts.add(parsed != null ? DateFormat.yMMMd().format(parsed) : d);
    }
    if (v.isNotEmpty) parts.add(v);
    if (org.isNotEmpty) parts.add(org);
    return parts.join(' Â· ');
  }

  Widget _buildExploreSearchResultsPanel() {
    return Obx(() {
      final q = controller.exploreSearchQuery.value.trim();
      if (q.isEmpty) return const SizedBox.shrink();

      final loading = controller.exploreSearchLoading.value;
      final items = controller.exploreSearchResults;

      return Padding(
        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 4.h),
        child: Material(
          elevation: 14,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(14),
          color: Colors.white,
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 280.h),
            child: loading && items.isEmpty
                ? Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.h),
                    child: const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(color: Color(0xFFFF5F15), strokeWidth: 2.5),
                      ),
                    ),
                  )
                : items.isEmpty
                    ? Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Text(
                          'No events match your search. Try different words.',
                          style: TextStyle(fontSize: 14.sp, color: Colors.grey[700], height: 1.35),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.symmetric(vertical: 6.h),
                        physics: const ClampingScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
                        itemBuilder: (context, i) {
                          final e = items[i];
                          final title = (e is Map ? e['title'] : null)?.toString() ?? 'Event';
                          final subtitle = _exploreSearchResultSubtitle(e);
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 2.h),
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFFF5F15).withValues(alpha: 0.15),
                              radius: 20,
                              child: const Icon(Icons.event_rounded, color: Color(0xFFFF5F15), size: 22),
                            ),
                            title: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp, color: Colors.black87),
                            ),
                            subtitle: subtitle.isEmpty
                                ? null
                                : Text(
                                    subtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[600], height: 1.25),
                                  ),
                            onTap: () {
                              FocusScope.of(context).unfocus();
                              final map = _eventMapForDetail(e);
                              searchCtrl.clear();
                              controller.clearExploreSearch();
                              _openEventDetail(map);
                            },
                          );
                        },
                      ),
          ),
        ),
      );
    });
  }

  Widget _browseDateChip(String label, _BrowseDatePreset preset) {
    final customOk =
        preset != _BrowseDatePreset.custom || (_browseCustomStart != null && _browseCustomEnd != null);
    final selected = _browsePreset == preset && customOk;
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 11.sp)),
      selected: selected,
      onSelected: (_) => _setBrowsePreset(preset),
      selectedColor: const Color(0xFFFF5F15).withValues(alpha: 0.22),
      checkmarkColor: const Color(0xFFFF5F15),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFFFF5F15) : Colors.black87,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
      side: BorderSide(color: selected ? const Color(0xFFFF5F15) : Colors.grey.shade300),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: const Color(0xFFFF5F15),
      child: Obx(() {
        final catalog = List<dynamic>.from(controller.liveEventCatalog);
        final loading = controller.isLoading.value;
        final liveTodayFiltered =
            catalog.where(_isLiveTodayEvent).where((e) => _categoryMatch(e, liveTodayCategory)).toList();
        final upcomingFiltered = catalog
            .where(_isUpcomingFutureDay)
            .where((e) => _categoryMatch(e, browseCategory))
            .where(_browseRangeMatch)
            .toList();
        return CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            cacheExtent: 720,
            slivers: [
          // Pinned header — elevation appears when content scrolls underneath
          CampusSliverAppBar(
            automaticallyImplyLeading: false,
            leadingWidth: 220,
            leading: CampusSliverAppBar.logoLeading(),
            actions: [
              TextButton(
                onPressed: () => _openMicampusWebsite(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white.withValues(alpha: 0.9),
                  padding: EdgeInsets.symmetric(horizontal: 6.w),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'micampus.co.in',
                  style: TextStyle(
                    fontSize: 11.sp,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white54,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Search',
                icon: const Icon(Icons.search_rounded, color: Colors.white, size: 26),
                onPressed: () => _searchFocus.requestFocus(),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(100.h),
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(() {
                      final name = Get.isRegistered<ProfileController>()
                          ? Get.find<ProfileController>().displayNameObs.value
                          : 'User';
                      return Text(
                        CampusAppBarTokens.greeting(name),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    }),
                    SizedBox(height: 10.h),
                    Material(
                      elevation: 0,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      color: AppColors.surface,
                      child: TextField(
                        controller: searchCtrl,
                        focusNode: _searchFocus,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          hintText: "Search by name, venue, category, organizer…",
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[600]),
                          suffixIcon: Obx(() {
                            if (controller.exploreSearchQuery.value.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return IconButton(
                              tooltip: 'Clear',
                              icon: Icon(Icons.close_rounded, color: Colors.grey[700], size: 22),
                              onPressed: () {
                                searchCtrl.clear();
                                _exploreSearchDebounce?.cancel();
                                controller.clearExploreSearch();
                              },
                            );
                          }),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 20.w),
                        ),
                        onChanged: _onSearchChanged,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Server-backed search results (events.php ?search=) - above reminders
          SliverToBoxAdapter(
            child: _buildExploreSearchResultsPanel(),
          ),

          // Upcoming reminders (notification dates)
          const SliverToBoxAdapter(
            child: _UpcomingRemindersSection(),
          ),

          // Featured Events Slider (never filtered by category, date, or search)
          SliverToBoxAdapter(
            child: () {
              if (loading && catalog.isEmpty) {
                return Padding(
                  padding: EdgeInsets.only(top: AppSpacing.md.h),
                  child: const EventListSkeleton(count: 2),
                );
              }
              if (catalog.isEmpty) return const SizedBox.shrink();
              final featuredEvents = catalog.take(5).toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Featured Events",
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  CarouselSlider.builder(
                    itemCount: featuredEvents.length,
                    options: CarouselOptions(
                      height: 320.h,
                      autoPlay: true,
                      autoPlayInterval: const Duration(milliseconds: 2600),
                      autoPlayAnimationDuration: const Duration(milliseconds: 520),
                      autoPlayCurve: Curves.fastEaseInToSlowEaseOut,
                      enlargeCenterPage: true,
                      viewportFraction: 0.82,
                      enableInfiniteScroll: featuredEvents.length > 1,
                      scrollPhysics: const BouncingScrollPhysics(),
                    ),
                    itemBuilder: (context, index, realIndex) {
                      final ev = featuredEvents[index];
                      return RepaintBoundary(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: TicketEventCard(
                            event: ev,
                            onTap: () => _openEventDetail(ev),
                            width: double.infinity,
                            posterHeight: 320,
                            showRegistrationOpenTag:
                                _showRegistrationOpenTagForFeatured(ev),
                            dateLineBuilder: (a, b) => _cardEventDateLine(a, b),
                            venueLineBuilder: (v) => _cardVenueLine(v),
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 20.h),
                ],
              );
            }(),
          ),

          // Recent winners under Featured; announcements stay at bottom of Explore.
          SliverToBoxAdapter(
            child: ColoredBox(
              color: AppColors.cream,
              child: WinnerPhotosCarousel(photos: _winnerPhotos),
            ),
          ),

          // Winners — single entry (removed from app bar)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 8.h),
              child: PressableScale(
                onTap: _openWinners,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
                    boxShadow: AppShadows.card,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                        ),
                        child: Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 26.sp),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Winners', style: Theme.of(context).textTheme.titleMedium),
                            SizedBox(height: 2.h),
                            Text(
                              'See who won past campus events',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.accent),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Live today (category filter only) + browse filters + upcoming
          SliverToBoxAdapter(
            child: loading && catalog.isEmpty
                ? const SizedBox.shrink()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Text(
                          "Live today",
                          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Text(
                          "Filter by event type",
                          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      _exploreCategoryChips(
                        selected: liveTodayCategory,
                        onSelect: (c) => setState(() => liveTodayCategory = c),
                      ),
                      SizedBox(height: 10.h),
                      if (liveTodayFiltered.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          child: AppEmptyState(
                            icon: Icons.event_busy_rounded,
                            accentColor: AppColors.teal,
                            headline: catalog.where(_isLiveTodayEvent).isEmpty
                                ? 'Nothing live right now'
                                : 'No events for this type today',
                            supporting: catalog.where(_isLiveTodayEvent).isEmpty
                                ? 'Check back soon or browse upcoming events below.'
                                : 'Try another category or check upcoming events.',
                          ),
                        )
                      else
                        SizedBox(
                          height: 320.h,
                          child: ListView.separated(
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            scrollDirection: Axis.horizontal,
                            itemCount: liveTodayFiltered.length,
                            separatorBuilder: (_, __) => SizedBox(width: 16.w),
                            itemBuilder: (context, i) => RepaintBoundary(
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: _AllEventCard(event: liveTodayFiltered[i]),
                              ),
                            ),
                          ),
                        ),
                      SizedBox(height: 24.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Text(
                          "Upcoming events - filters",
                          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Text(
                          "The search box finds events on the server. Category and date filters apply to the upcoming list below.",
                          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      _exploreCategoryChips(
                        selected: browseCategory,
                        onSelect: (c) => setState(() => browseCategory = c),
                      ),
                      SizedBox(height: 10.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Event date range',
                              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: Colors.black87),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              _browseFilterSummary(),
                              style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
                            ),
                            SizedBox(height: 8.h),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _browseDateChip('Any', _BrowseDatePreset.any),
                                  SizedBox(width: 8.w),
                                  _browseDateChip('Next 7 days', _BrowseDatePreset.next7),
                                  SizedBox(width: 8.w),
                                  _browseDateChip('Next 15 days', _BrowseDatePreset.next15),
                                  SizedBox(width: 8.w),
                                  _browseDateChip('This month', _BrowseDatePreset.thisMonth),
                                  SizedBox(width: 8.w),
                                  _browseDateChip('Custom range', _BrowseDatePreset.custom),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Text(
                          "Upcoming events",
                          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      if (upcomingFiltered.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          child: Text(
                            catalog.where(_isUpcomingFutureDay).isEmpty
                                ? "No upcoming events in the feed right now."
                                : "No upcoming events match your filters.",
                            style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600),
                          ),
                        )
                      else
                        SizedBox(
                          height: 320.h,
                          child: ListView.separated(
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            scrollDirection: Axis.horizontal,
                            itemCount: upcomingFiltered.length,
                            separatorBuilder: (_, __) => SizedBox(width: 16.w),
                            itemBuilder: (context, i) => RepaintBoundary(
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: _AllEventCard(
                                  event: upcomingFiltered[i],
                                  showRegistrationOpenTag: true,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),

          if (!loading && catalog.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
                child: SizedBox(height: 260.h, child: _buildEmptyState()),
              ),
            ),

          // Announcements last (previous Explore order).
          if (_adPosts.isNotEmpty)
            SliverToBoxAdapter(
              child: ColoredBox(
                color: AppColors.cream,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 8.h),
                  child: HomeAdCarousel(posts: _adPosts),
                ),
              ),
            ),

          // Bottom padding
          SliverToBoxAdapter(child: SizedBox(height: 30.h)),
        ],
      );
      }),
    );
  }

  Widget _buildEmptyState() => const AppEmptyState(
        icon: Icons.confirmation_number_outlined,
        headline: 'No events found',
        supporting: 'Try adjusting your filters or search terms.',
        accentColor: AppColors.accent,
      );
}

// --- ALL EVENT CARD (Horizontal Scrollable - Poster Style) ---
class _AllEventCard extends StatelessWidget {
  final dynamic event;
  final bool showRegistrationOpenTag;
  const _AllEventCard({required this.event, this.showRegistrationOpenTag = false});

  /// Profile + organiser flag for home card actions (Join / Volunteer / Participate).
  /// Kept for Part 3 sticky actions on event detail.
  // ignore: unused_element
  Future<Map<String, dynamic>> _eventCardJoinGates() async {
    try {
      final userId = await PrefService.getUserId();
      if (userId == null) {
        debugPrint("âŒ No user ID found");
        return {'success': false};
      }

      final userResponse = await ApiService.getUserProfile(userId);
      final userIsStudentValue = userResponse.data['data']['is_student'];
      final organizerIsStudentValue = event['organizer_is_student'];

      final int userIsStudentInt = userIsStudentValue is String
          ? int.tryParse(userIsStudentValue) ?? 1
          : (userIsStudentValue as int? ?? 1);
      final int organizerIsStudentInt = organizerIsStudentValue is String
          ? int.tryParse(organizerIsStudentValue) ?? 1
          : (organizerIsStudentValue as int? ?? 1);

      final bool userIsStudent = userIsStudentInt == 1;
      final bool organizerIsStudent = organizerIsStudentInt == 1;

      debugPrint("ðŸ‘¤ User is student: $userIsStudent (raw: $userIsStudentValue, converted: $userIsStudentInt)");
      debugPrint("ðŸŽ¯ Organizer is student: $organizerIsStudent (raw: $organizerIsStudentValue, converted: $organizerIsStudentInt)");

      return {
        'success': true,
        'userId': userId,
        'userIsStudent': userIsStudent,
        'rolesMatch': userIsStudent == organizerIsStudent,
        'isOrganizer': EventParticipationRules.isUserEventOrganizer(event, userId),
      };
    } catch (e) {
      debugPrint("âŒ Error checking join gates: $e");
      return {'success': false};
    }
  }

  @override
  Widget build(BuildContext context) {
    return TicketEventCard(
      event: event,
      onTap: () => _openEventDetail(event),
      width: 260.w,
      posterHeight: 320,
      showRegistrationOpenTag: showRegistrationOpenTag,
      posterCacheWidth: _eventPosterCacheWidth(context, 0.82),
      dateLineBuilder: (a, b) => _cardEventDateLine(a, b),
      venueLineBuilder: (v) => _cardVenueLine(v),
    );
  }
}

/// Kept for Part 3 (event detail sticky actions). Not used on list cards anymore.
// ignore: unused_element
class _AllEventCardActions extends StatelessWidget {
  final dynamic event;
  final EventController controller;
  final Future<Map<String, dynamic>> Function() joinGates;

  const _AllEventCardActions({
    required this.event,
    required this.controller,
    required this.joinGates,
  });

  ButtonStyle _pillStyle({
    required Color bg,
    required Color fg,
  }) {
    return FilledButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      disabledBackgroundColor: AppColors.surfaceMuted,
      disabledForegroundColor: AppColors.textSecondary,
      elevation: 0,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
      minimumSize: Size(0, 40.h),
      maximumSize: Size(double.infinity, 40.h),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
    );
  }

  Widget _pill({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required Color bg,
    Color fg = Colors.white,
  }) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14.sp),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.sp),
      ),
      style: _pillStyle(bg: bg, fg: fg),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: joinGates(),
      builder: (context, snap) {
        final waiting = snap.connectionState == ConnectionState.waiting;
        final g = snap.data;
        final ready = g != null && g['success'] == true;
        final isOrganizer = ready && g['isOrganizer'] == true;
        final rolesMatch = ready && g['rolesMatch'] == true;
        final userId = ready ? g['userId'] as String? : null;
        final userIsStudent = ready ? g['userIsStudent'] as bool? : null;
        final showJoin = !isOrganizer;
        final showVolPart = ready && rolesMatch;
        final eid = event['id'].toString();
        final status = (event['status'] ?? '').toString().toLowerCase();
        final isApproved = status == 'approved' || status.isEmpty;
        final regClosed = isEventRegistrationClosed(event);

        if (waiting) {
          return SizedBox(
            height: 28.h,
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accent,
                ),
              ),
            ),
          );
        }

        if (isOrganizer) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Divider(height: 1, thickness: 1, color: AppColors.border),
              SizedBox(height: 10.h),
              OutlinedButton(
                onPressed: null,
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(0, 40.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                child: const Text('Your event'),
              ),
            ],
          );
        }

        // No actions for this viewer — take zero height (fixes blank footer band).
        if (!showJoin && !showVolPart) {
          return const SizedBox.shrink();
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Divider(height: 1, thickness: 1, color: AppColors.border),
            SizedBox(height: 10.h),
            if (regClosed && showJoin)
              Obx(() {
                final attending = controller.attendingList
                    .any((e) => e['id'].toString() == eid);
                final volunteering = controller.volunteeringList
                        .any((e) => e['id'].toString() == eid) ||
                    (userId != null &&
                        EventParticipationRules.userInVolunteerList(event, userId));
                final participating = controller.participatingList
                        .any((e) => e['id'].toString() == eid) ||
                    (userId != null &&
                        EventParticipationRules.userInParticipantList(event, userId));
                // Leaving is still allowed after the deadline; only new joins are blocked.
                if (attending && !volunteering && !participating) {
                  return _pill(
                    label: 'Leave Event',
                    icon: Icons.logout,
                    bg: AppColors.surfaceMuted,
                    fg: AppColors.navy,
                    onPressed: () => controller.leaveEvent(eid),
                  );
                }
                if (volunteering && !participating && showVolPart) {
                  return Row(
                    children: [
                      Expanded(
                        child: _pill(
                          label: 'Leave',
                          icon: Icons.logout,
                          bg: AppColors.surfaceMuted,
                          fg: AppColors.navy,
                          onPressed: () => controller.leaveVolunteer(eid),
                        ),
                      ),
                    ],
                  );
                }
                if (participating && !volunteering && showVolPart) {
                  return _pill(
                    label: 'Leave',
                    icon: Icons.logout,
                    bg: AppColors.surfaceMuted,
                    fg: AppColors.navy,
                    onPressed: () => controller.leaveParticipant(eid),
                  );
                }
                return OutlinedButton(
                  onPressed: null,
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(0, 40.h),
                    foregroundColor: AppColors.textSecondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                  child: const Text('Registration closed'),
                );
              })
            else
            Row(
              children: [
                if (showJoin)
                  Expanded(
                    child: Obx(() {
                      final attending = controller.attendingList
                          .any((e) => e['id'].toString() == eid);
                      final volunteering = controller.volunteeringList
                              .any((e) => e['id'].toString() == eid) ||
                          (userId != null &&
                              EventParticipationRules.userInVolunteerList(
                                  event, userId));
                      final participating = controller.participatingList
                              .any((e) => e['id'].toString() == eid) ||
                          (userId != null &&
                              EventParticipationRules.userInParticipantList(
                                  event, userId));
                      final blockJoin = volunteering || participating;
                      final canLeave = attending && !blockJoin && isApproved;
                      final canJoin = isApproved && !attending && !blockJoin;
                      return _pill(
                        label: canLeave ? 'Leave Event' : 'Join',
                        icon: canLeave
                            ? Icons.logout
                            : Icons.check_circle_outline_rounded,
                        bg: canLeave ? AppColors.surfaceMuted : AppColors.accent,
                        fg: canLeave ? AppColors.navy : Colors.white,
                        onPressed: canLeave
                            ? () => controller.leaveEvent(eid)
                            : canJoin
                                ? () => controller.joinEvent(
                                      eid,
                                      organizerId: event['organizer_id']?.toString(),
                                      eventSnapshot: event,
                                      userIsStudent: userIsStudent,
                                    )
                                : null,
                      );
                    }),
                  ),
                if (showJoin && showVolPart) SizedBox(width: 6.w),
                if (showVolPart)
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Expanded(
                          child: Obx(() {
                            final volunteering = controller.volunteeringList
                                    .any((e) => e['id'].toString() == eid) ||
                                (userId != null &&
                                    EventParticipationRules.userInVolunteerList(
                                        event, userId));
                            final participating = controller.participatingList
                                    .any((e) => e['id'].toString() == eid) ||
                                (userId != null &&
                                    EventParticipationRules
                                        .userInParticipantList(event, userId));
                            final canSwitchToVolunteer =
                                participating && !volunteering && isApproved;
                            final canLeaveVolunteer =
                                volunteering && !participating && isApproved;
                            final canJoinVolunteer = isApproved &&
                                !volunteering &&
                                !participating;
                            return _pill(
                              label: canSwitchToVolunteer
                                  ? '→ Volunteer'
                                  : (canLeaveVolunteer ? 'Leave' : 'Volunteer'),
                              icon: canSwitchToVolunteer
                                  ? Icons.swap_horiz
                                  : (canLeaveVolunteer
                                      ? Icons.logout
                                      : Icons.front_hand_outlined),
                              bg: canSwitchToVolunteer
                                  ? AppColors.accent
                                  : (canLeaveVolunteer
                                      ? AppColors.surfaceMuted
                                      : AppColors.accent),
                              fg: canLeaveVolunteer ? AppColors.navy : Colors.white,
                              onPressed: canSwitchToVolunteer
                                  ? () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => VolunteerDialog(
                                          event: event,
                                          userIsStudent: userIsStudent,
                                          switchFromParticipant: true,
                                        ),
                                      );
                                    }
                                  : canLeaveVolunteer
                                      ? () => controller.leaveVolunteer(eid)
                                      : canJoinVolunteer
                                          ? () {
                                              showDialog(
                                                context: context,
                                                builder: (context) => VolunteerDialog(
                                                  event: event,
                                                  userIsStudent: userIsStudent,
                                                ),
                                              );
                                            }
                                          : null,
                            );
                          }),
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Obx(() {
                            final volunteering = controller.volunteeringList
                                    .any((e) => e['id'].toString() == eid) ||
                                (userId != null &&
                                    EventParticipationRules.userInVolunteerList(
                                        event, userId));
                            final participating = controller.participatingList
                                    .any((e) => e['id'].toString() == eid) ||
                                (userId != null &&
                                    EventParticipationRules
                                        .userInParticipantList(event, userId));
                            final canSwitchFromVolunteer =
                                volunteering && !participating && isApproved;
                            final canLeaveParticipant =
                                participating && !volunteering && isApproved;
                            final canJoinParticipant = isApproved &&
                                !participating &&
                                !volunteering;
                            return _pill(
                              label: canLeaveParticipant
                                  ? 'Leave'
                                  : (canSwitchFromVolunteer
                                      ? '→ Participant'
                                      : 'Participate'),
                              icon: canLeaveParticipant
                                  ? Icons.logout
                                  : (canSwitchFromVolunteer
                                      ? Icons.swap_horiz
                                      : Icons.person_add_alt_1_rounded),
                              bg: canLeaveParticipant
                                  ? AppColors.surfaceMuted
                                  : (canSwitchFromVolunteer
                                      ? AppColors.accent
                                      : AppColors.teal),
                              fg: canLeaveParticipant
                                  ? AppColors.navy
                                  : Colors.white,
                              onPressed: canLeaveParticipant
                                  ? () => controller.leaveParticipant(eid)
                                  : canSwitchFromVolunteer
                                      ? () {
                                          showParticipateRegistrationSheet(
                                            context,
                                            eventId: eid,
                                            eventTitle: (event['title'] ?? 'Event')
                                                .toString(),
                                            organizerId:
                                                event['organizer_id']?.toString(),
                                            eventSnapshot: event,
                                            userIsStudent: userIsStudent,
                                            switchFromVolunteer: true,
                                          );
                                        }
                                      : canJoinParticipant
                                          ? () {
                                              showParticipateRegistrationSheet(
                                                context,
                                                eventId: eid,
                                                eventTitle:
                                                    (event['title'] ?? 'Event')
                                                        .toString(),
                                                organizerId: event['organizer_id']
                                                    ?.toString(),
                                                eventSnapshot: event,
                                                userIsStudent: userIsStudent,
                                              );
                                            }
                                          : null,
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

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
    if (!mounted) return;
    if (userId == null) {
      setState(() { _loading = false; _error = 'Please log in.'; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final response = await ApiService.getCertificatesByUserId(userId);
      if (!mounted) return;
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
      if (!mounted) return;
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
          final pending = certificateIsPending(c);
          final url = certificateUrlFromRecord(c);
          return Card(
            margin: EdgeInsets.only(bottom: 12.h),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              leading: CircleAvatar(
                backgroundColor: pending
                    ? Colors.orange.withValues(alpha: 0.2)
                    : const Color(0xFFFF5F15).withValues(alpha: 0.2),
                child: Icon(
                  pending ? Icons.hourglass_empty : Icons.card_membership,
                  color: pending ? Colors.orange : const Color(0xFFFF5F15),
                ),
              ),
              title: Text(eventTitle, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp)),
              subtitle: Text(
                pending
                    ? 'Certificate not ready yet'
                    : '${type.toUpperCase()} | $eventDate',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: pending ? Colors.orange[800] : Colors.grey[600],
                ),
              ),
              trailing: pending
                  ? Icon(Icons.refresh, color: Colors.grey[400], size: 20)
                  : const Icon(Icons.more_vert),
              onTap: pending
                  ? () => _load()
                  : (url.isEmpty
                      ? null
                      : () => showCertificateViewDownloadSheet(context, url: url, title: eventTitle)),
            ),
          );
        },
      ),
    );
  }
}

// --- MY EVENTS TAB ---
class _MyEventsTab extends StatefulWidget {
  final int initialIndex;
  const _MyEventsTab({super.key, this.initialIndex = 0});

  @override
  State<_MyEventsTab> createState() => _MyEventsTabState();
}

class _MyEventsTabState extends State<_MyEventsTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 7,
      vsync: this,
      initialIndex: widget.initialIndex.clamp(0, 6),
    );
    // Prefetch all activity lists when opening My Activity (session is ready).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = AppBootstrap.ensureEventController();
      unawaited(c.fetchAttendingEvents());
      unawaited(c.fetchHostedEvents());
      unawaited(c.fetchEditingEvents());
      unawaited(c.fetchVolunteeringEvents());
      unawaited(c.fetchParticipatingEvents());
    });
  }

  @override
  void didUpdateWidget(covariant _MyEventsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      final next = widget.initialIndex.clamp(0, 6);
      if (_tabController.index != next) {
        _tabController.animateTo(next);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: CampusAppBar(
        titleText: 'My Activity',
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          isScrollable: true,
          tabs: const [
            Tab(text: "Viewing"),
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
        controller: _tabController,
        children: const [
          _EventListWidget(type: 'attending'),
          _EventListWidget(type: 'hosted'),
          _EventListWidget(type: 'editing'),
          _EventListWidget(type: 'volunteering'),
          _EventListWidget(type: 'participating'),
          FavoritesView(),
          _CertificatesTab(),
        ],
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
  bool _listLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _listLoading = true);
    
    final EventController controller = AppBootstrap.ensureEventController();
    try {
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
    } finally {
      if (mounted) setState(() => _listLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    final EventController controller = AppBootstrap.ensureEventController();
    
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
          emptyMessage = "You aren't viewing any events yet";
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
      
      if (_listLoading && eventsList.isEmpty) {
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

      // --- Hosted events: Pending / Rejected / Approved / Closed ---
      if (widget.type == 'hosted') {
        String hostNormStatus(dynamic e) =>
            (e is Map ? e['status'] : null)?.toString().toLowerCase().trim() ?? '';
        final approved =
            eventsList.where((e) => hostNormStatus(e) == 'approved').toList();
        final rejected =
            eventsList.where((e) => hostNormStatus(e) == 'rejected').toList();
        final closed =
            eventsList.where((e) => hostNormStatus(e) == 'closed').toList();
        final pending = eventsList
            .where((e) {
              final s = hostNormStatus(e);
              return s != 'approved' && s != 'rejected' && s != 'closed';
            })
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
                        color: chipColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: chipColor.withValues(alpha: 0.35)),
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
                items: pending,
              ),
              buildSection(
                title: "Rejected",
                chipColor: Colors.red,
                items: rejected,
              ),
              buildSection(
                title: "Approved",
                chipColor: Colors.green,
                items: approved,
              ),
              buildSection(
                title: "Closed",
                chipColor: Colors.grey,
                items: closed,
              ),
              if (approved.isEmpty &&
                  pending.isEmpty &&
                  rejected.isEmpty &&
                  closed.isEmpty)
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
    final EventController eventController = AppBootstrap.ensureEventController();
    
    await Future.wait([
      controller.loadProfile(),
      eventController.fetchHostedEvents(),
      eventController.fetchFavorites(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final ProfileController controller = Get.find<ProfileController>();
    final EventController eventController = AppBootstrap.ensureEventController();
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const AppLoadingScreen(message: 'Loading profile...');
        }
        
        final user = controller.userData.value;
        return RefreshIndicator(
          onRefresh: _refreshProfile,
          color: AppColors.accent,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            cacheExtent: 300,
            slivers: [
            SliverAppBar(
              expandedHeight: 56.h,
              floating: false,
              pinned: true,
              elevation: 0,
              scrolledUnderElevation: CampusAppBarTokens.scrolledUnderElevation,
              shadowColor: CampusAppBarTokens.shadowColor,
              surfaceTintColor: Colors.transparent,
              backgroundColor: AppColors.accent,
              leadingWidth: 200,
              leading: CampusSliverAppBar.logoLeading(),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: CampusAppBarTokens.gradientDecoration(),
                ),
              ),
              shape: CampusAppBarTokens.shape,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              actions: [
                const IconButton(
                  icon: Icon(Icons.edit_outlined, color: Colors.white, size: 22),
                  onPressed: _openEditProfile,
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
                          backgroundColor: Colors.grey,
                          child: const Text("Cancel"),
                        ),
                        ArtAlertButton(
                          onPressed: () {
                            Navigator.pop(context);
                            // Fire-and-forget; AuthController shows "Logging out..." loader.
                            unawaited(authController.logout());
                          },
                          backgroundColor: AppColors.accent,
                          child: const Text("Yes"),
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
                            color: Colors.black.withValues(alpha: 0.04),
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
                                color: const Color(0xFFFF5F15).withValues(alpha: 0.3),
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
                                ? appNetworkImageProvider("${Constant.uploadsBaseUrl}profiles/${user.image}") 
                                : null,
                              child: user.image == null || user.image!.isEmpty 
                                ? Icon(Icons.person, size: 50.w, color: const Color(0xFFFF5F15)) 
                                : null,
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 16.h),
                        
                        Text(
                          controller.displayNameObs.value,
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
                            color: const Color(0xFFFF5F15).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.email_outlined, size: 14, color: Color(0xFFFF5F15)),
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
                        if (user.departmentClass != null && user.departmentClass!.trim().isNotEmpty) ...[
                          SizedBox(height: 10.h),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.school_outlined, size: 14, color: Colors.green.shade800),
                                SizedBox(width: 6.w),
                                Flexible(
                                  child: Text(
                                    user.departmentClass!.trim(),
                                    style: TextStyle(
                                      color: Colors.green.shade900,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                            color: Colors.black.withValues(alpha: 0.04),
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
                            "Hosted",
                            onTap: () => _openMyActivityFromProfile(context, 1),
                          ),
                          _buildDivider(),
                          _buildStatItem(
                            Icons.people_rounded,
                            eventController.attendingList.length.toString(),
                            "Viewing",
                            onTap: () => _openMyActivityFromProfile(context, 0),
                          ),
                          _buildDivider(),
                          _buildStatItem(
                            Icons.volunteer_activism,
                            eventController.volunteeringList.length.toString(),
                            "Volunteer",
                            onTap: () => _openMyActivityFromProfile(context, 3),
                          ),
                          _buildDivider(),
                          _buildStatItem(
                            Icons.groups,
                            eventController.participatingList.length.toString(),
                            "Participate",
                            onTap: () => _openMyActivityFromProfile(context, 4),
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
                          color: Colors.black.withValues(alpha: 0.04),
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
                                color: const Color(0xFFFF5F15).withValues(alpha: 0.1),
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
                          user.bio ?? "No biodata added yet. Tap edit to add one!", 
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
                          color: Colors.black.withValues(alpha: 0.04),
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
                                color: const Color(0xFFFF5F15).withValues(alpha: 0.1),
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
                                        const Color(0xFFFF5F15).withValues(alpha: 0.1),
                                        const Color(0xFFFF9068).withValues(alpha: 0.1)
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFFFF5F15).withValues(alpha: 0.2),
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

  void _openMyActivityFromProfile(BuildContext context, int myEventsTabIndex) {
    context.findAncestorStateOfType<_HomeViewState>()?.openMyActivityTab(myEventsTabIndex);
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label, {
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 4.h),
            child: Column(
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
                        color: const Color(0xFFFF5F15).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                SizedBox(height: 10.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFF5F15),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 50.h, color: Colors.grey[200]);
  }
}

// --- EVENT CARD WIDGET (My Activity grid) ---
class _EventCard extends StatelessWidget {
  final dynamic event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return TicketEventCard(
      event: event,
      onTap: () => _openEventDetail(event),
      posterHeight: 100,
      compact: true,
      expandToFit: true,
      posterCacheWidth: _eventPosterCacheWidth(context, 0.96),
      dateLineBuilder: (a, b) => _cardEventDateLine(a, b),
      venueLineBuilder: (v) => _cardVenueLine(v),
    );
  }
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
      case 'closed':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  String _statusLabel(String status, {bool hasPendingEdit = false}) {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'pending':
        return hasPendingEdit ? 'Pending re-approval' : 'Pending approval';
      case 'hold':
        return 'On Hold';
      case 'rejected':
        return 'Rejected';
      case 'closed':
        return 'Closed';
      default:
        return status.isEmpty ? 'Pending approval' : status;
    }
  }

  bool _hasPendingEdit(dynamic event) {
    if (event is! Map) return false;
    final pe = event['pending_edit'];
    return pe != null && pe is Map && pe.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final EventController controller = AppBootstrap.ensureEventController();
    final status = (event is Map ? event['status'] : null)?.toString().toLowerCase() ?? '';
    final hasPendingEdit = _hasPendingEdit(event);
    final canEditDelete = status == 'pending';
    final badgeLabel = _statusLabel(status, hasPendingEdit: hasPendingEdit);
    final badgeColor = hasPendingEdit && status == 'pending'
        ? Colors.deepOrange
        : _statusColor(status);

    return InkWell(
      onTap: () => _openEventDetail(event),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
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
                color: const Color(0xFFFF5F15).withValues(alpha: 0.12),
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
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: badgeColor.withValues(alpha: 0.35)),
                        ),
                        child: Text(
                          badgeLabel,
                          style: TextStyle(
                            color: badgeColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 11.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    _cardEventDateLine(
                      event is Map ? event['event_date'] : null,
                      event is Map ? event['event_end_date'] : null,
                    ),
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
                    AppNavigation.to(
                      () => CreateEventView(existingEvent: event),
                      prepare: AppBootstrap.prepareCreateEvent,
                      loadingMessage: 'Loading...',
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
                          backgroundColor: Colors.grey,
                          child: const Text("Cancel"),
                        ),
                        ArtAlertButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await controller.deleteHostedEvent(event: event);
                          },
                          backgroundColor: Colors.red,
                          child: const Text("Delete"),
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

// --- Upcoming reminders (notification dates from API) ---
class _UpcomingRemindersSection extends StatefulWidget {
  const _UpcomingRemindersSection();

  @override
  State<_UpcomingRemindersSection> createState() => _UpcomingRemindersSectionState();
}

class _UpcomingRemindersSectionState extends State<_UpcomingRemindersSection> {
  List<dynamic> _dates = [];
  bool _loading = true;
  String? _error;

  DateTime? _notifyDateSortKey(dynamic d) {
    final s = (d is Map ? d['notify_date'] : null)?.toString();
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s.replaceAll(' ', 'T'));
  }

  /// Nearest reminder only (earliest `notify_date`).
  List<dynamic> _nearestRemindersOnly(List<dynamic> list) {
    if (list.isEmpty) return [];
    final sorted = List<dynamic>.from(list)
      ..sort((a, b) {
        final ta = _notifyDateSortKey(a);
        final tb = _notifyDateSortKey(b);
        if (ta == null && tb == null) return 0;
        if (ta == null) return 1;
        if (tb == null) return -1;
        return ta.compareTo(tb);
      });
    return [sorted.first];
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final from = DateTime.now().toIso8601String().substring(0, 10);
      final res = await ApiService.getNotificationDates(
        from: from,
        includeEvents: true,
        includeCelebrations: true,
      );
      if (!mounted) return;
      final data = res.data;
      if (data is Map && data['status'] == 'success') {
        final list = data['data'];
        setState(() {
          _dates = list is List ? list : [];
          _loading = false;
          _error = null;
        });
      } else {
        setState(() {
          _dates = [];
          _loading = false;
          _error = (data is Map ? data['message'] : null)?.toString();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
        _dates = [];
        _loading = false;
        _error = e.toString();
      });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
        child: SizedBox(
          height: 36.h,
          child: const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2.5),
            ),
          ),
        ),
      );
    }
    if (_error != null && _dates.isEmpty) return const SizedBox.shrink();
    if (_dates.isEmpty) return const SizedBox.shrink();

    final remindersToShow = _nearestRemindersOnly(_dates);

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active_outlined, color: AppColors.accent, size: 18.sp),
              SizedBox(width: 6.w),
              Text(
                "Upcoming reminders",
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: AppColors.navy),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          ...(remindersToShow.map<Widget>((d) {
            final title = (d is Map ? d['title'] : null)?.toString() ?? 'Reminder';
            final dateStr = (d is Map ? d['notify_date'] : null)?.toString() ?? '';
            final source = (d is Map ? d['source'] : null)?.toString() ?? '';
            final eventIdRaw = d is Map ? d['event_id'] : null;
            final eventId = eventIdRaw is int ? eventIdRaw : int.tryParse(eventIdRaw?.toString() ?? '');
            final meta = [if (dateStr.isNotEmpty) dateStr, if (source.isNotEmpty) source].join(' · ');
            return Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              elevation: 0,
              child: InkWell(
                onTap: () {
                  final id = eventId;
                  if (id != null && id > 0) {
                    _openEventDetail({'id': id});
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.calendar_today, color: AppColors.accent, size: 16.sp),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13.sp,
                                color: AppColors.navy,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (meta.isNotEmpty)
                              Text(
                                meta,
                                style: TextStyle(fontSize: 11.sp, color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      if (eventId != null)
                        Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18.sp),
                    ],
                  ),
                ),
              ),
            );
          })),
        ],
      ),
    );
  }
}
