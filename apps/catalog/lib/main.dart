import 'package:flutter/material.dart';
import 'package:iux_flutter/iux_flutter.dart';

import 'button_panels.dart';
import 'button_scenarios.dart';
import 'catalog_chrome.dart';
import 'catalog_overlays.dart';
import 'content_panels.dart';
import 'feedback_panels.dart';
import 'flow_panels.dart';
import 'form_panels.dart';
import 'input_panels.dart';
import 'layout_panels.dart';
import 'navigation_panels.dart';
import 'overlay_panels.dart';
import 'runtime_panels.dart';
import 'search_panels.dart';
import 'status_panels.dart';
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
///
/// Ordered the way the library is built rather than alphabetically: the things
/// a user touches, then the things that arrange them, then the patterns made
/// out of both, then the two engines underneath. A maintainer looking for
/// "where does the chip live" gets a wrong first guess either way, which is
/// why the summary line names the section as well.
enum _Section {
  /// Buttons and the action model behind them.
  buttons('Buttons'),

  /// The text field and the selection controls.
  inputs('Inputs'),

  /// Forms, validation and the guided form.
  forms('Forms'),

  /// The search field and the four states a search is in.
  search('Search'),

  /// Cards, rows and the containers that hold them.
  content('Cards and lists'),

  /// Glyphs, avatars, pictures, statuses, chips and badges.
  media('Media and status'),

  /// Pages, sections, surfaces, spacing and reading width.
  layout('Layout'),

  /// Bars, rails, drawers and tabs.
  navigation('Navigation'),

  /// Dialogs, sheets, transient messages and tooltips.
  overlays('Overlays'),

  /// Alerts, banners and progress.
  feedback('Feedback'),

  /// Absence, failure, permission, destruction and disclosure.
  flows('Flows'),

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

  /// Every other overlay, for the same reason.
  ///
  /// Four sections need one — a drawer, a dialog, a sheet, a transient strip —
  /// and all four are placed here, once, rather than four times in four
  /// panels. That is not a catalog convenience: it is the arrangement the
  /// library requires, and building it anywhere else is how an application
  /// ends up with two scrims.
  final CatalogOverlays _overlays = CatalogOverlays();

  _Section _section = _Section.buttons;

  /// Whether the section list and the three axes are showing.
  ///
  /// Open by default. A harness whose axes are hidden until somebody discovers
  /// them is a harness that gets used at 100% forever — which is exactly the
  /// habit it exists to break.
  bool _headerExpanded = true;

  @override
  void dispose() {
    _scenarios.dispose();
    _overlays.dispose();
    super.dispose();
  }

  /// The conditions in one line, for the folded header.
  ///
  /// Names the section as well as the profile, so a screenshot of a folded
  /// header is still evidence of what produced it.
  String get _summary {
    final IuxAccessibilityProfile profile = widget.configuration.profile;
    return <String>[
      _section.title,
      widget.configuration.brightness.name,
      '${profile.contrast.name} contrast',
      profile.density.name,
      '${profile.motion.name} motion',
      '${widget.textScale}x text',
      widget.longLabels ? 'long labels' : 'short labels',
    ].join(' · ');
  }

