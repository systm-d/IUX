import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

/// The mutable state the host page and the assertions share.
///
/// The parent owns whether the dialog is open, which is the whole point of the
/// component: the test plays the parent so the assertions can check that the
/// dialog never takes that decision for itself.
class _Scenario {
  bool open = false;
  int dismissals = 0;
  final List<String> chosen = <String>[];
  final FocusNode background = FocusNode(debugLabel: 'background');
  final FocusNode elsewhere = FocusNode(debugLabel: 'elsewhere');
  late StateSetter setHostState;

  void setOpen(bool value) => setHostState(() => open = value);
}

void main() {
  const String title = 'Delete this invoice?';
  const String shortMessage =
      'The invoice and its attachments are removed permanently.';
  const String longMessage =
      'The invoice, its attachments, the payment reminders sent for it and '
      'every note recorded against it are removed permanently from this '
      'workspace and from the exports already scheduled for the end of the '
      'month. Nobody in the team will be able to restore them afterwards.';

  const IuxActionDescriptor deleteAction = IuxActionDescriptor.destructive(
    semantics: IuxActionSemantics(label: 'Delete the March invoice'),
  );

  Future<_Scenario> pump(
    WidgetTester tester, {
    bool open = false,
    IuxThemeConfiguration configuration = const IuxThemeConfiguration(),
    TextDirection direction = TextDirection.ltr,
    double textScale = 1,
    Size size = const Size(400, 800),
    String message = shortMessage,
    String dismissLabel = 'Keep it',
    IuxActionDescriptor choice = deleteAction,
    String choiceLabel = 'Delete',
    bool withChoice = true,
    Widget? content,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final _Scenario scenario = _Scenario()..open = open;
    addTearDown(scenario.background.dispose);
    addTearDown(scenario.elsewhere.dispose);

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
            child: Scaffold(
              body: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  scenario.setHostState = setState;
                  return IuxModalLayer(
                    dialog: scenario.open
                        ? IuxDialog(
                            title: title,
                            message: message,
                            dismissLabel: dismissLabel,
                            content: content,
                            onDismiss: () => scenario.dismissals++,
                            actions: <IuxDialogAction>[
                              if (withChoice)
                                IuxDialogAction(
                                  label: choiceLabel,
                                  action: choice,
                                  onActivate: () =>
                                      scenario.chosen.add(choiceLabel),
                                ),
                            ],
                          )
                        : null,
                    child: IuxPage(
                      child: Column(
                        children: <Widget>[
                          IuxButton(
                            label: 'Open',
                            action: const IuxActionDescriptor(
                              semantics: IuxActionSemantics(label: 'Open'),
                            ),
                            focusNode: scenario.background,
                            onActivate: () {},
                          ),
                          IuxButton(
                            label: 'Elsewhere',
                            action: const IuxActionDescriptor(
                              semantics: IuxActionSemantics(label: 'Elsewhere'),
                            ),
                            focusNode: scenario.elsewhere,
                            onActivate: () {},
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return scenario;
  }

  /// Whether whatever holds focus right now is inside the dialog.
  bool focusIsInsideDialog() {
    final BuildContext? focused = FocusManager.instance.primaryFocus?.context;
    if (focused == null) return false;
    return focused.findAncestorWidgetOfExactType<IuxDialog>() != null;
  }

  /// The nearest ancestor semantics node of [finder] that scopes a route.
  SemanticsNode? routeNodeAbove(WidgetTester tester, Finder finder) {
    SemanticsNode? node = tester.getSemantics(finder);
    while (node != null && !node.flagsCollection.scopesRoute) {
      node = node.parent;
    }
    return node;
  }

  /// The accessible names of every control announced under [root].
  List<String> buttonLabelsUnder(SemanticsNode root) {
    final List<String> labels = <String>[];
    void visit(SemanticsNode node) {
      if (node.flagsCollection.isButton) labels.add(node.label);
      node.visitChildren((SemanticsNode child) {
        visit(child);
        return true;
      });
    }

    visit(root);
    return labels;
  }

  group('focus, which is what decides whether the dialog is usable at all', () {
    testWidgets('opening the dialog moves focus into it',
        (WidgetTester tester) async {
      final _Scenario scenario = await pump(tester);
      scenario.background.requestFocus();
      await tester.pump();
      expect(scenario.background.hasFocus, isTrue);

      scenario.setOpen(true);
      await tester.pumpAndSettle();

      expect(scenario.background.hasFocus, isFalse);
      expect(focusIsInsideDialog(), isTrue);
    });

    testWidgets(
        'focus does not land on a choice, so an unread dialog cannot '
        'be confirmed by a keypress already in flight',
        (WidgetTester tester) async {
      await pump(tester, open: true);

      final BuildContext focused = FocusManager.instance.primaryFocus!.context!;
      expect(
        focused.findAncestorWidgetOfExactType<IuxButton>(),
        isNull,
        reason: 'focus landed on a button; Enter would confirm it',
      );
    });

    testWidgets('the keyboard cannot leave the dialog',
        (WidgetTester tester) async {
      final _Scenario scenario = await pump(tester, open: true);

      for (int press = 1; press <= 8; press++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(
          scenario.background.hasFocus,
          isFalse,
          reason: 'focus reached the blocked page after $press tabs',
        );
        expect(
          focusIsInsideDialog(),
          isTrue,
          reason: 'focus left the dialog after $press tabs',
        );
      }
    });

    testWidgets('every choice in the dialog is reachable by keyboard',
        (WidgetTester tester) async {
      await pump(tester, open: true);

      final Set<String> reached = <String>{};
      for (int press = 0; press < 6; press++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final BuildContext focused =
            FocusManager.instance.primaryFocus!.context!;
        final IuxButton? button =
            focused.findAncestorWidgetOfExactType<IuxButton>();
        if (button != null) reached.add(button.label);
      }

      expect(reached, containsAll(<String>['Keep it', 'Delete']));
    });

    testWidgets('closing the dialog returns focus to what held it before',
        (WidgetTester tester) async {
      // Without this, every dialog drops a keyboard or screen-reader user back
      // at the top of the page they were half way through.
      final _Scenario scenario = await pump(tester);
      scenario.background.requestFocus();
      await tester.pump();

      scenario.setOpen(true);
      await tester.pumpAndSettle();
      expect(scenario.background.hasFocus, isFalse);

      scenario.setOpen(false);
      await tester.pumpAndSettle();

      expect(scenario.background.hasFocus, isTrue);
    });

    testWidgets(
        'focus returns to where the user was, not to wherever it '
        'drifted while the dialog was open', (WidgetTester tester) async {
      // The blocked page keeps rebuilding underneath — a stream arrives, a
      // field autofocuses — and can take focus programmatically even though
      // the user cannot reach it. Returning them to that widget would leave
      // them somewhere they never went.
      final _Scenario scenario = await pump(tester);
      scenario.background.requestFocus();
      await tester.pump();

      scenario.setOpen(true);
      await tester.pumpAndSettle();

      scenario.elsewhere.requestFocus();
      await tester.pump();
      expect(scenario.elsewhere.hasFocus, isTrue);

      scenario.setOpen(false);
      await tester.pumpAndSettle();

      expect(scenario.background.hasFocus, isTrue);
      expect(scenario.elsewhere.hasFocus, isFalse);
    });
  });

  group('there is always a way out, and they all mean the same thing', () {
    testWidgets('Escape dismisses', (WidgetTester tester) async {
      final _Scenario scenario = await pump(tester, open: true);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(scenario.dismissals, 1);
      expect(scenario.chosen, isEmpty);
    });

    testWidgets('a tap on the scrim dismisses', (WidgetTester tester) async {
      final _Scenario scenario = await pump(tester, open: true);

      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();

      expect(scenario.dismissals, 1);
    });

    testWidgets('the dismissal button dismisses', (WidgetTester tester) async {
      final _Scenario scenario = await pump(tester, open: true);

      await tester.tap(find.text('Keep it'));
      await tester.pumpAndSettle();

      expect(scenario.dismissals, 1);
    });

    testWidgets('a tap inside the dialog is not a dismissal',
        (WidgetTester tester) async {
      // Otherwise a tap that lands on the panel's padding closes the dialog
      // the user was still reading.
      final _Scenario scenario = await pump(tester, open: true);

      await tester.tap(find.text(title));
      await tester.pumpAndSettle();

      expect(scenario.dismissals, 0);
    });

    testWidgets(
        'a dialog with no choices is an acknowledgement, and its one '
        'button is still the way out', (WidgetTester tester) async {
      final _Scenario scenario = await pump(
        tester,
        open: true,
        withChoice: false,
        dismissLabel: 'Got it',
      );

      expect(find.text('Delete'), findsNothing);
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();

      expect(scenario.dismissals, 1);
    });

    testWidgets('Escape still dismisses once focus has moved to a choice',
        (WidgetTester tester) async {
      final _Scenario scenario = await pump(tester, open: true);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(scenario.dismissals, 1);
    });
  });

  group('the parent owns the outcome', () {
    testWidgets('taking a choice reports it and performs nothing',
        (WidgetTester tester) async {
      final _Scenario scenario = await pump(tester, open: true);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(scenario.chosen, <String>['Delete']);
      expect(scenario.dismissals, 0);
      expect(
        find.byType(IuxDialog),
        findsOneWidget,
        reason: 'the dialog closed itself; only the parent may close it',
      );
    });

    testWidgets('an unavailable choice reports nothing',
        (WidgetTester tester) async {
      final _Scenario scenario = await pump(
        tester,
        open: true,
        choice: const IuxActionDescriptor(
          semantics: IuxActionSemantics(
            label: 'Delete the March invoice',
            unavailabilityReason: 'The invoice is already paid',
          ),
          intent: IuxActionIntent.destructive,
          availability: IuxActionAvailability.disabled,
        ),
      );

      await tester.tap(find.text('Delete'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(scenario.chosen, isEmpty);
    });

    testWidgets('the page it interrupts stays behind it',
        (WidgetTester tester) async {
      // A layer, not a route: the parent's page is covered, never replaced.
      await pump(tester, open: true);

      expect(find.byType(IuxPage), findsOneWidget);
    });
  });

  group('assistive technology is told a dialog appeared', () {
    testWidgets('it scopes and names a route', (WidgetTester tester) async {
      await pump(tester, open: true);

      final SemanticsNode? route = routeNodeAbove(tester, find.text(title));

      expect(route, isNotNull);
      expect(route!.flagsCollection.namesRoute, isTrue);
      expect(
        route.label,
        contains(title),
        reason: 'the route is scoped but unnamed, so nothing is announced',
      );
    });

    testWidgets('the page behind it leaves the semantic tree',
        (WidgetTester tester) async {
      // A control that reads out but no longer responds is worse than one that
      // is gone.
      final _Scenario scenario = await pump(tester);
      expect(find.bySemanticsLabel('Open'), findsOneWidget);

      scenario.setOpen(true);
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Open'), findsNothing);
    });

    testWidgets('the page returns to the semantic tree when the dialog closes',
        (WidgetTester tester) async {
      final _Scenario scenario = await pump(tester, open: true);

      scenario.setOpen(false);
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Open'), findsOneWidget);
    });

    testWidgets('the title is a heading, so it can be jumped to',
        (WidgetTester tester) async {
      await pump(tester, open: true);

      expect(
        tester.getSemantics(find.text(title)).flagsCollection.isHeader,
        isTrue,
      );
    });

    testWidgets('it announces exactly the controls it shows',
        (WidgetTester tester) async {
      // The scrim dismisses, but it is not announced: the dismissal button
      // says the same thing in words, and an unlabelled tappable region
      // reachable only by swiping is a control the user cannot verify before
      // activating.
      await pump(tester, open: true);

      final SemanticsNode route = routeNodeAbove(tester, find.text(title))!;

      expect(
        buttonLabelsUnder(route),
        <String>['Keep it', 'Delete the March invoice'],
      );
    });
  });

  group(
      'everything stays reachable when the screen is small and the text '
      'is large', () {
    testWidgets('the dialog scrolls at 200% text on a 320x480 screen',
        (WidgetTester tester) async {
      final _Scenario scenario = await pump(
        tester,
        open: true,
        message: longMessage,
        textScale: 2,
        size: const Size(320, 480),
      );

      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text('Keep it'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep it'));
      await tester.pumpAndSettle();

      expect(
        scenario.dismissals,
        1,
        reason: 'the way out could not be reached, so it does not exist',
      );
    });

    testWidgets('the message can be read in full at 200% text',
        (WidgetTester tester) async {
      await pump(
        tester,
        open: true,
        message: longMessage,
        textScale: 2,
        size: const Size(320, 480),
      );

      final Text message = tester.widget<Text>(find.text(longMessage));
      expect(message.maxLines, isNull);
      expect(message.overflow, isNot(TextOverflow.ellipsis));
    });

    testWidgets('the panel never grows past the screen it sits on',
        (WidgetTester tester) async {
      await pump(
        tester,
        open: true,
        message: longMessage,
        textScale: 2,
        size: const Size(320, 480),
      );

      final Size panel = tester.getSize(find.byType(IuxSurface));
      expect(panel.height, lessThanOrEqualTo(480));
      expect(panel.width, lessThanOrEqualTo(320));
    });

    testWidgets('extra detail is placed after the message, not instead of it',
        (WidgetTester tester) async {
      await pump(
        tester,
        open: true,
        content: const Text('3 attachments'),
      );

      expect(find.text(shortMessage), findsOneWidget);
      expect(find.text('3 attachments'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('3 attachments')).dy,
        greaterThan(tester.getTopLeft(find.text(shortMessage)).dy),
      );
    });
  });

  group('it survives the conditions it will actually meet', () {
    testWidgets('the way out comes first in reading order, in both directions',
        (WidgetTester tester) async {
      await pump(tester, open: true);
      expect(
        tester.getCenter(find.text('Keep it')).dx,
        lessThan(tester.getCenter(find.text('Delete')).dx),
      );

      await pump(tester, open: true, direction: TextDirection.rtl);
      expect(
        tester.getCenter(find.text('Keep it')).dx,
        greaterThan(tester.getCenter(find.text('Delete')).dx),
      );
    });

    testWidgets('it renders right-to-left', (WidgetTester tester) async {
      final _Scenario scenario = await pump(
        tester,
        open: true,
        direction: TextDirection.rtl,
        dismissLabel: 'إلغاء',
        choiceLabel: 'حذف',
      );

      expect(tester.takeException(), isNull);
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();
      expect(scenario.dismissals, 1);
    });

    testWidgets('it renders and dismisses on every theme profile',
        (WidgetTester tester) async {
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
        final _Scenario scenario =
            await pump(tester, open: true, configuration: configuration);

        expect(tester.takeException(), isNull);
        expect(find.text(title), findsOneWidget);

        await tester.tap(find.text('Keep it'));
        await tester.pumpAndSettle();
        expect(scenario.dismissals, 1, reason: 'failed on $configuration');
      }
    });

    testWidgets('the scrim never brightens what it covers',
        (WidgetTester tester) async {
      // In dark conditions a scrim taken from the inverse surface would raise
      // the luminance of the page behind it, pushing it towards the dialog it
      // is supposed to sit behind.
      for (final Brightness brightness in Brightness.values) {
        await pump(
          tester,
          open: true,
          configuration: IuxThemeConfiguration(brightness: brightness),
        );

        final ColoredBox scrim = tester.widget<ColoredBox>(
          find.descendant(
            of: find.byType(IuxDialog),
            matching: find.byType(ColoredBox),
          ),
        );
        final IuxSemanticColors colors = IuxTheme.resolve(
          IuxThemeConfiguration(brightness: brightness),
        ).colors;

        expect(
          scrim.color.computeLuminance(),
          lessThanOrEqualTo(colors.surface.base.computeLuminance()),
          reason: 'the scrim is lighter than the page in ${brightness.name}',
        );
      }
    });
  });

  group('motion explains the change and never carries it', () {
    testWidgets('with motion turned off the dialog is there on the first frame',
        (WidgetTester tester) async {
      final _Scenario scenario = await pump(
        tester,
        configuration: const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(motion: IuxMotionPreference.none),
        ),
      );

      scenario.setOpen(true);
      await tester.pump();

      expect(find.text(title), findsOneWidget);
      expect(_fadeOf(tester).opacity.value, 1);
    });

    testWidgets('with motion allowed the dialog fades in rather than appearing',
        (WidgetTester tester) async {
      final _Scenario scenario = await pump(tester);

      scenario.setOpen(true);
      await tester.pump();
      expect(_fadeOf(tester).opacity.value, lessThan(1));

      await tester.pumpAndSettle();
      expect(_fadeOf(tester).opacity.value, 1);
    });

    testWidgets(
        'a reduced preference shortens the entrance, it does not '
        'remove it', (WidgetTester tester) async {
      await pump(tester, open: true);
      final Duration full = _durationOf(tester);

      // A fresh tree, because the entrance is deliberately not replayed when
      // the theme changes under a dialog that is already open.
      await tester.pumpWidget(const SizedBox.shrink());
      await pump(
        tester,
        open: true,
        configuration: const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(motion: IuxMotionPreference.reduced),
        ),
      );
      final Duration reduced = _durationOf(tester);

      expect(reduced, lessThan(full));
      expect(reduced, greaterThan(Duration.zero));
    });
  });

  group('incoherent dialogs are rejected at construction', () {
    test('a dialog with no title cannot announce itself', () {
      expect(
        () => IuxDialog(
          title: '',
          message: shortMessage,
          dismissLabel: 'Keep it',
          onDismiss: () {},
        ),
        throwsAssertionError,
      );
    });

    test('a dialog with no message states a topic, not a consequence', () {
      expect(
        () => IuxDialog(
          title: title,
          message: '',
          dismissLabel: 'Keep it',
          onDismiss: () {},
        ),
        throwsAssertionError,
      );
    });

    test('a dialog with no labelled way out is a trap', () {
      expect(
        () => IuxDialog(
          title: title,
          message: shortMessage,
          dismissLabel: '',
          onDismiss: () {},
        ),
        throwsAssertionError,
      );
    });

    test('a dialog with three choices is a menu', () {
      final IuxDialogAction choice = IuxDialogAction(
        label: 'Delete',
        action: deleteAction,
        onActivate: () {},
      );
      expect(
        () => IuxDialog(
          title: title,
          message: shortMessage,
          dismissLabel: 'Keep it',
          onDismiss: () {},
          actions: <IuxDialogAction>[choice, choice, choice],
        ),
        throwsAssertionError,
      );
    });

    test('a choice with no label is a decision the user cannot make', () {
      expect(
        () => IuxDialogAction(
          label: '',
          action: deleteAction,
          onActivate: () {},
        ),
        throwsAssertionError,
      );
    });
  });

  group('the modal layer', () {
    testWidgets('costs nothing while no dialog is open',
        (WidgetTester tester) async {
      await pump(tester);

      expect(find.byType(IuxDialog), findsNothing);
      expect(find.byType(IuxPage), findsOneWidget);
    });
  });
}

FadeTransition _fadeOf(WidgetTester tester) => tester.widget<FadeTransition>(
      find.descendant(
        of: find.byType(IuxDialog),
        matching: find.byType(FadeTransition),
      ),
    );

Duration _durationOf(WidgetTester tester) =>
    (_fadeOf(tester).opacity as AnimationController).duration!;
