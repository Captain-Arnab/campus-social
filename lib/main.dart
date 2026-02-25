import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'views/splash_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const MyApp());
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