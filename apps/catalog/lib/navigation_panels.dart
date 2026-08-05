import 'package:flutter/material.dart';
import 'package:iux_flutter/iux_flutter.dart';

import 'catalog_chrome.dart';
import 'catalog_overlays.dart';
import 'catalog_testable.dart';

/// Getting between the top-level places of an application.
///
/// Every widget here reports a choice and navigates nothing: the selected
/// index comes in and a callback goes out, because a bar that pushed its own
/// routes would own the back stack, and the back stack is the one thing an
/// application cannot delegate.
///
/// The failures worth looking for are all about size. A bar of five
/// destinations is five labels that must not be shortened, and enlarging text
/// makes it taller rather than narrower — so the panels here measure instead
/// of describing, and the numbers are the point.
class NavigationPanels extends StatelessWidget {
  /// Creates the navigation harness.
  const NavigationPanels({
    super.key,
    required this.longLabels,
    required this.overlays,
  });

  /// Whether samples use labels of translated length.
  final bool longLabels;

  /// The page's overlay owner, which the drawer has to be handed to.
  final CatalogOverlays overlays;

  @override
  Widget build(BuildContext context) => Column(
        children: <Widget>[
          _AppBarPanel(longLabels: longLabels),
          _BottomNavigationPanel(longLabels: longLabels),
          _RailPanel(longLabels: longLabels),
          _AdaptivePanel(longLabels: longLabels),
          _DrawerPanel(longLabels: longLabels, overlays: overlays),
          _TabsPanel(longLabels: longLabels),
          const _NavigationRefusalPanel(),
        ],
      );
}

/// The destinations the harness navigates between.
///
/// Five, because five is the maximum the bar accepts and therefore the case
/// that fails first. Their names are deliberately not one syllable each: a bar
/// checked with "Home / Search / You" has been checked against the easiest
/// input it will ever receive.
List<IuxNavigationDestination> _destinations({
  required bool long,
  required int count,
}) {
  final List<(String, String, IconData)> all = <(String, String, IconData)>[
    ('Invoices', 'Rechnungen und Gutschriften', Icons.receipt_long_outlined),
    ('Payments', 'Zahlungseingänge', Icons.payments_outlined),
    ('Customers', 'Geschäftspartner', Icons.people_outline),
    ('Reports', 'Auswertungen', Icons.insert_chart_outlined),
    ('Settings', 'Kontoeinstellungen', Icons.settings_outlined),
  ];

  return <IuxNavigationDestination>[
    for (final (String short, String longName, IconData icon)
        in all.take(count))
      IuxNavigationDestination(
        label: long ? longName : short,
        icon: icon,
        badge: short == 'Payments'
            ? const IuxBadge.count(count: '3', label: '3 unread payments')
            : null,
      ),
  ];
}

class _AppBarPanel extends StatefulWidget {
  const _AppBarPanel({required this.longLabels});

  final bool longLabels;

  @override
  State<_AppBarPanel> createState() => _AppBarPanelState();
}

class _AppBarPanelState extends State<_AppBarPanel> {
  int _actionCount = 2;
  int _pressed = 0;
  String _leading = 'back';

  IuxAppBarLeading? get _leadingControl => switch (_leading) {
        'back' => IuxAppBarLeading.back(
            label: 'Back',
            onActivate: () => setState(() => _pressed++),
          ),
        'close' => IuxAppBarLeading.close(
            label: 'Close',
            hint: 'Leaves without saving',
            onActivate: () => setState(() => _pressed++),
          ),
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);

    final List<IuxIconButton> actions = <IuxIconButton>[
      for (final (IconData icon, String name) in <(IconData, String)>[
        (Icons.search, 'Search the invoices'),
        (Icons.filter_list, 'Filter the invoices'),
        (Icons.more_vert, 'More invoice options'),
      ].take(_actionCount))
        IuxIconButton(
          icon: icon,
          action: IuxActionDescriptor(
            semantics: IuxActionSemantics(label: name),
          ),
          onActivate: () => setState(() => _pressed++),
        ),
    ];

    final Widget bar = CatalogMeasured(
      checksTarget: false,
      child: IuxAppBar(
        title: widget.longLabels
            ? 'Zahlungsbestätigungen und offene Rechnungen'
            : 'Invoices',
        leading: _leadingControl,
        actions: actions,
      ),
    );

