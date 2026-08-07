import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../layout/iux_material_ground.dart';
import '../../layout/iux_page.dart';
import 'iux_app_bar.dart';

/// The largest share of a screen its top chrome may take.
///
/// Half, and it is a rule about what a screen *is* rather than a tuned number:
/// a screen is content with chrome around it, so the moment the chrome wants
/// more than the content it has stopped being chrome. Above this the bar keeps
/// every pixel of its title and scrolls inside the strip it was given — the
/// degradation `IuxBottomNavigation` already chose for the other end of the
/// screen (IUX-024).
///
/// It only ever binds when an enlarged title and a short window are fighting
/// over the same pixels. At every ordinary size the bar asks for less than this
/// and gets exactly what it asked for.
///
/// Private: a caller who could raise it would be choosing, on one screen, that
/// the name of the screen matters more than the screen. That is the decision
/// this component exists to have made once.
const double _maximumChromeShare = 0.5;

/// An app bar over a page, which is what most screens are.
///
/// ```dart
/// MaterialPageRoute<void>(
///   builder: (BuildContext context) => IuxScreen(
///     appBar: IuxAppBar(
///       title: l10n.orders,
///       leading: IuxAppBarLeading.back(
///         label: l10n.backToHome,
///         onActivate: controller.goBack,
///       ),
///     ),
///     page: IuxPage(child: content),
///   ),
/// )
/// ```
///
/// **Use it** wherever a screen has both. It is two parameters wide on purpose:
/// there is no configuration to get right, and therefore no reason to write the
/// `Column` by hand.
///
/// **Do not use it** for a screen with no name worth showing — that is an
/// `IuxPage` on its own — nor as a `Scaffold` replacement. It owns the top
/// chrome and the content, and nothing else: navigation goes around it
/// (`IuxAdaptiveNavigation`), and so does the modal layer, and a `Scaffold`
/// still owns the floating action button, the drawers and the snack bars.
///
/// ## It no longer needs a `Scaffold` to render
///
/// It used to. This component sat directly under a route and required the
/// caller to supply a `Material` ancestor, and the example above began with
/// `Scaffold(body: …)` for that reason and no other. **Two consumer
/// applications out of two got it wrong** — one on the single screen it pushed
/// as its own route, one on all five of its screens — and both shipped a build
/// where every word on the affected screens, the title in this bar included,
/// rendered in Flutter's *"you forgot Material"* fallback: monospace, double
/// underlined in yellow.
///
/// Neither test suite could see it, and one of them was a golden suite over all
/// five screens whose committed PNGs were pictures of the defect. See
/// `IuxMaterialGround`, which this now establishes, for why that happened and
/// why documentation was the wrong instrument for the job.
///
/// A `Scaffold` above this is still correct and still recommended — it is what
/// paints the scaffold background and owns the rest of the chassis — and
/// nothing about it changed. It is simply no longer what stands between a
/// screen and legible text.
///
/// ## Why this exists at all
///
/// `IuxAppBar` and `IuxPage` are the most-repeated composition any application
/// writes, and written as siblings in a `Column` they carry three traps that
/// every application discovers separately (`IUX-APPBAR-PAGE-001`, measured by
/// the pilot application before this component existed).
///
/// **1. The top inset was spent twice.** The bar consumes it inside its own
/// `SafeArea`, which removes it *for the bar's subtree only*; a sibling page
/// still sees the full `MediaQuery` padding and insets the content again.
/// Measured with a 40-pixel inset: the first line of content landed at y 188
/// instead of y 148. Nothing asserted, and on a device with no cutout nothing
/// looked wrong. Here the page is given a `MediaQuery` with the top padding
/// already removed, so the inset is spent once — and the page can be left on
/// its default `IuxPageInsets.handled`, which still takes the side insets a
/// landscape cutout needs.
///
/// **2. Nothing owned the total height.** The bar has no fixed height by
/// design, so at a large text scale it can want more room than the window has
/// left after navigation. A `Column` in that position overflows and paints
/// outside itself: measured on a 320x640 window with three destinations,
/// *A RenderFlex overflowed by 248 pixels* at 300% text, with the page laid out
/// at zero height. This component owns it: the chrome may take at most
/// [_maximumChromeShare] of the box, the page takes the rest, and the bar
/// scrolls its own strip rather than overflowing anything.
///
/// **3. The standard fix was structurally unavailable.** Fill-viewport-or-
/// scroll needs `IntrinsicHeight`, which threw *LayoutBuilder does not support
/// returning intrinsic dimensions* because the bar decided its arrangement in
/// one. Both this frame and the bar now answer intrinsic queries, so that
/// arrangement works — and this component does not need it, which is the more
/// useful half: it measures the chrome and hands the page what is left, so it
/// never asks the caller's content how tall it would like to be. Content that
/// cannot answer that question — a nested `ListView`, an `IuxListItem`, or
/// anything else built on a `LayoutBuilder` — is laid out here without
/// complaint.
///
/// ## What happens when it does not fit
///
/// Decided, in this order, rather than emergent:
///
/// 1. **The page keeps half the box.** It is why the screen exists, and it
///    scrolls, so what does not fit is still reachable.
/// 2. **The bar takes what its title needs**, up to the other half. Below that
///    it is exactly as tall as it asks to be, which is every ordinary case.
/// 3. **Past that the bar's strip scrolls.** Nothing is clipped and nothing is
///    abbreviated: the whole title is still rendered, still a heading, and a
///    screen reader reaches all of it without scrolling anything.
///
/// The bottom chrome is not in this list because it is not in this widget.
/// `IuxAdaptiveNavigation` bounds the navigation bar by the window and hands
/// this component what is left; this component then fits inside that. Two
/// owners, one boundary between them, neither able to overflow the other.
///
/// ## Measured
///
/// A 320x640 window, a back affordance, one action, a title of twenty-nine
/// characters, and three destinations under an `IuxAdaptiveNavigation`. The bar
/// and the page here are what each was laid out at; *wanted* is the height the
/// bar asks for when nothing bounds it.
///
/// | text | wanted | bar | page | the same tree as siblings |
/// | --- | --- | --- | --- | --- |
/// | 100% | 148 | 148 | 400 | 148 / 400 |
/// | 150% | 282 | 230 | 230 | 282 / 178 |
/// | 200% | 360 | 212 | 212 | 360 / 64 |
/// | 250% | 510 | 178 | 178 | **overflowed by 154**, page 0 |
/// | 300% | 772 | 136 | 136 | **overflowed by 500**, page 0 |
///
/// The page never loses room to this rule; it only ever gains it. The bar gives
/// up height only where the page would otherwise have had less than half, which
/// on this window starts at 150% and on 360x800 at 200%.
class IuxScreen extends StatelessWidget {
  /// Creates a screen: a bar over a page.
  const IuxScreen({
    super.key,
    required this.appBar,
    required this.page,
  });

