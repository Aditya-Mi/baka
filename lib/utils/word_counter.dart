import 'package:baka/utils/note_marks.dart';

/// Words as written: list marks, checkboxes and time stamps don't count.
int countWords(String text) => _count(stripMarks(text));

/// Linear scan — no regex, no list allocation per call.
int _count(String text) {
  int count = 0;
  bool inWord = false;
  for (int i = 0; i < text.length; i++) {
    final c = text[i];
    if (c == ' ' || c == '\n' || c == '\t' || c == '\r') {
      inWord = false;
    } else if (!inWord) {
      count++;
      inWord = true;
    }
  }
  return count;
}
