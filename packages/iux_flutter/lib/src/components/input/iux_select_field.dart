import 'package:flutter/material.dart';

import '../../accessibility/iux_focus.dart';
import '../../accessibility/iux_focus_ownership.dart';
import '../../accessibility/iux_semantics.dart';
import '../../accessibility/iux_touch_target.dart';
import '../../inputs/iux_input_descriptor.dart';
import '../../inputs/iux_input_model.dart';
import '../../inputs/iux_input_theme.dart';
import '../../themes/extensions/iux_geometry_theme.dart';
import '../selection/iux_selection_controls.dart';
import '../selection/iux_selection_model.dart';
import 'iux_field_parts.dart';

/// One answer chosen from a list too long to show as a set of radio buttons.
///
/// **This exists because `IuxRadioGroup` stops working, not because a dropdown
/// looks tidier.** A radio group shows every option at once, which is the best
/// arrangement a chooser can have: nothing is hidden, nothing has to be opened,
/// and a screen-reader user hears "1 of 5" without acting. Past somewhere
/// around a dozen options that stops being a help and becomes a wall, and this
/// component trades the overview for a shorter resting state.
///
/// It takes **exactly the arguments `IuxRadioGroup` takes**, so a question that
/// outgrows one becomes the other by changing the class name and nothing else.
/// That is deliberate: the moment the two APIs diverge, the choice between them
/// stops being about the user and starts being about migration cost.
///
/// ```dart
/// IuxSelectField<String>(
///   label: l10n.country,
///   input: const IuxInputDescriptor(
///     semantics: IuxInputSemantics(label: 'Country'),
///     requirement: IuxInputRequirement.required,
///   ),
///   value: form.country,
///   options: countries,
///   onChanged: form.setCountry,
/// )
/// ```
///
/// ## When not to use it
///
/// - **Fewer than about a dozen options** — use `IuxRadioGroup`. Hiding five
///   options behind a control the user has to open is a cost with nothing
///   bought.
/// - **More than about thirty** — a list nobody can scan is not fixed by
///   collapsing it. Those need search, which is `IuxSearchField` and a result
///   list, not this.
/// - **Several answers at once** — that is a set of `IuxCheckbox`, and a
///   control that looks like this one but accepts many answers is how a user
///   comes to believe they have chosen one thing when they have chosen three.
/// - **An action** — `IuxButton`. This holds a value; it does not do anything.
///
/// ## What it announces
///
/// Collapsed, one stop carrying the question as its name and the chosen
/// option as its **value**, with a collapsed state and an activate action. The
/// two strings stay separate: the platform joins a name to a value in the
/// user's own language, and a framework that concatenates them has written a
/// sentence in a language it cannot read.
///
/// Expanded, the control *becomes* `IuxRadioGroup` — the same options, the same
/// mutually-exclusive group semantics, the same "1 of n". Nothing about the
/// open state is this component's own invention, which is the point: the
/// arrangement a screen-reader user meets is one that was already tested.
class IuxSelectField<T> extends StatefulWidget {
  /// Creates a select for [options], showing [value] as the current answer.
  ///
  /// Contradictions decidable from these values alone fail on an assertion
  /// rather than being quietly corrected, for the reason `IuxRadioGroup` gives:
  /// a chooser that shows no selection while the application believes it has
  /// one is how a form submits an answer the user never saw.
  IuxSelectField({
    super.key,
    required this.label,
    required this.input,
    required this.value,
    required this.options,
    required this.onChanged,
    this.placeholder,
    this.variant,
    this.focusNode,
  })  : assert(
          options.length > 0,
          'A select with no options is a question with no answers. Render the '
          'reason there are none — IuxEmptyState — rather than a control the '
          'user can open and find empty.',
        ),
        assert(
          label.length > 0,
          'A choice must be named. Unnamed, it is announced as "combo box" '
          'and nothing else.',
        ),
        assert(
          placeholder == null || placeholder.length > 0,
          'An empty placeholder reserves a line and says nothing. Pass null.',
        ),
        assert(
          value == null ||
              options.any((IuxRadioOption<T> o) => o.value == value),
          'The chosen value is not among the options, so the collapsed control '
          'shows its placeholder while the application believes it has an '
          'answer. That is how a form submits a value the user never saw, and '
          'it is the same refusal IuxRadioGroup makes.',
        );

