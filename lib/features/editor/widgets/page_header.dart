import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/models/mood.dart';
import 'package:baka/utils/time_picker_util.dart';
import 'package:baka/widgets/illustrations.dart';

/// Page header shared by Detail and the editors: large handwritten day name,
/// then "Month d, y · time". The editors pass [entryDate] to make the time a
/// tappable chip that opens the time picker.
class PageHeader extends StatelessWidget {
  final DateTime date;
  final ValueNotifier<DateTime>? entryDate;
  final Mood? mood;
  const PageHeader({super.key, required this.date, this.entryDate, this.mood});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final meta = AppText.label(context).copyWith(
        color: t.onSurfaceMuted,
      );
    final time = DateFormat.jm().format(date);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE').format(date),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.dayTitle(context).copyWith(
                fontWeight: FontWeight.w700,
                color: t.onBackground,
                height: 1.1,
              ),
          ),
          const SizedBox(height: 2),
          // Date shrinks first (ellipsis) so large font scales never overflow.
          Row(
            children: [
              Flexible(
                child: Text(DateFormat('MMMM d, y').format(date),
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: meta),
              ),
              Text(' · ', style: meta),
              if (entryDate != null)
                _TimeChip(label: time,
                    onTap: () => pickTime(context, entryDate!))
              else
                Text(time, maxLines: 1, style: meta),
              if (mood != null) ...[
                const SizedBox(width: 12),
                const Spacer(),
                MoodGlyph(mood: mood!, size: 18, color: t.primary),
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 110),
                  child: Text(mood!.label,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: AppText.caption(context).copyWith(
                          color: t.onPrimaryContainer,
                        )),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TimeChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Material(
      color: t.primaryContainer,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 32),
          padding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: AppText.label(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: t.onPrimaryContainer,
                    )),
              const SizedBox(width: 2),
              AppIcon(AppIconData.chevronDown,
                  size: 18, color: t.onPrimaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}
