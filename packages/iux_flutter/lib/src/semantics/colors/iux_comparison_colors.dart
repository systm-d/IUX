import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// The colour contract of one accent a compared reading may be drawn in.
///
/// A comparison role never asserts that one accent is red or that another is
/// blue, and — since `ADR-0015` — it no longer asserts which side of a
/// reference gets which. It states that a theme offers four distinguishable
/// hues plus a resting one for readings that have been compared with something;
/// which of them means *warmer* is the application's to say, in words, at the
/// call site.
///
/// **This is not a feedback role, and the difference is the whole reason it
/// exists.** `IuxFeedbackColorSet` names four categories of *news* — something
/// worked, something is about to stop working, something failed. A reading that
/// sits two degrees above its reference is none of those. Sending it through
/// `feedback.error` to obtain the colour the eye expects would assert that a
/// warm summer is a failure, which is a claim the framework has no standing to
/// make and the user no way to refuse. See `docs/decisions/ADR-0013-*`.
///
/// Because an accent is a choice and not an alarm, and because colour vision
/// varies, a component must always pair these colours with wording the reader
/// gets whatever they can see — which is why `IuxValue.meaning` is required.
@immutable
final class IuxComparisonRoleColors {
  /// Creates the immutable colour contract of one accent.
  const IuxComparisonRoleColors({
    required this.content,
    required this.surface,
  });

  /// The reading and the word that interprets it.
  ///
  /// Held to 4.5:1 twice, because it is painted on two grounds: the reading
  /// sits on [surface] and the word sits on the page beside it. One colour and
  /// two floors, rather than two roles — a second role whose value is always
  /// equal to the first is a role nobody can tell has been measured.
  final Color content;

  /// The tint the reading sits in.
  ///
  /// A tint of the accent's own hue where the palette has one, and the
  /// profile's raised neutral where it does not. It is never the accent at
  /// full strength: a capsule repeats down a column of rows, and thirty
  /// saturated capsules is a screen of alarms.
  final Color surface;

  /// **There is no outline role**, and its absence is the decision rather than
  /// an omission. `ADR-0013` gave the capsule one and `ADR-0015` removed it:
  /// what makes a deviation read as an alert is a ring around it, and the
  /// capsule's extent is not information — the reading inside it and the word
  /// beside it are, and both are text held to 4.5:1. A boundary that carries
  /// nothing is a boundary with no floor to meet.

  /// Returns a copy with the given roles replaced.
  IuxComparisonRoleColors copyWith({
    Color? content,
    Color? surface,
  }) =>
      IuxComparisonRoleColors(
        content: content ?? this.content,
        surface: surface ?? this.surface,
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
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxComparisonRoleColors &&
          other.content == content &&
          other.surface == surface;

  @override
  int get hashCode => Object.hash(content, surface);
}

/// The accents a compared reading may be drawn in: four, and a resting one.
///
/// **Four unranked hues rather than two ends of an axis**, and the change is
/// `ADR-0015`. An axis with a warm end and a cool end assumes that one side of
/// a reference always has one hue, and a single application disproves it: rain
/// above its normal is *wetter* and drawn blue, rain below it is *drier* and
/// drawn orange, while a temperature below its normal is *colder* and drawn the
/// same blue as the wet rain. Nothing about the arithmetic predicts any of
/// that. The theme supplies the hues; the application says which is which, in
/// the word it is already required to write.
///
/// [neutral] is the exception, and it is the one place the arithmetic still
/// decides: a reading level with its reference has nothing to interpret, so
/// `IuxValue.at` takes no accent and resolves here.
@immutable
final class IuxComparisonColorSet {
  /// Creates an immutable set of comparison accents.
  const IuxComparisonColorSet({
    required this.neutral,
    required this.one,
    required this.two,
    required this.three,
    required this.four,
  });

  /// A reading level with its reference.
  ///
  /// Grey in every shipped mapping, and deliberately so: a reading that matches
  /// its reference is the uneventful case, and giving it a hue would put a
  /// coloured capsule on every row of a list where most rows have nothing to
  /// report.
  final IuxComparisonRoleColors neutral;

  /// The first accent. Means nothing on its own.
  final IuxComparisonRoleColors one;

  /// The second accent. Means nothing on its own.
  final IuxComparisonRoleColors two;

  /// The third accent. Means nothing on its own.
  final IuxComparisonRoleColors three;

  /// The fourth accent. Means nothing on its own.
  final IuxComparisonRoleColors four;

  /// Returns a copy with the given roles replaced.
  IuxComparisonColorSet copyWith({
    IuxComparisonRoleColors? neutral,
    IuxComparisonRoleColors? one,
    IuxComparisonRoleColors? two,
    IuxComparisonRoleColors? three,
    IuxComparisonRoleColors? four,
  }) =>
      IuxComparisonColorSet(
        neutral: neutral ?? this.neutral,
        one: one ?? this.one,
        two: two ?? this.two,
        three: three ?? this.three,
        four: four ?? this.four,
      );

  /// Linearly interpolates between two comparison role sets.
  static IuxComparisonColorSet lerp(
    IuxComparisonColorSet a,
    IuxComparisonColorSet b,
    double t,
  ) =>
      IuxComparisonColorSet(
        neutral: IuxComparisonRoleColors.lerp(a.neutral, b.neutral, t),
        one: IuxComparisonRoleColors.lerp(a.one, b.one, t),
        two: IuxComparisonRoleColors.lerp(a.two, b.two, t),
        three: IuxComparisonRoleColors.lerp(a.three, b.three, t),
        four: IuxComparisonRoleColors.lerp(a.four, b.four, t),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxComparisonColorSet &&
          other.neutral == neutral &&
          other.one == one &&
          other.two == two &&
          other.three == three &&
          other.four == four;

  @override
  int get hashCode => Object.hash(neutral, one, two, three, four);
}
