import 'package:flutter/material.dart';

import '../../accessibility/iux_accessibility.dart';
import '../../accessibility/iux_focus.dart';
import '../../accessibility/iux_focus_ownership.dart';
import '../../accessibility/iux_semantics.dart';
import '../../actions/iux_action_descriptor.dart';
import '../../actions/iux_action_model.dart';
import '../../motion/iux_motion_policy.dart';
import '../../motion/iux_motion_role.dart';
import '../../themes/extensions/iux_button_theme.dart';

/// A textual action.
///
/// ```dart
/// IuxButton(
///   label: l10n.save,
///   action: const IuxActionDescriptor.primary(
///     semantics: IuxActionSemantics(label: 'Save'),
///   ),
///   onActivate: controller.save,
/// )
/// ```
///
/// **Use it** for anything the user activates that has a text label.
///
/// **Do not use it** to navigate as if it were a link, to toggle a value — a
/// switch says more — or to carry an asynchronous operation of its own. The
/// parent owns the operation and reports it through
/// [IuxActionDescriptor.operation]; a button that ran its own future would be
/// guessing at an outcome only the caller knows.
///
/// For an action with no room for a label, use [IuxIconButton]. It is a
/// separate widget rather than a null [label] because the two have different
/// obligations: an icon-only control has to take its name from somewhere, and
/// a nullable label would let a caller ship a control with no name at all.
///
/// There is no colour, radius, elevation or duration parameter, and there will
/// not be one. An API that accepts a colour has already lost the contrast
/// guarantee: the theme can no longer be held responsible for something a call
/// site overrode.
///
/// Availability, interaction and operation are three separate things. The
/// action carries availability and operation; focus, press and hover stay
/// inside the widget, because they belong to this instance and to nothing
/// else.
class IuxButton extends StatelessWidget {
  /// Creates a textual action.
  const IuxButton({
    super.key,
    required this.label,
    required this.action,
    required this.onActivate,
    this.icon,
    this.variant,
    this.autofocus = false,
    this.focusNode,
    this.expand = false,
    this.busyHint,
  })  : assert(
          label.length > 0,
          'A button must show something. An empty label leaves a container '
          'that a sighted user can see but cannot identify. When there is no '
          'room for text, use IuxIconButton: it takes its accessible name '
          'from the action, so the control still has one.',
        ),
        assert(
          variant != IuxButtonVariant.icon,
          'IuxButtonVariant.icon is a square target carrying an icon and no '
          'label, so it cannot describe a button that has one. Use '
          'IuxIconButton for an icon-only action, or pick the variant that '
          'expresses the emphasis you wanted.',
        );

  /// The visible text.
  ///
  /// Already localised. Kept separate from
  /// [IuxActionSemantics.label] so a button can read "Delete" while announcing
  /// "Delete the March invoice" — a screen reader user hears the row they are
  /// on, a sighted user sees the column they are in.
  final String label;

  /// What the action is, and whether it may run.
  final IuxActionDescriptor action;

  /// Called once per accepted activation.
  ///
  /// Never called while the action is unavailable, and never called twice for
  /// one gesture.
  final VoidCallback onActivate;

  /// A glyph shown before [label], in reading order.
  ///
  /// An [IconData] rather than a `Widget`: the button then sizes and colours
  /// the glyph from the same tokens as the label, so an icon cannot arrive
  /// carrying a colour that fails against the container it sits on. A widget
  /// slot would hand that guarantee back to the call site, which is exactly
  /// what this API refuses to do for colours.
  ///
  /// The icon must be redundant with [label]. It is excluded from the
  /// semantic tree — the action is already named — so an icon carrying
  /// information the label does not is information a screen-reader user never
  /// receives.
  ///
  /// There is no trailing position. A glyph after the label reads as a
  /// disclosure indicator rather than as part of the name, and a screen where
  /// some buttons lead with their icon and others trail it costs the user a
  /// scan on every row.
  final IconData? icon;

  /// How much visual weight to carry. Defaults to the theme's variant.
  ///
  /// Emphasis, not meaning: the same action can be prominent on one screen and
  /// discreet on another without changing what it does. Meaning stays in
  /// [IuxActionDescriptor.intent].
  final IuxButtonVariant? variant;

