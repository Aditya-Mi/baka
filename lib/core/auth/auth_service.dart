import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthMode { none, biometric, pin, biometricAndPin }

class AuthService {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  final _auth = LocalAuthentication();
  final _storage = const FlutterSecureStorage();

  static const _kConfigured  = 'auth_configured';
  static const _kBiometrics  = 'biometrics_enabled';
  static const _kSkipLock    = 'skip_lock_screen';
  static const _kAuthMode    = 'auth_mode';
  static const _kCustomPin   = 'custom_pin';

  Future<bool> isConfigured() async =>
      (await _storage.read(key: _kConfigured)) == 'true';

  Future<bool> isBiometricsEnabled() async =>
      (await _storage.read(key: _kBiometrics)) == 'true';

  Future<bool> canCheckBiometrics() async => _auth.canCheckBiometrics;

  Future<bool> isDeviceSupported() async => _auth.isDeviceSupported();

  Future<bool> authenticate({
    String reason = 'Open your journal',
    bool biometricOnly = false,
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> shouldSkipLock() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kSkipLock) ?? false;
  }

  Future<void> setSkipLock(bool skip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSkipLock, skip);
  }

  Future<void> setConfigured({bool biometrics = true}) async {
    await _storage.write(key: _kConfigured, value: 'true');
    await _storage.write(key: _kBiometrics, value: biometrics ? 'true' : 'false');
  }

  // ── Auth mode ────────────────────────────────────────────────────────────────

  Future<AuthMode> getAuthMode() async {
    final val = await _storage.read(key: _kAuthMode);
    return AuthMode.values.firstWhere(
      (m) => m.name == val,
      orElse: () => AuthMode.none,
    );
  }

  Future<void> setAuthMode(AuthMode mode) async {
    await _storage.write(key: _kAuthMode, value: mode.name);
  }

  // ── Custom PIN ───────────────────────────────────────────────────────────────

  Future<void> setPin(String pin) async {
    await _storage.write(key: _kCustomPin, value: pin);
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: _kCustomPin);
    return stored != null && stored == pin;
  }

  Future<bool> hasPin() async =>
      (await _storage.read(key: _kCustomPin)) != null;

  Future<void> clearPin() async => _storage.delete(key: _kCustomPin);

  // ── Clear all ────────────────────────────────────────────────────────────────

  Future<void> clearConfig() async {
    await _storage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSkipLock);
  }
}
