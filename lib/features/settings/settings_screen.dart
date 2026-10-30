import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:baka/core/auth/auth_provider.dart';
import 'package:baka/features/lock/pin_keypad.dart';
import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/core/fonts/font_provider.dart';
import 'package:baka/features/settings/widgets/font_picker_sheet.dart';
import 'package:baka/features/settings/widgets/font_theme_sheet.dart';
import 'package:baka/features/settings/widgets/reminder_settings_tile.dart';
import 'package:baka/features/settings/widgets/export_import_tile.dart';
import 'package:baka/features/settings/widgets/settings_row.dart';
import 'package:baka/features/settings/widgets/theme_toggle_tile.dart';
import 'package:baka/providers/user_provider.dart';
import 'package:baka/widgets/security_option_tile.dart';
import 'package:baka/core/fonts/font_theme.dart';

class SettingsScreen extends HookConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t       = context.tokens;
    final muted   = t.onSurfaceMuted;

    final fontKey = ref.watch(fontProvider);
    final preset  = ref.watch(fontThemeProvider);
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
          style: AppText.screenTitle(context).copyWith(
              fontWeight: FontWeight.w700,
              color: t.primary,
            ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [

          // ── Profile ──────────────────────────────────────────────────
          const _SectionHeader('Profile'),
          SettingsRow(
            icon: Icons.person_outline_rounded,
            title: 'Your name',
            value: name.isNotEmpty ? name : 'Not set',
            trailing: Icon(Icons.edit_outlined, size: 18, color: muted),
            onTap: () => _showNameEdit(context, ref, name, t),
          ),

          // ── Appearance ───────────────────────────────────────────────
          const _SectionHeader('Appearance'),
          const ThemeToggleTile(),
          const SettingsDivider(),
          SettingsRow(
            icon: Icons.text_fields_rounded,
            title: 'App font',
            value: preset.label,
            chevron: true,
            onTap: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: t.surfaceElev,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) => const FontThemeSheet(),
            ),
          ),
          const SettingsDivider(),
          SettingsRow(
            icon: Icons.edit_note_rounded,
            title: 'Writing font',
            value: _fontDisplayName(fontKey, preset),
            chevron: true,
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
          SettingsRow(
            icon: Icons.fingerprint_rounded,
            title: 'Lock with biometrics',
            trailing: Switch(
              value: auth.biometricsEnabled,
              onChanged: (enabled) {
                if (enabled) {
                  _showSecurityOptions(context);
                } else {
                  ref.read(authProvider.notifier).skipSetup();
                }
              },
            ),
          ),
          const SettingsDivider(),
          SettingsRow(
            icon: Icons.lock_outline_rounded,
            title: 'Change security method',
            chevron: true,
            onTap: () => _showSecurityOptions(context),
          ),

          // ── Data ─────────────────────────────────────────────────────
          const _SectionHeader('Data'),
          const ExportImportTile(),

          // ── About ────────────────────────────────────────────────────
          const _SectionHeader('About'),
          SettingsRow(
            icon: Icons.info_outline_rounded,
            title: 'Version',
            value: versionStr,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(58, 6, 20, 14),
            child: Text(
              'Made for your thoughts.',
              style: AppText.label(context).copyWith(
                  fontStyle: FontStyle.italic,
                  color: muted,
                ),
            ),
          ),
        ],
      ),
    );
  }

  static void _showSecurityOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _SecurityOptionsSheet(),
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
        title: const Text('Your name'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          cursorColor: t.primary,
          style: AppText.rowTitle(context).copyWith(
              color: t.onBackground,
            ),
          decoration: InputDecoration(
            hintText: 'Your name',
            hintStyle: AppText.rowTitle(context).copyWith(
                fontStyle: FontStyle.italic,
                color: t.onSurfaceMuted,
              ),
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
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(userProvider.notifier).setName(ctrl.text);
              Navigator.of(ctx).pop();
            },
            child: Text('Save',
                style: AppText.label(context).copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  /// A null key means the writing font is following the app font preset.
  static String _fontDisplayName(String? key, FontPreset preset) =>
      key == null ? 'Match app font' : kAvailableFonts[key] ?? preset.body;
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 4),
      child: Text(
        label,
        style: AppText.sectionHeading(context).copyWith(
            fontWeight: FontWeight.w600,
            height: 1.3,
            color: t.onBackground,
          ),
      ),
    );
  }
}

