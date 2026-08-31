import 'package:flutter/material.dart';

import '../../accessibility/iux_focus.dart';
import '../../accessibility/iux_focus_ownership.dart';
import '../../accessibility/iux_semantics.dart';
import '../../actions/iux_action_descriptor.dart';
import '../../actions/iux_action_model.dart';
import '../../foundations/iux_foundations.dart';
import '../../inputs/iux_input_descriptor.dart';
import '../../inputs/iux_input_theme.dart';
import '../../layout/iux_spacing_primitives.dart';
import '../../semantics/iux_semantic_colors.dart';
import '../../themes/extensions/iux_geometry_theme.dart';
import '../button/iux_button.dart';
import 'iux_field_parts.dart';

/// One value chosen from a continuous range.
///
/// **This is the component whose clause the platform can satisfy in full.** EN
/// 301 549 clause 11.5.2.7 asks that the current value *and any minimum or
/// maximum values of the range* be programmatically determinable, and Flutter
/// publishes all three. Nothing in this library had a range, so nothing
/// exercised the clause.
///
/// ```dart
/// IuxSlider(
///   input: const IuxInputDescriptor(
///     semantics: IuxInputSemantics(label: 'Text size'),
///   ),
///   value: settings.scale,
///   min: 1,
///   max: 2,
///   divisions: 10,
///   format: (double v) => '${(v * 100).round()}%',
///   decreaseLabel: l10n.smaller,
///   increaseLabel: l10n.larger,
///   onChanged: settings.setScale,
/// )
/// ```
///
/// ## The buttons are not decoration
///
/// A control that can only be dragged is a **path-based gesture with no
/// single-pointer alternative**, which fails WCAG 2.2 SC 2.5.1 outright and is
/// unreachable by a screen reader whatever its semantics say. The minus and
/// plus are what make the drag permissible, so they are not optional and there
/// is no parameter to remove them.
///
/// The drag is the only path-based gesture in this library. Everything else is
/// a tap — see `IUX-EN301549-002`, which this component amends.
///
/// ## The caller formats the value
///
/// [format] is required. A screen reader speaks what it is given, and `0.7` is
/// the wrong answer when the range is a price, a percentage or a temperature.
/// The framework does not know the unit and will not invent one.
///
/// ## When not to use it
///
/// - **When the number matters exactly.** A slider is for a value the user
///   judges, not one they know. An amount, a date, an age: those are fields.
/// - **For more than about a dozen steps** the buttons become the only usable
///   route, and a field is kinder than fifty taps.
/// - **For an on/off** — that is `IuxSwitch`.
class IuxSlider extends StatelessWidget {
  /// Creates a slider over `min`..`max` in [divisions] steps.
  IuxSlider({
    super.key,
    required this.input,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.format,
    required this.decreaseLabel,
    required this.increaseLabel,
    required this.onChanged,
  })  : assert(min < max, 'A range needs two different ends.'),
        assert(
          divisions > 0,
          'A range with no steps cannot be moved by a keyboard or a screen '
          'reader, which is every user who is not dragging.',
        ),
        assert(
          value >= min && value <= max,
          'The value is outside the range, so the control shows a position '
          'that does not exist and announces a number its own bounds refuse.',
        ),
        assert(
          decreaseLabel.length > 0 && increaseLabel.length > 0,
          'Both buttons must be named. An unnamed one is announced as '
          '"button" and nothing else.',
        );

  /// What the value is called, whether it may change, and what is known about
  /// it.
  final IuxInputDescriptor input;

  /// The current value.
  final double value;

  /// The lowest value the range offers.
  final double min;

  /// The highest value the range offers.
  final double max;

  /// How many steps the range is divided into.
  ///
  /// Required rather than defaulted. A continuous slider cannot be operated by
  /// a keyboard or a screen reader, so the step is a decision every caller has
  /// to take rather than one this component can guess.
  final int divisions;

  /// Renders a value as the text a screen reader will speak, already localised.
  final String Function(double value) format;

  /// What the minus button is called, already localised.
  final String decreaseLabel;

  /// What the plus button is called, already localised.
  final String increaseLabel;

  /// Called with the value the user asked for.
  final ValueChanged<double> onChanged;

  /// The size of one step.
  double get _step => (max - min) / divisions;

  double _clamp(double raw) {
    if (raw <= min) return min;
    if (raw >= max) return max;
    // Snapped to the step, so the value a screen reader announces is one the
    // user can return to. An unsnapped drag reports a number nobody can reach
    // again with the buttons.
    final int steps = ((raw - min) / _step).round();
    return min + steps * _step;
  }

  void _nudge(int steps) => onChanged(_clamp(value + steps * _step));

