import 'package:flutter/material.dart';

/// GitHub linguist colors for the most common languages.
const Map<String, Color> _languageColors = <String, Color>{
  'dart': Color(0xFF00B4AB),
  'java': Color(0xFFB07219),
  'python': Color(0xFF3572A5),
  'javascript': Color(0xFFF1E05A),
  'typescript': Color(0xFF3178C6),
  'c': Color(0xFF555555),
  'c++': Color(0xFFF34B7D),
  'c#': Color(0xFF178600),
  'go': Color(0xFF00ADD8),
  'rust': Color(0xFFDEA584),
  'kotlin': Color(0xFFA97BFF),
  'swift': Color(0xFFF05138),
  'ruby': Color(0xFF701516),
  'php': Color(0xFF4F5D95),
  'html': Color(0xFFE34C26),
  'css': Color(0xFF563D7C),
  'shell': Color(0xFF89E051),
  'objective-c': Color(0xFF438EFF),
};

/// Dot color for a language label; falls back to neutral grey.
Color languageColor(String? language) {
  if (language == null) return const Color(0xFF8B949E);
  return _languageColors[language.toLowerCase()] ?? const Color(0xFF8B949E);
}

/// Parses a GitHub label color (`rrggbb`, without `#`) into a [Color].
Color colorFromHex(String hex) {
  final normalized = hex.replaceAll('#', '');
  if (normalized.length != 6) return const Color(0xFF8B949E);
  final value = int.tryParse('ff$normalized', radix: 16);
  return value == null ? const Color(0xFF8B949E) : Color(value);
}

/// Readable foreground (black/white) for a colored background chip.
Color contrastOn(Color background) {
  return background.computeLuminance() > 0.5 ? Colors.black : Colors.white;
}
