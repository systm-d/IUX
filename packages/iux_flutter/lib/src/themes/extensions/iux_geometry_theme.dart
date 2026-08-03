import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../foundations/iux_foundations.dart';
import '../iux_theme_configuration.dart';

/// Resolved spacing, sizing, shape, elevation and focus geometry.
///
/// Spacing, shape and elevation live in one extension rather than three
/// because they are read together and change together: density and target size
/// move all of them at once. Splitting them would produce extensions that are
/// never independently useful, while merging them with colour would force a
/// rebuild of every measurement whenever contrast changed.
@immutable
final class IuxGeometryTheme extends ThemeExtension<IuxGeometryTheme> {
  /// Creates a resolved geometry.
  const IuxGeometryTheme({
    required this.spacingXxs,
    required this.spacingXs,
    required this.spacingSm,
    required this.spacingMd,
    required this.spacingLg,
    required this.spacingXl,
    required this.minimumTouchTarget,
    required this.focus,
    required this.borderWidth,
    required this.strongBorderWidth,
    required this.radiusSubtle,
    required this.radiusMedium,
    required this.radiusProminent,
    required this.elevationRaised,
    required this.elevationModal,
  });

  /// Resolves geometry for a configuration.
  factory IuxGeometryTheme.resolve(IuxThemeConfiguration configuration) {
    final IuxDensity density = configuration.density;
    double space(double value) => IuxDensityResolver.spacing(value, density);

    // High contrast thickens outlines rather than recolouring them, so a
    // border stays a border and does not start competing with focus.
    final bool high = configuration.contrast == IuxContrast.high;

    return IuxGeometryTheme(
      spacingXxs: space(IuxSpacing.xxs),
      spacingXs: space(IuxSpacing.xs),
      spacingSm: space(IuxSpacing.sm),
      spacingMd: space(IuxSpacing.md),
      spacingLg: space(IuxSpacing.lg),
      spacingXl: space(IuxSpacing.xl),
      minimumTouchTarget: configuration.profile.minimumTouchTarget,
      focus: IuxFocusStyle(width: high ? 3 : 2, gap: high ? 3 : 2),
      borderWidth: high ? 2 : 1,
      strongBorderWidth: high ? 3 : 2,
      radiusSubtle: 4,
      radiusMedium: 8,
      radiusProminent: 16,
      // Reduced visual stimulation flattens the interface: hierarchy then
      // rests entirely on surface contrast and borders, which are measurable,
      // rather than on shadows, which are not.
      elevationRaised:
          configuration.visualStimulation == IuxVisualStimulation.reduced
              ? 0
              : 1,
      elevationModal:
          configuration.visualStimulation == IuxVisualStimulation.reduced
              ? 0
              : 6,
    );
  }

  /// Smallest spacing step.
  final double spacingXxs;

  /// Spacing between tightly related elements.
  final double spacingXs;

  /// Spacing inside a compact grouping.
  final double spacingSm;

  /// Default spacing between elements and screen edges.
  final double spacingMd;

  /// Spacing between distinct groups.
  final double spacingLg;

  /// Spacing between major sections.
  final double spacingXl;

  /// The smallest permitted interactive dimension.
  ///
  /// Density never reduces this. A compact layout tightens the space between
  /// controls; it does not shrink what a finger must hit.
  final double minimumTouchTarget;

  /// Geometry of the visible focus ring.
  final IuxFocusStyle focus;

  /// Width of a standard outline.
  final double borderWidth;

  /// Width of an outline that must survive adverse conditions.
  final double strongBorderWidth;

  /// Corner radius for small elements.
  final double radiusSubtle;

  /// Corner radius for cards and controls.
  final double radiusMedium;

  /// Corner radius for sheets and prominent containers.
  final double radiusProminent;

  /// Elevation of a raised surface, in logical pixels.
  final double elevationRaised;

  /// Elevation of a modal surface, in logical pixels.
  final double elevationModal;

  /// Returns the spacing for a density-aware step.
  double spacing(IuxSpacingStep step) => switch (step) {
        IuxSpacingStep.xxs => spacingXxs,
        IuxSpacingStep.xs => spacingXs,
        IuxSpacingStep.sm => spacingSm,
        IuxSpacingStep.md => spacingMd,
        IuxSpacingStep.lg => spacingLg,
        IuxSpacingStep.xl => spacingXl,
      };

  /// Returns the corner radius for a semantic shape level.
  double radius(IuxShape shape) => switch (shape) {
        IuxShape.none => 0,
        IuxShape.subtle => radiusSubtle,
        IuxShape.medium => radiusMedium,
        IuxShape.prominent => radiusProminent,
        // Resolved by the component against its own height; the theme cannot
        // know it.
        IuxShape.full => double.infinity,
      };

  /// Resolves the geometry installed on the ambient theme.
  static IuxGeometryTheme of(BuildContext context) =>
      Theme.of(context).extension<IuxGeometryTheme>() ??
      (throw FlutterError(
        'No IuxGeometryTheme found. Install an IUX theme on your MaterialApp, '
        'for example theme: IuxTheme.light().',
      ));

