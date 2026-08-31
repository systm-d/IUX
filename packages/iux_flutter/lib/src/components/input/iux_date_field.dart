import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../../accessibility/iux_semantics.dart';
import '../../inputs/iux_date_parts.dart';
import '../../inputs/iux_input_descriptor.dart';
import '../../inputs/iux_input_model.dart';
import '../../inputs/iux_input_theme.dart';
import '../../layout/iux_spacing_primitives.dart';
import '../../themes/extensions/iux_geometry_theme.dart';
import 'iux_field_parts.dart';

/// A date entered as three named boxes: day, month and year.
///
/// **It is not a calendar, and that is the decision this component is.** A
/// calendar picker is a grid of forty-two targets a screen-reader user has to
/// arrow through to find one, it collapses at 200% text, and reaching it means
/// opening something — which a component in this library cannot do, because it
/// may not touch `Navigator`. Three labelled boxes are what accessibility
/// audits ask for and what every user can already type into.
///
/// The cost is real and is not hidden: **this does not look like what most
/// people expect a date field to look like**, and it gives no help with a date
/// far from today. An application that needs a calendar should build one and
/// own its accessibility; this is the field for the date somebody knows.
///
/// ```dart
/// IuxDateField(
///   input: const IuxInputDescriptor(
///     semantics: IuxInputSemantics(label: 'Date of birth'),
///     requirement: IuxInputRequirement.required,
///   ),
///   labels: IuxDateFieldLabels(
///     day: l10n.day, month: l10n.month, year: l10n.year,
///   ),
///   value: form.birthDate,
///   onChanged: form.setBirthDate,
/// )
/// ```
///
/// ## What it announces
///
/// A named container carrying the question, holding three fields that each
/// announce their own name. The question is **not** composed into each box's
/// name — "Date of birth day" is a sentence the framework would be writing in a
/// language it cannot read. A named container is the platform's own mechanism
/// for the same relationship, and the analogue of a `fieldset` and its
/// `legend`.
///
/// **The platform is not told these are numbers.** `SemanticsInputType` offers
/// text, url, phone, search and email, and nothing for a number or a date, so
/// the keyboard is numeric and the announcement is not. That is Flutter's
/// limit, recorded rather than worked around.
///
/// ## Validity is the parent's, as everywhere else
///
/// The boxes accept what is typed. A field that silently refused `32` would be
/// deciding mid-keystroke that the user meant something else, and one that
/// corrected `31/02` would be answering a question the user had not finished
/// asking. [IuxDateParts.date] is null when the parts do not name a real day,
/// so the check is one line at the call site — and what a bad date *means*
/// stays with the parent that knows.
class IuxDateField extends StatefulWidget {
  /// Creates a date field showing [value].
  const IuxDateField({
    super.key,
    required this.input,
    required this.labels,
    required this.value,
    required this.onChanged,
    this.variant,
  });

  /// What the date is called, whether it may change, and what is known about
  /// the answer.
  final IuxInputDescriptor input;

  /// What the three boxes are called, already localised.
  final IuxDateFieldLabels labels;

  /// The parts entered so far.
  final IuxDateParts value;

  /// Called with the parts after every keystroke.
  ///
  /// Called with incomplete and impossible dates too. The parent is the only
  /// thing that knows whether "31/02" is worth an error yet, or whether the
  /// user is still typing.
  final ValueChanged<IuxDateParts> onChanged;

  /// The field's visual variant, or null to take the theme's default.
  final IuxInputVariant? variant;

  @override
  State<IuxDateField> createState() => _IuxDateFieldState();
}

class _IuxDateFieldState extends State<IuxDateField> {
  late final TextEditingController _day;
  late final TextEditingController _month;
  late final TextEditingController _year;

  @override
  void initState() {
    super.initState();
    _day = TextEditingController(text: _text(widget.value.day));
    _month = TextEditingController(text: _text(widget.value.month));
    _year = TextEditingController(text: _text(widget.value.year));
  }

  @override
  void didUpdateWidget(IuxDateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only when the parent actually changed the value. Writing the controller
    // on every rebuild would move the caret to the end while the user types.
    _sync(_day, widget.value.day, oldWidget.value.day);
    _sync(_month, widget.value.month, oldWidget.value.month);
    _sync(_year, widget.value.year, oldWidget.value.year);
  }

  static String _text(int? part) => part?.toString() ?? '';

  void _sync(TextEditingController controller, int? next, int? previous) {
    if (next == previous) return;
    final String text = _text(next);
    if (controller.text == text) return;
    controller.text = text;
  }