  /// Whether this takes focus when first built.
  final bool autofocus;

  /// An externally owned focus node.
  final FocusNode? focusNode;

  /// Announced after the label while the action is running.
  ///
  /// Already localised, like every other string this API takes. Leave it null
  /// and a screen reader hears nothing extra — silence is indistinguishable
  /// from a control that did nothing, so supply it for anything asynchronous.
  final String? busyHint;

  /// Whether to fill the available width.
  ///
  /// Off by default: a button as wide as the screen reads as a banner, and its
  /// label drifts far from its edges.
  ///
  /// It takes the width only. Height always follows the content, so a button
  /// in a `Center` or an `Expanded` stays the size of a button.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return _IuxActionSurface(
      action: action,
      variant: variant,
      hasLabel: true,
      onActivate: onActivate,
      autofocus: autofocus,
      focusNode: focusNode,
      expand: expand,
      busyHint: busyHint,
      builder: (BuildContext context, IuxButtonTokens tokens) {
        final Widget text = Text(
          label,
          style: tokens.textStyle,
          textAlign: TextAlign.center,
          // No ellipsis and no line limit. A truncated action label is an
          // action the user cannot identify, and truncation gets worse exactly
          // when a user has enlarged their text.
          softWrap: true,
        );

        final IconData? glyph = icon;
        if (glyph == null) return text;

        // Row rather than a fixed layout: the icon leads in *reading* order,
        // so right-to-left places it on the right without the widget knowing
        // which language it is in.
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _IuxButtonGlyph(icon: glyph, tokens: tokens),
            SizedBox(width: tokens.iconGap),
            // Flexible so the label keeps wrapping once the icon has taken its
            // share of the width. Without it, enlarging text turns a wrapping
            // button into an overflowing one.
            Flexible(child: text),
          ],
        );
      },
    );
  }
}

/// An action with no room for a label.
///
/// ```dart
/// IuxIconButton(
///   icon: Icons.close,
///   action: const IuxActionDescriptor(
///     semantics: IuxActionSemantics(label: 'Close'),
///     role: IuxActionRole.dismiss,
///   ),
///   onActivate: controller.close,
/// )
/// ```
///
/// **Use it** where a label genuinely does not fit and the glyph is already
/// understood — closing, going back, searching. A row of controls in an app
/// bar is the usual case.
///
/// **Do not use it** for an action whose glyph the user has to guess. An icon
/// nobody recognises is a control nobody activates, and unlike a label there
/// is nothing to read. Icons are the least discoverable form of a control, so
/// reach for [IuxButton] first and drop the label only when space forces it.
/// Also avoid it for a destructive action reached without confirmation: an
/// unlabelled control is the easiest one to hit by accident.
///
/// **Accessibility.** There is no `label` parameter and no way to omit the
/// accessible name: it comes from [IuxActionSemantics.label], which the action
/// model already requires to be non-empty. An icon-only control without a name
/// is unusable with a screen reader, so this widget makes that state
/// unrepresentable rather than checked.
///
/// The glyph stays small while the interactive region does not: the region
/// meets the resolved touch target floor even though the icon inside it is
/// around 20 logical pixels. Enlarging the glyph to fill the target would make
/// the interface shout; shrinking the target to fit the glyph would make it
/// hard to hit. They are separate measurements.
class IuxIconButton extends StatelessWidget {
  /// Creates an icon-only action.
  const IuxIconButton({
    super.key,
    required this.icon,
    required this.action,
    required this.onActivate,
    this.variant = IuxButtonVariant.icon,
    this.autofocus = false,
    this.focusNode,
    this.busyHint,
  });

  /// The glyph identifying the action.
  ///
  /// An [IconData] rather than a `Widget`, for the same reason as
  /// [IuxButton.icon]: the widget colours it from the tokens that were
  /// measured against the container behind it.
  final IconData icon;

  /// What the action is, whether it may run, and — through
  /// [IuxActionDescriptor.semantics] — what it is called.
  final IuxActionDescriptor action;

  /// Called once per accepted activation.
  final VoidCallback onActivate;

