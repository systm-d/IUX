import 'package:flutter/material.dart';
import 'package:iux_flutter/iux_flutter.dart';

/// Demonstrates the accessibility runtime delivered by IUX-005.
///
/// Everything here reads the runtime rather than `MediaQuery`, which is the
/// point: change a preference in the panel above, or in the platform settings,
/// and these react without any of them knowing why.
class RuntimePanels extends StatelessWidget {
  /// Creates the runtime demonstration.
  const RuntimePanels({super.key, required this.panelBuilder});

  /// Wraps each section in the catalog's panel chrome.
  final Widget Function({
    required String title,
    required String description,
    required Widget child,
  }) panelBuilder;

  @override
  Widget build(BuildContext context) {
    final IuxAccessibility a11y = IuxAccessibility.of(context);
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme type = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);

    return Column(
      children: <Widget>[
        panelBuilder(
          title: 'Runtime state',
          description: 'What the application asked for, reconciled with what '
              'the platform reports. The platform can strengthen an '
              'accommodation; the application cannot weaken one.',
          child: Column(
            children: <Widget>[
              for (final (String label, String value) in <(String, String)>[
                ('Contrast in force', a11y.contrast.name),
                ('Motion in force', a11y.motion.name),
                (
                  'Decorative motion',
                  a11y.allowsNonEssentialMotion ? 'allowed' : 'suppressed'
                ),
                (
                  'Minimum touch target',
                  a11y.minimumTouchTarget.toStringAsFixed(0)
                ),
                ('Text scale', a11y.scaleText(16).toStringAsFixed(1)),
                (
                  'Layout should stack',
                  a11y.prefersStackedLayout ? 'yes' : 'no'
                ),
                (
                  'Screen reader expected',
                  a11y.screenReaderExpected ? 'yes' : 'no'
                ),
                (
                  'Announcements supported',
                  IuxAnnouncement.isSupported(context) ? 'yes' : 'no'
                ),
              ])
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
                        style:
                            type.label.copyWith(color: colors.content.primary),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        panelBuilder(
          title: 'Touch targets',
          description: 'The icons stay small. The regions that respond do not. '
              'Switch the touch target preference above and watch the '
              'spacing change while the icons stay put.',
          child: Row(
            children: <Widget>[
              for (final IconData icon in <IconData>[
                Icons.close,
                Icons.add,
                Icons.remove,
                Icons.check,
              ])
                Container(
                  margin: EdgeInsets.only(right: geometry.spacingXxs),
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.border.subtle),
                  ),
                  child: IuxTapTarget(
                    semanticLabel: icon.toString(),
                    onTap: () {},
                    child: Icon(icon, size: 16, color: colors.content.primary),
                  ),
                ),
            ],
          ),
        ),
        panelBuilder(
          title: 'Focus',
          description: 'Tab between these. The ring reserves its space whether '
              'or not it is drawn, so focus never shifts the layout.',
          child: Row(
            children: <Widget>[
              for (final String label in <String>['One', 'Two', 'Three'])
                IuxFocusable(
                  onActivate: () {},
                  child: Container(
                    constraints: BoxConstraints(
                      minHeight: geometry.minimumTouchTarget,
                    ),
                    padding:
                        EdgeInsets.symmetric(horizontal: geometry.spacingSm),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: colors.border.standard,
                        width: geometry.borderWidth,
                      ),
                    ),
                    child: Text(
                      label,
                      style: type.label.copyWith(color: colors.content.primary),
                    ),
                  ),
                ),
            ],
          ),
        ),
        panelBuilder(
          title: 'Motion roles',
          description: 'Each role declares how it adapts. Change the motion '
              'preference above and watch the decisions change.',
          child: Column(
            children: <Widget>[
              for (final IuxMotionRole role in IuxMotionRole.values)
                Builder(
                  builder: (BuildContext context) {
                    final IuxResolvedMotion m =
                        IuxMotionPolicy.resolve(context, role: role);
                    return Padding(
                      padding: EdgeInsets.only(bottom: geometry.spacingXxs),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              role.name,
                              style: type.supporting
                                  .copyWith(color: colors.content.secondary),
                            ),
                          ),
                          Text(
                            '${m.behavior.name} · ${m.duration.inMilliseconds}ms',
                            style: type.label
                                .copyWith(color: colors.content.primary),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        panelBuilder(
          title: 'Feedback roles',
          description: 'Intensity is proportionate to consequence. Only '
              'failures and irreversible actions interrupt a screen reader.',
          child: Column(
            children: <Widget>[
              for (final IuxFeedbackRole role in IuxFeedbackRole.values)
                Padding(
                  padding: EdgeInsets.only(bottom: geometry.spacingXxs),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          role.name,
                          style: type.supporting
                              .copyWith(color: colors.content.secondary),
                        ),
                      ),
                      Text(
                        '${IuxHapticPolicy.patternFor(role).name}'
                        '${role.interrupts ? ' · interrupts' : ''}',
                        style:
                            type.label.copyWith(color: colors.content.primary),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        panelBuilder(
          title: 'Layout',
          description: 'Width caps are measured in characters and converted at '
              'the text size in force, so a larger text keeps the same line '
              'length instead of a narrower column.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Layout class: ${IuxBreakpoints.of(context).name}',
                style: type.label.copyWith(color: colors.content.primary),
              ),
              SizedBox(height: geometry.spacingXxs),
              for (final IuxContentWidth width in IuxContentWidth.values)
                Padding(
                  padding: EdgeInsets.only(bottom: geometry.spacingXxs),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          width.name,
                          style: type.supporting
                              .copyWith(color: colors.content.secondary),
                        ),
                      ),
                      Text(
                        IuxContentWidthResolver.maxWidthFor(context, width)
                                ?.toStringAsFixed(0) ??
                            'no cap',
                        style:
                            type.label.copyWith(color: colors.content.primary),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: geometry.spacingXs),
              Text(
                'Adjacent targets keep at least '
                '${kIuxMinimumTargetSpacing.toStringAsFixed(0)} between them:',
                style:
                    type.supporting.copyWith(color: colors.content.secondary),
              ),
              SizedBox(height: geometry.spacingXxs),
              IuxTargetSpacing(
                axis: Axis.horizontal,
                children: <Widget>[
                  for (final String label in <String>['Cancel', 'Confirm'])
                    IuxSurface(
                      role: IuxSurfaceRole.subtle,
                      bordered: true,
                      padding: IuxInsets.compact(context),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: geometry.minimumTouchTarget,
                        ),
                        child: Align(
                          child: Text(
                            label,
                            style: type.label
                                .copyWith(color: colors.content.primary),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        panelBuilder(
          title: 'Progress',
          description: 'Determinate keeps its bar when motion is reduced — '
              '45% is already a static statement. Indeterminate removes its '
              'bar entirely and falls back to its label: a frozen segment is '
              'parked at a position that means nothing, which reads as a hung '
              'operation. Switch motion to "none" above to see both.',
          child: const _ProgressDemo(),
        ),
        panelBuilder(
          title: 'Announcements',
          description: 'A live region is preferred to an announcement. Android '
              'deprecated announcements because they cut off whatever TalkBack '
              'was saying.',
          child: _AnnouncementDemo(
            geometry: geometry,
            type: type,
            colors: colors,
          ),
        ),
      ],
    );
  }
}

class _AnnouncementDemo extends StatefulWidget {
  const _AnnouncementDemo({
    required this.geometry,
    required this.type,
    required this.colors,
  });

  final IuxGeometryTheme geometry;
  final IuxTypographyTheme type;
  final IuxSemanticColors colors;

  @override
  State<_AnnouncementDemo> createState() => _AnnouncementDemoState();
}

class _AnnouncementDemoState extends State<_AnnouncementDemo> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // The status is on screen and marked live, so the platform announces
        // it once, in context, and the user can re-read it.
        IuxSemantics.liveRegion(
          child: Text(
            _count == 0 ? 'No results' : '$_count results',
            style:
                widget.type.body.copyWith(color: widget.colors.content.primary),
          ),
        ),
        SizedBox(height: widget.geometry.spacingXs),
        IuxFocusable(
          onActivate: _refresh,
          child: IuxTapTarget(
            semanticLabel: 'Refresh results',
            onTap: _refresh,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: widget.geometry.spacingSm,
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: widget.colors.action.primary.background,
                border: Border.all(color: widget.colors.action.primary.border),
              ),
              child: Text(
                'Refresh',
                style: widget.type.label.copyWith(
                  color: widget.colors.action.primary.foreground,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _refresh() => setState(() => _count += 3);
}

class _ProgressDemo extends StatefulWidget {
  const _ProgressDemo();

  @override
  State<_ProgressDemo> createState() => _ProgressDemoState();
}

class _ProgressDemoState extends State<_ProgressDemo> {
  double _value = 0.45;

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme type = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        IuxProgressIndicator(
          label: 'Uploading invoices',
          value: _value,
          // Supplied by the caller: the framework composes no percentage,
          // because '%', '٪' and '45 %' are locale decisions.
          valueLabel: '${(_value * 100).round()}%',
        ),
        SizedBox(height: geometry.spacingXs),
        Row(
          children: <Widget>[
            for (final (String label, double delta) in <(String, double)>[
              ('-25%', -0.25),
              ('+25%', 0.25),
            ])
              Padding(
                padding: EdgeInsets.only(right: geometry.spacingXs),
                child: IuxButton(
                  label: label,
                  variant: IuxButtonVariant.outlined,
                  action: IuxActionDescriptor(
                    semantics: IuxActionSemantics(
                      label: 'Change progress by $label',
                    ),
                  ),
                  onActivate: () => setState(
                    () => _value = (_value + delta).clamp(0.0, 1.0),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: geometry.spacingMd),
        const IuxLoadingIndicator(label: 'Checking availability'),
        SizedBox(height: geometry.spacingXs),
        Text(
          'Both stay announced to a screen reader; only the announcement is '
          'throttled to milestones, never the eye.',
          style: type.supporting.copyWith(color: colors.content.secondary),
        ),
      ],
    );
  }
}
