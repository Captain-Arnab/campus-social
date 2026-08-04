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

/// Non-critical work after the first frame. Previously ran sequentially
/// (fonts → FCM → branding), adding seconds even though nothing here
/// blocks navigation to home/login.
Future<void> _startupDeferredServices() async {
  await Future.wait<void>([
    () async {
      try {
        await GoogleFonts.pendingFonts([GoogleFonts.plusJakartaSans()]);
      } catch (e, st) {
        debugPrint('Deferred startup (GoogleFonts): $e\n$st');
      }
    }(),
    () async {
      try {
        await NotificationService.init();
      } catch (e, st) {
        debugPrint('Deferred startup (NotificationService): $e\n$st');
      }
    }(),
    () async {
      try {
        await AppBranding.refresh();
      } catch (e, st) {
        debugPrint('Deferred startup (AppBranding): $e\n$st');
      }
    }(),
  ]);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Required before [runApp] for the background handler registration.
  // Keep this as the only awaited native work on the critical path.
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const MyApp());

  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_startupDeferredServices());
    unawaited(DeepLinkService.instance.init());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
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
