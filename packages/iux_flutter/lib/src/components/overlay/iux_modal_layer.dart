import 'package:flutter/material.dart';

import '../../layout/iux_material_ground.dart';
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
  /// Typed for the same reason as [dialog] and [sheet]. It also spares the
  /// caller a shape that is easy to get wrong: a drawer placed by hand in
  /// `Stack(children: [page, if (open) drawer])` hides the page correctly, but
  /// destroys and rebuilds it every time it opens — which is IUX-OVERLAY-001,
  /// and is a crash rather than an annoyance. Routing the drawer through here
  /// makes the working shape the only shape a caller can express.
  ///
  /// **Correction to the record.** IUX-027 reported that the hand-rolled stack
  /// also left the covered page readable to a screen reader, and that finding
  /// is withdrawn: it was measured with `find.bySemanticsLabel`, which reads
  /// `RenderObject.debugSemantics` — a per-render-object cache that keeps its
  /// last value when a subtree simply stops being visited. Walking the
  /// semantics tree the platform is actually given shows the page gone in both
  /// shapes. See the 'IUX-027, withdrawn' test.
  final IuxNavigationDrawer? drawer;

  @override
  Widget build(BuildContext context) {
    final Widget? modal = dialog ?? sheet ?? drawer;
    // Around the Stack, so it covers the modal as well as the page. The modal
    // is slot one and the page is slot zero — siblings — so the medium the page
    // establishes for itself stops at the page. Measured with this layer as the
    // route root: the page read against IUX's body style while the dialog's
    // title, message and dismiss label all read against Flutter's fallback.
    // A confirmation dialog in monospace and yellow rules is the worst place
    // this defect could have surfaced. See `IuxMaterialGround`.
    return IuxMaterialGround(
      child: Stack(
        // The Stack is here whether or not anything is open, and that is the
        // whole of IUX-OVERLAY-001.
        //
        // While the layer returned [child] directly, opening a modal changed the
        // page's depth in the element tree. Flutter cannot reuse an element at a
        // different depth under a different parent widget, so it threw the page
        // away and inflated a new one: every `State` below disposed, every
        // controller rebuilt, every list back to offset zero — and any callback
        // the page had already handed to the modal now closed over a defunct
        // `State`, so the tap that *answered* the dialog threw `setState()
        // called after dispose()`. A modal that destroys the page it interrupts
        // is not an ergonomic cost, it is a crash on the ordinary path.
        //
        // `expand`, unchanged, and now applied while nothing is open as well.
        // That is deliberate rather than incidental: the layer used to hand the
        // page whatever loose constraints it was given while closed and a tight
        // `constraints.biggest` the moment a modal appeared, so the page
        // relaid out — a second, quieter half of the same defect. One
        // arrangement in both states is the point. `passthrough` was tried and
        // rejected: under the loose constraints a `Scaffold` body supplies it
        // shrinks the layer to the page's content, and the modal is then
        // laid out inside a box the size of the page rather than the screen.
        //
        // The cost is that a layer placed in an unbounded box now fails while
        // closed instead of failing when the user opens something. A modal layer
        // that cannot show a modal is not usable there either way, and the early
        // failure is the one a developer can act on.
        fit: StackFit.expand,
        children: <Widget>[
          child,
          // Painted after the page, which is what lets its `BlockSemantics` drop
          // the page from the semantics tree. Reversing the order would leave
          // the page readable to a screen reader while it is unreachable by
          // touch.
          //
          // Nothing here excludes the page a second time. That was written, and
          // then removed: with the Stack permanent, the covered page was
          // measured absent from the semantics tree and from the simulated
          // screen-reader traversal in all three slots, with and without the
          // extra exclusion. A second mechanism no test can distinguish is a
          // mechanism that will rot — the guarantee is pinned by
          // 'the page behind a modal is unreachable' instead, which fails
          // whichever way it is broken.
          if (modal != null) modal,
        ],
      ),
    );
  }
}
