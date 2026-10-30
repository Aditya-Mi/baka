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

    final ctrl = useTextEditingController();

    void save() {
      final name = ctrl.text.trim();
      if (name.isNotEmpty) {
        ref.read(userProvider.notifier).setName(name);
      }
      Navigator.of(context).pop();
    }

    return AlertDialog(
      title: const Text('What should we call you?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your name shows as a greeting on the home screen.',
            style: AppText.meta(context).copyWith(
                color: muted,
              ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: ctrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            style: AppText.rowTitle(context).copyWith(
                color: onBg,
              ),
            decoration: InputDecoration(
              hintText: 'Your name',
              hintStyle: AppText.rowTitle(context).copyWith(
                  fontStyle: FontStyle.italic,
                  color: muted,
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
          child: Text('Skip', style: AppText.label(context)),
        ),
        ElevatedButton(
          onPressed: save,
          child: Text(
            "Let's go",
            style: AppText.label(context).copyWith(
                fontWeight: FontWeight.w600,
              ),
          ),
        ),
      ],
    );
  }
}
