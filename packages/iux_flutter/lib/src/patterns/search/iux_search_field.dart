import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../accessibility/iux_focus.dart';
import '../../actions/iux_action_descriptor.dart';
import '../../actions/iux_action_model.dart';
import '../../components/button/iux_button.dart';
import '../../components/input/iux_text_field.dart';
import '../../inputs/iux_input_descriptor.dart';
import '../../inputs/iux_input_model.dart';
import '../../layout/iux_spacing_primitives.dart';
import '../../themes/extensions/iux_geometry_theme.dart';

/// Why a search box with no name is refused.
const String _kEmptyLabel =
    'A search box must be named. An unnamed one is announced as "edit box" and '
    'nothing else, so a screen-reader user is asked for a value and not told '
    'what it will be matched against — and on a screen whose entire content is '
    'driven by this one box, that is the whole interface. Pass the localised '
    'name: "Search your orders", not "Search".';

/// Why a clear control with no name is refused.
const String _kEmptyClearLabel =
    'The clear control must be named. It is an icon with no text, so without a '
    'name it is announced as "button" and a screen-reader user is offered '
    'something that will change their results and refuses to say how. Pass the '
    'localised name: "Clear the search".';

/// Why an empty hint is refused rather than ignored.
const String _kEmptyHint =
    'An empty hint is the same as no hint, and says so less clearly. Omit the '
    'parameter, or pass the localised sentence a screen reader should read '
    'after the name.';

/// Why an empty placeholder is refused rather than ignored.
const String _kEmptyPlaceholder =
    'An empty placeholder is not a placeholder. Pass null instead, so the '
    'field does not fade an empty string in and out.';

/// The glyph on the clear control.
///
/// A cross rather than a backspace or a circled X: it is the one glyph users
/// already read as "remove what is in this box", and an unconventional glyph on
/// an unlabelled control is a puzzle with the answer hidden in the semantics.
const IconData _kClearIcon = Icons.close;

