import 'package:flutter/material.dart';
import 'package:iux_flutter/iux_flutter.dart';

import 'catalog_chrome.dart';

/// The layout widgets, measured rather than described.
///
/// Every number here is read back off the widget that was actually built, so
/// a cap that stops applying at 300% or a frame that quietly took the whole
/// window shows up as a number rather than as a feeling about the screenshot.
class LayoutPanels extends StatelessWidget {
  /// Creates the layout harness.
  const LayoutPanels({super.key, required this.longLabels});

  /// Whether samples use a label of translated length.
  final bool longLabels;

  @override
  Widget build(BuildContext context) => Column(
        children: <Widget>[
          const _WindowPanel(),
          _PagePanel(longLabels: longLabels),
          _SectionPanel(longLabels: longLabels),
          const _SurfacePanel(),
          const _SpacingPanel(),
          const _ReadableWidthPanel(),
        ],
      );
}

/// A sentence of the length a translated paragraph produces.
const String _longProse =
    'Die Zahlungsbestätigung wird an den Empfänger gesendet, sobald die '
    'Rechnung freigegeben wurde und die Buchhaltung sie geprüft hat.';

/// A short sentence, the case every design is drawn for.
const String _shortProse = 'The invoice is ready to send.';

String _prose(bool long) => long ? _longProse : _shortProse;

class _WindowPanel extends StatelessWidget {
  const _WindowPanel();

  @override
  Widget build(BuildContext context) {
    final IuxLayoutClass layoutClass = IuxBreakpoints.of(context);
    const IuxResponsiveValue<String> columns = IuxResponsiveValue<String>(
      compact: 'one column',
      medium: 'two columns',
      expanded: 'three columns',
    );
    const IuxResponsiveValue<String> partial = IuxResponsiveValue<String>(
      compact: 'one column',
      expanded: 'three columns',
    );

    return CatalogPanel(
      title: 'Which window this is',
      description: 'The layout class comes from the window width, not from the '
          'device. Rotate the phone, or run this on a tablet in a split view, '
          'and watch the class change under everything below. It does not move '
          'with the text scale: a 360-wide window at 300% text is still '
          'compact, which is why enlarging text has to be handled by the '
          'widgets rather than by the breakpoint.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CatalogRows(<(String, String)>[
            ('Class in force', layoutClass.name),
            ('Medium starts at', IuxBreakpoints.medium.toStringAsFixed(0)),
            ('Expanded starts at', IuxBreakpoints.expanded.toStringAsFixed(0)),
            ('Full value resolves to', columns.resolve(context)),
            ('Value with no medium resolves to', partial.resolve(context)),
          ]),
          const CatalogNote(
            'The second value declares no medium, so a medium window falls '
            'back to the compact one rather than to the expanded one. Falling '
            'downwards is the safe direction — a layout built for one column '
            'survives a wider window, and one built for three does not survive '
            'a narrower one.',
          ),
        ],
      ),
    );
  }
}

class _PagePanel extends StatelessWidget {
  const _PagePanel({required this.longLabels});

  final bool longLabels;

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);

    return CatalogPanel(
      title: 'A page frame',
      description: 'IuxPage caps the content width, applies the page insets '
          'and pins a footer above the bottom edge. Both frames below are '
          'given scrollable: false, because this catalog is already a '
          'scrollable and a page that brought its own would nest one inside '
          'another — the arrangement where a flung list scrolls whichever of '
          'the two Flutter guessed at.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const CatalogSubheading('a page with a pinned footer'),
          SizedBox(
            height: 220,
            child: IuxPage(
              scrollable: false,
              insets: IuxPageInsets.none,
              footer: IuxButton(
                label: longLabels
                    ? 'Zahlungsbestätigung senden'
                    : 'Send the invoice',
                expand: true,
                action: const IuxActionDescriptor.primary(
                  semantics: IuxActionSemantics(label: 'Send the invoice'),
                ),
                onActivate: () {},
              ),
              child: Text(
                _prose(longLabels),
                style: IuxTypographyTheme.of(context).body.copyWith(
                      color: IuxSemanticColors.of(context).content.primary,
                    ),
              ),
            ),
          ),
          SizedBox(height: geometry.spacingSm),
          const CatalogNote(
            'The footer keeps its own room even when the content above it '
            'grows. At 300% with a long label the frame is 220 tall and the '
            'footer alone can want most of it: nothing may clip, and the '
            'content above may be squeezed to nothing before the footer is. '
            'That order is deliberate — an action the user cannot reach is '
            'worse than a sentence they must scroll for — but a fixed-height '
            'box this small is where you see it.',
          ),
          SizedBox(height: geometry.spacingSm),
          const CatalogSubheading('insets: handled versus none'),
          const CatalogNote(
            'IuxPageInsets decides which of the platform intrusions the page '
            'absorbs. On this screen the frames are nested inside a list that '
            'has already consumed them, so both look the same. The value '
            'matters at the top level, where a page with insets: none puts its '
            'first line under the status bar. That is a device check, not a '
            'catalog one.',
          ),
        ],
      ),
    );
  }
}

