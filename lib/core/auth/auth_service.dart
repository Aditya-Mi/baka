import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
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
  static const _kSkipLock    = 'skip_lock_v2';       // SecureStorage (current)
  static const _kSkipLockLeg = 'skip_lock_screen';   // SharedPreferences (legacy)
  static const _kAuthMode    = 'auth_mode';
  static const _kCustomPin   = 'custom_pin';
  static const _kPinSalt     = 'pin_salt';

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
    final secureVal = await _storage.read(key: _kSkipLock);
    if (secureVal != null) return secureVal == 'true';

    // Migrate from SharedPreferences on first access
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getBool(_kSkipLockLeg) ?? false;
    await _storage.write(key: _kSkipLock, value: legacy ? 'true' : 'false');
    await prefs.remove(_kSkipLockLeg);
    return legacy;
  }

  Future<void> setSkipLock(bool skip) async {
    await _storage.write(key: _kSkipLock, value: skip ? 'true' : 'false');
    // Remove legacy key if it still exists
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSkipLockLeg);
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

  String _generateSalt() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode(salt + pin);
    return sha256.convert(bytes).toString();
  }

  Future<void> setPin(String pin) async {
    final salt = _generateSalt();
    await _storage.write(key: _kPinSalt, value: salt);
    await _storage.write(key: _kCustomPin, value: _hashPin(pin, salt));
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: _kCustomPin);
    if (stored == null) return false;

    // Plaintext PINs are ≤8 chars; SHA-256 hex is always 64 chars — migrate on match
    if (stored.length != 64) {
      if (stored != pin) return false;
      await setPin(pin); // re-hash going forward
      return true;
    }

    final salt = await _storage.read(key: _kPinSalt);
    if (salt == null) return false;
    return _hashPin(pin, salt) == stored;
  }

  Future<bool> hasPin() async =>
      (await _storage.read(key: _kCustomPin)) != null;

  Future<void> clearPin() async {
    await _storage.delete(key: _kCustomPin);
    await _storage.delete(key: _kPinSalt);
  }

  // ── Clear all ────────────────────────────────────────────────────────────────

  Future<void> clearConfig() async {
    await _storage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSkipLockLeg);
  }
}
