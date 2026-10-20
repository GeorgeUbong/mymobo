import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Handles biometric / device authentication.
/// Used for (1) unlocking the app and (2) revealing card details.
class AuthRepository {
  final LocalAuthentication _auth;

  AuthRepository({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  /// True if the device can authenticate at all
  /// (biometrics enrolled, or a device PIN/pattern/passcode set).
  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  /// True if at least one biometric (fingerprint/face) is enrolled.
  Future<bool> hasBiometrics() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return false;
      final available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  /// Prompts the user to authenticate.
  /// Returns true only if authentication succeeded.
  ///
  /// By default the device PIN/passcode is accepted as a fallback.
  /// Pass [biometricOnly] = true to require fingerprint/face strictly.
  Future<bool> authenticate({
    String reason = 'Please authenticate to continue',
    bool biometricOnly = false,
  }) async {
    try {
      if (!await isDeviceSupported()) return false;

      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: biometricOnly,
        // Retry authentication if the app is backgrounded during the prompt.
        persistAcrossBackgrounding: true,
      );
    } on PlatformException {
      // Not enrolled, locked out, user cancelled, etc.
      return false;
    }
  }
}
