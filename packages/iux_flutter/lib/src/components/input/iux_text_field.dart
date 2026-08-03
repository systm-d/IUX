import 'dart:math' as math;
// SemanticsInputType is imported by `package:flutter/semantics.dart` and not
// re-exported by it, so `dart:ui` is the only way to name the type. It is
// worth the unusual import: it is what tells a screen reader that a box holds
// an email address rather than prose, which changes how the value is spoken.
import 'dart:ui' show SemanticsInputType;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../accessibility/iux_accessibility.dart';
import '../../accessibility/iux_focus.dart';
import '../../accessibility/iux_semantics.dart';
import '../../inputs/iux_input_descriptor.dart';
import '../../inputs/iux_input_model.dart';
import '../../inputs/iux_input_theme.dart';
import '../../layout/iux_spacing_primitives.dart';
import '../../motion/iux_motion_policy.dart';
import '../../motion/iux_motion_role.dart';
import '../../themes/extensions/iux_geometry_theme.dart';

/// How many lines a multi-line field shows before it starts to grow.
///
/// One line would be a lie: a field that looks like every other field but
/// accepts paragraphs gives the user no way to know they may write more than a
/// sentence. Three is enough to read as "there is room here" without reserving
/// a third of a phone screen for a field that may stay empty.
const int _kMultilineMinimumLines = 3;

/// What kind of thing a field asks for.
///
/// One decision instead of five. A caller who picks [IuxTextContent.email]
/// gets the email keyboard, capitalisation off, autocorrect off, the email
/// autofill hint and the email input type in the semantic tree — together,
/// every time. Set separately, those five are five chances to ship the field
/// that capitalises the first letter of an address and then rejects it.
///
/// This is a description of the *content*, not of the keyboard. A caller says
/// what is being asked for; the widget decides what that implies, and can
/// change its mind later without a migration.
///
/// There is no `password` value. An obscured field owes the user a way to
/// reveal what they typed — otherwise a motor or dyslexic user cannot check a
/// long password before submitting it — and that reveal control is a second
/// interactive element with its own name, state and announcement. It is a
/// component, not an enum value.
///
/// There is no `number` value either. "A number" is three different fields: a
/// quantity, a formatted code, and a currency amount, each with its own
/// keyboard, grouping and validation. Naming them all `number` would give the
/// caller a value that is right a third of the time.
enum IuxTextContent {
  /// Free text with no particular shape. The default.
  text,

  /// A person's name.
  ///
  /// Capitalises words and turns autocorrect off: a name is not a dictionary
  /// word, and autocorrect renaming someone is a memorable way to lose them.
  name,

  /// An email address.
  email,

  /// A telephone number.
  phone,

  /// A web address.
  url,

  /// Several lines of prose.
  ///
  /// The only value that changes the shape of the field rather than only the
  /// keyboard: it opens at [_kMultilineMinimumLines] lines and grows.
  multiline,
}

/// Resolves one content kind into the several settings it implies.
///
/// Private on purpose. The public API is the intent; the platform types it
/// maps to are an implementation detail, and exposing them would let a call
/// site keep the intent while contradicting it.
extension _IuxTextContentResolution on IuxTextContent {
  TextInputType get keyboardType => switch (this) {
        IuxTextContent.text => TextInputType.text,
        IuxTextContent.name => TextInputType.name,
        IuxTextContent.email => TextInputType.emailAddress,
        IuxTextContent.phone => TextInputType.phone,
        IuxTextContent.url => TextInputType.url,
        IuxTextContent.multiline => TextInputType.multiline,
      };

  TextCapitalization get capitalization => switch (this) {
        IuxTextContent.text ||
        IuxTextContent.multiline =>
          TextCapitalization.sentences,
        IuxTextContent.name => TextCapitalization.words,
        IuxTextContent.email ||
        IuxTextContent.phone ||
        IuxTextContent.url =>
          TextCapitalization.none,
      };

  bool get autocorrect => switch (this) {
        IuxTextContent.text || IuxTextContent.multiline => true,
        IuxTextContent.name ||
        IuxTextContent.email ||
        IuxTextContent.phone ||
        IuxTextContent.url =>
          false,
      };

  /// The platform autofill hints, which spare a user with a motor impairment
  /// an entire address typed one character at a time.
  List<String>? get autofillHints => switch (this) {
        IuxTextContent.text || IuxTextContent.multiline => null,
        IuxTextContent.name => const <String>[AutofillHints.name],
        IuxTextContent.email => const <String>[AutofillHints.email],
        IuxTextContent.phone => const <String>[AutofillHints.telephoneNumber],
        IuxTextContent.url => const <String>[AutofillHints.url],
      };

