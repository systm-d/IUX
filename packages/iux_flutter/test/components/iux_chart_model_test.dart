import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

void main() {
  group('IuxChartPoint', () {
    test('a missing reading is null, and null is not zero', () {
      const IuxChartPoint absent = IuxChartPoint(position: 12, value: null);
      expect(absent.value, isNull);
      expect(absent.value == 0, isFalse);
    });

    test('two points with the same position and value are the same point', () {
      expect(
        const IuxChartPoint(position: 3, value: 8.4),
        const IuxChartPoint(position: 3, value: 8.4),
      );
      expect(
        const IuxChartPoint(position: 3, value: 8.4).hashCode,
        const IuxChartPoint(position: 3, value: 8.4).hashCode,
      );
    });

    test('a gap differs from a zero', () {
      expect(
        const IuxChartPoint(position: 3, value: null),
        isNot(const IuxChartPoint(position: 3, value: 0)),
      );
    });
  });

  group('IuxChartSeries', () {
    test('emphasis defaults to primary', () {
      const IuxChartSeries series = IuxChartSeries(
        label: 'x',
        points: <IuxChartPoint>[],
        stroke: IuxSeriesStroke.solid,
      );
      expect(series.emphasis, IuxSeriesEmphasis.primary);
    });

    test('two series holding the same points are still two series', () {
      // Identity equality, on purpose. A year of daily readings is 365 points,
      // and comparing them on every rebuild costs more than the rebuild it
      // would save.
      //
      // Built without `const`, and that is the whole subtlety: Dart
      // canonicalises structurally identical const objects into a single
      // instance, so a const version of this test would pass by measuring the
      // compiler rather than the class — and would keep passing if somebody
      // later added a deep `==`.
      final List<IuxChartPoint> points = <IuxChartPoint>[
        const IuxChartPoint(position: 0, value: 1),
      ];
      IuxChartSeries construire() => IuxChartSeries(
            label: 'x',
            points: points,
            stroke: IuxSeriesStroke.solid,
          );

      expect(construire(), isNot(construire()));
    });
  });

  group('IuxChartAxis', () {
    test('two axes with the same bounds and ticks are the same axis', () {
      const IuxChartAxis a = IuxChartAxis(
        min: 0,
        max: 100,
        ticks: <IuxAxisTick>[IuxAxisTick(value: 50, label: 'half')],
      );
      const IuxChartAxis b = IuxChartAxis(
        min: 0,
        max: 100,
        ticks: <IuxAxisTick>[IuxAxisTick(value: 50, label: 'half')],
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('a different tick label is a different axis', () {
      expect(
        const IuxChartAxis(
          min: 0,
          max: 1,
          ticks: <IuxAxisTick>[IuxAxisTick(value: 0, label: 'zero')],
        ),
        isNot(
          const IuxChartAxis(
            min: 0,
            max: 1,
            ticks: <IuxAxisTick>[IuxAxisTick(value: 0, label: 'nil')],
          ),
        ),
      );
    });
  });

  group('IuxChartStop', () {
    test('carries a range and a sentence about it', () {
      const IuxChartStop stop = IuxChartStop(start: 0, end: 31, label: 'x');
      expect(stop.start, 0);
      expect(stop.end, 31);
      expect(stop.label, 'x');
    });

    test('value semantics', () {
      expect(
        const IuxChartStop(start: 0, end: 31, label: 'x'),
        const IuxChartStop(start: 0, end: 31, label: 'x'),
      );
    });
  });

  group('IuxChartBar', () {
    test('an unnamed bar is refused', () {
      expect(
        () => IuxChartBar(label: '', value: 1, valueLabel: 'one'),
        throwsA(isA<AssertionError>()),
      );
    });

    test('a bar with no value in words is refused', () {
      // The bar length is the sighted reading and the words are the spoken
      // one. A bar without words leaves a screen-reader user estimating a
      // length they cannot see.
      expect(
        () => IuxChartBar(label: 'Paris', value: 1, valueLabel: ''),
        throwsA(isA<AssertionError>()),
      );
    });

    test('a negative value is refused', () {
      // A bar chart of signed values needs a baseline in the middle of the
      // row, and everything about reading it changes. That is a different
      // component; drawing a negative as a length would show a drought and a
      // flood the same size.
      expect(
        () => IuxChartBar(label: 'Paris', value: -1, valueLabel: 'minus one'),
        throwsA(isA<AssertionError>()),
      );
    });

    test('emphasis defaults to primary', () {
      const IuxChartBar bar =
          IuxChartBar(label: 'Paris', value: 1, valueLabel: 'one');
      expect(bar.emphasis, IuxSeriesEmphasis.primary);
    });
  });
}
