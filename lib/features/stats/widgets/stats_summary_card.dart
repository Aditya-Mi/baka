import 'package:flutter/material.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/core/fonts/font_theme.dart';

class StatsSummaryCard extends StatelessWidget {
  final int longest;
  final int entries;
  final int words;
  final bool isDark;

  const StatsSummaryCard({
    super.key,
    required this.longest,
    required this.entries,
    required this.words,
    required this.isDark,
  });

  static String _fmtWords(int w) =>
      w >= 1000 ? '${(w / 1000).toStringAsFixed(0)}k' : '$w';

  @override
  Widget build(BuildContext context) {
    final t      = context.tokens;
    final onBg   = t.onBackground;
    final muted  = t.onSurfaceMuted;
    final divider= t.outline;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          _Col(value: '$longest', unit: 'days',    label: 'Longest', onBg: onBg, muted: muted),
          VerticalDivider(color: divider, width: 1),
          _Col(value: '$entries', unit: '',         label: 'Entries', onBg: onBg, muted: muted),
          VerticalDivider(color: divider, width: 1),
          _Col(value: _fmtWords(words), unit: '',   label: 'Words',   onBg: onBg, muted: muted),
        ],
      ),
    );
  }
}

class _Col extends StatelessWidget {
  final String value;
  final String unit;
  final String label;
  final Color onBg;
  final Color muted;

  const _Col({
    required this.value, required this.unit, required this.label,
    required this.onBg, required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: TextStyle(fontFamily: context.fonts.body,
                fontSize: 28, fontWeight: FontWeight.w700, color: onBg, height: 1.0,
              )),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 3),
                Text(unit, style: TextStyle(fontFamily: context.fonts.accent, fontSize: 13, color: muted)),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontFamily: context.fonts.accent,
            fontSize: 13, fontWeight: FontWeight.w500, color: muted,
          )),
        ],
      ),
    );
  }
}