/// The box the user types a query into, and the control that empties it.
///
/// ```dart
/// IuxSearchField(
///   label: l10n.searchYourOrders,
///   clearLabel: l10n.clearTheSearch,
///   placeholder: l10n.orderNumberOrCustomer,
///   controller: _query,
///   onChanged: controller.queryChanged,
/// )
/// ```
///
/// **Use it** for the query half of a search: a box, its name, and a way to
/// empty it. Pair it with [IuxSearchResults], which owns the other half.
///
/// **Do not use it for a field whose value is answered rather than used.** A
/// value the application keeps — a name, an address, an amount — is
/// `IuxTextField`, which carries a requirement, a validation result and a help
/// line. None of those apply here, and this widget makes all three
/// unrepresentable rather than merely unusual. See "What it refuses to be"
/// below.
///
/// **Do not use it as a filter chip row.** Narrowing a list by choosing among
/// known values is a selection control; this is for a query the user composes.
///
/// **It runs no query, holds no history and stores nothing.** [onChanged]
/// reports the new text and that is the whole of this widget's output. Recent
/// searches are user data — a record of what someone looked for, which is
/// frequently the most sensitive thing an application holds — so where they are
/// kept, whether they survive a sign-out and whether they are kept at all are
/// the application's decisions, not a framework's.
///
/// ## What it refuses to be
///
/// The field descriptor is *derived* rather than accepted, the same choice
/// `IuxRecoveryRoute` makes with its action descriptor and for the same reason:
/// what may be configured is what may be got wrong. Four dimensions of
/// `IuxInputDescriptor` are fixed here and cannot be reached:
///
/// | Dimension | Fixed to | Why it is not offered |
/// | --- | --- | --- |
/// | requirement | optional | A search box is never required. Announcing it as required tells the user they must fill in a box that gates nothing. |
/// | validation | not validated | A query is not right or wrong, it matches or it does not — and "no matches" is an answer the results region gives, not a rejection the field gives. |
/// | help text | none | `IuxTextField` puts it below the box, which here is where the results are. A persistent instruction wedged between the query and its answer pushes the answer down on every screen and is read out between them. |
/// | availability | enabled | A search box nobody may use is a box that should not be on the screen. |
///
/// A caller who genuinely needs one of those is describing a text field rather
/// than a search box, and `IuxTextField` is still there.
///
/// ## The clear control
///
/// **It is always offered, and that is not negotiable through the API.** A box
/// full of text with no way to empty it leaves the user holding backspace,
/// which is a motor-accessibility problem before it is an annoyance and gets
/// worse the longer the query. So [clearLabel] is required rather than
/// nullable: there is no configuration of this widget that produces a query
/// with no way out of it.
///
/// **It is a control beside the box, not a glyph inside it.** A target inside a
/// target is two hit regions competing for the same pixels — a tap near the
/// trailing edge either clears the query or places the caret, and which one it
/// did is invisible until the results change. Placing it outside also lets it
/// be a real `IuxIconButton`, which means the touch-target floor, the focus
/// ring, the announced name and the keyboard activation are the button's rather
/// than reimplemented here. Measured at the standard profile it renders 56×56,
/// against a floor of `IuxTouchTarget.minimum` (48); the gap to the field is at
/// least [kIuxMinimumTargetSpacing].
///
/// **Its space is reserved whether or not it is shown.** The alternative — a
/// control that appears with the first character — resizes the box on the
/// keystroke that starts the query, which moves the caret under the user's
/// finger and, for someone using a screen magnifier, moves the box they are
/// looking at. The reserved slot costs one target's width and buys a field that
/// never changes size. While the box is empty the control is hidden, excluded
/// from the semantic tree and removed from the focus order, so nobody is
/// offered a control that would do nothing.
///
/// ## Accessibility
///
/// **Clearing returns focus to the box.** This is a deliberate exception to the
/// rule `IuxLoadingRetry` and `IuxEmptyState` follow — that focus is not moved
/// when content changes — and the difference is who asked. A load resolving
/// happens *to* the user; clearing is something they did, by activating a
/// control that then ceases to exist. Leaving focus where it was would hand it
/// back to the nearest enclosing scope, which is the defect IUX-030 documents
/// and cannot fix from its own side. Here it can be fixed, and the destination
/// is not a guess: the only reason to empty a search box is to put something
/// else in it.
///
/// What a screen reader hears as a result is the box's own name and its now
/// empty value — the platform's words for "this is empty", in the user's
/// language, rather than a sentence IUX composed. Nothing announces "cleared".
///
/// The trade is that focusing the box reopens the software keyboard for a user
/// who had dismissed it. That is the smaller cost: a user who has just emptied
/// their query is about to type.
///
/// **Everything else is inherited rather than reimplemented.** The name, the
/// text-scaling behaviour, the focus ring and the caret are `IuxTextField`'s;
/// the target, the announced name and the keyboard activation of the clear
/// control are `IuxIconButton`'s. This widget adds the row, the reserved slot
/// and the focus move, and nothing else.
///
/// ## Known limitations
///
/// **The box is not announced as a search box.** `SemanticsInputType.search`
/// exists in Flutter and would be the honest value here, but it is reachable
/// only through `IuxTextContent`, which has no `search` member; that enum
/// belongs to `IuxTextField` and is not this pattern's to change. The box is
/// therefore announced as an ordinary text field carrying the name the caller
/// gave it. Nothing essential is lost — the name says what it searches — and
/// whether Android's TalkBack distinguishes the two input types at all is
/// unverified, so this is recorded as a gap rather than as a defect with a
/// known user cost.
///
/// **There is no submit.** `IuxTextField` exposes neither `textInputAction` nor
/// `onSubmitted`, so this widget cannot give the software keyboard a "Search"
/// key and cannot report the user pressing it. The query therefore reaches the
/// caller only through [onChanged], and a search that should run when the user
/// finishes typing must be driven by the caller from that callback. Enter
/// dismisses the keyboard and does nothing else.
///
/// **There is no suggestion list.** See [IuxSearchResults] for the measurement
/// behind that.
///
/// **The clear control is bottom-aligned with the field block.** With no
/// supporting line below the box — which is every configuration this widget
/// permits — that puts it level with the box. It is not aligned by measuring
/// the box, because the box's offset depends on the name's height at the user's
/// text scale, which is not known until layout.
class IuxSearchField extends StatefulWidget {
  /// Creates a search box.
  const IuxSearchField({
    super.key,
    required this.label,
    required this.controller,
    required this.onChanged,
    required this.clearLabel,
    this.hint,
    this.placeholder,
    this.autofocus = false,
    this.focusNode,
  })  : assert(label.length > 0, _kEmptyLabel),
        assert(clearLabel.length > 0, _kEmptyClearLabel),
        assert(hint == null || hint.length > 0, _kEmptyHint),
        assert(
          placeholder == null || placeholder.length > 0,
          _kEmptyPlaceholder,
        );

