import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'contrast.dart';

void main() {
  group('contrast measurement', () {
    test('black on white is the maximum ratio', () {
      expect(
        ContrastMetric.ratio(const Color(0xFF000000), const Color(0xFFFFFFFF)),
        closeTo(21, 0.01),
      );
    });

    test('a color against itself is the minimum ratio', () {
      expect(
        ContrastMetric.ratio(const Color(0xFF3366AA), const Color(0xFF3366AA)),
        closeTo(1, 0.0001),
      );
    });

    test('argument order does not change the ratio', () {
      const Color a = Color(0xFF1560B0);
      const Color b = Color(0xFFF6F7F9);
      expect(ContrastMetric.ratio(a, b),
          closeTo(ContrastMetric.ratio(b, a), 1e-12));
    });

    test('luminance matches the WCAG reference for pure channels', () {
      expect(
        ContrastMetric.relativeLuminance(const Color(0xFFFFFFFF)),
        closeTo(1, 1e-9),
      );
      expect(
        ContrastMetric.relativeLuminance(const Color(0xFF000000)),
        closeTo(0, 1e-9),
      );
      expect(
        ContrastMetric.relativeLuminance(const Color(0xFF00FF00)),
        closeTo(0.7152, 1e-4),
      );
    });

    test('meets compares against the requested threshold', () {
      const Color mid = Color(0xFF767676);
      const Color white = Color(0xFFFFFFFF);
      expect(
          ContrastMetric.meets(mid, white, ContrastMetric.normalText), isTrue);
      expect(ContrastMetric.meets(mid, white, 5.0), isFalse);
    });

    test('a translucent color is rejected rather than silently composited', () {
      expect(
        () => ContrastMetric.relativeLuminance(const Color(0x80000000)),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
