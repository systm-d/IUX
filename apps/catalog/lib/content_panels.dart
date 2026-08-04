import 'package:flutter/material.dart';
import 'package:iux_flutter/iux_flutter.dart';

import 'catalog_chrome.dart';
import 'catalog_testable.dart';
import 'semantics_readout.dart';

/// Cards and rows: the two containers an application puts its content in.
///
/// Both exist mainly to answer one question — is this thing itself a control,
/// or does it merely contain some? Getting that wrong produces a target inside
/// a target, which is the failure mode both of them are shaped to prevent and
/// which nothing can detect once it has been shipped.
class ContentPanels extends StatelessWidget {
  /// Creates the card and list harness.
  const ContentPanels({super.key, required this.longLabels});

  /// Whether samples use text of translated length.
  final bool longLabels;

  @override
  Widget build(BuildContext context) => Column(
        children: <Widget>[
          _CardPanel(longLabels: longLabels),
          _CardContrastPanel(longLabels: longLabels),
          _ListPanel(longLabels: longLabels),
          const _SelectableListPanel(),
          const _ContainmentPanel(),
        ],
      );
}

/// The words the content harness uses.
abstract final class _Copy {
  static const String shortTitle = 'March invoice';
  static const String longTitle =
      'Zahlungsbestätigung für die Märzrechnung der Nordwind GmbH';
  static const String shortBody =
      'Costa Ltd — due on the 30th. Three attachments.';
  static const String longBody =
      'Nordwind GmbH — fällig am 30., einschließlich dreier Anhänge und der '
      'Zahlungsbestätigung der Buchhaltung.';

  static String title({required bool long}) => long ? longTitle : shortTitle;

  static String body({required bool long}) => long ? longBody : shortBody;
}

class _CardPanel extends StatefulWidget {
  const _CardPanel({required this.longLabels});

  final bool longLabels;

  @override
  State<_CardPanel> createState() => _CardPanelState();
}

class _CardPanelState extends State<_CardPanel> {
  int _opened = 0;

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme type = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);
    final bool long = widget.longLabels;

    Widget body() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _Copy.title(long: long),
              style: type.title.copyWith(color: colors.content.primary),
            ),
            SizedBox(height: geometry.spacingXxs),
            Text(
              _Copy.body(long: long),
              style: type.body.copyWith(color: colors.content.secondary),
            ),
          ],
        );

    return CatalogPanel(
      title: 'A card, and a card that is a button',
      description: 'The first contains controls; the second is one. They are '
          'different constructors rather than a flag, because a card with an '
          'onTap and two buttons inside it is three targets in one rectangle '
          'and nobody can predict which one a tap lands on. Measure the two: '
          'the tappable one is slightly taller, because the focus ring '
          'reserves its gap whether or not it is drawn.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const CatalogSubheading('a card that contains actions'),
          CatalogMeasured(
            checksTarget: false,
            child: IuxCard(
              actions: <Widget>[
                IuxButton(
                  label: 'Send',
                  action: const IuxActionDescriptor.primary(
                    semantics: IuxActionSemantics(label: 'Send the invoice'),
                  ),
                  onActivate: () {},
                ),
                IuxButton(
                  label: 'Later',
                  variant: IuxButtonVariant.outlined,
                  action: const IuxActionDescriptor(
                    role: IuxActionRole.dismiss,
                    semantics: IuxActionSemantics(label: 'Send it later'),
                  ),
                  onActivate: () {},
                ),
              ],
              child: body(),
            ),
          ),
          SizedBox(height: geometry.spacingSm),
          const CatalogSubheading('a card that is itself one control'),
          CatalogTestable(
            what: 'Opens the invoice, and the count under it climbs. Anywhere '
                'on the card answers, because the whole card is the one '
                'control — the card above it is not.',
            child: SemanticsReadout(
              child: IuxCard.tappable(
                semanticLabel: 'Open the March invoice',
                hint: 'Opens the invoice',
                onActivate: () => setState(() => _opened++),
                child: body(),
              ),
            ),
          ),
          CatalogNote('Opened $_opened time(s).'),
          const CatalogNote(
            'The tappable card is announced by the name the caller gave it '
            'and then by the text inside it, as one stop. Measured, the node '
            'reads "Open the March invoice" followed by the title and the '
            'body. That is the opposite of what a button does, deliberately: '
            'a button\'s content only repeats its own label, while a card\'s '
            'content *is* the information, and excluding it would delete the '
            'reference, the status and the amount from the interface of every '
            'screen-reader user while the control went on looking correct. '
            'One stop also means nothing inside may be a control of its own, '
            'which is what the panel below is about.',
          ),
          const CatalogNote(
            'The node declares a focusable state and offers the focus action. '
            'It did not until IUX-038 — no IUX control did — so assistive '
            'technology had no way to move accessibility focus onto any of '
            'them. Read it with the semantics probe above rather than taking '
            'it from here.',
          ),
          SizedBox(height: geometry.spacingSm),
          const CatalogSubheading('grouped, with separators'),
          IuxContentGroup(
            children: <Widget>[
              for (final String label in <String>['March', 'April', 'May'])
                Padding(
                  padding: EdgeInsets.all(geometry.spacingSm),
                  child: Text(
                    '$label invoice',
                    style: type.body.copyWith(color: colors.content.primary),
                  ),
                ),
            ],
          ),
          const CatalogNote(
            'IuxContentGroup builds every child at once and does not clip '
            'them, so a child painting its own background spills past the '
            'group\'s rounded corners. Two hundred rows is a ListView\'s job, '
            'not this one\'s.',
          ),
        ],
      ),
    );
  }
}

