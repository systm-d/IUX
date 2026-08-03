import 'package:flutter/material.dart';
import 'package:iux_flutter/iux_flutter.dart';

import 'demonstration_palettes.dart';

void main() {
  runApp(const IuxCatalogApp());
}

/// Local integration surface for the experimental IUX package.
///
/// The catalog explains roles rather than promoting a palette. Every swatch is
/// labelled with the role it represents, because the point is to make the
/// semantic layer inspectable, not to present a finished look.
class IuxCatalogApp extends StatefulWidget {
  /// Creates the catalog application.
  const IuxCatalogApp({super.key});

  @override
  State<IuxCatalogApp> createState() => _IuxCatalogAppState();
}

class _IuxCatalogAppState extends State<IuxCatalogApp> {
  Brightness _brightness = Brightness.light;

  IuxSemanticColors get _colors => _brightness == Brightness.light
      ? CatalogPalettes.light
      : CatalogPalettes.dark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IUX catalog',
      theme: ThemeData(
        brightness: _brightness,
        scaffoldBackgroundColor: _colors.surface.base,
        extensions: <ThemeExtension<dynamic>>[_colors],
      ),
      home: _SemanticRolesScreen(
        brightness: _brightness,
        onBrightnessChanged: (Brightness value) =>
            setState(() => _brightness = value),
      ),
    );
  }
}

class _SemanticRolesScreen extends StatelessWidget {
  const _SemanticRolesScreen({
    required this.brightness,
    required this.onBrightnessChanged,
  });

  final Brightness brightness;
  final ValueChanged<Brightness> onBrightnessChanged;

  @override
  Widget build(BuildContext context) {
    final IuxSemanticColors colors = IuxSemanticColors.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.surface.subtle,
        foregroundColor: colors.content.primary,
        title: const Text('IUX semantic roles'),
        actions: <Widget>[
          Semantics(
            label: 'Dark condition',
            child: Switch(
              value: brightness == Brightness.dark,
              onChanged: (bool value) => onBrightnessChanged(
                value ? Brightness.dark : Brightness.light,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(IuxSpacing.md),
        children: <Widget>[
          _Note(
            'These mappings demonstrate the roles of ${Iux.packageName} '
            '${Iux.version}. They are not themes, and not a brand palette. '
            'IUX-004 replaces them with a real theme engine.',
            colors: colors,
          ),
          _Section(
            title: 'Content',
            description: 'Emphasis decreases from primary to tertiary. '
                'Every level stays readable.',
            colors: colors,
            swatches: <_Swatch>[
              _Swatch('content.primary', colors.content.primary),
              _Swatch('content.secondary', colors.content.secondary),
              _Swatch('content.tertiary', colors.content.tertiary),
              _Swatch('content.disabled', colors.content.disabled),
              _Swatch('content.link', colors.content.link),
              _Swatch('content.onAction', colors.content.onAction),
              _Swatch('content.inverse', colors.content.inverse),
            ],
          ),
          _Section(
            title: 'Surface',
            description: 'Levels separate through color, so hierarchy '
                'survives without a shadow.',
            colors: colors,
            swatches: <_Swatch>[
              _Swatch('surface.base', colors.surface.base),
              _Swatch('surface.subtle', colors.surface.subtle),
              _Swatch('surface.raised', colors.surface.raised),
              _Swatch('surface.overlay', colors.surface.overlay),
              _Swatch('surface.interactive', colors.surface.interactive),
              _Swatch('surface.selected', colors.surface.selected),
              _Swatch('surface.disabled', colors.surface.disabled),
              _Swatch('surface.inverse', colors.surface.inverse),
            ],
          ),
          _Section(
            title: 'Border',
            description: 'Roles carry no thickness. Focus stays distinct from '
                'selection.',
            colors: colors,
            swatches: <_Swatch>[
              _Swatch('border.standard', colors.border.standard),
              _Swatch('border.subtle', colors.border.subtle),
              _Swatch('border.strong', colors.border.strong),
              _Swatch('border.interactive', colors.border.interactive),
              _Swatch('border.focus', colors.border.focus),
              _Swatch('border.selected', colors.border.selected),
              _Swatch('border.disabled', colors.border.disabled),
              _Swatch('border.error', colors.border.error),
            ],
          ),
          _ActionSection(colors: colors),
          _FeedbackSection(colors: colors),
          _Section(
            title: 'State',
            description: 'Transverse states. Disabled uses dedicated roles '
                'rather than an opacity, so contrast stays predictable.',
            colors: colors,
            swatches: <_Swatch>[
              _Swatch('state.focus', colors.state.focus),
              _Swatch('state.selected', colors.state.selected),
              _Swatch('state.hovered', colors.state.hovered),
              _Swatch('state.pressed', colors.state.pressed),
              _Swatch('state.dragged', colors.state.dragged),
            ],
          ),
          _NonColorSection(colors: colors),
        ],
      ),
    );
  }
}

class _Swatch {
  const _Swatch(this.label, this.color);

  final String label;
  final Color color;
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.description,
    required this.colors,
    required this.swatches,
  });

  final String title;
  final String description;
  final IuxSemanticColors colors;
  final List<_Swatch> swatches;

