import 'package:flutter/foundation.dart';

/// Whether a disclosure is showing its content, and whether it may stop.
///
/// ```dart
/// IuxDisclosureState state = const IuxDisclosureState.collapsed();
/// state = const IuxDisclosureState.expanded();
/// // The submission was refused and the reason is inside this section.
/// state = const IuxDisclosureState.heldOpen();
/// ```
///
/// **Sealed, and that is the whole point.** The obvious shape for this is two
/// booleans — `expanded`, plus something like `mustStayOpen` for the case where
/// the content has become important. That pair can say *collapsed and must stay
/// open*, which is not a state an interface can render and is precisely the
/// defect this pattern exists to prevent: a closed section holding the thing
/// the user is stuck on. There is one value here instead, the combination
/// cannot be written, and the exhaustiveness checker refuses a `switch` that
/// forgets a case if a fourth state is ever added.
///
/// **The parent owns it.** Nothing in IUX produces an [IuxDisclosureState].
/// A widget that decided for itself when a section had become important would
/// be deciding on evidence it does not have, and a widget that owned `expanded`
/// would be a widget whose state the parent cannot read — the defect the
/// component standard §3 exists to prevent.
///
/// ## What may never be hidden
///
/// Progressive disclosure trades discoverability for calm. The trade is only
/// sound when what is hidden is genuinely optional, because **hidden content is
/// content most people never find**: every press is a decision, and a user who
/// cannot tell from the summary whether the answer is inside will not make it.
///
/// So four things never go behind a disclosure, whatever the layout pressure:
///
/// | Never disclosed | Why |
/// | --- | --- |
/// | a required input | a form that cannot be completed without opening a panel is a form most people fail |
/// | an error, or what caused it | WCAG 2.2 SC 3.3.1 requires the error to be described *in text*; text behind a press is text the user has already proved they did not open |
/// | the way out — cancel, back, the primary action | a user who cannot find the exit is trapped, and the exit is the one control that must never need discovering |
/// | a cost, a consequence, or what is being agreed to | consent obtained from someone who did not read what was hidden is not consent |
///
/// **This type enforces exactly one of those four, and it is honest about
/// which.** No widget can read a subtree and decide whether it contains a
/// required field, an exit or a price; anything claiming to would be guessing.
/// What it can do is refuse the combination the parent itself has just
/// declared: once the caller says the content must be dealt with,
/// [IuxDisclosureHeldOpen] is the only state that says it, and it is open by
/// construction. The other three rows are documentation, and are marked as such
/// rather than dressed up as a guarantee.
@immutable
sealed class IuxDisclosureState {
  /// Creates a disclosure state.
  const IuxDisclosureState();

  /// The content is hidden, and the user may reveal it.
  ///
  /// Hidden means *absent*, not transparent and not off-screen: see
  /// `IuxProgressiveDisclosure`.
  const factory IuxDisclosureState.collapsed() = IuxDisclosureCollapsed;

  /// The content is shown because the user asked for it, and may be hidden
  /// again.
  const factory IuxDisclosureState.expanded() = IuxDisclosureExpanded;

  /// The content is shown and may not be hidden, because it now matters.
  const factory IuxDisclosureState.heldOpen() = IuxDisclosureHeldOpen;
}

/// The content is hidden.
///
/// Carries nothing. Whether the user has ever opened this section, how many
/// times, and when, are facts about the application rather than about the
/// disclosure, and a state object that held them could not be `const`.
@immutable
final class IuxDisclosureCollapsed extends IuxDisclosureState {
  /// States that the content is hidden.
  const IuxDisclosureCollapsed();

  // runtimeType rather than a type test, for the reason `IuxLoadState` gives:
  // an asymmetric `==` is a value that goes into a Set twice and comes out of
  // a Map never. These states are not generic, so the two agree — the habit is
  // kept so that adding a field later cannot silently break it.
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other.runtimeType == runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'IuxDisclosureState.collapsed()';
}

/// The content is shown at the user's request.
@immutable
final class IuxDisclosureExpanded extends IuxDisclosureState {
  /// States that the content is shown and may be hidden again.
  const IuxDisclosureExpanded();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other.runtimeType == runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'IuxDisclosureState.expanded()';
}

/// The content is shown and the control that would hide it is gone.
///
/// The state for the moment a disclosure stops being optional: a submission was
/// refused and the rejected field is in this section, a choice the user made
/// elsewhere turned an advanced setting into a required one. The section is no
/// longer something the user may decline to read, so it stops offering to
/// close.
///
/// **The toggle is removed rather than disabled or ignored.** Three worse
/// answers were available and each fails somewhere specific:
///
/// - *Keep the toggle and ignore the press.* The node still announces
///   "expanded, button", a screen-reader user double-taps it, and nothing
///   happens — a control that lies about what it does.
/// - *Disable it.* On Android a disabled control leaves the focus order, so it
///   is announced as unavailable to the users who reach it and is invisible to
///   the users who navigate by focus, and neither group is told why.
/// - *Let the parent refuse.* That is honest for a panel that never opens —
///   `IuxContextualHelp` relies on it — but the failure here is the opposite
///   shape: the user asks for *less* and the interface silently keeps showing
///   more, which reads as a stuck screen rather than as a refusal.
///
/// What replaces it is a heading. The summary keeps its wording and its place,
/// gains a heading landmark a screen reader can jump to, and drops an
/// affordance that would have done nothing. The cost — a control disappearing
/// under a user who may have been standing on it — is real and is measured
/// rather than asserted: see the focus note in `docs/patterns/disclosure.md`.
///
/// **It carries no message.** Why the section is held open is already inside
/// it: the rejected field shows its own error, and `IuxValidationSummary` names
/// the failure at the top of the form. A second sentence on the summary line
/// would be a second error vocabulary, which is the mistake this library keeps
/// declining to make — `IuxEmptyState` refuses `IuxActionRole.retry` for the
/// same reason.
///
/// **It is a moment, not a mode.** A section that is *always* held open is not
/// a disclosure at all: it is a titled block of content, and `IuxSection` draws
/// one without pretending anything was ever hideable.
@immutable
final class IuxDisclosureHeldOpen extends IuxDisclosureState {
  /// States that the content is shown and may not be hidden.
  const IuxDisclosureHeldOpen();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other.runtimeType == runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'IuxDisclosureState.heldOpen()';
}
