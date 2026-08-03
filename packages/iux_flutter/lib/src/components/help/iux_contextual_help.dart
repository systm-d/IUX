import 'package:flutter/material.dart';

import '../../accessibility/iux_focus.dart';
import '../../accessibility/iux_semantics.dart';
import 'iux_help_tokens.dart';

/// Why an empty label is refused.
const String _kEmptyLabel =
    'The control that opens help has to say what it will explain. Unnamed, it '
    'is announced as "button" and drawn as a question mark, so the only way to '
    'find out what it is about is to press it — which is the cost this '
    'component exists to remove.';

/// Why an empty help text is refused.
const String _kEmptyHelp =
    'A disclosure that reveals nothing is a control that punishes the user for '
    'using it. Pass the explanation, or remove the IuxContextualHelp.';

/// Help the user asks for, revealed in the page rather than over it.
///
/// ```dart
/// IuxContextualHelp(
///   label: l10n.whatIsASortCode,
///   help: l10n.sortCodeExplanation,
///   expanded: state.sortCodeHelpOpen,
///   onExpandedChanged: controller.toggleSortCodeHelp,
/// )
/// ```
///
/// **Use it** for an explanation that most users do not need and some cannot do
/// without: what a field means, why it is being asked for, what happens next.
///
/// **Do not use it** for anything required in order to act. Help that everyone
/// needs is not help, it is instruction, and instruction that has to be opened
/// is instruction most people never see — put it on screen. For a text field
/// that is `IuxInputDescriptor.helpText`, which is always visible and always
/// announced.
///
/// ## Where help goes, and why there are three answers
///
/// | The user | Where it belongs | What it costs |
/// | --- | --- | --- |
/// | needs it to answer at all | always visible — `IuxInputDescriptor.helpText` | vertical space, on every screen, for every user |
/// | may need it, and asks | **here** | one press, and only for the people who press |
/// | already knows, but not this glyph | `IuxTooltip` | nothing, and it reaches nobody who does not hover, hold or focus |
///
/// The distinction is not length and it is not tone. It is **what happens to
/// the user who never sees it.** If the answer is "they cannot complete the
/// task", the information is not contextual help and no amount of disclosure
/// makes it so.
///
/// ## Why this is in the page and not in a floating box
///
/// A tooltip caps its message at [kIuxTooltipMaximumCharacters] characters
/// because a box floating over a page is the worst reading surface in the
/// library: it cannot be scrolled, it cannot be kept open while the user does
/// something else, and at 200% text on a 320-pixel screen a paragraph in one is
/// unreadable. This panel has none of those problems. It is in the flow, so it
/// scrolls with the page, wraps at any text size, and stays open until the
/// user closes it.
///
/// It costs layout: opening one moves everything below it. That is the trade,
/// and it is made deliberately — content that moves is recoverable, content
/// that is clipped is not.
///
/// ## The parent owns whether it is open
///
/// [expanded] and [onExpandedChanged] are required, and there is no internal
/// fallback. A form that wants to open the panel explaining the rule a value
/// just broke can only do that if the state lives outside the widget; and a
/// component that owned it would be a component whose state the parent cannot
/// read, which is the defect the component standard §3 exists to prevent.
///
/// ## Accessibility
///
/// The control announces its name, that it is a button, and whether it is
/// expanded — so a screen-reader user is told there is something to open before
/// they open it, and told the state changed after they did. The visible signal
/// for the same state is the direction of a chevron: a shape, not a hue, so it
/// survives a monochrome screen.
///
/// The panel is not a live region. The user has just pressed the control, the
/// platform announces the state change, and the text is the next thing in the
/// reading order — announcing it as well would interrupt them to repeat
/// something they are already on their way to.
class IuxContextualHelp extends StatelessWidget {
  /// Creates a help disclosure.
  const IuxContextualHelp({
    super.key,
    required this.label,
    required this.help,
    required this.expanded,
    required this.onExpandedChanged,
    this.focusNode,
  })  : assert(label.length > 0, _kEmptyLabel),
        assert(help.length > 0, _kEmptyHelp);

  /// What the control says it will explain. Already localised.
  ///
  /// A question or a subject, not a verb: "What is a sort code?" rather than
  /// "Help". Every control in an application labelled "Help" is the same
  /// control as far as a screen-reader user moving between them can tell.
  ///
  /// It is both the visible text and the accessible name. There is no separate
  /// semantic label, because a help control has nothing to say to one audience
  /// that it should hide from the other.
  final String label;

  /// The explanation, already localised.
  ///
  /// A string rather than a widget, so the panel keeps the typography and the
  /// measured contrast the theme is responsible for. Paragraphs are separated
  /// with blank lines in the string itself.
  ///
  /// Help that needs a control inside it — a link, a button, a form — is not
  /// contextual help; it is a destination, and it belongs on a screen of its
  /// own where the user can find their way back.
  final String help;

  /// Whether the panel is open. The parent's.
  final bool expanded;