  /// The top of the screen.
  ///
  /// Typed as [IuxAppBar] rather than as a `Widget`, for the reason the bar
  /// types its own actions as `IuxIconButton`: this component makes promises
  /// about the thing in this slot — that it spends the top inset, that it
  /// scrolls rather than overflows when the box is short — and it can only keep
  /// them about a component that behaves that way. A `Widget` slot would turn
  /// both promises into documentation.
  final IuxAppBar appBar;

  /// The content of the screen.
  ///
  /// Leave it on the default [IuxPageInsets.handled]. The top inset is already
  /// removed from the `MediaQuery` this page is given, so `handled` takes the
  /// side and bottom insets that are genuinely still exposed and adds nothing
  /// at the top. The old advice — `IuxPageInsets.bottomOnly` under a bar — is
  /// what a caller had to work out for themselves, and it is now neither
  /// necessary nor harmful.
  final IuxPage page;

  @override
  Widget build(BuildContext context) => IuxMaterialGround(
        // Around both halves, not inside the page: the bar is the page's
        // sibling, so a ground established within the page cannot reach it —
        // which is why a screen missing this rendered its *title* in the
        // fallback style too.
        child: _IuxScreenFrame(
          bar: appBar,
          body: MediaQuery.removePadding(
            context: context,
            // The bar consumed it, inside its own background, and a `SafeArea`
            // only removes what it consumes for its own subtree. This is the
            // sibling case that removal cannot reach, and the whole reason a
            // component owns both halves.
            removeTop: true,
            child: page,
          ),
        ),
      );
}

/// The two halves of a screen.
enum _IuxScreenSlot {
  /// The top chrome.
  bar,

  /// The content, and everything the page wraps around it.
  body,
}

/// The frame that owns the height, and refuses to give more of it to the chrome
/// than the content.
class _IuxScreenFrame
    extends SlottedMultiChildRenderObjectWidget<_IuxScreenSlot, RenderBox> {
  const _IuxScreenFrame({required this.bar, required this.body});

  final Widget bar;
  final Widget body;

  @override
  Iterable<_IuxScreenSlot> get slots => _IuxScreenSlot.values;

  @override
  Widget? childForSlot(_IuxScreenSlot slot) => switch (slot) {
        _IuxScreenSlot.bar => bar,
        _IuxScreenSlot.body => body,
      };

  @override
  _RenderIuxScreenFrame createRenderObject(BuildContext context) =>
      _RenderIuxScreenFrame();
}

