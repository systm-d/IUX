import 'package:flutter/material.dart';

import '../../accessibility/iux_semantics.dart';
import '../../foundations/iux_foundations.dart';
import '../../layout/iux_spacing_primitives.dart';
import '../../themes/extensions/iux_geometry_theme.dart';
import 'iux_chart_tokens.dart';
import 'iux_timeline_model.dart';

/// Stretches of time laid on a shared axis, one row per subject.
///
/// **The chart family answers "how much"; this answers "when, and for how
/// long".** A fortnight of days, each running midnight to midnight, coloured by
/// what the stretch is — reported as `systm-d/IUX#51`, where the point was made
/// better than it could be made here: a list saying "daily rest short by one
/// hour" is arithmetic, whereas a row whose rest band is visibly thinner than
/// the one above it is the same fact understood without doing any.
///
/// ## The drawing is not the hard part, and this component knows it
///
/// The reporter's own summary: the drawing is *"a `Row` of `Expanded` flex
/// weights, about forty lines"*. Two things are hard, and both are in the
/// contract here rather than in advice:
///
/// 1. **The bands must be disjoint before they can be drawn**, and the sets an
///    application holds are not — somebody can be on call during their working
///    hours. `resolveSpans` sweeps the axis boundary by boundary with a
///    precedence order. Getting that wrong produces a chart that renders, looks
///    plausible and states something untrue.
/// 2. **Colour cannot carry the meaning** (SC 1.4.1). Every row is announced
///    through [describeRow], and every kind is spelled out in the legend beside
///    its own swatch.
///
/// ## [describeRow] receives the resolved bands, not the caller's input
///
/// This is the guarantee worth having. The callback is handed exactly what was
/// drawn, so the sentence a screen reader hears cannot describe a different
/// arrangement from the one on screen. The framework does the arithmetic, which
/// it can verify; the caller writes the sentence, which it cannot — composing
/// "Monday: work from 09:00 to 17:00" here would be the framework writing in a
/// language it does not know it is using.
///
/// ## When not to use it
///
/// - **For a magnitude.** How much, not when — `IuxBarChart`.
/// - **For one row.** A single span is a sentence, and a sentence is cheaper to
///   read than a chart.
/// - **For an axis that is not shared.** Rows drawn against different ranges
///   cannot be compared down the column, which is the only reason to stack
///   them.
class IuxTimelineChart extends StatelessWidget {
  /// Creates a timeline over `axisStart`..`axisEnd`.
  IuxTimelineChart({
    super.key,
    required this.title,
    required this.precedence,
    required this.rows,
    required this.axisStart,
    required this.axisEnd,
    required this.formatPosition,
    required this.describeRow,
  })  : assert(title.length > 0, 'A chart must say what it is about.'),
        assert(
          axisStart < axisEnd,
          'The axis ends after it starts, or the rows have nowhere to be.',
        ),
        assert(rows.length > 0, 'A timeline with no rows is IuxEmptyState.'),
        assert(
          precedence.length > 0,
          'Without a precedence order there is no answer to two stretches '
          'claiming the same minute, and the chart would settle it by '
          'accident.',
        ),
        assert(
          precedence.length == precedence.toSet().length,
          'A kind appears twice in the precedence order, so which of its two '
          'positions wins is undefined.',
        );

  /// What the chart is about, already localised.
  final String title;

  /// The kinds, in order, first winning where two stretches overlap.
  ///
  /// Order rather than a number on each kind: a number invites two kinds to
  /// share one, and there is no honest answer to a tie. The same order is the
  /// legend's.
  final List<IuxSpanKind> precedence;

  /// The rows, in the order they are read.
  final List<IuxTimelineRow> rows;

  /// Where the shared axis begins.
  final double axisStart;

  /// Where the shared axis ends.
  final double axisEnd;

  /// Renders an axis position as text, already localised — "09:00".
  final String Function(double position) formatPosition;

  /// Renders one row as the sentence a screen reader will hear.
  ///
  /// Handed the **resolved** bands, so the description and the drawing cannot
  /// disagree. Already localised; the framework composes none of it.
  final String Function(IuxTimelineRow row, List<IuxResolvedSpan> bands)
      describeRow;

  @override
  Widget build(BuildContext context) {
    final IuxChartTokens tokens = IuxChartResolver.resolve(context);

    return IuxSemantics.contentContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IuxSemantics.header(
              label: title, child: Text(title, style: tokens.axisStyle)),
          const IuxGap.tight(),
          _IuxTimelineLegend(precedence: precedence, tokens: tokens),
          const IuxGap.standard(),
          for (final IuxTimelineRow row in rows) ...<Widget>[
            _IuxTimelineRowView(
              row: row,
              bands: resolveSpans(spans: row.spans, precedence: precedence),
              tokens: tokens,
              axisStart: axisStart,
              axisEnd: axisEnd,
              describeRow: describeRow,
            ),
            const IuxGap.tight(),
          ],
          // The ends of the axis, so a reader knows what the width means. Only
          // the ends: intermediate ticks on a row this short collide at 200%
          // text, and the row's own announcement carries the detail.
          IuxSemantics.decorative(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(formatPosition(axisStart), style: tokens.axisStyle),
                Text(formatPosition(axisEnd), style: tokens.axisStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Every kind, spelled out beside its own swatch.
///
/// A legend that shows colours and expects the reader to match them is the
/// failure SC 1.4.1 names. The swatch is excluded from the tree because the
/// word beside it already says what it is.
class _IuxTimelineLegend extends StatelessWidget {
  const _IuxTimelineLegend({required this.precedence, required this.tokens});

  final List<IuxSpanKind> precedence;
  final IuxChartTokens tokens;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: IuxSpacing.md,
        runSpacing: IuxSpacing.xs,
        children: <Widget>[
          for (final IuxSpanKind kind in precedence)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IuxSemantics.decorative(
                  child: SizedBox(
                    width: IuxSpacing.md,
                    height: IuxSpacing.sm,
                    child: CustomPaint(
                      painter: _IuxSpanPainter(
                        texture: kind.texture,
                        tokens: tokens,
                      ),
                    ),
                  ),
                ),
                const IuxGap.horizontal(IuxSpacingStep.xxs),
                Text(kind.label, style: tokens.legendStyle),
              ],
            ),
        ],
      );
}

/// One row: its name, and its settled bands drawn to scale.
class _IuxTimelineRowView extends StatelessWidget {
  const _IuxTimelineRowView({
    required this.row,
    required this.bands,
    required this.tokens,
    required this.axisStart,
    required this.axisEnd,
    required this.describeRow,
  });

