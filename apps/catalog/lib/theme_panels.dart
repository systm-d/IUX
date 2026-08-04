import 'package:flutter/material.dart';
import 'package:iux_flutter/iux_flutter.dart';

import 'catalog_chrome.dart';

/// What a theme profile resolves to, before any component is involved.
///
/// Nothing here is an IUX component. These are plain Flutter widgets painted
/// with resolved token values, which is the point: the theme can be inspected
/// without a component's own decisions standing in the way. The components are
/// in the other sections.
class ThemePanels extends StatelessWidget {
  /// Creates the theme explorer.
  const ThemePanels({super.key, required this.longLabels});

  /// Whether samples use a longer language.
  final bool longLabels;

  @override
  Widget build(BuildContext context) {
    final IuxSemanticColors colors = IuxSemanticColors.of(context);
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme type = IuxTypographyTheme.of(context);
    final IuxMotionTheme motion = IuxMotionTheme.of(context);

    return Column(
      children: <Widget>[
        CatalogPanel(
          title: 'What this profile changed',
          description: 'Resolved values, not requested ones.',
          child: CatalogRows(<(String, String)>[
            ('Default spacing', geometry.spacingMd.toStringAsFixed(1)),
            (
              'Minimum touch target',
              geometry.minimumTouchTarget.toStringAsFixed(0)
            ),
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
              motion.respectsPlatformPreference
                  ? 'still to consult'
                  : 'overridden'
            ),
          ]),
        ),
        CatalogPanel(
          title: 'Surfaces and content',
          description: 'Levels separate through colour, so hierarchy survives '
              'without a shadow.',
          child: _SurfaceSamples(colors: colors, geometry: geometry),
        ),
        CatalogPanel(
          title: 'Action token pairs',
          description: 'The colour pairs a button resolves from, drawn as bare '
              'rectangles so the theme is visible without a component in the '
              'way. The buttons themselves are in the Buttons section.',
          child: _ActionSamples(
            colors: colors,
            geometry: geometry,
            type: type,
            longLabels: longLabels,
          ),
        ),
        CatalogPanel(
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
        CatalogPanel(
          title: 'Focus',
          description: 'Focus stays distinct from selection: one says where '
              'the keyboard is, the other what the user chose.',
          child: _FocusSamples(colors: colors, geometry: geometry, type: type),
        ),
        CatalogPanel(
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
                            color: colors.border.standard,
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
