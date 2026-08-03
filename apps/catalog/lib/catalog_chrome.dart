import 'package:flutter/material.dart';
import 'package:iux_flutter/iux_flutter.dart';

/// One titled block of the catalog.
///
/// The description is not decoration: a panel that shows a control without
/// saying what it is meant to prove is a screenshot, and a screenshot cannot
/// be wrong. Every panel states what a maintainer should be looking at.
class CatalogPanel extends StatelessWidget {
  /// Creates a titled block.
  const CatalogPanel({
    super.key,
    required this.title,
    required this.description,
    required this.child,
  });

  /// The name of what is being shown.
  final String title;

  /// What the panel is for, and what would count as a failure.
  final String description;

  /// The demonstration itself.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final IuxSemanticColors colors = IuxSemanticColors.of(context);
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme type = IuxTypographyTheme.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: geometry.spacingMd),
      padding: EdgeInsets.all(geometry.spacingMd),
      decoration: BoxDecoration(
        color: colors.surface.raised,
        border: Border.all(
          color: colors.border.standard,
          width: geometry.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title,
              style: type.title.copyWith(color: colors.content.primary)),
          SizedBox(height: geometry.spacingXxs),
          Text(
            description,
            style: type.supporting.copyWith(color: colors.content.secondary),
          ),
          SizedBox(height: geometry.spacingSm),
          child,
        ],
      ),
    );
  }
}

/// A row of mutually exclusive options.
///
/// Named by dimension *and* value for assistive technology. Several dimensions
/// share a value — "comfortable" belongs to both density and touch target — so
/// a chip labelled only "comfortable" is ambiguous to a screen reader, which
/// hears the same word twice with nothing to distinguish them.
class CatalogChoice<T> extends StatelessWidget {
  /// Creates a row of options for one dimension.
  const CatalogChoice({
    super.key,
    required this.label,
    required this.value,
    required this.values,
    required this.naming,
    required this.onChanged,
  });

  /// The dimension being chosen.
  final String label;

  /// The option currently in force.
  final T value;

  /// Every option available.
  final List<T> values;

  /// How an option is written.
  final String Function(T) naming;

  /// Called with the option the user picked.
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme type = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: geometry.spacingSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: type.label.copyWith(color: colors.content.secondary),
          ),
          SizedBox(height: geometry.spacingXxs),
          Wrap(
            spacing: geometry.spacingXs,
            runSpacing: geometry.spacingXs,
            children: <Widget>[
              for (final T option in values)
                Semantics(
                  label: '$label: ${naming(option)}',
                  selected: option == value,
                  button: true,
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: () => onChanged(option),
                    child: Container(
                      constraints: BoxConstraints(
                        minHeight: geometry.minimumTouchTarget,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: geometry.spacingSm,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: option == value
                            ? colors.surface.selected
                            : colors.surface.base,
                        border: Border.all(
                          color: option == value
                              ? colors.border.selected
                              : colors.border.standard,
                          width: option == value
                              ? geometry.strongBorderWidth
                              : geometry.borderWidth,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (option == value) ...<Widget>[
                            Icon(
                              Icons.check,
                              size: 16,
                              color: colors.content.primary,
                            ),
                            SizedBox(width: geometry.spacingXxs),
                          ],
                          // Flexible, because the chip is the control the
                          // maintainer needs in order to *leave* 300%. A chip
                          // whose label overflowed at the largest text scale
                          // would take the harness down with the component it
                          // was meant to be testing.
                          Flexible(
                            child: Text(
                              naming(option),
                              style: type.label
                                  .copyWith(color: colors.content.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A label above a group of samples.
class CatalogSubheading extends StatelessWidget {
  /// Creates a group label.
  const CatalogSubheading(this.text, {super.key});

  /// The words.
  final String text;

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme type = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: geometry.spacingXxs),
      child: Text(
        text,
        style: type.label.copyWith(color: colors.content.secondary),
      ),
    );
  }
}

/// A remark attached to a sample.
///
/// [finding] marks something that looked wrong under stress rather than
/// something the component was designed to do. It is drawn on the warning
/// role's own surface — the pairing the theme measures for contrast — and
/// carries a word as well as a colour, so the distinction survives a reader
/// who cannot tell the two hues apart.
class CatalogNote extends StatelessWidget {
  /// Creates a remark.
  const CatalogNote(this.text, {super.key, this.finding = false});

  /// What the reader should know.
  final String text;

  /// Whether this records a defect rather than an explanation.
  final bool finding;

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme type = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);

    if (!finding) {
      return Padding(
        padding: EdgeInsets.only(top: geometry.spacingXxs),
        child: Text(
          text,
          style: type.supporting.copyWith(color: colors.content.secondary),
        ),
      );
    }

    final IuxFeedbackRoleColors warning = colors.feedback.warning;
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: geometry.spacingXs),
      padding: EdgeInsets.all(geometry.spacingXs),
      decoration: BoxDecoration(
        color: warning.surface,
        border: Border.all(color: warning.border, width: geometry.borderWidth),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.warning_amber_outlined, color: warning.icon, size: 18),
          SizedBox(width: geometry.spacingXs),
          Expanded(
            child: Text(
              'Finding — $text',
              style: type.supporting.copyWith(color: warning.content),
            ),
          ),
        ],
      ),
    );
  }
}

/// A label/value list of resolved values.
class CatalogRows extends StatelessWidget {
  /// Creates the list.
  const CatalogRows(this.rows, {super.key});

  /// The pairs to show, in reading order.
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme type = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);

    return Column(
      children: <Widget>[
        for (final (String label, String value) in rows)
          Padding(
            padding: EdgeInsets.only(bottom: geometry.spacingXxs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Text(
                    label,
                    style: type.supporting
                        .copyWith(color: colors.content.secondary),
                  ),
                ),
                SizedBox(width: geometry.spacingXs),
                Expanded(
                  child: Text(
                    value,
                    style: type.label.copyWith(color: colors.content.primary),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A sample with a caption under it.
///
/// The caption names the combination being shown, so a screenshot of a panel
/// is still readable as evidence.
class CatalogSample extends StatelessWidget {
  /// Creates a captioned sample.
  const CatalogSample({
    super.key,
    required this.caption,
    required this.child,
    this.width,
  });

  /// What combination this is.
  final String caption;

  /// The control being shown.
  final Widget child;

  /// A fixed width to squeeze the control into, or null for its natural size.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme type = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);

    final double? boxWidth = width;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          caption,
          style: type.supporting.copyWith(color: colors.content.secondary),
        ),
        SizedBox(height: geometry.spacingXxs),
        if (boxWidth == null)
          child
        else
          SizedBox(width: boxWidth, child: child),
      ],
    );
  }
}
