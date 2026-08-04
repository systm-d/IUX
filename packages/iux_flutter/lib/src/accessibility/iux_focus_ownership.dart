import 'package:flutter/widgets.dart';

/// Supplies the [FocusNode] a control's semantics node describes.
///
/// **Deliberately not exported.** It exists because two widgets in one control
/// have to name the *same* focus node: `IuxSemantics.action` publishes the
/// focus state and the `focus` action, and `IuxFocusable` is what actually
/// holds the focus. If they end up on different nodes, assistive technology is
/// told about a focus that lives somewhere else — which is a subtler version of
/// the defect this whole mechanism exists to fix (IUX-A11Y-FOCUS-001).
///
/// Callers usually accept a `focusNode` from their own caller and it is usually
/// null, so every control would otherwise repeat the same four lines: hold a
/// fallback node, create it lazily, prefer the caller's, dispose only the one
/// it owns. Four lines repeated at nine call sites is four lines that will
/// eventually disagree, and the one most easily forgotten is the disposal.
///
/// **Every composer of `IuxSemantics.action` routes through this**, and that is
/// enforced rather than remembered:
/// `test/accessibility/announced_controls_test.dart` refuses a call site that
/// passes no `focusNode` or no `onTap`, and refuses a file that composes the
/// helper without naming this widget. It had exactly one call site for a
/// while, which is how eight controls stayed broken after the defect was
/// declared fixed.
///
/// ```dart
/// IuxFocusNodeOwner(
///   focusNode: widget.focusNode,
///   builder: (BuildContext context, FocusNode node) => IuxSemantics.action(
///     label: label,
///     focusNode: node,
///     focusable: available,
///     child: IuxFocusable(focusNode: node, child: ...),
///   ),
/// )
/// ```
class IuxFocusNodeOwner extends StatefulWidget {
  /// Builds [builder] with [focusNode], or with one created and owned here.
  const IuxFocusNodeOwner({
    super.key,
    required this.focusNode,
    required this.builder,
    this.debugLabel,
  });

  /// The caller's node, or null to have one created here.
  ///
  /// A node passed in is never disposed here: its owner outlives this widget
  /// and disposing it would leave them holding a dead node.
  final FocusNode? focusNode;

  /// Names the created node in debug output. Ignored when [focusNode] is given.
  final String? debugLabel;

  /// Builds the control around the resolved node.
  final Widget Function(BuildContext context, FocusNode node) builder;

  @override
  State<IuxFocusNodeOwner> createState() => _IuxFocusNodeOwnerState();
}

class _IuxFocusNodeOwnerState extends State<IuxFocusNodeOwner> {
  FocusNode? _owned;

  FocusNode get _node =>
      widget.focusNode ?? (_owned ??= FocusNode(debugLabel: widget.debugLabel));

  @override
  void didUpdateWidget(IuxFocusNodeOwner oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The caller took ownership of the focus after this control was built. The
    // node created here is no longer described by anything, so it goes.
    if (widget.focusNode != null && _owned != null) {
      _owned!.dispose();
      _owned = null;
    }
  }

  @override
  void dispose() {
    _owned?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _node);
}