  /// The visible name of the choice, already localised.
  ///
  /// Rendered as a heading when the options are open, exactly as
  /// `IuxRadioGroup` renders it, so a screen-reader user can jump to the
  /// question rather than arrowing through options to infer it.
  final String label;

  /// What the choice is called, whether it may change, and what is known about
  /// the answer.
  ///
  /// Availability applies to the whole control. An option unavailable on its
  /// own says so through [IuxRadioOption.unavailabilityReason].
  final IuxInputDescriptor input;

  /// The chosen option, or null when the user has not answered yet.
  ///
  /// Null is a real state and the honest default for a required choice.
  /// Pre-selecting to avoid an empty control makes the application's guess
  /// indistinguishable from the user's answer.
  final T? value;

  /// The options, in the order they are read.
  ///
  /// Order carries meaning — commonest first, cheapest first — so it is the
  /// caller's and is never sorted here.
  final List<IuxRadioOption<T>> options;

  /// Called with the option the user chose.
  final ValueChanged<T> onChanged;

  /// What the collapsed control shows while there is no answer, already
  /// localised.
  ///
  /// Visible only. It is never announced as the value, because "Choose a
  /// country" is not an answer and a screen reader that reads it as one tells
  /// the user the question is done.
  final String? placeholder;

  /// The field's visual variant, or null to take the theme's default.
  final IuxInputVariant? variant;

  /// An externally owned focus node for the collapsed control.
  final FocusNode? focusNode;

  @override
  State<IuxSelectField<T>> createState() => _IuxSelectFieldState<T>();
}

class _IuxSelectFieldState<T> extends State<IuxSelectField<T>> {
  bool _expanded = false;
  bool _hovered = false;

  /// The option matching the current value, or null when unanswered.
  ///
  /// Looked up rather than remembered, so a value the parent changes underneath
  /// this widget cannot leave a stale label on screen.
  IuxRadioOption<T>? get _chosen {
    for (final IuxRadioOption<T> option in widget.options) {
      if (option.value == widget.value) return option;
    }
    return null;
  }

  void _setHovered(bool hovered) {
    if (_hovered == hovered) return;
    setState(() => _hovered = hovered);
  }

  void _toggle() => setState(() => _expanded = !_expanded);

  void _handleChanged(T chosen) {
    // Collapsing is not a second decision the user has to make. A radio cannot
    // be un-chosen, so the list has nothing left to offer once it is answered,
    // and leaving it open would hold the page open around a question that is
    // finished.
    setState(() => _expanded = false);
    widget.onChanged(chosen);
  }

  @override
  Widget build(BuildContext context) {
    // Open, this *is* a radio group: the same options, the same group
    // semantics, the same heading, and none of it re-implemented here. The
    // arrangement a screen-reader user meets when the list is open is one that
    // already had tests before this component existed.
    if (_expanded) {
      return IuxRadioGroup<T>(
        label: widget.label,
        input: widget.input,
        value: widget.value,
        options: widget.options,
        onChanged: _handleChanged,
        focusNode: widget.focusNode,
      );
    }

    final IuxInputTokens tokens = IuxInputResolver.resolve(
      context,
      widget.input,
      variant: widget.variant,
      hovered: _hovered,
      focused: false,
    );
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);

    // The focus ring reserves its own space whether or not it is drawn, so
    // gaining focus never moves anything — and the supporting lines are
    // indented to match, or the name sits beside the box it names.
    final double ringInset = geometry.focus.width + geometry.focus.gap;
    final EdgeInsetsDirectional textInset =
        EdgeInsetsDirectional.only(start: ringInset);
    final double gap = tokens.gap - ringInset;
    final double supportingGap = gap < 0 ? 0 : gap;

