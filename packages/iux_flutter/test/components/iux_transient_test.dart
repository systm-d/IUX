import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

import '../support/contrast.dart';

/// The four conditions every IUX component is held to.
const List<IuxThemeConfiguration> _profiles = <IuxThemeConfiguration>[
  IuxThemeConfiguration(),
  IuxThemeConfiguration(brightness: Brightness.dark),
  IuxThemeConfiguration(
    profile: IuxAccessibilityProfile(contrast: IuxContrast.high),
  ),
  IuxThemeConfiguration(
    brightness: Brightness.dark,
    profile: IuxAccessibilityProfile(contrast: IuxContrast.high),
  ),
];

IuxThemeConfiguration _withMotion(IuxMotionPreference motion) =>
    IuxThemeConfiguration(profile: IuxAccessibilityProfile(motion: motion));

/// A message whose derived reading time falls on the floor: eleven characters
/// at ten per second is a second, and the floor is four.
const IuxTransientMessage _saved = IuxTransientMessage(
  text: 'Draft saved',
  dismissLabel: 'Dismiss the saved-draft notice',
  tone: IuxTransientTone.success,
);

const String _longText =
    'Your photographs finished uploading to the shared album, and everyone '
    'you invited to it can see them now.';

/// A host that owns the message, exactly as a real parent does.
///
/// The component never removes itself, so nothing here would ever disappear
/// without a parent that responds to `onDismissed` by clearing its own state.
class _Host extends StatefulWidget {
  const _Host({
    super.key,
    this.initial,
    this.minimumDwell,
    this.page,
    this.clearOnDismiss = true,
  });

  final IuxTransientMessage? initial;
  final Duration? minimumDwell;
  final Widget? page;
  final bool clearOnDismiss;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  IuxTransientMessage? _message;

  /// How many times the layer has asked to stop showing a message.
  int dismissed = 0;

  @override
  void initState() {
    super.initState();
    _message = widget.initial;
  }

  @override
  void didUpdateWidget(covariant _Host old) {
    super.didUpdateWidget(old);
    // Re-hosting with a different message adopts it, so a test that loops over
    // theme profiles is not left holding the message from the previous turn.
    if (widget.initial != old.initial) _message = widget.initial;
  }

  /// Shows [message], replacing whatever was there.
  void show(IuxTransientMessage message) => setState(() => _message = message);

  @override
  Widget build(BuildContext context) => IuxTransientLayer(
        message: _message,
        minimumDwell: widget.minimumDwell,
        onDismissed: () {
          dismissed++;
          if (widget.clearOnDismiss) setState(() => _message = null);
        },
        child: widget.page ?? const SizedBox.expand(),
      );
}