  /// What this box searches, already localised.
  ///
  /// Shown above the box and announced as its name. Name the collection rather
  /// than the act: "Search your orders", not "Search". A screen may hold two
  /// search boxes — one over the whole application, one over the list in front
  /// of the user — and "Search" twice is two controls a screen-reader user
  /// cannot tell apart.
  ///
  /// It is always visible and there is no placeholder-as-name mode, which is
  /// `IuxTextField`'s position and inherited here: a name that disappears when
  /// typing starts leaves a user who has forgotten what the box searches with
  /// no way back, at exactly the moment they are checking what they typed.
  final String label;

  /// The live query text, owned and disposed by the parent.
  ///
  /// Required, with no internal fallback, for the reason `IuxTextField` gives:
  /// a field that quietly made its own controller would be a field whose value
  /// the parent cannot read.
  ///
  /// This widget writes to it in exactly one place — the clear control empties
  /// it — and reports that through [onChanged], which is the same sequence
  /// Flutter performs when the user types a character. There is no second
  /// callback for clearing, so there is no second callback to forget.
  final TextEditingController controller;

  /// Called on every change to the query, with the new text.
  ///
  /// Required. It is the only output this widget has: what to do with a query —
  /// when to run it, whether to run it at all — is the caller's, and this
  /// widget neither starts a search nor knows that one exists.
  ///
  /// Fires for the user's own edits and for the clear control. A programmatic
  /// change the parent makes through [controller] is the parent's own doing and
  /// does not come back to it.
  ///
  /// **Do not run a query straight from this callback.** See "Debounce is the
  /// caller's, and it is not optional" in `docs/patterns/search.md`: the
  /// measured cost of a query per keystroke is one screen-reader interruption
  /// per keystroke, before the results have said anything.
  final ValueChanged<String> onChanged;

  /// The name of the control that empties the box, already localised.
  ///
  /// Required, because the control is not optional. Name the outcome: "Clear
  /// the search", not "Clear" and not "X".
  final String clearLabel;

  /// What to search for, when the name alone leaves it ambiguous.
  ///
  /// Read by a screen reader after the name. Use it for what the query is
  /// matched against — "Matches order numbers and customer names" — where that
  /// is not obvious from [label].
  final String? hint;

  /// An example query, already localised, shown while the box is empty.
  ///
  /// Hidden from assistive technology by `IuxTextField`, because repeating it
  /// would make every empty box announce two names. Anything a user must know
  /// in order to search belongs in [hint], which is read after the name and
  /// does not vanish when typing starts.
  final String? placeholder;

  /// Whether the box takes focus when the screen opens.
  ///
  /// True is defensible here and almost nowhere else: a screen whose only
  /// purpose is searching has nothing else the user came for. It still opens
  /// the software keyboard over a screen the user has not read and moves a
  /// screen reader off the heading that says where they are, so leave it false
  /// when the search is one control among several.
  final bool autofocus;

