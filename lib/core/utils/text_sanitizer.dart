abstract final class TextSanitizer {
  static const _replacementChar = '�';
  static final _corruptedGroup = RegExp(r'\s*\([^)]*�[^)]*\)?');
  static final _whitespace = RegExp(r'\s+');

  static String clean(String input) {
    return input
        .replaceAll(_corruptedGroup, '')
        .replaceAll(_replacementChar, '')
        .replaceAll(_whitespace, ' ')
        .trim();
  }
}
