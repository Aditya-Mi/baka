import 'package:flutter/material.dart';

import 'package:baka/core/theme/app_theme.dart';

import 'package:baka/models/mood.dart';
import 'package:baka/widgets/illustrations.dart';
import 'package:baka/widgets/motion.dart';

class MoodChart extends StatelessWidget {
  final Map<Mood, int> moodCounts;
  final Color primary;
  final Color onBg;
  final Color muted;
  final ValueChanged<Mood>? onMoodTap;

  const MoodChart({
    super.key,
    required this.moodCounts,
    required this.primary,
    required this.onBg,
    required this.muted,
    this.onMoodTap,
  });

  @override
  Widget build(BuildContext context) {
    if (moodCounts.isEmpty) return const SizedBox.shrink();
    final sorted = (moodCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(5)
        .toList();
    final maxCount = sorted.first.value;

    return Column(
      children: [for (final (i, e) in sorted.indexed) () {
        final frac = maxCount > 0 ? e.value / maxCount : 0.0;
        // Rows ink in top to bottom: glyph traced, then the bar drawn across.
        final delay = Duration(milliseconds: 120 + i * 90);
        return InkWell(
          onTap: onMoodTap != null ? () => onMoodTap!(e.key) : null,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: [
                MoodGlyph(mood: e.key, size: 22, color: primary,
                    draw: true, delay: delay),
                const SizedBox(width: 12),
                SizedBox(
                  width: 92,
                  child: Text(e.key.label,
                      style: AppText.bodyPreview(context).copyWith(
                          color: onBg,
                        )),
                ),
                Expanded(
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: frac.clamp(0.04, 1.0)),
                        duration: Motion.of(context, delay + const Duration(milliseconds: 600)),
                        curve: Interval(
                            (delay.inMilliseconds + 200) / (delay.inMilliseconds + 600),
                            1, curve: Curves.easeOutCubic),
                        builder: (_, w, child) => FractionallySizedBox(
                            widthFactor: w, child: child),
                        child: Container(
                          decoration: BoxDecoration(
                            color: primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 26,
                  child: Text('${e.value}',
                      textAlign: TextAlign.right,
                      style: AppText.small(context).copyWith(
                          color: muted,
                        )),
                ),
                if (onMoodTap != null) ...[
                  const SizedBox(width: 4),
                  AppIcon(AppIconData.chevronRight, size: 16, color: muted),
                ],
              ],
            ),
          ),
        );
      }()],
    );
  }
}
