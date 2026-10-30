import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:baka/core/theme/app_theme.dart';

/// Bottom sheet that explains why Baka needs the microphone (and, on Android 13+,
/// notifications for recording controls), then requests them. Returns true if
/// the microphone ended up granted.
///
/// The widget-launched recorder can't show a rationale before its OS prompt, so
/// this primes the grant in-app — after which the widget path records silently.
Future<bool> showPermissionPrimingSheet(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _PrimingSheet(),
  );
  return result ?? false;
}

class _PrimingSheet extends StatefulWidget {
  const _PrimingSheet();

  @override
  State<_PrimingSheet> createState() => _PrimingSheetState();
}

class _PrimingSheetState extends State<_PrimingSheet> {
  bool _requesting = false;

  Future<void> _allow() async {
    if (_requesting) return;
    setState(() => _requesting = true);
    final navigator = Navigator.of(context);

    final mic = await Permission.microphone.request();
    if (Platform.isAndroid) {
      await Permission.notification.request();
    }

    if (mic.isPermanentlyDenied) {
      await openAppSettings();
    }
    if (mounted) navigator.pop(mic.isGranted);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: t.primary, shape: BoxShape.circle),
              child: Icon(Icons.mic_rounded, size: 34, color: Theme.of(context).colorScheme.onPrimary),
            ),
            const SizedBox(height: 16),
            Text('Let Baka hear you',
                style: AppText.numeral(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: t.onBackground,
                  )),
            const SizedBox(height: 12),
            Text(
              'Baka needs your microphone to record voice notes, and '
              'notifications to show recording controls. Your audio stays on '
              'your device.',
              textAlign: TextAlign.center,
              style: AppText.label(context).copyWith(
                  height: 1.45,
                  color: t.onSurfaceMuted,
                ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _requesting ? null : _allow,
                style: FilledButton.styleFrom(
                  backgroundColor: t.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: _requesting
                    ? SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary))
                    : Text('Allow',
                        style: AppText.handTitle(context).copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                          )),
              ),
            ),
            TextButton(
              onPressed: _requesting ? null : () => Navigator.of(context).pop(false),
              child: Text('Not now',
                  style: AppText.handTitle(context).copyWith(
                      color: t.onSurfaceMuted,
                    )),
            ),
          ],
        ),
      ),
    );
  }
}
