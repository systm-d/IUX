import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_catalog/button_panels.dart';
import 'package:iux_catalog/button_scenarios.dart';
import 'package:iux_catalog/catalog_overlays.dart';
import 'package:iux_catalog/catalog_testable.dart';
import 'package:iux_catalog/content_panels.dart';
import 'package:iux_catalog/feedback_panels.dart';
import 'package:iux_catalog/flow_panels.dart';
import 'package:iux_catalog/form_panels.dart';
import 'package:iux_catalog/input_panels.dart';
import 'package:iux_catalog/layout_panels.dart';
import 'package:iux_catalog/navigation_panels.dart';
import 'package:iux_catalog/overlay_panels.dart';
import 'package:iux_catalog/runtime_panels.dart';
import 'package:iux_catalog/search_panels.dart';
import 'package:iux_catalog/status_panels.dart';
import 'package:iux_catalog/theme_panels.dart';
import 'package:iux_flutter/iux_flutter.dart';

/// A frame that says "Test it" around something inert is worse than no frame.
///
/// The frame exists because the catalog shows live controls and deliberately
/// inert specimens side by side, and the first person to use it on a phone
/// read the specimens as broken components. That only holds while every frame
/// actually contains something a press changes — which is a claim about the
/// semantics tree, not about the source, and not one anybody can keep by
/// reading. So it is swept: every section is mounted and every frame in it is
/// asked whether anything inside answers a press.
///
/// The claim is deliberately the semantics tree's and not the gesture
/// detector's. A control a finger can press and a screen reader cannot is not
/// a testable sample — it is a defect, and the sweep is where the catalog
/// finds out. See the finding under the runtime section's announcements panel
/// for the one this sweep refused to frame.
void main() {
  /// The sections with nothing live in them at all.
  ///
  /// Not an oversight in either case. Layout shows frames, surfaces, gaps and
  /// caps — every control in it is an illustration of a size, and pressing one
  /// changes nothing. Theme is plain Flutter widgets painted with resolved
  /// tokens and contains no control of any kind. Both are asserted empty
  /// rather than skipped: a live sample added to either has to arrive with a
  /// frame, and taking a section out of this set is the reviewable moment.
  const Set<String> barren = <String>{'Layout', 'Theme'};

  /// Whether anything under [root] offers a press to assistive technology.
  ///
  /// Walks render objects rather than the semantics tree because that is what
  /// scopes the question to one frame: a node is reached only through the
  /// render object that published it, so nothing outside the frame can answer
  /// for it.
  bool answersAPress(RenderObject root) {
    final SemanticsNode? own = root.debugSemantics;
    if (own != null &&
        (own.getSemanticsData().actions & SemanticsAction.tap.index) != 0) {
      return true;
    }

    bool found = false;
    root.visitChildren((RenderObject child) {
      found = found || answersAPress(child);
    });
    return found;
  }

  /// Fails unless the frame rooted at [frame] holds something activable.
  void expectAnswersAPress(Element frame, {required String where}) {
    final RenderObject? render = frame.renderObject;
    expect(
      render != null && answersAPress(render),
      isTrue,
      reason: 'a "Test it" frame in $where contains nothing that answers a '
          'press. A frame telling the reader to press something and then '
          'refusing them reproduces exactly the confusion it exists to '
          'remove — either the sample stopped being live, or it should never '
          'have been framed',
    );
  }

  Future<void> mount(WidgetTester tester, Widget section) async {
    // Tall enough to lay the whole section out at once. A frame scrolled off
    // the bottom is still a frame, and a sweep that only saw the first screen
    // would be a sweep of the first panel.
    tester.view.physicalSize = const Size(900, 40000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      IuxFeedbackScope(
        child: MaterialApp(
          theme: IuxTheme.light(),
          home: Scaffold(body: SingleChildScrollView(child: section)),
        ),
      ),
    );
    // Fixed frames rather than pumpAndSettle: an indeterminate progress
    // indicator animates for as long as it is mounted, so settling never
    // returns.
    for (int i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  final Map<String, Widget Function()> sections = <String, Widget Function()>{
    'Buttons': () {
      final ButtonScenarios scenarios = ButtonScenarios();
      addTearDown(scenarios.dispose);
      return ButtonPanels(scenarios: scenarios, longLabels: false);
    },
    'Inputs': () => const InputPanels(longLabels: false),
    'Forms': () => const FormPanels(longLabels: false),
    'Search': () => const SearchPanels(longLabels: false),
    'Cards and lists': () => const ContentPanels(longLabels: false),
    'Media and status': () => const StatusPanels(longLabels: false),
    'Layout': () => const LayoutPanels(longLabels: false),
    'Navigation': () {
      final CatalogOverlays overlays = CatalogOverlays();
      addTearDown(overlays.dispose);
      return NavigationPanels(longLabels: false, overlays: overlays);
    },
    'Overlays': () {
      final CatalogOverlays overlays = CatalogOverlays();
      addTearDown(overlays.dispose);
      return OverlayPanels(longLabels: false, overlays: overlays);
    },
    'Feedback': () => const FeedbackPanels(longLabels: false),
    'Flows': () {
      final CatalogOverlays overlays = CatalogOverlays();
      addTearDown(overlays.dispose);
      return FlowPanels(longLabels: false, overlays: overlays);
    },
    'Theme': () => const ThemePanels(longLabels: false),
    'Runtime': () => const RuntimePanels(),
  };

  for (final MapEntry<String, Widget Function()> entry in sections.entries) {
    testWidgets('every Test it frame in ${entry.key} holds something activable',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await mount(tester, entry.value());

      final List<Element> frames =
          find.byType(CatalogTestable).evaluate().toList();

      if (barren.contains(entry.key)) {
        expect(
          frames,
          isEmpty,
          reason: 'nothing in ${entry.key} responds to a press, so a frame '
              'here is either around a specimen or around a sample that '
              'wants this section taken out of the barren set',
        );
      } else {
        expect(
          frames,
          isNotEmpty,
          reason: '${entry.key} has live samples in it and none of them is '
              'marked. That is the state the frame exists to end',
        );
        for (final Element frame in frames) {
          expectAnswersAPress(frame, where: entry.key);
        }
      }

      handle.dispose();
    });
  }

  /// Several samples stop responding when a chip above them is changed — an
  /// empty state whose cause owes the user nothing, a retry that is already
  /// running, a message with its action turned off. Those frames are withheld
  /// in exactly those branches, and the sweep above only ever sees the default
  /// one. These two drive the branches by hand.
  Future<void> choose(WidgetTester tester, String option) async {
    await tester.tap(find.bySemanticsLabel(option));
    for (int i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('a frame goes when its sample stops responding',
      (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    final CatalogOverlays overlays = CatalogOverlays();
    addTearDown(overlays.dispose);
    await mount(tester, FlowPanels(longLabels: false, overlays: overlays));

    final int before = find.byType(CatalogTestable).evaluate().length;

    // The one cause that owes the user no way forward, and a retry whose node
    // offers the focus action and not tap because the policy declines a second
    // activation. Both look exactly like the branch beside them.
    await choose(
      tester,
      'Cause: nothing left to do — the one cause owing no way forward',
    );
    await choose(tester, 'Route: retry — already running');

    final List<Element> frames =
        find.byType(CatalogTestable).evaluate().toList();
    expect(
      frames.length,
      before - 2,
      reason: 'both samples stopped answering a press, so both frames have to '
          'go with them — a frame that survives its own sample is the state '
          'this whole mechanism exists to prevent',
    );
    for (final Element frame in frames) {
      expectAnswersAPress(frame, where: 'Flows, in its inert branches');
    }

    handle.dispose();
  });

  testWidgets('a message with nothing in it to press is not framed',
      (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await mount(tester, const FeedbackPanels(longLabels: false));

    expect(find.byType(CatalogTestable), findsNWidgets(2));
    await choose(tester, 'Action: absent');

    expect(
      find.byType(CatalogTestable),
      findsNothing,
      reason: 'with neither an action nor a dismissal the alert and the '
          'banner are a paragraph in a coloured box, and nothing in either '
          'answers a press',
    );

    handle.dispose();
  });

  testWidgets('the sweep fails on a frame around something inert',
      (WidgetTester tester) async {
    // The negative control, and the reason to trust the thirteen above. A
    // disabled button is the specimen the catalog is full of: it looks like a
    // control, it is announced as one, and its node offers no tap. If the
    // sweep passed this, it would pass anything.
    final SemanticsHandle handle = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        theme: IuxTheme.light(),
        home: const Scaffold(
          body: CatalogTestable(
            what: 'Nothing. That is what this test is checking.',
            child: IuxButton(
              label: 'Send',
              action: IuxActionDescriptor(
                availability: IuxActionAvailability.disabled,
                semantics: IuxActionSemantics(
                  label: 'Send',
                  unavailabilityReason: 'Nothing is selected',
                ),
              ),
              onActivate: _noop,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      () => expectAnswersAPress(
        find.byType(CatalogTestable).evaluate().single,
        where: 'the negative control',
      ),
      throwsA(isA<TestFailure>()),
      reason: 'the sweep has to be able to fail, or the thirteen sections it '
          'passes prove nothing',
    );

    handle.dispose();
  });

  test('the frame refuses to say nothing', () {
    expect(
      () => CatalogTestable(what: '', child: const SizedBox()),
      throwsAssertionError,
    );
  });
}

/// A callback that does nothing, so the negative control can be `const`.
void _noop() {}
