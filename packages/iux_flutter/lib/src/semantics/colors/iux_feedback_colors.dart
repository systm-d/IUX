import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// The color contract of one feedback role.
///
/// A feedback role never asserts that success is green or that an error is
/// red. It states that a message belongs to a category; the theme decides how
/// that category is rendered, and may render two categories with the same hue
/// under a constrained palette.
///
/// Because of that, and because color vision varies, a component must always
/// pair these colors with an icon, wording, or screen-reader semantics.
@immutable
final class IuxFeedbackRoleColors {
  /// Creates the immutable color contract of one feedback role.
  const IuxFeedbackRoleColors({
    required this.content,
    required this.surface,
    required this.border,
    required this.icon,
  });

  /// The message text, targeting 4.5:1 against [surface].
  final Color content;

  /// The background of the feedback area.
  final Color surface;

  /// The outline, targeting 3:1 against the surface behind the feedback.
  final Color border;

  /// The accompanying icon, which carries the category without color.
  final Color icon;

  /// Returns a copy with the given roles replaced.
  IuxFeedbackRoleColors copyWith({
    Color? content,
    Color? surface,
    Color? border,
    Color? icon,
  }) =>
      IuxFeedbackRoleColors(
        content: content ?? this.content,
        surface: surface ?? this.surface,
        border: border ?? this.border,
        icon: icon ?? this.icon,
      );

  /// Linearly interpolates between two feedback role contracts.
  static IuxFeedbackRoleColors lerp(
    IuxFeedbackRoleColors a,
    IuxFeedbackRoleColors b,
    double t,
  ) =>
      IuxFeedbackRoleColors(
        content: Color.lerp(a.content, b.content, t)!,
        surface: Color.lerp(a.surface, b.surface, t)!,
        border: Color.lerp(a.border, b.border, t)!,
        icon: Color.lerp(a.icon, b.icon, t)!,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxFeedbackRoleColors &&
          other.content == content &&
          other.surface == surface &&
          other.border == border &&
          other.icon == icon;

  @override
  int get hashCode => Object.hash(content, surface, border, icon);
}

/// The feedback categories an interface can communicate.
@immutable
final class IuxFeedbackColorSet {
  /// Creates an immutable set of feedback roles.
  const IuxFeedbackColorSet({
    required this.info,
    required this.success,
    required this.warning,
    required this.error,
  });

  /// Neutral information that requires no action.
  final IuxFeedbackRoleColors info;

  /// Confirmation that a user-initiated operation completed.
  final IuxFeedbackRoleColors success;

  /// A consequence the user should consider before continuing.
  final IuxFeedbackRoleColors warning;

  /// A failure that prevents progress and needs a recovery path.
  final IuxFeedbackRoleColors error;

  /// Returns a copy with the given roles replaced.
  IuxFeedbackColorSet copyWith({
    IuxFeedbackRoleColors? info,
    IuxFeedbackRoleColors? success,
    IuxFeedbackRoleColors? warning,
    IuxFeedbackRoleColors? error,
  }) =>
      IuxFeedbackColorSet(
        info: info ?? this.info,
        success: success ?? this.success,
        warning: warning ?? this.warning,
        error: error ?? this.error,
      );

  /// Linearly interpolates between two feedback role sets.
  static IuxFeedbackColorSet lerp(
    IuxFeedbackColorSet a,
    IuxFeedbackColorSet b,
    double t,
  ) =>
      IuxFeedbackColorSet(
        info: IuxFeedbackRoleColors.lerp(a.info, b.info, t),
        success: IuxFeedbackRoleColors.lerp(a.success, b.success, t),
        warning: IuxFeedbackRoleColors.lerp(a.warning, b.warning, t),
        error: IuxFeedbackRoleColors.lerp(a.error, b.error, t),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxFeedbackColorSet &&
          other.info == info &&
          other.success == success &&
          other.warning == warning &&
          other.error == error;

  @override
  int get hashCode => Object.hash(info, success, warning, error);
}