  @override
  Widget build(BuildContext context) {
    final IuxInputTokens tokens = IuxInputResolver.resolve(
      context,
      input,
      hovered: false,
      focused: false,
    );
    final IuxSemanticColors colors = IuxSemanticColors.of(context);
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final bool editable = input.isEditable;
    final String? message = input.validation.message;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Excluded because the range's own node carries the same string as its
        // name; left in, the question is read twice.
        IuxSemantics.decorative(
          child: Text(input.semantics.label, style: tokens.labelStyle),
        ),
        const IuxGap.tight(),
        Row(
          children: <Widget>[
            IuxIconButton(
              icon: Icons.remove,
              action: IuxActionDescriptor(
                semantics: IuxActionSemantics(label: decreaseLabel),
                availability: editable && value > min
                    ? IuxActionAvailability.enabled
                    : IuxActionAvailability.disabled,
              ),
              onActivate: () => _nudge(-1),
            ),
            Expanded(
              child: IuxFocusNodeOwner(
                focusNode: null,
                debugLabel: input.semantics.label,
                builder: (BuildContext context, FocusNode node) =>
                    IuxSemantics.range(
                  label: input.semantics.label,
                  value: format(value),
                  minValue: format(min),
                  maxValue: format(max),
                  // What the value *would* become, so a step that changes
                  // nothing is heard as such rather than met with silence.
                  increasedValue: format(_clamp(value + _step)),
                  decreasedValue: format(_clamp(value - _step)),
                  enabled: editable,
                  onIncrease: editable ? () => _nudge(1) : null,
                  onDecrease: editable ? () => _nudge(-1) : null,
                  focusNode: node,
                  focusable: input.isFocusable,
                  child: IuxFocusable(
                    focusNode: node,
                    canRequestFocus: input.isFocusable,
                    child: _IuxSliderTrack(
                      fraction: (value - min) / (max - min),
                      colors: colors,
                      geometry: geometry,
                      enabled: editable,
                      onFraction: editable
                          ? (double f) =>
                              onChanged(_clamp(min + f * (max - min)))
                          : null,
                    ),
                  ),
                ),
              ),
            ),
            IuxIconButton(
              icon: Icons.add,
              action: IuxActionDescriptor(
                semantics: IuxActionSemantics(label: increaseLabel),
                availability: editable && value < max
                    ? IuxActionAvailability.enabled
                    : IuxActionAvailability.disabled,
              ),
              onActivate: () => _nudge(1),
            ),
          ],
        ),
        const IuxGap.tight(),
        // The value in words, on screen. A slider whose position is its only
        // readout is unreadable to anyone who cannot judge a bar against its
        // ends, which includes most people at a glance.
        IuxSemantics.decorative(
          child: Text(format(value), style: tokens.valueStyle),
        ),
        if (input.helpText case final String help) ...<Widget>[
          const IuxGap.tight(),
          Text(help, style: tokens.helpStyle),
        ],
        if (message != null) ...<Widget>[
          const IuxGap.tight(),
          IuxFieldValidationMessage(
            message: message,
            style: tokens.messageStyle,
            announce: true,
          ),
        ],
      ],
    );
  }
}

/// The bar, and the only path-based gesture in this library.
///
/// The drag is permitted because the minus and plus buttons beside it are a
/// single-pointer alternative to every value it can reach — SC 2.5.1. Without
/// them it would be a conformance failure rather than a convenience.
class _IuxSliderTrack extends StatelessWidget {
  const _IuxSliderTrack({
    required this.fraction,
    required this.colors,
    required this.geometry,
    required this.enabled,
    required this.onFraction,
  });

  final double fraction;
  final IuxSemanticColors colors;
  final IuxGeometryTheme geometry;
  final bool enabled;
  final ValueChanged<double>? onFraction;

  void _report(BuildContext context, Offset global) {
    final RenderBox box = context.findRenderObject()! as RenderBox;
    final double dx = box.globalToLocal(global).dx;
    onFraction!((dx / box.size.width).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) =>
            GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: onFraction == null
              ? null
              : (TapDownDetails d) => _report(context, d.globalPosition),
          onHorizontalDragUpdate: onFraction == null
              ? null
              : (DragUpdateDetails d) => _report(context, d.globalPosition),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: IuxSpacing.sm),
            child: SizedBox(
              height: geometry.strongBorderWidth * 4,
              child: Stack(
                children: <Widget>[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: enabled
                          ? colors.border.standard
                          : colors.border.disabled,
                      borderRadius: BorderRadius.circular(
                        geometry.strongBorderWidth * 2,
                      ),
                    ),
                    child: const SizedBox.expand(),
                  ),
                  FractionallySizedBox(
                    widthFactor: fraction.clamp(0.0, 1.0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: enabled
                            ? colors.action.primary.background
                            : colors.content.disabled,
                        borderRadius: BorderRadius.circular(
                          geometry.strongBorderWidth * 2,
                        ),
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
