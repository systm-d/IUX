import 'package:flutter/material.dart';

import '../../accessibility/iux_accessibility.dart';
import '../../accessibility/iux_focus.dart';
import '../../accessibility/iux_focus_ownership.dart';
import '../../accessibility/iux_semantics.dart';
import '../../semantics/iux_semantic_colors.dart';
import '../../themes/extensions/iux_geometry_theme.dart';
import '../../themes/extensions/iux_typography_theme.dart';
import 'iux_disclosure_state.dart';

/// The glyph edge length before text scaling, in logical pixels.
///
/// The same figure the button theme, the status indicator and
/// `IuxContextualHelp` use. A chevron beside a label that is a different size
/// to every other chevron in the library is the kind of inconsistency nobody
/// can name and everybody notices.
const double _kGlyphSize = 20;

/// Why an unnamed disclosure is refused.
const String _kEmptySummary =
    'A disclosure has to say what it is hiding. Unnamed, it is announced as '
    '"button, collapsed" and drawn as a chevron, so the only way to find out '
    'what is inside is to open it — which is the cost this pattern exists to '
    'impose deliberately and only on people who have been told what they are '
    'paying for. Pass the localised summary: "Delivery options", not "More".';

/// Content the user may choose to see, and the named control that reveals it.
///
/// ```dart
/// IuxProgressiveDisclosure(
///   summary: l10n.advancedDeliveryOptions,
///   state: state.deliveryDisclosure,
///   onExpandedChanged: controller.setDeliveryDisclosed,
///   child: const DeliveryOptionsFields(),
/// )
/// ```
///
/// **Use it** for a block of the page that most people can complete their task
/// without: advanced settings, optional fields, the detail behind a summary,
/// the long version of something already stated short. The gain is a shorter
/// page for everybody; the cost is that the people who needed the block have to
/// find and press a control first.
///
/// **Do not use it for anything in the table in [IuxDisclosureState]** — a
/// required input, an error, the way out of a flow, or a cost the user is
/// agreeing to. Read that table before using this widget; it is the part of
/// this pattern that decides whether it should be used at all, and only one of
/// its four rows can be enforced by a type.
///
/// **Do not use it for help.** `IuxContextualHelp` is the same control with
/// prose behind it, and it is the right one for an explanation: it refuses
/// content that contains controls, so the panel cannot become a destination
/// with a focus order of its own. See the table below.
///
/// **Do not use it to hide a long list.** Everything revealed here is built
/// eagerly when it is revealed. A collapsed section costs nothing, which is the
/// point, but a section holding two hundred rows builds two hundred rows the
/// moment it opens. That is `IuxListGroup`'s problem to solve, not this one's.
///
/// ## What this is, next to `IuxContextualHelp`
///
/// | | What is behind the control | What it is for |
/// | --- | --- | --- |
/// | `IuxContextualHelp` | a `String`, and no control may be in it | explaining something on the page |
/// | **`IuxProgressiveDisclosure`** | any widget, controls included | *being* part of the page |
///
/// The two are not variants of each other and the difference is not length.
/// Prose has no focus order, cannot be reached by tab, and cannot be left
/// half-filled; a revealed form section is all three. Everything below that is
/// specific to this pattern follows from that one difference, and everything
/// that is not — the expanded state on the control's own node, the chevron as a
/// shape rather than a hue, the parent owning whether it is open, the refusal
/// to animate — is `IuxContextualHelp`'s reasoning, reached first by IUX-018
/// and reused here rather than re-argued.
///
/// **The disclosure control itself should exist once in this library and
/// currently exists twice.** `IuxContextualHelp` carries a private copy from
/// IUX-018, written before there was a pattern layer to put it in. The
/// difference between the two is a leading help glyph. That is a defect of
/// duplication rather than of behaviour, it is recorded in
/// `docs/patterns/disclosure.md`, and it is not fixed here because this mission
/// does not own that file.
///
/// ## Hidden means absent
///
/// A collapsed disclosure does not build its [child]. Not `Offstage`, not
/// `Visibility(maintainState: true)`, not `Opacity(opacity: 0)`, not a zero
/// height clip — every one of those leaves the content in the tree, which means
/// it leaves controls in the focus order and nodes in the semantics tree.
///
/// That is the defect this pattern is most likely to have shipped, because all
/// four look correct on screen. A keyboard user tabs into a section they cannot
/// see and lands on a control they cannot read; a screen-reader user swipes
/// through a button that is not there. Both are worse than the content simply
/// being unavailable, because the interface has told them it exists and refused
/// to show it.
///
/// The consequence, stated plainly: **revealed content is built fresh.** A
/// scroll position, a partially typed field, an animation halfway through — any
/// state living inside [child] rather than above it is discarded when the
/// section closes. Hoisting it is the caller's job, and it is the same job
/// hoisting it out of any conditional subtree would be.
///
/// ## Focus does not move
///
/// Opening a section leaves focus on the control the user pressed. IUX-012
/// moves focus to a validation summary, IUX-028, IUX-029 and IUX-030 all
/// decline to move it, and the line between them is whether the user asked for
/// the change *and* whether the answer to what they asked is somewhere they
/// cannot get to. Here they asked, and the answer is the very next thing in the
/// tree: a screen reader's next swipe reaches it, a keyboard's next tab reaches
/// it, and the platform has already spoken the state change on the node they
/// are standing on.
///
/// Moving focus would cost more than it bought. It would take a keyboard user
/// past the control they might want to press again, and it would land a
/// screen-reader user *inside* a region without their having heard what it was.
/// Worse, closing the section would then have to move focus back from content
/// that is about to stop existing, which is two interruptions where the user
/// asked for none.
///
/// This holds only because the content is adjacent, which is why there is no
/// way to reveal content anywhere else. Flutter's semantics have no equivalent
/// of `aria-controls`: adjacency in the tree is the entire association between
/// this control and what it opens, so the pattern refuses to break it.
///
/// ## No animation, and no parameter to add one
///
/// `IuxContextualHelp` reached this conclusion first and the argument only gets
/// stronger with arbitrary content: an in-flow reveal moves everything below it
/// *while it runs*, which is the motion a vestibular user objects to; it delays
/// content for someone who just asked for it; the change happens at the point
/// the user pressed, so "what just changed" is already answered; and an
/// animation that does not exist cannot take information with it when a
/// preference removes it.
///
/// Two more apply here and not there. This [child] may contain controls, and
/// animating a reveal means a control whose hit box travels while the user
/// reaches for it. And a reveal that is interrupted by a second press would
/// leave the semantics tree mid-flight, announcing a region that is neither
/// open nor closed.
///
/// So there is no `AnimatedSize`, no `AnimatedCrossFade`, no duration
/// parameter, and this file imports the motion policy nowhere. WCAG 2.2
/// SC 2.3.3 is satisfied by there being no animation to disable rather than by
/// a preference check that could be got wrong.
///
/// ## Accessibility
///
/// The control announces its name, that it is a button, and whether it is
/// expanded — on one node, so a screen-reader user is told there is something
/// to open before they open it and told the state changed after they did. The
/// same state is carried visually by a chevron's direction: a shape, not a hue,
/// so it survives a monochrome screen.
///
/// Under [IuxDisclosureHeldOpen] the control becomes a heading instead, with no
/// button role and no open state at all — the platform is told the section has
/// no such state rather than told it is permanently true.
///
/// The revealed region is not a live region. The user pressed the control, the
/// platform announced the state change, and the content is the next thing in
/// the reading order; announcing it as well would interrupt them to repeat
/// something they are already on their way to.
class IuxProgressiveDisclosure extends StatelessWidget {
  /// Creates a disclosure over [child].
  const IuxProgressiveDisclosure({
    super.key,
    required this.summary,
    required this.state,
    required this.onExpandedChanged,
    required this.child,
    this.focusNode,
  }) : assert(summary.length > 0, _kEmptySummary);