class _SectionPanel extends StatelessWidget {
  const _SectionPanel({required this.longLabels});

  final bool longLabels;

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);

    return CatalogPanel(
      title: 'Sections',
      description: 'A heading, an optional sentence under it, and an optional '
          'control beside it. The control and the title share one row: raise '
          'the text scale and check that the title wraps rather than pushing '
          'the control off the edge, and that the control keeps its target '
          'floor when it does.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          IuxSection(
            title: longLabels
                ? 'Zahlungsbestätigungen und Rechnungsanhänge'
                : 'Invoices',
            description: _prose(longLabels),
            trailing: IuxButton(
              label: 'Add',
              variant: IuxButtonVariant.text,
              action: const IuxActionDescriptor(
                semantics: IuxActionSemantics(label: 'Add an invoice'),
              ),
              onActivate: () {},
            ),
            children: <Widget>[
              IuxSurface(
                role: IuxSurfaceRole.subtle,
                bordered: true,
                padding: IuxInsets.surface(context),
                child: Text(
                  'Section content stretches by default.',
                  style: IuxTypographyTheme.of(context).body.copyWith(
                        color: IuxSemanticColors.of(context).content.primary,
                      ),
                ),
              ),
            ],
          ),
          SizedBox(height: geometry.spacingSm),
          const CatalogSubheading('a header with no section around it'),
          const IuxSectionHeader(
            title: 'Attachments',
            description: 'Three files, none of them shared yet.',
          ),
          const CatalogNote(
            'IuxSectionHeader is the same row on its own, for a caller who '
            'owns the content below it — a lazily built list, most often, '
            'which IuxSection cannot hold because it builds its children '
            'eagerly.',
          ),
        ],
      ),
    );
  }
}

