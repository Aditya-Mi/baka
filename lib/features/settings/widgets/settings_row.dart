import 'package:flutter/material.dart';

import 'package:baka/core/theme/app_theme.dart';

/// The one row style used across Settings: leading icon, body-font title,
/// optional handwritten subtitle, optional value and trailing widget.
class SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? value;
  final Color? valueColor;
  final FontWeight? valueWeight;
  final Widget? trailing;
  final bool chevron;
  final VoidCallback? onTap;

  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.valueColor,
    this.valueWeight,
    this.trailing,
    this.chevron = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: subtitle != null ? 68 : 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 22, color: t.onSurfaceMuted),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        style: AppText.rowTitle(context).copyWith(
                            fontWeight: FontWeight.w500,
                            color: t.onBackground,
                          )),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!,
                          style: AppText.caption(context).copyWith(
                              color: t.onSurfaceMuted,
                            )),
                    ],
                  ],
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: 12),
                // Long names / font names truncate instead of overflowing.
                Flexible(
                  child: Text(value!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: AppText.label(context).copyWith(
                          fontWeight: valueWeight,
                          color: valueColor ?? t.onSurfaceMuted,
                        )),
                ),
              ],
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
              if (chevron) ...[
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, size: 20, color: t.onSurfaceMuted),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Hairline divider inset past the row icon so groups read as one list.
class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 58, right: 20),
        child: Divider(color: context.tokens.outlineSoft, height: 1, thickness: 1),
      );
}
