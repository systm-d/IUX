import 'package:flutter/material.dart';

import 'colors/iux_action_colors.dart';
import 'colors/iux_border_colors.dart';
import 'colors/iux_comparison_colors.dart';
import 'colors/iux_content_colors.dart';
import 'colors/iux_feedback_colors.dart';
import 'colors/iux_state_colors.dart';
import 'colors/iux_surface_colors.dart';

/// The semantic color contract every IUX component reads.
///
/// Components ask for a role — "the primary action background", "disabled
/// content" — and never for a color. A theme decides what each role looks
/// like, which is what allows the same component to stay correct in light,
/// dark and high contrast conditions without knowing they exist.
///
/// IUX roles are the source of truth. A theme derives Flutter's [ColorScheme]
/// from these roles, never the reverse: deriving roles from a [ColorScheme]
/// would move the contrast guarantee outside IUX, where it cannot be tested.
///
/// Resolve it with [of]:
///
/// ```dart
/// final colors = IuxSemanticColors.of(context);
/// ```
@immutable
final class IuxSemanticColors extends ThemeExtension<IuxSemanticColors> {
  /// Creates the immutable semantic color contract.
  const IuxSemanticColors({
    required this.content,
    required this.surface,
    required this.border,
    required this.action,
    required this.feedback,
    required this.comparison,
    required this.state,
  });

  /// Colors for text, icons and other content.
  final IuxContentColors content;

  /// Backgrounds establishing interface hierarchy.
  final IuxSurfaceColors surface;

  /// Colors for outlines, dividers and focus indication.
  final IuxBorderColors border;

  /// The color contract of each action intent.
  final IuxActionColorSet action;

  /// The color contract of each feedback category.
  final IuxFeedbackColorSet feedback;

  /// The color contract of each side of a reference a reading can fall on.
  ///
  /// Separate from [feedback] because a direction is not a piece of news. See
  /// [IuxComparisonColorSet].
  final IuxComparisonColorSet comparison;

  /// Interaction states applying to any element.
  final IuxStateColors state;

  /// Resolves the semantic colors installed on the ambient theme.
  ///
  /// Throws a [FlutterError] when no IUX theme is installed, because a silent
  /// fallback would render a plausible but unverified interface and hide the
  /// misconfiguration until it reached a user. Use [maybeOf] when absence is
  /// a legitimate outcome.
  static IuxSemanticColors of(BuildContext context) {
    final colors = maybeOf(context);
    if (colors != null) return colors;
    throw FlutterError.fromParts(<DiagnosticsNode>[
      ErrorSummary('No IuxSemanticColors found in the ambient theme.'),
      ErrorDescription(
        'IUX components resolve their colors from an IuxSemanticColors theme '
        'extension. The enclosing Theme does not provide one.',
      ),
      ErrorHint(
        'Install an IUX theme on your MaterialApp, or add IuxSemanticColors '
        'to ThemeData.extensions.',
      ),
      context.describeWidget('The widget requesting semantic colors was'),
    ]);
  }

  /// Resolves the semantic colors, or returns null when none are installed.
  static IuxSemanticColors? maybeOf(BuildContext context) =>
      Theme.of(context).extension<IuxSemanticColors>();

  @override
  IuxSemanticColors copyWith({
    IuxContentColors? content,
    IuxSurfaceColors? surface,
    IuxBorderColors? border,
    IuxActionColorSet? action,
    IuxFeedbackColorSet? feedback,
    IuxComparisonColorSet? comparison,
    IuxStateColors? state,
  }) =>
      IuxSemanticColors(
        content: content ?? this.content,
        surface: surface ?? this.surface,
        border: border ?? this.border,
        action: action ?? this.action,
        feedback: feedback ?? this.feedback,
        comparison: comparison ?? this.comparison,
        state: state ?? this.state,
      );

  @override
  IuxSemanticColors lerp(
    covariant ThemeExtension<IuxSemanticColors>? other,
    double t,
  ) {
    if (other is! IuxSemanticColors) return this;
    return IuxSemanticColors(
      content: IuxContentColors.lerp(content, other.content, t),
      surface: IuxSurfaceColors.lerp(surface, other.surface, t),
      border: IuxBorderColors.lerp(border, other.border, t),
      action: IuxActionColorSet.lerp(action, other.action, t),
      feedback: IuxFeedbackColorSet.lerp(feedback, other.feedback, t),
      comparison: IuxComparisonColorSet.lerp(
        comparison,
        other.comparison,
        t,
      ),
      state: IuxStateColors.lerp(state, other.state, t),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxSemanticColors &&
          other.content == content &&
          other.surface == surface &&
          other.border == border &&
          other.action == action &&
          other.feedback == feedback &&
          other.comparison == comparison &&
          other.state == state;

  @override
  int get hashCode => Object.hash(
        content,
        surface,
        border,
        action,
        feedback,
        comparison,
        state,
      );
}
