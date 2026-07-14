import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:baka/core/prompts/writing_prompts.dart';

const _kNotificationId = 1001;
const _kChannelId = 'daily_reminder';
const _kChannelName = 'Daily reminder';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final _plugin = FlutterLocalNotificationsPlugin();

  // Set this from main() after router is available
  void Function(String? payload)? onNotificationTap;

  Future<void> init() async {
    tz.initializeTimeZones();
    // Set the device's actual timezone so daily repeats fire at the correct
    // LOCAL time. Without this tz.local is UTC and reminders fire offset by
    // the UTC offset (e.g. a 21:00 IST reminder would fire at 02:30).
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Leave tz.local as UTC if lookup fails.
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (details) {
        onNotificationTap?.call(details.payload);
      },
    );
  }

  Future<bool> requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    if (ios != null) {
      final granted = await ios.requestPermissions(alert: true, sound: true);
      return granted ?? false;
    }
    return false;
  }

  Future<void> scheduleDailyReminder(TimeOfDay at) async {
    try {
    await cancelDailyReminder();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, at.hour, at.minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final body = WritingPrompts.todayPrompt();

    const androidDetails = AndroidNotificationDetails(
      _kChannelId,
      _kChannelName,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.zonedSchedule(
      _kNotificationId,
      'Your journal is waiting',
      body,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexact,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'open_new_entry',
    );
    } catch (_) {
      // Permission denied or unavailable — silently skip scheduling.
    }
  }

  Future<void> cancelDailyReminder() async {
    await _plugin.cancel(_kNotificationId);
  }

  Future<bool> areNotificationsEnabled() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    // iOS: assume enabled if we got here
    return true;
  }

  Future<NotificationAppLaunchDetails?> getLaunchDetails() async {
    return _plugin.getNotificationAppLaunchDetails();
  }
}