    final IuxRadioOption<T>? chosen = _chosen;
    final String? message = widget.input.validation.message;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: textInset,
          // Excluded because the control's own node carries the same string as
          // its name. Left in, the question would be read once as a heading and
          // once as the name of the control below it.
          child: IuxSemantics.decorative(
            child: Text(widget.label, style: tokens.labelStyle),
          ),
        ),
        SizedBox(height: supportingGap),
        // One node named twice. The announced node and the focusable region
        // must share a focus node, or the platform is told about a focus that
        // lives somewhere else — IUX-A11Y-FOCUS-001.
        IuxFocusNodeOwner(
          focusNode: widget.focusNode,
          debugLabel: widget.input.semantics.label,
          builder: (BuildContext context, FocusNode node) =>
              IuxSemantics.choice(
            label: widget.label,
            // The chosen option's own label, never the placeholder. A
            // placeholder announced as a value tells the user the question has
            // been answered.
            value: chosen?.label,
            expanded: false,
            hint: widget.input.accessibleHint,
            enabled: widget.input.isEditable,
            readOnly:
                widget.input.availability == IuxInputAvailability.readOnly,
            isRequired: widget.input.isRequired,
            // Registered on the node itself, because everything below it is
            // excluded from the semantic tree. Without this the control is
            // announced correctly and refuses a screen reader's activation.
            onTap: widget.input.isEditable ? _toggle : null,
            focusNode: node,
            focusable: widget.input.isFocusable,
            child: IuxFocusable(
              focusNode: node,
              canRequestFocus: widget.input.isFocusable,
              onActivate: widget.input.isEditable ? _toggle : null,
              borderRadius: BorderRadius.circular(resolveFieldRadius(tokens)),
              child: MouseRegion(
                onEnter: (_) => _setHovered(true),
                onExit: (_) => _setHovered(false),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.input.isEditable ? _toggle : null,
                  child: IuxTapTarget(
                    child: IuxFieldContainer(
                      tokens: tokens,
                      geometry: geometry,
                      child: _IuxSelectRow(
                        tokens: tokens,
                        // The placeholder is shown, never announced. The two
                        // are different questions, and this is the only place
                        // they are allowed to differ.
                        text: chosen?.label ?? widget.placeholder,
                        isAnswered: chosen != null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Help text and the validation message are both shown and neither
        // replaces the other, for the reason the text field gives: swapping the
        // instruction for the error removes the sentence explaining how to
        // answer correctly at the moment the user has proved they need it.
        if (widget.input.helpText case final String help) ...<Widget>[
          SizedBox(height: supportingGap),
          Padding(
            padding: textInset,
            child: Text(help, style: tokens.helpStyle),
          ),
        ],
        if (message != null) ...<Widget>[
          SizedBox(height: supportingGap),
          Padding(
            padding: textInset,
            child: IuxFieldValidationMessage(
              message: message,
              style: tokens.messageStyle,
              // Always announced here, unlike the text field's, because a
              // collapsed select has no editing session during which the
              // message could have been on screen already.
              announce: true,
            ),
          ),
        ],
      ],
    );
  }
}

/// The chosen label, or the placeholder, beside the mark that says this opens.
class _IuxSelectRow extends StatelessWidget {
  const _IuxSelectRow({
    required this.tokens,
    required this.text,
    required this.isAnswered,
  });

  final IuxInputTokens tokens;
  final String? text;
  final bool isAnswered;

  @override
  Widget build(BuildContext context) {
    // An unanswered control is drawn in the placeholder style and an answered
    // one in the value style. That difference is not the only signal the
    // answer exists — the announced value is, and so is the word itself — so
    // it carries no meaning colour alone would have to carry.
    final TextStyle style =
        isAnswered ? tokens.valueStyle : tokens.placeholderStyle;

    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            text ?? '',
            style: style,
            // Wraps rather than clips: a long option name at 200% text is the
            // ordinary case, not the exceptional one.
            softWrap: true,
          ),
        ),
        SizedBox(width: tokens.gap),
        Icon(
          Icons.expand_more,
          size: tokens.valueStyle.fontSize,
          color: tokens.valueStyle.color,
          // Scaled once, through the runtime every other IUX component reads.
          applyTextScaling: false,
        ),
      ],
    );
  }
}
