import 'package:flutter/material.dart';

import '../semantics/iux_semantic_colors.dart';
import '../themes/extensions/iux_geometry_theme.dart';

/// Which surface level a container sits at.
enum IuxSurfaceRole {
  /// The background of a screen.
  base,

  /// A recessed grouping surface.
  subtle,

  /// A surface above the page, such as a card.
  raised,

  /// A surface above the page content, such as a sheet.
  overlay,

  /// The background of a selected element.
  selected,

  /// A surface whose content uses the inverse content role.
  inverse,
}

/// A themed container that expresses a surface level.
///
/// It resolves colour, border, shape and elevation from the theme. A caller
/// names a level; it never names a colour, which is what keeps the same widget
/// correct in light, dark and high contrast.
///
/// Deliberately non-interactive and carrying no semantics of its own: a
/// surface is a background, not a card component and not a button. Those are
/// IUX-019 and IUX-008.
class IuxSurface extends StatelessWidget {
  /// Creates a themed surface.
  const IuxSurface({
    super.key,
    required this.child,
    this.role = IuxSurfaceRole.base,
    this.padding,
    this.bordered = false,
    this.shape = IuxSurfaceShape.medium,
    this.elevated = false,
  });

  /// The content.
  final Widget child;

  /// The level this surface sits at.
  final IuxSurfaceRole role;

  /// Inner padding. Defaults to none, so a surface can wrap a list without
  /// inserting space its caller did not ask for.
  final EdgeInsetsGeometry? padding;

  /// Whether to draw an outline.
  ///
  /// Worth enabling whenever the surface must be *identifiable* rather than
  /// merely grouped: surface contrast alone is intentionally gentle.
  final bool bordered;

  /// The corner treatment.
  final IuxSurfaceShape shape;

  /// Whether to cast a shadow.
  ///
  /// Opt-in, and never the only signal: the shadow is suppressed entirely
  /// under a reduced visual stimulation preference, where the theme resolves
  /// elevation to zero. Hierarchy has to survive that, so it rests on colour
  /// and border.
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final IuxSemanticColors colors = IuxSemanticColors.of(context);
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);

    final Color background = switch (role) {
      IuxSurfaceRole.base => colors.surface.base,
      IuxSurfaceRole.subtle => colors.surface.subtle,
      IuxSurfaceRole.raised => colors.surface.raised,
      IuxSurfaceRole.overlay => colors.surface.overlay,
      IuxSurfaceRole.selected => colors.surface.selected,
      IuxSurfaceRole.inverse => colors.surface.inverse,
    };

    final BorderRadius radius = BorderRadius.circular(switch (shape) {
      IuxSurfaceShape.none => 0,
      IuxSurfaceShape.subtle => geometry.radiusSubtle,
      IuxSurfaceShape.medium => geometry.radiusMedium,
      IuxSurfaceShape.prominent => geometry.radiusProminent,
    });

    final double elevation = elevated ? geometry.elevationRaised : 0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: radius,
        border: bordered
            ? Border.all(
                color: colors.border.standard,
                width: geometry.borderWidth,
              )
            : null,
        boxShadow: elevation > 0
            ? <BoxShadow>[
                BoxShadow(
                  color: const Color(0x1A000000),
                  blurRadius: elevation * 4,
                  offset: Offset(0, elevation),
                ),
              ]
            : null,
      ),
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );
  }
}

/// Corner treatments a surface may take.
enum IuxSurfaceShape {
  /// Square corners.
  none,

  /// A small radius, for dense elements.
  subtle,

  /// The default.
  medium,

  /// A large radius, for sheets and prominent containers.
  prominent,
}
