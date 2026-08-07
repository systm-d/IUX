import 'package:flutter/material.dart';

import '../semantics/iux_semantic_colors.dart';

/// The Material medium a route root needs, established by the components that
/// are route roots.
///
/// ## What it fixes
///
/// Flutter resolves a bare `Text` against the nearest `DefaultTextStyle`. The
/// one `MaterialApp` installs at the root is deliberately hostile — Flutter's
/// own `debugLabel` for it reads *"fallback style; consider putting your text
/// in a Material"* — and it is monospace, 48-point, and double-underlined in
/// yellow. `Material` is what replaces it; in an ordinary Material application
/// that is `Scaffold`'s job, and a route whose root is not a `Scaffold` never
/// gets one.
///
/// A caller writes that route root. This library used to answer the problem in
/// documentation: `IuxScreen` said it was not a `Scaffold` replacement and left
/// the ancestor to the caller. **Two consumer applications out of two got it
/// wrong**, which is not an error rate — it is an API telling you something.
///
/// - One had four screens inside a chassis `Scaffold` and one screen pushed as
///   its own route. That one screen rendered yellow. Its two widget tests
///   passed throughout, because the test host supplied the `Scaffold` that the
///   route did not.
/// - The other had five screens, each a route root, and no `Scaffold` anywhere
///   in the application. Every screen rendered yellow. It had **golden tests
///   over all five**, and the committed PNGs were pictures of the defect: under
///   `flutter_test` every glyph is a filled black box, so a thin yellow rule
///   beneath a black box reads as a style flourish. The goldens were reviewed
///   by eye and approved.
///
/// The second case is the argument. A golden suite is the strongest instrument
/// this kind of defect can meet, and it recorded the defect as the expectation.
/// A contract that only documentation enforces is a contract that measurement
/// cannot see.
///
/// ## Why transparency
///
/// [MaterialType.transparency] paints no background, absorbs no hit test, and
/// clips nothing at the default `Clip.none`. It contributes exactly the two
/// things that were missing — a text style and an ink surface — and leaves
/// colour to the semantic tokens, which is where this library keeps it. A
/// `Material` with a colour would paint `canvasColor` under every page and
/// take the surface decision away from `IuxSurface`.
///
/// ## Why the style replaces rather than merges
///
/// `Material` defaults its text style to `Theme.of(context).textTheme
/// .bodyMedium`, which under an IUX theme is already the `body` role —
/// `IuxResolvedTheme` installs `typography.toTextTheme()`. The style is passed
/// explicitly only to add a colour: the role styles name size, height and
/// weight, so a default without one resolves to the engine's black on a dark
/// page. Every IUX component sets its own colour and so never noticed; a
/// caller's bare `Text` would.
///
/// It must **replace** the ambient style, never merge onto it. Merging is the
/// trap: the style being displaced is the fallback, and `bodyMedium` sets
/// neither `fontFamily` nor `decoration`, so a merge would carry the monospace
/// and the yellow rules straight through the fix. `DefaultTextStyle`'s plain
/// constructor replaces, which is what `Material` uses.
///
/// ## Nesting is expected
///
/// `IuxScreen` establishes one for the bar and the page together — the bar is
/// the page's sibling, so a ground inside the page cannot reach it — and
/// `IuxPage` establishes one because it is documented as a route root on its
/// own. Composed, that is two. Nested transparent Materials are the ordinary
/// Material idiom (`Scaffold` inside, then `Card`, then `ListTile`), they cost
/// five widgets that paint nothing, and the inner one resolves to the same
/// style as the outer.
///
/// Not exported: a caller never names this. The components that are route roots
/// use it, and that is the whole surface.
class IuxMaterialGround extends StatelessWidget {
  /// Establishes the medium around [child].
  const IuxMaterialGround({super.key, required this.child});

  /// The subtree that gets a Material to resolve against.
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
        type: MaterialType.transparency,
        textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: IuxSemanticColors.of(context).content.primary,
            ),
        child: child,
      );
}
