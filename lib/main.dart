import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_fonts/google_fonts.dart';
import 'data/app_branding.dart';
import 'views/app_home_gate.dart';
import 'services/deep_link_service.dart';
import 'services/notification_service.dart';

/// Work that used to run in [main] before [runApp], which blocked the first
/// frame and triggered "Skipped N frames" (Choreographer): FCM permission,
/// notification channels, [getInitialMessage], token fetch, [DeviceInfo],
/// HTTP token registration, topic subscribe, plus [AppBranding.refresh] HTTP.
/// None of that must complete before the first pixel is drawn.
Future<void> _startupDeferredServices() async {
  try {
    await NotificationService.init();
  } catch (e, st) {
    debugPrint('Deferred startup (NotificationService): $e\n$st');
  }
  try {
    await AppBranding.refresh();
  } catch (e, st) {
    debugPrint('Deferred startup (AppBranding): $e\n$st');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase must be initialized on the root isolate before the background
  // handler is registered or any plugin touches Firebase. This uses native
  // channels and cannot be moved to [compute]; it is typically shorter than
  // the FCM + HTTP chain we defer below.
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Paint the first frame immediately. Awaiting NotificationService + branding
  // here kept the UI thread busy through permission, platform channels, and
  // network I/O, causing frame drops before MaterialApp existed.
  runApp(const MyApp());

  // Run non-critical startup after the first frame is submitted — same
  // behavior as before, but the raster thread gets a chance to show UI first.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_startupDeferredServices());
    unawaited(DeepLinkService.instance.init());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ScreenUtil for responsive design
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        final base = ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFF5F15),
            brightness: Brightness.light,
            surface: const Color(0xFFF8F9FD),
          ),
        );
        return GetMaterialApp(
          title: 'MiCampus',
          debugShowCheckedModeBanner: false,
          theme: base.copyWith(
            scaffoldBackgroundColor: const Color(0xFFF8F9FD),
            splashFactory: InkSparkle.splashFactory,
            textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme),
            appBarTheme: const AppBarTheme(
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: true,
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
              },
            ),
          ),
          home: const AppHomeGate(),
        );
      },
    );
  }
}