/// The vocabulary a chart is described in.
///
/// Values only: no colours, no sizes, no `BuildContext`. What a series looks
/// like is decided by the theme from the intent stated here, which is what
/// keeps the same data correct in light, dark and high contrast without the
/// caller knowing those exist.
library;

import 'package:flutter/foundation.dart';

/// The pattern a line is stroked with.
///
/// This is the channel that survives a screen with no usable colour on it — a
/// monochrome display, a night filter, a colour-vision deficiency, a
/// screenshot printed in grey. IUX refuses two series with the same pattern in
/// one chart for exactly that reason: on such a screen they would be one line
/// drawn twice.
///
/// Three patterns therefore means three series at most. That is a benefit
/// rather than a shortfall — a five-line chart is unreadable before it is
/// inaccessible.
enum IuxSeriesStroke {
  /// An unbroken line. The subject of most charts.
  solid,

  /// Long marks with short gaps. Reads as a full line at a glance and stays
  /// distinguishable close up.
  dashed,

  /// Short marks with long gaps. The least prominent of the three, so it suits
  /// the series that provides context rather than the one being examined.
  dotted,
}

/// How much visual weight a series or a bar carries.
///
/// Two values, and no more until something needs a third. A chart in which
/// four things all claim different weight has no subject.
enum IuxSeriesEmphasis {
  /// What the chart is about.
  primary,

  /// What the subject is read against.
  secondary,
}

/// One reading, at one position.
///
/// [value] is nullable and null means *absent*, never zero. A gap in a
/// temperature series is a day nobody measured; drawing it as zero puts a
/// freezing day in the middle of July, and nothing on screen says it was
/// invented.
@immutable
final class IuxChartPoint {
  /// Creates a reading, or a gap when [value] is null.
  const IuxChartPoint({required this.position, required this.value});

  /// Where along the horizontal axis this reading sits.
  ///
  /// Any monotonic quantity the caller chooses — a day number, a year, an
  /// index. IUX never interprets it and never sorts by it.
  final double position;

  /// What was read, or null when nothing was.
  final double? value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxChartPoint &&
          other.position == position &&
          other.value == value;

  @override
  int get hashCode => Object.hash(position, value);
}

/// One line on a chart.
///
/// Equality is identity, and deliberately. A year of daily readings is 365
/// points; comparing them element by element on every rebuild costs more than
/// the rebuild it would avoid. Callers who need to know whether the data
/// changed already know — they are the ones who changed it.
@immutable
final class IuxChartSeries {
  /// Creates a series.
  const IuxChartSeries({
    required this.label,
    required this.points,
    required this.stroke,
    this.emphasis = IuxSeriesEmphasis.primary,
  }) : assert(
          label.length > 0,
          'A series must be named. The name is what the legend shows and what '
          'tells a reader which of two lines is which; without it a chart with '
          'more than one series states two things and says which is which to '
          'nobody.',
        );

  /// What this line is, already localised. Shown in the legend.
  final String label;

  /// The readings, in the order they are drawn.
  ///
  /// Not sorted by IUX. A caller who supplies them out of order gets a line
  /// that doubles back, which is visible immediately and is their bug to fix —
  /// sorting silently would hide a data error instead.
  final List<IuxChartPoint> points;

  /// The pattern this line is stroked with.
  ///
  /// Must differ from every other series in the same chart. See
  /// [IuxSeriesStroke].
  final IuxSeriesStroke stroke;

  /// How much weight this line carries against the others.
  final IuxSeriesEmphasis emphasis;
}

/// An envelope a series is read against — a normal, a tolerance, a forecast
/// range.
///
/// The band is a filled area rather than two lines, which is what makes it a
/// different visual channel from every series drawn over it. It is therefore
/// distinguishable from them without depending on colour.
///
/// Equality is identity, for the reason given on [IuxChartSeries].
@immutable
final class IuxChartBand {
  /// Creates a reference band.
  const IuxChartBand({
    required this.label,
    required this.lower,
    required this.upper,
  }) : assert(
          label.length > 0,
          'A band must be named. An unnamed grey area behind a curve is a '
          'decoration that the reader has to guess the meaning of, and a '
          'screen-reader user is not told it exists at all.',
        );

  /// What the envelope represents, already localised. Shown in the legend.
  final String label;

  /// The lower edge.
  final List<IuxChartPoint> lower;

  /// The upper edge.
  ///
  /// Read in the same order as [lower]; the two are joined into one closed
  /// shape. A point that is null on either edge ends the shape and starts a
  /// new one, so a band with a hole in it has a hole rather than a straight
  /// line across the missing stretch.
  final List<IuxChartPoint> upper;
}

