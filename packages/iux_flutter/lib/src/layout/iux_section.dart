import 'package:flutter/material.dart';

import '../accessibility/iux_semantics.dart';
import '../semantics/iux_semantic_colors.dart';
import '../themes/extensions/iux_geometry_theme.dart';
import '../themes/extensions/iux_typography_theme.dart';
import 'iux_spacing_primitives.dart';

/// A titled group of related content.
///
/// Grouping is the cheapest way to reduce how much a user has to hold in mind
/// at once, and a section makes it structural rather than incidental: the
/// title becomes a screen-reader landmark, so the grouping exists for someone
/// who cannot see the spacing that expresses it.
///
/// ```dart
/// IuxSection(
///   title: 'Delivery',
///   children: <Widget>[address, instructions],
/// )
/// ```
class IuxSection extends StatelessWidget {
  /// Creates a section.
  const IuxSection({
    super.key,
    required this.children,
    this.title,
    this.description,
    this.trailing,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  /// The content, separated by the intra-group spacing step.
  final List<Widget> children;

  /// The heading. Exposed as a header so a screen reader can jump to it.
  final String? title;

  /// Supporting text explaining the group.
  final String? description;

  /// An action belonging to the section as a whole.
  final Widget? trailing;

  /// How children align across the section.
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);

    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (title != null || description != null || trailing != null) ...[
            IuxSectionHeader(
              title: title,
              description: description,
              trailing: trailing,
            ),
            SizedBox(height: geometry.spacingSm),
          ],
          for (int i = 0; i < children.length; i++) ...<Widget>[
            if (i > 0) const IuxGap.tight(),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// The heading of an [IuxSection].
///
/// Separated so a screen that lays its own content out can still get a
/// consistent heading without adopting the section's spacing.
class IuxSectionHeader extends StatelessWidget {
  /// Creates a section heading.
  const IuxSectionHeader({
    super.key,
    this.title,
    this.description,
    this.trailing,
  });

  /// The heading text.
  final String? title;

  /// Supporting text.
  final String? description;

  /// An action belonging to the section.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final IuxTypographyTheme type = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);

    final Widget text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (title != null)
          IuxSemantics.header(
            label: title!,
            child: Text(
              title!,
              style: type.title.copyWith(color: colors.content.primary),
            ),
          ),
        if (description != null) ...<Widget>[
          SizedBox(height: geometry.spacingXxs),
          Text(
            description!,
            style: type.supporting.copyWith(color: colors.content.secondary),
          ),
        ],
      ],
    );

    if (trailing == null) return text;

    // Wrap rather than Row: at a large text scale a heading and its action
    // stop fitting side by side, and moving the action to the next line is
    // better than clipping either.
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: geometry.spacingSm,
      runSpacing: geometry.spacingXs,
      children: <Widget>[text, trailing!],
    );
  }
}
