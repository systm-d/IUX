import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';
// Not in the barrel yet: the team lead owns that file. Imported from source so
// the pattern can be measured before the two export lines land.

/// What the list is called. Published as a heading.
const String _kListLabel = 'Visits on this round';

/// What activating a row does, worded as an outcome.
const String _kPlaceHint = 'centres the map on this visit';

/// The accessible name of the control that moves the camera closer.
const String _kZoomIn = 'Zoom in';

/// The accessible name of the control that moves the camera away.
const String _kZoomOut = 'Zoom out';

/// What a screen reader is told when a place becomes the current one.
///
/// Worded as a name rather than as an event, which is what
/// [IuxMapSelection.announcement] asks for: it has to read correctly as an
/// announcement *and* as the row's accessible name.
const String _kSelectionOfThree = 'Stop 3 of 8, Site 3, selected';

/// The same, for a different place, so a change can be measured.
const String _kSelectionOfFive = 'Stop 5 of 8, Site 5, selected';

/// What the caller's map contributes to the semantics tree before IUX removes
/// it.
///
/// A real `GoogleMap` contributes a platform view and whatever nodes the SDK
/// puts under it. This one contributes a single labelled node, which is the
/// easiest possible case for the pattern to leave alone — so finding it absent
/// is evidence rather than an accident of an empty subtree.
const String _kTileLabel = 'Platform map view';

/// Identifies the region the caller's map is given, so its height can be
/// measured.
const Key _kMapKey = Key('the caller map');

/// The two files this pattern is, and the only two it may be.
const List<String> _kSources = <String>[
  'lib/src/patterns/map/iux_place_map.dart',
  'lib/src/patterns/map/iux_place_map_model.dart',
];

/// [path] with its documentation and comments removed.
///
/// So prose about a rule is not mistaken for a violation of it. Both tests
/// below need it, and the focus one needs it most: this pattern's
/// documentation says in so many words that there is no `IuxFocus.request`
/// here, and a naive substring search reports that sentence as the call it
/// promises does not exist.
String _code(String path) {
  final StringBuffer buffer = StringBuffer();
  for (String line in File(path).readAsLinesSync()) {
    final String trimmed = line.trimLeft();
    if (trimmed.startsWith('//')) continue;
    final int marker = line.indexOf('//');
    if (marker >= 0) line = line.substring(0, marker);
    buffer.writeln(line);
  }
  return buffer.toString();
}

/// Stands in for the caller's map widget.
class _FakeMap extends StatelessWidget {
  const _FakeMap();

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: _kTileLabel,
        child: const SizedBox.expand(key: _kMapKey),
      );
}

/// A round of [count] places, each findable and orderable.
List<IuxPlace> round(int count) => <IuxPlace>[
      for (int i = 1; i <= count; i++)
        IuxPlace(
          id: 'WO-$i',
          ordinal: '$i',
          name: 'Site $i',
          detail: '$i Mill Lane, Salford',
          distance: '$i.2 km',
        ),
    ];

