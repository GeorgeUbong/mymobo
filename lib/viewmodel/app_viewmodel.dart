import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';

import '../model/card_model.dart';
import '../model/user_model.dart';
import '../repository/auth_repository.dart';
import '../repository/storage_repository.dart';
import '../repository/settings_repository.dart';

enum SplashDestination { start, home, authFailed }

/// The one global viewmodel: talks to the repositories and feeds the screens.
class AppViewModel extends ChangeNotifier {
  final AuthRepository _auth;
  final CardStorageRepository _cardStorage;
  final SettingsRepository _settings;

  AppViewModel({
    required AuthRepository auth,
    required CardStorageRepository cardStorage,
    required SettingsRepository settings,
  })  : _auth = auth,
        _cardStorage = cardStorage,
        _settings = settings;

  // ======================= STATE =======================

  UserModel? _user;
  ThemeMode _themeMode = ThemeMode.system;
  bool _biometricEnabled = false;
  String? _profileImagePath;

  List<CardModel> _cards = [];
  final Set<String> _revealed = {};
  bool _cardsLoading = false;

  UserModel? get user => _user;
  bool get hasUser => _user != null;
  ThemeMode get themeMode => _themeMode;
  bool get biometricEnabled => _biometricEnabled;
  String? get profileImagePath => _profileImagePath;

  UnmodifiableListView<CardModel> get cards => UnmodifiableListView(_cards);
  bool get cardsLoading => _cardsLoading;
  bool isRevealed(String id) => _revealed.contains(id);

  // ======================= STARTUP =======================

  /// Call in main() before runApp so the saved theme shows on the first frame.
  Future<void> load() async {
    _user = await _settings.getUser();
    _themeMode = await _settings.getThemeMode();
    _biometricEnabled = await _settings.getBiometricEnabled();
    _profileImagePath = await _settings.getProfileImagePath();
    await loadCards();
    notifyListeners();
  }

  // ======================= SPLASH =======================

  /// Shows the logo briefly, then decides where to go.
  Future<SplashDestination> runSplash() async {
    final results = await Future.wait([
      Future.delayed(const Duration(milliseconds: 1800)),
      _resolveSplashAuth(),
    ]);
    return results[1] as SplashDestination;
  }

  Future<SplashDestination> _resolveSplashAuth() async {
    if (!hasUser) return SplashDestination.start;
    if (!_biometricEnabled) return SplashDestination.home;
    final ok = await _auth.authenticate(reason: 'Unlock mymobo');
    return ok ? SplashDestination.home : SplashDestination.authFailed;
  }

  /// For a "Try again" button when the splash auth fails.
  Future<bool> retryUnlock() => _auth.authenticate(reason: 'Unlock mymobo');

  // ======================= AUTH GUARD =======================

  /// Biometric off -> no prompt, returns true.
  Future<bool> requireAuth(String reason) async {
    if (!_biometricEnabled) return true;
    return _auth.authenticate(reason: reason);
  }

  // ======================= START SCREEN (auto-swipe) =======================

  static const startPageCount = 2;
  final PageController startPageController = PageController();
  Timer? _startTimer;
  int _startPage = 0;
  int get startPage => _startPage;

