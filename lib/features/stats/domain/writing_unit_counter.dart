/// Counts writing units for Chinese-heavy manuscript text.
///
/// CJK ideographs count as one unit each. Contiguous Latin letters or digits
/// count as one unit. Whitespace and punctuation are ignored.
int countWritingUnits(String text) {
  if (text.isEmpty) return 0;

  var count = 0;
  var inLatinRun = false;

  for (final rune in text.runes) {
    if (_isCjkIdeograph(rune)) {
      count++;
      inLatinRun = false;
      continue;
    }

    if (_isLatinLetterOrDigit(rune)) {
      if (!inLatinRun) {
        count++;
        inLatinRun = true;
      }
      continue;
    }

    inLatinRun = false;
  }

  return count;
}

bool _isLatinLetterOrDigit(int rune) {
  return (rune >= 0x30 && rune <= 0x39) ||
      (rune >= 0x41 && rune <= 0x5a) ||
      (rune >= 0x61 && rune <= 0x7a);
}

bool _isCjkIdeograph(int rune) {
  return (rune >= 0x3400 && rune <= 0x4dbf) ||
      (rune >= 0x4e00 && rune <= 0x9fff) ||
      (rune >= 0xf900 && rune <= 0xfaff) ||
      (rune >= 0x20000 && rune <= 0x2a6df) ||
      (rune >= 0x2a700 && rune <= 0x2b73f) ||
      (rune >= 0x2b740 && rune <= 0x2b81f) ||
      (rune >= 0x2b820 && rune <= 0x2ceaf);
}
