/// The arithmetic behind a chart, with no Flutter and no vocabulary in it.
///
/// Kept apart from the widgets for one reason: every claim this file makes is
/// checkable without pumping anything. A mirrored axis, a dash pattern and a
/// half-drawn line are the three things about a chart that are easy to get
/// subtly wrong and impossible to notice by looking, so they are decided here
/// and asserted directly.
///
/// Not exported by `lib/iux_flutter.dart`. No caller has demonstrated a need
/// for it, and the Component Standard §7 refuses API on that basis.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'iux_chart_model.dart';

/// Maps a value onto a fraction of the extent it is plotted in.
@immutable
final class IuxChartScale {
  /// Creates a scale running from [min] to [max].
  const IuxChartScale({required this.min, required this.max})
      : assert(
          max > min,
          'A chart axis needs two distinct bounds. An axis whose minimum '
          'equals its maximum has no extent to place a value in, and every '
          'point on it would be drawn at the same coordinate — a flat line '
          'that looks like a real reading of a constant.',
        );

  /// The value that falls at fraction zero.
  final double min;

  /// The value that falls at fraction one.
  final double max;

  /// Where [value] falls, from 0 at [min] to 1 at [max].
  ///
  /// A value outside the bounds returns a fraction outside 0..1 rather than
  /// being clamped. A caller whose data leaves the axis it declared has a bug,
  /// and a clamped point would be drawn flat along the edge, which reads as a
  /// measurement rather than as the mistake it is.
  ///
  /// The degenerate case is refused by the constructor; the guard here is what
  /// keeps a release build from painting at NaN if one ever gets through.
  double fractionOf(double value) =>
      max == min ? 0.5 : (value - min) / (max - min);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxChartScale && other.min == min && other.max == max;

  @override
  int get hashCode => Object.hash(min, max);
}

/// Where a fraction of the plot falls horizontally, in reading order.
///
/// Fraction zero is the reading start: the left edge in a left-to-right
/// interface, the right edge in a right-to-left one. A time series in an Arabic
/// interface therefore runs the way the axis labels beside it do.
///
/// This is the only place the mirroring happens. A painter that mirrored on its
/// own would eventually disagree with the labels laid out around it, and a
/// chart whose curve and whose axis point in opposite directions is worse than
/// either convention.
double horizontalOffset(
  double fraction,
  double width,
  TextDirection direction,
) =>
    direction == TextDirection.rtl
        ? width - fraction * width
        : fraction * width;

/// Rewrites [source] as dashes [on] long separated by gaps [off].
///
/// Returns [source] itself when [off] is not positive, which is what a solid
/// stroke asks for — identity rather than a copy, so a solid series costs
/// nothing.
///
/// Every contour is dashed, not only the first: a series broken by missing data
/// is several contours, and dashing one of them would make the gap change the
/// pattern.
Path dashPath(Path source, {required double on, required double off}) {
  if (on <= 0 || off <= 0) return source;
  final Path out = Path();
  for (final PathMetric metric in source.computeMetrics()) {
    double start = 0;
    while (start < metric.length) {
      final double end = math.min(start + on, metric.length);
      out.addPath(metric.extractPath(start, end), Offset.zero);
      start = end + off;
    }
  }
  return out;
}

/// [source], stroked the way [stroke] asks, with [unit] as the mark length.
///
/// The one place the vocabulary meets the arithmetic. Both the plot and the
/// legend swatch call it, which is what stops a series being drawn dashed and
/// advertised dotted — a legend that disagrees with the picture is worse than
/// no legend, because it is believed.
///
/// The proportions: a dash is one unit on and two thirds off, a dot a third on
/// and two thirds off. Measured against a solid line those keep roughly three
/// fifths and a third of the ink, which is far enough apart to tell at arm's
/// length and on a printed grey page.
Path strokeAsPattern(Path source, IuxSeriesStroke stroke, double unit) =>
    switch (stroke) {
      IuxSeriesStroke.solid => source,
      IuxSeriesStroke.dashed => dashPath(source, on: unit, off: unit * 2 / 3),
      IuxSeriesStroke.dotted =>
        dashPath(source, on: unit / 3, off: unit * 2 / 3),
    };

