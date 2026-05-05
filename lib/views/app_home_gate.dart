import 'package:flutter/material.dart';
import '../data/pref_service.dart';
import 'splash_view.dart';
import 'login_view.dart';
import 'home_view.dart';

/// Chooses first screen: onboarding once, then login or home based on session.
class AppHomeGate extends StatefulWidget {
  const AppHomeGate({super.key});

  @override
  State<AppHomeGate> createState() => _AppHomeGateState();
}

class _AppHomeGateState extends State<AppHomeGate> {
  Widget? _child;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final onboardingDone = await PrefService.isOnboardingCompleted();
    final loggedIn = await PrefService.isLoggedIn();
    if (!mounted) return;
    setState(() {
      if (!onboardingDone) {
        _child = const OnboardingView();
      } else if (loggedIn) {
        _child = const HomeView();
      } else {
        _child = const LoginView();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = _child;
    if (c == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFF5F15))),
      );
    }
    return c;
  }
}
