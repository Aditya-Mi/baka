import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/providers/user_provider.dart';

class NamePromptDialog extends HookConsumerWidget {
  const NamePromptDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t       = context.tokens;
    final onBg    = t.onBackground;
    final muted   = t.onSurfaceMuted;
    final primary = t.primary;

    final ctrl = useTextEditingController();

    void save() {
      final name = ctrl.text.trim();
      if (name.isNotEmpty) {
        ref.read(userProvider.notifier).setName(name);
      }
      Navigator.of(context).pop();
    }

    return AlertDialog(
      title: Text(
        'What should we call you?',
        style: TextStyle(fontFamily: 'PlayfairDisplay',
          fontSize: 19, fontWeight: FontWeight.w600, color: onBg,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your name shows as a greeting on the home screen.',
            style: TextStyle(fontFamily: 'Caveat', fontSize: 15, color: muted),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: ctrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            style: TextStyle(fontFamily: 'Lora', fontSize: 16, color: onBg),
            decoration: InputDecoration(
              hintText: 'Your name',
              hintStyle: TextStyle(fontFamily: 'Lora',
                fontSize: 16, fontStyle: FontStyle.italic, color: muted,
              ),
            ),
            onSubmitted: (_) => save(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: muted),
          child: const Text('Skip', style: TextStyle(fontFamily: 'Lora', fontSize: 14)),
        ),
        ElevatedButton(
          onPressed: save,
          child: const Text(
            "Let's go",
            style: TextStyle(fontFamily: 'Lora', fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
