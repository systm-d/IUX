import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../accessibility/iux_focus.dart';
import '../../accessibility/iux_focus_ownership.dart';
import '../../accessibility/iux_semantics.dart';
import '../../accessibility/iux_touch_target.dart';
import '../../inputs/iux_input_descriptor.dart';
import '../../inputs/iux_input_model.dart';
import '../../layout/iux_spacing_primitives.dart';
import '../../themes/extensions/iux_geometry_theme.dart';
import 'iux_selection_model.dart';
import 'iux_selection_tokens.dart';

/// How large the tick on a switch thumb is, relative to the thumb.
const double _thumbMarkRatio = 0.7;

/// An independent yes/no.
///
/// ```dart
/// IuxCheckbox(
///   label: l10n.sendMeTheNewsletter,
///   input: const IuxInputDescriptor(
///     semantics: IuxInputSemantics(label: 'Send me the newsletter'),
///   ),
///   value: IuxSelectionState.fromSelected(subscribed),
///   onChanged: controller.setSubscribed,
/// )
/// ```
///
/// **Use it** when the answer is yes or no, when it is independent of every
/// other answer on the screen, and when nothing happens until the user
/// confirms the form. Several checkboxes together mean "choose any number of
/// these", including none.
///
/// **Do not use it** for a setting that takes effect immediately — that is
/// [IuxSwitch], and rendering an immediate setting as a checkbox makes users
/// look for the Save button that does not exist. Do not use it for a choice
/// among mutually exclusive options either: two checkboxes where only one may
/// be true is a radio group with a bug waiting in it, and the user can see
/// nothing that says the two are related. And do not use one on its own to
/// mean "on/off now" — an isolated checkbox says nothing about when it
/// applies.
///
/// **The label is part of the target.** Tapping the text toggles the control.
/// A 24-pixel box with an untappable label beside it is the classic failure of
/// this component family: it is legal, it looks right, and it is unusable for
/// anyone with a tremor.
///
/// **The parent owns the value.** This widget never holds the answer. It
/// renders [value] and reports what the user asked for; if the parent does not
/// re-render with a new [value], nothing changes on screen — which is correct,
/// because a control that flipped itself and then failed to save would be
/// showing the user something untrue.
class IuxCheckbox extends StatelessWidget {
  /// Creates an independent yes/no control.
  const IuxCheckbox({
    super.key,
    required this.label,
    required this.input,
    required this.value,
    required this.onChanged,
    this.autofocus = false,
    this.focusNode,
  }) : assert(
          label.length > 0,
          'A checkbox must show what it is asking. An unlabelled box is a '
          'question the user has to guess, and a screen reader announces it as '
          '"checkbox" and nothing else.',
        );

  /// The visible text, already localised.
  ///
  /// Kept separate from [IuxInputSemantics.label] for the same reason a button
  /// keeps the two apart: a checkbox in a table row can read "Include" and
  /// announce "Include the March invoice", because a screen-reader user has no
  /// column heading to read.
  final String label;

  /// What the control is called, whether it may change, and what is known
  /// about its value.
  ///
  /// The field model from IUX-009, unchanged. Availability, requirement and
  /// validation mean here exactly what they mean on a text field, so a form
  /// can disable or invalidate a checkbox and a text field the same way.
  final IuxInputDescriptor input;

  /// The current selection, owned by the parent.
  ///
  /// [IuxSelectionState.partial] is legal here and only here: it is how a
  /// "select all" reports that some of the things it stands for are chosen.
  final IuxSelectionState value;

  /// Called with the selection the user asked for.
  ///
  /// Non-nullable, deliberately. A nullable callback would be a second way to
  /// say "unavailable" alongside [IuxInputDescriptor.availability], and the
  /// two would eventually disagree — leaving a control that announces itself
  /// as available and does nothing. Unavailability has one home.
  ///
  /// Never called while the control is not editable, so the parent does not
  /// have to guard. Never called with [IuxSelectionState.partial]'s meaning:
  /// the user can only ask for yes or no.
  final ValueChanged<bool> onChanged;

  /// Whether this takes focus when first built.
  final bool autofocus;

  /// An externally owned focus node.
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) => _IuxSelectionControl(
        role: IuxSelectionRole.checkbox,
        value: value,
        label: label,
        input: input,
        onActivate: onChanged,
        autofocus: autofocus,
        focusNode: focusNode,
        indicator: (
          BuildContext context,
          IuxSelectionTokens tokens,
          IuxSelectionState state,
        ) =>
            _CheckboxIndicator(tokens: tokens, value: state),
      );
}

