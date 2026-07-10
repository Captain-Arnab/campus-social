import 'package:flutter/material.dart';

import 'app_loading_screen.dart';

/// Runs [prepare] once, shows [AppLoadingScreen] until it completes, then [child].
class ScreenLoadGate extends StatefulWidget {
  final Future<void> Function(BuildContext context) prepare;
  final Widget child;
  final String? loadingMessage;

  const ScreenLoadGate({
    super.key,
    required this.prepare,
    required this.child,
    this.loadingMessage,
  });

  @override
  State<ScreenLoadGate> createState() => _ScreenLoadGateState();
}

class _ScreenLoadGateState extends State<ScreenLoadGate> {
  bool _ready = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _runPrepare();
  }

  Future<void> _runPrepare() async {
    try {
      await widget.prepare(context);
      if (mounted) setState(() => _ready = true);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Could not load. Please try again.'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _error = null;
                      _ready = false;
                    });
                    _runPrepare();
                  },
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF5F15)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (!_ready) {
      return AppLoadingScreen(message: widget.loadingMessage);
    }
    return widget.child;
  }
}
