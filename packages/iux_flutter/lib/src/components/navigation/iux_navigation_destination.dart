import 'package:flutter/widgets.dart';

import '../status/iux_badge.dart';

/// Where a destination's badge sits.
enum IuxBadgePlacement {
  /// After the label, in reading order. The default, and the safe one.
  ///
  /// Nothing is covered, nothing clips at any text size, and the number sits
  /// beside the noun it counts.
  afterLabel,

  /// On the corner of the glyph, the way a launcher badges an application.
  ///
  /// **Opt in knowingly.** [afterLabel] remains the recommendation and the
  /// default; this exists because the corner badge is the most widely learned
  /// convention on a phone, and a navigation bar is where a user has already
  /// spent years learning it.
  ///
  /// What it costs, and what it does not:
  ///
  ///   * **It covers part of the glyph.** Accepted here and nowhere else,
  ///     because a destination's glyph is decorative by construction — the
  ///     label beside it carries the meaning and is drawn at every size.
  ///   * **It does not clip.** The corner exists only while the bar is in its
  ///     compact arrangement; once the text grows enough that the bar lays its
  ///     destinations out in rows, the badge goes back after the label on its
  ///     own. The overlay is an enhancement for the sizes that can carry it,
  ///     never a layout that breaks at the size somebody chose in order to
  ///     read.
  ///   * **It does not lose the number.** The badge is merged into the
  ///     destination's single announcement either way, so a screen reader
  ///     hears "Aujourd'hui, 10 notifications retenues, sélectionné" whichever
  ///     placement is drawn.
  onGlyph,
}

/// One place the user can go, described rather than drawn.
///
/// ```dart
/// IuxNavigationDestination(
///   label: l10n.messages,
///   icon: Icons.mail_outline,
///   selectedIcon: Icons.mail,
///   badge: IuxBadge.count(
///     count: l10n.formatCount(unread),
///     label: l10n.unreadMessages(unread),
///   ),
/// )
/// ```
///
/// A value, not a widget. The bar decides how a destination is laid out, how
/// large its target is, and how its state is announced, and it can only
/// guarantee those things if it owns the rendering. A widget here would be a
/// place for a call site to put a second control, a fixed height or a colour,
/// and every one of those defeats a guarantee the bar is making.
///
/// ## The label is not optional, and there is no way to hide it
///
/// There is no `labelBehavior`, no `showLabel`, and no icon-only form. An icon
/// on its own is a guess: the conventional ones (house, magnifier) are learned,
/// the rest are not, and the user finds out which kind they are looking at by
/// tapping. Showing the label of the current destination only is worse still —
/// it tells the user the name of the one place they already know they are, and
/// keeps the other four secret until they visit them.
///
/// The cost is space, and it is paid. See `docs/components/bottom-navigation.md`.
@immutable
final class IuxNavigationDestination {
  /// Creates a destination.
  const IuxNavigationDestination({
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.badge,
    this.badgePlacement = IuxBadgePlacement.afterLabel,
  }) : assert(
          label.length > 0,
          'A destination must be named. An unnamed one is a glyph the user has '
          'to interpret, and a screen reader announces it as an unlabelled '
          'control in a set of five identical unlabelled controls.',
        );

  /// The visible name of the destination, already localised.
  ///
  /// Always drawn, at every text size, on every screen width — see the class
  /// documentation. It is also the accessible name: the label a sighted user
  /// reads and the one a screen-reader user hears are deliberately the same
  /// string, because a navigation bar has no context in which they could
  /// legitimately differ.
  ///
  /// Short. This is the one place in IUX where a long string has nowhere to
  /// go: five names share one screen width, so a name that needs a sentence
  /// belongs to a section this bar should not be offering.
  final String label;

  /// The glyph shown when this destination is not the current one.
  ///
  /// [IconData] rather than a widget, so the bar sizes and colours it from the
  /// theme. A widget could carry its own colour, and the contrast guarantee
  /// would leave with it.
  ///
  /// Decorative. The label beside it already says what this is, so the glyph is
  /// removed from the semantic tree rather than announced a second time.
  final IconData icon;

  /// The glyph shown when this destination *is* the current one, or null.
  ///
  /// Optional, and a reinforcement rather than the signal: the bar already
  /// marks the current destination with an indicator behind the glyph and with
  /// the selection state in its semantics. A filled variant of the same glyph
  /// is a third cue for a user who reads shape faster than they read a tonal
  /// band; a *different* glyph here would tell the user the destination changed
  /// identity when they arrived.
  final IconData? selectedIcon;

  /// What is waiting at this destination, or null.
  ///
  /// Typed as [IuxBadge] rather than as a widget on purpose. A badge that shows
  /// a bare number tells a screen-reader user "3" and leaves them to work out
  /// three of what; [IuxBadge] already refuses that, and accepting any widget
  /// here would be a second, unchecked way to put a number on a destination.
  ///
  /// The badge is merged into the destination's single announcement either
  /// way — "Messages, 3 unread messages, checked" — so the number and its
  /// subject are never in two places for a screen reader, whichever placement
  /// is drawn.
  ///
  /// It is laid out after the label unless [badgePlacement] says otherwise.
  final IuxBadge? badge;

  /// Where [badge] sits. [IuxBadgePlacement.afterLabel] unless asked.
  ///
  /// The default is the recommendation. See [IuxBadgePlacement.onGlyph] for
  /// what the other one costs and what it is careful not to.
  final IuxBadgePlacement badgePlacement;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxNavigationDestination &&
          other.badgePlacement == badgePlacement &&
          other.label == label &&
          other.icon == icon &&
          other.selectedIcon == selectedIcon &&
          other.badge == badge;

  @override
  int get hashCode =>
      Object.hash(label, icon, selectedIcon, badge, badgePlacement);

  @override
  String toString() => 'IuxNavigationDestination($label)';
}
