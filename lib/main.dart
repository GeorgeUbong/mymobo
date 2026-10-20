import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'repository/auth_repository.dart';
import 'repository/storage_repository.dart';
import 'repository/settings_repository.dart';
import 'screens/splash_screen.dart';
import 'themes/app_themes.dart';
import 'viewmodel/app_viewmodel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appVm = AppViewModel(
    auth: AuthRepository(),
    cardStorage: CardStorageRepository(),
    settings: SettingsRepository(),
  );
  await appVm.load(); // saved theme applies on the very first frame

  runApp(ChangeNotifierProvider.value(value: appVm, child: const MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Re-hide revealed card details whenever the app goes to the background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      context.read<AppViewModel>().hideAllCards();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = context.select<AppViewModel, ThemeMode>((vm) => vm.themeMode);

    return MaterialApp(
      title: 'DigiWallet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode, // system / light / dark
      home: const SplashScreen(),
    );
  }
}