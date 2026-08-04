// Tristate is declared in `dart:ui` and is not re-exported by
// `package:flutter/semantics.dart`, so this is the only way to name it. It is
// what distinguishes "not focused" from "declares no focusable state at all",
// and that distinction is the whole subject of this file.
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';
// Imported from source because it is deliberately unexported: two widgets in
// one control have to name the same focus node, and a public helper for that
// would be an API whose only correct use is internal.
import 'package:iux_flutter/src/accessibility/iux_focus_ownership.dart';

/// Every control IUX builds on an excluding `IuxSemantics` helper, measured
/// the way the defect was found.
///
/// **IUX-A11Y-FOCUS-001.** The helper sets `excludeSemantics` in order to
/// control the announced name, and the exclusion deletes everything the
/// `IuxFocusable` subtree contributed — including the `Focus` widget's own
/// `focusable`, `focused` and `onFocus` annotations. A control built this way
/// reports `isFocused: Tristate.none` and offers `actions: [tap]`, which means
/// the node declares no focusable state at all and assistive technology has no
/// way to move accessibility focus onto it. WCAG 2.2 SC 4.1.2.
///
/// IUX-038 fixed `IuxButton` and, auditing its own fix, found that
/// `IuxFocusNodeOwner` had exactly one call site. This file measured the rest:
/// the disclosure control, the help disclosure control, the validation summary
/// entry, both transient-layer controls, both inline-feedback controls and the
/// filter chip — eight, not the four that had been reported. Three of those
/// were worse than reported: they carried no `tap` action either, which is the
/// IUX-011 defect still live, hidden because `announced_controls_test.dart`
/// scans bare `Semantics(` calls and these compose the helper instead.
///
/// Widening the sweep past `IuxSemantics.action` then found the same defect in
/// `IuxSemantics.selection`, which excludes for the same reason: the checkbox,
/// the switch and the radio option made eleven.
///
/// Three things are asserted for each, because two of them can pass while the
/// control is still broken:
///
/// 1. the node reports a focus *state* rather than `Tristate.none`;
/// 2. it offers `SemanticsAction.focus`;
/// 3. **driving that action moves real focus.** A node can advertise the
///    action and name a node nothing holds, which is the subtler version of
///    the same defect and the reason `IuxFocusNodeOwner` exists.
///
/// Each is measured against `ElevatedButton` under the same host, so a claim
/// about IUX is a claim about the gap between IUX and Flutter's own.
void main() {
  Future<void> host(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(400, 800)),
        child: MaterialApp(
          theme: IuxTheme.fromConfiguration(const IuxThemeConfiguration()),
          home: Directionality(
            textDirection: TextDirection.ltr,
            child: Scaffold(
              body: Align(alignment: Alignment.topLeft, child: child),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The focus state and the actions of the node [finder] lands on.
  ({Tristate focused, bool offersFocus}) describe(
    WidgetTester tester,
    Finder finder,
  ) {
    final SemanticsData data = tester.getSemantics(finder).getSemanticsData();
    return (
      focused: data.flagsCollection.isFocused,
      offersFocus: data.hasAction(SemanticsAction.focus),
    );
  }

  /// Drives an action on the node labelled [label], the way a platform does.
  ///
  /// `tester.semantics.performAction` refuses a node that does not advertise
  /// the action, so this cannot silently do nothing — which is what a raw
  /// `SemanticsOwner.performAction` does, and what made the original defect
  /// look like working code.
  Future<void> drive(
    WidgetTester tester,
    String label,
    SemanticsAction action,
  ) async {
    tester.semantics.performAction(find.semantics.byLabel(label), action);
    await tester.pumpAndSettle();
  }

  /// Asserts the three properties on the control labelled [label].
  Future<void> expectFocusIsPublishedAndReal(
    WidgetTester tester,
    String label, {
    required String what,
  }) async {
    final Finder finder = find.bySemanticsLabel(label);
    final ({Tristate focused, bool offersFocus}) before =
        describe(tester, finder);
    expect(
      before.focused,
      isNot(Tristate.none),
      reason: '$what declares no focusable state at all, so a screen reader '
          'is never told this is somewhere focus can go. It used to report '
          'Tristate.none — IUX-A11Y-FOCUS-001.',
    );
    expect(
      before.offersFocus,
      isTrue,
      reason: '$what offers no SemanticsAction.focus, so assistive technology '
          'cannot move accessibility focus onto it programmatically.',
    );

    await drive(tester, label, SemanticsAction.focus);

    expect(
      describe(tester, finder).focused,
      Tristate.isTrue,
      reason: 'performAction(SemanticsAction.focus) on $what left the node '
          'reporting that it is not focused. The action is advertised and '
          'connected to nothing, or it names a focus node that no widget in '
          'this control actually holds.',
    );
  }

  /// What Flutter's own button reports under the same host.
  ///
  /// Every expectation below is the same expectation applied to this, so the
  /// bar is Flutter's behaviour rather than a number this file invented.
  group('the bar: Flutter reports focus on its own button', () {
    testWidgets('ElevatedButton publishes a focus state and a focus action',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(
        tester,
        ElevatedButton(onPressed: () {}, child: const Text('Flutter')),
      );

      final ({Tristate focused, bool offersFocus}) measured =
          describe(tester, find.bySemanticsLabel('Flutter'));
      expect(measured.focused, Tristate.isFalse);
      expect(measured.offersFocus, isTrue);

      await expectFocusIsPublishedAndReal(
        tester,
        'Flutter',
        what: 'ElevatedButton',
      );
      handle.dispose();
    });
  });

  group('IuxButton, fixed at IUX-038 and still fixed', () {
    testWidgets('matches Flutter exactly', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(
        tester,
        Column(
          children: <Widget>[
            IuxButton(
              label: 'Pay',
              action: const IuxActionDescriptor(
                semantics: IuxActionSemantics(label: 'Pay'),
              ),
              onActivate: () {},
            ),
            ElevatedButton(onPressed: () {}, child: const Text('Flutter')),
          ],
        ),
      );

      expect(
        describe(tester, find.bySemanticsLabel('Pay')),
        describe(tester, find.bySemanticsLabel('Flutter')),
        reason: 'an IUX control and a Material one must describe focus '
            'identically, or a screen-reader user meets two kinds of button '
            'in one application',
      );
      await expectFocusIsPublishedAndReal(
        tester,
        'Pay',
        what: 'IuxButton',
      );
      handle.dispose();
    });
  });

  group('the seven controls IUX-038 left behind, and the eighth it missed', () {
    testWidgets('the disclosure control', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(tester, const _DisclosureHost());

      await expectFocusIsPublishedAndReal(
        tester,
        _disclosureSummary,
        what: 'the progressive disclosure control',
      );
      handle.dispose();
    });

    testWidgets('the disclosure control stays activatable after being focused',
        (WidgetTester tester) async {
      // Focus and activation are separate actions on the same node, and the
      // fix for one must not cost the other.
      final SemanticsHandle handle = tester.ensureSemantics();
      final GlobalKey<_DisclosureHostState> key =
          GlobalKey<_DisclosureHostState>();
      await host(tester, _DisclosureHost(key: key));

      await drive(tester, _disclosureSummary, SemanticsAction.tap);

      expect(key.currentState!.state, isA<IuxDisclosureExpanded>());
      handle.dispose();
    });

    testWidgets('the help disclosure control', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(tester, const _HelpHost());

      await expectFocusIsPublishedAndReal(
        tester,
        _helpLabel,
        what: 'the contextual help control',
      );
      handle.dispose();
    });

    testWidgets('the validation summary entry', (WidgetTester tester) async {
      // The entry is the one control on a refused submission a screen-reader
      // user has to be able to be *sent* to, rather than swiped onto.
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(
        tester,
        IuxValidationSummary(
          categoryLabel: 'Error',
          message: 'There is a problem with this form',
          entries: <IuxValidationSummaryEntry>[
            IuxValidationSummaryEntry(
              label: 'Email address',
              message: 'Enter an email address',
              onActivate: () {},
            ),
          ],
        ),
      );

      await expectFocusIsPublishedAndReal(
        tester,
        'Email address. Enter an email address',
        what: 'a validation summary entry',
      );
      handle.dispose();
    });

    testWidgets('both transient-layer controls', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(tester, const _TransientHost());

      await expectFocusIsPublishedAndReal(
        tester,
        'Undo',
        what: 'the transient message action',
      );
      await expectFocusIsPublishedAndReal(
        tester,
        _dismissTransient,
        what: 'the transient message dismiss control',
      );
      handle.dispose();
    });

    testWidgets('both inline-feedback controls', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(tester, _alert());

      await expectFocusIsPublishedAndReal(
        tester,
        'Retry',
        what: 'the inline feedback recovery control',
      );
      await expectFocusIsPublishedAndReal(
        tester,
        'Dismiss',
        what: 'the inline feedback dismiss control',
      );
      handle.dispose();
    });

    testWidgets('the filter chip', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(
        tester,
        IuxFilterChip(
          label: 'Vegetarian',
          selected: false,
          onSelectionChanged: (bool _) {},
        ),
      );

      await expectFocusIsPublishedAndReal(
        tester,
        'Vegetarian',
        what: 'IuxFilterChip',
      );
      handle.dispose();
    });
  });

  /// `IuxSemantics.selection` is the same mechanism a second time.
  ///
  /// It also sets `excludeSemantics` in order to control the announced name,
  /// so it also deleted the `Focus` widget's annotations. Found by widening
  /// the sweep past `IuxSemantics.action`: the checkbox and the switch
  /// reported `Tristate.none` with `actions: [tap]` while Flutter's own
  /// reported `Tristate.isFalse` with `[tap, focus]` under the same host.
  group('the selection helper had the same defect', () {
    testWidgets('a checkbox and a switch match Flutter\'s own',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(
        tester,
        Column(
          children: <Widget>[
            IuxCheckbox(
              label: 'Vegetarian',
              input: const IuxInputDescriptor(
                semantics: IuxInputSemantics(label: 'Vegetarian'),
              ),
              value: IuxSelectionState.unselected,
              onChanged: (bool _) {},
            ),
            IuxSwitch(
              label: 'Notifications',
              input: const IuxInputDescriptor(
                semantics: IuxInputSemantics(label: 'Notifications'),
              ),
              value: IuxSelectionState.unselected,
              onChanged: (bool _) {},
            ),
          ],
        ),
      );

      await expectFocusIsPublishedAndReal(
        tester,
        'Vegetarian',
        what: 'IuxCheckbox',
      );
      await expectFocusIsPublishedAndReal(
        tester,
        'Notifications',
        what: 'IuxSwitch',
      );
      handle.dispose();
    });

    testWidgets('a disabled selection control declares no focusable state',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(
        tester,
        IuxCheckbox(
          label: 'Vegetarian',
          input: const IuxInputDescriptor(
            semantics: IuxInputSemantics(label: 'Vegetarian'),
            availability: IuxInputAvailability.disabled,
          ),
          value: IuxSelectionState.unselected,
          onChanged: (bool _) {},
        ),
      );

      final ({Tristate focused, bool offersFocus}) measured =
          describe(tester, find.bySemanticsLabel('Vegetarian'));
      expect(measured.focused, Tristate.none);
      expect(measured.offersFocus, isFalse);
      handle.dispose();
    });

    testWidgets('a read-only control keeps its place in the focus order',
        (WidgetTester tester) async {
      // Read-only is not disabled. It stays focusable and still announces its
      // value; only a disabled control leaves the order.
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(
        tester,
        IuxCheckbox(
          label: 'Vegetarian',
          input: const IuxInputDescriptor(
            semantics: IuxInputSemantics(label: 'Vegetarian'),
            availability: IuxInputAvailability.readOnly,
          ),
          value: IuxSelectionState.unselected,
          onChanged: (bool _) {},
        ),
      );

      await expectFocusIsPublishedAndReal(
        tester,
        'Vegetarian',
        what: 'a read-only IuxCheckbox',
      );
      handle.dispose();
    });
  });

  /// The three that carried no `tap` action either.
  ///
  /// Found by the same sweep. `announced_controls_test.dart` scans bare
  /// `Semantics(` calls, and these compose `IuxSemantics.action` instead — the
  /// helper's own source satisfies that scan on behalf of every caller, so the
  /// callers were never read. Announced as buttons, and a screen-reader
  /// double-tap did nothing at all.
  group('a control announced as a button answers a double-tap', () {
    testWidgets('the inline feedback recovery control',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final List<String> pressed = <String>[];
      await host(tester, _alert(onRetry: () => pressed.add('retry')));

      await drive(tester, 'Retry', SemanticsAction.tap);

      expect(pressed, <String>['retry']);
      handle.dispose();
    });

    testWidgets('the inline feedback dismiss control',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final List<String> pressed = <String>[];
      await host(tester, _alert(onDismissed: () => pressed.add('dismiss')));

      await drive(tester, 'Dismiss', SemanticsAction.tap);

      expect(pressed, <String>['dismiss']);
      handle.dispose();
    });

    testWidgets('the filter chip', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final List<bool> asked = <bool>[];
      await host(
        tester,
        IuxFilterChip(
          label: 'Vegetarian',
          selected: false,
          onSelectionChanged: asked.add,
        ),
      );

      await drive(tester, 'Vegetarian', SemanticsAction.tap);

      expect(asked, <bool>[true]);
      handle.dispose();
    });
  });

  group('what the fix must not have broken', () {
    testWidgets('a caller\'s own focus node is still the node described',
        (WidgetTester tester) async {
      // IuxFocusNodeOwner prefers the caller's node over the one it creates.
      // If it did not, the node the platform is told about and the node the
      // application holds would be two different objects — which is the
      // subtler version of this same defect.
      final SemanticsHandle handle = tester.ensureSemantics();
      final FocusNode node = FocusNode(debugLabel: 'caller');
      addTearDown(node.dispose);
      await host(tester, _DisclosureHost(controlFocus: node));

      await drive(tester, _disclosureSummary, SemanticsAction.focus);

      expect(
        node.hasPrimaryFocus,
        isTrue,
        reason: 'the platform was told about a focus that lives somewhere '
            'other than the node the caller passed in',
      );
      handle.dispose();
    });

    testWidgets('a disabled chip declares no focusable state',
        (WidgetTester tester) async {
      // The opposite failure. Announcing "not focused" for a control that can
      // never take focus describes a state it does not have, and a disabled
      // control leaves the focus order entirely — which is what Flutter does
      // too.
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(
        tester,
        const IuxFilterChip(
          label: 'Vegetarian',
          selected: false,
          onSelectionChanged: null,
        ),
      );

      final ({Tristate focused, bool offersFocus}) measured =
          describe(tester, find.bySemanticsLabel('Vegetarian'));
      expect(measured.focused, Tristate.none);
      expect(measured.offersFocus, isFalse);
      handle.dispose();
    });

    testWidgets('a node created here is disposed with the control',
        (WidgetTester tester) async {
      // The line IuxFocusNodeOwner exists to write once, because it is the one
      // a copy at eight call sites forgets — and a leaked FocusNode is
      // invisible in a widget test, which is why nothing else here would
      // notice. Asserted against the helper directly, because a control that
      // routes through it hands the node to nobody.
      late FocusNode created;
      await tester.pumpWidget(
        IuxFocusNodeOwner(
          focusNode: null,
          builder: (BuildContext context, FocusNode node) {
            created = node;
            return const SizedBox.shrink();
          },
        ),
      );
      await tester.pumpWidget(const SizedBox.shrink());

      expect(
        () => created.addListener(() {}),
        throwsA(isA<FlutterError>()),
        reason: 'the node IuxFocusNodeOwner created outlived the control it '
            'belonged to. That is the leak the helper exists to prevent, and '
            'it is silent — nothing on screen and nothing in the semantics '
            'tree changes when it happens.',
      );
    });

    testWidgets('a node the caller owns is left alone',
        (WidgetTester tester) async {
      // The other half of the same rule. A node passed in outlives this
      // widget, and disposing it would leave its owner holding a dead one.
      final FocusNode caller = FocusNode(debugLabel: 'caller');
      addTearDown(caller.dispose);

      await tester.pumpWidget(
        IuxFocusNodeOwner(
          focusNode: caller,
          builder: (BuildContext context, FocusNode node) {
            expect(node, same(caller));
            return const SizedBox.shrink();
          },
        ),
      );
      await tester.pumpWidget(const SizedBox.shrink());

      expect(() => caller.addListener(() {}), returnsNormally);
    });
  });
}