  /// What the control says is inside, already localised.
  ///
  /// It is both the visible text and the accessible name. A disclosure has
  /// nothing to say to one audience that it should hide from the other, and a
  /// separate semantic label would be a second string to keep in step with the
  /// first.
  ///
  /// Name the content, not the gesture: "Delivery options", never "More" or
  /// "Show". A user deciding whether to spend a press on this is deciding on
  /// these words alone, and "More" tells them nothing to decide with. Every
  /// control in an application labelled "More" is also the same control as far
  /// as a screen-reader user moving between them can tell.
  final String summary;

  /// Whether the content is showing, and whether it may stop. The parent's.
  ///
  /// Required, with no internal fallback and no `initiallyExpanded`. A form
  /// that must open the section holding a rejected field can only do that if
  /// the state lives outside this widget — and see [IuxDisclosureState] for why
  /// it is one value rather than a pair of booleans.
  final IuxDisclosureState state;

  /// Called with the state the user asked for.
  ///
  /// Named for what happened rather than for what should follow. A parent that
  /// ignores it gets a section that never opens, which is honest and visible
  /// immediately.
  ///
  /// Never called under [IuxDisclosureHeldOpen], because that state renders no
  /// control to press. Still required: a disclosure that is *always* held open
  /// is not a disclosure, and asking for the callback is what makes that
  /// obvious at the call site rather than in production.
  final ValueChanged<bool> onExpandedChanged;

