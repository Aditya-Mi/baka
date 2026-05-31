import 'package:flutter/material.dart';

Future<void> pickTime(BuildContext context, ValueNotifier<DateTime> notifier) async {
  final current = notifier.value;
  final picked  = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(current),
  );
  if (picked == null || !context.mounted) return;
  var updated = DateTime(
      current.year, current.month, current.day, picked.hour, picked.minute);
  final now     = DateTime.now();
  final isToday = current.year == now.year &&
      current.month == now.month &&
      current.day == now.day;
  if (isToday && updated.isAfter(now)) {
    updated = DateTime(now.year, now.month, now.day, now.hour, now.minute);
  }
  notifier.value = updated;
}
