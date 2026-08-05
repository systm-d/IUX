import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/src/components/chart/iux_chart_geometry.dart';

/// A straight horizontal line of a known length, so every assertion below is
/// about the function under test rather than about curve arithmetic.
Path _line(double length) => Path()
  ..moveTo(0, 0)
  ..lineTo(length, 0);

void main() {
  group('IuxChartScale', () {
    test('maps the bounds onto zero and one', () {
      const IuxChartScale scale = IuxChartScale(min: -10, max: 30);
      expect(scale.fractionOf(-10), 0);
      expect(scale.fractionOf(30), 1);
      expect(scale.fractionOf(10), 0.5);
    });

    test('a value outside the axis leaves the range rather than clamping', () {
      // A caller whose data leaves the axis it declared has a bug. Clamping
      // would draw a flat line along the edge that reads as real data.
      const IuxChartScale scale = IuxChartScale(min: 0, max: 10);
      expect(scale.fractionOf(-5), lessThan(0));
      expect(scale.fractionOf(15), greaterThan(1));
    });

    test('a degenerate axis is refused', () {
      expect(
        () => IuxChartScale(min: 5, max: 5),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('horizontalOffset', () {
    test('fraction zero is the reading start', () {
      expect(horizontalOffset(0, 200, TextDirection.ltr), 0);
      expect(horizontalOffset(0, 200, TextDirection.rtl), 200);
    });

    test('fraction one is the reading end', () {
      expect(horizontalOffset(1, 200, TextDirection.ltr), 200);
      expect(horizontalOffset(1, 200, TextDirection.rtl), 0);
    });

    test('the midpoint is the midpoint either way', () {
      expect(horizontalOffset(0.5, 200, TextDirection.ltr), 100);
      expect(horizontalOffset(0.5, 200, TextDirection.rtl), 100);
    });
  });

  group('dashPath', () {
    test('a zero gap returns the source untouched', () {
      final Path source = _line(100);
      expect(identical(dashPath(source, on: 4, off: 0), source), isTrue);
    });

    test('a three-on two-off pattern keeps about three fifths of the line', () {
      final double dashed = pathLength(dashPath(_line(100), on: 3, off: 2));
      // Not exact: the last dash is truncated wherever the contour ends.
      expect(dashed, greaterThan(55));
      expect(dashed, lessThan(65));
    });

    test('a sparser pattern keeps less', () {
      final double dashed = pathLength(dashPath(_line(100), on: 3, off: 2));
      final double dotted = pathLength(dashPath(_line(100), on: 1, off: 2));
      expect(dotted, lessThan(dashed));
    });

    test('every contour is dashed, not only the first', () {
      final Path two = Path()
        ..moveTo(0, 0)
        ..lineTo(100, 0)
        ..moveTo(0, 10)
        ..lineTo(100, 10);
      // Both contours halved, so the total lands near half of 200 rather than
      // near 150 — which is what a loop that dashed only the first would give.
      expect(pathLength(dashPath(two, on: 5, off: 5)), lessThan(120));
    });
  });

  group('pathUpTo', () {
    test('a full fraction returns the source untouched', () {
      final Path source = _line(100);
      expect(identical(pathUpTo(source, 1), source), isTrue);
    });

    test('half the fraction is half the length', () {
      expect(pathLength(pathUpTo(_line(100), 0.5)), closeTo(50, 0.01));
    });

    test('nothing revealed is an empty path', () {
      expect(pathLength(pathUpTo(_line(100), 0)), 0);
    });
  });
}
