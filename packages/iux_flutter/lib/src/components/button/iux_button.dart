import 'package:flutter/material.dart';

import '../../accessibility/iux_focus.dart';
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
/// There is no colour, radius, elevation or duration parameter, and there will
/// not be one. An API that accepts a colour has already lost the contrast
/// guarantee: the theme can no longer be held responsible for something a call
/// site overrode.
///
/// Availability, interaction and operation are three separate things. The
/// action carries availability and operation; focus, press and hover stay
/// inside the widget, because they belong to this instance and to nothing
/// else.
class IuxButton extends StatefulWidget {
  /// Creates a textual action.
  const IuxButton({
    super.key,
    required this.label,
    required this.action,
    required this.onActivate,
    this.variant,
    this.autofocus = false,
    this.focusNode,
    this.expand = false,
  });

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

  /// How much visual weight to carry. Defaults to the theme's variant.
  final IuxButtonVariant? variant;

  /// Whether this takes focus when first built.
  final bool autofocus;

  /// An externally owned focus node.
  final FocusNode? focusNode;

  /// Whether to fill the available width.
  ///
  /// Off by default: a button as wide as the screen reads as a banner, and its
  /// label drifts far from its edges.
  final bool expand;

  @override
  State<IuxButton> createState() => _IuxButtonState();
}

class _IuxButtonState extends State<IuxButton> {
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
    );

    final bool activatable = widget.action.isActivatable;

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
      alignment: Alignment.center,
      child: Text(
        widget.label,
        style: tokens.textStyle,
        textAlign: TextAlign.center,
        // No ellipsis and no line limit. A truncated action label is an action
        // the user cannot identify, and truncation gets worse exactly when a
        // user has enlarged their text.
        softWrap: true,
      ),
    );

    if (!widget.expand) {
      visual = IntrinsicWidth(child: visual);
    }

    return IuxSemantics.action(
      label: widget.action.semantics.label,
      hint: _hint,
      enabled: activatable,
      busy: widget.action.isBusy,
      child: IuxFocusable(
        autofocus: widget.autofocus,
        focusNode: widget.focusNode,
        canRequestFocus: activatable,
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