  /// Switches section, taking any open modal with it.
  ///
  /// A modal left open across a section change would be a question about a
  /// panel that is no longer underneath it, and answering it would act on
  /// something the user can no longer see.
  void _selectSection(_Section value) {
    _overlays.closeModal();
    setState(() => _section = value);
  }

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('IUX catalog')),
      body: ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[_scenarios, _overlays]),
        builder: (BuildContext context, Widget? child) {
          // Precedence rather than trust. `IuxModalLayer` asserts that at most
          // one of its three slots is filled, and two owners feed it: a
          // destructive confirmation from the button section and everything
          // else from the overlay owner. Switching section closes both, so the
          // collision is already unreachable — and an assertion that fires in
          // debug and stacks two scrims in release is not worth leaving to an
          // argument about reachability.
          final IuxDialog? dialog = _scenarios.dialog ?? _overlays.dialog;

          return IuxModalLayer(
            dialog: dialog,
            sheet: dialog == null ? _overlays.sheet : null,
            drawer: dialog == null ? _overlays.drawer : null,
            child: IuxTransientLayer(
              message: _overlays.notice,
              onDismissed: _overlays.dismissNotice,
              child: ListView(
                padding: EdgeInsets.all(geometry.spacingMd),
                children: <Widget>[
                  CatalogHeader(
                    summary: _summary,
                    expanded: _headerExpanded,
                    onExpandedChanged: (bool value) =>
                        setState(() => _headerExpanded = value),
                    child: _ConditionsPanel(
                      section: _section,
                      configuration: widget.configuration,
                      textScale: widget.textScale,
                      longLabels: widget.longLabels,
                      onSectionChanged: _selectSection,
                      onConfigurationChanged: widget.onConfigurationChanged,
                      onTextScaleChanged: widget.onTextScaleChanged,
                      onLongLabelsChanged: widget.onLongLabelsChanged,
                    ),
                  ),
                  switch (_section) {
                    _Section.buttons => ButtonPanels(
                        scenarios: _scenarios,
                        longLabels: widget.longLabels,
                      ),
                    _Section.inputs =>
                      InputPanels(longLabels: widget.longLabels),
                    _Section.forms => FormPanels(longLabels: widget.longLabels),
                    _Section.search =>
                      SearchPanels(longLabels: widget.longLabels),
                    _Section.content =>
                      ContentPanels(longLabels: widget.longLabels),
                    _Section.media =>
                      StatusPanels(longLabels: widget.longLabels),
                    _Section.layout =>
                      LayoutPanels(longLabels: widget.longLabels),
                    _Section.navigation => NavigationPanels(
                        longLabels: widget.longLabels,
                        overlays: _overlays,
                      ),
                    _Section.overlays => OverlayPanels(
                        longLabels: widget.longLabels,
                        overlays: _overlays,
                      ),
                    _Section.feedback =>
                      FeedbackPanels(longLabels: widget.longLabels),
                    _Section.flows => FlowPanels(
                        longLabels: widget.longLabels,
                        overlays: _overlays,
                      ),
                    _Section.theme =>
                      ThemePanels(longLabels: widget.longLabels),
                    _Section.runtime => const RuntimePanels(),
                  },
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The three axes every panel is stressed along, and the section chooser.
class _ConditionsPanel extends StatelessWidget {
  const _ConditionsPanel({
    required this.section,
    required this.configuration,
    required this.textScale,
    required this.longLabels,
    required this.onSectionChanged,
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

  final _Section section;
  final IuxThemeConfiguration configuration;
  final double textScale;
  final bool longLabels;
  final ValueChanged<_Section> onSectionChanged;
  final ValueChanged<IuxThemeConfiguration> onConfigurationChanged;
  final ValueChanged<double> onTextScaleChanged;
  final ValueChanged<bool> onLongLabelsChanged;

  IuxAccessibilityProfile get _profile => configuration.profile;

  void _updateProfile(IuxAccessibilityProfile profile) =>
      onConfigurationChanged(configuration.copyWith(profile: profile));

  // The worst-case conditions, in one place. The button applies these and the
  // sentence beneath it is computed from the same values, so the two cannot
  // disagree — the mistake a hand-written caption makes the first time
  // somebody changes the preset and forgets the prose.
  static const Brightness _stressBrightness = Brightness.dark;
  static const IuxContrast _stressContrast = IuxContrast.high;
  static const IuxDensity _stressDensity = IuxDensity.compact;
  static const double _stressTextScale = 3;
  static const bool _stressLongLabels = true;

  static String get _stressDescription =>
      'Applies ${_stressBrightness.name}, ${_stressContrast.name} contrast, '
      '${_stressDensity.name} density, '
      '${_stressTextScale.toStringAsFixed(0)}00% text and long labels. '
      'The text is meant to be that large: it is where most defects show.';

  void _applyStress() {
    onConfigurationChanged(
      configuration.copyWith(
        brightness: _stressBrightness,
        profile: _profile.copyWith(
          contrast: _stressContrast,
          density: _stressDensity,
        ),
      ),
    );
    onTextScaleChanged(_stressTextScale);
    onLongLabelsChanged(_stressLongLabels);
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
    final IuxSemanticColors colors = IuxSemanticColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Every preference is independent. Any combination is valid, and high '
          'contrast exists for dark as well as light. The two presets are '
          'shortcuts, not modes: at 300% the chips below are large enough that '
          'setting six of them by hand is its own obstacle, which is also why '
          'this whole header folds away.',
          style: type.supporting.copyWith(color: colors.content.secondary),
        ),
        SizedBox(height: geometry.spacingSm),
        CatalogChoice<_Section>(
          label: 'Section',
          value: section,
          values: _Section.values,
          naming: (_Section value) => value.title,
          onChanged: onSectionChanged,
        ),
        IuxTargetSpacing(
          axis: Axis.horizontal,
          children: <Widget>[
            IuxButton(
              label: 'Worst case',
              action: IuxActionDescriptor(
                semantics: IuxActionSemantics(
                  label: 'Apply the worst-case conditions',
                  hint: _stressDescription,
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
        SizedBox(height: geometry.spacingXxs),
        Text(_stressDescription, style: type.body),
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
    );
  }
}