// ── Security options sheet ────────────────────────────────────────────────────

class _SecurityOptionsSheet extends ConsumerStatefulWidget {
  const _SecurityOptionsSheet();

  @override
  ConsumerState<_SecurityOptionsSheet> createState() => _SecurityOptionsSheetState();
}

class _SecurityOptionsSheetState extends ConsumerState<_SecurityOptionsSheet> {
  bool _loading = false;
  String? _error;
  // null = choice screen, 'pin', 'biometricAndPin' = PIN setup flow
  String? _pinMode;
  String? _firstPin;
  String? _pinError;

  Future<void> _biometricOnly() async {
    setState(() { _loading = true; _error = null; });
    try {
      final ok = await ref.read(authProvider.notifier).setupBiometric();
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
        final ok = await ref.read(authProvider.notifier).setupBiometricAndPin(pin);
        if (!ok && mounted) {
          await ref.read(authProvider.notifier).setupPin(pin);
        }
      } else {
        await ref.read(authProvider.notifier).setupPin(pin);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _pinError = 'Something went wrong.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _disable() async {
    await ref.read(authProvider.notifier).skipSetup();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: t.surfaceElev,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: _pinMode != null ? _buildPinSetup(t) : _buildChoices(t),
    );
  }

  Widget _buildChoices(BakaTokens t) {
    final currentMode = ref.watch(authProvider).authMode;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: t.outline.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Text('Security method', style: AppText.heading(context).copyWith(
            fontWeight: FontWeight.w600,
            color: t.onBackground,
          )),
        const SizedBox(height: 4),
        Text('Choose how to unlock your journal.',
            style: AppText.caption(context).copyWith(
                color: t.onSurfaceMuted,
              )),
        const SizedBox(height: 20),
        if (_error != null) ...[
          Text(_error!, style: AppText.meta(context).copyWith(
              color: Theme.of(context).colorScheme.error,
            ), textAlign: TextAlign.center),
          const SizedBox(height: 10),
        ],
        SecurityOptionTile(
            label: 'Fingerprint + PIN',
            subtitle: 'Fingerprint first, custom PIN',
            icon: Icons.fingerprint_rounded,
            selected: currentMode == AuthMode.biometricAndPin,
            loading: _loading,
            onTap: () => setState(() { _pinMode = 'biometricAndPin'; _firstPin = null; _pinError = null; })),
        const SizedBox(height: 8),
        SecurityOptionTile(
            label: 'Fingerprint only',
            subtitle: 'Biometric only',
            icon: Icons.fingerprint_rounded,
            selected: currentMode == AuthMode.biometric,
            loading: _loading,
            onTap: _biometricOnly),
        const SizedBox(height: 8),
        SecurityOptionTile(
            label: 'PIN only',
            subtitle: 'Custom 4-digit PIN to unlock',
            icon: Icons.pin_outlined,
            selected: currentMode == AuthMode.pin,
            loading: _loading,
            onTap: () => setState(() { _pinMode = 'pin'; _firstPin = null; _pinError = null; })),
        const SizedBox(height: 8),
        SecurityOptionTile(
            label: 'No lock',
            subtitle: 'Anyone can open the app',
            icon: Icons.lock_open_outlined,
            selected: currentMode == AuthMode.none,
            danger: true,
            loading: _loading,
            onTap: _disable),
      ],
    );
  }

  Widget _buildPinSetup(BakaTokens t) {
    final isConfirm = _firstPin != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          tooltip: 'Back',
          icon: Icon(Icons.arrow_back_ios_new, size: 18, color: t.onSurfaceMuted),
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
