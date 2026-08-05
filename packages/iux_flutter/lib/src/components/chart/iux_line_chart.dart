import 'package:flutter/material.dart';

import '../../accessibility/iux_semantics.dart';
import '../../layout/iux_spacing_primitives.dart';
import '../../themes/extensions/iux_geometry_theme.dart';
import 'iux_chart_geometry.dart';
import 'iux_chart_model.dart';
import 'iux_chart_tokens.dart';

/// How wide a legend swatch is, in dash units.
///
/// Three, so a dashed pattern shows at least two marks and a dotted one at
/// least three. A shorter swatch reduces every pattern to a single stub, and
/// the legend then identifies the series by colour alone — the one thing it
/// exists to avoid.
const double _swatchUnits = 3;

/// A series over time, optionally against an envelope it is read relative to.
///
/// ```dart
/// IuxLineChart(
///   series: <IuxChartSeries>[thisYear, lastYear],
///   band: normal,
///   horizontalAxis: months,
///   verticalAxis: degrees,
///   semanticsSummary: l10n.warmerThanUsualAllSummer,
///   stops: monthlyStops,
/// )
/// ```
///
/// **Use it** when a reader has to take values off the picture, compare two
/// runs of readings, or see where one sits against a reference range.
///
/// **Do not use it** for a shape with no numbers attached — that is
/// `IuxSparkline`, and it fits on a line of text. Do not use it for categories
/// either: months of the year are positions, but shops and departments are not,
/// and joining them with a line asserts a continuity that does not exist. That
/// is `IuxBarChart`.
///
/// ## What it refuses
///
/// **Two series may not share a stroke pattern**, which caps a chart at three.
/// The pattern is the channel that survives a monochrome screen, and two
/// series sharing one would be a single line drawn twice for a large share of
/// readers. The cap is a benefit: a five-line chart is unreadable before it is
/// inaccessible.
///
/// **The bounds are the caller's.** [IuxChartAxis] carries `min` and `max`, and
/// IUX never rounds them to pleasant numbers. Two charts on one screen with two
/// silently different scales are not comparable, and nothing on either would
/// say so.
///
/// ## Accessibility
///
/// [semanticsSummary] is required and is the picture's alternative. [stops] add
/// places a screen-reader user can stand, laid over the stretch they describe
/// so exploring by touch lands on the part being spoken about.
///
/// A stop is not a datum: a year profile paints 365 points and declares twelve
/// stops. Making them the same thing would force a choice between a chart too
/// coarse to read and an exploration 365 swipes long.
///
/// The chart is **not interactive** — no hover, no tooltip, no point selection.
/// It therefore has no focus, keyboard or target-size behaviour to describe. A
/// chart that needs those is a different component, and IUX does not have one.
class IuxLineChart extends StatelessWidget {
  /// Creates a line chart.
  const IuxLineChart({
    super.key,
    required this.series,
    required this.horizontalAxis,
    required this.verticalAxis,
    required this.semanticsSummary,
    this.band,
    this.stops = const <IuxChartStop>[],
  });

  /// The lines, drawn in order. At most three, each with its own pattern.
  final List<IuxChartSeries> series;

  /// The axis the readings are spread along.
  final IuxChartAxis horizontalAxis;

  /// The axis the readings are measured against.
  final IuxChartAxis verticalAxis;

  /// What the picture says, already localised. Never composed by IUX.
  final String semanticsSummary;

  /// An envelope drawn behind the series, or null.
  final IuxChartBand? band;

  /// Stretches a screen reader can stand on. Empty offers no exploration.
  final List<IuxChartStop> stops;

