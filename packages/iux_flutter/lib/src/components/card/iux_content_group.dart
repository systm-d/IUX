import 'package:flutter/material.dart';

import '../../accessibility/iux_semantics.dart';
import '../../layout/iux_spacing_primitives.dart';
import '../../layout/iux_surface.dart';
import '../../semantics/iux_semantic_colors.dart';
import '../../themes/extensions/iux_geometry_theme.dart';

/// Several related items presented as one object, on one shared surface.
///
/// ```dart
/// IuxSection(
///   title: l10n.delivery,
///   children: <Widget>[
///     IuxContentGroup(
///       children: <Widget>[address, window, instructions],
///     ),
///   ],
/// )
/// ```
///
/// **Use it** when a handful of items are parts of one thing rather than
/// things that merely sit near each other — the lines of an address, the rows
/// of a settings block, the fields of a summary. The shared surface and the
/// separators say "these belong to one object"; spacing alone only says "these
/// are near each other", and a user has to guess which was meant.
///
/// **Do not use it for a long list.** Everything here is built eagerly, so a
/// group of two hundred rows builds two hundred rows. Lists are IUX-020.
///
/// **Do not use it when the items are separate objects.** Three orders are
/// three objects; each one is an [IuxCard]. Enclosing them in a single group
/// tells the user they are parts of one order, which is a claim about their
/// data and not about their layout.
///
/// ## Three ways to group, and the difference between them
///
/// | | What it does | What a screen reader gets |
/// | --- | --- | --- |
/// | `IuxSection` | names a group and spaces its children apart | a heading landmark to navigate by |
/// | `IuxContentGroup` | encloses several items in one object | a container boundary, no name |
/// | [IuxCard] | presents one object with a visible boundary | a container boundary, no name |
///
/// A group takes no title, on purpose. `IuxSection` already publishes a
/// heading landmark, and duplicating that here would give two ways to write
/// the same heading with only one of them reaching a screen reader's heading
/// index. Wrap a group in a section when it needs a name.
///
/// ## Grouping does not rest on elevation
///
/// The group is bordered and never elevated. The theme resolves elevation to
/// zero under a reduced visual stimulation preference, and a shadow is close
/// to invisible in dark conditions, so a group that relied on one would simply
/// stop being a group for some users. Surface contrast, an outline and the
/// separators between items all survive that, and all of them are measurable.
///
/// ## Reading order
///
/// Items are laid out in the order given, and separators carry no semantics of
/// their own. What a sighted user reads top to bottom is what a screen reader
/// announces first to last.
class IuxContentGroup extends StatelessWidget {
  /// Creates a group of related items sharing one surface.
  const IuxContentGroup({super.key, required this.children});

  /// The items, in reading order.
  ///
  /// Each one is padded by the group, so a caller writes content and not
  /// spacing. Items that own their own padding — an interactive row whose
  /// target has to include it — are IUX-020 and are not modelled here.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // Checked here rather than in the constructor: a list length is not a
    // constant expression, and refusing `const IuxContentGroup(...)` to gain
    // an assertion would be a poor trade.
    assert(
      children.isNotEmpty,
      'An empty group draws a bordered box around nothing. A screen reader '
      'announces the container and finds no content in it, which reads as an '
      'interface that failed to load. Render nothing, or render an empty '
      'state that explains itself.',
    );

    final EdgeInsets padding = IuxInsets.surface(context);

    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      if (i > 0) rows.add(const _IuxGroupSeparator());
      rows.add(Padding(padding: padding, child: children[i]));
    }

    // A container whose children stay separate nodes. `explicitChildNodes` is
    // what makes a group of five items five stops for a screen reader instead
    // of one paragraph: an item that does not declare itself a semantic
    // container would otherwise have its text absorbed into this node, and the
    // user would hear the whole group read out with no way to move within it.
    //
    // It is the opposite decision from a tappable IuxCard, and deliberately
    // so. That card is one control, so it is one stop. A group is several
    // items, so it is several.
    return IuxSemantics.contentContainer(
      child: IuxSurface(
        role: IuxSurfaceRole.subtle,
        bordered: true,
        // Never elevated, at any profile. See the class documentation.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: rows,
        ),
      ),
    );
  }
}

/// The line between two items of a group.
///
/// Drawn in the subtle border role, which is exempt from the 3:1 contrast
/// minimum, and that is correct here: the separator repeats a boundary the
/// padding already expresses, so a user who cannot see it loses nothing. It is
/// never used to delimit a control, where the exemption would not apply.
///
/// It runs edge to edge. An inset separator implies that the part it skips
/// belongs to the row above, which is true for a leading avatar and false for
/// everything else — and at a large text scale the inset drifts away from
/// whatever it was aligned to.
class _IuxGroupSeparator extends StatelessWidget {
  const _IuxGroupSeparator();

  @override
  Widget build(BuildContext context) {
    final IuxSemanticColors colors = IuxSemanticColors.of(context);
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(color: colors.border.subtle),
      // The width follows the theme, so a high contrast profile thickens the
      // separator instead of recolouring it — a line that changes hue under
      // high contrast starts competing with focus for the same meaning.
      child: SizedBox(height: geometry.borderWidth, width: double.infinity),
    );
  }
}