  void startAutoSwipe() {
    _startTimer?.cancel();
    _startTimer = Timer.periodic(const Duration(seconds: 7), (_) {
      if (!startPageController.hasClients) return;
      startPageController.animateToPage(
        (_startPage + 1) % startPageCount,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  /// Hook to PageView.onPageChanged (also restarts the timer after a manual swipe).
  void onStartPageChanged(int index) {
    _startPage = index;
    notifyListeners();
    startAutoSwipe();
  }

  /// Call when Continue is tapped.
  void stopAutoSwipe() {
    _startTimer?.cancel();
    _startTimer = null;
  }

  // ======================= USER / SETTINGS =======================

  /// Used by both sign up and "edit details" in settings.
  Future<void> saveUser(UserModel user) async {
    await _settings.saveUser(user);
    _user = user;
    notifyListeners();
  }

  Future<void> setProfileImage(String? path) async {
    await _settings.saveProfileImagePath(path);
    _profileImagePath = path;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _settings.saveThemeMode(mode);
  }

  /// Turning it on or off requires a successful auth.
  /// Returns true if the change was applied.
  Future<bool> setBiometricEnabled(bool enable) async {
    if (enable && !await _auth.isDeviceSupported()) return false;

    final ok = await _auth.authenticate(
      reason: enable
          ? 'Confirm to enable biometric protection'
          : 'Confirm to turn off biometric protection',
    );
    if (!ok) return false;

    await _settings.saveBiometricEnabled(enable);
    _biometricEnabled = enable;
    notifyListeners();
    return true;
  }

  // ======================= CARDS =======================

  Future<void> loadCards() async {
    _cardsLoading = true;
    notifyListeners();
    _cards = await _cardStorage.getCards();
    _cardsLoading = false;
    notifyListeners();
  }

  /// Name is always visible; details need auth (skipped if biometric is off).
  Future<bool> revealCard(String id) async {
    if (isRevealed(id)) return true;
    final ok = await requireAuth('Authenticate to view card details');
    if (ok) {
      _revealed.add(id);
      notifyListeners();
    }
    return ok;
  }

  void hideCard(String id) {
    if (_revealed.remove(id)) notifyListeners();
  }

  /// Call when leaving home or when the app goes to the background.
  void hideAllCards() {
    if (_revealed.isEmpty) return;
    _revealed.clear();
    notifyListeners();
  }

  Future<void> addCard({
    required String name,
    required String number,
    required String cvv,
    required String expiry,
    required CardTemplate template,
  }) async {
    final digits = number.replaceAll(RegExp(r'\s'), '');
    final card = CardModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
      template: template,
      number: digits,
      cvv: cvv,
      expiry: expiry,
      type: CardType.detect(digits),
    );
    await _cardStorage.saveCard(card);
    _cards = [..._cards, card];
    notifyListeners();
  }

  Future<void> toggleCardActive(String id) async {
    final i = _cards.indexWhere((c) => c.id == id);
    if (i < 0) return;
    final updated = _cards[i].copyWith(isActive: !_cards[i].isActive);
    await _cardStorage.saveCard(updated);
    _cards = [..._cards]..[i] = updated;
    notifyListeners();
  }

  Future<bool> deleteCard(String id) async {
    final ok = await requireAuth('Authenticate to delete this card');
    if (!ok) return false;
    await _cardStorage.deleteCard(id);
    _cards = _cards.where((c) => c.id != id).toList();
    _revealed.remove(id);
    notifyListeners();
    return true;
  }

  // ======================= VALIDATORS (error text, or null if valid) =======================

  static String? validateCardName(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Enter a name for this card' : null;

  static String? validateCardNumber(String? v) {
    final n = (v ?? '').replaceAll(RegExp(r'\s'), '');
    if (!RegExp(r'^\d{13,19}$').hasMatch(n)) return 'Enter a valid card number';
    return _luhn(n) ? null : 'Card number is not valid';
  }

  static String? validateExpiry(String? v) {
    final m = RegExp(r'^(\d{2})/(\d{2})$').firstMatch((v ?? '').trim());
    if (m == null) return 'Use MM/YY';
    final month = int.parse(m.group(1)!);
    final year = 2000 + int.parse(m.group(2)!);
    if (month < 1 || month > 12) return 'Invalid month';
    final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);
    return endOfMonth.isBefore(DateTime.now()) ? 'Card has expired' : null;
  }

  static String? validateCvv(String? v, {CardType? type}) {
    final len = type == CardType.amex ? 4 : 3;
    return RegExp('^\\d{$len}\$').hasMatch(v ?? '') ? null : 'Enter $len digits';
  }

  static bool _luhn(String digits) {
    var sum = 0;
    var alt = false;
    for (var i = digits.length - 1; i >= 0; i--) {
      var d = int.parse(digits[i]);
      if (alt) {
        d *= 2;
        if (d > 9) d -= 9;
      }
      sum += d;
      alt = !alt;
    }
    return sum % 10 == 0;
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    startPageController.dispose();
    super.dispose();
  }
}