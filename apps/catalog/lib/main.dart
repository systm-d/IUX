import 'package:flutter/material.dart';
import 'package:iux_flutter/iux_flutter.dart';

import 'button_panels.dart';
import 'button_scenarios.dart';
import 'catalog_chrome.dart';
import 'runtime_panels.dart';
import 'theme_panels.dart';

void main() {
  runApp(const IuxCatalogApp());
}

/// A harness for the IUX package, not a showroom for it.
///
/// The catalog exists so a maintainer can put a component under the conditions
/// it is most likely to fail in and watch it fail: an accessibility profile
/// nobody designs for, a text scale of 300%, a label of the length translation
/// actually produces. Every panel says what it is trying to prove before it
/// shows anything.
///
/// The three conditions are owned here, above everything, because they have to
/// apply to every section at once. Anything that changed only one panel would
/// prove only that the panel was written to survive it.
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
    return IuxFeedbackScope(
      child: MaterialApp(
        title: 'IUX catalog',
        theme: IuxTheme.fromConfiguration(_configuration),
        home: MediaQuery.withClampedTextScaling(
          minScaleFactor: _textScale,
          maxScaleFactor: _textScale,
          child: _CatalogHome(
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
      ),
    );
  }
}

/// Which part of the library is on screen.
enum _Section {
  /// Buttons and the action model behind them.
  buttons('Buttons'),

  /// What a theme profile resolves to, before any component is involved.
  theme('Theme'),

  /// The accessibility, motion, feedback and layout runtimes.
  runtime('Runtime');

  const _Section(this.title);

  final String title;
}

class _CatalogHome extends StatefulWidget {
  const _CatalogHome({
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

  @override
  State<_CatalogHome> createState() => _CatalogHomeState();
}

class _CatalogHomeState extends State<_CatalogHome> {
  /// Owned here rather than inside the button panels.
  ///
  /// The confirmation a destructive action opens has to be handed to an
  /// `IuxModalLayer` at page level: a pattern that opened its own overlay from
  /// wherever the button happened to sit would be deciding layering, which is
  /// how two modals end up open at once with the way out of neither visible.
  /// So the page owns the state, exactly as an application would.
  final ButtonScenarios _scenarios = ButtonScenarios();

  _Section _section = _Section.buttons;

  @override
  void dispose() {
    _scenarios.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('IUX catalog')),
      body: ListenableBuilder(
        listenable: _scenarios,
        builder: (BuildContext context, Widget? child) => IuxModalLayer(
          dialog: _scenarios.dialog,
          child: ListView(
            padding: EdgeInsets.all(geometry.spacingMd),
            children: <Widget>[
              CatalogPanel(
                title: 'Section',
                description: 'The conditions below apply to whichever section '
                    'is showing, so a profile chosen here follows you into the '
                    'next one.',
                child: CatalogChoice<_Section>(
                  label: 'Section',
                  value: _section,
                  values: _Section.values,
                  naming: (_Section value) => value.title,
                  onChanged: (_Section value) =>
                      setState(() => _section = value),
                ),
              ),
              _ConditionsPanel(
                configuration: widget.configuration,
                textScale: widget.textScale,
                longLabels: widget.longLabels,
                onConfigurationChanged: widget.onConfigurationChanged,
                onTextScaleChanged: widget.onTextScaleChanged,
                onLongLabelsChanged: widget.onLongLabelsChanged,
              ),
              switch (_section) {
                _Section.buttons => ButtonPanels(
                    scenarios: _scenarios,
                    longLabels: widget.longLabels,
                  ),
                _Section.theme => ThemePanels(longLabels: widget.longLabels),
                _Section.runtime => const RuntimePanels(),
              },
            ],
          ),
        ),
      ),
    );
  }
}

/// The three axes every panel is stressed along.
class _ConditionsPanel extends StatelessWidget {
  const _ConditionsPanel({
    required this.configuration,
    required this.textScale,
    required this.longLabels,
    required this.onConfigurationChanged,
    required this.onTextScaleChanged,
    required this.onLongLabelsChanged,
  });

  /// The text scales the harness offers.
  ///
  /// Up to 300%, which Android reaches on its largest font setting with
  /// display size enlarged as well. A component checked at 200% and shipped is
  /// a component that has not met its largest users.
  static const List<double> _scales = <double>[1, 1.5, 2, 3];

