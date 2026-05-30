import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_service.dart';

export 'auth_service.dart' show AuthMode;

class AuthState {
  final bool isLocked;
  final bool biometricsEnabled;
  final bool configured;
  final bool isInitialized;
  final AuthMode authMode;

  const AuthState({
    required this.isLocked,
    required this.biometricsEnabled,
    required this.configured,
    required this.authMode,
    this.isInitialized = false,
  });

  AuthState copyWith({
    bool? isLocked,
    bool? biometricsEnabled,
    bool? configured,
    bool? isInitialized,
    AuthMode? authMode,
  }) =>
      AuthState(
        isLocked: isLocked ?? this.isLocked,
        biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
        configured: configured ?? this.configured,
        isInitialized: isInitialized ?? this.isInitialized,
        authMode: authMode ?? this.authMode,
      );
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _init();
    return const AuthState(
      isLocked: true,
      biometricsEnabled: false,
      configured: false,
      authMode: AuthMode.none,
    );
  }

  Future<void> _init() async {
    final svc        = AuthService.instance;
    final configured = await svc.isConfigured();
    final bio        = await svc.isBiometricsEnabled();
    final skipLock   = await svc.shouldSkipLock();
    final mode       = await svc.getAuthMode();

    // Derive effective mode: legacy users with skipLock=true → none
    final effectiveMode = skipLock ? AuthMode.none : mode;

    state = AuthState(
      isLocked: configured && !skipLock,
      biometricsEnabled: bio,
      configured: configured,
      authMode: effectiveMode,
      isInitialized: true,
    );
  }

  void lock() {
    if (state.authMode == AuthMode.none) return;
    state = state.copyWith(isLocked: true);
  }

  // ── Unlock methods ────────────────────────────────────────────────────────────

  /// Biometric unlock — used by biometric and biometricAndPin modes.
  Future<bool> unlock() async {
    final skip = await AuthService.instance.shouldSkipLock();
    if (skip) {
      state = state.copyWith(isLocked: false);
      return true;
    }
    final success = await AuthService.instance.authenticate();
    if (success) state = state.copyWith(isLocked: false);
    return success;
  }

  /// Custom PIN unlock — used by pin and biometricAndPin modes.
  Future<bool> unlockWithPin(String pin) async {
    final success = await AuthService.instance.verifyPin(pin);
    if (success) state = state.copyWith(isLocked: false);
    return success;
  }

  // ── Setup methods ─────────────────────────────────────────────────────────────

  /// Biometric-only setup. Returns true on success.
  Future<bool> setupBiometric() async {
    final deviceSupported = await AuthService.instance.isDeviceSupported();
    if (!deviceSupported) return false;

    final success = await AuthService.instance.authenticate(
      reason: 'Verify to enable biometric lock',
      biometricOnly: true,
    );
    if (success) {
      await AuthService.instance.setConfigured(biometrics: true);
      await AuthService.instance.setSkipLock(false);
      await AuthService.instance.setAuthMode(AuthMode.biometric);
      state = const AuthState(
        isLocked: false, biometricsEnabled: true,
        configured: true, authMode: AuthMode.biometric, isInitialized: true,
      );
    }
    return success;
  }

  /// Biometric + custom PIN setup. Verifies biometric works, then stores PIN.
  Future<bool> setupBiometricAndPin(String pin) async {
    final deviceSupported = await AuthService.instance.isDeviceSupported();
    if (!deviceSupported) return false;

    final success = await AuthService.instance.authenticate(
      reason: 'Verify fingerprint to set up combined lock',
      biometricOnly: true,
    );
    if (success) {
      await AuthService.instance.setConfigured(biometrics: true);
      await AuthService.instance.setSkipLock(false);
      await AuthService.instance.setPin(pin);
      await AuthService.instance.setAuthMode(AuthMode.biometricAndPin);
      state = const AuthState(
        isLocked: false, biometricsEnabled: true,
        configured: true, authMode: AuthMode.biometricAndPin, isInitialized: true,
      );
    }
    return success;
  }

  /// PIN-only setup. No biometric prompt.
  Future<void> setupPin(String pin) async {
    await AuthService.instance.setConfigured(biometrics: false);
    await AuthService.instance.setSkipLock(false);
    await AuthService.instance.setPin(pin);
    await AuthService.instance.setAuthMode(AuthMode.pin);
    state = const AuthState(
      isLocked: false, biometricsEnabled: false,
      configured: true, authMode: AuthMode.pin, isInitialized: true,
    );
  }

  /// No lock.
  Future<void> skipSetup() async {
    await AuthService.instance.setConfigured(biometrics: false);
    await AuthService.instance.setSkipLock(true);
    await AuthService.instance.setAuthMode(AuthMode.none);
    await AuthService.instance.clearPin();
    state = const AuthState(
      isLocked: false, biometricsEnabled: false,
      configured: true, authMode: AuthMode.none, isInitialized: true,
    );
  }

  // Legacy compat — still called from settings sheet for biometric toggle
  Future<bool> setupAuth({bool biometricOnly = false}) => setupBiometric();
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
