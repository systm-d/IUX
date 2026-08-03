import 'package:flutter/material.dart';
import 'package:iux_flutter/iux_flutter.dart';

void main() {
  runApp(const IuxCatalogApp());
}

/// Local integration surface for the experimental IUX package.
///
/// The catalog explains what each profile changes, rather than showing a
/// finished look. Nothing here is an IUX component: components arrive from
/// IUX-008 onward, and these are plain Flutter widgets painted with resolved
/// theme values so the theme itself can be inspected.
class IuxCatalogApp extends StatefulWidget {
  /// Creates the catalog application.
  const IuxCatalogApp({super.key});

  @override
  State<IuxCatalogApp> createState() => _IuxCatalogAppState();
}

class _IuxCatalogAppState extends State<IuxCatalogApp> {
  IuxThemeConfiguration _configuration = const IuxThemeConfiguration();
  double _textScale = 1;
  bool _longLabels = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IUX catalog',
      theme: IuxTheme.fromConfiguration(_configuration),
      home: MediaQuery.withClampedTextScaling(
        minScaleFactor: _textScale,
        maxScaleFactor: _textScale,
        child: _ThemeExplorer(
          configuration: _configuration,
          textScale: _textScale,
          longLabels: _longLabels,
          onConfigurationChanged: (IuxThemeConfiguration value) =>
              setState(() => _configuration = value),
          onTextScaleChanged: (double value) =>
              setState(() => _textScale = value),
          onLongLabelsChanged: (bool value) =>
              setState(() => _longLabels = value),
        ),
      ),
    );
  }
}

class _ThemeExplorer extends StatelessWidget {
  const _ThemeExplorer({
    required this.configuration,
    required this.textScale,
    required this.longLabels,
    required this.onConfigurationChanged,
    required this.onTextScaleChanged,
    required this.onLongLabelsChanged,
  });

  final IuxThemeConfiguration configuration;
  final double textScale;
  final bool longLabels;
  final ValueChanged<IuxThemeConfiguration> onConfigurationChanged;
  final ValueChanged<double> onTextScaleChanged;
  final ValueChanged<bool> onLongLabelsChanged;

  IuxAccessibilityProfile get _profile => configuration.profile;

  void _updateProfile(IuxAccessibilityProfile profile) =>
      onConfigurationChanged(configuration.copyWith(profile: profile));

