import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../base/constant.dart';
import '../theme/app_theme.dart';
import 'app_network_image.dart';

String? _youtubeVideoId(String raw) {
  final u = Uri.tryParse(raw.trim());
  if (u == null) return null;
  final host = u.host.toLowerCase();
  if (host == 'youtu.be') {
    return u.pathSegments.isNotEmpty ? u.pathSegments.first : null;
  }
  if (host.contains('youtube.com')) {
    final v = u.queryParameters['v'];
    if (v != null && v.isNotEmpty) return v;
    final seg = u.pathSegments;
    if (seg.length >= 2 && seg[0] == 'embed') return seg[1];
    if (seg.length >= 2 && seg[0] == 'shorts') return seg[1];
  }
  return null;
}

/// Sliding ads above the Explore header (admin `ad_posts`).
class HomeAdCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> posts;

  const HomeAdCarousel({super.key, required this.posts});

  @override
  State<HomeAdCarousel> createState() => _HomeAdCarouselState();
}

class _HomeAdCarouselState extends State<HomeAdCarousel> {
  late final PageController _pageController;
  int _index = 0;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _startAutoScroll();
  }

  @override
  void didUpdateWidget(covariant HomeAdCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.posts.length != widget.posts.length) {
      _restartAutoScroll();
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (widget.posts.length <= 1) return;
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _advanceSlide());
  }

  void _restartAutoScroll() {
    _autoScrollTimer?.cancel();
    if (!mounted) return;
    if (widget.posts.length <= 1) return;
    _startAutoScroll();
  }

  Future<void> _advanceSlide() async {
    if (!mounted || widget.posts.length <= 1) return;
    if (!_pageController.hasClients) return;
    final next = (_index + 1) % widget.posts.length;
    await _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  bool get _preferCompactHeight {
    if (widget.posts.isEmpty) return true;
    return widget.posts.every((m) {
      final mediaType = (m['media_type'] ?? '').toString().trim().toLowerCase();
      final mediaUrl = (m['media_url'] ?? '').toString().trim();
      final linkUrl = (m['link_url'] ?? '').toString().trim();
      if (mediaType == 'image' || mediaType == 'video') return false;
      if (mediaUrl.isNotEmpty && mediaType != 'link') return false;
      return mediaType == 'link' || linkUrl.isNotEmpty || mediaUrl.isEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.posts.isEmpty) return const SizedBox.shrink();
    final compact = _preferCompactHeight;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: compact ? 118.h : 168.h,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.posts.length,
            onPageChanged: (i) {
              setState(() => _index = i);
              _restartAutoScroll();
            },
            padEnds: true,
            itemBuilder: (context, i) {
              final m = widget.posts[i];
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 6.w,
                  vertical: compact ? 4.h : 8.h,
                ),
                child: _AdSlideCard(data: m, isActive: i == _index),
              );
            },
          ),
        ),
        if (widget.posts.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.posts.length, (i) {
              final on = i == _index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
                width: on ? 18.w : 6.w,
                height: 6.h,
                decoration: BoxDecoration(
                  color: on ? AppColors.accent : AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
      ],
    );
  }
}

class _AdSlideCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isActive;

  const _AdSlideCard({required this.data, required this.isActive});

  String _str(String k) => (data[k] ?? '').toString().trim();

  @override
  Widget build(BuildContext context) {
    final title = _str('title');
    final mediaType = _str('media_type').toLowerCase();
    final mediaUrl = _str('media_url');
    final linkUrl = _str('link_url');
    final link = linkUrl.isNotEmpty ? linkUrl : mediaUrl;

    Widget inner;
    if (!isActive) {
      inner = _AdPlaceholder(title: title, mediaType: mediaType, mediaUrl: mediaUrl);
    } else if (mediaType == 'link' || (mediaType.isEmpty && linkUrl.isNotEmpty && mediaUrl.isEmpty)) {
      inner = _LinkAdBody(url: link, title: title);
    } else if (mediaType == 'image' || (mediaUrl.isNotEmpty && _looksImage(mediaUrl))) {
      inner = _ImageAdBody(url: Constant.uploadPublicUrl(mediaUrl));
    } else if (mediaType == 'video' || _youtubeVideoId(mediaUrl) != null || _looksVideo(mediaUrl)) {
      final yt = _youtubeVideoId(mediaUrl);
      if (yt != null) {
        inner = _YoutubeEmbedWebView(videoId: yt, title: title);
      } else if (mediaUrl.isNotEmpty) {
        inner = _NetworkVideoTile(url: Constant.uploadPublicUrl(mediaUrl));
      } else {
        inner = _LinkAdBody(url: link, title: title);
      }
    } else if (link.isNotEmpty) {
      inner = _LinkAdBody(url: link, title: title);
    } else {
      inner = Center(
        child: Text(title.isEmpty ? 'Sponsored' : title, textAlign: TextAlign.center),
      );
    }

    return Material(
      elevation: 0,
      borderRadius: BorderRadius.circular(AppRadius.card),
      clipBehavior: Clip.antiAlias,
      color: Colors.transparent,
      child: inner,
    );
  }

  bool _looksImage(String u) {
    final low = u.toLowerCase();
    return low.endsWith('.png') ||
        low.endsWith('.jpg') ||
        low.endsWith('.jpeg') ||
        low.endsWith('.gif') ||
        low.endsWith('.webp');
  }

  bool _looksVideo(String u) {
    final low = u.toLowerCase();
    return low.endsWith('.mp4') ||
        low.endsWith('.webm') ||
        low.endsWith('.mov') ||
        low.contains('.mp4?');
  }
}