  /// Whether the series can be told apart without colour.
  ///
  /// In `build` rather than the constructor for the reason
  /// `IuxProgressIndicator` checks its label there: a const constructor may
  /// only assert on constant expressions, and the contents of a list are not
  /// one. Returns true so it can sit inside an `assert`.
  bool _debugSeriesAreDistinguishable() {
    final Set<IuxSeriesStroke> seen = <IuxSeriesStroke>{};
    for (final IuxChartSeries line in series) {
      assert(
        seen.add(line.stroke),
        'Two series share the stroke pattern ${line.stroke.name}. The pattern '
        'is the channel that survives a screen with no usable colour on it, '
        'so on such a screen these two are one line drawn twice — and neither '
        'the picture nor the legend says which. Give each series its own '
        'IuxSeriesStroke; there are three, which is the most a line chart '
        'should carry anyway.',
      );
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    assert(
      series.isNotEmpty,
      'A line chart with no series draws an empty grid. A chart with no data '
      'is an IuxEmptyState at the call site, which can say why there is '
      'nothing to draw.',
    );
    assert(
      semanticsSummary.length > 0,
      'semanticsSummary is what this picture says to everyone who cannot see '
      'it. Empty, the chart exists for sighted readers and for nobody else.',
    );
    assert(_debugSeriesAreDistinguishable());

    final IuxChartTokens tokens = IuxChartResolver.resolve(context);
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final TextDirection direction = Directionality.of(context);
    final IuxChartScale horizontal =
        IuxChartScale(min: horizontalAxis.min, max: horizontalAxis.max);
    final IuxChartScale vertical =
        IuxChartScale(min: verticalAxis.min, max: verticalAxis.max);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _Legend(series: series, band: band, tokens: tokens),
        const IuxGap.tight(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _ValueAxis(axis: verticalAxis, scale: vertical, tokens: tokens),
            const IuxGap.horizontal(IuxSpacingStep.xs),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SizedBox(
                    height: tokens.plotHeight,
                    child: _Plot(
                      series: series,
                      band: band,
                      ticks: verticalAxis.ticks,
                      stops: stops,
                      horizontal: horizontal,
                      vertical: vertical,
                      tokens: tokens,
                      direction: direction,
                      summary: semanticsSummary,
                    ),
                  ),
                  SizedBox(height: geometry.spacingXxs),
                  _PositionAxis(
                    axis: horizontalAxis,
                    scale: horizontal,
                    tokens: tokens,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The drawing area, and the places a screen reader can stand in it.
class _Plot extends StatelessWidget {
  const _Plot({
    required this.series,
    required this.band,
    required this.ticks,
    required this.stops,
    required this.horizontal,
    required this.vertical,
    required this.tokens,
    required this.direction,
    required this.summary,
  });

  final List<IuxChartSeries> series;
  final IuxChartBand? band;
  final List<IuxAxisTick> ticks;
  final List<IuxChartStop> stops;
  final IuxChartScale horizontal;
  final IuxChartScale vertical;
  final IuxChartTokens tokens;
  final TextDirection direction;
  final String summary;

  @override
  Widget build(BuildContext context) => IuxSemantics.contentContainer(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) => Stack(
            children: <Widget>[
              Positioned.fill(
                child: IuxSemantics.image(
                  label: summary,
                  child: tokens.reveal.isAnimated
                      ? TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: tokens.reveal.duration,
                          curve: tokens.reveal.curve,
                          builder: (
                            BuildContext context,
                            double revealed,
                            Widget? child,
                          ) =>
                              CustomPaint(painter: _painter(revealed)),
                        )
                      : CustomPaint(painter: _painter(1)),
                ),
              ),
              for (final IuxChartStop stop in stops)
                Positioned.directional(
                  textDirection: direction,
                  top: 0,
                  bottom: 0,
                  start:
                      horizontal.fractionOf(stop.start) * constraints.maxWidth,
                  width: (horizontal.fractionOf(stop.end) -
                          horizontal.fractionOf(stop.start)) *
                      constraints.maxWidth,
                  child: IuxSemantics.group(
                    label: stop.label,
                    child: const SizedBox.expand(),
                  ),
                ),
            ],
          ),
        ),
      );

  _PlotPainter _painter(double revealed) => _PlotPainter(
        series: series,
        band: band,
        ticks: ticks,
        horizontal: horizontal,
        vertical: vertical,
        tokens: tokens,
        direction: direction,
        revealed: revealed,
      );
}

/// Grid, then band, then series — in that order, so nothing hides the data.
class _PlotPainter extends CustomPainter {
  const _PlotPainter({
    required this.series,
    required this.band,
    required this.ticks,
    required this.horizontal,
    required this.vertical,
    required this.tokens,
    required this.direction,
    required this.revealed,
  });

  final List<IuxChartSeries> series;
  final IuxChartBand? band;
  final List<IuxAxisTick> ticks;
  final IuxChartScale horizontal;
  final IuxChartScale vertical;
  final IuxChartTokens tokens;
  final TextDirection direction;
  final double revealed;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = tokens.strokeWidth / 2
      ..color = tokens.gridline;
    for (final IuxAxisTick tick in ticks) {
      final double dy =
          size.height - vertical.fractionOf(tick.value) * size.height;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), grid);
    }

    final IuxChartBand? envelope = band;
    if (envelope != null) {
      final Paint fill = Paint()..color = tokens.bandFill;
      final Paint edge = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = tokens.strokeWidth / 2
        ..color = tokens.bandEdge;
      for (final Path shape in bandPaths(
        envelope.lower,
        envelope.upper,
        horizontal: horizontal,
        vertical: vertical,
        size: size,
        direction: direction,
      )) {
        canvas.drawPath(shape, fill);
        canvas.drawPath(shape, edge);
      }
    }