  int? get maxLines => this == IuxTextContent.multiline ? null : 1;

  int? get minLines =>
      this == IuxTextContent.multiline ? _kMultilineMinimumLines : null;

  /// What assistive technology is told the field holds.
  SemanticsInputType get semanticInputType => switch (this) {
        IuxTextContent.email => SemanticsInputType.email,
        IuxTextContent.phone => SemanticsInputType.phone,
        IuxTextContent.url => SemanticsInputType.url,
        IuxTextContent.text ||
        IuxTextContent.name ||
        IuxTextContent.multiline =>
          SemanticsInputType.text,
      };
}

/// A single value the user types, with its name, its instruction and whatever
/// the parent has decided about it.
///
/// ```dart
/// IuxTextField(
///   input: IuxInputDescriptor(
///     semantics: IuxInputSemantics(label: l10n.emailAddress),
///     requirement: IuxInputRequirement.required,
///     helpText: l10n.emailHelp,
///     validation: state.emailValidation,
///   ),
///   content: IuxTextContent.email,
///   controller: _email,
///   onChanged: controller.emailChanged,
/// )
/// ```
///
/// **Use it** wherever the user types something the application has to keep.
///
/// **Do not use it** for a password — see [IuxTextContent] — for a value that
/// is chosen rather than typed (that is IUX-011's selection controls), or as a
/// display for text nobody may change. A field that can never be edited under
/// any circumstance is a label and a value, not a control; reach for
/// [IuxInputAvailability.readOnly] only when the value is genuinely a field
/// that happens to be fixed right now.
///
/// **The parent owns everything.** The value lives in [controller], and
/// whether it is acceptable lives in [IuxInputDescriptor.validation]. This
/// widget has no `validator`, and it never decides that a value is right or
/// wrong: a field that validated itself would eventually reject something the
/// server accepts, and the user would be told two different things by the same
/// application.
///
/// **The label is always visible and always announced.** It is
/// [IuxInputSemantics.label], shown above the field and attached to it in the
/// semantic tree. There is no floating-label mode and no label-as-placeholder
/// mode, because a name that disappears when typing starts leaves a user who
/// has forgotten what the field was with no way back — and that is exactly the
/// moment they are checking what they entered.
///
/// There is no colour, radius, border or duration parameter, and there will
/// not be one. An API that accepts a colour has already lost the contrast
/// guarantee: the theme can no longer be held responsible for something a call
/// site overrode.
class IuxTextField extends StatefulWidget {
  /// Creates a text field.
  const IuxTextField({
    super.key,
    required this.input,
    required this.controller,
    required this.onChanged,
    this.placeholder,
    this.content = IuxTextContent.text,
    this.variant,
    this.autofocus = false,
    this.focusNode,
  }) : assert(
          placeholder == null || placeholder.length > 0,
          'An empty placeholder is not a placeholder. Pass null instead, so '
          'the field does not fade an empty string in and out.',
        );

  /// What the field is, what may be done to it, and what is known about its
  /// value.
  ///
  /// Everything in here is the parent's. The widget renders it and reports
  /// interaction; it changes nothing.
  final IuxInputDescriptor input;

  /// The live text, owned and disposed by the parent.
  ///
  /// Required rather than optional, and there is no internal fallback. A field
  /// that quietly made its own controller would be a field whose value the
  /// parent cannot read, which is the same defect as a component that owns its
  /// own state.
  ///
  /// A controller rather than a `value` string because the caret and the
  /// composing region live in it. Rebuilding a field from a plain string means
  /// re-seating the caret on every keystroke, and the user who was correcting
  /// the middle of a word finds themselves typing at the end of it.
  final TextEditingController controller;

  /// Called on every user edit, with the new text.
  ///
  /// Required. It is how the parent learns that the value it owns has changed
  /// and that whatever it decided about the old value no longer applies. It
  /// fires for user edits only — a programmatic change made through
  /// [controller] is the parent's own doing and does not come back to it.
  final ValueChanged<String> onChanged;

  /// An example of what to type, already localised, shown while the field is
  /// empty.
  ///
  /// **A placeholder is not a label** and cannot become one: it disappears the
  /// moment the user types. It is also hidden from assistive technology here,
  /// because repeating it as part of the field's name would make every empty
  /// field announce two names. Anything a user must know in order to answer
  /// belongs in [IuxInputDescriptor.helpText], which stays on screen, and in
  /// [IuxInputSemantics.hint], which a screen reader reads after the name.
  ///
  /// Not shown on a field that cannot be edited: prompting for input the user
  /// may not give is an instruction they cannot follow.
  final String? placeholder;