  /// What is revealed.
  ///
  /// Built only while the section is open — see "Hidden means absent" above.
  /// A widget rather than a string, which is the whole difference from
  /// `IuxContextualHelp`: this may contain controls, and they take their place
  /// in the focus order immediately after the summary.
  final Widget child;

  /// An externally owned focus node for the control.
  ///
  /// Pass one when something outside has to put focus on this section — a form
  /// sending the user to the block holding the field their value just broke.
  /// There is deliberately no `autofocus`: a screen that opens with focus on a
  /// disclosure has answered a question nobody asked yet.
  ///
  /// The node is not attached under [IuxDisclosureHeldOpen], where there is no
  /// control for it to belong to.
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final _IuxDisclosureTokens tokens = _IuxDisclosureTokens.resolve(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // One `switch` over one sealed value. The impossible pairing —
        // collapsed while the content must be dealt with — is not asserted
        // here because it cannot be constructed there.
        switch (state) {
          IuxDisclosureCollapsed() ||
          IuxDisclosureExpanded() =>
            _IuxDisclosureControl(
              summary: summary,
              expanded: state is IuxDisclosureExpanded,
              tokens: tokens,
              focusNode: focusNode,
              onActivate: () =>
                  onExpandedChanged(state is! IuxDisclosureExpanded),
            ),
          IuxDisclosureHeldOpen() =>
            _IuxDisclosureHeading(summary: summary, tokens: tokens),
        },
        if (state is! IuxDisclosureCollapsed) ...<Widget>[
          SizedBox(height: tokens.gap),
          // Wrapped in nothing. An unnamed semantic container here would be a
          // stop that says nothing, and a named one would need a string the
          // framework does not have. The association with the control above is
          // adjacency, which is all Flutter's semantics offer.
          child,
        ],
      ],
    );
  }
}

/// The named control that opens and closes the section.
///
/// Not an `IuxButton`, for the two reasons `IuxContextualHelp` gives. A button
/// resolves its container against the page surface and would paint a patch of
/// button where a section heading belongs; and, decisively, a button cannot
/// announce that it is expanded, so a disclosure built from one is a control a
/// screen-reader user has to press in order to understand.
///
/// `_IuxHelpDisclosureControl` is this widget plus a leading glyph, and
/// IUX-038 declined to merge the two. The argument is written out once, beside
/// that copy, in `lib/src/components/help/iux_contextual_help.dart` —
/// IUX-DISCLOSURE-004. The short version: the merge points a component at a
/// pattern, which is the wrong direction, and every way round that costs more
/// than the duplication does. If the two ever diverge, reopen it.
class _IuxDisclosureControl extends StatelessWidget {
  const _IuxDisclosureControl({
    required this.summary,
    required this.expanded,
    required this.tokens,
    required this.focusNode,
    required this.onActivate,
  });

  final String summary;
  final bool expanded;
  final _IuxDisclosureTokens tokens;
  final FocusNode? focusNode;
  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) {
    // One node named twice: the announced node and the focusable region below
    // it have to be the same focus node, or the platform is told about a focus
    // that lives somewhere else. IUX-A11Y-FOCUS-001.
    return IuxFocusNodeOwner(
      focusNode: focusNode,
      debugLabel: summary,
      builder: (BuildContext context, FocusNode node) => IuxSemantics.action(
        label: summary,
        // Not null, and not omitted. Left absent the platform is never told
        // this control has an open state, so it cannot say "collapsed" before
        // the press — which is the announcement that makes a disclosure usable
        // without opening it.
        expanded: expanded,
        onTap: onActivate,
        focusNode: node,
        child: IuxFocusable(
          focusNode: node,
          onActivate: onActivate,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onActivate,
            child: _IuxDisclosureRow(
              summary: summary,
              tokens: tokens,
              stateGlyph: expanded ? Icons.expand_less : Icons.expand_more,
            ),
          ),
        ),
      ),
    );
  }
}

/// The same line, once the section may no longer be closed.
///
/// A heading rather than a button: there is nothing to activate, and a heading
/// is what the line has actually become — it also gives a screen reader a
/// landmark to jump to, which the button role never did.
///
/// The focus ring's reserved space is kept even though nothing here can take
/// focus, and the row keeps the same minimum height. Both exist so that a
/// section flipping to [IuxDisclosureHeldOpen] does not shift the content
/// beneath it by a few pixels on top of the change the user is already
/// absorbing. Reusing [IuxFocusRing] rather than re-deriving the inset is what
/// stops the two measurements drifting apart.
class _IuxDisclosureHeading extends StatelessWidget {
  const _IuxDisclosureHeading({required this.summary, required this.tokens});