  /// Announced after the name while the action is running.
  ///
  /// Already localised. Leave it null and a screen reader hears nothing
  /// extra — silence is indistinguishable from a control that did nothing.
  final String? busyHint;

  /// How much visual weight to carry.
  ///
  /// Defaults to [IuxButtonVariant.icon] rather than to the theme's variant,
  /// which describes labelled buttons and is normally
  /// [IuxButtonVariant.filled]. Icon actions usually appear several to a row,
  /// and a row of filled containers competes with the content it sits above.
  /// Ask for a heavier variant when one icon action genuinely dominates.
  final IuxButtonVariant variant;

  /// Whether this takes focus when first built.
  final bool autofocus;

  /// An externally owned focus node.
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return _IuxActionSurface(
      action: action,
      variant: variant,
      // Square padding, so the target does not grow wider than it is tall for
      // want of a label to balance it.
      hasLabel: false,
      onActivate: onActivate,
      autofocus: autofocus,
      focusNode: focusNode,
      expand: false,
      busyHint: busyHint,
      builder: (BuildContext context, IuxButtonTokens tokens) =>
          _IuxButtonGlyph(icon: icon, tokens: tokens),
    );
  }
}

/// The container, semantics and gesture handling every button shape shares.
///
/// Private on purpose. It is the answer to "what does an activated IUX action
/// look and behave like", and there is exactly one answer: the labelled
/// button, the icon button and the asynchronous button of a later mission must
/// not be able to drift apart on focus order, repeat handling or the hint a
/// disabled control reads out. Exposing it would invite a call site to build a
/// fourth kind of button that skips one of them.
class _IuxActionSurface extends StatefulWidget {
  const _IuxActionSurface({
    required this.action,
    required this.variant,
    required this.hasLabel,
    required this.onActivate,
    required this.autofocus,
    required this.focusNode,
    required this.expand,
    required this.busyHint,
    required this.builder,
  });

  final IuxActionDescriptor action;
  final IuxButtonVariant? variant;
  final bool hasLabel;
  final VoidCallback onActivate;
  final bool autofocus;
  final FocusNode? focusNode;
  final bool expand;

  /// Announced while the action runs. Caller-localised, or null for silence.
  final String? busyHint;

  /// Builds the content, given the appearance resolved for the current state.
  ///
  /// A builder rather than a widget, because press and hover live here and the
  /// content has to be coloured for the state they produce.
  final Widget Function(BuildContext context, IuxButtonTokens tokens) builder;

  @override
  State<_IuxActionSurface> createState() => _IuxActionSurfaceState();
}

class _IuxActionSurfaceState extends State<_IuxActionSurface> {
  bool _pressed = false;
  bool _hovered = false;

  void _handleActivate() {
    // Asked rather than assumed, so this widget cannot disagree with any other
    // component about whether a busy action accepts a second tap.
    final IuxActionOutcome outcome = IuxActionPolicy.evaluate(
      widget.action,
      // Confirmation is a pattern's job (IUX-008.7). A core button treats a
      // confirmable action as ready, and the pattern wrapping it decides
      // otherwise.
      confirmed: true,
    );
    if (!outcome.isAccepted) return;
    widget.onActivate();
  }