  /// What kind of thing is being asked for. Defaults to [IuxTextContent.text].
  final IuxTextContent content;

  /// How the field separates itself from the page. Defaults to the theme's.
  final IuxInputVariant? variant;

  /// Whether this takes focus when first built.
  ///
  /// Use it sparingly. Focusing a field on arrival opens the keyboard over the
  /// screen the user has not read yet, and moves a screen reader off the
  /// heading that would have told them where they are.
  final bool autofocus;

  /// An externally owned focus node.
  ///
  /// Pass one when something outside the field has to move focus into it — a
  /// form sending the user to the first field that failed, for instance.
  final FocusNode? focusNode;

  @override
  State<IuxTextField> createState() => _IuxTextFieldState();
}

class _IuxTextFieldState extends State<IuxTextField> {
  FocusNode? _ownedNode;
  bool _focused = false;
  bool _hovered = false;

  FocusNode get _focusNode => widget.focusNode ?? (_ownedNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
    _focused = _focusNode.hasFocus;
  }

  @override
  void didUpdateWidget(IuxTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode == oldWidget.focusNode) return;
    oldWidget.focusNode?.removeListener(_handleFocusChange);
    _ownedNode?.removeListener(_handleFocusChange);
    _focusNode.addListener(_handleFocusChange);
    _handleFocusChange();
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_handleFocusChange);
    _ownedNode
      ?..removeListener(_handleFocusChange)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!mounted) return;
    final bool focused = _focusNode.hasFocus;
    if (_focused == focused) return;
    setState(() => _focused = focused);
  }

  void _setHovered(bool value) {
    if (_hovered == value) return;
    setState(() => _hovered = value);
  }

  /// Places the caret when the user taps the container rather than the text.
  ///
  /// The inner field wins any tap that lands on it, so this only ever runs for
  /// the padding around it. Without it the outer few pixels of a control look
  /// interactive and are not, which is the kind of near-miss that reads as the
  /// application being unresponsive.
  void _handleTap() => IuxFocus.request(_focusNode);

  @override
  Widget build(BuildContext context) {
    final IuxInputTokens tokens = IuxInputResolver.resolve(
      context,
      widget.input,
      variant: widget.variant,
      hovered: _hovered,
      focused: _focused,
    );
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);

    // The focus ring reserves its own space whether or not it is drawn, so
    // gaining focus never moves anything. That reserved space also indents the
    // field, so the label and the supporting lines are indented to match:
    // otherwise the name sits a few pixels to the side of the box it names.
    final double ringInset = geometry.focus.width + geometry.focus.gap;
    final EdgeInsetsDirectional textInset =
        EdgeInsetsDirectional.only(start: ringInset);
    final double gap = math.max(0, tokens.gap - ringInset);

    final String? message = widget.input.validation.message;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: textInset,
          // Excluded because the field's semantic node carries the same string
          // as its name. Left in, the label would be read once as a heading
          // and once as the name of the box below it.
          child: IuxSemantics.decorative(
            child: Text(
              widget.input.semantics.label,
              style: tokens.labelStyle,
            ),
          ),
        ),
        SizedBox(height: gap),
        _IuxFieldSemantics(
          input: widget.input,
          content: widget.content,
          child: IuxFocusRing(
            focused: tokens.focused,
            borderRadius: BorderRadius.circular(
              _resolveRadius(tokens),
            ),
            child: MouseRegion(
              onEnter: (_) => _setHovered(true),
              onExit: (_) => _setHovered(false),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.input.isFocusable ? _handleTap : null,
                child: _IuxFieldContainer(
                  tokens: tokens,
                  geometry: geometry,
                  child: _IuxFieldRow(
                    input: widget.input,
                    tokens: tokens,
                    content: widget.content,
                    controller: widget.controller,
                    onChanged: widget.onChanged,
                    placeholder: widget.placeholder,
                    focusNode: _focusNode,
                    autofocus: widget.autofocus,
                    cursorWidth: geometry.strongBorderWidth,
                  ),
                ),
              ),
            ),
          ),
        ),
        // Help text and the validation message are both shown, and neither
        // replaces the other. Swapping the instruction for the error removes
        // the sentence explaining how to write a correct value at the exact
        // moment the user has proved they need it.
        if (widget.input.helpText case final String help) ...<Widget>[
          SizedBox(height: gap),
          Padding(
            padding: textInset,
            child: Text(help, style: tokens.helpStyle),
          ),
        ],
        if (message != null) ...<Widget>[
          SizedBox(height: gap),
          Padding(
            padding: textInset,
            child: _IuxValidationMessage(
              message: message,
              style: tokens.messageStyle,
            ),
          ),
        ],
      ],
    );
  }

  /// [IuxShape.full] arrives as infinity, because the theme cannot know how
  /// tall the field will be. Half the minimum target is the answer for a
  /// single-line field and an under-estimate for a multi-line one, which
  /// rounds its corners less than asked rather than clipping its own text.
  double _resolveRadius(IuxInputTokens tokens) =>
      tokens.radius.isFinite ? tokens.radius : tokens.minimumSize / 2;
}