  /// An externally owned focus node for the box.
  ///
  /// Pass one when something outside has to put the caret here — a "Search"
  /// control in an app bar opening this screen, for instance. When it is null
  /// this widget owns a node instead, because clearing has to have somewhere to
  /// return focus to.
  final FocusNode? focusNode;

  @override
  State<IuxSearchField> createState() => _IuxSearchFieldState();
}

class _IuxSearchFieldState extends State<IuxSearchField> {
  /// Created only when the caller supplied no node, and disposed with the
  /// state. The clear control needs a node to hand focus back to, so unlike
  /// `IuxTextField` this widget cannot leave the question to the child.
  FocusNode? _ownedNode;

  FocusNode get _fieldNode =>
      widget.focusNode ?? (_ownedNode ??= FocusNode(debugLabel: 'IuxSearch'));

  @override
  void dispose() {
    _ownedNode?.dispose();
    super.dispose();
  }

  /// Empties the box, reports it, and puts the caret back.
  ///
  /// The order matters. The text goes first so that the callback and the focus
  /// move both see an empty box; the focus move goes last so it lands on a node
  /// that is still mounted — the control being activated is about to be hidden,
  /// and Flutter would otherwise hand focus to the nearest enclosing scope.
  void _clear() {
    widget.controller.clear();
    widget.onChanged('');
    IuxFocus.request(_fieldNode);
  }

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);

    // The floor between two adjacent targets, never below it. Written out
    // rather than delegated to IuxTargetSpacing because that primitive lays its
    // children out in a Wrap, which cannot hold an Expanded field.
    final double gap = math.max(geometry.spacingXs, kIuxMinimumTargetSpacing);

    return Row(
      // Bottom-aligned rather than centred. The field block is a name, a gap
      // and the box, and this widget permits nothing below the box, so aligning
      // the ends puts the control level with the box it empties. Centring would
      // hang it half the name's height too low.
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: IuxTextField(
            input: IuxInputDescriptor(
              semantics: IuxInputSemantics(
                label: widget.label,
                hint: widget.hint,
              ),
            ),
            controller: widget.controller,
            onChanged: widget.onChanged,
            placeholder: widget.placeholder,
            autofocus: widget.autofocus,
            focusNode: _fieldNode,
          ),
        ),
        SizedBox(width: gap),
        _IuxSearchClearControl(
          controller: widget.controller,
          label: widget.clearLabel,
          onClear: _clear,
        ),
      ],
    );
  }
}

/// The control that empties the box, occupying its slot even when hidden.
///
/// Rebuilt from the controller rather than from `setState`, so a keystroke
/// repaints this control and not the field around it.
class _IuxSearchClearControl extends StatelessWidget {
  const _IuxSearchClearControl({
    required this.controller,
    required this.label,
    required this.onClear,
  });

  final TextEditingController controller;
  final String label;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (BuildContext context, TextEditingValue value, Widget? child) =>
          Visibility(
        visible: value.text.isNotEmpty,
        // The slot keeps its size, so the box does not resize on the keystroke
        // that starts the query. The three maintain flags below it are what
        // Visibility requires in order to keep the size at all.
        maintainSize: true,
        maintainAnimation: true,
        maintainState: true,
        // Both left at their defaults, and both matter. An empty box has
        // nothing to clear, so while it is hidden the control is excluded from
        // the semantic tree, taken out of the focus order and stops responding
        // to a pointer — otherwise it would be a control announced, reachable
        // by keyboard, and incapable of doing anything.
        child: child!,
      ),
      child: IuxIconButton(
        icon: _kClearIcon,
        // Derived rather than accepted. A caller who could pass a descriptor
        // could give this control a confirmation policy — a second question
        // asked about emptying a text box — or a destructive intent, which
        // would paint the loudest thing on the screen over the least
        // consequential control on it.
        action: IuxActionDescriptor(
          semantics: IuxActionSemantics(label: label),
          // cancel rather than dismiss: the action model separates them by
          // whether input is discarded, and this discards what the user typed.
          role: IuxActionRole.cancel,
        ),
        onActivate: onClear,
      ),
    );
  }
}