/// A setting that takes effect the moment it moves.
///
/// ```dart
/// IuxSwitch(
///   label: l10n.useMobileData,
///   input: const IuxInputDescriptor(
///     semantics: IuxInputSemantics(label: 'Use mobile data'),
///   ),
///   value: IuxSelectionState.fromSelected(settings.mobileData),
///   onChanged: settings.setMobileData,
/// )
/// ```
///
/// **Use it** for a setting the application applies immediately: a preference,
/// a mode, something the user can turn back the same way they turned it on.
///
/// **Do not use it** anywhere there is a Save button. A switch plus a
/// confirmation step is a contradiction — either the switch already did the
/// thing, in which case Save is a lie, or it did not, in which case the switch
/// is. Pick one: immediate means a switch, deferred means a checkbox.
///
/// **Do not use it** for an action either. "Delete my account" is not a
/// setting, and a control whose whole design says "this is reversible" is the
/// wrong shape for something that is not.
///
/// A switch carries its state in the *position* of the thumb, plus a tick when
/// it is on. That matters: colour alone would leave the two states
/// indistinguishable for a user who cannot separate the hues, and this is
/// precisely the control that has nothing else to read.
class IuxSwitch extends StatelessWidget {
  /// Creates a setting that applies immediately.
  const IuxSwitch({
    super.key,
    required this.label,
    required this.input,
    required this.value,
    required this.onChanged,
    this.autofocus = false,
    this.focusNode,
  })  : assert(
          label.length > 0,
          'A switch must say what it turns on. An unlabelled switch is a '
          'setting the user changes without knowing what they changed.',
        ),
        assert(
          value != IuxSelectionState.partial,
          'A switch has two positions. There is nowhere on it to render '
          '"partly on", and a user who saw such a state could not predict '
          'what moving it would do. If you are summarising a set of settings, '
          'use IuxCheckbox — it has a partial state — or state the count in '
          'text.',
        );

  /// The visible text, already localised.
  final String label;

  /// What the setting is called, and whether it may change.
  ///
  /// [IuxInputDescriptor.validation] is accepted but rarely meaningful here: a
  /// setting that applies immediately has already been accepted or rejected by
  /// the time the user lets go, so a validation message describes the past.
  final IuxInputDescriptor input;

  /// The current position, owned by the parent.
  ///
  /// Assert-checked against [IuxSelectionState.partial].
  final IuxSelectionState value;

  /// Called with the position the user asked for.
  ///
  /// The parent applies it and re-renders. The switch does not move itself:
  /// a switch that animated to its new position and then discovered the write
  /// had failed would have told the user their setting was saved.
  final ValueChanged<bool> onChanged;

  /// Whether this takes focus when first built.
  final bool autofocus;

  /// An externally owned focus node.
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) => _IuxSelectionControl(
        role: IuxSelectionRole.toggle,
        value: value,
        label: label,
        input: input,
        onActivate: onChanged,
        autofocus: autofocus,
        focusNode: focusNode,
        indicator: (
          BuildContext context,
          IuxSelectionTokens tokens,
          IuxSelectionState state,
        ) =>
            _SwitchIndicator(tokens: tokens, value: state),
      );
}

