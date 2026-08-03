import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../themes/extensions/iux_geometry_theme.dart';

/// The smallest gap that may separate two adjacent interactive elements.
///
/// Target size alone does not prevent mis-taps: two 48-pixel targets touching
/// each other still produce them, because a finger that lands near the seam
/// has no margin for error. WCAG 2.2 SC 2.5.8 recognises this by allowing
/// smaller targets when spacing compensates; IUX keeps both.
///
/// This is the concern IUX-005 deferred when it delivered the target floor.
const double kIuxMinimumTargetSpacing = 8;

/// Empty space taken from the spacing scale, adapted to density.
///
/// Justified over a bare `SizedBox` because it reads the resolved scale
/// instead of a literal: a gap written as `SizedBox(height: 16)` stays 16 when
/// the user asks for a comfortable density, and the layout stops being
/// consistent with itself.
///
/// A `SizedBox` remains fine for a one-off measurement that is not part of the
/// rhythm.
class IuxGap extends StatelessWidget {
  /// A gap of the given step, applied vertically.
  const IuxGap(this.step, {super.key}) : _axis = Axis.vertical;

  /// A horizontal gap of the given step.
  const IuxGap.horizontal(this.step, {super.key}) : _axis = Axis.horizontal;

  /// The gap separating tightly related elements.
  const IuxGap.tight({super.key})
      : step = IuxSpacingStep.xs,
        _axis = Axis.vertical;

  /// The default gap between elements.
  const IuxGap.standard({super.key})
      : step = IuxSpacingStep.md,
        _axis = Axis.vertical;

  /// The gap separating distinct groups.
  const IuxGap.between({super.key})
      : step = IuxSpacingStep.lg,
        _axis = Axis.vertical;

  /// The step to take from the spacing scale.
  final IuxSpacingStep step;

  final Axis _axis;

  @override
  Widget build(BuildContext context) {
    final double size = IuxGeometryTheme.of(context).spacing(step);
    return SizedBox(
      width: _axis == Axis.horizontal ? size : null,
      height: _axis == Axis.vertical ? size : null,
    );
  }
}

/// Guarantees a minimum separation between adjacent interactive elements.
///
/// Wrap a row or column of controls in this rather than spacing them by hand:
/// the floor is then applied in one place and cannot drift.
///
/// ```dart
/// IuxTargetSpacing(
///   axis: Axis.horizontal,
///   children: <Widget>[cancel, confirm],
/// )
/// ```
class IuxTargetSpacing extends StatelessWidget {
  /// Separates [children] by at least [kIuxMinimumTargetSpacing].
  const IuxTargetSpacing({
    super.key,
    required this.children,
    this.axis = Axis.vertical,
    this.spacing,
  });

  /// The interactive elements.
  final List<Widget> children;

  /// The direction they are laid out in.
  final Axis axis;

  /// A larger separation. Values below the floor are raised to it.
  final double? spacing;

  @override
  Widget build(BuildContext context) {
    final double resolved = math.max(
      spacing ?? IuxGeometryTheme.of(context).spacingXs,
      kIuxMinimumTargetSpacing,
    );
    // Wrap rather than Row: at a large text scale a row of controls stops
    // fitting, and overflowing is worse than moving to a second line.
    return Wrap(
      direction: axis,
      spacing: resolved,
      runSpacing: resolved,
      children: children,
    );
  }
}

/// Padding taken from the spacing scale, adapted to density.
abstract final class IuxInsets {
  /// The padding around the content of a page.
  static EdgeInsets page(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    return EdgeInsets.symmetric(
      horizontal: geometry.spacingMd,
      vertical: geometry.spacingMd,
    );
  }

  /// The padding inside a grouped section.
  static EdgeInsets section(BuildContext context) =>
      EdgeInsets.all(IuxGeometryTheme.of(context).spacingMd);

  /// The padding inside a surface.
  static EdgeInsets surface(BuildContext context) =>
      EdgeInsets.all(IuxGeometryTheme.of(context).spacingMd);

  /// A compact padding, for dense containers such as a chip.
  static EdgeInsets compact(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    return EdgeInsets.symmetric(
      horizontal: geometry.spacingSm,
      vertical: geometry.spacingXs,
    );
  }
}
