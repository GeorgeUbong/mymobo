import 'package:flutter/foundation.dart';
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
    } on PlatformException catch (e) {
      debugPrint('isDeviceSupported failed: ${e.code}');
      return false;
    } on LocalAuthException catch (e) {
      debugPrint('isDeviceSupported failed: ${e.code}');
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
    } on PlatformException catch (e) {
      debugPrint('hasBiometrics failed: ${e.code}');
      return false;
    } on LocalAuthException catch (e) {
      debugPrint('hasBiometrics failed: ${e.code}');
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
      if (!await isDeviceSupported()) {
        debugPrint('Local auth: device not supported (no screen lock/biometrics set up)');
        return false;
      }

      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: biometricOnly,
        // Retry authentication if the app is backgrounded during the prompt.
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException catch (e) {
      // e.g. userCanceled, noBiometricsEnrolled, lockedOut, noActivity...
      debugPrint('Local auth failed: ${e.code}');
      return false;
    } on PlatformException catch (e) {
      debugPrint('Local auth platform error: ${e.code} ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Local auth error: $e');
      return false;
    }
  }
}