  final IuxTimelineRow row;
  final List<IuxResolvedSpan> bands;
  final IuxChartTokens tokens;
  final double axisStart;
  final double axisEnd;
  final String Function(IuxTimelineRow, List<IuxResolvedSpan>) describeRow;

  @override
  Widget build(BuildContext context) {
    final String description = describeRow(row, bands);
    assert(
      description.length > 0,
      'A row described by nothing is a row a screen reader meets as silence, '
      'and colour is then the only thing carrying its meaning.',
    );

    // One node for the whole row. The bands underneath are excluded: the
    // description already says what they are, and forty separate nodes reading
    // "band" would be a worse way to hear the same thing.
    return IuxSemantics.group(
      label: description,
      child: IuxSemantics.decorative(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: IuxSpacing.xxl,
              child: Text(row.label, style: tokens.axisStyle),
            ),
            const IuxGap.horizontal(IuxSpacingStep.xs),
            Expanded(
              child: SizedBox(
                height: tokens.barHeight,
                child: CustomPaint(
                  painter: _IuxTimelineRowPainter(
                    bands: bands,
                    tokens: tokens,
                    axisStart: axisStart,
                    axisEnd: axisEnd,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints the settled bands of one row across the shared axis.
class _IuxTimelineRowPainter extends CustomPainter {
  const _IuxTimelineRowPainter({
    required this.bands,
    required this.tokens,
    required this.axisStart,
    required this.axisEnd,
  });

  final List<IuxResolvedSpan> bands;
  final IuxChartTokens tokens;
  final double axisStart;
  final double axisEnd;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint track = Paint()..color = tokens.barTrack;
    canvas.drawRect(Offset.zero & size, track);

    final double span = axisEnd - axisStart;
    for (final IuxResolvedSpan band in bands) {
      final double left = ((band.start - axisStart) / span) * size.width;
      final double right = ((band.end - axisStart) / span) * size.width;
      if (right <= 0 || left >= size.width) continue;
      final Rect rect = Rect.fromLTRB(
        left.clamp(0.0, size.width),
        0,
        right.clamp(0.0, size.width),
        size.height,
      );
      paintSpan(canvas, rect, band.kind.texture, tokens);
    }
  }

  @override
  bool shouldRepaint(_IuxTimelineRowPainter old) =>
      old.bands != bands ||
      old.axisStart != axisStart ||
      old.axisEnd != axisEnd ||
      old.tokens != tokens;
}

/// Paints one swatch, for the legend.
class _IuxSpanPainter extends CustomPainter {
  const _IuxSpanPainter({required this.texture, required this.tokens});

  final IuxSpanTexture texture;
  final IuxChartTokens tokens;

  @override
  void paint(Canvas canvas, Size size) =>
      paintSpan(canvas, Offset.zero & size, texture, tokens);

  @override
  bool shouldRepaint(_IuxSpanPainter old) =>
      old.texture != texture || old.tokens != tokens;
}

/// Fills [rect] in the manner [texture] names.
///
/// One function for the legend swatch and the row band, so a kind cannot be
/// drawn one way in the key and another way on the chart — which would make the
/// key worse than useless.
@visibleForTesting
void paintSpan(
  Canvas canvas,
  Rect rect,
  IuxSpanTexture texture,
  IuxChartTokens tokens,
) {
  final Paint fill = Paint()..color = tokens.primaryStroke;
  final Paint quiet = Paint()..color = tokens.secondaryStroke;
  final Paint edge = Paint()
    ..color = tokens.primaryStroke
    ..style = PaintingStyle.stroke
    ..strokeWidth = tokens.strokeWidth;

  switch (texture) {
    case IuxSpanTexture.solid:
      canvas.drawRect(rect, fill);
    case IuxSpanTexture.hatched:
      canvas.save();
      canvas.clipRect(rect);
      canvas.drawRect(rect, Paint()..color = tokens.barTrack);
      final Paint rule = Paint()
        ..color = tokens.primaryStroke
        ..strokeWidth = tokens.strokeWidth;
      for (double x = rect.left - rect.height;
          x < rect.right + rect.height;
          x += tokens.dashUnit * 2) {
        canvas.drawLine(
          Offset(x, rect.bottom),
          Offset(x + rect.height, rect.top),
          rule,
        );
      }
      canvas.restore();
    case IuxSpanTexture.dotted:
      canvas.save();
      canvas.clipRect(rect);
      canvas.drawRect(rect, Paint()..color = tokens.barTrack);
      final double step = tokens.dashUnit * 2;
      for (double x = rect.left + step / 2; x < rect.right; x += step) {
        canvas.drawCircle(
          Offset(x, rect.center.dy),
          tokens.strokeWidth,
          quiet,
        );
      }
      canvas.restore();
    case IuxSpanTexture.open:
      canvas.drawRect(rect.deflate(tokens.strokeWidth / 2), edge);
  }
}
