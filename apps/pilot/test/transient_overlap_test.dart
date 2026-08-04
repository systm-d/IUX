import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_pilot/main.dart';
import 'package:iux_pilot/strings.dart';

/// Pins the one arrangement decision the shell cannot get wrong.
///
/// `IuxTransientLayer` pins its message to the bottom of whatever it wraps and
/// reserves no layout space for it, so wrapping it around the whole shell puts
/// every notice on top of the bottom navigation bar. Measured on a 360x800
/// window with the layer outside `IuxAdaptiveNavigation`: the notice occupies
/// y 712-760, the destinations sit at y 740-786, and all three report
/// `hitTestable = 0`. The dwell is a minimum of four seconds and there is
/// deliberately no way to shorten it, so the application's primary navigation
/// would be unusable for four seconds after every notice.
///
/// The fix is to place the layer *inside* the navigation, which is what the
/// shell does. This test fails if anybody moves it back.
void main() {
  Future<void> settle(WidgetTester tester, {int frames = 12}) async {
    for (int i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('a transient notice never covers the bottom navigation',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const PilotApp());
    await settle(tester);

    await tester.tap(find.text(Strings.navNew));
    await settle(tester);
    await tester.enterText(
      find.bySemanticsLabel(RegExp(Strings.formReference)),
      'WO-1',
    );
    await tester.enterText(
        find.bySemanticsLabel(RegExp(Strings.formSite)), 'A');
    await settle(tester);

    final Finder submit = find.text(Strings.formSubmit);
    await tester.ensureVisible(submit);
    await settle(tester, frames: 3);
    await tester.tap(submit);
    await settle(tester, frames: 4);

    // The notice is on screen: this test would pass vacuously without it.
    expect(find.text(Strings.formAdded('WO-1')), findsOneWidget);

    expect(find.text(Strings.navNew).hitTestable(), findsOneWidget);
    expect(find.text(Strings.navSettings).hitTestable(), findsOneWidget);
  });
}
