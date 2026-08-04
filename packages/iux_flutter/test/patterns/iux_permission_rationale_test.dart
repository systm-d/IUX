import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';
// Not yet in the barrel: the team lead owns that file. Imported from source so
// the pattern can be measured before the exports land.

/// What the user gets, named in their terms rather than the platform's.
const String _kTitle = 'Scan receipts with your camera?';

/// Why the application wants it, and what is bounded about that.
const String _kReason =
    'Photographs of receipts are read on this device and never uploaded.';

/// What happens without it, and who can change that.
const String _kGuidance = 'You can still add receipts by hand.';

/// The word on the forward control. Never "Allow": it allows nothing.
const String _kAskLabel = 'Choose camera access';

/// The fuller announced name of the forward control.
const String _kAskSemanticLabel = 'Choose camera access for receipt scanning';

/// The word on the refusal.
const String _kDeclineLabel = 'Not now';

/// The word on the control that leaves for the system settings.
const String _kSettingsLabel = 'Open settings';

/// A reason long enough to prove the block wraps rather than clips.
const String _kLongReason =
    'Receipts are matched to the expenses you have already entered by reading '
    'the total, the date and the merchant name off the photograph, which all '
    'happens on this device and needs the camera only for as long as the '
    'shutter is open; nothing is uploaded, nothing is kept once the figures '
    'have been read, and the photograph itself is discarded unless you ask us '
    'to keep it against the claim.';

