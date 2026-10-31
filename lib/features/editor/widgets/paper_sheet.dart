import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/models/paper.dart';
import 'package:baka/widgets/paper_background.dart';

/// Six sheets to write on, picked from a grid of swatches. Returns the new
/// paper, or null when dismissed. [subtitle] says what the choice applies to.
Future<Paper?> showPaperSheet(
  BuildContext context, {
  required Paper current,
  String subtitle = 'For this page. Set the default in Settings.',
}) =>
    showModalBottomSheet<Paper>(
      context: context,
      showDragHandle: true,
      builder: (_) => _PaperSheet(current: current, subtitle: subtitle),
    );

class _PaperSheet extends StatelessWidget {
  final Paper current;
  final String subtitle;
  const _PaperSheet({required this.current, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Paper', style: AppText.heading(context).copyWith(color: t.onBackground)),
            const SizedBox(height: 2),
            Text(subtitle, style: AppText.caption(context).copyWith(color: t.onSurfaceMuted)),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 14,
              crossAxisSpacing: 12,
              childAspectRatio: 0.78,
              children: [
                for (final p in Paper.values)
                  PaperSwatch(
                    paper: p,
                    selected: p == current,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.pop(context, p);
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A small sheet of [paper] with its name beneath.
class PaperSwatch extends StatelessWidget {
  final Paper paper;
  final bool selected;
  final VoidCallback onTap;
  const PaperSwatch(
      {super.key, required this.paper, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t    = context.tokens;
    final tint = paperTint(context, paper);
    return Semantics(
      button: true,
      selected: selected,
      label: '${paper.label} paper',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: tint ?? t.surfaceElev,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected ? t.primary : t.outlineSoft,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CustomPaint(
                    painter: PaperPainter(
                      paper: paper,
                      rule: tint == null ? t.rule : Color.lerp(tint, t.onBackground, 0.18)!,
                      margin: t.primary.withValues(alpha: 0.5),
                      spacing: 12,
                      topOffset: 2,
                      inset: 10,
                      stroke: 0.8,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(paper.label,
                  textAlign: TextAlign.center,
                  style: AppText.caption(context).copyWith(
                    color: selected ? t.primaryText : t.onSurface,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
