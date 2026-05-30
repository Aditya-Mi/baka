import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:baka/core/auth/auth_provider.dart';
import 'package:baka/features/lock/pin_keypad.dart';
import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/core/fonts/font_provider.dart';
import 'package:baka/features/settings/widgets/font_picker_sheet.dart';
import 'package:baka/features/settings/widgets/reminder_settings_tile.dart';
import 'package:baka/features/settings/widgets/export_import_tile.dart';
import 'package:baka/features/settings/widgets/theme_toggle_tile.dart';
import 'package:baka/providers/user_provider.dart';
import 'package:baka/widgets/illustrations.dart';

class SettingsScreen extends HookConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t       = context.tokens;
    final onBg    = t.onBackground;
    final muted   = t.onSurfaceMuted;
    final outline = t.outlineSoft;
    final primary = t.primary;

    final fontKey = ref.watch(fontProvider);
    final auth    = ref.watch(authProvider);
    final name    = ref.watch(userProvider);

    final versionFuture = useMemoized(PackageInfo.fromPlatform);
    final versionSnap   = useFuture(versionFuture);
    final versionStr    = versionSnap.data != null
        ? '${versionSnap.data!.version} (${versionSnap.data!.buildNumber})'
        : '—';

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        title: Text(
          'Settings',
          style: TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontSize: 22, fontWeight: FontWeight.w600, color: onBg,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [

          // ── Profile ──────────────────────────────────────────────────
          const _SectionHeader('Profile'),
          _Row(
            title: 'Your name',
            value: name.isNotEmpty ? name : 'Not set',
            valueColor: name.isNotEmpty ? primary : muted,
            trailing: AppIcon(AppIconData.pencil, size: 16, color: muted),
            onTap: () => _showNameEdit(context, ref, name, t),
          ),

          // ── Appearance ───────────────────────────────────────────────
          const _SectionHeader('Appearance'),
          const ThemeToggleTile(),
          _Divider(color: outline),
          _Row(
            title: 'Writing font',
            value: _fontDisplayName(fontKey),
            valueColor: primary,
            trailing: AppIcon(AppIconData.chevronRight, size: 18, color: muted),
            onTap: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: t.surfaceElev,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) => const FontPickerSheet(),
            ),
          ),

          // ── Reminders ────────────────────────────────────────────────
          const _SectionHeader('Reminders'),
          const ReminderSettingsTile(),

          // ── Security ─────────────────────────────────────────────────
          const _SectionHeader('Security'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Text('Lock with biometrics',
                    style: TextStyle(fontFamily: 'Caveat',
                      fontSize: 18, fontWeight: FontWeight.w600, color: onBg)),
                const Spacer(),
                Switch(
                  value: auth.biometricsEnabled,
                  onChanged: (enabled) {
                    if (enabled) {
                      _showSecurityOptions(context, ref, t);
                    } else {
                      ref.read(authProvider.notifier).skipSetup();
                    }
                  },
                ),
              ],
            ),
          ),
          _Divider(color: outline),
          _Row(
            title: 'Change security method',
            trailing: AppIcon(AppIconData.chevronRight, size: 18, color: muted),
            onTap: () => _showSecurityOptions(context, ref, t),
          ),

          // ── Data ─────────────────────────────────────────────────────
          const _SectionHeader('Data'),
          const ExportImportTile(),

          // ── About ────────────────────────────────────────────────────
          const _SectionHeader('About'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Text('Version',
                    style: TextStyle(fontFamily: 'Caveat',
                      fontSize: 18, fontWeight: FontWeight.w600, color: onBg)),
                const Spacer(),
                Text(versionStr,
                    style: TextStyle(fontFamily: 'CourierPrime',
                      fontSize: 12, letterSpacing: 0.5, color: muted)),
              ],
            ),
          ),
          _Divider(color: outline),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            child: Text(
              'Made for your thoughts.',
              style: TextStyle(fontFamily: 'Lora',
                fontSize: 14, fontStyle: FontStyle.italic, color: muted),
            ),
          ),
        ],
      ),
    );
  }

  static void _showSecurityOptions(
    BuildContext context,
    WidgetRef ref,
    BakaTokens t,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SecurityOptionsSheet(tokens: t, ref: ref),
    );
  }

  static void _showNameEdit(
    BuildContext context,
    WidgetRef ref,
    String current,
    BakaTokens t,
  ) {
    final ctrl = TextEditingController(text: current);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Your name',
            style: TextStyle(fontFamily: 'PlayfairDisplay',
              fontSize: 19, fontWeight: FontWeight.w600, color: t.onBackground,
            )),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          cursorColor: t.primary,
          style: TextStyle(fontFamily: 'Lora', fontSize: 16, color: t.onBackground),
          decoration: InputDecoration(
            hintText: 'Your name',
            hintStyle: TextStyle(fontFamily: 'Lora',
              fontSize: 16, fontStyle: FontStyle.italic, color: t.onSurfaceMuted),
          ),
          onSubmitted: (_) {
            ref.read(userProvider.notifier).setName(ctrl.text);
            Navigator.of(ctx).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(foregroundColor: t.onSurfaceMuted),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'Caveat', fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(userProvider.notifier).setName(ctrl.text);
              Navigator.of(ctx).pop();
            },
            child: const Text('Save',
                style: TextStyle(fontFamily: 'Caveat', fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  static String _fontDisplayName(String key) => switch (key) {
        'playfairDisplay'  => 'Playfair Display',
        'crimsonPro'       => 'Crimson Pro',
        'ebGaramond'       => 'EB Garamond',
        'caveat'           => 'Caveat',
        'libreBaskerville' => 'Libre Baskerville',
        _                  => 'Lora',
      };
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 4),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'PlayfairDisplay',
          fontSize: 20, fontWeight: FontWeight.w600,
          height: 1.3, color: t.primary,
        ),
      ),
    );
  }
}

