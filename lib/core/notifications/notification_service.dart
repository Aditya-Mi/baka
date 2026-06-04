import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

    // Use DateTime.now() (already local time) to avoid IANA timezone lookup.
    // millisecondsSinceEpoch correctly encodes the UTC epoch for the local time.
    final now = DateTime.now();
    var localScheduled = DateTime(now.year, now.month, now.day, at.hour, at.minute);
    if (localScheduled.isBefore(now)) {
      localScheduled = localScheduled.add(const Duration(days: 1));
    }
    final scheduled = tz.TZDateTime.fromMillisecondsSinceEpoch(
      tz.local,
      localScheduled.millisecondsSinceEpoch,
    );

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
