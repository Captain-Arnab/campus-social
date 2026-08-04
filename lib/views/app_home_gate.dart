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
    // SharedPreferences.getInstance is cached after first call, but the two
    // bool reads used to run sequentially — keep them concurrent.
    final results = await Future.wait<bool>([
      PrefService.isOnboardingCompleted(),
      PrefService.isLoggedIn(),
    ]);
    final onboardingDone = results[0];
    final loggedIn = results[1];
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
