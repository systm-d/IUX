import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'iux_accessibility.dart';

/// Guarantees that its child is large enough to hit, without enlarging it.
///
/// The interactive region and the visual element are different things. A
/// 20-pixel close icon can stay 20 pixels while responding across 48 — and
/// that separation is exactly what components get wrong when each one
/// reimplements the rule.
///
/// ```dart
/// IuxTapTarget(
///   onTap: dismiss,
///   semanticLabel: 'Dismiss',
///   child: const Icon(Icons.close, size: 20),
/// )
/// ```
///
/// ## The name and the action live on the same node
///
/// Passing [semanticLabel] excludes the subtree, because that is the only way
/// to replace what the child would otherwise announce — an icon-only control
/// has no text of its own, so the name has to come from here. The exclusion
/// takes the child's own tap action with it, which is why this node publishes
/// [onTap] itself.
///
/// It did not, until `IUX-TAPTARGET-ACTION-001`. The node announced "button,
/// enabled" and offered nothing to activate, **in exactly the case the widget
/// exists for**: a finger worked, a screen reader could not activate it at all.
/// That is the fourth thing this one mechanism has silently deleted — `onTap`
/// on every IUX button (IUX-005 to IUX-011), the focus state and `focus` action
/// on eleven controls (`IUX-A11Y-FOCUS-001`), the `Focus` widget's own
/// annotations, and then this.
class IuxTapTarget extends StatelessWidget {
  /// Wraps [child] in a guaranteed-size interactive region.
  const IuxTapTarget({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.semanticHint,
    this.enabled = true,
    this.minimumSize,
  });

  /// The visual content. Its size is not changed.
  final Widget child;

  /// Called when the region is activated, by a pointer or by a screen reader.
  ///
  /// Null both means "this is only a size guarantee" and is how a caller
  /// disables a control. The node cannot tell those apart, so it keeps
  /// announcing whatever [enabled] says — see the limit on
  /// `IUX-TAPTARGET-ACTION-001`.
  final VoidCallback? onTap;

  /// The accessible name. Required whenever [child] has no text of its own —
  /// an icon-only control without a label is unusable with a screen reader.
  final String? semanticLabel;

  /// What activating this does, when the label alone leaves it ambiguous.
  final String? semanticHint;

  /// Whether the region responds. Disabled state is announced, not merely
  /// visual.
  final bool enabled;

  /// Overrides the resolved minimum. Only ever raises it.
  final double? minimumSize;

  @override
  Widget build(BuildContext context) {
    final double resolved = IuxAccessibility.of(context).minimumTouchTarget;
    final double size =
        minimumSize == null ? resolved : math.max(minimumSize!, resolved);

    return Semantics(
      button: onTap != null,
      // Left exactly as it was, and deliberately. `onTap == null` is ambiguous
      // here — it is how a caller says "not a control" *and* how the same
      // caller disables one, as `_IuxSelectionControl` does. Deriving
      // control-ness from it would strip the enabled state off every disabled
      // control in the library. Recorded as a limit rather than guessed at.
      enabled: enabled,
      label: semanticLabel,
      hint: semanticHint,
      // Published here rather than left to the child. `excludeSemantics` below
      // removes the child's tap action along with everything else it was
      // contributing, and a supplied label is the case this widget exists for —
      // so without this the node is announced as a button and a screen-reader
      // double-tap does nothing. IUX-TAPTARGET-ACTION-001.
      onTap: enabled ? onTap : null,
      excludeSemantics: semanticLabel != null,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: size, minHeight: size),
        child: GestureDetector(
          // Opaque so the whole region responds, not only the painted child.
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? onTap : null,
          child: Center(widthFactor: 1, heightFactor: 1, child: child),
        ),
      ),
    );
  }
}

/// Reports whether a size satisfies the minimum in force at a context.
///
/// Intended for tests and for the catalog. Components should use
/// [IuxTapTarget] rather than measuring themselves.
abstract final class IuxTouchTargetCheck {
  /// Whether [size] is large enough at [context].
  static bool isLargeEnough(BuildContext context, Size size) {
    final double minimum = IuxAccessibility.of(context).minimumTouchTarget;
    return size.width >= minimum && size.height >= minimum;
  }
}
