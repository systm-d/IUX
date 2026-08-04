import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_catalog/catalog_testable.dart';
import 'package:iux_flutter/iux_flutter.dart';

/// A frame that says "Test it" around something inert is worse than no frame.
///
/// The frame exists because the catalog shows live controls and deliberately
/// inert specimens side by side, and the first person to use it on a phone
/// read the specimens as broken components. That only holds while every frame
/// actually contains something a press changes — which is a claim about the
/// semantics tree, not about the source.
void main() {
  testWidgets('every Test it frame holds something activable',
      (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        theme: IuxTheme.light(),
        home: Scaffold(
          body: CatalogTestable(
            what: 'Changes the selection.',
            child: IuxButton(
              label: 'Send',
              action: const IuxActionDescriptor(
                semantics: IuxActionSemantics(label: 'Send'),
              ),
              onActivate: () {},
            ),
          ),
        ),
      ),
    );

    final Iterable<SemanticsNode> nodes = <SemanticsNode>[
      tester.getSemantics(find.text('Send')),
    ];
    expect(
      nodes.any(
        (SemanticsNode n) =>
            (n.getSemanticsData().actions & SemanticsAction.tap.index) != 0,
      ),
      isTrue,
      reason: 'a frame telling the reader to press something must contain '
          'something that answers a press — otherwise it reproduces exactly '
          'the confusion it exists to remove',
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