  @override
  Widget build(BuildContext context) {
    return _Card(
      colors: colors,
      title: title,
      description: description,
      child: Column(
        children: <Widget>[
          for (final _Swatch swatch in swatches)
            Padding(
              padding: const EdgeInsets.only(bottom: IuxSpacing.xs),
              child: Row(
                children: <Widget>[
                  Container(
                    width: IuxTouchTarget.minimum,
                    height: IuxSpacing.lg,
                    decoration: BoxDecoration(
                      color: swatch.color,
                      border: Border.all(color: colors.border.subtle),
                    ),
                  ),
                  const SizedBox(width: IuxSpacing.sm),
                  Expanded(
                    child: Text(
                      swatch.label,
                      style: TextStyle(color: colors.content.secondary),
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

class _ActionSection extends StatelessWidget {
  const _ActionSection({required this.colors});

  final IuxSemanticColors colors;

  @override
  Widget build(BuildContext context) {
    final Map<String, IuxActionColors> intents = <String, IuxActionColors>{
      'primary': colors.action.primary,
      'secondary': colors.action.secondary,
      'tertiary': colors.action.tertiary,
      'destructive': colors.action.destructive,
    };
    return _Card(
      colors: colors,
      title: 'Action',
      description: 'Each intent owns its full state contract, so an action '
          'cannot look primary while behaving destructively. These are '
          'painted rectangles, not IUX buttons: the button arrives in '
          'IUX-008.',
      child: Column(
        children: <Widget>[
          for (final MapEntry<String, IuxActionColors> entry in intents.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: IuxSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'action.${entry.key}',
                    style: TextStyle(color: colors.content.secondary),
                  ),
                  const SizedBox(height: IuxSpacing.xxs),
                  Row(
                    children: <Widget>[
                      _ActionSample('rest', entry.value.foreground,
                          entry.value.background, entry.value.border),
                      _ActionSample('hover', entry.value.foreground,
                          entry.value.hoveredBackground, entry.value.border),
                      _ActionSample('press', entry.value.foreground,
                          entry.value.pressedBackground, entry.value.border),
                      _ActionSample(
                        'off',
                        entry.value.disabledForeground,
                        entry.value.disabledBackground,
                        colors.border.disabled,
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionSample extends StatelessWidget {
  const _ActionSample(
      this.label, this.foreground, this.background, this.borderColor);

  final String label;
  final Color foreground;
  final Color background;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: IuxSpacing.xs),
      child: Container(
        constraints: const BoxConstraints(minHeight: IuxTouchTarget.minimum),
        padding: const EdgeInsets.symmetric(
          horizontal: IuxSpacing.sm,
          vertical: IuxSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: background,
          border: Border.all(color: borderColor),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(color: foreground)),
      ),
    );
  }
}

class _FeedbackSection extends StatelessWidget {
  const _FeedbackSection({required this.colors});

  final IuxSemanticColors colors;

  @override
  Widget build(BuildContext context) {
    final Map<String, (IuxFeedbackRoleColors, IconData)> roles =
        <String, (IuxFeedbackRoleColors, IconData)>{
      'info': (colors.feedback.info, Icons.info_outline),
      'success': (colors.feedback.success, Icons.check_circle_outline),
      'warning': (colors.feedback.warning, Icons.warning_amber_outlined),
      'error': (colors.feedback.error, Icons.error_outline),
    };
    return _Card(
      colors: colors,
      title: 'Feedback',
      description: 'Each role pairs a color with an icon and wording. The '
          'category must survive a reader who cannot distinguish the hues.',
      child: Column(
        children: <Widget>[
          for (final MapEntry<String, (IuxFeedbackRoleColors, IconData)> entry
              in roles.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: IuxSpacing.xs),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(IuxSpacing.sm),
                decoration: BoxDecoration(
                  color: entry.value.$1.surface,
                  border: Border.all(color: entry.value.$1.border),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(entry.value.$2, color: entry.value.$1.icon),
                    const SizedBox(width: IuxSpacing.xs),
                    Expanded(
                      child: Text(
                        'feedback.${entry.key}',
                        style: TextStyle(color: entry.value.$1.content),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NonColorSection extends StatelessWidget {
  const _NonColorSection({required this.colors});

  final IuxSemanticColors colors;

  @override
  Widget build(BuildContext context) {
    return _Card(
      colors: colors,
      title: 'Without color alone',
      description: 'The same four states, rendered in a single hue. If a '
          'meaning disappears here, the role was carrying it through color '
          'alone, and a component using it would fail for part of its users.',
      child: Column(
        children: <Widget>[
          for (final (String label, IconData icon) in <(String, IconData)>[
            ('Information', Icons.info_outline),
            ('Completed', Icons.check_circle_outline),
            ('Needs attention', Icons.warning_amber_outlined),
            ('Failed', Icons.error_outline),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: IuxSpacing.xs),
              child: Row(
                children: <Widget>[
                  Icon(icon, color: colors.content.primary),
                  const SizedBox(width: IuxSpacing.xs),
                  Text(label, style: TextStyle(color: colors.content.primary)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.colors,
    required this.title,
    required this.description,
    required this.child,
  });

  final IuxSemanticColors colors;
  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: IuxSpacing.md),
      padding: const EdgeInsets.all(IuxSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface.raised,
        border: Border.all(color: colors.border.standard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              color: colors.content.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: IuxSpacing.xxs),
          Text(description, style: TextStyle(color: colors.content.secondary)),
          const SizedBox(height: IuxSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text, {required this.colors});

  final String text;
  final IuxSemanticColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: IuxSpacing.md),
      padding: const EdgeInsets.all(IuxSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surface.subtle,
        border: Border.all(color: colors.border.subtle),
      ),
      child: Text(text, style: TextStyle(color: colors.content.secondary)),
    );
  }
}
