
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodel/app_viewmodel.dart';
import 'signUp_screen.dart';

class _IntroData {
  final String image;
  final String heading;
  final String body;

  const _IntroData(this.image, this.heading, this.body);
}

const _pages = [
  _IntroData(
    'assets/cards.png',
    'All your cards, on one platform',
    'Add your cards, give them names and colours you love, and keep them neatly organised in one place.',
  ),
  _IntroData(
    'assets/hiden.png',
    'Locked behind you',
    'Your card details are encrypted and protected with your fingerprint or face, so only you can see them.',
  ),
];

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  late final AppViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = context.read<AppViewModel>();
    _vm.startAutoSwipe();
  }

  @override
  void dispose() {
    _vm.stopAutoSwipe();
    super.dispose();
  }

  void _continue() {
    _vm.stopAutoSwipe();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const SignUpScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AppViewModel>();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: vm.startPageController,
                onPageChanged: vm.onStartPageChanged,
                itemCount: _pages.length,
                itemBuilder: (_, i) {
                  final page = _pages[i];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 340,
                            height: 340,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: scheme.surfaceContainerLow,
                            ),
                            child: Image.asset(
                              page.image,
                              width: 200,
                              height: 200,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            page.heading,
                            textAlign: TextAlign.left,
                            style: text.headlineSmall?.copyWith(
                              fontFamily: 'Lobster',
                              fontWeight: FontWeight.w800,
                              color: scheme.primary,
                              fontSize: 32,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            page.body,
                            textAlign: TextAlign.left,
                            style: text.bodyLarge?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final active = i == vm.startPage;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active
                        ? scheme.primary
                        : scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: scheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(80),
                  ),
                ),
                onPressed: _continue,
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
