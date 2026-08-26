import 'package:flutter/material.dart';

import '../data/app_bootstrap.dart';
import '../widgets/screen_load_gate.dart';
import 'home_view.dart';
import 'login_view.dart';
import 'splash_view.dart';

class HomeBootstrapView extends StatelessWidget {
  final int initialBottomTabIndex;
  final int initialMyEventsTabIndex;

  const HomeBootstrapView({
    super.key,
    this.initialBottomTabIndex = 0,
    this.initialMyEventsTabIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ScreenLoadGate(
      prepare: AppBootstrap.prepareHome,
      loadingMessage: 'Loading MiCampus...',
      child: HomeView(
        initialBottomTabIndex: initialBottomTabIndex,
        initialMyEventsTabIndex: initialMyEventsTabIndex,
      ),
    );
  }
}

class LoginBootstrapView extends StatelessWidget {
  const LoginBootstrapView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScreenLoadGate(
      prepare: AppBootstrap.prepareLogin,
      loadingMessage: 'Preparing login...',
      child: LoginView(),
    );
  }
}

class OnboardingBootstrapView extends StatelessWidget {
  const OnboardingBootstrapView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScreenLoadGate(
      prepare: AppBootstrap.prepareOnboarding,
      loadingMessage: 'Loading...',
      child: OnboardingView(),
    );
  }
}