const String _disclosureSummary = 'Delivery options';
const String _helpLabel = 'What is a sort code?';
const String _dismissTransient = 'Dismiss the saved-draft notice';

Widget _alert({VoidCallback? onRetry, VoidCallback? onDismissed}) => IuxAlert(
      category: IuxFeedbackCategory.error,
      categoryLabel: 'Error',
      message: 'We could not charge your card',
      action: IuxNamedAction(
        label: 'Retry',
        onActivate: onRetry ?? () {},
      ),
      dismissal: IuxInlineFeedbackDismissal(
        label: 'Dismiss',
        onDismissed: onDismissed ?? () {},
      ),
    );

/// A parent that owns the disclosure state, exactly as a real one does.
class _DisclosureHost extends StatefulWidget {
  const _DisclosureHost({super.key, this.controlFocus});

  final FocusNode? controlFocus;

  @override
  State<_DisclosureHost> createState() => _DisclosureHostState();
}

class _DisclosureHostState extends State<_DisclosureHost> {
  IuxDisclosureState state = const IuxDisclosureState.collapsed();

  @override
  Widget build(BuildContext context) => IuxProgressiveDisclosure(
        summary: _disclosureSummary,
        state: state,
        focusNode: widget.controlFocus,
        onExpandedChanged: (bool value) => setState(
          () => state = value
              ? const IuxDisclosureState.expanded()
              : const IuxDisclosureState.collapsed(),
        ),
        child: const Text('Leave the parcel with a neighbour.'),
      );
}

/// A parent that owns whether the help panel is open.
class _HelpHost extends StatefulWidget {
  const _HelpHost();

  @override
  State<_HelpHost> createState() => _HelpHostState();
}

class _HelpHostState extends State<_HelpHost> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) => IuxContextualHelp(
        label: _helpLabel,
        help: 'Six digits identifying the branch that holds the account.',
        expanded: expanded,
        onExpandedChanged: (bool value) => setState(() => expanded = value),
      );
}

/// A parent that owns the transient message, exactly as a real one does.
class _TransientHost extends StatefulWidget {
  const _TransientHost();

  @override
  State<_TransientHost> createState() => _TransientHostState();
}

class _TransientHostState extends State<_TransientHost> {
  IuxTransientMessage? message = IuxTransientMessage(
    text: 'Draft saved',
    dismissLabel: _dismissTransient,
    tone: IuxTransientTone.success,
    action: IuxTransientAction(label: 'Undo', onActivate: () {}),
  );

  @override
  Widget build(BuildContext context) => IuxTransientLayer(
        message: message,
        onDismissed: () => setState(() => message = null),
        child: const SizedBox.expand(),
      );
}
