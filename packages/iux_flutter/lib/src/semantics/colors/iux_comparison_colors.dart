import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// The colour contract of one direction relative to a reference.
///
/// A comparison role never asserts that above is red or that below is blue. It
/// states which side of a stated reference a reading fell on; the theme decides
/// how that side is rendered, and may render two sides with the same hue under
/// a constrained palette.
///
/// **This is not a feedback role, and the difference is the whole reason it
/// exists.** `IuxFeedbackColorSet` names four categories of *news* — something
/// worked, something is about to stop working, something failed. A reading that
/// sits two degrees above its reference is none of those. Sending it through
/// `feedback.error` to obtain the colour the eye expects would assert that a
/// warm summer is a failure, which is a claim the framework has no standing to
/// make and the user no way to refuse. See `docs/decisions/ADR-0013-*`.
///
/// Because a direction is a fact and not an alarm, and because colour vision
/// varies, a component must always pair these colours with a mark, wording, or
/// screen-reader semantics.
@immutable
final class IuxComparisonRoleColors {
  /// Creates the immutable colour contract of one direction.
  const IuxComparisonRoleColors({
    required this.content,
    required this.surface,
    required this.border,
    required this.mark,
  });

  /// The reading itself, targeting 4.5:1 against [surface].
  final Color content;

  /// The background of the container the reading sits in.
  final Color surface;

  /// The outline, targeting 3:1 against the surface behind the container.
  final Color border;

  /// The direction mark, which carries the direction without colour.
  ///
  /// Targets 3:1 against [surface], the ratio SC 1.4.11 asks of a meaningful
  /// graphic. It is a separate role from [content] rather than an alias for it
  /// because the two are held to different floors, and an alias hides which
  /// floor a palette actually met.
  final Color mark;

  /// Returns a copy with the given roles replaced.
  IuxComparisonRoleColors copyWith({
    Color? content,
    Color? surface,
    Color? border,
    Color? mark,
  }) =>
      IuxComparisonRoleColors(
        content: content ?? this.content,
        surface: surface ?? this.surface,
        border: border ?? this.border,
        mark: mark ?? this.mark,
      );

  /// Linearly interpolates between two comparison role contracts.
  static IuxComparisonRoleColors lerp(
    IuxComparisonRoleColors a,
    IuxComparisonRoleColors b,
    double t,
  ) =>
      IuxComparisonRoleColors(
        content: Color.lerp(a.content, b.content, t)!,
        surface: Color.lerp(a.surface, b.surface, t)!,
        border: Color.lerp(a.border, b.border, t)!,
        mark: Color.lerp(a.mark, b.mark, t)!,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxComparisonRoleColors &&
          other.content == content &&
          other.surface == surface &&
          other.border == border &&
          other.mark == mark;

  @override
  int get hashCode => Object.hash(content, surface, border, mark);
}

/// The three sides of a reference a reading can fall on.
///
/// Three, and the number is not a taste. A reading compared with a reference is
/// above it, level with it, or below it; there is no fourth side and there is
/// no domain that has one. That is what separates this set from
/// `IuxFeedbackColorSet`, whose four categories are a judgement about how
/// worried the user should be — a judgement no framework can make about a
/// number it did not measure.
@immutable
final class IuxComparisonColorSet {
  /// Creates an immutable set of comparison roles.
  const IuxComparisonColorSet({
    required this.above,
    required this.at,
    required this.below,
  });

  /// A reading on the upper side of its reference.
  final IuxComparisonRoleColors above;

  /// A reading level with its reference.
  ///
  /// Neutral in every shipped mapping, and deliberately so: a reading that
  /// matches its reference is the uneventful case, and giving it a hue would
  /// put a coloured pill on every row of a list where most rows have nothing
  /// to report.
  final IuxComparisonRoleColors at;

  /// A reading on the lower side of its reference.
  final IuxComparisonRoleColors below;

  /// Returns a copy with the given roles replaced.
  IuxComparisonColorSet copyWith({
    IuxComparisonRoleColors? above,
    IuxComparisonRoleColors? at,
    IuxComparisonRoleColors? below,
  }) =>
      IuxComparisonColorSet(
        above: above ?? this.above,
        at: at ?? this.at,
        below: below ?? this.below,
      );

  /// Linearly interpolates between two comparison role sets.
  static IuxComparisonColorSet lerp(
    IuxComparisonColorSet a,
    IuxComparisonColorSet b,
    double t,
  ) =>
      IuxComparisonColorSet(
        above: IuxComparisonRoleColors.lerp(a.above, b.above, t),
        at: IuxComparisonRoleColors.lerp(a.at, b.at, t),
        below: IuxComparisonRoleColors.lerp(a.below, b.below, t),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxComparisonColorSet &&
          other.above == above &&
          other.at == at &&
          other.below == below;

  @override
  int get hashCode => Object.hash(above, at, below);
}
