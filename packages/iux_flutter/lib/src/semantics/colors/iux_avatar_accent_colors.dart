import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// The colour contract of one decorative accent for an icon's container.
///
/// **This is not a feedback role, and it is not a comparison role either —
/// see `docs/decisions/ADR-0014-a-container-is-not-a-verdict.md`.**
/// `IuxFeedbackColorSet` names four categories of *news*; `IuxComparisonColorSet`
/// names the three sides of a *reference*. What tints an avatar's circle is
/// neither: a season, a category, a place carries no news and sits on no
/// scale. Sending it through `feedback.error` to obtain a recognisable red
/// would assert that the thing painted red failed, which is a claim the
/// framework has no way to know is true and the caller no way to refuse
/// silently — the same category error `IuxComparisonRoleColors` was written
/// to avoid.
///
/// Because the accent carries no meaning of its own, and because colour
/// vision varies, a component must always pair it with a distinct glyph.
/// `IuxAvatar.tone` is deliberately paired with `IuxAvatar.icon`, never used
/// alone, for exactly this reason.
@immutable
final class IuxAvatarAccentRoleColors {
  /// Creates the immutable colour contract of one accent.
  const IuxAvatarAccentRoleColors({
    required this.content,
    required this.surface,
    required this.border,
    required this.icon,
  });

  /// Initials drawn on [surface], targeting 4.5:1 (WCAG 2.2 SC 1.4.3).
  final Color content;

  /// The circle's fill.
  final Color surface;

  /// The circle's outline.
  final Color border;

  /// A caller-supplied glyph drawn on [surface], targeting 3:1 (WCAG 2.2
  /// SC 1.4.11 — a graphical object, not text).
  ///
  /// A separate field from [content] rather than an alias for it, because the
  /// two are held to different floors and a shared field would hide which
  /// floor a palette actually met. In every mapping this record ships, the
  /// safest available colour clears both, so the two fields currently hold
  /// equal values — the same choice `IuxFeedbackRoleColors.icon` already
  /// makes over `IuxFeedbackRoleColors.content`. Nothing prevents a future
  /// mapping from diverging them, which is the entire reason there are two
  /// fields rather than one.
  final Color icon;

  /// Returns a copy with the given roles replaced.
  IuxAvatarAccentRoleColors copyWith({
    Color? content,
    Color? surface,
    Color? border,
    Color? icon,
  }) =>
      IuxAvatarAccentRoleColors(
        content: content ?? this.content,
        surface: surface ?? this.surface,
        border: border ?? this.border,
        icon: icon ?? this.icon,
      );

  /// Linearly interpolates between two accent contracts.
  static IuxAvatarAccentRoleColors lerp(
    IuxAvatarAccentRoleColors a,
    IuxAvatarAccentRoleColors b,
    double t,
  ) =>
      IuxAvatarAccentRoleColors(
        content: Color.lerp(a.content, b.content, t)!,
        surface: Color.lerp(a.surface, b.surface, t)!,
        border: Color.lerp(a.border, b.border, t)!,
        icon: Color.lerp(a.icon, b.icon, t)!,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxAvatarAccentRoleColors &&
          other.content == content &&
          other.surface == surface &&
          other.border == border &&
          other.icon == icon;

  @override
  int get hashCode => Object.hash(content, surface, border, icon);
}

/// The four decorative accents an icon's container may be tinted with.
///
/// **Four, and the number is the palette's, not a choice made for this
/// record.** IUX ships exactly four non-neutral hue families —
/// `docs/decisions/ADR-0013-a-reading-is-compared-not-judged.md` counted
/// them while looking for two — and inventing a fifth is palette work: new
/// primitives, measured on four profiles, under three simulated colour-vision
/// deficiencies, which is a mission rather than a paragraph in a component's
/// colour file. This record spends the four that already exist rather than
/// commissioning more.
///
/// **The members carry no meaning, and are named so that none can be read
/// into them.** [one] is not "the first" of anything and does not outrank
/// [four]; there is no order here the way there is an order in
/// `IuxValueDirection`. An application maps each member to whatever it needs
/// distinguished — a season, a workspace, a label colour — and that mapping
/// lives in the application, the same way the choice of glyph does.
@immutable
final class IuxAvatarAccentColorSet {
  /// Creates an immutable set of accents.
  const IuxAvatarAccentColorSet({
    required this.one,
    required this.two,
    required this.three,
    required this.four,
  });

  /// The first accent.
  final IuxAvatarAccentRoleColors one;

  /// The second accent.
  final IuxAvatarAccentRoleColors two;

  /// The third accent.
  final IuxAvatarAccentRoleColors three;

  /// The fourth accent.
  final IuxAvatarAccentRoleColors four;

  /// Returns a copy with the given accents replaced.
  IuxAvatarAccentColorSet copyWith({
    IuxAvatarAccentRoleColors? one,
    IuxAvatarAccentRoleColors? two,
    IuxAvatarAccentRoleColors? three,
    IuxAvatarAccentRoleColors? four,
  }) =>
      IuxAvatarAccentColorSet(
        one: one ?? this.one,
        two: two ?? this.two,
        three: three ?? this.three,
        four: four ?? this.four,
      );

  /// Linearly interpolates between two accent sets.
  static IuxAvatarAccentColorSet lerp(
    IuxAvatarAccentColorSet a,
    IuxAvatarAccentColorSet b,
    double t,
  ) =>
      IuxAvatarAccentColorSet(
        one: IuxAvatarAccentRoleColors.lerp(a.one, b.one, t),
        two: IuxAvatarAccentRoleColors.lerp(a.two, b.two, t),
        three: IuxAvatarAccentRoleColors.lerp(a.three, b.three, t),
        four: IuxAvatarAccentRoleColors.lerp(a.four, b.four, t),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxAvatarAccentColorSet &&
          other.one == one &&
          other.two == two &&
          other.three == three &&
          other.four == four;

  @override
  int get hashCode => Object.hash(one, two, three, four);
}
