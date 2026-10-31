import 'package:flutter/material.dart';
import 'package:baka/widgets/app_icon.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:baka/core/notifications/notification_service.dart';
import 'package:baka/core/notifications/reminder_provider.dart';
import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/features/settings/widgets/settings_row.dart';

class ReminderSettingsTile extends HookConsumerWidget {
  const ReminderSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t        = context.tokens;

    final reminder = ref.watch(reminderProvider);
    final notifier = ref.read(reminderProvider.notifier);

    // Re-check the system permission whenever the app resumes (e.g. after
    // returning from system settings) so a revoked permission is visible here
    // instead of the switch silently lying.
    final recheck = useState(0);
    useOnAppLifecycleStateChange((_, state) {
      if (state == AppLifecycleState.resumed) recheck.value++;
    });
    final permFuture = useMemoized(
        () => NotificationService.instance.areNotificationsEnabled(),
        [recheck.value, reminder.enabled]);
    final systemOff = reminder.enabled && useFuture(permFuture).data == false;

    // Format time
    final timeStr = DateFormat.jm().format(DateTime(
      2000, 1, 1, reminder.time.hour, reminder.time.minute,
    ));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main switch row
        SettingsRow(
          icon: AppIconData.bell,
          title: 'Daily reminder',
          subtitle: 'A gentle nudge to capture your thoughts.',
          trailing: Switch(
            value: reminder.enabled,
            onChanged: (v) async {
              if (v) {
                final granted = await NotificationService.instance.requestPermissions();
                if (!granted) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Notifications are off for Baka'),
                        action: SnackBarAction(
                            label: 'Settings', onPressed: openAppSettings)));
                  }
                  return;
                }
              }
              notifier.setEnabled(v);
            },
          ),
        ),

        // Animated reveal when enabled
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: reminder.enabled
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (systemOff)
                      _PermissionWarning(t: t),
                    const SettingsDivider(),
                    SettingsRow(
                      icon: AppIconData.clock,
                      title: 'Remind me at',
                      value: timeStr,
                      valueColor: t.primary,
                      valueWeight: FontWeight.w600,
                      chevron: true,
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: reminder.time,
                        );
                        if (picked != null) notifier.setTime(picked);
                      },
                    ),
                    // Preview — a soft card inside the gutter, under its row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(58, 2, 20, 8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: t.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '“What did today feel like?”',
                              style: AppText.bodyPreview(context).copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: t.onSurface,
                                ),
                            ),
                            const SizedBox(height: 4),
                            Text('Preview · changes daily',
                                style: AppText.caption(context).copyWith(
                                    color: t.onSurfaceMuted,
                                  )),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// Shown under the reminder switch when Android notifications are blocked —
/// the reminder can't fire, so say so and offer the fix.
class _PermissionWarning extends StatelessWidget {
  final BakaTokens t;
  const _PermissionWarning({required this.t});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(58, 0, 12, 8),
      child: Row(
        children: [
          AppIcon(AppIconData.bellOff, size: 18, color: t.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Notifications are off in system settings.',
                style: AppText.meta(context).copyWith(
                    color: t.onSurface,
                  )),
          ),
          TextButton(
            onPressed: openAppSettings,
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            child: Text('Open settings',
                style: AppText.meta(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: t.primaryText,
                  )),
          ),
        ],
      ),
    );
  }
}