  final IuxThemeConfiguration configuration;
  final double textScale;
  final bool longLabels;
  final ValueChanged<IuxThemeConfiguration> onConfigurationChanged;
  final ValueChanged<double> onTextScaleChanged;
  final ValueChanged<bool> onLongLabelsChanged;

  IuxAccessibilityProfile get _profile => configuration.profile;

  void _updateProfile(IuxAccessibilityProfile profile) =>
      onConfigurationChanged(configuration.copyWith(profile: profile));

  void _applyStress() {
    onConfigurationChanged(
      configuration.copyWith(
        brightness: Brightness.dark,
        profile: _profile.copyWith(
          contrast: IuxContrast.high,
          density: IuxDensity.compact,
        ),
      ),
    );
    onTextScaleChanged(3);
    onLongLabelsChanged(true);
  }

  void _applyDefaults() {
    onConfigurationChanged(const IuxThemeConfiguration());
    onTextScaleChanged(1);
    onLongLabelsChanged(false);
  }

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme type = IuxTypographyTheme.of(context);

    return CatalogPanel(
      title: 'Conditions',
      description: 'Every preference is independent. Any combination is valid, '
          'and high contrast exists for dark as well as light. The two presets '
          'are shortcuts, not modes: at 300% the chips below are large enough '
          'that setting six of them by hand is its own obstacle.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          IuxTargetSpacing(
            axis: Axis.horizontal,
            children: <Widget>[
              IuxButton(
                label: 'Worst case',
                action: const IuxActionDescriptor(
                  semantics: IuxActionSemantics(
                    label: 'Apply the worst-case conditions',
                    hint: 'Dark, high contrast, compact, 300% text, long '
                        'labels',
                  ),
                ),
                onActivate: _applyStress,
              ),
              IuxButton(
                label: 'Defaults',
                variant: IuxButtonVariant.outlined,
                action: const IuxActionDescriptor(
                  role: IuxActionRole.undo,
                  semantics: IuxActionSemantics(
                      label: 'Return to the default '
                          'conditions'),
                ),
                onActivate: _applyDefaults,
              ),
            ],
          ),
          SizedBox(height: geometry.spacingSm),
          CatalogChoice<Brightness>(
            label: 'Brightness',
            value: configuration.brightness,
            values: Brightness.values,
            naming: (Brightness value) => value.name,
            onChanged: (Brightness value) => onConfigurationChanged(
              configuration.copyWith(brightness: value),
            ),
          ),
          CatalogChoice<IuxContrast>(
            label: 'Contrast',
            value: _profile.contrast,
            values: IuxContrast.values,
            naming: (IuxContrast value) => value.name,
            onChanged: (IuxContrast value) =>
                _updateProfile(_profile.copyWith(contrast: value)),
          ),
          CatalogChoice<IuxDensity>(
            label: 'Density',
            value: _profile.density,
            values: IuxDensity.values,
            naming: (IuxDensity value) => value.name,
            onChanged: (IuxDensity value) =>
                _updateProfile(_profile.copyWith(density: value)),
          ),
          CatalogChoice<IuxMotionPreference>(
            label: 'Motion',
            value: _profile.motion,
            values: IuxMotionPreference.values,
            naming: (IuxMotionPreference value) => value.name,
            onChanged: (IuxMotionPreference value) =>
                _updateProfile(_profile.copyWith(motion: value)),
          ),
          CatalogChoice<IuxTouchTargetPreference>(
            label: 'Touch target',
            value: _profile.touchTarget,
            values: IuxTouchTargetPreference.values,
            naming: (IuxTouchTargetPreference value) => value.name,
            onChanged: (IuxTouchTargetPreference value) =>
                _updateProfile(_profile.copyWith(touchTarget: value)),
          ),
          CatalogChoice<IuxVisualStimulation>(
            label: 'Visual stimulation',
            value: _profile.visualStimulation,
            values: IuxVisualStimulation.values,
            naming: (IuxVisualStimulation value) => value.name,
            onChanged: (IuxVisualStimulation value) =>
                _updateProfile(_profile.copyWith(visualStimulation: value)),
          ),
          CatalogChoice<double>(
            label: 'Text scale',
            value: textScale,
            values: _scales,
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
                      'Replaces every sample label with one of the length a '
                      'German or Finnish translation produces.',
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
    );
  }
}