/// One labelled position on an axis.
@immutable
final class IuxAxisTick {
  /// Creates a tick.
  const IuxAxisTick({required this.value, required this.label});

  /// Where on the axis it falls.
  final double value;

  /// What to write there, already localised and already formatted.
  ///
  /// IUX composes no number: "8,4 °C", "8.4°C" and "٨٫٤" are three strings and
  /// only the caller knows which one this locale wants.
  final String label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxAxisTick && other.value == value && other.label == label;

  @override
  int get hashCode => Object.hash(value, label);
}

/// The bounds of an axis, and the positions worth naming on it.
///
/// **IUX does not choose the bounds.** A framework that rounded them to
/// pleasant numbers would give two charts on the same screen two different
/// scales, and a comparison across two scales is not a comparison. The caller
/// states the range, which is also what lets several years be drawn against
/// each other.
@immutable
final class IuxChartAxis {
  /// Creates an axis.
  const IuxChartAxis({
    required this.min,
    required this.max,
    required this.ticks,
  });

  /// The value at the start of the axis.
  final double min;

  /// The value at the end of the axis.
  final double max;

  /// The positions to label and to rule a gridline at.
  ///
  /// May be empty, which draws a plot with no grid. Ticks outside [min] and
  /// [max] are drawn where they fall, off the plot — the caller is told by
  /// looking rather than by having them silently dropped.
  final List<IuxAxisTick> ticks;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxChartAxis &&
          other.min == min &&
          other.max == max &&
          listEquals(other.ticks, ticks);

  @override
  int get hashCode => Object.hash(min, max, Object.hashAll(ticks));
}

/// A stretch of a chart, and the sentence a screen reader says about it.
///
/// **A stop is not a datum.** A year profile paints 365 points and declares
/// twelve stops: the picture stays fine and the exploration stays listenable.
/// Were the two the same thing, a caller would have to choose between a chart
/// too coarse to read and an exploration 365 swipes long, and nobody would
/// choose the second.
///
/// Stops are laid over the stretch they describe, so exploring by touch lands
/// on the part of the picture being spoken about.
@immutable
final class IuxChartStop {
  /// Creates a stop covering [start] to [end] on the horizontal axis.
  const IuxChartStop({
    required this.start,
    required this.end,
    required this.label,
  }) : assert(
          label.length > 0,
          'A stop with no sentence is a stop that announces nothing, which '
          'adds a swipe to the exploration and gives it back no information.',
        );

  /// Where the stretch begins, on the horizontal axis.
  final double start;

  /// Where it ends.
  final double end;

  /// What this stretch of the chart says, already localised.
  ///
  /// Write it to stand alone: it is heard on its own, out of order, by
  /// somebody who cannot see what surrounds it.
  final String label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxChartStop &&
          other.start == start &&
          other.end == end &&
          other.label == label;

  @override
  int get hashCode => Object.hash(start, end, label);
}

/// One bar.
@immutable
final class IuxChartBar {
  /// Creates a bar.
  const IuxChartBar({
    required this.label,
    required this.value,
    required this.valueLabel,
    this.emphasis = IuxSeriesEmphasis.primary,
  })  : assert(
          label.length > 0,
          'A bar must be named. An unnamed bar is a length with nothing '
          'attached to it, and a screen reader reads it as exactly that.',
        ),
        assert(
          valueLabel.length > 0,
          'valueLabel is the bar said in words, and it is required for the '
          'same reason IuxProgressIndicator requires one: the length is the '
          'sighted reading and the words are the spoken one. Without them a '
          'screen-reader user is asked to estimate a length they cannot see.',
        ),
        assert(
          value >= 0,
          'A bar is a length, and a length is not signed. A chart of values '
          'that can go below zero needs a baseline in the middle of the row, '
          'which changes how every bar is read — that is a different '
          'component. Drawing a negative here would show a drought and a '
          'flood at the same size.',
        );

  /// What this bar counts, already localised.
  final String label;

  /// How long the bar is, relative to the longest bar in the chart.
  ///
  /// Not clamped and not normalised here: [IuxBarChart] divides by the largest
  /// value it was given, so a caller passes raw quantities and the chart stays
  /// the one place the scale is decided.
  final double value;

  /// [value] in words, already localised — "412 mm", "3 of 7".
  ///
  /// IUX composes no number. See [IuxAxisTick.label].
  final String valueLabel;

  /// How much weight this bar carries against the others.
  ///
  /// Useful for marking the row the reader arrived for — the current commune
  /// in a ranking — without moving it out of order.
  final IuxSeriesEmphasis emphasis;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxChartBar &&
          other.label == label &&
          other.value == value &&
          other.valueLabel == valueLabel &&
          other.emphasis == emphasis;

  @override
  int get hashCode => Object.hash(label, value, valueLabel, emphasis);
}
