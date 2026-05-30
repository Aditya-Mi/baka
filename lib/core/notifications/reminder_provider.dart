import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

const _kEnabled = 'reminder_enabled';
const _kHour   = 'reminder_hour';
const _kMinute = 'reminder_minute';

class ReminderState {
  final bool enabled;
  final TimeOfDay time;

  const ReminderState({required this.enabled, required this.time});

  static const defaultTime = TimeOfDay(hour: 21, minute: 0);

  ReminderState copyWith({bool? enabled, TimeOfDay? time}) {
    return ReminderState(
      enabled: enabled ?? this.enabled,
      time: time ?? this.time,
    );
  }
}

class ReminderNotifier extends Notifier<ReminderState> {
  @override
  ReminderState build() {
    _loadFromPrefs();
    return const ReminderState(enabled: false, time: ReminderState.defaultTime);
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_kEnabled) ?? false;
    final hour   = prefs.getInt(_kHour)   ?? 21;
    final minute = prefs.getInt(_kMinute) ?? 0;
    state = ReminderState(enabled: enabled, time: TimeOfDay(hour: hour, minute: minute));
  }

  Future<void> setEnabled(bool value) async {
    state = state.copyWith(enabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, value);
    if (value) {
      await NotificationService.instance.scheduleDailyReminder(state.time);
    } else {
      await NotificationService.instance.cancelDailyReminder();
    }
  }

  Future<void> setTime(TimeOfDay t) async {
    state = state.copyWith(time: t);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kHour, t.hour);
    await prefs.setInt(_kMinute, t.minute);
    if (state.enabled) {
      await NotificationService.instance.scheduleDailyReminder(t);
    }
  }

  Future<void> refreshScheduleOnOpen() async {
    if (state.enabled) {
      await NotificationService.instance.scheduleDailyReminder(state.time);
    }
  }
}

final reminderProvider = NotifierProvider<ReminderNotifier, ReminderState>(
  ReminderNotifier.new,
);