/// A choice among mutually exclusive options.
///
/// ```dart
/// IuxRadioGroup<Speed>(
///   label: l10n.deliverySpeed,
///   input: const IuxInputDescriptor(
///     semantics: IuxInputSemantics(label: 'Delivery speed'),
///     requirement: IuxInputRequirement.required,
///   ),
///   value: order.speed,
///   options: <IuxRadioOption<Speed>>[
///     IuxRadioOption<Speed>(value: Speed.standard, label: l10n.standard),
///     IuxRadioOption<Speed>(value: Speed.express, label: l10n.express),
///   ],
///   onChanged: controller.setSpeed,
/// )
/// ```
///
/// **Use it** when exactly one of a small, visible set applies, and when
/// seeing the alternatives is part of deciding. Two to about five options: past
/// that a list or a menu costs less to read.
///
/// **Do not use it** for an independent yes/no — that is [IuxCheckbox]. Do not
/// use it for a set the user may leave empty: a radio cannot be unchosen once
/// chosen, so "none of these" has to be an option in its own right, spelled
/// out in words the caller writes.
///
/// **There is no standalone radio widget, and there will not be one.** A radio
/// outside a group announces itself as one of one and never says what the
/// choice is about, and nothing in the layout tells a sighted user that two
/// distant radios are related. Making the group the only way to build one
/// removes an entire class of defect rather than documenting it.
///
/// **The group owns the answer.** [value] is the chosen option; the widget
/// derives each row's state from it, so two options can never both appear
/// chosen.
///
/// **[focusNode] lands on the first option, not on the group.** See the
/// parameter for why.
class IuxRadioGroup<T> extends StatefulWidget {
  /// Creates a mutually exclusive group.
  ///
  /// The assertions here catch the contradictions that can be decided from the
  /// arguments alone. Quietly repairing them would hide that the caller
  /// believed something untrue about their own data.
  IuxRadioGroup({
    super.key,
    required this.label,
    required this.input,
    required this.value,
    required this.options,
    required this.onChanged,
    this.focusNode,
  })  : assert(
          label.length > 0,
          'A group of radios must be named. Without a name the options are a '
          'list of words with no question attached, and a screen reader reads '
          'them that way.',
        ),
        assert(
          options.length >= 2,
          'A radio group needs at least two options. One radio is a control '
          'the user can switch on and never switch off, which is a checkbox '
          'that lost its off state — use IuxCheckbox instead.',
        ),
        assert(
          options.map((IuxRadioOption<T> o) => o.value).toSet().length ==
              options.length,
          'Two options share a value. They would both appear chosen at once, '
          'and choosing either would produce the same result — so the user is '
          'shown a decision that does not exist.',
        ),
        assert(
          value == null ||
              options.any((IuxRadioOption<T> o) => o.value == value),
          'The chosen value is not among the options, so nothing is marked. '
          'A group that shows no selection while the application believes it '
          'has one is how a form submits an answer the user never saw.',
        );

  /// The visible name of the choice, already localised.
  ///
  /// Rendered as a heading, so a screen-reader user can jump to it rather than
  /// arrowing through every option to find out what the question was.
  final String label;

  /// What the group is called, whether it may change, and what is known about
  /// the answer.
  ///
  /// Availability applies to every option at once. An option that is
  /// unavailable on its own says so through
  /// [IuxRadioOption.unavailabilityReason].
  final IuxInputDescriptor input;

  /// The chosen option, or null when the user has not answered yet.
  ///
  /// Null is a real state and it is the honest default for a required choice.
  /// Pre-selecting an option to avoid an empty group makes the application's
  /// guess indistinguishable from the user's answer.
  final T? value;

  /// The options, in the order they are read.
  ///
  /// Order carries meaning — cheapest first, safest first — so it is the
  /// caller's, never sorted here.
  final List<IuxRadioOption<T>> options;

  /// Called with the option the user chose.
  ///
  /// Not called when the user activates the option that is already chosen. A
  /// radio cannot be unchosen, so that gesture changes nothing, and reporting
  /// it would have parents re-running whatever a choice triggers.
  final ValueChanged<T> onChanged;

  /// An externally owned node, attached to the **first option**.
  ///
  /// A group is a question, and a question is not a control: focusing the
  /// column would put the user on a stop they cannot act on and would have to
  /// leave again, with nothing drawn to say where they are. Focusing the first
  /// option puts them on the first answer, which the next gesture gives.
  ///
  /// Nothing is lost by not landing on the group. The option sits inside the
  /// group's `SemanticsRole.radioGroup` container, so a screen reader
  /// announces the question and the option's position within it — "How fast do
  /// you need it, Standard, radio button, not checked, 1 of 2" on Android —
  /// rather than the option's word on its own.
  ///
  /// This exists because [input] can carry a rejection, and a rejected field
  /// has to be reachable from the thing that reports it. `IuxFormField`
  /// requires a node and uses it to send a user from an error summary to the
  /// field it names; before this parameter existed the node reached no widget
  /// at all, and activating that entry left focus on the summary — measured,
  /// not supposed. WCAG 2.2 SC 2.4.3 and SC 4.1.2.
  ///
  /// When the first option is individually unavailable the node goes to the
  /// first one that can take focus, because a node attached to a control that
  /// refuses focus is the same defect wearing a different hat. A group that is
  /// disabled as a whole cannot carry a rejection — the resolver asserts on it
  /// — so there is no case where the node has nowhere to go.
  final FocusNode? focusNode;

