import 'package:flutter/material.dart';

import '../semantics/iux_semantic_colors.dart';
import 'iux_content_width.dart';
import 'iux_spacing_primitives.dart';

/// Which system insets a page consumes.
///
/// Applying `SafeArea` everywhere is how double padding happens: a page adds
/// it, then a sheet inside adds it again, and the content ends up inset twice
/// from a notch that is only there once.
enum IuxPageInsets {
  /// The page consumes the insets. The usual choice for a full screen.
  handled,

  /// The page consumes only the top inset.
  ///
  /// For a screen whose bottom is occupied by navigation that already handles
  /// its own inset.
  topOnly,

  /// The page consumes only the bottom inset.
  bottomOnly,

  /// The page consumes none, leaving them to the application.
  ///
  /// Required for edge-to-edge content that must paint behind the system bars.
  none,
}

/// The frame of a screen: background, safe areas, width, padding and scroll.
///
/// Deliberately not a `Scaffold` replacement. A `Scaffold` owns app bars,
/// sheets and the snack bar host; this owns the content area, and the two
/// compose:
///
/// ```dart
/// Scaffold(
///   appBar: AppBar(title: Text('Orders')),
///   body: IuxPage(
///     child: IuxSection(title: 'Recent', children: <Widget>[...]),
///   ),
/// )
/// ```
///
/// Scrolls by default. A screen that does not scroll is a screen that breaks
/// the moment a user enlarges their text or a keyboard appears, and both
/// happen constantly.
class IuxPage extends StatelessWidget {
  /// Creates a page frame.
  const IuxPage({
    super.key,
    required this.child,
    this.insets = IuxPageInsets.handled,
    this.contentWidth = IuxContentWidth.standard,
    this.scrollable = true,
    this.padding,
    this.background = true,
    this.footer,
    this.scrollController,
  });

  /// The content.
  final Widget child;

  /// Which system insets this page consumes.
  final IuxPageInsets insets;

  /// How wide the content may grow before it stops and centres.
  final IuxContentWidth contentWidth;

  /// Whether the content scrolls when it exceeds the viewport.
  final bool scrollable;

  /// Padding around the content. Defaults to the density-aware page insets.
  final EdgeInsetsGeometry? padding;

  /// Whether to paint the base surface behind the content.
  final bool background;

  /// Content pinned below the scrolling area, such as a primary action.
  ///
  /// Stays reachable without scrolling to the end — which matters most on the
  /// long forms where scrolling to find the confirm button is worst.
  final Widget? footer;

  /// A controller for the scroll view, when the caller needs one.
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final IuxSemanticColors colors = IuxSemanticColors.of(context);
    final EdgeInsetsGeometry resolvedPadding =
        padding ?? IuxInsets.page(context);

    Widget content = Padding(
      padding: resolvedPadding,
      child: IuxReadableWidth(width: contentWidth, child: child),
    );

    if (scrollable) {
      content = SingleChildScrollView(
        controller: scrollController,
        // Always scrollable so the content can be dragged away from under a
        // keyboard even when it would otherwise fit.
        physics: const AlwaysScrollableScrollPhysics(),
        child: content,
      );
    }

    Widget body = footer == null
        ? content
        : Column(
            children: <Widget>[
              Expanded(child: content),
              Padding(
                padding: resolvedPadding,
                child: IuxReadableWidth(
                  width: contentWidth,
                  alignment: Alignment.bottomCenter,
                  child: footer!,
                ),
              ),
            ],
          );

    body = SafeArea(
      top: insets == IuxPageInsets.handled || insets == IuxPageInsets.topOnly,
      bottom:
          insets == IuxPageInsets.handled || insets == IuxPageInsets.bottomOnly,
      left: insets != IuxPageInsets.none,
      right: insets != IuxPageInsets.none,
      child: body,
    );

    if (!background) return body;
    return ColoredBox(color: colors.surface.base, child: body);
  }
}
