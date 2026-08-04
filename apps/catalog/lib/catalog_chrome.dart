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

/// The harness header, which can be folded away.
///
/// A usability problem the catalog gave itself. The section list and the three
/// axes both have to be reachable from every section, so both sit above the
/// content — and once the library grew past a dozen sections that header was
/// most of the first screen at 100% and rather more than one screen at 300%,
/// where the panel a maintainer came to look at started below the fold.
///
/// Folding it away is the answer rather than shortening it: every control in
/// it is needed, just not at the same time as the thing being looked at. It
/// opens by default, because a harness whose axes are hidden until discovered
/// is a harness that gets used at 100% forever.
///
/// [summary] is what survives the fold. It names the combination on screen, so
/// a screenshot of a folded header is still evidence of which conditions
/// produced it — the one thing a collapsed header must not cost.
///
/// Hand-rolled rather than built on `IuxProgressiveDisclosure`, for the reason
/// the option chips are hand-rolled: this is the control a maintainer needs in
/// order to *leave* a broken state, and a harness that cannot be navigated
/// when the component under test is broken cannot report that it is broken.
class CatalogHeader extends StatelessWidget {
  /// Creates the foldable header.
  const CatalogHeader({
    super.key,
    required this.summary,
    required this.expanded,
    required this.onExpandedChanged,
    required this.child,
  });

  /// The conditions in force, in one line, shown whether or not it is open.
  final String summary;

  /// Whether the controls are showing.
  final bool expanded;

  /// Called with the state the user asked for.
  final ValueChanged<bool> onExpandedChanged;

  /// The controls themselves.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final IuxSemanticColors colors = IuxSemanticColors.of(context);
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme type = IuxTypographyTheme.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: geometry.spacingMd),
      decoration: BoxDecoration(
        color: colors.surface.raised,
        border: Border.all(
          color: colors.border.strong,
          width: geometry.strongBorderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Semantics(
            label: 'Catalog conditions',
            value: summary,
            hint: expanded ? 'Folds the controls away' : 'Shows the controls',
            button: true,
            expanded: expanded,
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onExpandedChanged(!expanded),
              child: Container(
                constraints: BoxConstraints(
                  minHeight: geometry.minimumTouchTarget,
                ),
                padding: EdgeInsets.all(geometry.spacingSm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Conditions',
                            style: type.title
                                .copyWith(color: colors.content.primary),
                          ),
                          SizedBox(height: geometry.spacingXxs),
                          Text(
                            summary,
                            style: type.supporting
                                .copyWith(color: colors.content.secondary),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: geometry.spacingXs),
                    // A word as well as a chevron. The chevron's direction is a
                    // shape rather than a colour, so it survives a reader who
                    // cannot tell two hues apart — but it does not survive one
                    // who has never met the convention, and this is the control
                    // the whole harness is reached through.
                    Text(
                      expanded ? 'Hide' : 'Show',
                      style: type.label.copyWith(color: colors.content.primary),
                    ),
                    SizedBox(width: geometry.spacingXxs),
                    Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      color: colors.content.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: EdgeInsets.fromLTRB(
                geometry.spacingSm,
                0,
                geometry.spacingSm,
                geometry.spacingSm,
              ),
              child: child,
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

/// Reports the size a control actually occupied.
///
/// A touch target that meets its floor in the default profile and loses it at
/// 300% is a target nobody measures, because the number is invisible. This
/// prints it, next to the floor the profile resolved, so the comparison is on
/// screen rather than in a test nobody runs by hand.
///
/// [checksTarget] turns the comparison off for something that is not a target
/// — a page frame, a readable column — where the number is still worth seeing
/// and the floor means nothing.
class CatalogMeasured extends StatefulWidget {
  /// Creates a measured sample.
  const CatalogMeasured({
    super.key,
    required this.child,
    this.checksTarget = true,
  });

  /// The widget to measure.
  final Widget child;

  /// Whether the measured height is compared against the target floor.
  final bool checksTarget;

  @override
  State<CatalogMeasured> createState() => _CatalogMeasuredState();
}

class _CatalogMeasuredState extends State<CatalogMeasured> {
  final GlobalKey _key = GlobalKey();
  Size? _size;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());

    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme type = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);
    final Size? size = _size;
    final double floor = geometry.minimumTouchTarget;
    final bool short =
        widget.checksTarget && size != null && (size.height + 0.5) < floor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        KeyedSubtree(key: _key, child: widget.child),
        SizedBox(height: geometry.spacingXxs),
        Text(
          size == null
              ? 'measuring…'
              : '${size.width.toStringAsFixed(0)}'
                  ' × ${size.height.toStringAsFixed(0)}'
                  '${widget.checksTarget ? ' (floor ${floor.toStringAsFixed(0)})' : ''}'
                  '${short ? ' — under the floor' : ''}',
          style: type.supporting.copyWith(
            color: short
                ? colors.feedback.error.content
                : colors.content.secondary,
          ),
        ),
      ],
    );
  }

  void _measure() {
    if (!mounted) return;
    final Size? size = _key.currentContext?.size;
    if (size == null || size == _size) return;
    setState(() => _size = size);
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