/// The first [fraction] of [source], measured along its length.
///
/// This is what a chart being drawn in looks like part-way through. Measured
/// along the path rather than clipped to a rectangle, so the line arrives at an
/// even speed instead of racing through its flat stretches.
Path pathUpTo(Path source, double fraction) {
  if (fraction >= 1) return source;
  final Path out = Path();
  if (fraction <= 0) return out;
  for (final PathMetric metric in source.computeMetrics()) {
    out.addPath(metric.extractPath(0, metric.length * fraction), Offset.zero);
  }
  return out;
}

/// The total length of [path], summed over its contours.
double pathLength(Path path) {
  double total = 0;
  for (final PathMetric metric in path.computeMetrics()) {
    total += metric.length;
  }
  return total;
}

/// One path per unbroken run of readings in [points].
///
/// A null reading ends the current run and the next reading starts a new one,
/// which is what puts a hole in the line instead of a straight segment across
/// the missing stretch. Joining across a gap would draw a week of steady
/// weather nobody observed.
///
/// A run holding a single reading has no length to stroke, so it is drawn as a
/// dot of radius [dotRadius]. Left as a zero-length line it would disappear,
/// and a reading that exists and is not shown is the failure this component
/// exists to prevent.
///
/// [horizontal] and [vertical] are the value ranges; [size] is the area to draw
/// in. The vertical axis is flipped on the way out, because screen coordinates
/// grow downwards and readings grow upwards — an easy sign error that produces
/// an upside-down chart and no other symptom.
List<Path> seriesPaths(
  List<IuxChartPoint> points, {
  required IuxChartScale horizontal,
  required IuxChartScale vertical,
  required Size size,
  required TextDirection direction,
  required double dotRadius,
}) {
  final List<Path> paths = <Path>[];
  List<Offset> run = <Offset>[];

  void flush() {
    if (run.isEmpty) return;
    final Path path = Path();
    if (run.length == 1) {
      path.addOval(Rect.fromCircle(center: run.single, radius: dotRadius));
    } else {
      path.moveTo(run.first.dx, run.first.dy);
      for (final Offset point in run.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
    }
    paths.add(path);
    run = <Offset>[];
  }

  for (final IuxChartPoint point in points) {
    final double? value = point.value;
    if (value == null) {
      flush();
      continue;
    }
    run.add(
      Offset(
        horizontalOffset(
          horizontal.fractionOf(point.position),
          size.width,
          direction,
        ),
        size.height - vertical.fractionOf(value) * size.height,
      ),
    );
  }
  flush();

  return paths;
}

/// One closed shape per unbroken stretch where both edges of a band exist.
///
/// The two edges are read in step, index by index. A null on either side ends
/// the current shape, so a band with a hole in it has a hole rather than an
/// envelope drawn across a stretch where none was computed.
///
/// A stretch one column wide encloses no area and is dropped: it would paint
/// nothing and outline a hairline that reads as a stray mark.
///
/// The edges may be of different lengths. The shorter one decides, because the
/// overlap is the part both edges describe and refusing the whole band over one
/// extra reading would help nobody.
List<Path> bandPaths(
  List<IuxChartPoint> lower,
  List<IuxChartPoint> upper, {
  required IuxChartScale horizontal,
  required IuxChartScale vertical,
  required Size size,
  required TextDirection direction,
}) {
  final List<Path> paths = <Path>[];
  List<Offset> below = <Offset>[];
  List<Offset> above = <Offset>[];

  void flush() {
    if (below.length >= 2) {
      final Path path = Path()..moveTo(above.first.dx, above.first.dy);
      for (final Offset point in above.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      for (final Offset point in below.reversed) {
        path.lineTo(point.dx, point.dy);
      }
      paths.add(path..close());
    }
    below = <Offset>[];
    above = <Offset>[];
  }

  final int columns = lower.length < upper.length ? lower.length : upper.length;
  for (int i = 0; i < columns; i++) {
    final double? low = lower[i].value;
    final double? high = upper[i].value;
    if (low == null || high == null) {
      flush();
      continue;
    }
    final double dx = horizontalOffset(
      horizontal.fractionOf(lower[i].position),
      size.width,
      direction,
    );
    below.add(Offset(dx, size.height - vertical.fractionOf(low) * size.height));
    above
        .add(Offset(dx, size.height - vertical.fractionOf(high) * size.height));
  }
  flush();

  return paths;
}
