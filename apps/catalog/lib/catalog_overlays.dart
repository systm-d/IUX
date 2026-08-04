import 'package:flutter/material.dart';
import 'package:iux_flutter/iux_flutter.dart';

/// The overlays the page owns on behalf of whichever section is showing.
///
/// A dialog, a bottom sheet and a navigation drawer are all handed to one
/// `IuxModalLayer` at page level, and the transient strip to one
/// `IuxTransientLayer` above it. A section that opened its own overlay from
/// wherever its button happened to sit would be deciding layering, which is
/// how two modals end up open at once with the way out of neither visible.
///
/// So the page owns them, exactly as an application would, and the sections
/// hand up a builder rather than a widget. A builder, because
/// `IuxDestructiveActionController.dialog` rebuilds on every read for a
/// reason: wording or availability that changed between frames has to reach an
/// overlay that is already open, and a widget captured once cannot.
class CatalogOverlays extends ChangeNotifier {
  /// Creates the overlay owner and the one controller that computes its own.
  CatalogOverlays() {
    _flow = IuxDestructiveFlowController(
      semantics: const IuxActionSemantics(
        label: 'Delete the March invoice',
      ),
      scope: IuxDestructiveScope.items,
      wayBack: _undoOffer,
      onDestroy: _recordDestroyed,
    );
    _flow.addListener(notifyListeners);
  }

  IuxDialog Function()? _dialog;
  IuxBottomSheet Function()? _sheet;
  IuxNavigationDrawer Function()? _drawer;
  IuxTransientMessage? _notice;
  late final IuxDestructiveFlowController _flow;
  final Map<String, int> _tally = <String, int>{};
  int _destroyed = 0;

  /// The undo offer the flow starts with.
  ///
  /// Built here rather than in the panel because [onDestroy] is fixed at
  /// construction and the way back has to agree with it: an offer whose undo
  /// restored something a different counter was tracking would demonstrate
  /// nothing.
  IuxUndoOffer get _undoOffer => IuxUndoOffer(
        notice: 'The March invoice was deleted',
        undoLabel: 'Undo',
        dismissLabel: 'Dismiss',
        onUndo: _recordRestored,
      );

  /// The destructive flow, whose confirmation and way back the page places.
  ///
  /// The one pattern in the library that computes its own overlays rather than
  /// being handed them, which is why it lives with the page's other overlays
  /// instead of inside the panel that configures it. With no `IuxModalLayer`
  /// the confirmation is computed and never shown; with no `IuxTransientLayer`
  /// the way back is computed and never offered and the deletion simply
  /// happens. Nothing detects either, because nothing can from where the
  /// trigger sits.
  IuxDestructiveFlowController get flow => _flow;

  /// The undo offer, so a panel can hand it back to [reconfigure] unchanged.
  IuxUndoOffer get undoOffer => _undoOffer;

  /// How many invoices the flow has destroyed, net of undos.
  int get destroyed => _destroyed;

  /// How many times [key] has happened.
  int tally(String key) => _tally[key] ?? 0;

  /// Records that [key] happened once more.
  ///
  /// Counters live here rather than in the panel that opened the overlay, and
  /// that is not tidiness. `IUX-OVERLAY-001` rebuilds the page's subtree when
  /// a modal opens, which resets the scroll position — and a panel that had
  /// been scrolled to is then disposed. A callback closing over that panel's
  /// `setState` fires on a dead `State` and throws
  /// "setState() called after dispose()", which is how the harness found the
  /// behaviour. Anything an overlay's own controls report has to outlive the
  /// widget that opened it.
  void record(String key) {
    _tally[key] = tally(key) + 1;
    notifyListeners();
  }

  /// Re-arms the flow with a different proportionality.
  ///
  /// Separate from the getter because `update` is what re-runs the
  /// proportionality assertions, and running them during a build would report
  /// an illegal pairing from whichever frame happened to notice.
  void reconfigure({
    required IuxDestructiveScope scope,
    required IuxWayBack wayBack,
    IuxConfirmationPrompt? prompt,
  }) {
    _flow.update(
      semantics: const IuxActionSemantics(label: 'Delete the March invoice'),
      scope: scope,
      wayBack: wayBack,
      prompt: prompt,
    );
    notifyListeners();
  }

  /// The dialog currently open, or null.
  ///
  /// The flow's own confirmation wins, because it is the only one of the two
  /// that a user reached by pressing something rather than by the harness
  /// deciding to show it.
  IuxDialog? get dialog => _flow.dialog ?? _dialog?.call();

  /// The bottom sheet currently open, or null.
  IuxBottomSheet? get sheet => _sheet?.call();

  /// The navigation drawer currently open, or null.
  IuxNavigationDrawer? get drawer => _drawer?.call();

  /// The transient message currently showing, or null.
  IuxTransientMessage? get notice => _flow.notice ?? _notice;

  /// Whether any modal is open.
  ///
  /// Read by the section list: switching section while a modal covers the
  /// screen would leave the modal describing a section that is no longer
  /// underneath it.
  bool get hasModal =>
      _dialog != null ||
      _sheet != null ||
      _drawer != null ||
      _flow.isConfirming;

  /// Opens [build]'s dialog, closing whatever else was open.
  ///
  /// `IuxModalLayer` asserts that at most one of its three slots is filled, so
  /// the exclusion is enforced here rather than left to the caller: a section
  /// that opened a sheet over a dialog would take the application down in
  /// debug and stack them in release.
  void showDialog(IuxDialog Function() build) {
    _closeModals();
    _dialog = build;
    notifyListeners();
  }

  /// Opens [build]'s bottom sheet, closing whatever else was open.
  void showSheet(IuxBottomSheet Function() build) {
    _closeModals();
    _sheet = build;
    notifyListeners();
  }

  /// Opens [build]'s navigation drawer, closing whatever else was open.
  void showDrawer(IuxNavigationDrawer Function() build) {
    _closeModals();
    _drawer = build;
    notifyListeners();
  }

  /// Closes whichever modal is open. Safe when none is.
  ///
  /// Includes the flow's confirmation, which is the one modal this class did
  /// not open: leaving a question about deleting an invoice on screen after
  /// the section that asked it has gone would be a dialog with nothing behind
  /// it, and answering it would destroy something the user can no longer see.
  void closeModal() {
    if (!hasModal) return;
    if (_flow.isConfirming) _flow.cancel();
    _closeModals();
    notifyListeners();
  }

  /// Shows [message] in the transient strip, replacing whatever was there.
  ///
  /// Replacing is the channel's own rule, not this class's: one message at a
  /// time and no history. What it replaced cannot be recovered.
  void showNotice(IuxTransientMessage message) {
    _notice = message;
    notifyListeners();
  }

  /// Removes whichever transient message is showing.
  ///
  /// Dispatches, because `IuxTransientLayer` reports a dismissal without
  /// saying which message it was: the layer sees one message at a time and
  /// has no idea two owners are feeding it.
  void dismissNotice() {
    if (_flow.notice != null) {
      _flow.dismissNotice();
      return;
    }
    if (_notice == null) return;
    _notice = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _flow.removeListener(notifyListeners);
    _flow.dispose();
    super.dispose();
  }

  void _recordDestroyed() {
    _destroyed++;
    notifyListeners();
  }

  void _recordRestored() {
    if (_destroyed > 0) _destroyed--;
    notifyListeners();
  }

  void _closeModals() {
    _dialog = null;
    _sheet = null;
    _drawer = null;
  }
}
