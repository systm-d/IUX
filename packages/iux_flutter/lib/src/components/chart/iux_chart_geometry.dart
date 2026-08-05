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