void main() {
  /// Builds a forward control that records its activations.
  IuxNamedAction ask({
    String label = _kAskLabel,
    String? semanticLabel,
    VoidCallback? onActivate,
  }) =>
      IuxNamedAction(
        label: label,
        semanticLabel: semanticLabel,
        onActivate: onActivate ?? () {},
      );

  /// Builds a refusal that records its activations.
  IuxNamedAction decline({
    String label = _kDeclineLabel,
    VoidCallback? onActivate,
  }) =>
      IuxNamedAction(
        label: label,
        onActivate: onActivate ?? () {},
      );

  /// Puts one rationale on a page, under the conditions given.
  Future<void> pump(
    WidgetTester tester,
    Widget block, {
    double textScale = 1,
    TextDirection direction = TextDirection.ltr,
    Size size = const Size(400, 800),
    IuxThemeConfiguration configuration = const IuxThemeConfiguration(),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: MaterialApp(
          theme: IuxTheme.fromConfiguration(configuration),
          home: Directionality(
            textDirection: direction,
            child: Scaffold(body: Center(child: block)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('the moment carries only what is honest at that point', () {
    test('before the system asks, a way to ask is not optional', () {
      // A rationale that cannot lead to the question is a wall of text with no
      // door: the user is told why and left unable to agree.
      final IuxBeforeAsking moment =
          IuxBeforeAsking(ask: ask(), decline: decline());

      // Non-nullable on this member, so a caller reading it never checks for an
      // absence that cannot happen.
      expect(moment.action.label, _kAskLabel);
      expect(moment.decline.label, _kDeclineLabel);
    });

    test('after a refusal, asking again is optional', () {
      // Declining to ask twice is a legitimate answer and must be as cheap to
      // write as asking, or the pattern pushes every caller towards the nag.
      expect(IuxAfterRefusal(decline: decline()).action, isNull);
      expect(
        IuxAfterRefusal(askAgain: ask(), decline: decline()).action?.label,
        _kAskLabel,
      );
    });

    test('when the system will not ask, there is nothing that asks', () {
      // The constructor has no ask parameter at all — this is the one thing in
      // the pattern that is unrepresentable rather than asserted. What can be
      // measured is that whatever it does carry goes somewhere rather than
      // claiming to grant something.
      final IuxSystemWillNotAsk moment = IuxSystemWillNotAsk(
        openSettings: ask(label: _kSettingsLabel),
        decline: decline(),
      );

      expect(moment.action?.label, _kSettingsLabel);
      expect(moment.actionDescriptor?.role, IuxActionRole.navigate);
    });

    test('a policy-restricted device may offer no settings link either', () {
      // Sending someone to a screen where the switch is greyed is worse than
      // not offering: they now believe they failed at something.
      expect(IuxSystemWillNotAsk(decline: decline()).action, isNull);
      expect(IuxSystemWillNotAsk(decline: decline()).actionDescriptor, isNull);
    });

    test('two moments of the same kind with the same parts are equal', () {
      void go() {}
      void no() {}
      expect(
        IuxBeforeAsking(
          ask: ask(onActivate: go),
          decline: decline(onActivate: no),
        ),
        equals(
          IuxBeforeAsking(
            ask: ask(onActivate: go),
            decline: decline(onActivate: no),
          ),
        ),
      );
      expect(
        IuxBeforeAsking(
          ask: ask(onActivate: go),
          decline: decline(onActivate: no),
        ).hashCode,
        equals(
          IuxBeforeAsking(
            ask: ask(onActivate: go),
            decline: decline(onActivate: no),
          ).hashCode,
        ),
      );
      // Different kinds never compare equal, whatever they carry: the whole
      // point of the sealed type is that these are different screens.
      expect(
        IuxAfterRefusal(askAgain: ask(onActivate: go), decline: decline()),
        isNot(equals(
            IuxBeforeAsking(ask: ask(onActivate: go), decline: decline()))),
      );
    });

    test('each moment names itself for a debugger', () {
      // Which of the three is on screen is the first question a bug report
      // about a permission screen has to answer.
      expect(
        IuxBeforeAsking(ask: ask(), decline: decline()).toString(),
        contains('IuxBeforeAsking'),
      );
      expect(
        IuxAfterRefusal(decline: decline()).toString(),
        contains('IuxAfterRefusal'),
      );
      expect(
        IuxSystemWillNotAsk(decline: decline()).toString(),
        contains('IuxSystemWillNotAsk'),
      );
    });
  });

  group('the moment derives the action rather than accepting one', () {
    test('no control in this pattern can be a retry', () {
      // Asking again is not repeating a request that failed for a transient
      // reason. Announcing it as "try again" tells a user who deliberately said
      // no that the interface read their decision as a malfunction — and it is
      // the same lie the error pattern forbids from the other side.
      final List<IuxPermissionMoment> moments = <IuxPermissionMoment>[
        IuxBeforeAsking(ask: ask(), decline: decline()),
        IuxAfterRefusal(askAgain: ask(), decline: decline()),
        IuxSystemWillNotAsk(
          openSettings: ask(label: _kSettingsLabel),
          decline: decline(),
        ),
      ];

      for (final IuxPermissionMoment moment in moments) {
        expect(moment.actionDescriptor?.role, IuxActionRole.navigate);
        expect(moment.actionDescriptor?.role, isNot(IuxActionRole.retry));
        expect(moment.declineDescriptor.role, isNot(IuxActionRole.retry));
      }
    });

    test('the forward control grants nothing, and says so in its role', () {
      final IuxActionDescriptor? forward =
          IuxBeforeAsking(ask: ask(), decline: decline()).actionDescriptor;

      // navigate: it hands the user to a surface this application does not own.
      expect(forward?.role, IuxActionRole.navigate);
      expect(forward?.intent, IuxActionIntent.primary);
      expect(forward?.importance, IuxActionImportance.high);
      // No second question, so none can be dropped in silence.
      expect(forward?.requiresConfirmation, isFalse);
      // No lifecycle: the system prompt owns its own progress.
      expect(forward?.operation, IuxActionOperation.idle);
      expect(forward?.isBusy, isFalse);
      expect(forward?.isActivatable, isTrue);
    });

    test('the refusal dismisses, it does not cancel', () {
      // Cancelling abandons an in-progress task and discards what was in it.
      // Declining a permission discards nothing, and announcing it as a
      // cancellation tells the user they are about to lose something.
      final IuxActionDescriptor no =
          IuxBeforeAsking(ask: ask(), decline: decline()).declineDescriptor;

      expect(no.role, IuxActionRole.dismiss);
      expect(no.role, isNot(IuxActionRole.cancel));
      expect(no.intent, IuxActionIntent.secondary);
      expect(no.availability, IuxActionAvailability.enabled);
      expect(no.isActivatable, isTrue);
    });

    test('the announced name falls back to the visible one', () {
      expect(
        IuxBeforeAsking(ask: ask(), decline: decline())
            .actionDescriptor
            ?.semantics
            .label,
        _kAskLabel,
      );
      expect(
        IuxBeforeAsking(
          ask: ask(semanticLabel: _kAskSemanticLabel),
          decline: decline(),
        ).actionDescriptor?.semantics.label,
        _kAskSemanticLabel,
      );
    });
  });

  group('what it puts on screen', () {
    testWidgets('the title, the reason and the guidance', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        IuxPermissionRationale(
          moment: IuxBeforeAsking(ask: ask(), decline: decline()),
          title: _kTitle,
          reason: _kReason,
          guidance: _kGuidance,
        ),
      );

      expect(find.text(_kTitle), findsOneWidget);
      expect(find.text(_kReason), findsOneWidget);
      expect(find.text(_kGuidance), findsOneWidget);
    });

    testWidgets('a request always shows a way to refuse it', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        IuxPermissionRationale(
          moment: IuxBeforeAsking(ask: ask(), decline: decline()),
          title: _kTitle,
          reason: _kReason,
        ),
      );

      expect(find.text(_kAskLabel), findsOneWidget);
      expect(find.text(_kDeclineLabel), findsOneWidget);
      expect(find.byType(IuxButton), findsNWidgets(2));
    });

    testWidgets('a moment that will not ask again shows only the refusal', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        IuxPermissionRationale(
          moment: IuxAfterRefusal(decline: decline()),
          title: _kTitle,
          reason: _kReason,
          guidance: _kGuidance,
        ),
      );

      expect(find.byType(IuxButton), findsOneWidget);
      expect(find.text(_kDeclineLabel), findsOneWidget);
      expect(find.text(_kAskLabel), findsNothing);
    });

    testWidgets('the settings link is the only forward control that remains', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        IuxPermissionRationale(
          moment: IuxSystemWillNotAsk(
            openSettings: ask(label: _kSettingsLabel),
            decline: decline(),
          ),
          title: _kTitle,
          reason: _kReason,
        ),
      );

      expect(find.text(_kSettingsLabel), findsOneWidget);
      expect(find.text(_kDeclineLabel), findsOneWidget);
      // No control that offers to ask: the system will not put the question,
      // and a button that produced nothing when pressed reads as a broken app.
      expect(find.text(_kAskLabel), findsNothing);
    });

    testWidgets('activating a control does not remove the rationale', (
      WidgetTester tester,
    ) async {
      // Whether the permission was granted afterwards is something only the
      // parent can know, and a pattern that hid itself would hide a question
      // that may still be unanswered.
      int asks = 0;
      await pump(
        tester,
        IuxPermissionRationale(
          moment: IuxBeforeAsking(
            ask: ask(onActivate: () => asks++),
            decline: decline(),
          ),
          title: _kTitle,
          reason: _kReason,
        ),
      );

      await tester.tap(find.text(_kAskLabel));
      await tester.pumpAndSettle();

      expect(asks, 1);
      expect(find.text(_kTitle), findsOneWidget);
    });

    testWidgets('the refusal reports itself and nothing else', (
      WidgetTester tester,
    ) async {
      int refusals = 0;
      int asks = 0;
      await pump(
        tester,
        IuxPermissionRationale(
          moment: IuxBeforeAsking(
            ask: ask(onActivate: () => asks++),
            decline: decline(onActivate: () => refusals++),
          ),
          title: _kTitle,
          reason: _kReason,
        ),
      );

      await tester.tap(find.text(_kDeclineLabel));
      await tester.pump();

      expect(refusals, 1);
      expect(asks, 0);
    });

    testWidgets('a rationale with no heading is refused', (
      WidgetTester tester,
    ) async {
      expect(
        () => IuxPermissionRationale(
          moment: IuxBeforeAsking(ask: ask(), decline: decline()),
          title: '',
          reason: _kReason,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    testWidgets('a rationale with no reason is refused', (
      WidgetTester tester,
    ) async {
      // The reason is the entire pattern. Without it this is the system prompt
      // with extra steps.
      expect(
        () => IuxPermissionRationale(
          moment: IuxBeforeAsking(ask: ask(), decline: decline()),
          title: _kTitle,
          reason: '',
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    testWidgets('an empty guidance is refused rather than ignored', (
      WidgetTester tester,
    ) async {
      expect(
        () => IuxPermissionRationale(
          moment: IuxBeforeAsking(ask: ask(), decline: decline()),
          title: _kTitle,
          reason: _kReason,
          guidance: '',
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('the dead end', () {
    testWidgets('a moment with no forward control may not also be silent', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        IuxPermissionRationale(
          moment: IuxAfterRefusal(decline: decline()),
          title: _kTitle,
          reason: _kReason,
        ),
      );

      expect(tester.takeException(), isA<AssertionError>());
    });

    testWidgets('the same holds once the system has closed the door', (
      WidgetTester tester,
    ) async {
      // No exempt moment: in every one of them the user is short of a feature
      // they came for.
      await pump(
        tester,
        IuxPermissionRationale(
          moment: IuxSystemWillNotAsk(decline: decline()),
          title: _kTitle,
          reason: _kReason,
        ),
      );

      expect(tester.takeException(), isA<AssertionError>());
    });

    testWidgets('guidance alone is a way forward', (WidgetTester tester) async {
      await pump(
        tester,
        IuxPermissionRationale(
          moment: IuxSystemWillNotAsk(decline: decline()),
          title: _kTitle,
          reason: _kReason,
          guidance: 'Your work profile manages camera access.',
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(IuxButton), findsOneWidget);
    });

    testWidgets('an action alone is a way forward', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        IuxPermissionRationale(
          moment: IuxBeforeAsking(ask: ask(), decline: decline()),
          title: _kTitle,
          reason: _kReason,
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('nothing here starts a loop', () {
    testWidgets('nothing is asked without the user asking', (
      WidgetTester tester,
    ) async {
      int asks = 0;
      await pump(
        tester,
        IuxPermissionRationale(
          moment: IuxBeforeAsking(
            ask: ask(onActivate: () => asks++),
            decline: decline(),
          ),
          title: _kTitle,
          reason: _kReason,
        ),
      );

      // No timer, no attempt budget, no "ask again in three days". A rationale
      // left on screen asks for nothing, however long it is left there.
      await tester.pump(const Duration(seconds: 30));
      expect(asks, 0);
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('rebuilding the block asks for nothing', (
      WidgetTester tester,
    ) async {
      int asks = 0;
      Widget block() => IuxPermissionRationale(
            moment: IuxBeforeAsking(
              ask: ask(onActivate: () => asks++),
              decline: decline(),
            ),
            title: _kTitle,
            reason: _kReason,
          );

      await pump(tester, block());
      await pump(tester, block());
      await pump(tester, block());

      expect(asks, 0);
    });

    test('the pattern reaches no platform', () {
      // The framework holds the shape of the conversation; the application owns
      // the platform call. Measured rather than promised: a permission plugin
      // that crept in here would spend a user's answer on a request no user
      // made, and on Android a second refusal closes the prompt for good.
      const List<String> sources = <String>[
        'lib/src/patterns/permission/iux_permission_moment.dart',
        'lib/src/patterns/permission/iux_permission_rationale.dart',
      ];

      /// The file with its documentation and comments removed, so prose about
      /// a rule is not mistaken for a violation of it.
      String code(String path) {
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

      for (final String path in sources) {
        final String body = code(path);

        for (final RegExpMatch directive
            in RegExp(r"import\s+'([^']+)'").allMatches(body)) {
          final String target = directive.group(1)!;
          // Flutter itself, or another IUX file by relative path. Anything
          // else — a `dart:` library or a third-party package — is a door this
          // pattern must not have.
          final bool allowed = target.startsWith('package:flutter/') ||
              (!target.startsWith('package:') && !target.startsWith('dart:'));
          expect(
            allowed,
            isTrue,
            reason: '$path imports $target. This pattern may reach Flutter and '
                'the layers of IUX below it, and nothing else: a permission '
                'plugin here would put a platform call, a manifest entry and a '
                'release cadence into every application that uses IUX.',
          );
        }

        for (final String forbidden in <String>[
          'MethodChannel',
          'Platform.',
          'dart:io',
          'permission_handler',
          'openAppSettings',
          'requestPermissions',
          'shouldShowRequestPermissionRationale',
        ]) {
          expect(
            body.contains(forbidden),
            isFalse,
            reason: '$path mentions $forbidden outside a comment. Nothing here '
                'calls a permission API, reads a permission status, or knows '
                'which platform it is on.',
          );
        }
      }
    });
  });

  group('accessibility', () {
    testWidgets('the argument is one stop, not three fragments', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(
        tester,
        IuxPermissionRationale(
          moment: IuxBeforeAsking(ask: ask(), decline: decline()),
          title: _kTitle,
          reason: _kReason,
          guidance: _kGuidance,
        ),
      );

      final SemanticsNode node = tester.getSemantics(find.text(_kTitle));
      final SemanticsData data = node.getSemanticsData();

      // What is being asked for, then why, then what happens otherwise.
      expect(data.label, contains(_kTitle));
      expect(data.label, contains(_kReason));
      expect(data.label, contains(_kGuidance));
      expect(
        data.label.indexOf(_kTitle),
        lessThan(data.label.indexOf(_kReason)),
      );
      // And neither of the other two is a stop of its own.
      expect(tester.getSemantics(find.text(_kReason)), same(node));
      expect(tester.getSemantics(find.text(_kGuidance)), same(node));

      handle.dispose();
    });

    testWidgets('the framework adds no words of its own', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(
        tester,
        IuxPermissionRationale(
          moment: IuxBeforeAsking(ask: ask(), decline: decline()),
          title: _kTitle,
          reason: _kReason,
          guidance: _kGuidance,
        ),
      );

      // Every word a user hears here arrived from the caller, already
      // localised. Take the caller's three sentences out of the announced label
      // and nothing with a letter in it may be left — a separator is a pause,
      // and a pause is wanted in every language.
      final String residue = tester
          .getSemantics(find.text(_kTitle))
          .getSemanticsData()
          .label
          .replaceAll(_kTitle, '')
          .replaceAll(_kReason, '')
          .replaceAll(_kGuidance, '');

      expect(RegExp(r'\p{L}', unicode: true).hasMatch(residue), isFalse);

      handle.dispose();
    });

    testWidgets('the request is announced where it appears', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(
        tester,
        IuxPermissionRationale(
          moment: IuxBeforeAsking(ask: ask(), decline: decline()),
          title: _kTitle,
          reason: _kReason,
        ),
      );

      // A question nobody heard is not a question. Unlike IuxEmptyState there
      // is no arrival dimension: a request is an event by definition.
      expect(
        tester.getSemantics(find.text(_kTitle)),
        isSemantics(isLiveRegion: true),
      );

      handle.dispose();
    });

    testWidgets('every moment is announced, not only the first', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      for (final IuxPermissionMoment moment in <IuxPermissionMoment>[
        IuxBeforeAsking(ask: ask(), decline: decline()),
        IuxAfterRefusal(askAgain: ask(), decline: decline()),
        IuxSystemWillNotAsk(
          openSettings: ask(label: _kSettingsLabel),
          decline: decline(),
        ),
      ]) {
        await pump(
          tester,
          IuxPermissionRationale(
            moment: moment,
            title: _kTitle,
            reason: _kReason,
          ),
        );

        expect(
          tester.getSemantics(find.text(_kTitle)),
          isSemantics(isLiveRegion: true),
        );
      }

      handle.dispose();
    });

    testWidgets('the argument itself is not announced as a control', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(
        tester,
        IuxPermissionRationale(
          moment: IuxBeforeAsking(ask: ask(), decline: decline()),
          title: _kTitle,
          reason: _kReason,
        ),
      );

      // A paragraph is not activatable. Announcing it as a button would promise
      // an action that does not exist — and here that action would be consent.
      expect(
        tester.getSemantics(find.text(_kTitle)),
        isSemantics(isButton: false),
      );

      handle.dispose();
    });

    testWidgets('both controls are stops of their own, and can be activated', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      int asks = 0;
      int refusals = 0;
      await pump(
        tester,
        IuxPermissionRationale(
          moment: IuxBeforeAsking(
            ask: ask(
              semanticLabel: _kAskSemanticLabel,
              onActivate: () => asks++,
            ),
            decline: decline(onActivate: () => refusals++),
          ),
          title: _kTitle,
          reason: _kReason,
        ),
      );

      final SemanticsNode forward =
          tester.getSemantics(find.bySemanticsLabel(_kAskSemanticLabel));
      final SemanticsNode no =
          tester.getSemantics(find.bySemanticsLabel(_kDeclineLabel));

      for (final SemanticsNode control in <SemanticsNode>[forward, no]) {
        expect(
          control,
          isSemantics(
            isButton: true,
            isEnabled: true,
            hasEnabledState: true,
            hasTapAction: true,
          ),
        );
        expect(control, isNot(same(tester.getSemantics(find.text(_kTitle)))));
      }

      // A screen-reader double tap is the platform's tap action, not a pointer
      // gesture. A node announced as a button that offers nothing to activate
      // is visible, named and unusable.
      // ignore: deprecated_member_use
      final SemanticsOwner owner = tester.binding.pipelineOwner.semanticsOwner!;
      owner.performAction(no.id, SemanticsAction.tap);
      await tester.pump();
      expect(refusals, 1);

      owner.performAction(forward.id, SemanticsAction.tap);
      await tester.pump();
      expect(asks, 1);

      handle.dispose();
    });

    testWidgets('the announced name may be fuller than the visible one', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(
        tester,
        IuxPermissionRationale(
          moment: IuxBeforeAsking(
            ask: ask(semanticLabel: _kAskSemanticLabel),
            decline: decline(),
          ),
          title: _kTitle,
          reason: _kReason,
        ),
      );

      // A screen offering two permissions holds two controls called "Choose
      // access", and a user moving by control cannot tell which is which.
      expect(find.text(_kAskLabel), findsOneWidget);
      expect(find.bySemanticsLabel(_kAskSemanticLabel), findsOneWidget);

      handle.dispose();
    });

    testWidgets('the refusal is the first control a keyboard reaches', (
      WidgetTester tester,
    ) async {
      int asks = 0;
      int refusals = 0;
      await pump(
        tester,
        IuxPermissionRationale(
          moment: IuxBeforeAsking(
            ask: ask(onActivate: () => asks++),
            decline: decline(onActivate: () => refusals++),
          ),
          title: _kTitle,
          reason: _kReason,
        ),
      );

      // The way out is never something the user has to travel past a request to
      // find — and the control that opens a system prompt is never the one
      // sitting under the first Enter press.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(refusals, 1);
      expect(asks, 0);

      // And the forward control is reachable from a keyboard too.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(asks, 1);
    });

    testWidgets('nothing takes focus when the rationale appears', (
      WidgetTester tester,
    ) async {
      final FocusNode elsewhere = FocusNode();
      addTearDown(elsewhere.dispose);

      final ValueNotifier<bool> asked = ValueNotifier<bool>(false);
      addTearDown(asked.dispose);

      await pump(
        tester,
        ValueListenableBuilder<bool>(
          valueListenable: asked,
          builder: (BuildContext context, bool showing, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Focus(
                focusNode: elsewhere,
                child: const SizedBox.square(dimension: 24),
              ),
              if (showing)
                IuxPermissionRationale(
                  moment: IuxBeforeAsking(ask: ask(), decline: decline()),
                  title: _kTitle,
                  reason: _kReason,
                ),
            ],
          ),
        ),
      );

      elsewhere.requestFocus();
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, same(elsewhere));

      // Focus landing on a control arms it under the next Enter or the next
      // screen-reader double tap, and the control this block offers opens the
      // operating system's permission prompt. A refusal the user never meant to
      // give can close that prompt for good.
      asked.value = true;
      await tester.pumpAndSettle();

      expect(find.text(_kAskLabel), findsOneWidget);
      expect(FocusManager.instance.primaryFocus, same(elsewhere));
    });

    testWidgets('nothing autofocuses on a fresh screen', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        IuxPermissionRationale(
          moment: IuxBeforeAsking(ask: ask(), decline: decline()),
          title: _kTitle,
          reason: _kReason,
        ),
      );

      expect(
        FocusManager.instance.primaryFocus?.context?.widget,
        isNot(isA<IuxButton>()),
      );
    });

    testWidgets('the illustration carries nothing', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(
        tester,
        IuxPermissionRationale(
          moment: IuxBeforeAsking(ask: ask(), decline: decline()),
          title: _kTitle,
          reason: _kReason,
          illustration: Icons.photo_camera_outlined,
        ),
      );

      // WCAG SC 1.1.1: decoration is hidden outright rather than described.
      final SemanticsNode glyph = tester.getSemantics(
        find.byType(IuxIcon),
      );
      expect(glyph.getSemanticsData().label, isEmpty);
      expect(glyph, isSemantics(isImage: false));

      // And the argument is unchanged by its presence.
      expect(
        tester.getSemantics(find.text(_kTitle)).getSemanticsData().label,
        contains(_kTitle),
      );

      handle.dispose();
    });

    testWidgets('both controls keep the touch target floor', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        IuxPermissionRationale(
          moment: IuxBeforeAsking(ask: ask(), decline: decline()),
          title: _kTitle,
          reason: _kReason,
        ),
      );

      final BuildContext context =
          tester.element(find.byType(IuxPermissionRationale));
      final double floor = IuxAccessibility.of(context).minimumTouchTarget;

      // The refusal is held to the same floor as the request. An easy yes
      // beside a fiddly no is the manipulation this pattern refuses to make
      // possible.
      for (final Element element
          in tester.elementList(find.byType(IuxButton))) {
        expect(
          tester.getSize(find.byElementPredicate((Element e) => e == element)),
          isA<Size>().having(
            (Size size) => size.height,
            'height',
            greaterThanOrEqualTo(floor),
          ),
        );
      }
    });

    testWidgets('the two controls keep a gap between them', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        IuxPermissionRationale(
          moment: IuxBeforeAsking(ask: ask(), decline: decline()),
          title: _kTitle,
          reason: _kReason,
        ),
      );

      // WCAG SC 2.5.8 recognises that adjacent targets need spacing as well as
      // size: a finger landing near the seam between "Not now" and a request
      // has no margin for error, and here the two answers are opposites.
      //
      // Measured on whichever axis they ended up on. With real labels on a
      // 400-pixel screen the two controls do not fit side by side, so they take
      // a second line — which is the point of laying them out with
      // IuxTargetSpacing rather than a Row, and the separation is held either
      // way.
      final Rect no = tester.getRect(find.byType(IuxButton).at(0));
      final Rect forward = tester.getRect(find.byType(IuxButton).at(1));
      final double sideBySide = forward.left - no.right;
      final double stacked = forward.top - no.bottom;

      expect(
        sideBySide >= kIuxMinimumTargetSpacing ||
            stacked >= kIuxMinimumTargetSpacing,
        isTrue,
        reason: 'the refusal and the request are $sideBySide apart '
            'horizontally and $stacked apart vertically, and one of those has '
            'to clear $kIuxMinimumTargetSpacing.',
      );
    });
  });

  group('both answers stay reachable', () {
    /// The scales the audit measures, and the screen it measures them on.
    const List<double> scales = <double>[1, 1.5, 2, 3];
    const Size small = Size(320, 640);

    /// A block carrying what a real one carries, so the controls sit where a
    /// real one puts them: under a glyph, a title, a reason and a guidance.
    IuxPermissionRationale block({
      required VoidCallback onAsk,
      required VoidCallback onDecline,
    }) =>
        IuxPermissionRationale(
          moment: IuxBeforeAsking(
            ask: ask(onActivate: onAsk),
            decline: decline(onActivate: onDecline),
          ),
          title: _kTitle,
          reason: _kReason,
          guidance: _kGuidance,
          illustration: Icons.photo_camera_outlined,
        );

    /// One drag from the middle of the viewport, which is what a user does and
    /// is never on top of either control.
    ///
    /// Far enough to reach the end of any of these blocks; the physics clamp
    /// it.
    Future<void> dragToTheEnd(WidgetTester tester) async {
      await tester.dragFrom(const Offset(160, 320), const Offset(0, -3000));
      await tester.pumpAndSettle();
    }

    testWidgets(
        'the fold does not leave the user able to refuse and unable to '
        'accept', (WidgetTester tester) async {
      // The measured defect, at the scale it was measured on. The refusal is
      // laid out first, so when the block outgrows the viewport the fold falls
      // between the two controls: on 320×640 at 150% the refusal took its tap
      // and the request did not, which is a screen offering one answer.
      int asks = 0;
      int refusals = 0;
      await pump(
        tester,
        block(onAsk: () => asks++, onDecline: () => refusals++),
        textScale: 1.5,
        size: small,
      );

      final Finder refusal = find.byType(IuxButton).at(0);
      final Finder request = find.byType(IuxButton).at(1);

      // The refusal is where it always was: reachable without moving anything.
      expect(refusal.hitTestable(), findsOneWidget);
      await tester.tap(refusal);
      await tester.pump();
      expect(refusals, 1);

      // And the request is reachable too, because there is now something to
      // drag. Without it this is the point at which the user's only remaining
      // answer is no.
      await dragToTheEnd(tester);
      expect(request.hitTestable(), findsOneWidget);
      await tester.tap(request);
      await tester.pump();
      expect(asks, 1);
    });

    testWidgets(
        'both controls can be reached and pressed at 100, 150, 200 and '
        '300 per cent', (WidgetTester tester) async {
      for (final double scale in scales) {
        int asks = 0;
        int refusals = 0;
        await pump(
          tester,
          block(onAsk: () => asks++, onDecline: () => refusals++),
          textScale: scale,
          size: small,
        );

        // DebugOverflowIndicatorMixin reports an overflow once per render
        // object lifetime, so this assertion is only worth anything because
        // every case ends by tearing the tree down (IUX-QA-VACUOUS-003).
        expect(tester.takeException(), isNull, reason: 'at ${scale}x');
        expect(find.byType(Scrollable), findsOneWidget, reason: 'at ${scale}x');

        // The request is the lower of the two, so it is the one the fold takes
        // first; reaching it means the refusal above it is reachable as well.
        await dragToTheEnd(tester);
        final Finder request = find.byType(IuxButton).at(1);
        expect(request.hitTestable(), findsOneWidget, reason: 'at ${scale}x');
        await tester.tap(request);
        await tester.pump();
        expect(asks, 1, reason: 'at ${scale}x');

        final Finder refusal = find.byType(IuxButton).at(0);
        await tester.ensureVisible(refusal);
        await tester.pumpAndSettle();
        expect(refusal.hitTestable(), findsOneWidget, reason: 'at ${scale}x');
        await tester.tap(refusal);
        await tester.pump();
        expect(refusals, 1, reason: 'at ${scale}x');

        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets(
        'a caller who already scrolls does not get a second scroll '
        'view', (WidgetTester tester) async {
      // Every vertical scroll view hands its children an unbounded height, so
      // the block sees one and adds nothing. A sheet or a list that already
      // scrolls keeps exactly one scrollable region.
      final Map<String, Widget Function(Widget)> hosts =
          <String, Widget Function(Widget)>{
        'an IuxPage': (Widget child) => IuxPage(child: child),
        'a single-child scroll view': (Widget child) =>
            SingleChildScrollView(child: child),
        'a list': (Widget child) => ListView(children: <Widget>[child]),
        'a sliver list': (Widget child) => CustomScrollView(
              slivers: <Widget>[SliverToBoxAdapter(child: child)],
            ),
      };

      for (final MapEntry<String, Widget Function(Widget)> host
          in hosts.entries) {
        await pump(
          tester,
          host.value(block(onAsk: () {}, onDecline: () {})),
          textScale: 2,
          size: small,
        );

        expect(tester.takeException(), isNull, reason: 'inside ${host.key}');
        expect(
          find.byType(Scrollable),
          findsOneWidget,
          reason: 'inside ${host.key} there must be one scroll view, the '
              "caller's — a second one is a nested scrollable, which is its "
              'own defect',
        );

        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('a block that fits is not moved and takes no gesture', (
      WidgetTester tester,
    ) async {
      // The fix has to be invisible where there was nothing wrong.
      await pump(
        tester,
        block(onAsk: () {}, onDecline: () {}),
        size: small,
      );

      expect(
        tester
            .state<ScrollableState>(find.byType(Scrollable))
            .position
            .maxScrollExtent,
        0,
      );
      // And it still hugs its content rather than filling the box it was
      // given: this block is in a Center, and it is still centred.
      expect(
        tester.getRect(find.byType(IuxPermissionRationale)).center.dy,
        moreOrLessEquals(320, epsilon: 1),
      );
    });

    testWidgets('a block that does not fit reports something to scroll', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        block(onAsk: () {}, onDecline: () {}),
        textScale: 2,
        size: small,
      );

      expect(
        tester
            .state<ScrollableState>(find.byType(Scrollable))
            .position
            .maxScrollExtent,
        greaterThan(0),
      );
    });
  });

  group('layout under pressure', () {
    testWidgets('a long reason wraps rather than clipping', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        IuxPermissionRationale(
          moment: IuxBeforeAsking(ask: ask(), decline: decline()),
          title: _kTitle,
          reason: _kLongReason,
        ),
        size: const Size(320, 900),
      );

      // Half a reason is a reason the user cannot weigh, and a user who cannot
      // weigh a request refuses it.
      final Text text = tester.widget<Text>(find.text(_kLongReason));
      expect(text.maxLines, isNull);
      expect(text.overflow, isNot(TextOverflow.ellipsis));
      expect(tester.takeException(), isNull);
    });

    testWidgets('it survives 200% text on a small screen', (
      WidgetTester tester,
    ) async {
      // Standalone, in the bounded viewport, and that is the whole point of
      // this test. It used to wrap the block in a `SingleChildScrollView`,
      // which hands the column an unbounded height — so
      // `expect(takeException(), isNull)` could not fail, whatever the block
      // did. Rebuilt without it the assertion has teeth: remove the
      // `LayoutBuilder` that lets a bounded block scroll itself and this
      // reports `RenderFlex overflowed`. The already-scrolling arrangement has
      // its own test in "both answers stay reachable", which is also where
      // finding a control is shown not to be the same as pressing it
      // (IUX-QA-VACUOUS-003).
      await pump(
        tester,
        IuxPermissionRationale(
          moment: IuxBeforeAsking(ask: ask(), decline: decline()),
          title: _kTitle,
          reason: _kLongReason,
          guidance: _kGuidance,
          illustration: Icons.photo_camera_outlined,
        ),
        textScale: 2,
        size: const Size(320, 640),
      );

      expect(tester.takeException(), isNull);
      expect(find.text(_kLongReason), findsOneWidget);
      expect(
        tester.widget<Text>(find.text(_kLongReason)).overflow,
        isNot(TextOverflow.ellipsis),
      );
      // Both answers are still on screen at 200%: a request whose refusal has
      // been pushed off the layout is a request with one answer.
      expect(find.text(_kAskLabel), findsOneWidget);
      expect(find.text(_kDeclineLabel), findsOneWidget);
    });

    testWidgets('it lays out right to left without complaint', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        IuxPermissionRationale(
          moment: IuxBeforeAsking(ask: ask(), decline: decline()),
          title: _kTitle,
          reason: _kReason,
        ),
        direction: TextDirection.rtl,
      );

      expect(tester.takeException(), isNull);
      expect(find.text(_kTitle), findsOneWidget);
      expect(find.text(_kDeclineLabel), findsOneWidget);
    });

    testWidgets('it renders under every theme profile', (
      WidgetTester tester,
    ) async {
      for (final IuxThemeConfiguration configuration in <IuxThemeConfiguration>[
        const IuxThemeConfiguration(),
        const IuxThemeConfiguration(brightness: Brightness.dark),
        const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(contrast: IuxContrast.high),
        ),
        const IuxThemeConfiguration(
          brightness: Brightness.dark,
          profile: IuxAccessibilityProfile(contrast: IuxContrast.high),
        ),
      ]) {
        await pump(
          tester,
          IuxPermissionRationale(
            moment: IuxBeforeAsking(ask: ask(), decline: decline()),
            title: _kTitle,
            reason: _kReason,
          ),
          configuration: configuration,
        );

        expect(tester.takeException(), isNull);
        expect(find.text(_kReason), findsOneWidget);

        // DebugOverflowIndicatorMixin reports an overflow once per render
        // object lifetime, so without this every case after the first would
        // pass whatever it laid out (IUX-QA-VACUOUS-003).
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('it renders with motion switched off', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        IuxPermissionRationale(
          moment: IuxBeforeAsking(ask: ask(), decline: decline()),
          title: _kTitle,
          reason: _kReason,
        ),
        configuration: const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(motion: IuxMotionPreference.none),
        ),
      );

      // Nothing here animates, so there is nothing for the preference to
      // remove and nothing that was carrying information through movement.
      expect(tester.takeException(), isNull);
      expect(find.text(_kTitle), findsOneWidget);
      expect(find.text(_kAskLabel), findsOneWidget);
    });

    testWidgets('nothing animates on arrival', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: IuxTheme.fromConfiguration(const IuxThemeConfiguration()),
          home: Scaffold(
            body: IuxPermissionRationale(
              moment: IuxBeforeAsking(ask: ask(), decline: decline()),
              title: _kTitle,
              reason: _kReason,
            ),
          ),
        ),
      );

      // One frame is enough. An entrance animation would delay the announcement
      // to save nothing.
      expect(find.text(_kTitle), findsOneWidget);
      expect(find.text(_kAskLabel), findsOneWidget);
      expect(find.text(_kDeclineLabel), findsOneWidget);
    });
  });
}