  @override
  Widget build(BuildContext context) {
    final IuxSemanticColors colors = IuxSemanticColors.of(context);
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme type = IuxTypographyTheme.of(context);
    final IuxMotionTheme motion = IuxMotionTheme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('IUX theme explorer')),
      body: ListView(
        padding: EdgeInsets.all(geometry.spacingMd),
        children: <Widget>[
          _Panel(
            title: 'Conditions',
            description: 'Every preference is independent. Any combination is '
                'valid, and high contrast exists for dark as well as light.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _Choice<Brightness>(
                  label: 'Brightness',
                  value: configuration.brightness,
                  values: Brightness.values,
                  naming: (Brightness value) => value.name,
                  onChanged: (Brightness value) => onConfigurationChanged(
                    configuration.copyWith(brightness: value),
                  ),
                ),
                _Choice<IuxContrast>(
                  label: 'Contrast',
                  value: _profile.contrast,
                  values: IuxContrast.values,
                  naming: (IuxContrast value) => value.name,
                  onChanged: (IuxContrast value) =>
                      _updateProfile(_profile.copyWith(contrast: value)),
                ),
                _Choice<IuxDensity>(
                  label: 'Density',
                  value: _profile.density,
                  values: IuxDensity.values,
                  naming: (IuxDensity value) => value.name,
                  onChanged: (IuxDensity value) =>
                      _updateProfile(_profile.copyWith(density: value)),
                ),
                _Choice<IuxMotionPreference>(
                  label: 'Motion',
                  value: _profile.motion,
                  values: IuxMotionPreference.values,
                  naming: (IuxMotionPreference value) => value.name,
                  onChanged: (IuxMotionPreference value) =>
                      _updateProfile(_profile.copyWith(motion: value)),
                ),
                _Choice<IuxTouchTargetPreference>(
                  label: 'Touch target',
                  value: _profile.touchTarget,
                  values: IuxTouchTargetPreference.values,
                  naming: (IuxTouchTargetPreference value) => value.name,
                  onChanged: (IuxTouchTargetPreference value) =>
                      _updateProfile(_profile.copyWith(touchTarget: value)),
                ),
                _Choice<IuxVisualStimulation>(
                  label: 'Visual stimulation',
                  value: _profile.visualStimulation,
                  values: IuxVisualStimulation.values,
                  naming: (IuxVisualStimulation value) => value.name,
                  onChanged: (IuxVisualStimulation value) => _updateProfile(
                    _profile.copyWith(visualStimulation: value),
                  ),
                ),
                _Choice<double>(
                  label: 'Text scale',
                  value: textScale,
                  values: const <double>[1, 1.5, 2],
                  naming: (double value) => '${value}x',
                  onChanged: onTextScaleChanged,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Long labels', style: type.label),
                          Text(
                            'Checks that a longer language does not clip or '
                            'overflow.',
                            style: type.supporting,
                          ),
                        ],
                      ),
                    ),
                    Switch(value: longLabels, onChanged: onLongLabelsChanged),
                  ],
                ),
              ],
            ),
          ),
          _Panel(
            title: 'What this profile changed',
            description: 'Resolved values, not requested ones.',
            child: _ResolvedValues(
              geometry: geometry,
              motion: motion,
              type: type,
            ),
          ),
          _Panel(
            title: 'Surfaces and content',
            description: 'Levels separate through colour, so hierarchy '
                'survives without a shadow.',
            child: _SurfaceSamples(colors: colors, geometry: geometry),
          ),
          _Panel(
            title: 'Actions',
            description: 'Each intent carries its own state contract. '
                'Painted rectangles — the IUX button arrives in IUX-008.',
            child: _ActionSamples(
              colors: colors,
              geometry: geometry,
              type: type,
              longLabels: longLabels,
            ),
          ),
          _Panel(
            title: 'Feedback',
            description: 'Colour is paired with an icon, so the category '
                'survives a reader who cannot distinguish the hues.',
            child: _FeedbackSamples(
              colors: colors,
              geometry: geometry,
              type: type,
              longLabels: longLabels,
            ),
          ),
          _Panel(
            title: 'Focus',
            description: 'Focus stays distinct from selection: one says where '
                'the keyboard is, the other what the user chose.',
            child: _FocusSamples(
              colors: colors,
              geometry: geometry,
              type: type,
            ),
          ),
          _Panel(
            title: 'Typography',
            description: 'Roles, not sizes. Nothing falls below 14.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (final IuxTypographyRole role in IuxTypographyRole.values)
                  Padding(
                    padding: EdgeInsets.only(bottom: geometry.spacingXs),
                    child: Text(
                      role.name,
                      style: type
                          .forRole(role)
                          .copyWith(color: colors.content.primary),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResolvedValues extends StatelessWidget {
  const _ResolvedValues({
    required this.geometry,
    required this.motion,
    required this.type,
  });

  final IuxGeometryTheme geometry;
  final IuxMotionTheme motion;
  final IuxTypographyTheme type;

  @override
  Widget build(BuildContext context) {
    final IuxSemanticColors colors = IuxSemanticColors.of(context);
    final List<(String, String)> rows = <(String, String)>[
      ('Default spacing', geometry.spacingMd.toStringAsFixed(1)),
      ('Minimum touch target', geometry.minimumTouchTarget.toStringAsFixed(0)),
      ('Border width', geometry.borderWidth.toStringAsFixed(0)),
      ('Focus ring width', geometry.focus.width.toStringAsFixed(0)),
      ('Raised elevation', geometry.elevationRaised.toStringAsFixed(0)),
      ('Standard transition', '${motion.standard.inMilliseconds} ms'),
      (
        'Decorative motion',
        motion.allowsNonEssentialMotion ? 'allowed' : 'suppressed'
      ),
      (
        'Platform preference',
        motion.respectsPlatformPreference ? 'still to consult' : 'overridden'
      ),
    ];

    return Column(
      children: <Widget>[
        for (final (String label, String value) in rows)
          Padding(
            padding: EdgeInsets.only(bottom: geometry.spacingXxs),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    label,
                    style: type.supporting
                        .copyWith(color: colors.content.secondary),
                  ),
                ),
                Text(
                  value,
                  style: type.label.copyWith(color: colors.content.primary),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SurfaceSamples extends StatelessWidget {
  const _SurfaceSamples({required this.colors, required this.geometry});

  final IuxSemanticColors colors;
  final IuxGeometryTheme geometry;

  @override
  Widget build(BuildContext context) {
    final List<(String, Color)> surfaces = <(String, Color)>[
      ('surface.base', colors.surface.base),
      ('surface.subtle', colors.surface.subtle),
      ('surface.raised', colors.surface.raised),
      ('surface.selected', colors.surface.selected),
      ('surface.disabled', colors.surface.disabled),
      ('surface.inverse', colors.surface.inverse),
    ];
    return Column(
      children: <Widget>[
        for (final (String label, Color surface) in surfaces)
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: geometry.spacingXxs),
            padding: EdgeInsets.all(geometry.spacingSm),
            decoration: BoxDecoration(
              color: surface,
              border: Border.all(
                color: colors.border.subtle,
                width: geometry.borderWidth,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: label == 'surface.inverse'
                    ? colors.content.inverse
                    : colors.content.primary,
              ),
            ),
          ),
      ],
    );
  }
}

class _ActionSamples extends StatelessWidget {
  const _ActionSamples({
    required this.colors,
    required this.geometry,
    required this.type,
    required this.longLabels,
  });

  final IuxSemanticColors colors;
  final IuxGeometryTheme geometry;
  final IuxTypographyTheme type;
  final bool longLabels;

  @override
  Widget build(BuildContext context) {
    final Map<String, IuxActionColors> intents = <String, IuxActionColors>{
      'primary': colors.action.primary,
      'secondary': colors.action.secondary,
      'tertiary': colors.action.tertiary,
      'destructive': colors.action.destructive,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final MapEntry<String, IuxActionColors> entry in intents.entries)
          Padding(
            padding: EdgeInsets.only(bottom: geometry.spacingSm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'action.${entry.key}',
                  style: type.label.copyWith(color: colors.content.secondary),
                ),
                SizedBox(height: geometry.spacingXxs),
                Wrap(
                  spacing: geometry.spacingXs,
                  runSpacing: geometry.spacingXs,
                  children: <Widget>[
                    for (final (String state, Color background, Color fg)
                        in <(String, Color, Color)>[
                      ('rest', entry.value.background, entry.value.foreground),
                      (
                        'hover',
                        entry.value.hoveredBackground,
                        entry.value.foreground
                      ),
                      (
                        'press',
                        entry.value.pressedBackground,
                        entry.value.foreground
                      ),
                      (
                        'off',
                        entry.value.disabledBackground,
                        entry.value.disabledForeground
                      ),
                    ])
                      Container(
                        constraints: BoxConstraints(
                          minHeight: geometry.minimumTouchTarget,
                          minWidth: geometry.minimumTouchTarget,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: geometry.spacingSm,
                        ),
                        decoration: BoxDecoration(
                          color: background,
                          border: Border.all(
                            color: entry.value.border,
                            width: geometry.borderWidth,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          longLabels ? '$state — Bestätigungsvorgang' : state,
                          style: type.label.copyWith(color: fg),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _FeedbackSamples extends StatelessWidget {
  const _FeedbackSamples({
    required this.colors,
    required this.geometry,
    required this.type,
    required this.longLabels,
  });

  final IuxSemanticColors colors;
  final IuxGeometryTheme geometry;
  final IuxTypographyTheme type;
  final bool longLabels;

  @override
  Widget build(BuildContext context) {
    final Map<String, (IuxFeedbackRoleColors, IconData)> roles =
        <String, (IuxFeedbackRoleColors, IconData)>{
      'info': (colors.feedback.info, Icons.info_outline),
      'success': (colors.feedback.success, Icons.check_circle_outline),
      'warning': (colors.feedback.warning, Icons.warning_amber_outlined),
      'error': (colors.feedback.error, Icons.error_outline),
    };
    return Column(
      children: <Widget>[
        for (final MapEntry<String, (IuxFeedbackRoleColors, IconData)> entry
            in roles.entries)
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: geometry.spacingXs),
            padding: EdgeInsets.all(geometry.spacingSm),
            decoration: BoxDecoration(
              color: entry.value.$1.surface,
              border: Border.all(
                color: entry.value.$1.border,
                width: geometry.borderWidth,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(entry.value.$2, color: entry.value.$1.icon),
                SizedBox(width: geometry.spacingXs),
                Expanded(
                  child: Text(
                    longLabels
                        ? 'feedback.${entry.key} — Die Zahlungsbestätigung '
                            'konnte nicht abgeschlossen werden.'
                        : 'feedback.${entry.key}',
                    style: type.body.copyWith(color: entry.value.$1.content),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _FocusSamples extends StatelessWidget {
  const _FocusSamples({
    required this.colors,
    required this.geometry,
    required this.type,
  });

  final IuxSemanticColors colors;
  final IuxGeometryTheme geometry;
  final IuxTypographyTheme type;

  @override
  Widget build(BuildContext context) {
    Widget sample(String label, Color border, double width, Widget? mark) =>
        Container(
          constraints: BoxConstraints(minHeight: geometry.minimumTouchTarget),
          margin: EdgeInsets.only(bottom: geometry.spacingXs),
          padding: EdgeInsets.all(geometry.spacingSm),
          decoration: BoxDecoration(
            color: colors.surface.base,
            border: Border.all(color: border, width: width),
          ),
          child: Row(
            children: <Widget>[
              if (mark != null) ...<Widget>[
                mark,
                SizedBox(width: geometry.spacingXs),
              ],
              Text(
                label,
                style: type.body.copyWith(color: colors.content.primary),
              ),
            ],
          ),
        );

    return Column(
      children: <Widget>[
        sample('Focused', colors.border.focus, geometry.focus.width, null),
        sample(
          'Selected',
          colors.border.selected,
          geometry.borderWidth,
          Icon(Icons.check, color: colors.content.primary),
        ),
        sample('Resting', colors.border.standard, geometry.borderWidth, null),
      ],
    );
  }
}

class _Choice<T> extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.value,
    required this.values,
    required this.naming,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T) naming;
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
                  selected: option == value,
                  button: true,
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
                          Text(
                            naming(option),
                            style: type.label
                                .copyWith(color: colors.content.primary),
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

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.description,
    required this.child,
  });

  final String title;
  final String description;
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
