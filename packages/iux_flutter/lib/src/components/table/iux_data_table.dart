import 'package:flutter/material.dart';

import '../../accessibility/iux_semantics.dart';
import '../../foundations/iux_foundations.dart';
import '../../layout/iux_spacing_primitives.dart';
import '../../semantics/iux_semantic_colors.dart';
import '../../themes/extensions/iux_geometry_theme.dart';
import '../../themes/extensions/iux_typography_theme.dart';

/// One column of an [IuxDataTable], and how to read a row's value for it.
@immutable
class IuxTableColumn<T> {
  /// Creates a column headed [label], reading each row through [value].
  const IuxTableColumn({required this.label, required this.value})
      : assert(
          label.length > 0,
          'A column header must be named. An unnamed one leaves every cell '
          'beneath it announced without saying what it is a value of, which '
          'is the whole thing a table is for.',
        );

  /// The column's heading, already localised.
  final String label;

  /// Reads this column's cell out of a row, already localised and formatted.
  ///
  /// A `String`, not a widget. A table cell that can hold anything is a table
  /// whose cells cannot be announced, and the announcement is the reason this
  /// component exists rather than a `Column` of `Row`s.
  final String Function(T row) value;
}

/// A table of values, with the row and column of every cell exposed to
/// assistive technology.
///
/// **This exists for one clause.** EN 301 549 clause 11.5.2.6 requires the row
/// and column of each cell in a data table — including headers — to be
/// programmatically determinable. Nothing in this library exercised it, because
/// a table assembled from a `Column` of `Row`s satisfies it by accident at
/// best: it renders identically and announces a flat run of strings with no
/// structure at all. RAAM tests the same ground as its criteria 4.1 to 4.5,
/// all level A.
///
/// ```dart
/// IuxDataTable<Delivery>(
///   title: l10n.deliveriesThisWeek,
///   columns: <IuxTableColumn<Delivery>>[
///     IuxTableColumn<Delivery>(label: l10n.day, value: (Delivery d) => d.day),
///     IuxTableColumn<Delivery>(label: l10n.parcels, value: (Delivery d) => '${d.parcels}'),
///   ],
///   rows: week,
/// )
/// ```
///
/// ## When not to use it
///
/// - **For layout.** A table is a claim that the values are related across two
///   dimensions. Using one to place things side by side tells a screen-reader
///   user to look for a relationship that is not there.
/// - **For a list of things.** One value per item is a list — `IuxListGroup`.
/// - **For many columns.** The columns share the width and wrap; past four or
///   five on a phone every column becomes a stack of single words. There is no
///   assertion, because the right number depends on the words.
/// - **When it might be empty.** Render `IuxEmptyState` instead. A table with a
///   heading and no rows announces a structure and then holds nothing.
///
/// ## What it announces
///
/// A `table` node named by [title], containing `row` nodes, each containing
/// `columnHeader` or `cell` nodes. Flutter enforces that nesting and throws on
/// the first frame if it is broken, which is why the shape is built here rather
/// than left to callers.
///
/// **The row-header half of 11.5.2.6 cannot be satisfied on this platform.**
/// `SemanticsRole` has `columnHeader` and no `rowHeader`, so a table whose
/// first column names its rows announces those cells as ordinary cells. The
/// limitation is Flutter's and it is recorded rather than worked around.
///
/// ## Why it does not scroll sideways
///
/// The columns share the available width and their text wraps. A table that
/// scrolls horizontally puts the row label out of sight exactly when the user
/// needs it, and at 200% text it does so immediately. WCAG 2.2 SC 1.4.10
/// exempts tables from the reflow requirement, so scrolling would have been
/// permitted — it is not taken because permitted is not the same as usable.
class IuxDataTable<T> extends StatelessWidget {
  /// Creates a table of [rows] described by [columns].
  IuxDataTable({
    super.key,
    required this.title,
    required this.columns,
    required this.rows,
    this.description,
  })  : assert(
          title.length > 0,
          'A table must be named. Unnamed, a screen-reader user meets a grid '
          'of values with nothing saying what was tabulated — RAAM 4.3.',
        ),
        assert(
          columns.length > 0,
          'A table with no columns has nothing to tabulate.',
        ),
        assert(
          rows.length > 0,
          'A table with no rows announces a structure and then holds nothing. '
          'Render IuxEmptyState and say why there is no data.',
        ),
        assert(
          description == null || description.length > 0,
          'An empty description reserves a line and says nothing. Pass null.',
        );

