import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../layout/iux_surface.dart';
import '../../semantics/iux_semantic_colors.dart';
import '../../themes/extensions/iux_geometry_theme.dart';

/// A short run of list rows presented as one bounded object.
///
/// ```dart
/// IuxSection(
///   title: l10n.notifications,
///   children: <Widget>[
///     IuxListGroup(
///       children: <Widget>[
///         IuxListItem.selectable(title: l10n.replies, ...),
///         IuxListItem.selectable(title: l10n.mentions, ...),
///       ],
///     ),
///   ],
/// )
/// ```
///
/// **Use it** for a handful of rows that belong together and are all on screen
/// at once — the rows of a settings block, the lines of a summary, a filter
/// list.
///
/// **Do not use it for a long list, and do not look for `IuxList`.** Everything
/// here is built eagerly, so a group of two hundred rows builds two hundred
/// rows. Flutter's `ListView` already solves lazy building, recycling and
/// scroll physics better than a wrapper around it would, and a wrapper would
/// only add a second place for those to go wrong. For a long list, use
/// `ListView.separated` with [IuxListItem] as the item and [IuxListSeparator]
/// as the separator — which is what this widget does internally, without the
/// scrolling.
///
/// **Do not use it to give a screen its structure.** A group draws a boundary;
/// it does not name what is inside. `IuxSection` names a group and publishes
/// that name as a heading landmark, so a screen-reader user has something to
/// navigate by. Put groups inside sections, never the reverse — and the group
/// takes no title of its own, because a second way to write a heading would be
/// a second way to write one that never reaches the heading index.
///
/// ## How this differs from `IuxContentGroup`
///
/// `IuxContentGroup` pads each of its children. That is right for content and
/// wrong for a row: a row's padding has to be *inside* its touch target, or the
/// visible row is larger than the area that responds and the user finds out by
/// tapping somewhere that does nothing. So this group adds no padding, and the
/// rows own theirs. IUX-019 recorded the split rather than guessing at it.
///
/// | | Children | Padding | Reach for it when |
/// | --- | --- | --- | --- |
/// | `IuxContentGroup` | any content | added by the group | the items are parts of one object |
/// | `IuxListGroup` | `IuxListItem` | owned by each row | the items are comparable things |
///
/// ## Rows touch, and that is deliberate
///
/// Adjacent controls elsewhere in IUX keep `kIuxMinimumTargetSpacing` between
/// them. Rows do not, and the reason is that the two risks are not the same
/// one. Vertically stacked rows are each at least the full target height, the
/// separator marks the boundary, and a mis-tap opens the neighbouring item —
/// recoverable with the back button. Two controls sharing a horizontal edge
/// are usually "confirm" and "cancel", where a mis-tap is not. Spacing every
/// row apart would also dissolve the grouping the user reads the list by.
///
/// The separation that *is* enforced is between a row's target and the target
/// of a control inside it, which is where the two outcomes really do differ.
/// See [IuxListItem.trailingAction].
class IuxListGroup extends StatelessWidget {
  /// Creates a bounded run of rows.
  const IuxListGroup({super.key, required this.children});

  /// The rows, in reading order.
  ///
  /// Separated by an [IuxListSeparator] and never padded: a row owns its own
  /// padding so that its target includes it.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // Checked here rather than in the constructor: a list length is not a
    // constant expression, and refusing `const IuxListGroup(...)` to gain an
    // assertion would be a poor trade.
    assert(
      children.isNotEmpty,
      'An empty group draws a bordered box around nothing. A screen reader '
      'announces the container and finds no content in it, which reads as an '
      'interface that failed to load. Render nothing, or render an empty '
      'state that explains itself.',
    );

    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);

    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      if (i > 0) rows.add(const IuxListSeparator());
      rows.add(children[i]);
    }

    // A container whose children stay separate nodes. `explicitChildNodes` is
    // what makes a group of five rows five stops for a screen reader instead
    // of one paragraph. It is the opposite decision from a tappable row, and
    // deliberately so: that row is one control, so it is one stop; a group is
    // several items, so a user has to be able to move between them.
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: IuxSurface(
        role: IuxSurfaceRole.subtle,
        bordered: true,
        // Never elevated, at any profile. The theme resolves elevation to zero
        // under a reduced visual stimulation preference and a shadow is close
        // to invisible in dark conditions, so what is left — surface contrast
        // and an outline — has to be enough on its own.
        child: Padding(
          // Inset by the outline's own width. A row paints its chosen state
          // edge to edge, and the surface draws its border *behind* its child,
          // so without this inset a selected first row would paint over the
          // line that says where the group starts.
          padding: EdgeInsets.all(geometry.borderWidth),
          child: ClipRRect(
            // Clipped, unlike IuxContentGroup, because these children do paint
            // their own backgrounds: a chosen row at the top would otherwise
            // spill square corners past the group's rounded ones.
            borderRadius: BorderRadius.circular(
              math.max(0, geometry.radiusMedium - geometry.borderWidth),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: rows,
            ),
          ),
        ),
      ),
    );
  }
}

/// The line between two list rows.
///
/// ```dart
/// ListView.separated(
///   itemCount: orders.length,
///   separatorBuilder: (_, __) => const IuxListSeparator(),
///   itemBuilder: (BuildContext context, int index) =>
///       IuxListItem.tappable(title: orders[index].reference, ...),
/// )
/// ```
///
/// Public, unlike the separator inside `IuxContentGroup`, because a long list
/// is built with `ListView.separated` rather than with [IuxListGroup] — and a
/// list whose separators are hand-drawn is a list whose separators drift from
/// the ones the rest of the application uses.
///
/// Drawn in the subtle border role, which is exempt from the 3:1 contrast
/// minimum, and that is correct here: the separator repeats a boundary the row
/// spacing already expresses, so a user who cannot see it loses nothing. It is
/// never used to delimit a control, where the exemption would not apply.
///
/// It runs edge to edge. An inset separator implies that the part it skips
/// belongs to the row above, which is true for a leading avatar and false for
/// everything else — and at a large text scale the inset drifts away from
/// whatever it was aligned to.
class IuxListSeparator extends StatelessWidget {
  /// Creates the line drawn between two rows.
  const IuxListSeparator({super.key});

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