  @override
  State<IuxRadioGroup<T>> createState() => _IuxRadioGroupState<T>();
}

class _IuxRadioGroupState<T> extends State<IuxRadioGroup<T>> {
  /// The validation message this group arrived on screen carrying, if any.
  String? _messageOnArrival;

  /// Whether the message currently shown is a change rather than content.
  ///
  /// The rule the individual controls use, for the same reason: a message
  /// already there when the group appeared is content, not a status change,
  /// and announcing it competes with whatever put the group on screen
  /// (IUX-GUIDED-FORM-LIVE-001).
  bool get _messageIsNews {
    final String? message = widget.input.validation.message;
    return message != null && message != _messageOnArrival;
  }

  @override
  void initState() {
    super.initState();
    _messageOnArrival = widget.input.validation.message;
  }

  @override
  void didUpdateWidget(IuxRadioGroup<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.input.validation.message != _messageOnArrival) {
      _messageOnArrival = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String label = widget.label;
    final IuxInputDescriptor input = widget.input;
    final List<IuxRadioOption<T>> options = widget.options;
    final IuxSelectionTokens tokens =
        IuxSelectionResolver.resolve(context, input);
    final String? help = input.helpText;
    final String? message = input.validation.message;

    return IuxSemantics.radioGroup(
      // What lets Android announce "1 of 3" instead of leaving the user to
      // count. Named from the descriptor rather than from [label], so a group
      // can read "Delivery speed" and announce "How fast do you need it".
      label: input.semantics.label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _GroupHeading(label: label, tokens: tokens),
          if (help != null) ...<Widget>[
            const IuxGap(IuxSpacingStep.xxs),
            Text(help, style: tokens.helpStyle),
          ],
          const IuxGap.tight(),
          _SpacedColumn(
            children: <Widget>[
              for (int index = 0; index < options.length; index++)
                _option(options[index], index),
            ],
          ),
          if (message != null) ...<Widget>[
            const IuxGap.tight(),
            if (_messageIsNews)
              IuxSemantics.liveRegion(
                child: Text(message, style: tokens.messageStyle),
              )
            else
              IuxSemantics.group(
                child: Text(message, style: tokens.messageStyle),
              ),
          ],
        ],
      ),
    );
  }

  /// One option's row.
  ///
  /// [IuxRadioGroup.focusNode] goes to exactly one of them; see
  /// [_focusTargetIndex].
  Widget _option(IuxRadioOption<T> option, int index) => _IuxSelectionControl(
        role: IuxSelectionRole.radio,
        value: IuxSelectionState.fromSelected(option.value == widget.value),
        label: option.label,
        input: _optionInput(option),
        onActivate: (bool _) => widget.onChanged(option.value),
        autofocus: false,
        focusNode: index == _focusTargetIndex ? widget.focusNode : null,
        indicator: (
          BuildContext context,
          IuxSelectionTokens tokens,
          IuxSelectionState state,
        ) =>
            _RadioIndicator(tokens: tokens, value: state),
      );

  /// Which option adopts [IuxRadioGroup.focusNode].
  ///
  /// The first that can take focus. Attaching it to an unavailable option
  /// would leave a node that is attached and still refuses to be focused,
  /// which is the original defect with an extra step in it. The fallback of
  /// zero is unreachable while a group carrying a rejection cannot be disabled.
  int get _focusTargetIndex {
    final int index = widget.options.indexWhere(
      (IuxRadioOption<T> option) => _optionInput(option).isFocusable,
    );
    return index == -1 ? 0 : index;
  }

  /// The field descriptor one option renders under.
  ///
  /// The group's validation is deliberately not passed down. An unanswered
  /// required group is not five wrong options; painting every ring red would
  /// say each choice is invalid when the problem is that none was made, and
  /// the message under the group already says so in words.
  IuxInputDescriptor _optionInput(IuxRadioOption<T> option) =>
      IuxInputDescriptor(
        semantics: IuxInputSemantics(
          label: option.label,
          unavailabilityReason: option.unavailabilityReason,
        ),
        availability: option.isAvailable
            ? widget.input.availability
            : IuxInputAvailability.disabled,
        helpText: option.helpText,
      );
}

