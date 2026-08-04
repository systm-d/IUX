import 'package:flutter/material.dart';

import '../navigation/iux_navigation_drawer.dart';
import 'iux_bottom_sheet.dart';
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
///             onDismissed: controller.closeDialog,
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
  /// Places [dialog] or [sheet], when there is one, over [child].
  ///
  /// At most one may be open. Two modals at once means one blocks the other's
  /// semantics, so the user is trapped in a layer a screen reader cannot see
  /// out of — refused here rather than left to be discovered.
  const IuxModalLayer({
    super.key,
    required this.child,
    this.dialog,
    this.sheet,
    this.drawer,
  }) : assert(
          (dialog == null ? 0 : 1) +
                  (sheet == null ? 0 : 1) +
                  (drawer == null ? 0 : 1) <=
              1,
          'A dialog, a bottom sheet and a navigation drawer cannot be open at '
          'once. Close one before opening the other, or model the second step '
          'inside the first.',
        );

  /// The page the dialog interrupts.
  final Widget child;

  /// The dialog currently open, or null when none is.
  ///
  /// Typed as [IuxDialog] rather than as a `Widget`: the slot exists to hold a
  /// modal that traps focus, blocks the page behind it and names a route, and
  /// an arbitrary widget dropped in here would do none of those while looking
  /// from the call site exactly like one that did.
  final IuxDialog? dialog;

  /// The bottom sheet currently open, or null when none is.
  ///
  /// Typed for the same reason as [dialog]: the slot promises focus trapping,
  /// a blocked page and a named route, and an arbitrary widget would promise
  /// none of them while reading identically at the call site.
  final IuxBottomSheet? sheet;

  /// The navigation drawer currently open, or null when none is.
  ///
  /// This slot exists because getting the shape wrong is silent. IUX-027
  /// probed the obvious alternative — `Stack(children: [page, if (open)
  /// drawer])` — and found that the page element survives, its semantics node
  /// is never recompiled, and `BlockSemantics` therefore does **not** remove
  /// the covered page: a screen reader still reads and offers to activate
  /// controls the user cannot touch. Touch behaves identically in both
  /// shapes, which is exactly why nobody catches it without a screen reader.
  ///
  /// Routing the drawer through here makes the working shape the only shape a
  /// caller can express, rather than an idiom they have to know.
  final IuxNavigationDrawer? drawer;

  @override
  Widget build(BuildContext context) {
    final Widget? modal = dialog ?? sheet ?? drawer;
    // No Stack at all while nothing is open.
    //
    // This has a measured cost: the page changes depth in the element tree
    // when a modal opens, so its subtree rebuilds and a list scrolled to 400
    // snaps back to 0. Keeping the Stack permanently fixes that — and breaks
    // something worse. With the page element preserved, `BlockSemantics` no
    // longer removes it from the semantics tree, so a screen-reader user can
    // still read and try to activate a page they cannot touch.
    //
    // PROJECT_PROMPT.md §5 puts accessibility above ergonomics, so the scroll
    // loss stays and is recorded as IUX-OVERLAY-001. Fixing both at once needs
    // a way to preserve the element *and* dirty the semantics — not a
    // one-line change, and not this mission's.
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
