import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:baka/core/notifications/reminder_provider.dart';

class ReminderPromptDialog extends HookConsumerWidget {
  const ReminderPromptDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: implement
    return AlertDialog(
      title: const Text('Daily reminder?'),
      content: const Text('Would you like a daily reminder to write?'),
      actions: [
        TextButton(
          onPressed: () {
            ref.read(reminderProvider.notifier).setEnabled(false);
            Navigator.of(context).pop();
          },
          child: const Text('Not now'),
        ),
        ElevatedButton(
          onPressed: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: ReminderState.defaultTime,
            );
            if (time != null && context.mounted) {
              await ref.read(reminderProvider.notifier).setEnabled(true);
              await ref.read(reminderProvider.notifier).setTime(time);
            }
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('Yes, set a time'),
        ),
      ],
    );
  }
}
