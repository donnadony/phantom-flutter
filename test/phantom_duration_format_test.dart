import 'package:flutter_test/flutter_test.dart';
import 'package:phantom_flutter/src/theme/phantom_theme.dart';
import 'package:phantom_flutter/src/utils/phantom_duration_format.dart';

void main() {
  group('phantomFormatDuration', () {
    test('reads a sub-second call in hundredths of a second', () {
      expect(phantomFormatDuration(350), '0.35 s');
      expect(phantomFormatDuration(4), '0.00 s');
      expect(phantomFormatDuration(999), '1.00 s');
    });

    test('reads a call of a few seconds in tenths', () {
      expect(phantomFormatDuration(1000), '1.0 s');
      expect(phantomFormatDuration(1200), '1.2 s');
      expect(phantomFormatDuration(9500), '9.5 s');
    });

    test('drops the decimals past ten seconds', () {
      expect(phantomFormatDuration(12000), '12 s');
      expect(phantomFormatDuration(65400), '65 s');
    });
  });

  group('durationColor', () {
    const theme = PhantomTheme.kodivex;

    test('a call up to a second is the success colour', () {
      expect(theme.durationColor(120), theme.success);
      expect(theme.durationColor(1000), theme.success);
    });

    test('a call over a second is the error colour', () {
      expect(theme.durationColor(1001), theme.error);
      expect(theme.durationColor(8000), theme.error);
    });
  });
}
