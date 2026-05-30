import 'package:intl/intl.dart';

String formatEntryDate(DateTime dt) {
  return DateFormat.yMMMMd().format(dt);
}

String formatEntryTime(DateTime dt) {
  return DateFormat.jm().format(dt);
}

String formatEntryDateShort(DateTime dt) {
  return DateFormat.MMMd().format(dt);
}

String formatReminderTime(DateTime dt) {
  return DateFormat.jm().format(dt);
}
