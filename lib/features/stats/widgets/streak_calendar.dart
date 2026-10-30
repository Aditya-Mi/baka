import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:baka/core/theme/app_theme.dart';

class StreakCalendar extends StatefulWidget {
  final Map<DateTime, int> entriesPerDay;
  final Color primary;
  final bool isDark;

  const StreakCalendar({
    super.key,
    required this.entriesPerDay,
    required this.primary,
    required this.isDark,
  });

  @override
  State<StreakCalendar> createState() => _StreakCalendarState();
}

class _StreakCalendarState extends State<StreakCalendar> {
  final _scroll = ScrollController();

  static const _cell  = 10.0;
  static const _gap   = 3.0;
  static const _total = _cell + _gap;

  @override
  void initState() {
    super.initState();
    // Jump to the rightmost position (current month) after layout.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Color _heat(List<Color> levels, int count) =>
      levels[count.clamp(0, levels.length - 1)];

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    var start = today.subtract(const Duration(days: 364));
    start = start.subtract(Duration(days: (start.weekday - 1) % 7));

    final weeks = <List<DateTime?>>[];
    var cur = start;
    while (cur.isBefore(today.add(const Duration(days: 1)))) {
      final week = List<DateTime?>.generate(7, (d) {
        final day = cur.add(Duration(days: d));
        return day.isAfter(today) ? null : day;
      });
      weeks.add(week);
      cur = cur.add(const Duration(days: 7));
    }

    final monthLabels = <int, String>{};
    for (var wi = 0; wi < weeks.length; wi++) {
      for (final day in weeks[wi]) {
        if (day != null && day.day == 1) {
          monthLabels[wi] = DateFormat.MMM().format(day);
          break;
        }
      }
    }

    final t     = context.tokens;
    final muted = t.onSurfaceMuted;
    const dayLabels = ['M', '', 'W', '', 'F', '', ''];

    return SingleChildScrollView(
      controller: _scroll,
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month row — grows with the system text scale so labels never clip.
          SizedBox(
            height: MediaQuery.textScalerOf(context).scale(16),
            child: Row(
              children: [
                const SizedBox(width: 16),
                ...weeks.asMap().entries.map((e) {
                  final label = monthLabels[e.key];
                  return SizedBox(
                    width: _total,
                    child: label == null
                        ? null
                        // Labels are wider than one week column; let them overflow.
                        : OverflowBox(
                            alignment: Alignment.centerLeft,
                            maxWidth: 40,
                            child: Text(label,
                                softWrap: false,
                                style: AppText.micro(context).copyWith(
                                    color: muted,
                                  )),
                          ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day labels
              Column(
                children: List.generate(7, (i) => SizedBox(
                  width: 14, height: _total,
                  child: Center(
                    child: Text(dayLabels[i],
                        style: AppText.micro(context).copyWith(
                            color: muted,
                          )),
                  ),
                )),
              ),
              // Week columns
              ...weeks.map((week) => Column(
                children: List.generate(7, (di) {
                  final day = week[di];
                  if (day == null) {
                    return const SizedBox(width: _total, height: _total);
                  }
                  final key   = DateTime(day.year, day.month, day.day);
                  final count = widget.entriesPerDay[key] ?? 0;
                  return Container(
                    width: _cell, height: _cell,
                    margin: const EdgeInsets.all(_gap / 2),
                    decoration: BoxDecoration(
                      color: _heat(t.heatmap, count),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              )),
            ],
          ),
        ],
      ),
    );
  }
}