// ── Flat row ─────────────────────────────────────────────────────────────────

class _Row extends StatelessWidget {
  final String title;
  final String? value;
  final Color? valueColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _Row({
    required this.title,
    this.value,
    this.valueColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Text(title,
                style: TextStyle(fontFamily: 'Caveat',
                  fontSize: 18, fontWeight: FontWeight.w600,
                  color: t.onBackground)),
            const Spacer(),
            if (value != null) ...[
              Text(value!,
                  style: TextStyle(fontFamily: 'Caveat',
                    fontSize: 16, color: valueColor ?? t.onSurfaceMuted)),
              const SizedBox(width: 6),
            ],
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

// ── Security options sheet ────────────────────────────────────────────────────

class _SecurityOptionsSheet extends StatefulWidget {
  final BakaTokens tokens;
  final WidgetRef ref;
  const _SecurityOptionsSheet({required this.tokens, required this.ref});

  @override
  State<_SecurityOptionsSheet> createState() => _SecurityOptionsSheetState();
}

class _SecurityOptionsSheetState extends State<_SecurityOptionsSheet> {
  bool _loading = false;
  String? _error;
  // null = choice screen, 'pin', 'biometricAndPin' = PIN setup flow
  String? _pinMode;
  String? _firstPin;
  String? _pinError;

  BakaTokens get t => widget.tokens;

  Future<void> _biometricOnly() async {
    setState(() { _loading = true; _error = null; });
    try {
      final ok = await widget.ref.read(authProvider.notifier).setupBiometric();
      if (ok && mounted) {
        Navigator.of(context).pop();
      } else if (!ok) setState(() => _error = 'Biometric setup failed.');
    } catch (_) {
      setState(() => _error = 'Something went wrong.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _finalizePinMode(String pin) async {
    setState(() { _loading = true; _pinError = null; });
    try {
      if (_pinMode == 'biometricAndPin') {
        final ok = await widget.ref.read(authProvider.notifier).setupBiometricAndPin(pin);
        if (!ok && mounted) {
          // Biometric unavailable — fall back to PIN only
          await widget.ref.read(authProvider.notifier).setupPin(pin);
        }
      } else {
        await widget.ref.read(authProvider.notifier).setupPin(pin);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      setState(() => _pinError = 'Something went wrong.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _disable() async {
    await widget.ref.read(authProvider.notifier).skipSetup();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: t.surfaceElev,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: _pinMode != null ? _buildPinSetup() : _buildChoices(),
    );
  }

  Widget _buildChoices() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 40, height: 4,
          decoration: BoxDecoration(color: t.outline.withValues(alpha:0.5),
              borderRadius: BorderRadius.circular(2))),
      const SizedBox(height: 20),
      Text('Security method', style: TextStyle(fontFamily: 'PlayfairDisplay',
          fontSize: 20, fontWeight: FontWeight.w600, color: t.onBackground)),
      const SizedBox(height: 4),
      Text('Choose how to unlock your journal.',
          style: TextStyle(fontFamily: 'Caveat', fontSize: 15, color: t.onSurfaceMuted)),
      const SizedBox(height: 20),
      if (_error != null) ...[
        Text(_error!, style: TextStyle(fontFamily: 'Lora', fontSize: 13,
            color: Theme.of(context).colorScheme.error), textAlign: TextAlign.center),
        const SizedBox(height: 10),
      ],
      _Opt(label: 'Fingerprint + PIN', subtitle: 'Fingerprint first, custom PIN as fallback',
          icon: Icons.fingerprint_rounded, primary: true, t: t, loading: _loading,
          onTap: () => setState(() { _pinMode = 'biometricAndPin'; _firstPin = null; _pinError = null; })),
      const SizedBox(height: 8),
      _Opt(label: 'Fingerprint only', subtitle: 'Biometric only, no PIN fallback',
          icon: Icons.fingerprint_rounded, primary: false, t: t, loading: _loading,
          onTap: _biometricOnly),
      const SizedBox(height: 8),
      _Opt(label: 'PIN only', subtitle: 'Custom 4-digit PIN to unlock',
          icon: Icons.pin_outlined, primary: false, t: t, loading: _loading,
          onTap: () => setState(() { _pinMode = 'pin'; _firstPin = null; _pinError = null; })),
      const SizedBox(height: 8),
      _Opt(label: 'No lock', subtitle: 'Anyone can open the app',
          icon: Icons.lock_open_outlined, primary: false, t: t, loading: _loading,
          onTap: _disable, danger: true),
    ],
  );

  Widget _buildPinSetup() {
    final isConfirm = _firstPin != null;
    final _attempt  = _firstPin == null ? (_pinError == null ? 0 : 1) : 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back arrow
        IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 18,
              color: widget.tokens.onSurfaceMuted),
          onPressed: () => setState(() {
            if (isConfirm) { _firstPin = null; _pinError = null; }
            else { _pinMode = null; }
          }),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(height: 12),
        PinKeypad(
          key: ValueKey(isConfirm ? 'confirm' : 'set_${_pinError ?? ''}'),
          title: isConfirm ? 'Confirm your PIN' : 'Set your PIN',
          subtitle: isConfirm
              ? (_pinError ?? 'Re-enter the same PIN')
              : (_pinMode == 'biometricAndPin'
                  ? 'Fingerprint fallback PIN'
                  : '4-digit PIN to unlock your journal'),
          onComplete: (pin) {
            if (!isConfirm) {
              setState(() { _firstPin = pin; _pinError = null; });
            } else {
              if (pin != _firstPin) {
                setState(() { _firstPin = null; _pinError = 'PINs don\'t match. Try again.'; });
              } else {
                _finalizePinMode(pin);
              }
            }
          },
        ),
      ],
    );
  }
}

class _Opt extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool primary;
  final bool danger;
  final BakaTokens t;
  final bool loading;
  final VoidCallback onTap;
  const _Opt({required this.label, required this.subtitle, required this.icon, required this.primary, required this.t, required this.loading, required this.onTap, this.danger = false});

  @override
  Widget build(BuildContext context) {
    final bg = primary ? t.primary : Colors.transparent;
    final border = danger ? Colors.red.shade300 : t.outline;
    final labelColor = primary ? Colors.white : (danger ? Colors.red.shade400 : t.onBackground);
    final subColor = primary ? Colors.white70 : t.onSurfaceMuted;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: loading ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: primary ? null : BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: border, width: 1)),
            child: Row(children: [
              Icon(icon, size: 20, color: labelColor),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: TextStyle(fontFamily: 'Caveat', fontSize: 17, fontWeight: FontWeight.w700, color: labelColor)),
                Text(subtitle, style: TextStyle(fontFamily: 'Caveat', fontSize: 13, color: subColor)),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Thin divider with horizontal margin ──────────────────────────────────────

class _Divider extends StatelessWidget {
  final Color color;
  const _Divider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(color: color, height: 1, thickness: 1),
    );
  }
}
