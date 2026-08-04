import 'package:flutter/widgets.dart';
import 'package:iux_flutter/iux_flutter.dart';

/// An app bar over a page, which is what every screen in this application is.
///
/// This widget exists because the framework does not compose the two, and it is
/// the single largest piece of framework work this application had to do for
/// itself. `IuxPage` and `IuxAppBar` are siblings by design —
/// `docs/components/app-bar.md` says so, and says a composition widget owning
/// both "belongs to a later mission". Until it lands, every application that
/// uses both writes this file and has to discover three things the hard way.
///
/// ## 1. The top inset is applied twice
///
/// `IuxAppBar` wraps itself in a `SafeArea`, which removes the top inset for
/// **its own subtree only**. A sibling `IuxPage` on the default
/// `IuxPageInsets.handled` still sees the full `MediaQuery` padding and insets
/// the content again. Measured with a 40-pixel top padding: the first line of
/// content starts at y 152 without the [MediaQuery.removePadding] below and at
/// y 112 with it — exactly one status bar of daylight that nobody asked for.
/// Nothing asserts, and on a device with no cutout nothing is visibly wrong.
///
/// `IuxPageInsets` cannot express the fix: `none` would also give up the left
/// and right insets, which a landscape cutout still needs, and there is no
/// `exceptTop`.
///
/// ## 2. The chrome does not fit at a large text scale
///
/// The obvious frame is `Column(children: [bar, Expanded(page)])`. It overflows,
/// because neither component owns the total height and each honours its own
/// degradation independently. Measured on a 320x640 window with three
/// destinations:
///
/// | text | `IuxAppBar` | `IuxBottomNavigation` | left for content |
/// | --- | --- | --- | --- |
/// | 100% | 56 | 92 | 492 |
/// | 200% | 120 | 240 | 280 |
/// | 250% | 148 | 316 | 176 |
/// | 300% | 260 | 408 | **-28** |
///
/// At 300% the bar and the navigation want 668 pixels of a 640-pixel window, so
/// the plain `Column` reports *A RenderFlex overflowed by 28 pixels on the
/// bottom*. `IuxBottomNavigation` documents its own answer to not fitting — it
/// scrolls — and takes its 408 pixels first; nothing then defends the content.
///
/// ## 3. The usual fix for (2) is unavailable
///
/// The standard Flutter answer is fill-or-scroll: a `SingleChildScrollView`
/// holding a `ConstrainedBox(minHeight: viewport)` around an `IntrinsicHeight`,
/// so the bar stays pinned while there is room and scrolls away when there is
/// not. It throws: *LayoutBuilder does not support returning intrinsic
/// dimensions*. `IuxAppBar` uses a `LayoutBuilder` internally
/// (`iux_app_bar.dart:339`) to decide whether the title shares a row with the
/// controls, and a `LayoutBuilder` can never report an intrinsic height. So no
/// IUX screen containing an app bar can take part in `IntrinsicHeight`,
/// `IntrinsicWidth`, or a `Table` with intrinsic sizing.
///
/// What is left is to scroll the whole screen, bar included. The cost is a real
/// one and is stated rather than hidden: **the title is not pinned.** It
/// scrolls off the top like any other content, at every text scale, because the
/// composition cannot be made conditional without the intrinsic height that
/// does not exist.
class PilotScreen extends StatelessWidget {
  /// Creates a screen frame.
  const PilotScreen({
    super.key,
    required this.title,
    required this.child,
    this.leading,
    this.actions = const <IuxIconButton>[],
  });

  /// The name of the screen, already localised.
  final String title;

  /// The content of the page.
  final Widget child;

  /// The way up and out, or null on a root screen.
  final IuxAppBarLeading? leading;

  /// Screen-level actions.
  final List<IuxIconButton> actions;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        // Always scrollable, like `IuxPage`'s own, so the content can be
        // dragged out from under a keyboard even when it would otherwise fit.
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            IuxAppBar(title: title, leading: leading, actions: actions),
            MediaQuery.removePadding(
              context: context,
              removeTop: true,
              // This view owns the scroll now, so the page must not open a
              // second one inside it. The page shrink-wraps; the surface below
              // it is the scaffold, which `IuxResolvedTheme` paints with the
              // same `colors.surface.base` the page would have used.
              child: IuxPage(scrollable: false, child: child),
            ),
          ],
        ),
      );
}