    return CatalogPanel(
      title: 'The bar at the top',
      description: 'A name for the screen, one way back, and at most three '
          'controls. The fourth is refused rather than folded into a menu — a '
          'menu is a surface with its own focus and dismissal rules, and half '
          'of one is worse than none. Raise the action count and the text '
          'scale together and watch the title wrap rather than push the '
          'controls off the edge.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CatalogChoice<String>(
            label: 'Leading',
            value: _leading,
            values: const <String>['back', 'close', 'none'],
            naming: (String value) => value,
            onChanged: (String value) => setState(() => _leading = value),
          ),
          CatalogChoice<int>(
            label: 'Actions',
            value: _actionCount,
            values: const <int>[0, 1, 2, 3],
            naming: (int value) => '$value',
            onChanged: (int value) => setState(() => _actionCount = value),
          ),
          SizedBox(height: geometry.spacingXs),
          // Framed only while the bar has a control in it. Set the leading to
          // none and the actions to zero and there is nothing left to press —
          // a frame saying "Test it" around a title is the confusion this
          // frame exists to remove, arrived at from the other direction.
          if (_leading == 'none' && _actionCount == 0)
            bar
          else
            CatalogTestable(
              what: 'The leading control and each action answer a press — the '
                  'count below climbs. None of them navigates: the bar reports '
                  'and the application decides.',
              child: bar,
            ),
          SizedBox(height: geometry.spacingXs),
          CatalogRows(<(String, String)>[
            ('Controls pressed', '$_pressed'),
            ('Maximum actions', '$kIuxAppBarMaximumActions'),
          ]),
          const CatalogNote(
            'The back and close constructors are separate because they are '
            'different promises. Back returns to where the user came from; '
            'close abandons what they were doing. One arrow that meant either '
            'depending on the screen is how a user loses work they thought '
            'they were stepping back from.',
          ),
          const CatalogNote(
            'The title takes the row when it fits and a line of its own when '
            'it does not. The threshold is twelve characters at half an em '
            'each — the same crude conversion the layout package uses, stated '
            'as a hypothesis rather than a measurement. It is wrong for CJK '
            'and for monospace, in the generous direction: the title keeps the '
            'shared row slightly more often than it should.',
          ),
          const CatalogNote(
            'At 300% with a long title and no controls, the bar alone can take '
            'most of a small screen. Nothing clips, which is the guarantee — '
            'whether a title that long is a good title is not the component\'s '
            'decision to make.',
          ),
          const CatalogNote(
            'This panel used to record that docs/components/app-bar.md listed '
            '"Not exported from the barrel" as a limit while the export sat at '
            'iux_flutter.dart line 16. The page no longer says it. The export '
            'is still on line 16, and the limits that remain on that page — no '
            'overflow menu, no subtitle, no PreferredSizeWidget — are the ones '
            'this panel demonstrates.',
          ),
        ],
      ),
    );
  }
}

class _BottomNavigationPanel extends StatefulWidget {
  const _BottomNavigationPanel({required this.longLabels});

  final bool longLabels;

  @override
  State<_BottomNavigationPanel> createState() => _BottomNavigationPanelState();
}

class _BottomNavigationPanelState extends State<_BottomNavigationPanel> {
  int _count = 5;
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final List<IuxNavigationDestination> destinations =
        _destinations(long: widget.longLabels, count: _count);

