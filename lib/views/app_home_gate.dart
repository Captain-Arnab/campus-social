import 'package:flutter/material.dart';
import '../data/pref_service.dart';
import '../widgets/app_loading_screen.dart';
import 'bootstrap_views.dart';

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
        _child = const OnboardingBootstrapView();
      } else if (loggedIn) {
        _child = const HomeBootstrapView();
      } else {
        _child = const LoginBootstrapView();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = _child;
    if (c == null) {
      return const AppLoadingScreen(message: 'Starting MiCampus...');
    }
    return c;
  }
}