  @override
  IuxGeometryTheme copyWith({
    double? spacingXxs,
    double? spacingXs,
    double? spacingSm,
    double? spacingMd,
    double? spacingLg,
    double? spacingXl,
    double? minimumTouchTarget,
    IuxFocusStyle? focus,
    double? borderWidth,
    double? strongBorderWidth,
    double? radiusSubtle,
    double? radiusMedium,
    double? radiusProminent,
    double? elevationRaised,
    double? elevationModal,
  }) =>
      IuxGeometryTheme(
        spacingXxs: spacingXxs ?? this.spacingXxs,
        spacingXs: spacingXs ?? this.spacingXs,
        spacingSm: spacingSm ?? this.spacingSm,
        spacingMd: spacingMd ?? this.spacingMd,
        spacingLg: spacingLg ?? this.spacingLg,
        spacingXl: spacingXl ?? this.spacingXl,
        minimumTouchTarget: minimumTouchTarget ?? this.minimumTouchTarget,
        focus: focus ?? this.focus,
        borderWidth: borderWidth ?? this.borderWidth,
        strongBorderWidth: strongBorderWidth ?? this.strongBorderWidth,
        radiusSubtle: radiusSubtle ?? this.radiusSubtle,
        radiusMedium: radiusMedium ?? this.radiusMedium,
        radiusProminent: radiusProminent ?? this.radiusProminent,
        elevationRaised: elevationRaised ?? this.elevationRaised,
        elevationModal: elevationModal ?? this.elevationModal,
      );

  @override
  IuxGeometryTheme lerp(
    covariant ThemeExtension<IuxGeometryTheme>? other,
    double t,
  ) {
    if (other is! IuxGeometryTheme) return this;
    return IuxGeometryTheme(
      spacingXxs: lerpDouble(spacingXxs, other.spacingXxs, t),
      spacingXs: lerpDouble(spacingXs, other.spacingXs, t),
      spacingSm: lerpDouble(spacingSm, other.spacingSm, t),
      spacingMd: lerpDouble(spacingMd, other.spacingMd, t),
      spacingLg: lerpDouble(spacingLg, other.spacingLg, t),
      spacingXl: lerpDouble(spacingXl, other.spacingXl, t),
      // Held at the larger endpoint mid-transition rather than ramped: a
      // target that is briefly smaller than both themes intended is a target
      // the user can miss for the duration of the animation. The bounds stay
      // exact so the resolved theme is still reached.
      minimumTouchTarget: switch (t) {
        <= 0 => minimumTouchTarget,
        >= 1 => other.minimumTouchTarget,
        _ => math.max(minimumTouchTarget, other.minimumTouchTarget),
      },
      focus: IuxFocusStyle.lerp(focus, other.focus, t),
      borderWidth: lerpDouble(borderWidth, other.borderWidth, t),
      strongBorderWidth:
          lerpDouble(strongBorderWidth, other.strongBorderWidth, t),
      radiusSubtle: lerpDouble(radiusSubtle, other.radiusSubtle, t),
      radiusMedium: lerpDouble(radiusMedium, other.radiusMedium, t),
      radiusProminent: lerpDouble(radiusProminent, other.radiusProminent, t),
      elevationRaised: lerpDouble(elevationRaised, other.elevationRaised, t),
      elevationModal: lerpDouble(elevationModal, other.elevationModal, t),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxGeometryTheme &&
          other.spacingXxs == spacingXxs &&
          other.spacingXs == spacingXs &&
          other.spacingSm == spacingSm &&
          other.spacingMd == spacingMd &&
          other.spacingLg == spacingLg &&
          other.spacingXl == spacingXl &&
          other.minimumTouchTarget == minimumTouchTarget &&
          other.focus == focus &&
          other.borderWidth == borderWidth &&
          other.strongBorderWidth == strongBorderWidth &&
          other.radiusSubtle == radiusSubtle &&
          other.radiusMedium == radiusMedium &&
          other.radiusProminent == radiusProminent &&
          other.elevationRaised == elevationRaised &&
          other.elevationModal == elevationModal;

  @override
  int get hashCode => Object.hashAll(<Object>[
        spacingXxs,
        spacingXs,
        spacingSm,
        spacingMd,
        spacingLg,
        spacingXl,
        minimumTouchTarget,
        focus,
        borderWidth,
        strongBorderWidth,
        radiusSubtle,
        radiusMedium,
        radiusProminent,
        elevationRaised,
        elevationModal,
      ]);
}

/// The density-aware steps of the IUX spacing scale.
enum IuxSpacingStep {
  /// Smallest step.
  xxs,

  /// Tightly related elements.
  xs,

  /// Compact grouping.
  sm,

  /// Default spacing.
  md,

  /// Distinct groups.
  lg,

  /// Major sections.
  xl,
}