class _CardContrastPanel extends StatelessWidget {
  const _CardContrastPanel({required this.longLabels});

  final bool longLabels;

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme type = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);

    return CatalogPanel(
      title: 'A card on a surface it was not measured against',
      description: 'A card is always the raised role, with no way to ask for '
          'another. Put one inside something already raised — a bottom sheet, '
          'a dialog, the overlay role below — and the separation the card '
          'relies on is between two colours nobody compared. Look at the third '
          'one in every profile, and at high contrast in particular.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final (String name, IuxSurfaceRole role)
              in <(String, IuxSurfaceRole)>[
            ('on the page surface', IuxSurfaceRole.base),
            ('on a subtle surface', IuxSurfaceRole.subtle),
            ('on an overlay surface — a sheet', IuxSurfaceRole.overlay),
          ]) ...<Widget>[
            CatalogSubheading(name),
            IuxSurface(
              role: role,
              padding: IuxInsets.compact(context),
              child: IuxCard(
                child: Text(
                  _Copy.title(long: longLabels),
                  style: type.body.copyWith(color: colors.content.primary),
                ),
              ),
            ),
            SizedBox(height: geometry.spacingXs),
          ],
          const CatalogNote(
            'There is no tone or level parameter on IuxCard, and the '
            'documentation says the parameter should be added when there is '
            'something real to measure it against. A sheet is that something, '
            'and it has shipped: the pairing is now reachable and still '
            'unmeasured.',
            finding: true,
          ),
        ],
      ),
    );
  }
}

class _ListPanel extends StatefulWidget {
  const _ListPanel({required this.longLabels});

  final bool longLabels;

  @override
  State<_ListPanel> createState() => _ListPanelState();
}

class _ListPanelState extends State<_ListPanel> {
  int _opened = 0;
  int _archived = 0;

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final bool long = widget.longLabels;

    return CatalogPanel(
      title: 'Rows',
      description: 'A plain row, a row that is a control, and a row that is a '
          'control with a second control beside it. The last is where a mistap '
          'costs something: the two targets touch, against the eight-pixel '
          'floor every other pair of targets in this library keeps. Raise the '
          'text scale and check that the trailing control keeps its own floor '
          'while the row grows around it.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CatalogTestable(
            what: 'The second and third rows open an invoice and the count '
                'below climbs; the archive control beside the third is its own '
                'target and reports separately. The first row is not a control '
                'and answers nothing.',
            child: IuxListGroup(
              children: <Widget>[
                IuxListItem(
                  title: _Copy.title(long: long),
                  subtitle: _Copy.body(long: long),
                  trailingText: '€1,240.00',
                  leading: const IuxIcon(
                    icon: Icons.description_outlined,
                    description: IuxImageDescription.decorative(),
                  ),
                ),
                const IuxListSeparator(),
                IuxListItem.tappable(
                  title: long ? 'Aprilrechnung öffnen' : 'April invoice',
                  subtitle: 'Costa Ltd — paid',
                  trailingText: '€980.00',
                  hint: 'Opens the invoice',
                  onActivate: () => setState(() => _opened++),
                ),
                const IuxListSeparator(),
                IuxListItem.tappable(
                  title: long ? 'Mairechnung öffnen' : 'May invoice',
                  subtitle: 'Nordwind GmbH — overdue',
                  hint: 'Opens the invoice',
                  onActivate: () => setState(() => _opened++),
                  trailingAction: IuxIconButton(
                    icon: Icons.archive_outlined,
                    action: const IuxActionDescriptor(
                      role: IuxActionRole.custom,
                      semantics:
                          IuxActionSemantics(label: 'Archive the May invoice'),
                    ),
                    onActivate: () => setState(() => _archived++),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: geometry.spacingXs),
          CatalogRows(<(String, String)>[
            ('Rows opened', '$_opened'),
            ('Archived from the trailing control', '$_archived'),
          ]),
          const CatalogNote(
            'The trailing control is its own target and its own focus stop, '
            'beside the row rather than inside it. A control placed inside a '
            'tappable row would be a second answer to one tap; the debug guard '
            'throws with the offending widget named rather than letting it '
            'ship.',
          ),
          const CatalogNote(
            'Rows touch. IUX keeps eight pixels between adjacent targets '
            'everywhere else, and a list is the one place it does not, because '
            'gaps between rows read as groups that are not there. It is a '
            'judgement, argued in the documentation and context dependent — '
            'and a mistap between two rows opens the wrong invoice.',
          ),
          const CatalogNote(
            'There is no IuxList. IuxListGroup builds every child eagerly, so '
            'a group of two hundred rows builds two hundred rows; a real list '
            'reaches for ListView.separated directly and IUX has no say over '
            'its physics.',
          ),
        ],
      ),
    );
  }
}