  /// What was tabulated, already localised.
  ///
  /// Rendered as a heading and used as the table's accessible name, so a
  /// screen-reader user can jump to it — RAAM criteria 4.3 and 4.4.
  final String title;

  /// How to read the table, for one complex enough to need saying.
  ///
  /// This is what RAAM criteria 4.1 and 4.2 call a table's *résumé*. It is
  /// named `description` rather than `summary` because `summary` already means
  /// three unrelated things in this library — a collapsed section's headline,
  /// a validation-error label set, and a search-result count — and
  /// `api_consistency_test.dart` refuses a fourth. RAAM does not define
  /// *complex*, so this is optional and the caller decides. A description that
  /// repeats the title is worse than none.
  final String? description;

  /// The columns, in the order they are read.
  final List<IuxTableColumn<T>> columns;

  /// The rows, in the order they are read.
  ///
  /// Order carries meaning and is the caller's; nothing is sorted here.
  final List<T> rows;

  @override
  Widget build(BuildContext context) {
    final IuxTypographyTheme type = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IuxSemantics.header(
          label: title,
          child: Text(
            title,
            style: type.title.copyWith(color: colors.content.primary),
          ),
        ),
        if (description case final String text) ...<Widget>[
          const IuxGap.tight(),
          Text(
            text,
            style: type.supporting.copyWith(color: colors.content.secondary),
          ),
        ],
        const IuxGap.standard(),
        // The table's own name repeats the heading above it. Both are needed:
        // the heading is what a screen-reader user jumps to, and the name is
        // what the table announces once they are inside it.
        IuxSemantics.table(
          label: title,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _IuxTableRow<T>(
                columns: columns,
                row: null,
                style: type.label.copyWith(color: colors.content.primary),
                border: colors.border.strong,
                borderWidth: geometry.strongBorderWidth,
              ),
              for (final T row in rows)
                _IuxTableRow<T>(
                  columns: columns,
                  row: row,
                  style: type.body.copyWith(color: colors.content.primary),
                  border: colors.border.subtle,
                  borderWidth: geometry.borderWidth,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One row: the header row when [row] is null, a data row otherwise.
///
/// One widget for both, so a header and a cell cannot drift apart in padding or
/// alignment — the drift a reader notices as a table whose columns do not line
/// up with their own headings.
class _IuxTableRow<T> extends StatelessWidget {
  const _IuxTableRow({
    required this.columns,
    required this.row,
    required this.style,
    required this.border,
    required this.borderWidth,
  });

  final List<IuxTableColumn<T>> columns;
  final T? row;
  final TextStyle style;
  final Color border;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final T? value = row;

    return IuxSemantics.tableRow(
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: border, width: borderWidth),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: IuxSpacing.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final IuxTableColumn<T> column in columns)
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: IuxSpacing.xxs),
                    child: value == null
                        ? IuxSemantics.tableColumnHeader(
                            label: column.label,
                            child: Text(column.label, style: style),
                          )
                        : _cell(column, value),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cell(IuxTableColumn<T> column, T value) {
    final String text = column.value(value);
    return IuxSemantics.tableCell(
      // An empty cell still has a row and a column, so it stays a cell rather
      // than being dropped: a missing node would shift every cell after it into
      // the wrong column as far as assistive technology is concerned.
      label: text,
      child: Text(text, style: style),
    );
  }
}
