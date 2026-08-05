import 'package:flutter/material.dart';

import '../../accessibility/iux_semantics.dart';
import '../../layout/iux_spacing_primitives.dart';
import '../../themes/extensions/iux_geometry_theme.dart';
import 'iux_chart_model.dart';
import 'iux_chart_tokens.dart';

/// Quantities compared against each other, one per row.
///
/// ```dart
/// IuxBarChart(
///   bars: monthlyRainfall,
///   semanticsSummary: l10n.wettestMonthWas(march),
/// )
/// ```
///
/// **Use it** for a ranking, or for quantities that belong to categories
/// rather than to positions on a scale — months of rainfall, communes ordered
/// by temperature.
///
/// **Do not use it** for a run of readings over time where the line between
/// them means something; that is `IuxLineChart`.
///
/// ## Why the bars are horizontal, and why there is no option
///
/// Twelve vertical columns with their labels underneath is the classic way
/// this component fails: at 200% text the labels collide, and the usual fix is
/// to rotate or truncate them, which makes the chart unreadable for exactly the
/// person who enlarged the text.
///
/// One bar per row solves it structurally. The label wraps, the row grows, the
/// value stays beside its bar, and each row is one place a screen reader can
/// stand. A caller who wants vertical columns wants a different component, and
/// IUX does not have one.
///
/// ## Accessibility
///
/// Every bar carries `valueLabel`, for the reason `IuxProgressIndicator`
/// requires one: the length is the sighted reading and the words are the spoken
/// one. The chart is not interactive, so it has no focus, keyboard or
/// target-size behaviour, and it has no draw-in at all — bars that grew would
/// move the value labels beside them, and a number sliding while somebody reads
/// it is worse than a bar that simply appears.
class IuxBarChart extends StatelessWidget {
  /// Creates a bar chart.
  const IuxBarChart({
    super.key,
    required this.bars,
    required this.semanticsSummary,
  });

  /// The bars, drawn in the order given. IUX never sorts them.
  final List<IuxChartBar> bars;

  /// What the comparison says, already localised. Never composed by IUX.
  final String semanticsSummary;

  /// The value the longest bar has, which every other is drawn against.
  ///
  /// Zero when every bar is zero, which is a legitimate answer — no rain at
  /// all — and is handled by drawing every fill empty rather than by dividing
  /// by it.
  double get _longest {
    double longest = 0;
    for (final IuxChartBar bar in bars) {
      if (bar.value.isFinite && bar.value > longest) longest = bar.value;
    }
    return longest;
  }

  @override
  Widget build(BuildContext context) {
    assert(
      bars.isNotEmpty,
      'A bar chart with no bars draws nothing. A comparison with nothing to '
      'compare is an IuxEmptyState at the call site, which can say why.',
    );
    assert(
      semanticsSummary.length > 0,
      'semanticsSummary is what the comparison says to somebody who cannot '
      'see the lengths. Empty, the chart states its conclusion to nobody.',
    );

    final IuxChartTokens tokens = IuxChartResolver.resolve(context);
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final double longest = _longest;

    return IuxSemantics.group(
      label: semanticsSummary,
      child: IuxSemantics.contentContainer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final IuxChartBar bar in bars)
              Padding(
                padding: EdgeInsets.only(bottom: geometry.spacingXs),
                child: _BarRow(bar: bar, longest: longest, tokens: tokens),
              ),
          ],
        ),
      ),
    );
  }
}

/// One bar: its name, its value in words, and the length between them.
class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.bar,
    required this.longest,
    required this.tokens,
  });

  final IuxChartBar bar;
  final double longest;
  final IuxChartTokens tokens;

  @override
  Widget build(BuildContext context) {
    final Widget name = Text(bar.label, style: tokens.legendStyle);
    final Widget value = Text(bar.valueLabel, style: tokens.axisStyle);

    // Above roughly 130% text scaling a name and a value stop fitting on a
    // phone width. Stacking keeps both readable; shrinking produces the
    // clipped label users report as "the text size setting does nothing".
    final Widget heading = IuxReadableText.shouldStack(context)
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[name, value],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Expanded(child: name),
              const IuxGap.horizontal(IuxSpacingStep.xs),
              value,
            ],
          );

    // One stop per row, carrying the name and the value as one utterance. Left
    // as two nodes they are announced as unrelated fragments, and the
    // relationship between them — which is the whole content — is lost.
    return IuxSemantics.group(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          heading,
          const IuxGap.tight(),
          IuxSemantics.decorative(
            child: Transform.scale(
              // The painter fills from x = 0, which is the left edge in every
              // language. Mirroring here is what makes a bar start where the
              // reader does, and it is one line rather than a second set of
              // coordinates to keep in step with the first.
              scaleX: Directionality.of(context) == TextDirection.rtl ? -1 : 1,
              child: SizedBox(
                height: tokens.barHeight,
                child: CustomPaint(
                  painter: _BarPainter(
                    fraction: longest <= 0 ? 0 : bar.value / longest,
                    emphasis: bar.emphasis,
                    tokens: tokens,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The track, then the part of it this bar fills.
class _BarPainter extends CustomPainter {
  const _BarPainter({
    required this.fraction,
    required this.emphasis,
    required this.tokens,
  });

  final double fraction;
  final IuxSeriesEmphasis emphasis;
  final IuxChartTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    final Radius radius = Radius.circular(size.height / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, radius),
      Paint()..color = tokens.barTrack,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & Size(size.width * fraction.clamp(0.0, 1.0), size.height),
        radius,
      ),
      Paint()
        ..color = emphasis == IuxSeriesEmphasis.primary
            ? tokens.primaryStroke
            : tokens.secondaryStroke,
    );
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.fraction != fraction ||
      old.emphasis != emphasis ||
      old.tokens != tokens;
}