/// A named set of independent controls, spaced so they cannot be mis-tapped.
///
/// ```dart
/// IuxSelectionGroup(
///   label: l10n.notifyMeAbout,
///   children: <Widget>[replies, mentions, weeklyDigest],
/// )
/// ```
///
/// **Use it** around a column of [IuxCheckbox] or [IuxSwitch] that belong
/// together. It does two things a `Column` does not: it names the set, so a
/// screen-reader user is told what the answers are about, and it keeps at
/// least [kIuxMinimumTargetSpacing] between neighbouring targets. Two 48-pixel
/// targets that touch still produce mis-taps — a finger landing near the seam
/// has no margin — which is why WCAG 2.2 SC 2.5.8 treats spacing and size as
/// one requirement.
///
/// **Do not use it** for a mutually exclusive choice: [IuxRadioGroup] already
/// is one, and it enforces the exclusivity this widget cannot. Do not use it
/// as a general layout box either — it exists to make one specific defect
/// unrepresentable, not to stack widgets.
///
/// [label] is required. A group nobody named is a group a screen-reader user
/// experiences as loose controls, and if a set of controls cannot be given a
/// name they probably do not belong together. Where the intent is really just
/// spacing — a row of chips, a pair of buttons — use `IuxTargetSpacing`.
class IuxSelectionGroup extends StatelessWidget {
  /// Creates a named, correctly spaced set of controls.
  IuxSelectionGroup({
    super.key,
    required this.label,
    required this.children,
  })  : assert(
          label.length > 0,
          'A group must be named. See the class documentation: if there is no '
          'name for this set, it is probably not a set.',
        ),
        assert(
          children.length > 0,
          'An empty group renders a heading over nothing, which reads as '
          'content that failed to load.',
        );

  /// The visible name of the set, already localised.
  final String label;

  /// The controls, in the order they are read.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // Resolved from a descriptor built here rather than from a second styling
    // path, so a group heading looks the same whatever encloses it.
    final IuxSelectionTokens tokens = IuxSelectionResolver.resolve(
      context,
      IuxInputDescriptor(semantics: IuxInputSemantics(label: label)),
    );

    return IuxSemantics.group(
      label: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _GroupHeading(label: label, tokens: tokens),
          const IuxGap.tight(),
          _SpacedColumn(children: children),
        ],
      ),
    );
  }
}

/// The row every selection control is: an indicator, a label, one target.
///
/// Private on purpose. It is the answer to "what does an IUX selection control
/// behave like", and there is one answer: the checkbox, the switch and the
/// radio must not be able to drift apart on where the target starts, what a
/// disabled control announces, or whether the label is tappable. Exposing it
/// would invite a fourth control that skips one of them.
class _IuxSelectionControl extends StatefulWidget {
  const _IuxSelectionControl({
    required this.role,
    required this.value,
    required this.label,
    required this.input,
    required this.onActivate,
    required this.autofocus,
    required this.focusNode,
    required this.indicator,
  });

  final IuxSelectionRole role;
  final IuxSelectionState value;
  final String label;
  final IuxInputDescriptor input;

  /// Called with the selection the user asked for.
  final ValueChanged<bool> onActivate;

  final bool autofocus;
  final FocusNode? focusNode;

  /// Builds the mark, given the appearance resolved for the current state.
  final Widget Function(
    BuildContext context,
    IuxSelectionTokens tokens,
    IuxSelectionState state,
  ) indicator;

  @override
  State<_IuxSelectionControl> createState() => _IuxSelectionControlState();
}

class _IuxSelectionControlState extends State<_IuxSelectionControl> {
  bool _pressed = false;
  bool _hovered = false;

  /// The validation message this control arrived on screen carrying, if any.
  String? _messageOnArrival;

  /// Whether the message currently shown is a change rather than content.
  ///
  /// A live region announces a *status change*. A message that was already
  /// there when the control appeared is not one: it is content, read when the
  /// user reaches it, and announcing it puts an utterance in the same frame as
  /// whatever mounted the control — which is how a stepped form came to speak
  /// twice for one step change (IUX-GUIDED-FORM-LIVE-001). The message keeps
  /// its own labelled node either way, so nothing becomes unreachable.
  bool get _messageIsNews {
    final String? message = widget.input.validation.message;
    return message != null && message != _messageOnArrival;
  }

  @override
  void initState() {
    super.initState();
    _messageOnArrival = widget.input.validation.message;
  }

  @override
  void didUpdateWidget(_IuxSelectionControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Any message that is not the one this control arrived with is news, and
    // so is every message after it.
    if (widget.input.validation.message != _messageOnArrival) {
      _messageOnArrival = null;
    }
  }