  /// Called with the state the user asked for.
  ///
  /// Named for what happened rather than for what should follow: the parent
  /// decides what to do about it, including doing nothing, in which case the
  /// panel simply does not open — which is honest, and visible immediately.
  final ValueChanged<bool> onExpandedChanged;

  /// An externally owned focus node for the control that opens the panel.
  ///
  /// Pass one when something outside has to move focus onto the help — a form
  /// sending the user to the explanation of the rule their value just broke.
  /// There is deliberately no `autofocus`: a screen that opens with focus on
  /// its help control has answered a question nobody asked yet.
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final IuxContextualHelpTokens tokens =
        IuxContextualHelpResolver.resolve(context, expanded: expanded);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _IuxHelpDisclosureControl(
          label: label,
          expanded: expanded,
          tokens: tokens,
          focusNode: focusNode,
          onActivate: () => onExpandedChanged(!expanded),
        ),
        if (expanded) ...<Widget>[
          SizedBox(height: tokens.gap),
          _IuxHelpPanel(help: help, tokens: tokens),
        ],
      ],
    );
  }
}

/// The named control that opens and closes the panel.
///
/// Not an `IuxButton`, for two reasons. The first is the one the inline and
/// transient messages give: a button resolves its container against the page
/// surface and would paint a patch of button inside a block of prose. The
/// second is decisive — a button cannot announce that it is expanded, and a
/// disclosure that does not announce its state is a control a screen-reader
/// user has to press to discover.
class _IuxHelpDisclosureControl extends StatelessWidget {
  const _IuxHelpDisclosureControl({
    required this.label,
    required this.expanded,
    required this.tokens,
    required this.focusNode,
    required this.onActivate,
  });

  final String label;
  final bool expanded;
  final IuxContextualHelpTokens tokens;
  final FocusNode? focusNode;
  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) {
    return IuxSemantics.action(
      label: label,
      expanded: expanded,
      onTap: onActivate,
      child: IuxFocusable(
        focusNode: focusNode,
        onActivate: onActivate,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onActivate,
          child: ConstrainedBox(
            // The interactive region meets the resolved floor while the glyphs
            // and the label stay the size of the text around them. They are
            // separate measurements.
            constraints: BoxConstraints(minHeight: tokens.minimumSize),
            child: Padding(
              padding: tokens.controlPadding,
              child: Row(
                // Only as wide as it needs to be: a target stretching the width
                // of the page would swallow taps meant for the margin beside it.
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _IuxHelpGlyph(icon: tokens.glyph, tokens: tokens),
                  SizedBox(width: tokens.gap),
                  // Flexible so a long question wraps rather than overflowing
                  // once the two glyphs have taken their share of the width.
                  Flexible(
                    child: Text(
                      label,
                      // No line limit and no ellipsis: a truncated question is
                      // a question the user cannot decide whether to ask.
                      style: tokens.labelStyle,
                    ),
                  ),
                  SizedBox(width: tokens.gap),
                  _IuxHelpGlyph(icon: tokens.stateGlyph, tokens: tokens),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The disclosed explanation.
///
/// A recessed surface with an outline, so the panel is identifiable as one
/// block rather than as loose text that happened to appear. Neither the fill
/// nor the outline carries meaning: the words do.
class _IuxHelpPanel extends StatelessWidget {
  const _IuxHelpPanel({required this.help, required this.tokens});

  final String help;
  final IuxContextualHelpTokens tokens;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.panelBackground,
        borderRadius: BorderRadius.circular(tokens.radius),
        border: Border.all(
          color: tokens.panelBorder,
          width: tokens.borderWidth,
        ),
      ),
      child: Padding(
        padding: tokens.panelPadding,
        child: Text(
          help,
          // No line limit and no ellipsis at any text size. Truncated help is
          // help that stops exactly where it starts being needed, and it gets
          // worse for the user who enlarged their text.
          style: tokens.helpStyle,
        ),
      ),
    );
  }
}

/// A glyph sized and coloured from the tokens the disclosure resolved.
///
/// Written once so the help mark and the chevron cannot disagree about how
/// large a glyph is, and so the text-scaling rule is stated in one place.
class _IuxHelpGlyph extends StatelessWidget {
  const _IuxHelpGlyph({required this.icon, required this.tokens});

  final IconData icon;
  final IuxContextualHelpTokens tokens;

  @override
  Widget build(BuildContext context) {
    // Hidden from assistive technology. Both glyphs repeat what the semantic
    // node already carries — that this is about help, and whether it is open —
    // and the platform speaks that in the user's own language rather than as a
    // shape they would have to decode.
    return IuxSemantics.decorative(
      child: Icon(
        icon,
        size: tokens.glyphSize,
        color: tokens.glyphColor,
        // Scaled once, through the runtime every other IUX component reads.
        // Letting Flutter scale it again would grow the glyph twice as fast as
        // the label beside it.
        applyTextScaling: false,
      ),
    );
  }
}
