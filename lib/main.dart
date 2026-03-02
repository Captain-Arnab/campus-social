import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'views/splash_view.dart';
import 'services/notification_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
  // Defer Firebase + FCM until after first frame so platform channel is ready
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      await Firebase.initializeApp();
      await NotificationService.init();
    } catch (e, st) {
      debugPrint('Firebase init error: $e');
      debugPrint('$st');
    }
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
        return GetMaterialApp(
          title: 'Campus Social',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.orange,
            useMaterial3: true,
          ),
          home: const OnboardingView(),
        );
      },
    );
  }
}