import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import 'package:baka/core/auth/auth_provider.dart';
import 'package:baka/core/notifications/notification_service.dart';
import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/features/lock/pin_keypad.dart';
import 'package:baka/features/onboarding/reminder_prompt_dialog.dart';
import 'package:baka/providers/user_provider.dart';
import 'package:baka/widgets/illustrations.dart';

class LockScreen extends HookConsumerWidget {
  const LockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth    = ref.watch(authProvider);
    final isSetup = !auth.configured;
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final t       = context.tokens;

    // ── Setup state ───────────────────────────────────────────────────────────
    final setupStep    = useState(0);          // 0=name 1=security 2=pin
    final pendingMode  = useState<AuthMode?>(null);
    final firstPin     = useState<String?>(null);
    final pinAttempt   = useState(0);          // bumped on each reset → new PinKeypad key
    final pinError     = useState<String?>(null);

    // ── Unlock state ──────────────────────────────────────────────────────────
    final showPinKeypad   = useState(auth.authMode == AuthMode.pin);
    final pinUnlockError  = useState<String?>(null);
    final pinUnlockAttempt = useState(0);
    final biometricLabel  = useState('Biometrics');
    final bioError        = useState<String?>(null);
    final bioInFlight     = useState(false);

    useEffect(() {
      _loadBiometricLabel(biometricLabel);
      return null;
    }, const []);

    // Derive whether logo should show
    final showLogo = isSetup
        ? setupStep.value < 2
        : (auth.authMode != AuthMode.pin && !showPinKeypad.value);

    // Determine if PIN controls are active (for layout)
    final showPin = isSetup ? setupStep.value == 2 : showPinKeypad.value;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: t.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Logo — centered in top space, animates out for PIN ──────
              if (showLogo)
                Expanded(
                  child: Center(
                    child: _Branding(
                      primary: t.primary,
                      muted: t.onSurfaceMuted,
                    ),
                  ),
                ),

