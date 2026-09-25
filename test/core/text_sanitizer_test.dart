import 'package:flutter_test/flutter_test.dart';
import 'package:mapid_case_study/core/utils/text_sanitizer.dart';

void main() {
  group('TextSanitizer.clean', () {
    test('keeps clean text unchanged', () {
      expect(
        TextSanitizer.clean('BENTARA BUDAYA YOGYAKARTA (BBY)'),
        'BENTARA BUDAYA YOGYAKARTA (BBY)',
      );
    });

    test('removes parenthesized groups containing corrupted characters', () {
      expect(
        TextSanitizer.clean('TAMAN WARUNGBOTO (ʦ�ʦ�)'),
        'TAMAN WARUNGBOTO',
      );
    });

    test('removes corrupted groups without a leading space', () {
      expect(
        TextSanitizer.clean('TAMAN TUGU AIR WARUNGBOTO(ʦ�ʧ�)'),
        'TAMAN TUGU AIR WARUNGBOTO',
      );
    });

    test('removes stray replacement characters and collapses whitespace', () {
      expect(TextSanitizer.clean('  TAMAN �   VREDEBURG '), 'TAMAN VREDEBURG');
    });
  });
}
