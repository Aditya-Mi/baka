/// Linear scan — no regex, no list allocation per call.
int countWords(String text) {
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
