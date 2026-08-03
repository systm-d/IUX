import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../semantics/iux_semantic_colors.dart';

/// Derives a Material [ColorScheme] from IUX semantic roles.
///
/// The direction is fixed by ADR-0002: IUX roles are the source of truth and
/// the scheme is derived from them. Material widgets used alongside IUX
/// components therefore inherit colours that were measured, instead of
/// colours generated from a seed that guarantees nothing.
///
/// Not every Material field has an IUX counterpart. Where none exists, the
/// mapping picks the closest role and the choice is documented here rather
/// than a new role being invented to fill a Material-shaped hole.
@internal
abstract final class IuxColorSchemeMapping {
  /// Builds the scheme corresponding to [colors].
  static ColorScheme resolve(
    IuxSemanticColors colors,
    Brightness brightness,
  ) =>
      ColorScheme(
        brightness: brightness,

        // Primary maps to the primary action, which is what Material uses it
        // for in practice.
        primary: colors.action.primary.background,
        onPrimary: colors.action.primary.foreground,
        primaryContainer: colors.surface.selected,
        onPrimaryContainer: colors.content.primary,

        // Material's secondary is a second accent. IUX's secondary action is
        // outlined, so its foreground carries the accent.
        secondary: colors.action.secondary.foreground,
        onSecondary: colors.content.onAction,
        secondaryContainer: colors.surface.subtle,
        onSecondaryContainer: colors.content.primary,

        tertiary: colors.action.tertiary.foreground,
        onTertiary: colors.content.onAction,
        tertiaryContainer: colors.surface.subtle,
        onTertiaryContainer: colors.content.primary,

        error: colors.action.destructive.background,
        onError: colors.action.destructive.foreground,
        errorContainer: colors.feedback.error.surface,
        onErrorContainer: colors.feedback.error.content,

        surface: colors.surface.base,
        onSurface: colors.content.primary,
        onSurfaceVariant: colors.content.secondary,
        surfaceDim: colors.surface.subtle,
        surfaceBright: colors.surface.base,
        surfaceContainerLowest: colors.surface.base,
        surfaceContainerLow: colors.surface.subtle,
        surfaceContainer: colors.surface.subtle,
        surfaceContainerHigh: colors.surface.raised,
        surfaceContainerHighest: colors.surface.raised,

        outline: colors.border.standard,
        outlineVariant: colors.border.subtle,

        inverseSurface: colors.surface.inverse,
        onInverseSurface: colors.content.inverse,
        inversePrimary: colors.content.link,

        shadow: const Color(0xFF000000),
        scrim: const Color(0xFF000000),

        // Material 3 tints a surface as its elevation rises. That would shift
        // surfaces away from the values IUX measured, so the tint is disabled
        // and elevation is expressed through the surface roles instead.
        surfaceTint: const Color(0x00000000),
      );
}