  /// Whether a gesture here would change anything.
  ///
  /// A chosen radio is excluded: it is available, it is focusable, and
  /// activating it is a no-op, because a radio cannot be unchosen. Reporting
  /// that gesture would re-run whatever the parent does on a choice.
  bool get _canActivate =>
      widget.input.isEditable &&
      !(widget.role == IuxSelectionRole.radio && widget.value.isSelected);

  void _handleActivate() {
    if (!_canActivate) return;
    widget.onActivate(widget.value.requestedSelection);
  }

  @override
  Widget build(BuildContext context) {
    final IuxSelectionTokens tokens = IuxSelectionResolver.resolve(
      context,
      widget.input,
      hovered: _hovered && _canActivate,
      pressed: _pressed && _canActivate,
    );

    final String? help = widget.input.helpText;

    final Widget texts = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // No line limit and no ellipsis, at any text scale. A truncated
        // question is a question the user answers without having read it, and
        // truncation gets worse exactly when someone has enlarged their text.
        Text(widget.label, style: tokens.labelStyle),
        if (help != null) ...<Widget>[
          const IuxGap(IuxSpacingStep.xxs),
          Text(help, style: tokens.helpStyle),
        ],
      ],
    );

    final Widget row = Row(
      // Aligned to the top so a label wrapping to three lines keeps its
      // indicator beside the first one, where reading starts.
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: tokens.lineExtent,
          child: Center(
            child: widget.indicator(context, tokens, widget.value),
          ),
        ),
        SizedBox(width: tokens.gap),
        // Flexible rather than fixed: without it, enlarging the text turns a
        // wrapping label into an overflow.
        Expanded(child: texts),
      ],
    );

    // One node named twice. The announced node and the focusable region have to
    // be the same focus node, or the platform is told about a focus that lives
    // somewhere else — IUX-A11Y-FOCUS-001, which reached this helper as well as
    // IuxSemantics.action.
    final Widget control = IuxFocusNodeOwner(
      focusNode: widget.focusNode,
      debugLabel: widget.input.semantics.label,
      builder: (BuildContext context, FocusNode node) => _selectionSemantics(
        role: widget.role,
        value: widget.value,
        input: widget.input,
        // Registered on the node itself, because everything below it is excluded
        // from the semantic tree. Without this the control would be announced
        // correctly and refuse to respond to a screen reader's activation.
        onTap: _canActivate ? _handleActivate : null,
        // The same exclusion takes the Focus widget's own annotations, so the
        // control declared no focusable state at all and assistive technology had
        // no way to move accessibility focus onto it.
        focusNode: node,
        focusable: widget.input.isFocusable,
        child: IuxFocusable(
          autofocus: widget.autofocus,
          focusNode: node,
          canRequestFocus: widget.input.isFocusable,
          onActivate: _canActivate ? _handleActivate : null,
          child: Listener(
            // A Listener, not a second GestureDetector. Pointer events never
            // enter the gesture arena, so press feedback cannot steal the tap
            // from the target beneath it.
            onPointerDown: (PointerDownEvent _) => _setPressed(true),
            onPointerUp: (PointerUpEvent _) => _setPressed(false),
            onPointerCancel: (PointerCancelEvent _) => _setPressed(false),
            child: MouseRegion(
              onEnter: (_) => _setHovered(true),
              onExit: (_) => _setHovered(false),
              child: AnimatedContainer(
                duration: tokens.motion.duration,
                curve: tokens.motion.curve,
                // A decoration that is always present, holding a colour that
                // may be null — not a colour that may be null. The difference
                // is the whole control working or not.
                //
                // `Container` inserts a `DecoratedBox` only when it has a
                // decoration. Passing `color: tokens.rowHighlight` gave it one
                // only while pressed, so the first `onPointerDown` grew a
                // `DecoratedBox` where there had been none and reparented
                // everything below it — including the `GestureDetector` inside
                // `IuxTapTarget`, whose `State` was disposed along with the
                // recognizer tracking the pointer. The `up` then landed
                // nowhere and the control never changed state.
                //
                // Wrapping the colour in a `BoxDecoration` keeps the box in
                // the tree at rest, where it paints nothing, so the shape of
                // the tree no longer changes under the pointer. The control
                // still inherits the surface it was placed on, which is why
                // `rowHighlight` is nullable to begin with.
                //
                // It survived the suite because `tester.tap()` sends `down`
                // and `up` with no frame between them, so the rebuild never
                // landed mid-gesture. A finger always leaves a frame. See the
                // regression test in `test/components/iux_selection_test.dart`.
                decoration: BoxDecoration(color: tokens.rowHighlight),
                // Outside the tap target, so the tint covers the region that
                // actually responds rather than only the part that is painted.
                child: IuxTapTarget(
                  enabled: _canActivate,
                  onTap: _canActivate ? _handleActivate : null,
                  child: row,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final String? message = widget.input.validation.message;
    if (message == null) return control;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        control,
        const IuxGap.tight(),
        // Its own node, outside the control's. Merging it into the label would
        // have the error read out again every time the user passes the
        // control; a live region announces it when it appears and then lets
        // the user re-read it on their own terms. "When it appears" is what
        // [_messageIsNews] makes true — a message already there when the
        // control arrived keeps the node and loses only the flag.
        if (_messageIsNews)
          IuxSemantics.liveRegion(
            child: Text(message, style: tokens.messageStyle),
          )
        else
          IuxSemantics.group(
            child: Text(message, style: tokens.messageStyle),
          ),
      ],
    );
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  void _setHovered(bool value) {
    if (_hovered == value) return;
    setState(() => _hovered = value);
  }
}

/// The semantic node a selection control presents.
///
/// The whole node comes from the runtime, so a checkbox, a switch and a radio
/// cannot disagree about what a disabled or a read-only one announces. What is
/// left here is the translation: the field model's availability and the
/// component's own selection state, expressed in the vocabulary the runtime
/// speaks.
Widget _selectionSemantics({
  required IuxSelectionRole role,
  required IuxSelectionState value,
  required IuxInputDescriptor input,
  required VoidCallback? onTap,
  required FocusNode? focusNode,
  required bool focusable,
  required Widget child,
}) =>
    IuxSemantics.selection(
      role: role,
      value: _announced(value),
      label: input.semantics.label,
      hint: input.accessibleHint,
      enabled: input.availability != IuxInputAvailability.disabled,
      // Distinct from disabled. A read-only control stays in the focus order
      // and still announces its value; a disabled one leaves the order
      // entirely, and a value the user cannot reach is a value they do not
      // have.
      readOnly: input.availability == IuxInputAvailability.readOnly,
      isRequired: input.isRequired,
      onTap: onTap,
      focusNode: focusNode,
      focusable: focusable,
      child: child,
    );

/// The component's selection state, in the runtime's announcement vocabulary.
///
/// Two enums rather than one because the runtime sits below the components and
/// must not know that a checkbox widget exists. The translation is written
/// once, here, so it cannot be written backwards in three places.
IuxSelectionValue _announced(IuxSelectionState value) => switch (value) {
      IuxSelectionState.selected => IuxSelectionValue.selected,
      IuxSelectionState.partial => IuxSelectionValue.partial,
      IuxSelectionState.unselected => IuxSelectionValue.unselected,
    };

/// A square box carrying a tick, a dash, or nothing.
///
/// Square, and it stays square. Shape is what tells a checkbox from a radio
/// before either is read; a fully rounded checkbox is a radio that behaves
/// differently, and the user finds out by getting it wrong.
class _CheckboxIndicator extends StatelessWidget {
  const _CheckboxIndicator({required this.tokens, required this.value});

  final IuxSelectionTokens tokens;
  final IuxSelectionState value;

  @override
  Widget build(BuildContext context) {
    // A tick for chosen, a dash for partly chosen, nothing for unchosen. The
    // mark — not the fill colour — is what carries the state: a user who
    // cannot separate the two hues still sees the difference between a mark
    // and an empty box.
    final IconData? mark = switch (value) {
      IuxSelectionState.selected => Icons.check,
      IuxSelectionState.partial => Icons.remove,
      IuxSelectionState.unselected => null,
    };
    final bool filled = mark != null;

    return AnimatedContainer(
      duration: tokens.motion.duration,
      curve: tokens.motion.curve,
      width: tokens.indicatorSize,
      height: tokens.indicatorSize,
      decoration: BoxDecoration(
        color: tokens.fillFor(selected: filled),
        borderRadius: BorderRadius.circular(tokens.checkboxRadius),
        border: Border.all(
          color: tokens.outlineFor(selected: filled),
          width: tokens.borderWidth,
        ),
      ),
      child: mark == null
          ? null
          : Icon(
              mark,
              size: tokens.markSize,
              color: tokens.markColor,
              // Already scaled once, by the resolver, through the same runtime
              // every other IUX component reads. Letting Flutter scale it again
              // would enlarge the tick past the box holding it.
              applyTextScaling: false,
            ),
    );
  }
}

/// A ring with a dot inside it when the option is chosen.
class _RadioIndicator extends StatelessWidget {
  const _RadioIndicator({required this.tokens, required this.value});

  final IuxSelectionTokens tokens;
  final IuxSelectionState value;

  @override
  Widget build(BuildContext context) {
    final bool selected = value.isSelected;

    return SizedBox(
      width: tokens.indicatorSize,
      height: tokens.indicatorSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: tokens.outlineFor(selected: selected),
            width: tokens.borderWidth,
          ),
        ),
        child: Center(
          // The dot grows in rather than fading: at zero size there is nothing
          // to mistake for a faint dot, so the two states stay unambiguous at
          // every frame. Under no motion it simply appears.
          child: AnimatedContainer(
            duration: tokens.motion.duration,
            curve: tokens.motion.curve,
            width: selected ? tokens.dotSize : 0,
            height: selected ? tokens.dotSize : 0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tokens.selectedFill,
            ),
          ),
        ),
      ),
    );
  }
}

