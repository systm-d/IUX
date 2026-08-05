import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';
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

  group('seriesPaths', () {
    const IuxChartScale unit = IuxChartScale(min: 0, max: 1);
    const Size size = Size(100, 50);

    List<Path> pathsOf(List<double?> values) => seriesPaths(
          <IuxChartPoint>[
            for (int i = 0; i < values.length; i++)
              IuxChartPoint(
                  position: i / (values.length - 1), value: values[i]),
          ],
          horizontal: unit,
          vertical: unit,
          size: size,
          direction: TextDirection.ltr,
          dotRadius: 1,
        );

    test('an unbroken series is one path', () {
      expect(pathsOf(<double?>[0, 0.5, 1]).length, 1);
    });

    test('a gap breaks the series in two', () {
      // The whole reason IuxChartPoint.value is nullable. Joined across the
      // gap, a missing week of readings becomes a straight line that looks
      // like a week of steady weather.
      expect(pathsOf(<double?>[0, 0.5, null, 0.5, 1]).length, 2);
    });

    test('two gaps in a row are one gap', () {
      expect(pathsOf(<double?>[0, null, null, 1]).length, 2);
    });

    test('a reading alone between two gaps is still drawn', () {
      // A run of one has no length to stroke, so it is drawn as a dot. Left
      // as a zero-length line it would vanish, and a reading that exists and
      // is not shown is the failure this whole component is about.
      final List<Path> paths = pathsOf(<double?>[null, 0.5, null]);
      expect(paths.length, 1);
      expect(pathLength(paths.single), greaterThan(0));
    });

    test('a series of nothing but gaps draws nothing', () {
      expect(pathsOf(<double?>[null, null]), isEmpty);
    });

    test('the first reading sits at the reading start', () {
      const List<IuxChartPoint> deux = <IuxChartPoint>[
        IuxChartPoint(position: 0, value: 0),
        IuxChartPoint(position: 1, value: 1),
      ];
      final Path ltr = seriesPaths(
        deux,
        horizontal: unit,
        vertical: unit,
        size: size,
        direction: TextDirection.ltr,
        dotRadius: 1,
      ).single;
      final Path rtl = seriesPaths(
        deux,
        horizontal: unit,
        vertical: unit,
        size: size,
        direction: TextDirection.rtl,
        dotRadius: 1,
      ).single;

      expect(ltr.getBounds().left, 0);
      expect(rtl.getBounds().right, size.width);
      // Mirrored, not rotated: the same two readings, drawn the other way
      // round. Their vertical extent is untouched.
      expect(ltr.getBounds().height, closeTo(rtl.getBounds().height, 0.01));
    });

    test('the minimum sits at the bottom', () {
      // Screen coordinates grow downwards and values grow upwards. Getting
      // this backwards produces a chart that is upside down and otherwise
      // entirely plausible.
      final Path path = pathsOf(<double?>[0, 1]).single;
      expect(path.getBounds().bottom, closeTo(size.height, 0.01));
      expect(path.getBounds().top, closeTo(0, 0.01));
    });
  });
}
