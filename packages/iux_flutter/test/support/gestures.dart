/// Gestures that behave the way a finger does, available to tests only.
///
/// `tester.tap()` sends `down` and `up` inside a single call, with **no frame
/// between them**. A finger always leaves at least one: the shortest tap a
/// human can make lasts tens of milliseconds, and the framework draws during
/// it.
///
/// That single missing frame is the difference between a suite that can see a
/// whole class of defect and one that cannot. Any component that rebuilds
/// while it is held — which is every component with press feedback — gets one
/// opportunity to change the shape of its own subtree mid-gesture. When it
/// does, the `State` carrying the recogniser that is tracking the pointer is
/// disposed, the `up` lands nowhere, and the control never fires. With no
/// frame in between, the rebuild never happens before the `up`, so the defect
/// is not merely missed: it is **unreachable** by that instrument.
///
/// It is not a hypothetical. `IUX-SELECTION-PRESS-001` shipped exactly this
/// way — no `IuxSwitch`, `IuxCheckbox` or `IuxRadioGroup` responded to a
/// finger, while 2 320 tests passed, including tap tests written directly
/// against those controls.
///
/// See `COMPONENT_STANDARD.md` §18 for when this is required rather than
/// preferred.
library;

import 'package:flutter_test/flutter_test.dart';

/// Presses [target], waits a frame, then releases — one realistic tap.
///
/// Use this for every assertion of the form *this component responds when the
/// user presses it*. `tester.tap()` stays correct where the question is about
/// the target rather than the response: whether a region is large enough,
/// whether the label is inside it, whether a disabled control refuses. Those
/// do not depend on what happens between `down` and `up`.
///
/// [hold] is how long the pointer stays down. The default is roughly the
/// shortest deliberate human tap, and it is long enough for any number of
/// frames to be produced: what matters is that at least one is, not how many.
/// Raise it only when a component's own timing is under test — a long-press,
/// a hold-to-pause.
///
/// [warnIfMissed] is forwarded to the hit test, and defaults to true for the
/// same reason `tester.tap()` does: a gesture aimed at a widget that is not
/// there should say so rather than silently assert nothing. Pass false when a
/// test deliberately presses something that is not expected to respond.
///
/// Settles afterwards, so an assertion that follows sees the state the press
/// produced rather than a frame partway into its animation.
Future<void> realTap(
  WidgetTester tester,
  Finder target, {
  Duration hold = const Duration(milliseconds: 80),
  bool warnIfMissed = true,
}) async {
  final TestGesture gesture = await tester.startGesture(
    tester.getCenter(target, warnIfMissed: warnIfMissed, callee: 'realTap'),
  );
  // The frame the press feedback rebuilds in. Everything this helper exists
  // for happens here.
  await tester.pump(hold);
  await gesture.up();
  await tester.pumpAndSettle();
}