class _SurfacePanel extends StatelessWidget {
  const _SurfacePanel();

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme type = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);

    return CatalogPanel(
      title: 'Surfaces',
      description: 'A caller names a level, never a colour. Every role below '
          'is drawn with the same content colour on purpose: one of them is '
          'unreadable, and which one is the point.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final IuxSurfaceRole role in IuxSurfaceRole.values)
            Padding(
              padding: EdgeInsets.only(bottom: geometry.spacingXs),
              child: IuxSurface(
                role: role,
                bordered: true,
                padding: IuxInsets.surface(context),
                child: Text(
                  'role: ${role.name}',
                  style: type.body.copyWith(color: colors.content.primary),
                ),
              ),
            ),
          const CatalogNote(
            'surface.inverse is a dark panel in a light theme and a light one '
            'in dark, and IuxSurface does not touch the content colour, so a '
            'caller who writes content.primary inside it gets a pairing the '
            'theme never measured. Measured now, on the standard light '
            'profile: content.primary on surface.inverse is 1.08:1, which is '
            'text nobody can read, against 17.63:1 for content.inverse on the '
            'same panel. Nothing asserts, and the failure is '
            'invisible until somebody looks. A surface is a background rather '
            'than a component, so it is arguably not the surface\'s job — but '
            'it is nobody else\'s either, and content.inverse exists precisely '
            'for this pairing.',
            finding: true,
          ),
          SizedBox(height: geometry.spacingXs),
          const CatalogSubheading('shapes'),
          Wrap(
            spacing: geometry.spacingXs,
            runSpacing: geometry.spacingXs,
            children: <Widget>[
              for (final IuxSurfaceShape shape in IuxSurfaceShape.values)
                IuxSurface(
                  role: IuxSurfaceRole.subtle,
                  shape: shape,
                  bordered: true,
                  padding: IuxInsets.compact(context),
                  child: Text(
                    shape.name,
                    style: type.label.copyWith(color: colors.content.primary),
                  ),
                ),
            ],
          ),
          SizedBox(height: geometry.spacingSm),
          const CatalogSubheading('elevated'),
          IuxSurface(
            role: IuxSurfaceRole.raised,
            elevated: true,
            padding: IuxInsets.surface(context),
            child: Text(
              'elevated: true',
              style: type.body.copyWith(color: colors.content.primary),
            ),
          ),
          const CatalogNote(
            'The shadow is a hardcoded Color(0x1A000000) inside IuxSurface — '
            'the one colour in the layout package that does not come from a '
            'token. On a dark theme it is black on near-black and carries '
            'nothing; under high contrast it is unmeasured. The semantic layer '
            'models no shadow role, which is the reason, and it is also the '
            'gap: a component that needs a colour the tokens do not have '
            'should say so rather than pick one.',
            finding: true,
          ),
        ],
      ),
    );
  }
}

