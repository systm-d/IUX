import 'package:flutter/material.dart';

import 'iux_dialog.dart';

/// Places at most one dialog over a page.
///
/// ```dart
/// Scaffold(
///   body: IuxModalLayer(
///     dialog: state.confirmingDelete
///         ? IuxDialog(
///             title: 'Delete this invoice?',
///             message: 'The invoice and its attachments are removed '
///                 'permanently.',
///             dismissLabel: 'Keep it',
///             onDismiss: controller.closeDialog,
///           )
///         : null,
///     child: IuxPage(child: content),
///   ),
/// )
/// ```
///
/// **Why a layer rather than a route.** A component that pushed a route would
/// be deciding navigation, and navigation belongs to the application: the back
/// stack, deep links and state restoration are the parent's, and a component
/// that quietly pushes onto them cannot be reasoned about from the call site.
/// Here the parent owns a flag, and the dialog exists exactly while the flag is
/// true — which also means it can never be left open by a code path that
/// forgot to pop.
///
/// **Why one slot.** [dialog] is a single nullable value rather than a list, so
/// a second dialog cannot open over the first. Stacked dialogs are the clearest
/// way to lose a user: the way out of the top one is not the way out of the
/// flow, and neither is visible from the other.
///
/// **Insets.** The page consumes its own system insets and the dialog consumes
/// its own, so neither pads the other twice. For the same reason, never place
/// an [IuxDialog] *inside* an `IuxPage`: the page has already applied a
/// `SafeArea` and its padding, and the dialog would be inset a second time from
/// a notch that is only there once.
class IuxModalLayer extends StatelessWidget {
  /// Places [dialog], when there is one, over [child].
  const IuxModalLayer({
    super.key,
    required this.child,
    this.dialog,
  });

  /// The page the dialog interrupts.
  final Widget child;

  /// The dialog currently open, or null when none is.
  ///
  /// Typed as [IuxDialog] rather than as a `Widget`: the slot exists to hold a
  /// modal that traps focus, blocks the page behind it and names a route, and
  /// an arbitrary widget dropped in here would do none of those while looking
  /// from the call site exactly like one that did.
  final IuxDialog? dialog;

  @override
  Widget build(BuildContext context) {
    final IuxDialog? modal = dialog;
    // No Stack at all while nothing is open. A layer that costs a render object
    // on every page whether or not it is used is a layer people stop adding.
    if (modal == null) return child;
    return Stack(
      // The dialog is painted after the page, which is what lets it block the
      // page's semantics. Reversing the order would leave the page readable to
      // a screen reader while it is unreachable by touch.
      fit: StackFit.expand,
      children: <Widget>[child, modal],
    );
  }
}