class _LinkAdBody extends StatelessWidget {
  final String url;
  final String title;

  const _LinkAdBody({required this.url, required this.title});

  Future<void> _open() async {
    final u = Uri.tryParse(url);
    if (u == null) return;
    await launchUrl(u, mode: LaunchMode.externalApplication);
  }

  String get _hostLabel {
    final u = Uri.tryParse(url);
    final host = (u?.host ?? '').replaceFirst(RegExp(r'^www\.'), '');
    if (host.isEmpty) return 'Visit link';
    return 'Visit $host →';
  }

  String get _headline {
    if (title.isNotEmpty) return title;
    final lower = url.toLowerCase();
    if (lower.contains('gnu') || lower.contains('admission')) {
      return 'Admissions are open now';
    }
    return 'Campus announcement';
  }

  IconData get _badgeIcon {
    final t = '$_headline $url'.toLowerCase();
    if (t.contains('admission') || t.contains('gnu') || t.contains('graduat')) {
      return Icons.school_rounded;
    }
    return Icons.campaign_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accent.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _open,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.22)),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  color: AppColors.accent,
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
                    child: Row(
                      children: [
                        Container(
                          width: 44.w,
                          height: 44.w,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _badgeIcon,
                            color: AppColors.accent,
                            size: 24.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'ANNOUNCEMENT',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: AppColors.accent,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                _headline,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.navy,
                                  height: 1.25,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                _hostLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14.sp,
                          color: AppColors.accent,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageAdBody extends StatelessWidget {
  final String url;

  const _ImageAdBody({required this.url});

  @override
  Widget build(BuildContext context) {
    final cacheW = (MediaQuery.sizeOf(context).width * MediaQuery.devicePixelRatioOf(context)).round().clamp(280, 900);
    return AppNetworkImage(
      url: url,
      fit: BoxFit.cover,
      width: double.infinity,
      filterQuality: FilterQuality.medium,
      cacheWidth: cacheW,
      errorWidget: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 40)),
    );
  }
}

class _AdPlaceholder extends StatelessWidget {
  final String title;
  final String mediaType;
  final String mediaUrl;

  const _AdPlaceholder({
    required this.title,
    required this.mediaType,
    required this.mediaUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isImage = mediaType == 'image' ||
        mediaUrl.toLowerCase().endsWith('.png') ||
        mediaUrl.toLowerCase().endsWith('.jpg') ||
        mediaUrl.toLowerCase().endsWith('.jpeg') ||
        mediaUrl.toLowerCase().endsWith('.webp');
    if (isImage && mediaUrl.isNotEmpty) {
      final cacheW = (MediaQuery.sizeOf(context).width * MediaQuery.devicePixelRatioOf(context)).round().clamp(280, 900);
      return AppNetworkImage(
        url: Constant.uploadPublicUrl(mediaUrl),
        fit: BoxFit.cover,
        width: double.infinity,
        filterQuality: FilterQuality.low,
        cacheWidth: cacheW,
        errorWidget: (_, __, ___) => _placeholderBody(),
      );
    }
    return _placeholderBody();
  }

  Widget _placeholderBody() {
    return ColoredBox(
      color: Colors.grey.shade100,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.campaign_outlined, size: 36, color: Colors.grey.shade500),
              if (title.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Inline playback via YouTube embed (avoids `youtube_player_flutter` ↔ Firebase resolver clash).
class _YoutubeEmbedWebView extends StatefulWidget {
  final String videoId;
  final String title;

  const _YoutubeEmbedWebView({required this.videoId, required this.title});

  @override
  State<_YoutubeEmbedWebView> createState() => _YoutubeEmbedWebViewState();
}

class _YoutubeEmbedWebViewState extends State<_YoutubeEmbedWebView> {
  late final WebViewController _web;

  @override
  void initState() {
    super.initState();
    final uri = Uri.parse(
      'https://www.youtube.com/embed/${widget.videoId}?playsinline=1&modestbranding=1',
    );
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..loadRequest(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
            child: Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        Expanded(child: WebViewWidget(controller: _web)),
      ],
    );
  }
}

class _NetworkVideoTile extends StatefulWidget {
  final String url;

  const _NetworkVideoTile({required this.url});

  @override
  State<_NetworkVideoTile> createState() => _NetworkVideoTileState();
}

class _NetworkVideoTileState extends State<_NetworkVideoTile> {
  VideoPlayerController? _c;
  bool _err = false;

  @override
  void initState() {
    super.initState();
    _c = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) setState(() {});
      }).catchError((_) {
        if (mounted) setState(() => _err = true);
      });
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_err) {
      return Center(
        child: TextButton.icon(
          onPressed: () async {
            final u = Uri.tryParse(widget.url);
            if (u != null) await launchUrl(u, mode: LaunchMode.externalApplication);
          },
          icon: const Icon(Icons.play_circle_outline),
          label: const Text('Open video'),
        ),
      );
    }
    final c = _c;
    if (c == null || !c.value.isInitialized) {
      return const Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2)));
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(aspectRatio: c.value.aspectRatio, child: VideoPlayer(c)),
        IconButton.filled(
          style: IconButton.styleFrom(backgroundColor: Colors.black54),
          onPressed: () {
            if (c.value.isPlaying) {
              c.pause();
            } else {
              c.play();
            }
            setState(() {});
          },
          icon: Icon(c.value.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 40),
        ),
      ],
    );
  }
}