void main() {
  Future<void> host(
    WidgetTester tester, {
    IuxTransientMessage? message,
    GlobalKey<_HostState>? key,
    Duration? minimumDwell,
    Widget? page,
    bool clearOnDismiss = true,
    IuxThemeConfiguration configuration = const IuxThemeConfiguration(),
    TextDirection direction = TextDirection.ltr,
    double textScale = 1,
    bool accessibleNavigation = false,
    Size size = const Size(400, 800),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
          accessibleNavigation: accessibleNavigation,
        ),
        child: MaterialApp(
          // Keyed by configuration so switching profiles swaps the theme
          // outright rather than cross-fading between two of them.
          key: ValueKey<IuxThemeConfiguration>(configuration),
          theme: IuxTheme.fromConfiguration(configuration),
          home: Directionality(
            textDirection: direction,
            child: Scaffold(
              body: _Host(
                key: key,
                initial: message,
                minimumDwell: minimumDwell,
                page: page,
                clearOnDismiss: clearOnDismiss,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The dwell a message resolves to under given conditions, or null when it
  /// must not expire at all.
  Future<Duration?> dwellFor(
    WidgetTester tester,
    IuxTransientMessage message, {
    Duration? minimumDwell,
    bool accessibleNavigation = false,
  }) async {
    Duration? resolved;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(accessibleNavigation: accessibleNavigation),
        child: MaterialApp(
          theme: IuxTheme.light(),
          home: Builder(
            builder: (BuildContext context) {
              resolved = IuxTransientTiming.resolve(
                context,
                message,
                minimumDwell: minimumDwell,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return resolved;
  }

  /// The tokens a message would resolve under [configuration].
  Future<IuxTransientTokens> tokensFor(
    WidgetTester tester,
    IuxThemeConfiguration configuration,
    IuxTransientTone tone, {
    double textScale = 1,
  }) async {
    late IuxTransientTokens resolved;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: MaterialApp(
          key: ValueKey<IuxThemeConfiguration>(configuration),
          theme: IuxTheme.fromConfiguration(configuration),
          home: Builder(
            builder: (BuildContext context) {
              resolved = IuxTransientResolver.resolve(context, tone);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return resolved;
  }

  Finder tapTargetAround(Finder child) =>
      find.ancestor(of: child, matching: find.byType(IuxTapTarget));

  group('the channel refuses to carry anything a user needs', () {
    test('there is no failure tone and no warning tone', () {
      // The whole component rests on this. A failure that vanishes on a timer
      // is a failure the user cannot act on, and a warning about a consequence
      // is worse still because the consequence is still coming. Both belong in
      // an IuxAlert, which stays until the parent removes it.
      expect(IuxTransientTone.values, hasLength(2));
      expect(
        IuxTransientTone.values.map((IuxTransientTone t) => t.name),
        containsAll(<String>['neutral', 'success']),
      );
      expect(
        IuxTransientTone.values.map((IuxTransientTone t) => t.name),
        isNot(anyOf(contains('error'), contains('warning'))),
      );
    });

    test('a message with no words is rejected', () {
      expect(
        () => IuxTransientMessage(text: '', dismissLabel: 'Dismiss'),
        throwsAssertionError,
      );
    });

    test('a message with no named way out is rejected', () {
      expect(
        () => IuxTransientMessage(text: 'Draft saved', dismissLabel: ''),
        throwsAssertionError,
      );
    });

    test('an unlabelled action is rejected', () {
      expect(
        () => IuxTransientAction(label: '', onActivate: () {}),
        throwsAssertionError,
      );
      expect(
        () => IuxTransientAction(
          label: 'Undo',
          semanticLabel: '',
          onActivate: () {},
        ),
        throwsAssertionError,
      );
    });

    test('a non-positive dwell floor is rejected', () {
      expect(
        () => IuxTransientLayer(
          onDismissed: () {},
          minimumDwell: Duration.zero,
          child: const SizedBox.shrink(),
        ),
        throwsAssertionError,
      );
    });

    test('nothing in this component announces through the platform', () {
      // The live region is the only channel. IuxAnnouncement clears TalkBack's
      // speech queue on Android, and a message that is on screen has no
      // business interrupting a sentence the user chose to listen to.
      final List<String> offenders = <String>[];
      for (final FileSystemEntity entity
          in Directory('lib/src/components/transient').listSync()) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final String source = entity.readAsStringSync();
        if (source.contains('IuxAnnouncement') ||
            source.contains('SemanticsService')) {
          offenders.add(entity.path);
        }
      }
      expect(offenders, isEmpty);
    });
  });

  group('the clock is derived from the message, never fixed', () {
    test('a message never stays less than the floor', () {
      expect(IuxTransientTiming.readingTime('OK'), IuxTransientTiming.minimum);
      expect(
        IuxTransientTiming.readingTime('Draft saved'),
        IuxTransientTiming.minimum,
      );
    });

    test('a longer sentence is given longer', () {
      final Duration short = IuxTransientTiming.readingTime('Draft saved');
      final Duration long = IuxTransientTiming.readingTime(_longText);
      expect(long, greaterThan(short));
      expect(long, greaterThan(IuxTransientTiming.minimum));
    });

    test('the rate is characters per second, and there is no ceiling', () {
      final String enormous = 'a' * 4000;
      expect(
        IuxTransientTiming.readingTime(enormous).inSeconds,
        4000 ~/ IuxTransientTiming.charactersPerSecond,
      );
    });

    testWidgets('a message leaves once its reading time has passed',
        (WidgetTester tester) async {
      final GlobalKey<_HostState> key = GlobalKey<_HostState>();
      await host(tester, message: _saved, key: key);

      expect(find.text('Draft saved'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      expect(
        find.text('Draft saved'),
        findsOneWidget,
        reason: 'it left before the floor had passed',
      );

      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Draft saved'), findsNothing);
      expect(key.currentState!.dismissed, 1);
    });

    testWidgets('and it asks to be removed exactly once',
        (WidgetTester tester) async {
      final GlobalKey<_HostState> key = GlobalKey<_HostState>();
      await host(tester, message: _saved, key: key, clearOnDismiss: false);

      await tester.pump(const Duration(seconds: 30));
      expect(key.currentState!.dismissed, 1);
    });

    testWidgets('a long sentence stays longer than a short one',
        (WidgetTester tester) async {
      await host(
        tester,
        message: const IuxTransientMessage(
          text: _longText,
          dismissLabel: 'Dismiss the upload notice',
        ),
      );

      await tester.pump(const Duration(seconds: 5));
      expect(
        find.text(_longText),
        findsOneWidget,
        reason: 'a message that takes nine seconds to read left after five',
      );

      await tester.pump(const Duration(seconds: 6));
      expect(find.text(_longText), findsNothing);
    });
  });

  group('the clock stops for the people a clock hurts most', () {
    testWidgets('an action removes the deadline outright',
        (WidgetTester tester) async {
      // "Undo" that expires is undo for fast people. Rather than tune a
      // duration that some users will always lose, the deadline is removed:
      // there is no race, so nobody can lose it.
      expect(
        await dwellFor(
          tester,
          IuxTransientMessage(
            text: 'Invoice deleted',
            dismissLabel: 'Dismiss the deleted-invoice notice',
            action: IuxTransientAction(label: 'Undo', onActivate: () {}),
          ),
        ),
        isNull,
      );
    });

    testWidgets('and the message really does stay',
        (WidgetTester tester) async {
      final GlobalKey<_HostState> key = GlobalKey<_HostState>();
      await host(
        tester,
        key: key,
        message: IuxTransientMessage(
          text: 'Invoice deleted',
          dismissLabel: 'Dismiss the deleted-invoice notice',
          action: IuxTransientAction(label: 'Undo', onActivate: () {}),
        ),
      );

      await tester.pump(const Duration(minutes: 5));

      expect(find.text('Invoice deleted'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      expect(key.currentState!.dismissed, 0);
    });

    testWidgets('an expected screen reader removes the deadline',
        (WidgetTester tester) async {
      // A live region is queued behind whatever the platform is already
      // speaking, so a clock started when the message is painted measures
      // nothing for that user — and content reached by navigating to it cannot
      // be reached once it has gone.
      expect(
        await dwellFor(tester, _saved, accessibleNavigation: true),
        isNull,
      );
    });

    testWidgets('and the message stays for as long as they need',
        (WidgetTester tester) async {
      final GlobalKey<_HostState> key = GlobalKey<_HostState>();
      await host(
        tester,
        message: _saved,
        key: key,
        accessibleNavigation: true,
      );

      await tester.pump(const Duration(minutes: 5));

      expect(find.text('Draft saved'), findsOneWidget);
      expect(key.currentState!.dismissed, 0);
    });

    testWidgets('touching the message stops the clock',
        (WidgetTester tester) async {
      await host(tester, message: _saved);

      final TestGesture gesture =
          await tester.startGesture(tester.getCenter(find.text('Draft saved')));
      await tester.pump(const Duration(seconds: 30));
      expect(find.text('Draft saved'), findsOneWidget);

      await gesture.up();
      await tester.pump();

      // Restarted from the beginning rather than resumed: someone who held the
      // message and let go has lost their place, and handing back the last
      // three hundred milliseconds hands back nothing.
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Draft saved'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Draft saved'), findsNothing);
    });

    testWidgets('focusing a control inside it stops the clock',
        (WidgetTester tester) async {
      // This is what stops a keyboard user being stranded: the message cannot
      // vanish while they are standing on it.
      await host(tester, message: _saved);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 30));
      expect(find.text('Draft saved'), findsOneWidget);
    });

    testWidgets('leaving it again restarts the clock',
        (WidgetTester tester) async {
      await host(tester, message: _saved);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 10));
      expect(find.text('Draft saved'), findsOneWidget);

      FocusManager.instance.primaryFocus!.unfocus();
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Draft saved'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Draft saved'), findsNothing);
    });

    testWidgets('minimumDwell raises the floor', (WidgetTester tester) async {
      expect(
        await dwellFor(
          tester,
          _saved,
          minimumDwell: const Duration(seconds: 12),
        ),
        const Duration(seconds: 12),
      );
    });

    testWidgets('minimumDwell below the derived reading time is ignored',
        (WidgetTester tester) async {
      // There is deliberately no parameter anywhere that can shorten a dwell.
      expect(
        await dwellFor(
          tester,
          const IuxTransientMessage(
            text: _longText,
            dismissLabel: 'Dismiss the upload notice',
          ),
          minimumDwell: const Duration(seconds: 1),
        ),
        IuxTransientTiming.readingTime(_longText),
      );
    });

    testWidgets('a raised floor is observed on screen',
        (WidgetTester tester) async {
      await host(
        tester,
        message: _saved,
        minimumDwell: const Duration(seconds: 12),
      );

      await tester.pump(const Duration(seconds: 6));
      expect(find.text('Draft saved'), findsOneWidget);

      await tester.pump(const Duration(seconds: 7));
      expect(find.text('Draft saved'), findsNothing);
    });
  });

  group('there is no queue, and the second message wins', () {
    testWidgets('a second message replaces the first',
        (WidgetTester tester) async {
      final GlobalKey<_HostState> key = GlobalKey<_HostState>();
      await host(tester, message: _saved, key: key);

      key.currentState!.show(
        const IuxTransientMessage(
          text: 'Reconnected',
          dismissLabel: 'Dismiss the connection notice',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Draft saved'), findsNothing);
      expect(find.text('Reconnected'), findsOneWidget);
      expect(
        find.byIcon(Icons.close),
        findsOneWidget,
        reason: 'two messages on screen at once is a queue by accident',
      );
    });

    testWidgets('the replacement gets its own full reading time',
        (WidgetTester tester) async {
      final GlobalKey<_HostState> key = GlobalKey<_HostState>();
      await host(tester, message: _saved, key: key);

      await tester.pump(const Duration(seconds: 3));
      key.currentState!.show(
        const IuxTransientMessage(
          text: 'Reconnected',
          dismissLabel: 'Dismiss the connection notice',
        ),
      );
      await tester.pump();

      await tester.pump(const Duration(seconds: 3));
      expect(
        find.text('Reconnected'),
        findsOneWidget,
        reason: 'the replacement inherited what was left of the first clock',
      );

      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Reconnected'), findsNothing);
    });

    testWidgets('the same message shown again does not restart the clock',
        (WidgetTester tester) async {
      // Without this, a parent that rebuilds every frame would hold a message
      // on screen forever, one restarted countdown at a time.
      final GlobalKey<_HostState> key = GlobalKey<_HostState>();
      await host(tester, message: _saved, key: key);

      await tester.pump(const Duration(seconds: 3));
      key.currentState!.show(
        const IuxTransientMessage(
          text: 'Draft saved',
          dismissLabel: 'Dismiss the saved-draft notice',
          tone: IuxTransientTone.success,
        ),
      );
      await tester.pump();

      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Draft saved'), findsNothing);
    });

    test('a message knows when another says the same thing', () {
      const IuxTransientMessage relabelled = IuxTransientMessage(
        text: 'Draft saved',
        dismissLabel: 'Close',
        tone: IuxTransientTone.success,
      );
      expect(_saved.saysTheSameAs(relabelled), isTrue);

      expect(
        _saved.saysTheSameAs(
          const IuxTransientMessage(
            text: 'Draft saved',
            dismissLabel: 'Dismiss the saved-draft notice',
          ),
        ),
        isFalse,
        reason: 'a different tone is a different message',
      );

      expect(
        _saved.saysTheSameAs(
          IuxTransientMessage(
            text: 'Draft saved',
            dismissLabel: 'Dismiss the saved-draft notice',
            tone: IuxTransientTone.success,
            action: IuxTransientAction(label: 'Undo', onActivate: () {}),
          ),
        ),
        isFalse,
        reason: 'gaining an action changes whether the message expires at all',
      );
    });
  });

  group('it never takes focus, and never blocks the page', () {
    testWidgets('appearing does not move focus', (WidgetTester tester) async {
      // Moving focus onto something that is about to vanish strands the user
      // it moved.
      final GlobalKey<_HostState> key = GlobalKey<_HostState>();
      await host(
        tester,
        key: key,
        page: const Focus(autofocus: true, child: SizedBox.expand()),
      );

      final FocusNode? before = FocusManager.instance.primaryFocus;
      expect(before, isNotNull);

      key.currentState!.show(_saved);
      await tester.pumpAndSettle();

      expect(FocusManager.instance.primaryFocus, same(before));
      expect(find.text('Draft saved'), findsOneWidget);
    });

    testWidgets('the page behind it stays operable',
        (WidgetTester tester) async {
      int pressed = 0;
      await host(
        tester,
        message: _saved,
        page: Align(
          alignment: Alignment.topCenter,
          child: IuxButton(
            label: 'Save',
            action: const IuxActionDescriptor(
              semantics: IuxActionSemantics(label: 'Save'),
            ),
            onActivate: () => pressed++,
          ),
        ),
      );

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(pressed, 1);
    });

    testWidgets('the page behind it stays in the semantic tree',
        (WidgetTester tester) async {
      // Unlike a dialog, this blocks nothing: a message nobody has to read may
      // not remove the page from under a screen-reader user.
      await host(
        tester,
        message: _saved,
        page: Align(
          alignment: Alignment.topCenter,
          child: IuxButton(
            label: 'Save',
            action: const IuxActionDescriptor(
              semantics: IuxActionSemantics(label: 'Save'),
            ),
            onActivate: () {},
          ),
        ),
      );

      expect(find.bySemanticsLabel('Save'), findsOneWidget);
    });

    testWidgets('both controls are reachable and activatable by keyboard',
        (WidgetTester tester) async {
      final GlobalKey<_HostState> key = GlobalKey<_HostState>();
      int undone = 0;
      await host(
        tester,
        key: key,
        clearOnDismiss: false,
        message: IuxTransientMessage(
          text: 'Invoice deleted',
          dismissLabel: 'Dismiss the deleted-invoice notice',
          action: IuxTransientAction(
            label: 'Undo',
            onActivate: () => undone++,
          ),
        ),
      );

      for (int stop = 0; stop < 2; stop++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
      }

      expect(undone, 1, reason: 'the action was never reached');
      expect(
        key.currentState!.dismissed,
        1,
        reason: 'the way out was never reached',
      );
    });
  });

  group('it is announced in place, once', () {
    testWidgets('the message is one live region labelled with its sentence',
        (WidgetTester tester) async {
      await host(tester, message: _saved);

      final SemanticsNode node =
          tester.getSemantics(find.bySemanticsLabel('Draft saved'));
      expect(node.flagsCollection.isLiveRegion, isTrue);
    });

    testWidgets('the tone is not spoken, because it says nothing',
        (WidgetTester tester) async {
      // An IuxAlert requires a localised category word. This does not, and the
      // absence is the design: a message whose category the user needs to hear
      // is a message that must not disappear.
      await host(tester, message: _saved);

      final SemanticsNode node =
          tester.getSemantics(find.bySemanticsLabel('Draft saved'));
      expect(node.label, 'Draft saved');
    });

    testWidgets('the visible text is not a second stop in the reading order',
        (WidgetTester tester) async {
      // The words are already the live region's label. Left in the tree as a
      // node of their own they would be read a second time, and the user would
      // swipe through the same sentence twice.
      await host(tester, message: _saved);

      expect(find.text('Draft saved'), findsOneWidget);
      expect(find.bySemanticsLabel('Draft saved'), findsOneWidget);
    });

    testWidgets('it emits nothing: no feedback scope, no haptic',
        (WidgetTester tester) async {
      // A message the user can see has no business vibrating a phone. The
      // parent emits feedback if it wants any; IuxFeedbackScope.of throws when
      // missing, so rendering without one is proof that nothing is emitted.
      final List<MethodCall> platform = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform,
              (MethodCall call) async {
        platform.add(call);
        return null;
      });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );

      await host(
        tester,
        clearOnDismiss: false,
        message: IuxTransientMessage(
          text: 'Invoice deleted',
          dismissLabel: 'Dismiss the deleted-invoice notice',
          action: IuxTransientAction(label: 'Undo', onActivate: () {}),
        ),
      );
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        platform.where((MethodCall c) => c.method.startsWith('HapticFeedback')),
        isEmpty,
      );
    });
  });

  group('the parent owns whether the message exists', () {
    testWidgets('dismissing reports to the parent and removes nothing itself',
        (WidgetTester tester) async {
      final GlobalKey<_HostState> key = GlobalKey<_HostState>();
      await host(tester, message: _saved, key: key, clearOnDismiss: false);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(key.currentState!.dismissed, 1);
      expect(
        find.text('Draft saved'),
        findsOneWidget,
        reason: 'the component removed itself instead of asking',
      );
    });

    testWidgets('the action reports and leaves the message where it is',
        (WidgetTester tester) async {
      int undone = 0;
      await host(
        tester,
        message: IuxTransientMessage(
          text: 'Invoice deleted',
          dismissLabel: 'Dismiss the deleted-invoice notice',
          action: IuxTransientAction(
            label: 'Undo',
            onActivate: () => undone++,
          ),
        ),
      );

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(undone, 1);
      expect(find.text('Invoice deleted'), findsOneWidget);
    });

    testWidgets('a terse action can announce a longer name',
        (WidgetTester tester) async {
      await host(
        tester,
        message: IuxTransientMessage(
          text: 'Invoice deleted',
          dismissLabel: 'Dismiss the deleted-invoice notice',
          action: IuxTransientAction(
            label: 'Undo',
            semanticLabel: 'Undo deleting the March invoice',
            onActivate: () {},
          ),
        ),
      );

      expect(find.text('Undo'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Undo deleting the March invoice'),
        findsOneWidget,
      );
    });

    testWidgets('the way out says what disappears',
        (WidgetTester tester) async {
      await host(tester, message: _saved);
      expect(
        find.bySemanticsLabel('Dismiss the saved-draft notice'),
        findsOneWidget,
        reason: 'an unnamed close control reaches a screen reader as "button"',
      );
    });
  });

  group('it holds up under the conditions users actually have', () {
    testWidgets('a long sentence wraps rather than being truncated',
        (WidgetTester tester) async {
      await host(
        tester,
        message: const IuxTransientMessage(
          text: _longText,
          dismissLabel: 'Dismiss the upload notice',
        ),
        size: const Size(320, 640),
      );

      expect(tester.takeException(), isNull);
      final Text text = tester.widget<Text>(find.text(_longText));
      expect(text.maxLines, isNull);
      expect(text.overflow, isNot(TextOverflow.ellipsis));
    });

    testWidgets('a 200% text scale on a small screen clips nothing',
        (WidgetTester tester) async {
      await host(
        tester,
        message: IuxTransientMessage(
          text: 'Invoice deleted',
          dismissLabel: 'Dismiss the deleted-invoice notice',
          action: IuxTransientAction(label: 'Undo', onActivate: () {}),
        ),
        textScale: 2,
        size: const Size(320, 480),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Undo'), findsOneWidget);

      final Rect target = tester.getRect(tapTargetAround(find.text('Undo')));
      expect(target.left, greaterThanOrEqualTo(0));
      expect(target.right, lessThanOrEqualTo(320));
    });

    testWidgets('and does not push the way out off the screen',
        (WidgetTester tester) async {
      await host(
        tester,
        message: const IuxTransientMessage(
          text: 'Your photographs finished uploading.',
          dismissLabel: 'Dismiss the upload notice',
        ),
        textScale: 2,
        size: const Size(320, 480),
      );

      final Rect target =
          tester.getRect(tapTargetAround(find.byIcon(Icons.close)));
      expect(target.left, greaterThanOrEqualTo(0));
      expect(target.right, lessThanOrEqualTo(320));
    });

    testWidgets('both controls meet the touch target floor',
        (WidgetTester tester) async {
      await host(
        tester,
        message: IuxTransientMessage(
          text: 'Invoice deleted',
          dismissLabel: 'Dismiss the deleted-invoice notice',
          action: IuxTransientAction(label: 'Undo', onActivate: () {}),
        ),
      );

      for (final Finder finder in <Finder>[
        tapTargetAround(find.byIcon(Icons.close)),
        tapTargetAround(find.text('Undo')),
      ]) {
        final Size size = tester.getSize(finder);
        expect(size.width, greaterThanOrEqualTo(IuxTouchTarget.minimum));
        expect(size.height, greaterThanOrEqualTo(IuxTouchTarget.minimum));
      }
    });

    testWidgets('it renders right-to-left', (WidgetTester tester) async {
      await host(
        tester,
        direction: TextDirection.rtl,
        message: IuxTransientMessage(
          text: 'تم حفظ المسودة',
          dismissLabel: 'إغلاق إشعار الحفظ',
          tone: IuxTransientTone.success,
          action: IuxTransientAction(label: 'تراجع', onActivate: () {}),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('تراجع'), findsOneWidget);

      // Mirrored by the framework rather than by hand: a Row lays out in
      // reading order, so an Arabic interface gets the glyph on the right
      // without the widget knowing which language it is in.
      final double glyph =
          tester.getCenter(find.byIcon(Icons.check_circle_outline)).dx;
      final double close = tester.getCenter(find.byIcon(Icons.close)).dx;
      expect(glyph, greaterThan(close));
    });

    testWidgets('it sits above the bottom system inset',
        (WidgetTester tester) async {
      await host(tester, message: _saved);
      final Rect message = tester.getRect(find.text('Draft saved'));
      expect(message.bottom, lessThan(800));
    });

    testWidgets('it renders on every theme profile',
        (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in _profiles) {
        for (final IuxTransientTone tone in IuxTransientTone.values) {
          await host(
            tester,
            configuration: configuration,
            message: IuxTransientMessage(
              text: 'A sentence about ${tone.name}.',
              dismissLabel: 'Dismiss the ${tone.name} notice',
              tone: tone,
            ),
          );
          expect(tester.takeException(), isNull, reason: '$configuration');
          expect(find.text('A sentence about ${tone.name}.'), findsOneWidget);
        }
      }
    });
  });

  group('every colour is measured against the surface it sits on', () {
    testWidgets('the sentence is readable on its own surface',
        (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in _profiles) {
        for (final IuxTransientTone tone in IuxTransientTone.values) {
          final IuxTransientTokens tokens =
              await tokensFor(tester, configuration, tone);
          for (final TextStyle style in <TextStyle>[
            tokens.messageStyle,
            tokens.actionStyle,
          ]) {
            expect(
              ContrastMetric.ratio(style.color!, tokens.surface),
              greaterThanOrEqualTo(ContrastMetric.normalText),
              reason: '${tone.name} on $configuration',
            );
          }
        }
      }
    });

    testWidgets('the tone glyph is distinguishable on its own surface',
        (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in _profiles) {
        final IuxTransientTokens tokens = await tokensFor(
          tester,
          configuration,
          IuxTransientTone.success,
        );
        expect(tokens.glyph, isNotNull);
        expect(
          ContrastMetric.ratio(tokens.icon, tokens.surface),
          greaterThanOrEqualTo(ContrastMetric.nonText),
          reason: '$configuration',
        );
      }
    });

    testWidgets('the neutral tone claims nothing, so it carries no glyph',
        (WidgetTester tester) async {
      final IuxTransientTokens tokens = await tokensFor(
        tester,
        const IuxThemeConfiguration(),
        IuxTransientTone.neutral,
      );
      expect(tokens.glyph, isNull);
    });

    testWidgets('the outline separates the message from the page behind it',
        (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in _profiles) {
        final Color page = IuxTheme.fromConfiguration(configuration)
            .extension<IuxSemanticColors>()!
            .surface
            .base;
        for (final IuxTransientTone tone in IuxTransientTone.values) {
          final IuxTransientTokens tokens =
              await tokensFor(tester, configuration, tone);
          expect(
            ContrastMetric.ratio(tokens.border, page),
            greaterThanOrEqualTo(ContrastMetric.nonText),
            reason: '${tone.name} on $configuration',
          );
        }
      }
    });

    testWidgets('the outline is the strong one, because it floats over content',
        (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in _profiles) {
        final IuxGeometryTheme geometry =
            IuxTheme.fromConfiguration(configuration)
                .extension<IuxGeometryTheme>()!;
        final IuxTransientTokens tokens =
            await tokensFor(tester, configuration, IuxTransientTone.neutral);
        expect(tokens.borderWidth, geometry.strongBorderWidth);
        expect(tokens.borderWidth, greaterThan(geometry.borderWidth));
      }
    });

    testWidgets('enlarged text enlarges the glyph with it',
        (WidgetTester tester) async {
      final IuxTransientTokens standard = await tokensFor(
        tester,
        const IuxThemeConfiguration(),
        IuxTransientTone.success,
      );
      final IuxTransientTokens enlarged = await tokensFor(
        tester,
        const IuxThemeConfiguration(),
        IuxTransientTone.success,
        textScale: 2,
      );
      expect(enlarged.iconSize, greaterThan(standard.iconSize));
    });
  });

  group('motion explains the arrival and carries nothing', () {
    testWidgets(
        'a reduced preference shortens the entrance without removing it',
        (WidgetTester tester) async {
      final IuxTransientTokens full = await tokensFor(
        tester,
        _withMotion(IuxMotionPreference.standard),
        IuxTransientTone.neutral,
      );
      final IuxTransientTokens reduced = await tokensFor(
        tester,
        _withMotion(IuxMotionPreference.reduced),
        IuxTransientTone.neutral,
      );

      expect(reduced.entrance.duration, greaterThan(Duration.zero));
      expect(reduced.entrance.duration, lessThan(full.entrance.duration));
    });

    testWidgets('no motion shows the message immediately',
        (WidgetTester tester) async {
      // Nothing is lost: the sentence is the message, and it was never the
      // fade that carried it.
      await host(
        tester,
        message: _saved,
        configuration: _withMotion(IuxMotionPreference.none),
      );

      final FadeTransition fade = tester.widget<FadeTransition>(
        find
            .ancestor(
              of: find.text('Draft saved'),
              matching: find.byType(FadeTransition),
            )
            .first,
      );
      expect(fade.opacity.value, 1);
      expect(find.text('Draft saved'), findsOneWidget);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });
}
