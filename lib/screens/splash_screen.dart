import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodel/app_viewmodel.dart';
import 'home_screen.dart';
import 'start_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _authFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    setState(() => _authFailed = false);
    final dest = await context.read<AppViewModel>().runSplash();
    if (!mounted) return;

    switch (dest) {
      case SplashDestination.start:
        _go(const StartScreen());
      case SplashDestination.home:
        _go(const HomeScreen());
      case SplashDestination.authFailed:
        setState(() => _authFailed = true);
    }
  }

  Future<void> _retry() async {
    final ok = await context.read<AppViewModel>().retryUnlock();
    if (ok && mounted) _go(const HomeScreen());
  }

  void _go(Widget page) {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Swap this Container for Image.asset
            Image.asset(
              'assets/mymobo.png',
              width: 300,
              height: 300,
              fit: BoxFit.contain,
            ),
           /*
            const SizedBox(height: 20),
            Text(
              'MyMoboWallet',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontFamily: 'Lobster',
                fontWeight: FontWeight.w800,
                fontSize: 42,
                color: scheme.primary,
              ),
            ),
           */
            const SizedBox(height: 32),
            if (_authFailed) ...[
              const Text('Authentication required'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Try again'),
              ),
            ] else
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
          ],
        ),
      ),
    );
  }
}
