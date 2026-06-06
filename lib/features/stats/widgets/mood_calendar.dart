import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/models/journal_entry.dart';
import 'package:baka/models/mood.dart';
import 'package:baka/widgets/illustrations.dart';

class MoodCalendar extends StatefulWidget {
  final List<JournalEntry> entries;
  final void Function(DateTime date, JournalEntry? entry) onDayTap;

  const MoodCalendar({
    super.key,
    required this.entries,
    required this.onDayTap,
  });

  @override
  State<MoodCalendar> createState() => _MoodCalendarState();
}

class _MoodCalendarState extends State<MoodCalendar> {
  late DateTime _month; // first day of displayed month

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  void _prev() => setState(() => _month = DateTime(_month.year, _month.month - 1));
  void _next() {
    final now  = DateTime.now();
    final next = DateTime(_month.year, _month.month + 1);
    if (next.isAfter(DateTime(now.year, now.month))) return; // can't go to future
    setState(() => _month = next);
  }

  @override
  Widget build(BuildContext context) {
    final t   = context.tokens;
    final now = DateTime.now();
    final isCurrentMonth =
        _month.year == now.year && _month.month == now.month;

    // Build date → entry map (most recent entry per day)
    final Map<DateTime, JournalEntry> dayMap = {};
    for (final e in widget.entries) {
      final d = DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day);
      if (d.year == _month.year && d.month == _month.month) {
        // Keep most recent (entries sorted desc already)
        dayMap[d] ??= e;
      }
    }

    final daysInMonth   = DateTime(_month.year, _month.month + 1, 0).day;
    final firstWeekday  = _month.weekday; // 1=Mon … 7=Sun
    final leadingBlanks = firstWeekday - 1;

    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: prev ← Month Year → next
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left_rounded,
                  color: t.onSurfaceMuted, size: 22),
              onPressed: _prev,
              visualDensity: VisualDensity.compact,
            ),
            Expanded(
              child: Center(
                child: Text(
                  DateFormat('MMMM yyyy').format(_month),
                  style: TextStyle(fontFamily: 'Caveat',
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: t.onBackground),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.chevron_right_rounded,
                  color: isCurrentMonth
                      ? t.outline
                      : t.onSurfaceMuted,
                  size: 22),
              onPressed: isCurrentMonth ? null : _next,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Day-of-week labels
        Row(
          children: dayLabels.map((l) => Expanded(
            child: Center(
              child: Text(l,
                  style: TextStyle(fontFamily: 'Caveat',
                    fontSize: 12, color: t.onSurfaceMuted)),
            ),
          )).toList(),
        ),
        const SizedBox(height: 6),

        // Calendar grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1,
          ),
          itemCount: leadingBlanks + daysInMonth,
          itemBuilder: (_, index) {
            if (index < leadingBlanks) return const SizedBox.shrink();

            final day     = index - leadingBlanks + 1;
            final date    = DateTime(_month.year, _month.month, day);
            final entry   = dayMap[date];
            final isToday = date.year == now.year &&
                date.month == now.month &&
                date.day == now.day;
            final isFuture = date.isAfter(now);

            return GestureDetector(
              onTap: isFuture ? null : () => widget.onDayTap(date, entry),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isToday
                      ? t.primaryContainer
                      : Colors.transparent,
                  border: isToday
                      ? Border.all(color: t.primary, width: 1.5)
                      : null,
                ),
                child: Center(
                  child: _DayContent(
                    day: day,
                    entry: entry,
                    isFuture: isFuture,
                    t: t,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _DayContent extends StatelessWidget {
  final int day;
  final JournalEntry? entry;
  final bool isFuture;
  final BakaTokens t;
  const _DayContent({
    required this.day,
    required this.entry,
    required this.isFuture,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    if (isFuture) {
      return Text('$day',
          style: TextStyle(fontFamily: 'Caveat',
            fontSize: 13, color: t.outline));
    }

    if (entry == null) {
      // No entry — show day number, muted
      return Text('$day',
          style: TextStyle(fontFamily: 'Caveat',
            fontSize: 13, color: t.onSurfaceMuted));
    }

    final mood = entry!.mood;
    if (mood == null) {
      // Entry exists but no mood — number above, dot below
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$day',
              style: TextStyle(fontFamily: 'Caveat',
                fontSize: 11, color: t.onBackground)),
          const SizedBox(height: 1),
          Container(
            width: 4, height: 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: t.outline,
            ),
          ),
        ],
      );
    }

    // Entry + mood — show MoodGlyph
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MoodGlyph(mood: mood, size: 16, color: t.primary),
        Text('$day',
            style: TextStyle(fontFamily: 'Caveat',
              fontSize: 10, color: t.primary)),
      ],
    );
  }
}