    return CatalogPanel(
      title: 'The bar at the bottom, and what it costs in height',
      description: 'Three destinations minimum, five maximum, and no way to '
          'disable one. The measurement under the bar is the panel: this '
          'component grows *taller* as text grows, because a name is never '
          'shortened, and five long names at 300% is the arrangement that '
          'stops fitting. Set the count to five, turn long labels on, go to '
          '300%, and read the number.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CatalogChoice<int>(
            label: 'Destinations',
            value: _count,
            values: const <int>[3, 4, 5],
            naming: (int value) => '$value',
            onChanged: (int value) => setState(() {
              _count = value;
              if (_selected >= value) _selected = value - 1;
            }),
          ),
          SizedBox(height: geometry.spacingXs),
          CatalogTestable(
            what: 'Moves the selection, and the row underneath says which '
                'destination is showing. Nothing here is disabled — there is '
                'no such thing as a disabled destination.',
            child: CatalogMeasured(
              checksTarget: false,
              child: IuxBottomNavigation(
                label: 'Main sections',
                destinations: destinations,
                selectedIndex: _selected,
                onDestinationSelected: (int value) =>
                    setState(() => _selected = value),
              ),
            ),
          ),
          SizedBox(height: geometry.spacingXs),
          CatalogRows(<(String, String)>[
            ('Showing', destinations[_selected].label),
            ('Destinations', '$_count'),
          ]),
          const CatalogNote(
            'The five destinations shown here take 408 pixels of height at '
            '200% text on a 320-wide surface. Three take 264. Measured on the '
            'list this panel actually builds, badge included — the same five '
            'without the badge are 384 and 240, which is the number the '
            'app-bar arithmetic in the evidence register uses. An application '
            'that expects enlarged text should ship three, and that is a '
            'design decision the component cannot make — it can only refuse to '
            'hide the cost.',
          ),
          const CatalogNote(
            'Above roughly 250% with five destinations on a short screen the '
            'bar cannot fit at all. It clamps to the space available and '
            'scrolls sideways. That is a degradation and it is stated as one: '
            'a destination the user has to scroll to may not be found, and a '
            'destination that is not rendered certainly will not be.',
          ),
          const CatalogNote(
            'The arrangement switches on text scale rather than on width, so a '
            'very narrow screen at 100% keeps the row and lets the names wrap. '
            'Below 320 pixels the guarantee is arithmetically impossible — '
            'five targets of 48 need 240 — and nothing here rescues it.',
          ),
          const CatalogNote(
            'The badge sits under the name rather than over the glyph, in '
            'reading order, which is why enlarging text moves it instead of '
            'clipping it.',
          ),
        ],
      ),
    );
  }
}

class _RailPanel extends StatefulWidget {
  const _RailPanel({required this.longLabels});

  final bool longLabels;

  @override
  State<_RailPanel> createState() => _RailPanelState();
}

