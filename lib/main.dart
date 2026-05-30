import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:baka/core/db/database_helper.dart';
import 'package:baka/core/notifications/notification_service.dart';
import 'package:baka/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.initDb();
  await NotificationService.instance.init();

  // Check if app was cold-launched by a notification tap.
  // If so, queue navigation to /new after first frame.
  final launchDetails = await NotificationService.instance.getLaunchDetails();
  String? coldLaunchPayload;
  if (launchDetails != null &&
      launchDetails.didNotificationLaunchApp &&
      launchDetails.notificationResponse?.payload == 'open_new_entry') {
    coldLaunchPayload = launchDetails.notificationResponse?.payload;
  }

  runApp(ProviderScope(
    child: App(coldLaunchPayload: coldLaunchPayload),
  ));
}
