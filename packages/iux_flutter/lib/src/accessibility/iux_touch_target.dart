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

  /// Called when the region is activated.
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
      enabled: enabled,
      label: semanticLabel,
      hint: semanticHint,
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