class _RailPanelState extends State<_RailPanel> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme type = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);
    final List<IuxNavigationDestination> destinations =
        _destinations(long: widget.longLabels, count: 5);

    return CatalogPanel(
      title: 'The rail, for a window wide enough to spare the space',
      description: 'The same destinations turned on their side. It is given a '
          'fixed 360-tall box here because a rail scrolls when its '
          'destinations no longer fit, and a rail inside this catalog\'s own '
          'scroll view would have nothing to scroll against. Raise the text '
          'scale and watch the rail start scrolling inside its box — and watch '
          'the two numbers underneath cross over.',
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double asked =
              IuxNavigationRail.widthFor(context, destinations);
          final double available = constraints.maxWidth;
          // The content beside the rail is never allowed below the width the
          // adaptive component itself insists on before it will choose a rail
          // at all. Without this the sample overflows: the rail is not
          // flexible, so a Row hands it its full width and clips whatever is
          // left. It is the caller's arrangement that must give, not the rail.
          final double needed = asked + 320;
          final bool fits = needed <= available;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CatalogTestable(
                what: 'Moves the selection, and the panel beside it follows. '
                    'When the rail no longer fits, the box scrolls sideways — '
                    'that scroll is the harness\'s, not the component\'s.',
                child: SizedBox(
                  height: 360,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: fits ? available : needed,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          IuxNavigationRail(
                            label: 'Main sections',
                            destinations: destinations,
                            selectedIndex: _selected,
                            onDestinationSelected: (int value) =>
                                setState(() => _selected = value),
                          ),
                          Expanded(
                            child: IuxSurface(
                              role: IuxSurfaceRole.subtle,
                              padding: IuxInsets.surface(context),
                              child: Text(
                                destinations[_selected].label,
                                style: type.body
                                    .copyWith(color: colors.content.primary),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: geometry.spacingXs),
              CatalogRows(<(String, String)>[
                ('Width this rail asked for', asked.toStringAsFixed(0)),
                ('Width available here', available.toStringAsFixed(0)),
                (
                  'Rail plus a usable content column',
                  '${needed.toStringAsFixed(0)}'
                      '${fits ? '' : ' — more than there is'}'
                ),
                ('Layout class in force', IuxBreakpoints.of(context).name),
              ]),
              if (!fits)
                const CatalogNote(
                  'The rail and a readable column no longer fit side by side, '
                  'so this sample has grown a horizontal scroll of its own to '
                  'stay visible. That scroll is the harness\'s, not the '
                  'component\'s: a Row hands the rail its full asked-for width '
                  'because a rail is not flexible, and whatever is beside it '
                  'is then clipped. Measured at 300%: a hand-placed rail in a '
                  'Row on a 360-wide surface reports a debug overflow of 36 '
                  'pixels; the same arrangement on an 800-wide one reports '
                  'nothing, because 800 is wide enough for the 396 the rail '
                  'asks for. IuxAdaptiveNavigation now refuses a rail that '
                  'will not fit at all. A rail placed by hand gets no such '
                  'refusal — and cannot: a Row lays out a non-flexible child '
                  'against an infinite width, so the rail is never told the '
                  'window it is in and has nothing to compare. What it does '
                  'get is Flutter\'s own report, and the overflow is exactly '
                  'the number of pixels the rail was short by — measured at '
                  '100%, 200% and 300%. In a bounded box narrower than it '
                  'asked for there is no report at all: the rail takes what it '
                  'is given, the names wrap, and every destination still '
                  'renders.',
                  finding: true,
                ),
              const CatalogNote(
                'The width is computed from the widest name at the text size '
                'in force, so it is a number rather than a constant. Enlarging '
                'text widens the rail, which is the trade a rail makes against '
                'the bar: the bar spends height, the rail spends width.',
              ),
              const CatalogNote(
                'widthFor ignores badges and display insets. A badge is '
                'narrower than any realistic name so it has never driven the '
                'width, and the inset omission makes the adaptive budget '
                'optimistic by the width of a camera cutout — tens of pixels '
                'against the hundreds to spare on any window where a rail is '
                'chosen at all.',
              ),
              const CatalogNote(
                'On a 320 × 640 phone at 300% neither arrangement fits: the '
                'bar takes the window and the content is laid out at zero '
                'height, and the rail would need 394 of 320 pixels. That is a '
                'documented degradation inherited from IUX-024 and it is not '
                'solved here.',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AdaptivePanel extends StatefulWidget {
  const _AdaptivePanel({required this.longLabels});

  final bool longLabels;

  @override
  State<_AdaptivePanel> createState() => _AdaptivePanelState();
}

class _AdaptivePanelState extends State<_AdaptivePanel> {
  /// The height of the demonstration box.
  ///
  /// Shorter than the narrowest width on offer, so every option is a landscape
  /// window — the only shape in which a rail is considered at all.
  static const double _boxHeight = 320;

  int _selected = 0;
  double _width = 360;

  /// Whether the rail would be wider than the box it was offered.
  ///
  /// No longer a prediction of an overflow: the component now weighs this
  /// itself and takes the bar instead. It is kept because it is the condition
  /// the note below is about, and reading it off the same public `widthFor`
  /// the component uses is what makes the note checkable on screen.
  bool _railWouldNotFit(
    BuildContext context,
    List<IuxNavigationDestination> destinations,
  ) =>
      _width >= _boxHeight &&
      IuxNavigationRail.widthFor(context, destinations) > _width;

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme type = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);
    final List<IuxNavigationDestination> destinations =
        _destinations(long: widget.longLabels, count: 3);

    return CatalogPanel(
      title: 'Letting the window decide',
      description: 'One widget that is the bar on a phone and the rail on a '
          'tablet, with no parameter to force either — because a parameter to '
          'force one is a parameter somebody sets once and never revisits. The '
          'width below is a box, not the window: squeeze it and watch the '
          'arrangement change without anything else being touched.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CatalogChoice<double>(
            label: 'Box width',
            value: _width,
            values: const <double>[360, 700, 1000],
            naming: (double value) => value.toStringAsFixed(0),
            onChanged: (double value) => setState(() => _width = value),
          ),
          SizedBox(height: geometry.spacingXs),
          // Both bounded. The rail is only chosen when the box has a width and
          // a height to spend.
          //
          // This sample used to be withheld whenever the rail would be wider
          // than the box, because building it produced a debug overflow that
          // took the harness down. It is built at every size now: the
          // component asks whether the rail fits before it asks how much is
          // left over, so the case that used to overflow renders the bar.
          CatalogTestable(
            what: 'Moves the selection, and the panel inside the box follows. '
                'Change the box width above and the same widget answers as the '
                'bar or as the rail, with nothing else touched.',
            child: SizedBox(
              width: _width,
              height: _boxHeight,
              child: IuxAdaptiveNavigation(
                label: 'Main sections',
                destinations: destinations,
                selectedIndex: _selected,
                onDestinationSelected: (int value) =>
                    setState(() => _selected = value),
                child: IuxSurface(
                  role: IuxSurfaceRole.subtle,
                  padding: IuxInsets.surface(context),
                  child: Text(
                    destinations[_selected].label,
                    style: type.body.copyWith(color: colors.content.primary),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: geometry.spacingXs),
          CatalogRows(<(String, String)>[
            (
              'Rail would ask for',
              IuxNavigationRail.widthFor(context, destinations)
                  .toStringAsFixed(0)
            ),
            ('Box', '${_width.toStringAsFixed(0)} × $_boxHeight'),
            (
              'Landscape, so a rail is on the table',
              _width >= _boxHeight ? 'yes' : 'no'
            ),
          ]),
          if (_railWouldNotFit(context, destinations))
            const CatalogNote(
              'The rail is wider than this box, and the component has taken '
              'the bar. That is the case the rule used to miss. On a landscape '
              'window past the stacked text threshold it picked the rail even '
              'when the content budget failed — the argument being that the '
              'bar there is a full-width list leaving zero content while the '
              'rail at least leaves some — but the reasoning weighed how much '
              'was *left over* and never asked whether the rail fitted at all. '
              'At 300% in a 360 × 320 box the leftover was negative and the '
              'Row overflowed by 36 pixels: a debug error instead of the '
              'degradation the documentation promises. Measured again at the '
              'same size, the bar is chosen and nothing is thrown. What is '
              'left is the degradation itself, which is real: read the row '
              'above and see how little height the content keeps.',
            ),
          const CatalogNote(
            'The decision is made from the box, not from the device and not '
            'from the layout class: the same widget in a split view gets the '
            'bar while the tablet it is running on would have earned a rail. '
            'That is right — the user sees the box, not the hardware.',
          ),
          const CatalogNote(
            'An unbounded box is now refused by name, which the documentation '
            'claimed from IUX-025 until IUX-042 struck the claim. Measured '
            'before the fix: put this inside a SingleChildScrollView and the '
            'private '
            'width check returned false for the unbounded height, so the '
            'widget chose the bar — the phone arrangement on a tablet — and '
            'Flutter then threw "RenderFlex children have non-zero flex but '
            'incoming height constraints are unbounded" from the component\'s '
            'own Column, 27 exceptions in all. Loud, but by accident and in '
            'somebody else\'s words: nothing in it said navigation, said rail, '
            'or said what to do. The assertion says all three. It is an '
            'assert, so a release build still falls through to the bar.',
          ),
        ],
      ),
    );
  }
}

class _DrawerPanel extends StatefulWidget {
  const _DrawerPanel({required this.longLabels, required this.overlays});

  final bool longLabels;
  final CatalogOverlays overlays;

  @override
  State<_DrawerPanel> createState() => _DrawerPanelState();
}

class _DrawerPanelState extends State<_DrawerPanel> {
  /// Kept on the page, not here.
  ///
  /// Opening the drawer rebuilds the page's subtree — IUX-OVERLAY-001 — and
  /// disposes this panel when it had been scrolled to. A selection held in
  /// this `State` would be written by a callback firing on a dead widget, and
  /// read back from a fresh one that had reset it to zero.
  static int _selected = 0;

  /// Whether the dismissal is given a name long enough to overflow the header.
  ///
  /// Off by default, because on it renders a debug overflow and the harness
  /// has to stay usable. It is a switch rather than a sentence because the
  /// failure is worth seeing: see the finding below.
  bool _longDismiss = false;

  void _open() {
    final CatalogOverlays overlays = widget.overlays;

    final IuxNavigationDrawer value = IuxNavigationDrawer(
      title: 'Invoicing',
      dismissLabel: _longDismiss ? 'Close the menu' : 'Close',
      onDismiss: overlays.closeModal,
      destinations: _destinations(long: widget.longLabels, count: 5),
      selectedIndex: _selected,
      onDestinationSelected: (int index) {
        _selected = index;
        overlays.closeModal();
      },
    );

    overlays.showDrawer(() => value);
  }

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final List<IuxNavigationDestination> destinations =
        _destinations(long: widget.longLabels, count: 5);

    return CatalogPanel(
      title: 'The drawer, which the page has to place',
      description: 'The only navigation component that is a modal, so the only '
          'one the page owns rather than lays out. It is handed to the '
          'catalog\'s IuxModalLayer at page level: a section that built its '
          'own Stack would be deciding layering, which is how two modals end '
          'up open at once with the way out of neither visible.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CatalogChoice<bool>(
            label: 'Dismiss label',
            value: _longDismiss,
            values: const <bool>[false, true],
            naming: (bool value) =>
                value ? '"Close the menu" — used to overflow' : '"Close"',
            onChanged: (bool value) => setState(() => _longDismiss = value),
          ),
          SizedBox(height: geometry.spacingXs),
          CatalogTestable(
            what: 'Opens the menu over the whole page. Choosing a destination '
                'closes it and changes the row below — and the page behind it '
                'loses its scroll position on the way, which is the finding '
                'under this panel.',
            child: IuxButton(
              label: 'Open the menu',
              action: const IuxActionDescriptor(
                role: IuxActionRole.navigate,
                semantics: IuxActionSemantics(
                  label: 'Open the navigation menu',
                  hint: 'Covers the page until it is closed',
                ),
              ),
              onActivate: _open,
            ),
          ),
          SizedBox(height: geometry.spacingXs),
          CatalogRows(<(String, String)>[
            ('Showing', destinations[_selected].label),
          ]),
          const CatalogNote(
            'It takes any number of destinations where the bar takes three to '
            'five, because a drawer scrolls and a bar cannot. That is the '
            'reason to reach for one, and it is also the reason a drawer is '
            'the worst of the three for discovery: everything in it is behind '
            'a control that says nothing about what is inside.',
          ),
          const CatalogNote(
            'Opening it rebuilds the page beneath, so a scrolled list behind '
            'it loses its position — IUX-OVERLAY-001, accepted rather than '
            'fixed because the alternative is worse. Scroll this catalog down '
            'a little, open the menu, close it, and watch where you land.',
          ),
          const CatalogNote(
            'The system back button does not close it here. The drawer is the '
            'only overlay in the library that installs a PopScope of its own; '
            'IuxDialog and IuxBottomSheet leave the back button to the caller '
            'and name the two lines it needs in their own documentation. So '
            'three overlays answer Android\'s most practised gesture two '
            'different ways, and which one a user gets depends on which '
            'happens to be open.',
            finding: true,
          ),
          const CatalogNote(
            'Set the dismiss label to the longer one and open the drawer. The '
            'header row overflows by 9.5 pixels — measured, at 100% text, on '
            'an 800-wide surface and again on a 1200-wide one, with identical '
            'geometry in both. The panel is capped at the width the names need '
            'whatever the screen, so a wider screen never helps; the header is '
            'Row([Expanded(title), gap, dismiss]) and once the dismissal\'s '
            'intrinsic width plus the gap exceeds the content width the '
            'Expanded is handed negative space. "Close the menu" is fourteen '
            'characters and an entirely ordinary label. The row stacks '
            'instead of sharing a line only past roughly 130% text, so '
            'enlarging the text fixes it and leaving it alone does not — which '
            'is the opposite of every other size failure in this library.',
            finding: true,
          ),
          const CatalogNote(
            'The slot this panel is built on is real and the page that once '
            'denied it agrees now: docs/components/navigation-drawer.md marks '
            '"No IuxModalLayer slot" as closed. IuxModalLayer takes dialog, '
            'sheet and drawer and asserts that at most one is filled, which is '
            'what makes two-modals-at-once unrepresentable rather than merely '
            'discouraged.',
          ),
        ],
      ),
    );
  }
}

class _TabsPanel extends StatefulWidget {
  const _TabsPanel({required this.longLabels});

  final bool longLabels;

  @override
  State<_TabsPanel> createState() => _TabsPanelState();
}

class _TabsPanelState extends State<_TabsPanel> {
  int _count = 3;
  int _selected = 0;

  static const List<String> _short = <String>[
    'All',
    'Unpaid',
    'Overdue',
    'Paid',
    'Draft',
  ];

  static const List<String> _long = <String>[
    'Alle Rechnungen',
    'Offene Zahlungen',
    'Überfällige Posten',
    'Bezahlte Rechnungen',
    'Entwürfe und Vorlagen',
  ];

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme type = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);
    final List<String> tabs =
        (widget.longLabels ? _long : _short).take(_count).toList();

    return CatalogPanel(
      title: 'Tabs, which are a filter and not a place',
      description: 'Two to five names over one panel the caller owns. The '
          'strip wraps into rows rather than scrolling sideways or '
          'ellipsising, so the failure to look for is height: five long names '
          'at 300% is five full-width rows, and the panel starts below all of '
          'them.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CatalogChoice<int>(
            label: 'Tabs',
            value: _count,
            values: const <int>[2, 3, 4, 5],
            naming: (int value) => '$value',
            onChanged: (int value) => setState(() {
              _count = value;
              if (_selected >= value) _selected = value - 1;
            }),
          ),
          SizedBox(height: geometry.spacingXs),
          CatalogTestable(
            what: 'Changes the filter, and the panel underneath follows the '
                'name. A tab is a filter rather than a place: nothing '
                'navigates and nothing swipes.',
            child: CatalogMeasured(
              checksTarget: false,
              child: IuxTabs(
                label: 'Filter the invoices',
                tabs: tabs,
                selectedIndex: _selected,
                onTabSelected: (int value) => setState(() => _selected = value),
              ),
            ),
          ),
          SizedBox(height: geometry.spacingXs),
          IuxSurface(
            role: IuxSurfaceRole.subtle,
            bordered: true,
            padding: IuxInsets.surface(context),
            child: Text(
              'The panel for "${tabs[_selected]}" — the caller builds this, '
              'and nothing swipes between panels.',
              style: type.body.copyWith(color: colors.content.primary),
            ),
          ),
          const CatalogNote(
            'A word wider than the strip breaks across lines. It is never '
            'clipped and never ellipsised, so at 300% a long German compound '
            'breaks mid-word inside its own full-width row. Nothing rescues '
            'that except a shorter word, and saying so is more useful than an '
            'ellipsis that hides which tab the user is looking at.',
          ),
          const CatalogNote(
            'No roving focus: five tabs are five Tab stops rather than one '
            'stop with arrow keys inside it. The same trade the radio group '
            'makes — more presses, and no tab unreachable.',
          ),
          const CatalogNote(
            'No glyph and no badge on a tab, and adding either later means '
            'changing List<String> to a value type, which is a breaking '
            'change. That is the argument for not speculating one in now, and '
            'it is also the reason this parameter will be the expensive one to '
            'change if the need turns out to be real.',
          ),
        ],
      ),
    );
  }
}