  @override
  void dispose() {
    _day.dispose();
    _month.dispose();
    _year.dispose();
    super.dispose();
  }

  void _emit({
    String? day,
    String? month,
    String? year,
  }) {
    IuxDateParts next = widget.value;
    if (day != null) {
      next = day.isEmpty
          ? next.copyWith(clearDay: true)
          : next.copyWith(day: int.tryParse(day));
    }
    if (month != null) {
      next = month.isEmpty
          ? next.copyWith(clearMonth: true)
          : next.copyWith(month: int.tryParse(month));
    }
    if (year != null) {
      next = year.isEmpty
          ? next.copyWith(clearYear: true)
          : next.copyWith(year: int.tryParse(year));
    }
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final IuxInputTokens tokens = IuxInputResolver.resolve(
      context,
      widget.input,
      variant: widget.variant,
      hovered: false,
      focused: false,
    );
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final double ringInset = geometry.focus.width + geometry.focus.gap;
    final EdgeInsetsDirectional textInset =
        EdgeInsetsDirectional.only(start: ringInset);
    final double gap = tokens.gap - ringInset;
    final double supportingGap = gap < 0 ? 0 : gap;
    final String? message = widget.input.validation.message;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: textInset,
          // Excluded because the container below carries the same string as its
          // name. Left in, the question is read once as a heading and once as
          // the name of the group under it.
          child: IuxSemantics.decorative(
            child: Text(
              widget.input.semantics.label,
              style: tokens.labelStyle,
            ),
          ),
        ),
        SizedBox(height: supportingGap),
        IuxSemantics.fieldGroup(
          label: widget.input.semantics.label,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _IuxDatePart(
                label: widget.labels.day,
                controller: _day,
                input: widget.input,
                tokens: tokens,
                geometry: geometry,
                maxLength: 2,
                flex: 2,
                onChanged: (String text) => _emit(day: text),
              ),
              const IuxGap.horizontal(IuxSpacingStep.xs),
              _IuxDatePart(
                label: widget.labels.month,
                controller: _month,
                input: widget.input,
                tokens: tokens,
                geometry: geometry,
                maxLength: 2,
                flex: 2,
                onChanged: (String text) => _emit(month: text),
              ),
              const IuxGap.horizontal(IuxSpacingStep.xs),
              _IuxDatePart(
                label: widget.labels.year,
                controller: _year,
                input: widget.input,
                tokens: tokens,
                geometry: geometry,
                maxLength: 4,
                flex: 3,
                onChanged: (String text) => _emit(year: text),
              ),
            ],
          ),
        ),
        if (widget.input.helpText case final String help) ...<Widget>[
          SizedBox(height: supportingGap),
          Padding(
            padding: textInset,
            child: Text(help, style: tokens.helpStyle),
          ),
        ],
        if (message != null) ...<Widget>[
          SizedBox(height: supportingGap),
          Padding(
            padding: textInset,
            child: IuxFieldValidationMessage(
              message: message,
              style: tokens.messageStyle,
              announce: true,
            ),
          ),
        ],
      ],
    );
  }
}

/// One of the three boxes, with its own name above it.
///
/// The name is visible as well as announced. A box labelled only to assistive
/// technology leaves a sighted user counting boxes to work out which one is the
/// month, and the order differs by country.
class _IuxDatePart extends StatelessWidget {
  const _IuxDatePart({
    required this.label,
    required this.controller,
    required this.input,
    required this.tokens,
    required this.geometry,
    required this.maxLength,
    required this.flex,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final IuxInputDescriptor input;
  final IuxInputTokens tokens;
  final IuxGeometryTheme geometry;
  final int maxLength;
  final int flex;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IuxSemantics.decorative(
              child: Text(label, style: tokens.helpStyle),
            ),
            const IuxGap.tight(),
            IuxSemantics.field(
              label: label,
              enabled: input.availability != IuxInputAvailability.disabled,
              readOnly: input.availability == IuxInputAvailability.readOnly,
              isRequired: input.isRequired,
              validation: input.validation.isInvalid
                  ? SemanticsValidationResult.invalid
                  : SemanticsValidationResult.none,
              child: IuxFieldContainer(
                tokens: tokens,
                geometry: geometry,
                child: TextField(
                  controller: controller,
                  enabled: input.isEditable,
                  readOnly: !input.isEditable,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(maxLength),
                  ],
                  style: tokens.valueStyle,
                  onChanged: onChanged,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