/// Attaches the field's name, role and state to the node the user lands on.
///
/// One place, on purpose. A label that is merely adjacent to a field is a
/// label a screen-reader user has to find for themselves, and the failure is
/// silent: the field still works, it is simply announced as "edit box".
///
/// `IuxSemantics.field` is what does the attaching. It merges the editing
/// widget's own node into the named one, so the stop the user lands on to type
/// is the stop that carries the name — and it merges rather than excludes, so
/// the text-editing actions the screen reader needs to edit at all (set text,
/// move cursor, set selection) survive the naming.
class _IuxFieldSemantics extends StatelessWidget {
  const _IuxFieldSemantics({
    required this.input,
    required this.content,
    required this.child,
  });

  final IuxInputDescriptor input;
  final IuxTextContent content;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IuxSemantics.field(
      label: input.semantics.label,
      // The caller's hint, or their explanation of why the field is
      // unavailable. Resolved by the model so a text field and a checkbox
      // cannot announce the same situation differently.
      hint: input.accessibleHint,
      enabled: input.availability != IuxInputAvailability.disabled,
      // Only the read-only case. A disabled field is already announced as
      // unavailable, and saying both would describe two different reasons for
      // one state.
      readOnly: input.availability == IuxInputAvailability.readOnly,
      isRequired: input.isRequired,
      validation: switch (input.validation.status) {
        IuxInputValidationStatus.invalid => SemanticsValidationResult.invalid,
        IuxInputValidationStatus.valid => SemanticsValidationResult.valid,
        IuxInputValidationStatus.notValidated ||
        IuxInputValidationStatus.validating =>
          SemanticsValidationResult.none,
      },
      inputType: content.semanticInputType,
      child: child,
    );
  }
}

/// The outlined box itself.
class _IuxFieldContainer extends StatelessWidget {
  const _IuxFieldContainer({
    required this.tokens,
    required this.geometry,
    required this.child,
  });

  final IuxInputTokens tokens;
  final IuxGeometryTheme geometry;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Declared as a state change, so a reduced-motion preference shortens it
    // and no motion removes it — without the colour change itself ever being
    // lost.
    final IuxResolvedMotion motion = IuxMotionPolicy.resolve(
      context,
      role: IuxMotionRole.stateChange,
      scale: IuxMotionScale.short,
    );

    // An invalid field draws a thicker outline. Left uncompensated, that
    // thickening would grow the box by two pixels and push the help text and
    // the error down the screen — so the padding gives back exactly what the
    // border takes, and the field stays where the user left it.
    final double reserved = geometry.strongBorderWidth - tokens.borderWidth;

    return AnimatedContainer(
      duration: motion.duration,
      curve: motion.curve,
      constraints: BoxConstraints(minHeight: tokens.minimumSize),
      padding: tokens.padding + EdgeInsets.all(reserved),
      decoration: BoxDecoration(
        color: tokens.background,
        borderRadius: BorderRadius.circular(
          tokens.radius.isFinite ? tokens.radius : tokens.minimumSize / 2,
        ),
        border: Border.all(color: tokens.border, width: tokens.borderWidth),
      ),
      child: child,
    );
  }
}

/// The editable text, its placeholder, and the marker a read-only field wears.
class _IuxFieldRow extends StatelessWidget {
  const _IuxFieldRow({
    required this.input,
    required this.tokens,
    required this.content,
    required this.controller,
    required this.onChanged,
    required this.placeholder,
    required this.focusNode,
    required this.autofocus,
    required this.cursorWidth,
  });

  final IuxInputDescriptor input;
  final IuxInputTokens tokens;
  final IuxTextContent content;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? placeholder;
  final FocusNode focusNode;
  final bool autofocus;
  final double cursorWidth;