class _NavigationRefusalPanel extends StatelessWidget {
  const _NavigationRefusalPanel();

  @override
  Widget build(BuildContext context) => const CatalogPanel(
        title: 'What navigation refuses',
        description: 'Assertions, so a release build has none of them. The '
            'app bar\'s is in build rather than in the constructor, so that '
            'the widget can stay const — it fires on the first frame instead '
            'of at construction, which is later but still before a user.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CatalogRows(<(String, String)>[
              ('a fourth app-bar action', 'no overflow menu to put it in'),
              ('two destinations in a bar', 'not a set worth a bar'),
              ('six destinations in a bar', 'six targets do not fit'),
              ('two destinations with one name', 'indistinguishable spoken'),
              ('one tab', 'a filter with nothing to filter against'),
              ('six tabs', 'six rows at a large text scale'),
              ('an empty tab name', 'a target announcing nothing'),
              ('a selected index outside the list', 'nothing is selected'),
              ('two modals in one layer', 'the way out of neither is visible'),
              ('three dialog actions', 'a decision, not a question'),
            ]),
            CatalogNote(
              'There is no disabled destination anywhere in this family, and '
              'no loading or error state on a bar. A destination that occupies '
              'a target and answers nothing is a target that lies; a section '
              'the user may not reach should not be in the bar at all.',
            ),
            CatalogNote(
              'None of these components navigates. Each reports an index and '
              'the application does the rest, which is why none of them '
              'restores a per-section scroll position or back stack — and why '
              'an application that forgets to is a bar that always returns the '
              'user to the top of a list they had read half of.',
            ),
          ],
        ),
      );
}
