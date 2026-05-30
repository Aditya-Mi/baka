import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:baka/core/notifications/notification_service.dart';
import 'package:baka/core/notifications/reminder_provider.dart';
import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/widgets/illustrations.dart';

class ReminderSettingsTile extends ConsumerWidget {
  const ReminderSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t        = context.tokens;
    final onBg     = t.onBackground;
    final muted    = t.onSurfaceMuted;
    final primary  = t.primary;
    final outline  = t.outline;
    final surface  = t.surface;

    final reminder = ref.watch(reminderProvider);
    final notifier = ref.read(reminderProvider.notifier);

    // Format time
    final timeStr = DateFormat.jm().format(DateTime(
      2000, 1, 1, reminder.time.hour, reminder.time.minute,
    ));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main switch row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daily reminder',
                        style: TextStyle(fontFamily: 'Lora',
                          fontSize: 15, fontWeight: FontWeight.w500, color: onBg,
                        )),
                    const SizedBox(height: 2),
                    Text('A gentle nudge to capture your thoughts.',
                        style: TextStyle(fontFamily: 'Caveat',fontSize: 13, color: muted)),
                  ],
                ),
              ),
              Switch(
                value: reminder.enabled,
                onChanged: (v) async {
                  if (v) {
                    await NotificationService.instance.requestPermissions();
                  }
                  notifier.setEnabled(v);
                },
              ),
            ],
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
                    Divider(color: outline, height: 1),
                    // Time row
                    InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: reminder.time,
                        );
                        if (picked != null) notifier.setTime(picked);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Text('Remind me at',
                                style: TextStyle(fontFamily: 'Lora',
                                  fontSize: 15, fontWeight: FontWeight.w500, color: onBg,
                                )),
                            const Spacer(),
                            Text(timeStr,
                                style: TextStyle(fontFamily: 'Lora',
                                  fontSize: 15, fontWeight: FontWeight.w600, color: primary,
                                )),
                            const SizedBox(width: 4),
                            AppIcon(AppIconData.chevronRight, size: 18, color: muted),
                          ],
                        ),
                      ),
                    ),
                    Divider(color: outline, height: 1),
                    // Preview
                    Container(
                      width: double.infinity,
                      color: surface,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '"What did today feel like?"',
                            style: TextStyle(fontFamily: 'Lora',
                              fontSize: 14, fontStyle: FontStyle.italic, color: onBg,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Preview · changes daily',
                              style: TextStyle(fontFamily: 'Caveat',fontSize: 12, color: muted)),
                        ],
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