    for (final IuxChartSeries line in series) {
      final Paint stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = tokens.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = line.emphasis == IuxSeriesEmphasis.primary
            ? tokens.primaryStroke
            : tokens.secondaryStroke;
      for (final Path run in seriesPaths(
        line.points,
        horizontal: horizontal,
        vertical: vertical,
        size: size,
        direction: direction,
        dotRadius: tokens.strokeWidth,
      )) {
        // Revealed first, then dashed. Dashing first and revealing after would
        // shorten the pattern as the line arrives, so the marks would change
        // length while it drew.
        canvas.drawPath(
          strokeAsPattern(
              pathUpTo(run, revealed), line.stroke, tokens.dashUnit),
          stroke,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PlotPainter old) =>
      !identical(old.series, series) ||
      !identical(old.band, band) ||
      !identical(old.ticks, ticks) ||
      old.horizontal != horizontal ||
      old.vertical != vertical ||
      old.tokens != tokens ||
      old.direction != direction ||
      old.revealed != revealed;
}

/// The value axis: labels aligned with the gridlines they name.
class _ValueAxis extends StatelessWidget {
  const _ValueAxis({
    required this.axis,
    required this.scale,
    required this.tokens,
  });

  final IuxChartAxis axis;
  final IuxChartScale scale;
  final IuxChartTokens tokens;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: tokens.plotHeight,
        child: Stack(
          children: <Widget>[
            for (final IuxAxisTick tick in axis.ticks)
              Align(
                // -1 is the top of the strip and 1 the bottom, while a value
                // grows upwards: the fraction is inverted here for the same
                // reason the painter subtracts from the height.
                alignment: AlignmentDirectional(
                  -1,
                  1 - 2 * scale.fractionOf(tick.value),
                ),
                child: Text(tick.label, style: tokens.axisStyle),
              ),
          ],
        ),
      );
}

/// The position axis, laid out under the plot.
class _PositionAxis extends StatelessWidget {
  const _PositionAxis({
    required this.axis,
    required this.scale,
    required this.tokens,
  });

  final IuxChartAxis axis;
  final IuxChartScale scale;
  final IuxChartTokens tokens;

  @override
  Widget build(BuildContext context) => Stack(
        children: <Widget>[
          for (final IuxAxisTick tick in axis.ticks)
            Align(
              // Directional, so the first position sits at the reading start
              // and the labels agree with the curve above them.
              alignment: AlignmentDirectional(
                2 * scale.fractionOf(tick.value) - 1,
                0,
              ),
              child: Text(tick.label, style: tokens.axisStyle),
            ),
        ],
      );
}

/// Which line is which, shown with the pattern rather than only the colour.
class _Legend extends StatelessWidget {
  const _Legend({
    required this.series,
    required this.band,
    required this.tokens,
  });

  final List<IuxChartSeries> series;
  final IuxChartBand? band;
  final IuxChartTokens tokens;

  @override
  Widget build(BuildContext context) {
    final IuxChartBand? envelope = band;
    return Wrap(
      spacing: tokens.dashUnit,
      runSpacing: tokens.dashUnit / 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        for (final IuxChartSeries line in series)
          _LegendEntry(
            text: line.label,
            tokens: tokens,
            swatch: CustomPaint(
              size:
                  Size(tokens.dashUnit * _swatchUnits, tokens.strokeWidth * 2),
              painter: _SwatchPainter(
                stroke: line.stroke,
                tokens: tokens,
                emphasis: line.emphasis,
              ),
            ),
          ),
        if (envelope != null)
          _LegendEntry(
            text: envelope.label,
            tokens: tokens,
            swatch: Container(
              width: tokens.dashUnit * _swatchUnits,
              height: tokens.strokeWidth * 2,
              decoration: BoxDecoration(
                color: tokens.bandFill,
                border: Border.all(
                  color: tokens.bandEdge,
                  width: tokens.strokeWidth / 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A swatch and the name beside it, kept together when the text wraps.
class _LegendEntry extends StatelessWidget {
  const _LegendEntry({
    required this.text,
    required this.swatch,
    required this.tokens,
  });

  final String text;
  final Widget swatch;
  final IuxChartTokens tokens;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IuxSemantics.decorative(child: swatch),
          const IuxGap.horizontal(IuxSpacingStep.xxs),
          Text(text, style: tokens.legendStyle),
        ],
      );
}

/// One short line, stroked the way its series is.
class _SwatchPainter extends CustomPainter {
  const _SwatchPainter({
    required this.stroke,
    required this.tokens,
    required this.emphasis,
  });

  final IuxSeriesStroke stroke;
  final IuxChartTokens tokens;
  final IuxSeriesEmphasis emphasis;

  @override
  void paint(Canvas canvas, Size size) {
    final Path line = Path()
      ..moveTo(0, size.height / 2)
      ..lineTo(size.width, size.height / 2);
    canvas.drawPath(
      strokeAsPattern(line, stroke, tokens.dashUnit),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = tokens.strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = emphasis == IuxSeriesEmphasis.primary
            ? tokens.primaryStroke
            : tokens.secondaryStroke,
    );
  }

  @override
  bool shouldRepaint(_SwatchPainter old) =>
      old.stroke != stroke || old.tokens != tokens || old.emphasis != emphasis;
}