  @override
  Widget build(BuildContext context) {
    final bool editable = input.isEditable;

    final Widget field = TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      // Availability decides this, never the presence of a callback. Flutter's
      // own convention — a null onChanged greys the control — would let a
      // field become unusable because a caller had nothing to do on change.
      enabled: input.availability != IuxInputAvailability.disabled,
      readOnly: !editable,
      onChanged: onChanged,
      style: tokens.valueStyle,
      // The caret takes the colour of the text it sits in, which is the one
      // colour already measured against this background. It thickens with the
      // theme's strong border, so high contrast widens it too.
      cursorColor: tokens.valueStyle.color,
      cursorWidth: cursorWidth,
      keyboardType: content.keyboardType,
      textCapitalization: content.capitalization,
      autocorrect: content.autocorrect,
      autofillHints: content.autofillHints,
      maxLines: content.maxLines,
      minLines: content.minLines,
      // The container draws the outline and owns the padding, so the
      // decorator would only add a second one.
      decoration: null,
    );

    // Shown only while the field is empty *and* editable. Prompting for input
    // the user may not give is an instruction they cannot follow.
    final String? prompt = placeholder;
    final Widget prompted = prompt == null || !editable
        ? field
        : Stack(
            children: <Widget>[
              Positioned.fill(
                child: IgnorePointer(
                  // Hidden from assistive technology: repeating it would make
                  // every empty field announce two names. Anything essential
                  // belongs in helpText and in IuxInputSemantics.hint.
                  child: IuxSemantics.decorative(
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: controller,
                      builder: (
                        BuildContext context,
                        TextEditingValue value,
                        Widget? child,
                      ) =>
                          value.text.isEmpty
                              ? Align(
                                  alignment: AlignmentDirectional.topStart,
                                  child: child,
                                )
                              : const SizedBox.shrink(),
                      child: Text(prompt, style: tokens.placeholderStyle),
                    ),
                  ),
                ),
              ),
              field,
            ],
          );

    if (input.availability != IuxInputAvailability.readOnly) return prompted;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(child: prompted),
        const IuxGap.horizontal(IuxSpacingStep.xs),
        _IuxReadOnlyMarker(tokens: tokens),
      ],
    );
  }
}

/// The glyph that says a value may be read and not changed.
///
/// A read-only field asks the theme for `surface.subtle` and an editable
/// filled one for `surface.interactive`. Those are distinct roles, but every
/// palette IUX ships maps them to the same colour (open issue
/// IUX-SURFACE-001), so in the filled variant the fill separates nothing. The
/// behavioural signals — no caret, no keyboard, the read-only flag in the
/// semantic tree — are real but arrive only once the user has already tried to
/// type.
///
/// This is the signal that is there beforehand, and it is a shape rather than
/// a hue, so it survives greyscale, a colour-vision deficiency and a
/// screenshot printed in black and white.
///
/// It is hidden from assistive technology because the semantic node already
/// carries `readOnly`, which the platform speaks in the user's own language —
/// and an icon carrying information the semantics do not is information a
/// screen-reader user never receives.
class _IuxReadOnlyMarker extends StatelessWidget {
  const _IuxReadOnlyMarker({required this.tokens});

  final IuxInputTokens tokens;

  @override
  Widget build(BuildContext context) {
    // Sized from the value's own metrics, so the marker grows with the text it
    // annotates instead of shrinking into a dot at 200%.
    final double size = IuxAccessibility.of(context)
        .scaleText(tokens.valueStyle.fontSize ?? tokens.labelStyle.fontSize!);

    return IuxSemantics.decorative(
      child: Icon(
        Icons.lock_outline,
        size: size,
        color: tokens.labelStyle.color,
        // Scaled once, through the runtime every other IUX component reads.
        applyTextScaling: false,
      ),
    );
  }
}

/// The validation message, announced when it appears.
///
/// A live region rather than an announcement: Android deprecated
/// `announceForAccessibility` because it clears TalkBack's speech queue, so an
/// announcement cuts off whatever the user was listening to. A live region is
/// spoken in place, once, and the user can go back and re-read it.
///
/// The text is also always on screen. An error that only a screen reader hears
/// is an error a sighted user with a cognitive impairment never finds.
class _IuxValidationMessage extends StatelessWidget {
  const _IuxValidationMessage({required this.message, required this.style});

  final String message;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    // The visual repeats the label verbatim, so it is excluded to keep the
    // message from being read twice — the same shape the progress indicator
    // uses.
    return IuxSemantics.liveRegion(
      label: message,
      child: IuxSemantics.decorative(
        child: Text(message, style: style),
      ),
    );
  }
}
