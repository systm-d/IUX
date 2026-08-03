import 'package:flutter/material.dart';

/// How much horizontal room a layout has, in Android's terms.
///
/// Three classes, deliberately. A finer scale invites per-device tuning, which
/// is how a layout ends up correct on the two phones a team owns and wrong
/// everywhere else.
enum IuxLayoutClass {
  /// A phone in portrait, and any narrow window. The common case.
  compact,

  /// A large phone in landscape, a small tablet, a split-screen window.
  medium,

  /// A tablet, a desktop window, an unfolded foldable.
  expanded,
}

/// The width thresholds separating layout classes.
///
/// These are Android's window size class breakpoints, adopted rather than
/// invented so that IUX agrees with the platform an application also targets.
abstract final class IuxBreakpoints {
  /// Below this width, the layout is [IuxLayoutClass.compact].
  static const double medium = 600;

  /// At or above this width, the layout is [IuxLayoutClass.expanded].
  static const double expanded = 840;

  /// The class for a given width.
  static IuxLayoutClass classFor(double width) {
    if (width >= expanded) return IuxLayoutClass.expanded;
    if (width >= medium) return IuxLayoutClass.medium;
    return IuxLayoutClass.compact;
  }

  /// The class in force at [context].
  ///
  /// Measured from the width actually available, not from the physical screen:
  /// a split-screen window on a tablet is compact, and treating it as expanded
  /// is the classic way to ship an unusable multi-window experience.
  static IuxLayoutClass of(BuildContext context) =>
      classFor(MediaQuery.sizeOf(context).width);
}

/// A value that differs by layout class.
///
/// ```dart
/// const columns = IuxResponsiveValue<int>(compact: 1, medium: 2, expanded: 3);
/// final count = columns.resolve(context);
/// ```
///
/// [compact] is required and the others fall back to it, so the narrow case —
/// the one most users are in — cannot be forgotten.
@immutable
final class IuxResponsiveValue<T> {
  /// Creates a responsive value.
  const IuxResponsiveValue({required this.compact, this.medium, this.expanded});

  /// The value for narrow layouts. Always defined.
  final T compact;

  /// The value for medium layouts, or null to reuse [compact].
  final T? medium;

  /// The value for expanded layouts, or null to reuse the medium value.
  final T? expanded;

  /// The value for [layoutClass].
  T resolveFor(IuxLayoutClass layoutClass) => switch (layoutClass) {
        IuxLayoutClass.compact => compact,
        IuxLayoutClass.medium => medium ?? compact,
        IuxLayoutClass.expanded => expanded ?? medium ?? compact,
      };

  /// The value in force at [context].
  T resolve(BuildContext context) => resolveFor(IuxBreakpoints.of(context));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxResponsiveValue<T> &&
          other.compact == compact &&
          other.medium == medium &&
          other.expanded == expanded;

  @override
  int get hashCode => Object.hash(compact, medium, expanded);
}
