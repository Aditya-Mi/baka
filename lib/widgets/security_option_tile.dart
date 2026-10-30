import 'package:flutter/material.dart';
import 'package:baka/core/theme/app_theme.dart';

class SecurityOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool selected;
  final bool danger;
  final bool loading;
  final VoidCallback onTap;

  const SecurityOptionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.selected = false,
    this.danger = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final cs = Theme.of(context).colorScheme;
    final filled = selected && !danger;
    final bg = filled ? t.primary : Colors.transparent;
    final borderColor = danger ? cs.error : (selected ? t.primary : t.outline);
    final labelColor = filled ? cs.onPrimary : (danger ? cs.error : t.onBackground);
    final subColor = filled ? cs.onPrimary.withValues(alpha: 0.8) : t.onSurfaceMuted;

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
            decoration: filled
                ? null
                : BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: 1),
                  ),
            child: Row(children: [
              Icon(icon, size: 20, color: labelColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label,
                      style: AppText.rowTitle(context).copyWith(
                          fontWeight: FontWeight.w600,
                          color: labelColor,
                        )),
                  Text(subtitle,
                      style: AppText.meta(context).copyWith(
                          color: subColor,
                        )),
                ]),
              ),
              if (filled) Icon(Icons.check_circle_rounded, size: 18, color: cs.onPrimary),
            ]),
          ),
        ),
      ),
    );
  }
}