class _SelectableListPanel extends StatefulWidget {
  const _SelectableListPanel();

  @override
  State<_SelectableListPanel> createState() => _SelectableListPanelState();
}

class _SelectableListPanelState extends State<_SelectableListPanel> {
  final Set<String> _chosen = <String>{'April invoice'};

  static const List<String> _rows = <String>[
    'March invoice',
    'April invoice',
    'May invoice',
  ];

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);

    return CatalogPanel(
      title: 'Rows the user chooses',
      description: 'A selectable row is a checkbox wearing a list row, and it '
          'is announced as one. The mark is a second implementation of the '
          'checkbox indicator that resolves the same tokens, so the two cannot '
          'drift in size or colour — but there are two of them, and only one '
          'is tested as a checkbox.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CatalogTestable(
            what: 'Chooses and unchooses a row. The count below changes, and '
                'so does the word under the name — the row is a checkbox and '
                'is announced as one.',
            child: IuxListGroup(
              children: <Widget>[
                for (final String row in _rows)
                  IuxListItem.selectable(
                    title: row,
                    subtitle: _chosen.contains(row) ? 'Selected' : null,
                    selected: _chosen.contains(row)
                        ? IuxSelectionState.selected
                        : IuxSelectionState.unselected,
                    onSelectedChanged: (bool selected) => setState(() {
                      if (selected) {
                        _chosen.add(row);
                      } else {
                        _chosen.remove(row);
                      }
                    }),
                  ),
              ],
            ),
          ),
          SizedBox(height: geometry.spacingXs),
          CatalogRows(<(String, String)>[
            ('Chosen', '${_chosen.length} of ${_rows.length}'),
          ]),
          const CatalogNote(
            'A row cannot be partly chosen: the constructor asserts against '
            'it. A row stands for one item, there is nowhere on it to draw '
            '"partly", and a user who saw one could not predict what tapping '
            'it would do. The summary of a set is a checkbox, which does have '
            'that state.',
          ),
          const CatalogNote(
            'There is no long-press selection mode, no swipe action and no '
            'reordering. Each needs an accessible equivalent that does not '
            'depend on a gesture, and shipping the gesture without the '
            'equivalent would be a feature only some users can reach.',
          ),
        ],
      ),
    );
  }
}

class _ContainmentPanel extends StatelessWidget {
  const _ContainmentPanel();

  @override
  Widget build(BuildContext context) => const CatalogPanel(
        title: 'What a container refuses to hold',
        description: 'Two of these throw in debug with the offending widget '
            'named, and the rest are assertions. None of them exists in a '
            'release build, which is where a nested target reaches a user.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CatalogRows(<(String, String)>[
              ('a control inside a tappable card', 'two answers to one tap'),
              ('a control inside a tappable row', 'same, in a row'),
              ('a row with a partial selection', 'a row is one item'),
              ('an untitled row', 'read as whatever is left in it'),
              ('empty supporting text', 'reserves a line, says nothing'),
              ('an empty trailing value', 'space for a number never sent'),
              ('a card with both actions and an onTap', 'not expressible'),
            ]),
            CatalogNote(
              'The nested-control guard is a debug heuristic, not a guarantee: '
              'it recognises the widgets IUX knows about. A caller\'s own '
              'GestureDetector inside a tappable card passes it and produces '
              'exactly the failure it exists to catch.',
            ),
            CatalogNote(
              'There is no disabled row and no disabled card, by '
              'construction. A row that occupies a target and answers nothing '
              'is a target that lies; the row that cannot be used is the row '
              'that should not be tappable.',
            ),
          ],
        ),
      );
}
