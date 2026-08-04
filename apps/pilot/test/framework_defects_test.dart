import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

/// Defects in `iux_flutter` that this application had to work around.
///
/// Every test here asserts the **current, wrong** behaviour, so the day it is
/// fixed one of them fails and somebody comes and reads this file. Nothing here
/// is a test of the pilot; it is the pilot's evidence, kept executable so it
/// cannot rot into a paragraph nobody rechecks.
///
/// Where the application's workaround lives is named in each test.
void main() {
  Future<void> settle(WidgetTester tester, {int frames = 6}) async {
    for (int i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> clear(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  Widget host(double scale, Widget child) => MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: MaterialApp(
          theme: IuxTheme.light(),
          home: Scaffold(body: IuxPage(child: child)),
        ),
      );

  testWidgets(
      'IUX-EXPAND-CRASH-001 is fixed: two full-width buttons stack, and keep '
      'the separation floor', (WidgetTester tester) async {
    await tester.pumpWidget(
      host(
        1,
        IuxTargetSpacing(
          children: <Widget>[
            IuxButton(
              label: 'One',
              action: const IuxActionDescriptor(
                semantics: IuxActionSemantics(label: 'One'),
              ),
              expand: true,
              onActivate: () {},
            ),
            IuxButton(
              label: 'Two',
              action: const IuxActionDescriptor(
                semantics: IuxActionSemantics(label: 'Two'),
              ),
              expand: true,
              onActivate: () {},
            ),
          ],
        ),
      ),
    );

    // This test was written asserting the crash, so that a fix would fail
    // loudly rather than land unnoticed. It has done its job: IuxTargetSpacing
    // now lays its vertical axis out with a Column, which gives `expand`
    // a bounded width to take.
    //
    // The assertion that matters is not merely that nothing throws — it is
    // that the arrangement keeps the guarantee the workaround gave up. The
    // Column-plus-IuxGap the pilot used instead measures 4px between bare
    // targets; this measures the floor.
    expect(tester.takeException(), isNull);

    final Rect one = tester.getRect(find.byType(IuxButton).first);
    final Rect two = tester.getRect(find.byType(IuxButton).last);
    expect(two.top - one.bottom, greaterThanOrEqualTo(kIuxMinimumTargetSpacing),
        reason: 'the whole point of IuxTargetSpacing is that adjacent targets '
            'cannot end up closer than the floor');
  });

  testWidgets(
      'IuxListItem overflows when its trailing control is an IuxStatusIndicator',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    Future<Object?> at(double scale) async {
      await clear(tester);
      await tester.pumpWidget(
        host(
          scale,
          IuxListGroup(
            children: <Widget>[
              IuxListItem.tappable(
                title: 'WO-4471',
                subtitle: '18 Mill Lane',
                trailingAction: const IuxStatusIndicator(
                  status: IuxStatus.neutral('Scheduled'),
                ),
                onActivate: () {},
              ),
            ],
          ),
        ),
      );
      await settle(tester);
      return tester.takeException();
    }

    // The row lays its trailing control out as a non-flexible child of a Row,
    // so the control takes its full intrinsic width and the Expanded holding
    // the row's own text absorbs a negative remainder. Neither component is
    // wrong on its own; the composition is.
    //
    // Workaround: lib/jobs_screen.dart uses `trailingText`, which sits inside
    // the constrained region — and loses the status tone with it.
    expect(await at(1), isNull);
    expect(await at(1.5), isNull);
    expect(await at(2), isNotNull, reason: 'overflows by 68px at 200%');
    expect(await at(3), isNotNull, reason: 'overflows by 214px at 300%');
  });

  testWidgets('IuxSearchResults cannot be placed on an IuxPage',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      host(
        1,
        IuxSearchResults<String>(
          results: const IuxLoadState<List<String>>.ready(<String>['a']),
          summary: (BuildContext context, List<String> value) =>
              '${value.length} results',
          searchingLabel: 'Searching',
          failureCategoryLabel: 'Error',
          recovery: IuxRetryRoute(label: 'Try again', onRetry: () {}),
          reset: IuxEmptyStateAction(
            label: 'Clear the search',
            action: const IuxActionDescriptor(
              semantics: IuxActionSemantics(label: 'Clear the search'),
            ),
            onActivate: () {},
          ),
          builder: (BuildContext context, List<String> value) =>
              const Text('results'),
        ),
      ),
    );

    // `RenderFlex children have non-zero flex but incoming height constraints
    // are unbounded`, from the Column at iux_search_results.dart:341. The ready
    // branch wraps the caller's list in an Expanded; IuxPage scrolls by
    // default. The two cannot be composed, and IuxPage is the only thing in the
    // framework that knows the page insets and the reading width.
    //
    // Workaround: lib/jobs_screen.dart composes IuxSearchField, IuxEmptyState
    // and IuxListGroup by hand, reimplementing the private status line.
    expect(tester.takeException(), isNotNull);
  });

  testWidgets('IuxAppBar cannot report an intrinsic height',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: IuxTheme.light(),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: IntrinsicHeight(
              child: Column(
                children: <Widget>[
                  IuxAppBar(title: 'Visits'),
                  Expanded(child: IuxPage(child: Text('content'))),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // `LayoutBuilder does not support returning intrinsic dimensions`.
    // IuxAppBar uses a LayoutBuilder internally (iux_app_bar.dart:339) to
    // decide whether the title shares a row with its controls, which rules out
    // IntrinsicHeight, IntrinsicWidth and intrinsic Table sizing for any screen
    // containing one — including the standard fill-viewport-or-scroll frame.
    //
    // Consequence: lib/screen_frame.dart scrolls the whole screen and the
    // title is never pinned.
    expect(tester.takeException(), isNotNull);
  });

  testWidgets('IuxAppBar above IuxPage applies the top inset twice',
      (WidgetTester tester) async {
    const EdgeInsets inset = EdgeInsets.only(top: 40);

    Future<double> contentTop({required bool removeTop}) async {
      await clear(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: IuxTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(padding: inset, viewPadding: inset),
            child: Builder(
              builder: (BuildContext context) => Column(
                children: <Widget>[
                  const IuxAppBar(title: 'Visits'),
                  Expanded(
                    child: removeTop
                        ? MediaQuery.removePadding(
                            context: context,
                            removeTop: true,
                            child: const IuxPage(child: Text('content')),
                          )
                        : const IuxPage(child: Text('content')),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await settle(tester, frames: 2);
      return tester.getRect(find.text('content')).top;
    }

    // The bar consumes the top inset for its own subtree; a sibling page on the
    // default IuxPageInsets.handled consumes it again. Nothing asserts.
    //
    // Workaround: the MediaQuery.removePadding in lib/screen_frame.dart.
    expect(
      await contentTop(removeTop: false) - await contentTop(removeTop: true),
      inset.top,
    );
  });
}