  @override
  Widget build(BuildContext context) {
    final IuxButtonTokens tokens = IuxButtonResolver.resolve(
      context,
      widget.action,
      variant: widget.variant,
      hovered: _hovered,
      pressed: _pressed,
      hasLabel: widget.hasLabel,
    );

    // Whether activating right now would run anything. False while a busy
    // action drops repeats, which is what the gesture handlers and the tap
    // action have to follow.
    final bool activatable = widget.action.isActivatable;

    // Whether the control exists as far as the user is concerned. Only
    // *unavailable* takes a control out of the focus order and announces it as
    // unusable; running is not unavailable. The two were one flag, so a button
    // that was working announced itself as disabled and threw a keyboard user
    // back to the enclosing scope the moment they pressed Enter on it. The
    // action model kept these dimensions apart from the start — it even
    // asserts that a disabled action cannot be in progress — and the button
    // collapsed them anyway.
    final bool available =
        widget.action.availability != IuxActionAvailability.disabled;

    // The container animates between states so a change is perceptible rather
    // than instantaneous. Declared as a state change, so a reduced-motion
    // preference shortens it and no motion removes it — without the colour
    // change itself ever being lost.
    final IuxResolvedMotion motion = IuxMotionPolicy.resolve(
      context,
      role: IuxMotionRole.stateChange,
      scale: IuxMotionScale.short,
    );

    Widget visual = AnimatedContainer(
      duration: motion.duration,
      curve: motion.curve,
      constraints: BoxConstraints(
        minHeight: tokens.minimumSize,
        minWidth: tokens.minimumSize,
      ),
      padding: tokens.padding,
      decoration: BoxDecoration(
        color: tokens.background,
        borderRadius: BorderRadius.circular(
          tokens.radius.isFinite ? tokens.radius : tokens.minimumSize / 2,
        ),
        border: tokens.borderWidth > 0
            ? Border.all(color: tokens.border, width: tokens.borderWidth)
            : null,
      ),
      // Centred by a shrink-wrapping Center rather than by the container's own
      // alignment. A container that aligns its child grows to fill whatever
      // its parent offers, so a button placed in a Center or an Expanded came
      // out as tall as the screen — a 792-pixel target that still announced
      // itself as a button.
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: widget.builder(context, tokens),
      ),
    );

    visual = widget.expand
        // Asks for the width and nothing else. Where no width is on offer —
        // an unbounded row — this fails loudly rather than quietly ignoring
        // what the caller asked for.
        ? SizedBox(width: double.infinity, child: visual)
        : IntrinsicWidth(child: visual);

    return IuxFocusNodeOwner(
      focusNode: widget.focusNode,
      debugLabel: widget.action.semantics.label,
      builder: (BuildContext context, FocusNode node) => IuxSemantics.action(
        label: widget.action.semantics.label,
        hint: _hint,
        enabled: available,
        focusNode: node,
        focusable: available,
        busyHint: widget.action.isBusy ? widget.busyHint : null,
        onTap: activatable ? _handleActivate : null,
        child: IuxFocusable(
          autofocus: widget.autofocus,
          focusNode: node,
          canRequestFocus: available,
          onActivate: activatable ? _handleActivate : null,
          child: MouseRegion(
            onEnter: (_) => _setHovered(true),
            onExit: (_) => _setHovered(false),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: activatable ? (_) => _setPressed(true) : null,
              onTapUp: activatable ? (_) => _setPressed(false) : null,
              onTapCancel: activatable ? () => _setPressed(false) : null,
              onTap: activatable ? _handleActivate : null,
              child: visual,
            ),
          ),
        ),
      ),
    );
  }

  /// The hint a screen reader reads after the label.
  ///
  /// An unavailable action explains itself when the caller said why. A greyed
  /// control with no explanation leaves the user unable to tell whether they
  /// did something wrong or the feature does not apply to them.
  String? get _hint {
    if (widget.action.availability == IuxActionAvailability.disabled) {
      return widget.action.semantics.unavailabilityReason ??
          widget.action.semantics.hint;
    }
    return widget.action.semantics.hint;
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

/// A glyph sized and coloured from the tokens the button resolved.
///
/// Separate from the buttons so the two cannot disagree about how large an
/// icon is, and so the text-scaling rule below is written once.
class _IuxButtonGlyph extends StatelessWidget {
  const _IuxButtonGlyph({required this.icon, required this.tokens});

  final IconData icon;
  final IuxButtonTokens tokens;

  @override
  Widget build(BuildContext context) {
    // An icon is content, not decoration. A user who enlarged text because
    // 14pt was unreadable gains nothing from a control whose only content
    // stays at 20 — and for an icon-only button that content is the whole
    // control. The target floor is applied separately by the container, so
    // scaling here never makes the button smaller.
    final double size = IuxAccessibility.of(context).scaleText(tokens.iconSize);

    return Icon(
      icon,
      size: size,
      color: tokens.foreground,
      // Flutter would otherwise scale it a second time. The scale is applied
      // once, through the runtime every other IUX component reads, so an icon
      // and a label enlarge by the same factor.
      applyTextScaling: false,
    );
  }
}