/// A track with a thumb at one end of it.
class _SwitchIndicator extends StatelessWidget {
  const _SwitchIndicator({required this.tokens, required this.value});

  final IuxSelectionTokens tokens;
  final IuxSelectionState value;

  @override
  Widget build(BuildContext context) {
    final bool on = value.isSelected;
    final double inset = math.max(
      0,
      (tokens.indicatorSize - tokens.borderWidth * 2 - tokens.thumbSize) / 2,
    );

    return AnimatedContainer(
      duration: tokens.motion.duration,
      curve: tokens.motion.curve,
      width: tokens.trackLength,
      height: tokens.indicatorSize,
      padding: EdgeInsets.symmetric(horizontal: inset),
      decoration: BoxDecoration(
        color: on ? tokens.selectedFill : tokens.trackFill,
        borderRadius: BorderRadius.circular(tokens.indicatorSize / 2),
        border: Border.all(
          color: tokens.outlineFor(selected: on),
          width: tokens.borderWidth,
        ),
      ),
      child: AnimatedAlign(
        duration: tokens.motion.duration,
        curve: tokens.motion.curve,
        // Directional. "On" belongs at the end of the reading direction, so an
        // Arabic interface puts it on the left without this widget knowing
        // which language it is in — a switch that reads backwards is a setting
        // the user turns off believing they turned it on.
        alignment: on
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: Container(
          width: tokens.thumbSize,
          height: tokens.thumbSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on ? tokens.markColor : tokens.borderColor,
          ),
          // A tick on the thumb when the switch is on. The position already
          // says which way it is set for someone who can see the whole track;
          // the tick says it for someone reading through a magnifier, who may
          // only have one end of the track in view.
          child: on
              ? Icon(
                  Icons.check,
                  size: tokens.thumbSize * _thumbMarkRatio,
                  color: tokens.selectedFill,
                  applyTextScaling: false,
                )
              : null,
        ),
      ),
    );
  }
}

/// The name of a group, announced as a heading.
class _GroupHeading extends StatelessWidget {
  const _GroupHeading({required this.label, required this.tokens});

  final String label;
  final IuxSelectionTokens tokens;

  @override
  Widget build(BuildContext context) => IuxSemantics.header(
        label: label,
        child: Text(label, style: tokens.groupStyle),
      );
}

/// A column whose children never sit closer than the target-spacing floor.
///
/// A `Column` with no separation lets two 48-pixel targets touch, and a finger
/// landing near the seam hits whichever one it drifts towards. The floor is
/// applied here so the radio group and the selection group cannot end up
/// applying different ones.
class _SpacedColumn extends StatelessWidget {
  const _SpacedColumn({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final double gap = math.max(
      IuxGeometryTheme.of(context).spacingXs,
      kIuxMinimumTargetSpacing,
    );

    final List<Widget> spaced = <Widget>[];
    for (int index = 0; index < children.length; index++) {
      if (index > 0) spaced.add(SizedBox(height: gap));
      spaced.add(children[index]);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: spaced,
    );
  }
}