/// Allocates the height: chrome first but bounded, content everything else.
///
/// A render object rather than a `LayoutBuilder`, for the reason the bar stopped
/// using one: a `LayoutBuilder` cannot answer an intrinsic query, and a screen
/// that cannot be asked how tall it is cannot be placed in an `IntrinsicHeight`,
/// an intrinsic `Table` or a `SliverFillRemaining(hasScrollBody: false)`. It
/// also does the allocation in one pass instead of rebuilding during layout.
class _RenderIuxScreenFrame extends RenderBox
    with SlottedContainerRenderObjectMixin<_IuxScreenSlot, RenderBox> {
  RenderBox get _bar => childForSlot(_IuxScreenSlot.bar)!;
  RenderBox get _body => childForSlot(_IuxScreenSlot.body)!;

  @override
  Iterable<RenderBox> get children {
    final RenderBox? bar = childForSlot(_IuxScreenSlot.bar);
    final RenderBox? body = childForSlot(_IuxScreenSlot.body);
    return <RenderBox>[
      if (bar != null) bar,
      if (body != null) body,
    ];
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! BoxParentData) child.parentData = BoxParentData();
  }

  /// The whole allocation, shared by [performLayout] and [computeDryLayout].
  Size _arrange(
    BoxConstraints constraints,
    ChildLayouter layoutChild, {
    void Function(RenderBox child, Offset offset)? positionChild,
  }) {
    final bool acrossTheWidth = constraints.hasBoundedWidth;
    // The box to divide up. Normally the height this was given; inside a scroll
    // view there is no end to it, and then the floor is the answer — a
    // `ConstrainedBox(minHeight: viewport)` under a `SingleChildScrollView` is
    // how a caller says "fill the viewport", and filling it is what the page's
    // background and pinned footer need. With neither, nothing is bounded and
    // both children take the height they ask for.
    final double? total = constraints.hasBoundedHeight
        ? constraints.maxHeight
        : (constraints.minHeight > 0 ? constraints.minHeight : null);

    BoxConstraints across(BoxConstraints inner) => acrossTheWidth
        ? inner.copyWith(
            minWidth: constraints.maxWidth,
            maxWidth: constraints.maxWidth,
          )
        : inner;

    final Size barSize = layoutChild(
      _bar,
      across(
        BoxConstraints(
          maxHeight:
              total == null ? double.infinity : total * _maximumChromeShare,
        ),
      ),
    );
    final Size bodySize = layoutChild(
      _body,
      across(
        total == null
            ? const BoxConstraints()
            // Tight, not loose: the page fills what it was given, so a pinned
            // footer stays pinned and a centred empty state stays centred
            // instead of collapsing to the height of its own text.
            : BoxConstraints.tightFor(
                height: math.max(0, total - barSize.height)),
      ),
    );

    final double width = acrossTheWidth
        ? constraints.maxWidth
        : math.max(barSize.width, bodySize.width);

    if (positionChild != null) {
      positionChild(_bar, Offset.zero);
      positionChild(_body, Offset(0, barSize.height));
    }
    return Size(width, total ?? barSize.height + bodySize.height);
  }

  /// How tall the screen would like to be: the chrome it asks for, plus the
  /// content it holds.
  ///
  /// Deliberately not the allocation above. An intrinsic query asks what this
  /// wants, and what it wants is a bar at its natural height over a page at
  /// its natural height; the share only decides how a shortage is settled.
  @override
  double computeMaxIntrinsicHeight(double width) =>
      _bar.getMaxIntrinsicHeight(width) + _body.getMaxIntrinsicHeight(width);

  @override
  double computeMinIntrinsicHeight(double width) =>
      _bar.getMinIntrinsicHeight(width) + _body.getMinIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicWidth(double height) => math.max(
        _bar.getMaxIntrinsicWidth(height),
        _body.getMaxIntrinsicWidth(height),
      );

  @override
  double computeMinIntrinsicWidth(double height) => math.max(
        _bar.getMinIntrinsicWidth(height),
        _body.getMinIntrinsicWidth(height),
      );

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.constrain(
        _arrange(constraints, ChildLayoutHelper.dryLayoutChild),
      );

  @override
  void performLayout() {
    size = constraints.constrain(
      _arrange(
        constraints,
        ChildLayoutHelper.layoutChild,
        positionChild: (RenderBox child, Offset offset) =>
            (child.parentData! as BoxParentData).offset = offset,
      ),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final RenderBox child in children) {
      context.paintChild(
        child,
        (child.parentData! as BoxParentData).offset + offset,
      );
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    // Front to back: the page is painted after the bar, so it is asked first.
    for (final RenderBox child in children.toList().reversed) {
      final BoxParentData parentData = child.parentData! as BoxParentData;
      final bool hit = result.addWithPaintOffset(
        offset: parentData.offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) =>
            child.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }
}
