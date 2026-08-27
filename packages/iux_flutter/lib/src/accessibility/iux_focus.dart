import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../semantics/iux_semantic_colors.dart';
import '../themes/extensions/iux_geometry_theme.dart';

/// Draws the focus indicator, using the geometry and colour the theme resolved.
///
/// Focus is drawn *outside* the child rather than over it, so the indicator
/// never covers the content it identifies — WCAG 2.2 added a criterion for
/// exactly that failure.
///
/// ```dart
/// IuxFocusRing(
///   focused: hasFocus,
///   child: const Text('Continue'),
/// )
/// ```
class IuxFocusRing extends StatelessWidget {
  /// Wraps [child] with a focus indicator shown when [focused] is true.
  const IuxFocusRing({
    super.key,
    required this.child,
    required this.focused,
    this.borderRadius,
  });

  /// The element being focused.
  final Widget child;

  /// Whether the indicator is visible.
  final bool focused;

  /// Corner radius of the ring. Defaults to the theme's medium radius.
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);
    final BorderRadius radius =
        borderRadius ?? BorderRadius.circular(geometry.radiusMedium);

    return Padding(
      // The gap is reserved whether or not the ring is drawn, so gaining focus
      // never shifts the layout — a moving target is hard to follow, and for a
      // screen-magnifier user it can push the element off screen.
      padding: EdgeInsets.all(geometry.focus.width + geometry.focus.gap),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: focused
              ? Border.all(
                  color: colors.state.focus,
                  width: geometry.focus.width,
                )
              : Border.all(color: const Color(0x00000000), width: 0),
        ),
        child: child,
      ),
    );
  }
}

/// A focus-aware region that reports its own focus state.
///
/// Wraps `Focus` and `IuxFocusRing` so a component gets keyboard focus,
/// a visible indicator and the correct semantics from one widget instead of
/// three that can disagree.
class IuxFocusable extends StatefulWidget {
  /// Creates a focusable region.
  const IuxFocusable({
    super.key,
    required this.child,
    this.onActivate,
    this.autofocus = false,
    this.focusNode,
    this.canRequestFocus = true,
    this.borderRadius,
  });

  /// The content.
  final Widget child;

  /// Called when the region is activated by keyboard — Enter or Space.
  ///
  /// **Keyboard only, and deliberately.** This widget carries no gesture
  /// recogniser and publishes no tap action: focusability is not activability,
  /// and a focus ring that also captured pointers would compete with whatever
  /// it is wrapped around for the gesture arena. Every IUX control pairs it
  /// with something that owns the pointer — a `GestureDetector`, or
  /// [IuxTapTarget].
  ///
  /// So a region built from this alone cannot be pressed at all, by a finger
  /// or by a screen reader. That is correct and it is not obvious: a semantics
  /// probe of the catalog reported it as a surprise rather than as a defect,
  /// which is why it is written down here (`IUX-TAPTARGET-ACTION-001`).
  final VoidCallback? onActivate;

  /// Whether this takes focus when first built.
  final bool autofocus;

  /// An externally owned focus node.
  final FocusNode? focusNode;

  /// Whether this participates in focus traversal at all.
  final bool canRequestFocus;

  /// Corner radius of the focus ring.
  final BorderRadius? borderRadius;

  @override
  State<IuxFocusable> createState() => _IuxFocusableState();
}

class _IuxFocusableState extends State<IuxFocusable> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      canRequestFocus: widget.canRequestFocus,
      onFocusChange: (bool value) => setState(() => _focused = value),
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (widget.onActivate == null) return KeyEventResult.ignored;
        final bool isActivation = event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.space);
        if (!isActivation) return KeyEventResult.ignored;
        widget.onActivate!();
        return KeyEventResult.handled;
      },
      child: IuxFocusRing(
        focused: _focused,
        borderRadius: widget.borderRadius,
        child: widget.child,
      ),
    );
  }
}

/// Focus operations components share instead of reimplementing.
abstract final class IuxFocus {
  /// Moves focus to [node], if it can take it.
  static void request(FocusNode node) {
    if (node.canRequestFocus) node.requestFocus();
  }

  /// Returns focus to [previous], used when a dialog or sheet closes.
  ///
  /// Restoring focus is what keeps a keyboard or screen-reader user from being
  /// dropped back at the top of the page after every overlay.
  static void restore(FocusNode? previous) {
    if (previous != null && previous.context != null) {
      previous.requestFocus();
    }
  }

  /// The node currently holding focus, captured before opening an overlay.
  static FocusNode? current(BuildContext context) =>
      FocusManager.instance.primaryFocus;

  /// Removes focus from whatever holds it, without giving it to anything else.
  ///
  /// Use when dismissing a keyboard, never to hide a focus indicator.
  static void unfocus(BuildContext context) => FocusScope.of(context).unfocus();
}
