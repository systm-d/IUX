import 'package:flutter/material.dart';

import '../../accessibility/iux_accessibility.dart';
import '../../motion/iux_motion_policy.dart';
import '../../motion/iux_motion_role.dart';
import '../../semantics/iux_semantic_colors.dart';
import '../../themes/extensions/iux_geometry_theme.dart';
import '../../themes/extensions/iux_typography_theme.dart';

/// How many extra-large spacing steps tall a plot is at standard text size.
///
/// Four, which lands at 128 logical pixels on the default geometry. Below
/// roughly a hundred, a year of daily readings compresses into a band in which
/// a two-degree anomaly is a pixel and a half — the chart is then drawn and
/// still unreadable.
const int _plotSteps = 4;

/// What fraction of a plot a sparkline occupies.
///
/// A quarter. A sparkline sits inside a line of text and answers "up or down";
/// giving it a plot's height would make it a chart, and a chart with no axis is
/// a chart missing its axis rather than a micro-trend.
const double _sparklineFraction = 0.25;

/// Everything needed to paint a chart, and nothing about how.
///
/// One class for all three components, so a sparkline cannot end up thinner
/// than the line chart it summarises — which is the usual way a library gets a
/// family of charts that do not look related.
@immutable
final class IuxChartTokens {
  /// Creates a resolved appearance.
  const IuxChartTokens({
    required this.plotHeight,
    required this.sparklineHeight,
    required this.strokeWidth,
    required this.dashUnit,
    required this.gridline,
    required this.axisStyle,
    required this.legendStyle,
    required this.bandFill,
    required this.bandEdge,
    required this.primaryStroke,
    required this.secondaryStroke,
    required this.barTrack,
    required this.barHeight,
    required this.reveal,
  });

  /// The height of the drawing area of a line chart, in logical pixels.
  final double plotHeight;

  /// The height of a sparkline.
  final double sparklineHeight;

  /// How thick a line is drawn.
  final double strokeWidth;

  /// The length of one dash at the densest pattern.
  ///
  /// Scaled with the text, so a magnified screen gets a pattern that is still
  /// a pattern rather than a grey smear.
  final double dashUnit;

  /// The colour of a gridline.
  ///
  /// Deliberately the quietest border role available: a grid that competes
  /// with the data is a grid that has to be read past.
  final Color gridline;

  /// The style of an axis label.
  final TextStyle axisStyle;

  /// The style of a legend entry.
  final TextStyle legendStyle;

  /// The fill of a reference band.
  ///
  /// A surface role rather than a transparent overlay. Painting a translucent
  /// wash would put an unverifiable colour behind the data and take the
  /// contrast guarantee away from the theme, which is the one place it can be
  /// tested.
  final Color bandFill;

  /// The colour of the two edges of a reference band.
  ///
  /// Always drawn, under every profile. A fill difference is exactly what a
  /// high-contrast palette flattens, so the band states its extent with a line
  /// as well as with an area, and no branch on contrast is needed anywhere.
  final Color bandEdge;

  /// The colour of a series or bar at `IuxSeriesEmphasis.primary`.
  final Color primaryStroke;

  /// The colour of a series or bar at `IuxSeriesEmphasis.secondary`.
  final Color secondaryStroke;

  /// The colour of the unfilled remainder of a bar row.
  ///
  /// It is what makes a bar a proportion rather than a length: without it, a
  /// row of bars shows which is longest and refuses to say of what.
  final Color barTrack;

  /// The thickness of one bar.
  final double barHeight;

  /// Whether a chart may draw itself in, and how long that takes.
  ///
  /// Role [IuxMotionRole.emphasis]. A finished chart says exactly what a chart
  /// being drawn says, so the movement carries nothing and goes at the first
  /// request for less of it — not only when motion is switched off. Classing it
  /// as an entrance would have been more flattering and untrue.
  final IuxResolvedMotion reveal;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxChartTokens &&
          other.plotHeight == plotHeight &&
          other.sparklineHeight == sparklineHeight &&
          other.strokeWidth == strokeWidth &&
          other.dashUnit == dashUnit &&
          other.gridline == gridline &&
          other.axisStyle == axisStyle &&
          other.legendStyle == legendStyle &&
          other.bandFill == bandFill &&
          other.bandEdge == bandEdge &&
          other.primaryStroke == primaryStroke &&
          other.secondaryStroke == secondaryStroke &&
          other.barTrack == barTrack &&
          other.barHeight == barHeight &&
          other.reveal == reveal;

  @override
  int get hashCode => Object.hashAll(<Object>[
        plotHeight,
        sparklineHeight,
        strokeWidth,
        dashUnit,
        gridline,
        axisStyle,
        legendStyle,
        bandFill,
        bandEdge,
        primaryStroke,
        secondaryStroke,
        barTrack,
        barHeight,
        reveal,
      ]);
}

/// Resolves the complete appearance of a chart.
///
/// There is no `IuxChartTheme`, for the reason there is no `IuxProgressTheme`:
/// a chart has no decision an application could usefully vary that geometry,
/// typography and the semantic palette do not already carry. An extension would
/// have created a second place to set a stroke width and a second place for it
/// to disagree with the first.
abstract final class IuxChartResolver {
  /// Resolves the tokens in force at [context].
  static IuxChartTokens resolve(BuildContext context) {
    final IuxAccessibility accessibility = IuxAccessibility.of(context);
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme typography = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);

    final double plotHeight =
        accessibility.scaleText(geometry.spacingXl * _plotSteps);

    return IuxChartTokens(
      plotHeight: plotHeight,
      sparklineHeight: plotHeight * _sparklineFraction,
      // The strong border width rather than the ordinary one: a data line is
      // the subject of the picture, not the frame around it, and the strong
      // role is the one a high-contrast palette thickens.
      strokeWidth: accessibility.scaleText(geometry.strongBorderWidth),
      dashUnit: accessibility.scaleText(geometry.spacingXs),
      gridline: colors.border.subtle,
      axisStyle:
          typography.supporting.copyWith(color: colors.content.secondary),
      legendStyle: typography.label.copyWith(color: colors.content.primary),
      bandFill: colors.surface.subtle,
      bandEdge: colors.border.standard,
      primaryStroke: colors.action.primary.background,
      secondaryStroke: colors.content.secondary,
      barTrack: colors.surface.subtle,
      barHeight: accessibility.scaleText(geometry.spacingSm),
      reveal: IuxMotionPolicy.resolve(
        context,
        role: IuxMotionRole.emphasis,
        scale: IuxMotionScale.long,
      ),
    );
  }
}
