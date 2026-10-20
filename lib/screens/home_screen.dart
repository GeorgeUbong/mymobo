import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../viewmodel/app_viewmodel.dart';
import '../viewmodel/digi_widget.dart';
import 'addCard_screen.dart';
import 'cardview_screen.dart';
import 'settings_screen.dart';

/// Shell with the bottom bar: Home (cards) and Settings tabs.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [_CardsTab(), SettingsScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) {
          if (i == _tab) return;
          context.read<AppViewModel>().hideAllCards();
          setState(() => _tab = i);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _CardsTab extends StatelessWidget {
  const _CardsTab();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AppViewModel>();
    final scheme = Theme.of(context).colorScheme;
    final firstName = vm.user?.name.trim().split(' ').first;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          firstName == null || firstName.isEmpty
              ? 'My Wallet'
              : 'Hi, $firstName',
          style: GoogleFonts.lobster(
            textStyle: TextStyle(
              fontSize: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
      body: _body(context, vm, scheme),
      floatingActionButton: FloatingActionButton(
        backgroundColor: scheme.primary, // theme colour from AppTheme
        foregroundColor: scheme.onPrimary,
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AddCardScreen())),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _body(BuildContext context, AppViewModel vm, ColorScheme scheme) {
    if (vm.cardsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.cards.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.credit_card_off_outlined,
                size: 72,
                color: scheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'No cards yet',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the + button to add your first card.',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: vm.cards.length,
      separatorBuilder: (_, __) => const SizedBox(height: 18),
      itemBuilder: (_, i) {
        final card = vm.cards[i];
        return DigiCardWidget(
          card: card,
          showDetails: false, // list shows names only; details need auth
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => CardViewScreen(cardId: card.id)),
          ),
        );
      },
    );
  }
}
