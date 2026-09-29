class TextNormalizer {
  TextNormalizer._();

  /// Removes Vietnamese accents, collapses whitespace, converts to lowercase.
  /// Used ONLY for pattern/keyword matching. NEVER alters original text in database.
  static String normalize(String? text) {
    if (text == null || text.trim().isEmpty) return '';

    // 1. Trim and lowercase
    String result = text.trim().toLowerCase();

    // 2. Collapse multiple whitespaces and newlines into single spaces
    result = result.replaceAll(RegExp(r'\s+'), ' ');

    // 3. Map accented Vietnamese vowels to ASCII equivalents
    const fromChars =
        'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const toChars =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';

    for (int i = 0; i < fromChars.length; i++) {
      result = result.replaceAll(fromChars[i], toChars[i]);
    }

    return result;
  }

  /// Checks if the source text contains any of the target keywords (accent-insensitive & case-insensitive)
  static bool containsAny(String? source, List<String> keywords) {
    if (source == null || source.isEmpty) return false;
    final normalized = normalize(source);

    for (final kw in keywords) {
      final normKw = normalize(kw);
      if (normKw.isEmpty) continue;

      // For short keywords (<= 3 chars, e.g. 'otp', 'vnd', 'pin'), use word boundaries
      if (normKw.length <= 3) {
        final regex = RegExp('(^|[^a-z0-9])${RegExp.escape(normKw)}([^a-z0-9]|\$)', caseSensitive: false);
        if (regex.hasMatch(normalized)) return true;
      } else {
        if (normalized.contains(normKw)) return true;
      }
    }
    return false;
  }

  /// Extracts the first occurrence matching regex pattern, or returns null.
  /// Never invents or hallucinates fake values.
  static String? extractFirstMatch(String? source, RegExp pattern, {int group = 0}) {
    if (source == null || source.isEmpty) return null;
    final match = pattern.firstMatch(source);
    if (match != null && match.groupCount >= group) {
      return match.group(group)?.trim();
    }
    return null;
  }
}
