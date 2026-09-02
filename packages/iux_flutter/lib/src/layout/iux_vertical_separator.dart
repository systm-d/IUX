import 'package:flutter/material.dart';

import '../semantics/iux_semantic_colors.dart';
import '../themes/extensions/iux_geometry_theme.dart';

/// The line between two columns of one block.
///
/// ```dart
/// SizedBox(
///   child: Row(
///     crossAxisAlignment: CrossAxisAlignment.stretch,
///     children: <Widget>[
///       Expanded(child: nights),
///       const IuxVerticalSeparator(),
///       Expanded(child: days),
///       const IuxVerticalSeparator(),
///       Expanded(child: rain),
///     ],
///   ),
/// )
/// ```
///
/// **Use it** where one block is read in columns and the columns are peers — a
/// summary card whose three figures belong to the same subject, a dense row
/// whose facts describe the same item.
///
/// **Do not use it** between two things that are not peers: a line implies the
/// two sides are the same kind of thing, and a rule between a label and its
/// value says they are two readings. Do not use it to separate rows — that is
/// [IuxListSeparator], and it runs the other way. Do not use it to delimit a
/// control: this is drawn in the subtle border role, which is the one role
/// exempt from the 3:1 contrast floor, and the exemption does not apply where
/// a line says where a target begins.
///
/// **States.** One: at rest. It carries no interaction, so it has no other
/// state to hold.
///
/// **Accessibility.** It announces nothing, and it is drawn in a role a user
/// may not be able to see. That is correct here for the reason
/// [IuxListSeparator] records: the line repeats a boundary the column spacing
/// already expresses, so a reader who never sees it loses nothing. The moment
/// that stops being true — the moment the line is the only thing saying two
/// figures are different — the columns need labels, not a stronger rule.
///
/// **Themes.** Drawn in the subtle border role, so it moves with light, dark
/// and their high contrast variants without a branch in this file. High
/// contrast thickens [IuxGeometryTheme.borderWidth] rather than recolouring
/// the role — the rule [IuxListSeparator] records: a line that changes hue
/// under high contrast starts competing with focus for the same meaning.
///
/// **Responsive.** It has no width of its own to give up, so it costs a
/// layout nothing when columns narrow. What narrows *around* it is the
/// caller's decision, not this widget's: a card whose columns wrap into a
/// stack under a narrow width or large text stops having anything to
/// separate, and stops placing this widget in that arrangement — the way the
/// catalog sample below drops the second separator once two columns is all a
/// 200px frame can hold. This widget does not detect that on its own; it has
/// no notion of its siblings.
///
/// **It has no height of its own.** It takes what its parent gives it, so in a
/// `Row` it needs `CrossAxisAlignment.stretch`, or an `IntrinsicHeight` above
/// it when the row's height comes from its tallest child. A separator that
/// declared a height would be a separator shorter or taller than the columns
/// beside it at some text scale, and at 200% text that is every text scale.
class IuxVerticalSeparator extends StatelessWidget {
  /// Creates the line drawn between two columns.
  const IuxVerticalSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    final IuxSemanticColors colors = IuxSemanticColors.of(context);
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);

    return ColoredBox(
      color: colors.border.subtle,
      // The width follows the theme, so a high contrast profile thickens the
      // line instead of recolouring it — a separator that changes hue under
      // high contrast starts competing with focus for the same meaning.
      child: SizedBox(width: geometry.borderWidth),
    );
  }
}