class _SpacingPanel extends StatelessWidget {
  const _SpacingPanel();

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme type = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);

    Widget bar(IuxSpacingStep step) => Row(
          children: <Widget>[
            SizedBox(
              width: 40,
              child: Text(
                step.name,
                style: type.supporting.copyWith(
                  color: colors.content.secondary,
                ),
              ),
            ),
            IuxGap.horizontal(step),
            Container(width: 4, height: 16, color: colors.border.strong),
          ],
        );

    return CatalogPanel(
      title: 'Gaps, and the distance between two targets',
      description: 'Spacing follows density, so every gap below moves when the '
          'density changes above. The distance between adjacent targets does '
          'not: it is a floor, and a floor that shrank on a compact setting '
          'would put two destructive controls a mistap apart on exactly the '
          'profile where fingers have least room.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final IuxSpacingStep step in IuxSpacingStep.values)
            Padding(
              padding: EdgeInsets.only(bottom: geometry.spacingXxs),
              child: bar(step),
            ),
          SizedBox(height: geometry.spacingSm),
          CatalogRows(<(String, String)>[
            (
              'Minimum spacing between targets',
              kIuxMinimumTargetSpacing.toStringAsFixed(0)
            ),
            ('Page insets', IuxInsets.page(context).toString()),
            ('Surface insets', IuxInsets.surface(context).toString()),
            ('Compact insets', IuxInsets.compact(context).toString()),
            ('Keyboard inset', IuxInsets.keyboard(context).toStringAsFixed(0)),
          ]),
          SizedBox(height: geometry.spacingSm),
          const CatalogSubheading('two targets, horizontally'),
          IuxTargetSpacing(
            axis: Axis.horizontal,
            children: <Widget>[
              for (final String label in <String>['Keep', 'Delete'])
                IuxButton(
                  label: label,
                  variant: IuxButtonVariant.outlined,
                  action: IuxActionDescriptor(
                    semantics: IuxActionSemantics(label: '$label the invoice'),
                  ),
                  onActivate: () {},
                ),
            ],
          ),
          SizedBox(height: geometry.spacingSm),
          const CatalogSubheading('the same two, vertically and full width'),
          IuxTargetSpacing(
            children: <Widget>[
              for (final String label in <String>['Keep', 'Delete'])
                IuxButton(
                  label: label,
                  variant: IuxButtonVariant.outlined,
                  expand: true,
                  action: IuxActionDescriptor(
                    semantics: IuxActionSemantics(
                      label: '$label the invoice, stacked',
                    ),
                  ),
                  onActivate: () {},
                ),
            ],
          ),
          const CatalogNote(
            'The horizontal arrangement is a Wrap, so at 300% the two move to '
            'separate lines rather than overflowing — and the run spacing that '
            'separates them then is the same floor. Watch the order once they '
            'do: "Keep" ends up above "Delete", which is the reading order a '
            'screen reader gets too.',
          ),
          const CatalogNote(
            'The vertical pair above is expanded, and until IUX-038 it could '
            'not be. IuxTargetSpacing was a Wrap on both axes, and a Wrap '
            'offers its children no width, so IuxButton\'s expand — a '
            'SizedBox(width: double.infinity) — forced an infinite width and '
            'the layout threw on "BoxConstraints forces an infinite width". '
            'Two full-width buttons stacked with the library\'s own spacing '
            'primitive is the most ordinary thing a caller can write, and it '
            'was the one arrangement the primitive refused. The vertical axis '
            'is a Column now; the horizontal one is still a Wrap, which is '
            'what lets the pair above it move to a second line.',
          ),
          const CatalogNote(
            'The measurement that decided the shape is better than the crash '
            'it fixed. A vertical Wrap protected nothing: a page scrolls, so '
            'height is normally unbounded and it never wrapped at all — and '
            'where height *was* bounded it moved the overflow sideways in '
            'silence, putting a target off the right edge with no exception '
            'reported. The Column reports a RenderFlex overflow instead.',
          ),
          SizedBox(height: geometry.spacingSm),
          const CatalogSubheading(
            'the arrangement people reached for instead: a Column and a gap',
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              IuxButton(
                label: 'Keep',
                variant: IuxButtonVariant.outlined,
                expand: true,
                action: const IuxActionDescriptor(
                  semantics: IuxActionSemantics(
                    label: 'Keep the invoice, full width',
                  ),
                ),
                onActivate: () {},
              ),
              const IuxGap(IuxSpacingStep.xs),
              IuxButton(
                label: 'Delete',
                variant: IuxButtonVariant.outlined,
                expand: true,
                action: const IuxActionDescriptor(
                  semantics: IuxActionSemantics(
                    label: 'Delete the invoice, full width',
                  ),
                ),
                onActivate: () {},
              ),
            ],
          ),
          const CatalogNote(
            'A gap from the spacing scale is not the target floor: it follows '
            'density and can resolve below eight. This arrangement gets the '
            'width and gives up the guarantee the primitive above exists to '
            'make — which is what it cost to reach for it while the primitive '
            'was broken, and the reason to stop reaching for it now. Measured: '
            'two bare 48-tall targets in IuxTargetSpacing come out 8 pixels '
            'apart; with IuxGap(IuxSpacingStep.xxs) they come out 4.',
          ),
        ],
      ),
    );
  }
}

class _ReadableWidthPanel extends StatelessWidget {
  const _ReadableWidthPanel();

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme type = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);

    return CatalogPanel(
      title: 'Readable width',
      description: 'A cap is a character count converted at the text size in '
          'force, so enlarging text widens the column instead of narrowing it. '
          'The measured width under each block is the box the text was given. '
          'On a phone every cap is wider than the window, so nothing appears '
          'to happen — that is the honest result, and it is why the numbers '
          'are printed rather than the effect described.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final IuxContentWidth width in IuxContentWidth.values)
            Padding(
              padding: EdgeInsets.only(bottom: geometry.spacingSm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  CatalogSubheading(
                    '${width.name} — '
                    '${IuxContentWidthResolver.charactersFor(width)} characters'
                    ', cap '
                    '${IuxContentWidthResolver.maxWidthFor(context, width)?.toStringAsFixed(0) ?? 'none'}',
                  ),
                  CatalogMeasured(
                    checksTarget: false,
                    child: IuxReadableWidth(
                      width: width,
                      child: Text(
                        _longProse,
                        style: type.body.copyWith(
                          color: colors.content.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const CatalogNote(
            'fluid declares no cap at all, so its measurement is the window. '
            'It is the value to reach for when the content is a table or a '
            'picture rather than prose — a capped table is a table with a '
            'scrollbar nobody asked for.',
          ),
        ],
      ),
    );
  }
}