              // ── Back button (PIN screens only) ──────────────────────────
              if (showPin)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back_ios_new,
                          size: 18, color: t.onSurfaceMuted),
                      onPressed: () {
                        if (isSetup) {
                          firstPin.value = null;
                          pinError.value = null;
                          pinAttempt.value++;
                          setupStep.value = 1;
                        } else {
                          showPinKeypad.value = false;
                          pinUnlockError.value = null;
                        }
                      },
                    ),
                  ),
                ),

              // ── Main content ────────────────────────────────────────────
              // PIN screens: full remaining height
              // Normal screens: fixed at bottom
              if (showPin)
                Expanded(
                  child: _PinArea(
                        isSetup: isSetup,
                        firstPin: firstPin.value,
                        pinAttempt: pinAttempt.value,
                        pinError: pinError.value,
                        pinUnlockError: pinUnlockError.value,
                        pinUnlockAttempt: pinUnlockAttempt.value,
                        onSetupFirstPin: (pin) {
                          firstPin.value = pin;
                          pinError.value = null;
                        },
                        onSetupConfirmPin: (pin) async {
                          if (pin != firstPin.value) {
                            pinError.value = 'PINs don\'t match. Try again.';
                            firstPin.value = null;
                            pinAttempt.value++;
                            return;
                          }
                          final mode = pendingMode.value ?? AuthMode.pin;
                          if (mode == AuthMode.biometricAndPin) {
                            final ok = await ref
                                .read(authProvider.notifier)
                                .setupBiometricAndPin(pin);
                            if (!ok && context.mounted) {
                              await ref.read(authProvider.notifier).setupPin(pin);
                            }
                          } else {
                            await ref.read(authProvider.notifier).setupPin(pin);
                          }
                          if (context.mounted) await _finishSetup(context);
                        },
                        onUnlockPin: (pin) async {
                          final ok = await ref
                              .read(authProvider.notifier)
                              .unlockWithPin(pin);
                          if (ok && context.mounted) {
                            context.go('/');
                          } else {
                            pinUnlockError.value = 'Wrong PIN. Try again.';
                            pinUnlockAttempt.value++;
                          }
                        },
                      ),
                )
              else
                // Normal (non-PIN) controls — pinned to bottom
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 8, 32, 40),
                  child: isSetup
                      ? SingleChildScrollView(
                          child: _SetupControls(
                            step: setupStep.value,
                            onNameDone: (name) {
                              ref.read(userProvider.notifier).setName(name);
                              setupStep.value = 1;
                            },
                            onBiometricOnly: () async {
                              bioInFlight.value = true;
                              bioError.value = null;
                              try {
                                final ok = await ref
                                    .read(authProvider.notifier)
                                    .setupBiometric();
                                if (ok && context.mounted) {
                                  await _finishSetup(context);
                                } else if (!ok) {
                                  bioError.value = 'Biometric setup failed.';
                                }
                              } catch (_) {
                                bioError.value = 'Something went wrong.';
                              } finally {
                                bioInFlight.value = false;
                              }
                            },
                            onBiometricAndPin: () {
                              pendingMode.value = AuthMode.biometricAndPin;
                              firstPin.value = null;
                              pinError.value = null;
                              pinAttempt.value++;
                              setupStep.value = 2;
                            },
                            onPinOnly: () {
                              pendingMode.value = AuthMode.pin;
                              firstPin.value = null;
                              pinError.value = null;
                              pinAttempt.value++;
                              setupStep.value = 2;
                            },
                            onSkip: () async {
                              await ref.read(authProvider.notifier).skipSetup();
                              if (context.mounted) await _finishSetup(context);
                            },
                            bioError: bioError.value,
                            bioInFlight: bioInFlight.value,
                          ),
                        )
                      : _UnlockControls(
                          authMode: auth.authMode,
                          biometricLabel: biometricLabel.value,
                          bioError: bioError.value,
                          bioInFlight: bioInFlight.value,
                          onBiometricTap: () async {
                            if (bioInFlight.value) return;
                            bioInFlight.value = true;
                            bioError.value = null;
                            try {
                              await ref.read(authProvider.notifier).unlock();
                              if (context.mounted &&
                                  ref.read(authProvider).isLocked == false) {
                                context.go('/');
                              }
                            } catch (e) {
                              bioError.value = 'Authentication error.';
                            } finally {
                              bioInFlight.value = false;
                            }
                          },
                          onUsePinInstead: () {
                            showPinKeypad.value = true;
                            pinUnlockError.value = null;
                          },
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _finishSetup(BuildContext context) async {
    // Request notification permission before asking about reminders
    await NotificationService.instance.requestPermissions();
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ReminderPromptDialog(),
    );
    if (context.mounted) context.go('/');
  }

  static Future<void> _loadBiometricLabel(ValueNotifier<String> label) async {
    try {
      final biometrics = await LocalAuthentication().getAvailableBiometrics();
      if (biometrics.contains(BiometricType.face)) {
        label.value = 'Face ID';
      } else if (biometrics.contains(BiometricType.fingerprint) ||
                 biometrics.contains(BiometricType.strong)) {
        label.value = 'Touch ID';
      }
    } catch (_) {}
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Branding
// ─────────────────────────────────────────────────────────────────────────────

class _Branding extends StatelessWidget {
  final Color primary;
  final Color muted;
  const _Branding({required this.primary, required this.muted});

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          WordmarkWidget(fontSize: 40, color: primary),
          const SizedBox(height: 6),
          Text('Your private sanctuary.',
              style: TextStyle(fontFamily: 'Caveat',
                fontSize: 16, color: muted, letterSpacing: 0.2)),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// PIN area — full-screen centered keypad (setup or unlock)
// ─────────────────────────────────────────────────────────────────────────────

class _PinArea extends StatelessWidget {
  final bool isSetup;
  final String? firstPin;
  final int pinAttempt;
  final String? pinError;
  final String? pinUnlockError;
  final int pinUnlockAttempt;
  final ValueChanged<String> onSetupFirstPin;
  final ValueChanged<String> onSetupConfirmPin;
  final ValueChanged<String> onUnlockPin;

  const _PinArea({
    required this.isSetup,
    required this.firstPin,
    required this.pinAttempt,
    required this.pinError,
    required this.pinUnlockError,
    required this.pinUnlockAttempt,
    required this.onSetupFirstPin,
    required this.onSetupConfirmPin,
    required this.onUnlockPin,
  });

  @override
  Widget build(BuildContext context) {
    if (isSetup) {
      final isConfirm = firstPin != null;
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: PinKeypad(
            key: ValueKey(isConfirm ? 'confirm' : 'set_$pinAttempt'),
            title: isConfirm ? 'Confirm your PIN' : 'Set your PIN',
            subtitle: isConfirm
                ? (pinError ?? 'Enter the same PIN again')
                : 'Choose a 4-digit PIN for your journal',
            onComplete: isConfirm ? onSetupConfirmPin : onSetupFirstPin,
          ),
        ),
      );
    }

    // Unlock
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: PinKeypad(
          key: ValueKey('unlock_$pinUnlockAttempt'),
          title: 'Enter your PIN',
          subtitle: pinUnlockError ?? 'Unlock your journal',
          onComplete: onUnlockPin,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Setup controls (steps 0 and 1)
// ─────────────────────────────────────────────────────────────────────────────

class _SetupControls extends StatefulWidget {
  final int step;
  final ValueChanged<String> onNameDone;
  final VoidCallback onBiometricOnly;
  final VoidCallback onBiometricAndPin;
  final VoidCallback onPinOnly;
  final VoidCallback onSkip;
  final String? bioError;
  final bool bioInFlight;

  const _SetupControls({
    required this.step,
    required this.onNameDone,
    required this.onBiometricOnly,
    required this.onBiometricAndPin,
    required this.onPinOnly,
    required this.onSkip,
    required this.bioError,
    required this.bioInFlight,
  });

  @override
  State<_SetupControls> createState() => _SetupControlsState();
}

class _SetupControlsState extends State<_SetupControls> {
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.step == 0) return _NameStep(ctrl: _nameCtrl, onDone: widget.onNameDone);
    return _SecurityStep(
      onBiometricOnly: widget.onBiometricOnly,
      onBiometricAndPin: widget.onBiometricAndPin,
      onPinOnly: widget.onPinOnly,
      onSkip: widget.onSkip,
      error: widget.bioError,
      loading: widget.bioInFlight,
    );
  }
}

// ── Name step ─────────────────────────────────────────────────────────────────

class _NameStep extends StatefulWidget {
  final TextEditingController ctrl;
  final ValueChanged<String> onDone;
  const _NameStep({required this.ctrl, required this.onDone});

  @override
  State<_NameStep> createState() => _NameStepState();
}

class _NameStepState extends State<_NameStep> {
  bool _valid = false;

  @override
  void initState() {
    super.initState();
    widget.ctrl.addListener(() {
      final v = widget.ctrl.text.trim().isNotEmpty;
      if (v != _valid) setState(() => _valid = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What should we call you?',
            style: TextStyle(fontFamily: 'PlayfairDisplay',
              fontSize: 20, fontWeight: FontWeight.w600, color: t.onBackground)),
        const SizedBox(height: 4),
        Text('Shows as a greeting on the home screen.',
            style: TextStyle(fontFamily: 'Caveat', fontSize: 15, color: t.onSurfaceMuted)),
        const SizedBox(height: 20),
        TextField(
          controller: widget.ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          cursorColor: t.primary,
          style: TextStyle(fontFamily: 'Lora', fontSize: 17, color: t.onBackground),
          decoration: InputDecoration(
            hintText: 'Your name',
            hintStyle: TextStyle(fontFamily: 'Lora', fontSize: 17,
                fontStyle: FontStyle.italic, color: t.onSurfaceMuted),
          ),
          onSubmitted: _valid ? (v) => widget.onDone(widget.ctrl.text.trim()) : null,
        ),
        const SizedBox(height: 24),
        AnimatedOpacity(
          opacity: _valid ? 1.0 : 0.38,
          duration: const Duration(milliseconds: 150),
          child: _FilledPill(
            label: 'Continue →',
            onTap: _valid ? () => widget.onDone(widget.ctrl.text.trim()) : null,
          ),
        ),
      ],
    );
  }
}

// ── Security choice step ──────────────────────────────────────────────────────

class _SecurityStep extends StatelessWidget {
  final VoidCallback onBiometricOnly;
  final VoidCallback onBiometricAndPin;
  final VoidCallback onPinOnly;
  final VoidCallback onSkip;
  final String? error;
  final bool loading;

  const _SecurityStep({
    required this.onBiometricOnly, required this.onBiometricAndPin,
    required this.onPinOnly, required this.onSkip,
    required this.error, required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: t.primaryContainer,
            border: Border.all(color: t.primary, width: 1.5),
          ),
          child: Icon(Icons.lock_outline_rounded, size: 28, color: t.primary),
        ),
        const SizedBox(height: 16),
        Text('Protect your journal?',
            style: TextStyle(fontFamily: 'PlayfairDisplay',
              fontSize: 20, fontWeight: FontWeight.w600, color: t.onBackground)),
        const SizedBox(height: 4),
        Text('Choose your lock method. Change anytime in Settings.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Caveat', fontSize: 14,
                color: t.onSurfaceMuted, height: 1.4)),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(error!,
              style: TextStyle(fontFamily: 'Lora', fontSize: 13,
                  color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center),
        ],
        const SizedBox(height: 20),
        _SecOpt(icon: Icons.fingerprint_rounded,
            label: 'Fingerprint + PIN',
            sub: 'Fingerprint first, custom PIN as fallback',
            primary: true, t: t, loading: loading, onTap: onBiometricAndPin),
        const SizedBox(height: 8),
        _SecOpt(icon: Icons.fingerprint_rounded,
            label: 'Fingerprint only',
            sub: 'Biometric only, no PIN fallback',
            primary: false, t: t, loading: loading, onTap: onBiometricOnly),
        const SizedBox(height: 8),
        _SecOpt(icon: Icons.pin_outlined,
            label: 'PIN only',
            sub: 'Set a custom 4-digit PIN',
            primary: false, t: t, loading: loading, onTap: onPinOnly),
        const SizedBox(height: 12),
        TextButton(
          onPressed: loading ? null : onSkip,
          style: TextButton.styleFrom(foregroundColor: t.onSurfaceMuted),
          child: Text('Skip for now',
              style: TextStyle(fontFamily: 'Caveat', fontSize: 16, color: t.onSurfaceMuted)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Unlock controls (biometric mode)
// ─────────────────────────────────────────────────────────────────────────────

class _UnlockControls extends StatelessWidget {
  final AuthMode authMode;
  final String biometricLabel;
  final String? bioError;
  final bool bioInFlight;
  final VoidCallback onBiometricTap;
  final VoidCallback? onUsePinInstead;

  const _UnlockControls({
    required this.authMode,
    required this.biometricLabel,
    required this.bioError,
    required this.bioInFlight,
    required this.onBiometricTap,
    this.onUsePinInstead,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Welcome back',
            style: TextStyle(fontFamily: 'PlayfairDisplay',
              fontSize: 22, fontWeight: FontWeight.w600, color: t.onBackground)),
        const SizedBox(height: 4),
        Text('Tap to unlock your journal',
            style: TextStyle(fontFamily: 'Caveat', fontSize: 16, color: t.onSurfaceMuted)),
        const SizedBox(height: 32),

        // Fingerprint circle — primary colored, clearly tappable
        GestureDetector(
          onTap: bioInFlight ? null : onBiometricTap,
          child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: t.primaryContainer,
              border: Border.all(color: t.primary, width: 2),
            ),
            child: Center(
              child: bioInFlight
                  ? SizedBox(width: 28, height: 28,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(t.primary)))
                  : FingerprintIcon(size: 44, color: t.primary),
            ),
          ),
        ),

        const SizedBox(height: 8),
        Text('Tap to unlock',
            style: TextStyle(fontFamily: 'Caveat', fontSize: 14, color: t.onSurfaceMuted)),

        if (bioError != null) ...[
          const SizedBox(height: 12),
          Text(bioError!,
              style: TextStyle(fontFamily: 'Lora', fontSize: 13,
                  color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center),
        ],

        if (authMode == AuthMode.biometricAndPin && onUsePinInstead != null) ...[
          const SizedBox(height: 24),
          _OutlinedPill(label: 'Use PIN instead', onTap: onUsePinInstead!, t: t),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SecOpt extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final bool primary;
  final BakaTokens t;
  final bool loading;
  final VoidCallback onTap;
  const _SecOpt({required this.icon, required this.label, required this.sub,
      required this.primary, required this.t, required this.loading,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg     = primary ? t.primary : Colors.transparent;
    final fg     = primary ? Colors.white : t.onBackground;
    final subfg  = primary ? Colors.white70 : t.onSurfaceMuted;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: bg, borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: loading ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: primary ? null : BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: t.outline, width: 1)),
            child: Row(children: [
              Icon(icon, size: 20, color: fg),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: TextStyle(fontFamily: 'Caveat',
                    fontSize: 16, fontWeight: FontWeight.w700, color: fg)),
                Text(sub, style: TextStyle(fontFamily: 'Caveat',
                    fontSize: 12, color: subfg)),
              ])),
            ]),
          ),
        ),
      ),
    );
  }
}

class _FilledPill extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _FilledPill({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: t.primary, borderRadius: BorderRadius.circular(50),
        child: InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Center(child: Text(label,
                style: const TextStyle(fontFamily: 'Caveat',
                  fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white))),
          ),
        ),
      ),
    );
  }
}

class _OutlinedPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final BakaTokens t;
  const _OutlinedPill({required this.label, required this.onTap, required this.t});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: Material(
          color: Colors.transparent, borderRadius: BorderRadius.circular(50),
          child: InkWell(
            borderRadius: BorderRadius.circular(50),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: t.primary, width: 1.5),
              ),
              child: Center(child: Text(label,
                  style: TextStyle(fontFamily: 'Caveat',
                    fontSize: 18, fontWeight: FontWeight.w700, color: t.primary))),
            ),
          ),
        ),
      );
}
