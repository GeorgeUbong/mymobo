import 'dart:convert';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../model/user_model.dart';

/// Stores the user profile and app preferences
/// (theme mode, biometric switch, profile image path).
class SettingsRepository {
  static const _userKey = 'digiwallet_user';
  static const _themeKey = 'digiwallet_theme_mode';
  static const _biometricKey = 'digiwallet_biometric_enabled';
  static const _imageKey = 'digiwallet_profile_image';

  final FlutterSecureStorage _storage;
  SettingsRepository({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<UserModel?> getUser() async {
    try {
      final raw = await _storage.read(key: _userKey);
      if (raw == null) return null;
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUser(UserModel user) =>
      _storage.write(key: _userKey, value: jsonEncode(user.toJson()));

  Future<ThemeMode> getThemeMode() async {
    final raw = await _storage.read(key: _themeKey);
    return ThemeMode.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> saveThemeMode(ThemeMode mode) =>
      _storage.write(key: _themeKey, value: mode.name);

  Future<bool> getBiometricEnabled() async =>
      (await _storage.read(key: _biometricKey)) == 'true';

  Future<void> saveBiometricEnabled(bool value) =>
      _storage.write(key: _biometricKey, value: value.toString());

  Future<String?> getProfileImagePath() => _storage.read(key: _imageKey);

  Future<void> saveProfileImagePath(String? path) => path == null
      ? _storage.delete(key: _imageKey)
      : _storage.write(key: _imageKey, value: path);
}