  final String summary;
  final _IuxDisclosureTokens tokens;

  @override
  Widget build(BuildContext context) {
    return IuxSemantics.header(
      label: summary,
      child: IuxFocusRing(
        focused: false,
        // No chevron. A chevron on a line that cannot be collapsed is an
        // affordance advertising a gesture that does nothing.
        child: _IuxDisclosureRow(summary: summary, tokens: tokens),
      ),
    );
  }
}

/// The summary line, drawn identically whether or not it is a control.
///
/// Written once so the two states cannot disagree about type, padding or
/// height — which is what would turn the transition between them into a jump.
class _IuxDisclosureRow extends StatelessWidget {
  const _IuxDisclosureRow({
    required this.summary,
    required this.tokens,
    this.stateGlyph,
  });

  final String summary;
  final _IuxDisclosureTokens tokens;

  /// The chevron, or null on a line with nothing to toggle.
  final IconData? stateGlyph;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      // The interactive region meets the resolved floor while the label and the
      // chevron stay the size of the text around them. They are separate
      // measurements, and conflating them is how a control ends up enormous at
      // 200% text.
      constraints: BoxConstraints(minHeight: tokens.minimumSize),
      child: Padding(
        padding: tokens.rowPadding,
        child: Row(
          // Only as wide as it needs to be: a target stretching the width of
          // the page would swallow taps meant for the margin beside it, and
          // would put the chevron a long saccade away from the words it
          // belongs to on a wide screen.
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Flexible so a long summary wraps rather than overflowing once the
            // chevron has taken its share of the width.
            Flexible(
              child: Text(
                summary,
                // No line limit and no ellipsis at any text size. A truncated
                // summary is a summary the user cannot decide on, which is the
                // one thing this control has to let them do.
                style: tokens.summaryStyle,
              ),
            ),
            if (stateGlyph != null) ...<Widget>[
              SizedBox(width: tokens.gap),
              // Hidden from assistive technology. The chevron repeats what the
              // semantic node already carries, and the platform speaks that in
              // the user's own language rather than as a shape to decode.
              IuxSemantics.decorative(
                child: Icon(
                  stateGlyph,
                  size: tokens.glyphSize,
                  color: tokens.glyphColor,
                  // Scaled once, through the runtime every other IUX component
                  // reads. Letting Flutter scale it again would grow the
                  // chevron twice as fast as the words beside it.
                  applyTextScaling: false,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Everything needed to draw a disclosure, and nothing about how.
///
/// Private, unlike `IuxContextualHelpTokens`. A pattern composes what the
/// components and the runtime already resolve; publishing a token class here
/// would be public API with no caller, and the two decisions it holds — which
/// type role a summary uses, and how tall the row is — are not decisions an
/// application can usefully vary without breaking the guarantee that goes with
/// them.
@immutable
final class _IuxDisclosureTokens {
  const _IuxDisclosureTokens({
    required this.summaryStyle,
    required this.glyphColor,
    required this.glyphSize,
    required this.rowPadding,
    required this.gap,
    required this.minimumSize,
  });

  /// Resolves the tokens in force at [context].
  factory _IuxDisclosureTokens.resolve(BuildContext context) {
    final IuxAccessibility accessibility = IuxAccessibility.of(context);
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme typography = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);

    return _IuxDisclosureTokens(
      // The label role, the same one `IuxContextualHelp` gives its question.
      // Two controls that do the same thing and are set in different type are
      // two things as far as the reader is concerned.
      summaryStyle: typography.label.copyWith(color: colors.content.primary),
      // The *content* ratio rather than the 3:1 non-text one: the chevron sits
      // inside a control's label and is read alongside it.
      glyphColor: colors.content.primary,
      glyphSize: accessibility.scaleText(_kGlyphSize),
      // Vertical only. The summary lines up with whatever it introduces, and a
      // horizontal inset would set it a few pixels to the side of its content.
      rowPadding: EdgeInsets.symmetric(vertical: geometry.spacingXxs),
      gap: geometry.spacingXs,
      minimumSize: geometry.minimumTouchTarget,
    );
  }

  /// The summary's style, already carrying its colour.
  final TextStyle summaryStyle;

  /// The chevron's colour, held to 4.5:1 against the page by the theme.
  final Color glyphColor;

  /// The chevron's edge length, already scaled for the user's text size.
  final double glyphSize;

  /// Padding around the summary line.
  final EdgeInsets rowPadding;

  /// Space between the summary and the chevron, and between the control and
  /// the content it reveals.
  final double gap;

  /// The smallest permitted interactive dimension.
  final double minimumSize;
}
