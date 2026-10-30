import 'package:flutter/material.dart';

import 'package:baka/core/theme/app_theme.dart';

/// Calm, centred message for empty / not-found / error states.
/// Shared so every screen fails the same, readable way.
class StateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;

  const StateMessage({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: t.onSurfaceMuted),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppText.sectionHeading(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: t.onBackground,
                  height: 1.3,
                ),
            ),
            if (body != null) ...[
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Text(
                  body!,
                  textAlign: TextAlign.center,
                  style: AppText.label(context).copyWith(
                      height: 1.5,
                      color: t.onSurfaceMuted,
                    ),
                ),
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                child: Text(
                  actionLabel!,
                  style: AppText.bodyPreview(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: t.primaryText,
                    ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Load failure with a retry. Never shows the raw exception to the user.
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorView({
    super.key,
    this.message = 'Something went wrong loading your pages.',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) => StateMessage(
        icon: Icons.error_outline_rounded,
        title: "Couldn't load this",
        body: '$message Your entries are safe on this device.',
        actionLabel: onRetry != null ? 'Try again' : null,
        onAction: onRetry,
      );
}
