import 'package:flutter/material.dart';

import '../../accessibility/iux_semantics.dart';
import 'iux_chart_geometry.dart';
import 'iux_chart_model.dart';
import 'iux_chart_tokens.dart';

/// How far a flat series is spread so it has a range to be drawn in.
///
/// Half a unit either side of the value. Any positive number would do; what
/// matters is that a series of identical readings lands in the middle of the
/// strip rather than at NaN.
const double _flatSeriesSpread = 0.5;

/// A trend, small enough to sit beside the number it is about.
///
/// ```dart
/// IuxSparkline(
///   points: trend,
///   semanticsSummary: l10n.warmerEveryYearSince(2014),
/// )
/// ```
///
/// **Use it** where the shape is the whole message — is this going up or down,
/// steadily or not — and the numbers are already on screen beside it.
///
/// **Do not use it** to be read from. It has no axis, no grid and no labels,
/// so nobody can take a value off it; that is `IuxLineChart`. Do not put two
/// beside each other and expect them to be comparable either: each one is
/// scaled to its own readings, because a sparkline shows shape rather than
/// level. Two series on one scale is two lines on one `IuxLineChart`.
///
/// ## Accessibility
///
/// [semanticsSummary] is required, and it is the entire alternative: there is
/// no point-by-point exploration here, because a strip this small has nothing
/// to explore. Write the sentence the picture is for.
class IuxSparkline extends StatelessWidget {
  /// Creates a sparkline.
  const IuxSparkline({
    super.key,
    required this.points,
    required this.semanticsSummary,
  });

  /// The readings, in drawing order. A null value is a gap.
  final List<IuxChartPoint> points;

  /// What the shape says, already localised.
  ///
  /// Required, and never composed by IUX. A picture with no text alternative
  /// is not a picture for everyone — it is a picture for the people who can
  /// see it, and this parameter is what makes that impossible to ship by
  /// accident.
  final String semanticsSummary;

  /// The vertical range the readings occupy.
  ///
  /// Derived rather than declared: a sparkline is about shape, and asking a
  /// caller to compute bounds for a decoration is friction with nothing behind
  /// it. A flat series is spread by [_flatSeriesSpread] so it lands in the
  /// middle of the strip instead of dividing by zero.
  IuxChartScale get _vertical {
    double low = double.infinity;
    double high = double.negativeInfinity;
    for (final IuxChartPoint point in points) {
      final double? value = point.value;
      if (value == null || !value.isFinite) continue;
      if (value < low) low = value;
      if (value > high) high = value;
    }
    if (low > high) return const IuxChartScale(min: 0, max: 1);
    if (low == high) {
      return IuxChartScale(
        min: low - _flatSeriesSpread,
        max: high + _flatSeriesSpread,
      );
    }
    return IuxChartScale(min: low, max: high);
  }

  /// The horizontal range, from the first position to the last.
  IuxChartScale get _horizontal {
    final double first = points.first.position;
    final double last = points.last.position;
    return first == last
        ? IuxChartScale(
            min: first - _flatSeriesSpread,
            max: last + _flatSeriesSpread,
          )
        : IuxChartScale(min: first, max: last);
  }

  @override
  Widget build(BuildContext context) {
    // Checked here rather than in the constructor for the reason
    // IuxProgressIndicator checks its own label there: a const constructor may
    // only assert on constant expressions, and the length of a list is not
    // one. The assertion fires on the first frame either way.
    assert(
      points.isNotEmpty,
      'A sparkline of no readings draws nothing and says nothing. A series '
      'with no data is an IuxEmptyState at the call site, which can explain '
      'why there is nothing — an empty strip cannot.',
    );
    assert(
      semanticsSummary.length > 0,
      'semanticsSummary is the whole alternative to the picture. Empty, this '
      'is a shape that exists for sighted users and does not exist at all for '
      'anyone else.',
    );

    // The assertion above is the real guard. This is what keeps a release
    // build from reading `points.first` on an empty list — the same division
    // of labour as IuxProgressIndicator, which asserts its fraction and then
    // clamps it anyway.
    if (points.isEmpty) return const SizedBox.shrink();

    final IuxChartTokens tokens = IuxChartResolver.resolve(context);
    final TextDirection direction = Directionality.of(context);

    final Widget strip = SizedBox(
      height: tokens.sparklineHeight,
      width: double.infinity,
      child: tokens.reveal.isAnimated
          ? TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: tokens.reveal.duration,
              curve: tokens.reveal.curve,
              builder: (BuildContext context, double revealed, Widget? child) =>
                  CustomPaint(painter: _painter(tokens, direction, revealed)),
            )
          : CustomPaint(painter: _painter(tokens, direction, 1)),
    );

    return IuxSemantics.image(label: semanticsSummary, child: strip);
  }

  _SparklinePainter _painter(
    IuxChartTokens tokens,
    TextDirection direction,
    double revealed,
  ) =>
      _SparklinePainter(
        points: points,
        horizontal: _horizontal,
        vertical: _vertical,
        tokens: tokens,
        direction: direction,
        revealed: revealed,
      );
}

/// Strokes the runs of a sparkline, and nothing else.
class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({
    required this.points,
    required this.horizontal,
    required this.vertical,
    required this.tokens,
    required this.direction,
    required this.revealed,
  });

  final List<IuxChartPoint> points;
  final IuxChartScale horizontal;
  final IuxChartScale vertical;
  final IuxChartTokens tokens;
  final TextDirection direction;
  final double revealed;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = tokens.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = tokens.primaryStroke;

    for (final Path run in seriesPaths(
      points,
      horizontal: horizontal,
      vertical: vertical,
      size: size,
      direction: direction,
      dotRadius: tokens.strokeWidth,
    )) {
      canvas.drawPath(pathUpTo(run, revealed), stroke);
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      !identical(old.points, points) ||
      old.horizontal != horizontal ||
      old.vertical != vertical ||
      old.tokens != tokens ||
      old.direction != direction ||
      old.revealed != revealed;
}