void main() {
  /// Puts one place map on a screen of the size and text scale given.
  ///
  /// 320x640 by default: the smallest screen this library targets, and the one
  /// where a map and a list competing for the same height stops being
  /// hypothetical.
  Future<void> host(
    WidgetTester tester,
    Widget region, {
    Size size = const Size(320, 640),
    double textScale = 1,
    bool insideAScrollView = false,
    double? boundedHeight,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    Widget body = region;
    if (boundedHeight != null) {
      body = SizedBox(height: boundedHeight, child: body);
    }
    if (insideAScrollView) {
      body = SingleChildScrollView(child: body);
    }

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: MaterialApp(
          theme: IuxTheme.fromConfiguration(const IuxThemeConfiguration()),
          home: Directionality(
            textDirection: TextDirection.ltr,
            child: Scaffold(body: body),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// Builds a place map, defaulting to the shape the pilot's round takes.
  Widget placeMap({
    List<IuxPlace>? places,
    int count = 5,
    Widget map = const _FakeMap(),
    IuxMapZoom? zoom,
    String listLabel = _kListLabel,
    IuxMapSelection? selection,
    ValueChanged<IuxPlace>? onPlaceSelected,
    String? placeActionHint,
  }) =>
      IuxPlaceMap(
        places: places ?? round(count),
        map: map,
        zoom: zoom ??
            IuxZoomControls(
              zoomInLabel: _kZoomIn,
              zoomOutLabel: _kZoomOut,
              onZoomIn: () {},
              onZoomOut: () {},
            ),
        listLabel: listLabel,
        selection: selection,
        onPlaceSelected: onPlaceSelected,
        placeActionHint: placeActionHint,
      );

  /// Every non-empty label a screen reader would walk, in the order it walks
  /// them.
  ///
  /// Read from [SemanticsNode.getSemanticsData], never from
  /// [SemanticsNode.label], and the difference is the whole test. A row built
  /// on `MergeSemantics` carries **nothing** in its own `label`: the ordinal,
  /// the name, the address and the distance are its descendants' and only the
  /// merged data has them. The first draft of this file read `label` and
  /// reported an empty semantics tree for a list that was fully populated —
  /// which would have been an alarming false positive if it had gone the other
  /// way and passed.
  List<String> spoken(WidgetTester tester) => tester.semantics
      .simulatedAccessibilityTraversal()
      .map((SemanticsNode node) => node.getSemanticsData().label)
      .where((String label) => label.isNotEmpty)
      .toList();

  /// The one node whose whole merged label is [label].
  SemanticsNode nodeLabelled(WidgetTester tester, String label) =>
      tester.semantics.simulatedAccessibilityTraversal().firstWhere(
            (SemanticsNode node) => node.getSemanticsData().label == label,
          );

  group('a map without its list equivalent is not constructible', () {
    test('a map of nowhere is refused, and the refusal names the four causes',
        () {
      // An empty list is not a map with nothing on it. It is one of the four
      // situations IuxEmptyStateCause already distinguishes, and this pattern
      // can express none of them.
      expect(
        () => IuxPlaceMap(
          places: const <IuxPlace>[],
          map: const SizedBox.shrink(),
          zoom: const IuxZoomFixed(),
          listLabel: _kListLabel,
        ),
        throwsA(
          isA<AssertionError>().having(
            (AssertionError error) => error.message.toString(),
            'message',
            allOf(
              contains('IuxNothingCreatedYet'),
              contains('IuxNoMatches'),
              contains('IuxAccessRestricted'),
              contains('IuxNothingLeftToDo'),
              contains('IuxLoadingRetry'),
            ),
          ),
        ),
      );
    });

    testWidgets('every place is on screen as text, always',
        (WidgetTester tester) async {
      // The claim the whole pattern rests on. There is no parameter that could
      // have removed these rows: `places` is required, the widget renders them
      // itself, and no combination of the other six parameters suppresses one.
      await host(tester, placeMap(count: 5));

      for (int i = 1; i <= 5; i++) {
        expect(find.text('Site $i'), findsOneWidget, reason: 'name $i');
        expect(find.text('$i'), findsOneWidget, reason: 'ordinal $i');
        expect(find.text('$i Mill Lane, Salford'), findsOneWidget);
        expect(find.text('$i.2 km'), findsOneWidget);
      }
    });

    testWidgets(
        'the map is removed from the semantics tree and the list is not',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(tester, placeMap(count: 3));

      final List<String> labels = spoken(tester);

      // Hiding the map is only defensible because the list is guaranteed. Both
      // halves of that trade are asserted here, in one test, so neither can be
      // changed without the other being looked at.
      expect(labels, isNot(contains(_kTileLabel)));
      expect(labels, contains(_kListLabel));
      for (int i = 1; i <= 3; i++) {
        expect(
          labels.any((String label) => label.contains('Site $i')),
          isTrue,
          reason: 'place $i is not in the semantics tree',
        );
      }

      handle.dispose();
    });

    testWidgets(
        'a row carries the ordinal, the name, the address and the '
        'distance as one utterance', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(tester, placeMap(count: 3, onPlaceSelected: (IuxPlace _) {}));

      final SemanticsData row =
          tester.getSemantics(find.text('Site 2')).getSemanticsData();
      final String label = row.label;

      // Four fragments the user would otherwise have to reassemble, and the
      // ordinal first, because it is the position in the round.
      expect(label, contains('2'));
      expect(label, contains('Site 2'));
      expect(label, contains('2 Mill Lane, Salford'));
      expect(label, contains('2.2 km'));
      expect(label.indexOf('Site 2'), greaterThan(label.indexOf('2')));
      expect(row.flagsCollection.isButton, isTrue);

      handle.dispose();
    });

    test('two places sharing an identifier are refused', () {
      expect(
        () => IuxPlaceMap(
          places: const <IuxPlace>[
            IuxPlace(id: 'same', ordinal: '1', name: 'One'),
            IuxPlace(id: 'same', ordinal: '2', name: 'Two'),
          ],
          map: const SizedBox.shrink(),
          zoom: const IuxZoomFixed(),
          listLabel: _kListLabel,
        ),
        throwsAssertionError,
      );
    });

    test('a selection naming a place that is not in the list is refused', () {
      expect(
        () => IuxPlaceMap(
          places: round(3),
          map: const SizedBox.shrink(),
          zoom: const IuxZoomFixed(),
          listLabel: _kListLabel,
          selection: const IuxMapSelection(
            placeId: 'WO-40',
            announcement: _kSelectionOfThree,
          ),
        ),
        throwsAssertionError,
      );
    });

    test('an unnamed list is refused', () {
      expect(
        () => IuxPlaceMap(
          places: round(1),
          map: const SizedBox.shrink(),
          zoom: const IuxZoomFixed(),
          listLabel: '',
        ),
        throwsAssertionError,
      );
    });

    test('a hint for a tap that does not exist is refused', () {
      expect(
        () => IuxPlaceMap(
          places: round(1),
          map: const SizedBox.shrink(),
          zoom: const IuxZoomFixed(),
          listLabel: _kListLabel,
          placeActionHint: _kPlaceHint,
        ),
        throwsAssertionError,
      );
    });
  });

  group('a place says enough to be found without the map', () {
    test('a place with no name is refused', () {
      expect(
        () => IuxPlace(id: 'a', ordinal: '1', name: ''),
        throwsAssertionError,
      );
    });

    test('a place with no ordinal is refused, and the refusal cites SC 1.4.1',
        () {
      // The ordinal is the whole of IUX's contribution to a marker it does not
      // draw: a token that is not a colour, shared between the list and the
      // marker.
      expect(
        () => IuxPlace(id: 'a', ordinal: '', name: 'Site'),
        throwsA(
          isA<AssertionError>().having(
            (AssertionError error) => error.message.toString(),
            'message',
            contains('1.4.1'),
          ),
        ),
      );
    });

    test('a place with no identity is refused', () {
      expect(
        () => IuxPlace(id: '', ordinal: '1', name: 'Site'),
        throwsAssertionError,
      );
    });

    test('an empty detail and an empty distance are refused, not ignored', () {
      expect(
        () => IuxPlace(id: 'a', ordinal: '1', name: 'Site', detail: ''),
        throwsAssertionError,
      );
      expect(
        () => IuxPlace(id: 'a', ordinal: '1', name: 'Site', distance: ''),
        throwsAssertionError,
      );
    });

    test('a place is a value', () {
      const IuxPlace one = IuxPlace(id: 'a', ordinal: '1', name: 'Site');
      const IuxPlace same = IuxPlace(id: 'a', ordinal: '1', name: 'Site');
      const IuxPlace other = IuxPlace(id: 'b', ordinal: '1', name: 'Site');

      expect(one, same);
      expect(one.hashCode, same.hashCode);
      expect(one, isNot(other));
    });

    testWidgets('a place with no address and no distance still renders',
        (WidgetTester tester) async {
      // Both are optional and both being absent is a real round: a sequence of
      // sites the driver knows by name.
      await host(
        tester,
        placeMap(
          places: const <IuxPlace>[
            IuxPlace(id: 'a', ordinal: '1', name: 'Depot'),
          ],
        ),
      );

      expect(find.text('Depot'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('pinch is never the only way to zoom', () {
    test('a zoom control with no name is refused', () {
      expect(
        () => IuxZoomControls(
          zoomInLabel: '',
          zoomOutLabel: _kZoomOut,
          onZoomIn: () {},
          onZoomOut: () {},
        ),
        throwsAssertionError,
      );
      expect(
        () => IuxZoomControls(
          zoomInLabel: _kZoomIn,
          zoomOutLabel: '',
          onZoomIn: () {},
          onZoomOut: () {},
        ),
        throwsAssertionError,
      );
    });

    test('the answer is one of exactly two, and it is a property of the type',
        () {
      expect(const IuxZoomFixed().hasControls, isFalse);
      expect(
        IuxZoomControls(
          zoomInLabel: _kZoomIn,
          zoomOutLabel: _kZoomOut,
          onZoomIn: () {},
          onZoomOut: () {},
        ).hasControls,
        isTrue,
      );
    });

    testWidgets('both controls are named and both are activatable',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      int zoomedIn = 0;
      int zoomedOut = 0;

      await host(
        tester,
        placeMap(
          zoom: IuxZoomControls(
            zoomInLabel: _kZoomIn,
            zoomOutLabel: _kZoomOut,
            onZoomIn: () => zoomedIn++,
            onZoomOut: () => zoomedOut++,
          ),
        ),
      );

      expect(
        nodeLabelled(tester, _kZoomIn)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
      expect(
        nodeLabelled(tester, _kZoomOut)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();

      expect(zoomedIn, 1);
      expect(zoomedOut, 1);

      handle.dispose();
    });

    testWidgets('a fixed map draws no controls at all',
        (WidgetTester tester) async {
      await host(tester, placeMap(zoom: const IuxZoomFixed()));

      expect(find.byIcon(Icons.add), findsNothing);
      expect(find.byIcon(Icons.remove), findsNothing);
      // And the list is untouched: a map that cannot zoom still has places.
      expect(find.text('Site 1'), findsOneWidget);
    });

    testWidgets('a map too short to draw takes its controls with it',
        (WidgetTester tester) async {
      // Controls for a camera nobody can see are two targets in the thumb zone
      // that do nothing observable.
      await host(tester, placeMap(), boundedHeight: 260);

      expect(find.byKey(_kMapKey), findsNothing);
      expect(find.byIcon(Icons.add), findsNothing);
      expect(find.text('Site 1'), findsOneWidget);
    });
  });

  group('the map yields, the list never does', () {
    testWidgets(
        'the map takes two fifths of a bounded height, divided by the '
        'text scale', (WidgetTester tester) async {
      // The rule, pinned at all four scales on the smallest screen this
      // library targets. At 300% the map is gone entirely, and that is the
      // case the division exists for: held at a fixed share, the list had 304
      // pixels for rows whose titles alone are 144 pixels tall, so not one
      // place was fully visible until the user scrolled.
      const List<(double, double?)> expected = <(double, double?)>[
        (1, 256),
        (1.5, 170.67),
        (2, 128),
        (3, null),
      ];

      for (final (double scale, double? height) in expected) {
        await host(tester, placeMap(), textScale: scale);
        if (height == null) {
          expect(find.byKey(_kMapKey), findsNothing, reason: 'at $scale');
        } else {
          expect(
            tester.getSize(find.byKey(_kMapKey)).height,
            closeTo(height, 0.01),
            reason: 'at $scale',
          );
        }
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('the share is capped, so a tall window is mostly list',
        (WidgetTester tester) async {
      await host(
        tester,
        placeMap(),
        size: const Size(400, 1200),
        boundedHeight: 1200,
      );

      expect(tester.getSize(find.byKey(_kMapKey)).height, 360);
    });

    testWidgets('below the floor the map goes and the list keeps everything',
        (WidgetTester tester) async {
      await host(tester, placeMap(), boundedHeight: 260);

      expect(find.byKey(_kMapKey), findsNothing);
      for (int i = 1; i <= 5; i++) {
        expect(find.text('Site $i'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'an unbounded height gives the map its minimum and adds no '
        'second scroll view', (WidgetTester tester) async {
      await host(tester, placeMap(), insideAScrollView: true);

      expect(tester.getSize(find.byKey(_kMapKey)).height, 120);
      // The caller's, and only the caller's. A scroll view inside a scroll
      // view is the defect IUX-028 records.
      expect(find.byType(Scrollable), findsOneWidget);
    });

    testWidgets('a bounded height scrolls the list and nothing else',
        (WidgetTester tester) async {
      await host(tester, placeMap(count: 40));

      expect(find.byType(Scrollable), findsOneWidget);
    });

    testWidgets('a short viewport at 300% survives a long selection sentence',
        (WidgetTester tester) async {
      // The measurement behind putting the status line inside the scrolling
      // region rather than above it. Everything above the list is a fixed
      // height the map has to fit inside; on a 320-tall viewport — a phone in
      // landscape — a selection sentence at 300% wraps to four lines, and four
      // lines is more than the room left over.
      //
      // Rebuild with `_IuxSelectedPlaceStatus` hoisted above the `Expanded`
      // and this reports a RenderFlex overflow of about 90 pixels.
      await host(
        tester,
        placeMap(
          count: 8,
          selection: const IuxMapSelection(
            placeId: 'WO-3',
            announcement: 'Stop 3 of 8, Renshaw and Company, Depot 4, '
                '18 Mill Lane, Salford, selected and shown on the map',
          ),
        ),
        size: const Size(640, 320),
        boundedHeight: 320,
        textScale: 3,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Site 1'), findsOneWidget);
    });
  });

  group('one place, forty places, and every text scale between', () {
    testWidgets('one place is a list of one', (WidgetTester tester) async {
      await host(tester, placeMap(count: 1));

      expect(find.text('Site 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('forty places all build, and the last one is reachable',
        (WidgetTester tester) async {
      IuxPlace? chosen;
      await host(
        tester,
        placeMap(
          count: 40,
          onPlaceSelected: (IuxPlace place) => chosen = place,
          placeActionHint: _kPlaceHint,
        ),
      );

      // Eagerly built, which is IuxListGroup's documented behaviour and this
      // pattern's stated limit.
      expect(find.text('Site 40'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Site 40'),
        300,
        scrollable: find.byType(Scrollable),
      );

      // findsOneWidget is not evidence a control can be pressed — the lesson
      // of IUX-A11Y-REACH-001. Hit-test it, then press it, then check the
      // activation arrived.
      expect(find.text('Site 40').hitTestable(), findsOneWidget);
      await tester.tap(find.text('Site 40'));
      await tester.pump();

      expect(chosen?.id, 'WO-40');
    });

    testWidgets('nothing overflows at 100, 150, 200 or 300 per cent',
        (WidgetTester tester) async {
      for (final double scale in <double>[1, 1.5, 2, 3]) {
        await host(tester, placeMap(count: 8), textScale: scale);
        expect(tester.takeException(), isNull, reason: 'standalone at $scale');

        // DebugOverflowIndicatorMixin reports a render object's overflow once
        // per lifetime, so a loop reusing the element tree passes vacuously
        // after the first case (IUX-QA-VACUOUS-003). Tear the tree down.
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('nothing overflows inside a scroll view either, at any scale',
        (WidgetTester tester) async {
      for (final double scale in <double>[1, 1.5, 2, 3]) {
        await host(
          tester,
          placeMap(count: 8),
          textScale: scale,
          insideAScrollView: true,
        );
        expect(tester.takeException(), isNull, reason: 'nested at $scale');
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets(
        'the zoom controls are reachable whenever the map is drawn, '
        'and absent when it is not', (WidgetTester tester) async {
      for (final double scale in <double>[1, 1.5, 2, 3]) {
        int zoomed = 0;
        await host(
          tester,
          placeMap(
            zoom: IuxZoomControls(
              zoomInLabel: _kZoomIn,
              zoomOutLabel: _kZoomOut,
              onZoomIn: () => zoomed++,
              onZoomOut: () {},
            ),
          ),
          textScale: scale,
        );

        if (find.byKey(_kMapKey).evaluate().isEmpty) {
          // No camera on screen, so no controls for it. Two targets in the
          // thumb zone that move something invisible are worse than none.
          expect(find.byIcon(Icons.add), findsNothing, reason: 'at $scale');
        } else {
          expect(
            find.byIcon(Icons.add).hitTestable(),
            findsOneWidget,
            reason: 'zoom in is not hit-testable at $scale',
          );
          await tester.tap(find.byIcon(Icons.add));
          await tester.pump();
          expect(zoomed, 1, reason: 'zoom in did not activate at $scale');
        }

        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('the fortieth place stays reachable at every scale',
        (WidgetTester tester) async {
      for (final double scale in <double>[1, 1.5, 2, 3]) {
        IuxPlace? chosen;
        await host(
          tester,
          placeMap(
            count: 40,
            onPlaceSelected: (IuxPlace place) => chosen = place,
            placeActionHint: _kPlaceHint,
          ),
          textScale: scale,
        );

        await tester.scrollUntilVisible(
          find.text('Site 40'),
          300,
          scrollable: find.byType(Scrollable),
        );
        expect(find.text('Site 40').hitTestable(), findsOneWidget);
        await tester.tap(find.text('Site 40'));
        await tester.pump();

        expect(chosen?.id, 'WO-40', reason: 'unreachable at $scale');

        await tester.pumpWidget(const SizedBox.shrink());
      }
    });
  });

  group('selection is words, never a colour', () {
    test('a selection with no wording is refused', () {
      expect(
        () => IuxMapSelection(placeId: 'a', announcement: ''),
        throwsAssertionError,
      );
      expect(
        () => IuxMapSelection(placeId: '', announcement: 'Selected'),
        throwsAssertionError,
      );
    });

    testWidgets('the selection is announced in place and shown on screen',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(
        tester,
        placeMap(
          count: 8,
          selection: const IuxMapSelection(
            placeId: 'WO-3',
            announcement: _kSelectionOfThree,
          ),
        ),
      );

      // Visible: a sighted user needs to know which place the map is showing
      // them too, and a line of text survives a monochrome display.
      expect(find.text(_kSelectionOfThree), findsOneWidget);
      expect(
        nodeLabelled(tester, _kSelectionOfThree)
            .getSemanticsData()
            .flagsCollection
            .isLiveRegion,
        isTrue,
      );

      handle.dispose();
    });

    testWidgets('the selected row names itself as the current one',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(
        tester,
        placeMap(
          count: 8,
          selection: const IuxMapSelection(
            placeId: 'WO-3',
            announcement: _kSelectionOfThree,
          ),
          onPlaceSelected: (IuxPlace _) {},
          placeActionHint: _kPlaceHint,
        ),
      );

      // A user sweeping the list lands on the one row that says it is the
      // current one, rather than having to remember what they heard.
      expect(
        tester.getSemantics(find.text('Site 3')).getSemanticsData().label,
        contains(_kSelectionOfThree),
      );
      expect(
        tester.getSemantics(find.text('Site 4')).getSemanticsData().label,
        isNot(contains(_kSelectionOfThree)),
      );

      handle.dispose();
    });

    testWidgets('activating a row reports the place and changes nothing else',
        (WidgetTester tester) async {
      IuxPlace? chosen;
      await host(
        tester,
        placeMap(
          count: 8,
          onPlaceSelected: (IuxPlace place) => chosen = place,
          placeActionHint: _kPlaceHint,
        ),
      );

      await tester.tap(find.text('Site 2'));
      await tester.pump();

      expect(chosen?.id, 'WO-2');
      // Nothing has been selected: the parent owns that answer and has not
      // given one yet.
      expect(find.text(_kSelectionOfThree), findsNothing);
    });

    testWidgets('without a callback the rows are not controls',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(tester, placeMap(count: 3));

      expect(
        tester
            .getSemantics(find.text('Site 1'))
            .getSemanticsData()
            .flagsCollection
            .isButton,
        isFalse,
      );

      handle.dispose();
    });
  });

  group('focus is never moved, because the user never asked for it', () {
    testWidgets('a selection change leaves the caret where it was',
        (WidgetTester tester) async {
      final FocusNode elsewhere = FocusNode(debugLabel: 'elsewhere');
      addTearDown(elsewhere.dispose);

      Future<void> pumpWith(IuxMapSelection selection) => host(
            tester,
            Column(
              children: <Widget>[
                Focus(
                  focusNode: elsewhere,
                  autofocus: true,
                  child: const SizedBox(height: 24),
                ),
                Expanded(
                  child: placeMap(
                    count: 8,
                    selection: selection,
                    onPlaceSelected: (IuxPlace _) {},
                    placeActionHint: _kPlaceHint,
                  ),
                ),
              ],
            ),
          );

      await pumpWith(
        const IuxMapSelection(
          placeId: 'WO-3',
          announcement: _kSelectionOfThree,
        ),
      );
      expect(elsewhere.hasPrimaryFocus, isTrue);

      // The selection changes under the user — a marker tapped by a sighted
      // colleague, an application advancing the round. The event happened to
      // them, so nothing takes their place in the focus order.
      await pumpWith(
        const IuxMapSelection(
          placeId: 'WO-5',
          announcement: _kSelectionOfFive,
        ),
      );
      await tester.pump();

      expect(find.text(_kSelectionOfFive), findsOneWidget);
      expect(elsewhere.hasPrimaryFocus, isTrue);
      expect(tester.binding.focusManager.primaryFocus, same(elsewhere));
    });

    testWidgets('activating a row does not move focus either',
        (WidgetTester tester) async {
      final FocusNode elsewhere = FocusNode(debugLabel: 'elsewhere');
      addTearDown(elsewhere.dispose);

      await host(
        tester,
        Column(
          children: <Widget>[
            Focus(
              focusNode: elsewhere,
              autofocus: true,
              child: const SizedBox(height: 24),
            ),
            Expanded(
              child: placeMap(
                count: 8,
                onPlaceSelected: (IuxPlace _) {},
                placeActionHint: _kPlaceHint,
              ),
            ),
          ],
        ),
      );

      await tester.tap(find.text('Site 2'));
      await tester.pump();

      expect(elsewhere.hasPrimaryFocus, isTrue);
    });
  });

  group('the framework composes nothing the caller did not write', () {
    testWidgets('every word on screen came from the call site',
        (WidgetTester tester) async {
      await host(
        tester,
        placeMap(
          count: 3,
          selection: const IuxMapSelection(
            placeId: 'WO-3',
            announcement: _kSelectionOfThree,
          ),
          onPlaceSelected: (IuxPlace _) {},
          placeActionHint: _kPlaceHint,
        ),
      );

      final Set<String> supplied = <String>{
        _kListLabel,
        _kSelectionOfThree,
        for (int i = 1; i <= 3; i++) ...<String>[
          '$i',
          'Site $i',
          '$i Mill Lane, Salford',
          '$i.2 km',
        ],
      };

      final Iterable<String> painted = tester
          .widgetList<Text>(find.byType(Text))
          .map((Text text) => text.data ?? '')
          .where((String data) => data.isNotEmpty);

      expect(painted, isNotEmpty);
      for (final String data in painted) {
        expect(
          supplied,
          contains(data),
          reason: '"$data" is on screen and no call site supplied it',
        );
      }
    });

    testWidgets('and every word a screen reader hears did too',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(
        tester,
        placeMap(
          count: 3,
          selection: const IuxMapSelection(
            placeId: 'WO-3',
            announcement: _kSelectionOfThree,
          ),
          onPlaceSelected: (IuxPlace _) {},
          placeActionHint: _kPlaceHint,
        ),
      );

      final Set<String> supplied = <String>{
        _kListLabel,
        _kSelectionOfThree,
        _kZoomIn,
        _kZoomOut,
        _kPlaceHint,
        for (int i = 1; i <= 3; i++) ...<String>[
          '$i',
          'Site $i',
          '$i Mill Lane, Salford',
          '$i.2 km',
        ],
      };

      final List<String> longestFirst = supplied.toList()
        ..sort((String a, String b) => b.length.compareTo(a.length));

      // A merged row is several supplied strings joined by the platform, so
      // the test removes what the caller wrote and asserts nothing is left but
      // separators.
      for (final SemanticsNode node
          in tester.semantics.simulatedAccessibilityTraversal()) {
        final SemanticsData data = node.getSemanticsData();
        String residue = '${data.label} ${data.hint}';
        // Longest first. Removing '1' before 'Site 1' leaves 'Site ' behind
        // and reports the framework for a word the caller wrote — which is how
        // the first version of this test failed.
        for (final String word in longestFirst) {
          residue = residue.replaceAll(word, '');
        }
        expect(
          RegExp('[A-Za-z]').hasMatch(residue),
          isFalse,
          reason: 'the framework contributed "$residue" to "${data.label}"',
        );
      }

      handle.dispose();
    });
  });

  group('the pattern reaches no platform', () {
    test('it imports Flutter and IUX and nothing else', () {
      // The constraint that shapes the whole pattern, measured rather than
      // promised. A map plugin here would put a platform call, an API key, a
      // manifest entry and a release cadence into every application that uses
      // IUX — and IUX would then be shipping a map, which is the one thing it
      // has decided not to do.
      for (final String path in _kSources) {
        final String body = _code(path);

        for (final RegExpMatch directive
            in RegExp(r"import\s+'([^']+)'").allMatches(body)) {
          final String target = directive.group(1)!;
          final bool allowed = target.startsWith('package:flutter/') ||
              (!target.startsWith('package:') && !target.startsWith('dart:'));
          expect(
            allowed,
            isTrue,
            reason: '$path imports $target. This pattern may reach Flutter and '
                'the layers of IUX below it, and nothing else.',
          );
        }

        for (final String forbidden in <String>[
          'MethodChannel',
          'Platform.',
          'dart:io',
          'google_maps_flutter',
          'GoogleMap',
          'LatLng',
          'CameraPosition',
          'MapController',
          'mapbox',
          'flutter_map',
        ]) {
          expect(
            body.contains(forbidden),
            isFalse,
            reason: '$path mentions $forbidden outside a comment. Nothing here '
                'renders a tile, holds a coordinate, or knows which map SDK '
                'the application chose.',
          );
        }
      }
    });

    test('and it requests focus nowhere', () {
      // The eighth pattern to decide focus, holding IUX-033's line: the user
      // asked for a place, not for a position in the focus order. Pinned
      // mechanically as well as behaviourally, because a single call added
      // later would be invisible at review.
      for (final String path in _kSources) {
        expect(
          _code(path).contains('IuxFocus'),
          isFalse,
          reason: '$path moves focus.',
        );
      }
    });
  });
}
