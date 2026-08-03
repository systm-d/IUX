import 'package:flutter/material.dart';

import '../accessibility/iux_accessibility.dart';

/// How wide a block of content is allowed to grow.
///
/// The constraint exists for reading comfort, not for decoration: a line that
/// spans a tablet is hard to track back to the start of the next one.
enum IuxContentWidth {
  /// A single short input or a confirmation. Very constrained.
  narrow,

  /// Running prose. Capped near the length a reader can scan comfortably.
  reading,

  /// Mixed content: forms, lists, cards.
  standard,

  /// Dense content that benefits from room, such as a table.
  wide,

  /// No cap. The content fills whatever it is given.
  fluid,
}

/// Resolves reading-width caps, scaled to the user's text size.
///
/// The caps are expressed in characters rather than pixels, then converted
/// using the text size actually in force. A fixed pixel cap silently halves
/// the number of characters per line when a user doubles their text size —
/// producing a narrow column of enlarged text, which is the opposite of what
/// they asked for.
abstract final class IuxContentWidthResolver {
  /// Approximate characters per line for each cap.
  ///
  /// The 60–75 character range for prose is long-standing typographic
  /// guidance rather than a measured optimum, and it varies by script. Treat
  /// these as defaults, not as findings.
  static int charactersFor(IuxContentWidth width) => switch (width) {
        IuxContentWidth.narrow => 35,
        IuxContentWidth.reading => 70,
        IuxContentWidth.standard => 100,
        IuxContentWidth.wide => 140,
        IuxContentWidth.fluid => 0,
      };

  /// The maximum width in logical pixels at [context], or null for no cap.
  static double? maxWidthFor(BuildContext context, IuxContentWidth width) {
    if (width == IuxContentWidth.fluid) return null;
    // Roughly half the font size per character for a proportional Latin face.
    // Crude, and deliberately so: a precise measurement would need the actual
    // font, and being slightly generous is safer than clipping.
    final double scaledBody = IuxAccessibility.of(context).scaleText(16);
    return charactersFor(width) * scaledBody * 0.5;
  }
}

/// Caps its child's width for readability, and centres it.
///
/// Below the cap the child simply fills the available width, so this never
/// makes a narrow screen narrower.
class IuxReadableWidth extends StatelessWidget {
  /// Constrains [child] to [width].
  const IuxReadableWidth({
    super.key,
    required this.child,
    this.width = IuxContentWidth.standard,
    this.alignment = Alignment.topCenter,
  });

  /// The content.
  final Widget child;

  /// How wide the content may grow.
  final IuxContentWidth width;

  /// Where the content sits once it stops growing.
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final double? maxWidth =
        IuxContentWidthResolver.maxWidthFor(context, width);
    if (maxWidth == null) return child;
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
