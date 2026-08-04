import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

/// The four profiles every visual guarantee has to survive.
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

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget subject, {
    IuxThemeConfiguration configuration = const IuxThemeConfiguration(),
    TextDirection direction = TextDirection.ltr,
    double textScale = 1,
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
        ),
        child: MaterialApp(
          theme: IuxTheme.fromConfiguration(configuration),
          home: Directionality(
            textDirection: direction,
            child: Scaffold(body: SingleChildScrollView(child: subject)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// A control built without touching another mission's component, so this
  /// file keeps testing the row rather than whatever the button is doing.
  Widget control(String label, VoidCallback onTap) => IuxTapTarget(
        onTap: onTap,
        semanticLabel: label,
        child: const Icon(Icons.close),
      );

  /// The region of a row that actually responds to a tap.
  ///
  /// Measured on the gesture detector rather than on the whole widget: the
  /// focus ring reserves a gap outside it, so measuring the widget would
  /// report a target larger than the one the user can hit.
  Finder tapRegion() => find
      .descendant(
        of: find.byType(IuxListItem),
        matching: find.byType(GestureDetector),
      )
      .first;

  BoxDecoration surfaceDecoration(WidgetTester tester) => tester
      .widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(IuxSurface),
              matching: find.byType(DecoratedBox),
            )
            .first,
      )
      .decoration as BoxDecoration;

  /// What a screen reader actually announces for [node], after merging.
  String announced(SemanticsNode node) => node.getSemanticsData().label;

  /// How many separate stops a screen reader finds below [node].
  ///
  /// A node merged into its parent is not a stop: the user cannot land on it,
  /// which is the whole point of merging a row into one control.
  int stopsBelow(SemanticsNode node) {
    int count = 0;
    void visit(SemanticsNode parent) {
      parent.visitChildren((SemanticsNode child) {
        if (!child.isMergedIntoParent) count++;
        visit(child);
        return true;
      });
    }

    visit(node);
    return count;
  }

  group('a row is either a control or it contains controls, never both', () {
    testWidgets('an interactive row holding an IUX control fails loudly',
        (WidgetTester tester) async {
      await pump(
        tester,
        IuxListItem.tappable(
          title: 'Order 3141',
          onActivate: () {},
          leading: control('Track', () {}),
        ),
      );

      final Object? error = tester.takeException();
      expect(error, isFlutterError);
      expect(
        error.toString(),
        contains('IuxTapTarget'),
        reason: 'the message has to name what to go and remove',
      );
      expect(
        error.toString(),
        contains('what does tapping do'),
        reason: 'the message explains the failure, not only the rule',
      );
      expect(
        error.toString(),
        contains('trailingAction'),
        reason: 'refusing a combination without naming the sanctioned one '
            'leaves the developer to guess, and they will guess wrong',
      );
    });

    testWidgets('a Material control in the leading slot fails too',
        (WidgetTester tester) async {
      // The check is not an IUX allow-list. A row assembled from Material
      // widgets produces exactly the same nested-control confusion.
      await pump(
        tester,
        IuxListItem.tappable(
          title: 'Order 3141',
          onActivate: () {},
          leading: TextButton(onPressed: () {}, child: const Text('Track')),
        ),
      );

      expect(tester.takeException(), isFlutterError);
    });

    testWidgets('a selectable row is checked the same way',
        (WidgetTester tester) async {
      await pump(
        tester,
        IuxListItem.selectable(
          title: 'March invoice',
          selected: IuxSelectionState.unselected,
          onSelectedChanged: (bool _) {},
          leading: control('Track', () {}),
        ),
      );

      expect(tester.takeException(), isFlutterError);
    });

    testWidgets('an icon in the leading slot is accepted',
        (WidgetTester tester) async {
      await pump(
        tester,
        IuxListItem.tappable(
          title: 'Order 3141',
          subtitle: 'Delivered',
          onActivate: () {},
          leading: const Icon(Icons.local_shipping),
        ),
      );

      expect(
        tester.takeException(),
        isNull,
        reason: 'icons are content; only controls are the problem',
      );
    });

    testWidgets('a plain row is free to hold a control',
        (WidgetTester tester) async {
      // The mirror image: a row that is not itself a control has no second
      // answer to give, so a control inside it is simply another target.
      await pump(
        tester,
        IuxListItem(
          title: 'Order 3141',
          leading: control('Track', () {}),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('a control passed as trailingAction is accepted and reachable',
        (WidgetTester tester) async {
      final List<String> pressed = <String>[];
      await pump(
        tester,
        IuxListItem.tappable(
          title: 'Order 3141',
          onActivate: () => pressed.add('row'),
          trailingAction: control('Delete', () => pressed.add('delete')),
        ),
      );

      expect(tester.takeException(), isNull);

      await tester.tap(find.bySemanticsLabel('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(tapRegion());
      await tester.pumpAndSettle();

      expect(
        pressed,
        <String>['delete', 'row'],
        reason: 'the control and the row are two targets, each doing its own '
            'thing — which is the arrangement that makes the combination '
            'usable at all',
      );
    });

    testWidgets('the row target and the control target never overlap',
        (WidgetTester tester) async {
      await pump(
        tester,
        IuxListItem.tappable(
          title: 'Order 3141',
          onActivate: () {},
          trailingAction: control('Delete', () {}),
        ),
      );

      final Rect row = tester.getRect(tapRegion());
      final Rect action = tester.getRect(find.bySemanticsLabel('Delete'));

      expect(
        row.overlaps(action),
        isFalse,
        reason: 'two overlapping targets give the user no way to know which '
            'one a tap will reach',
      );
      expect(
        action.left - row.right,
        greaterThanOrEqualTo(kIuxMinimumTargetSpacing),
        reason: 'target size alone does not prevent mis-taps: a finger on the '
            'seam between "open" and "delete" has no margin for error',
      );
    });

    testWidgets('the control is a sibling stop, not a nested one',
        (WidgetTester tester) async {
      await pump(
        tester,
        IuxListItem.tappable(
          title: 'Order 3141',
          onActivate: () {},
          trailingAction: control('Delete', () {}),
        ),
      );

      expect(
        stopsBelow(tester.getSemantics(find.byType(IuxListItem))),
        2,
        reason: 'the row and its control are two adjacent stops. Nesting one '
            'in the other is what makes a screen reader announce controls '
            'inside a control',
      );
    });

    testWidgets('the text slots cannot hold a control at all',
        (WidgetTester tester) async {
      // The type-level half of the rule, asserted the only way a test can:
      // these are strings, so there is no widget position to smuggle a button
      // into. `IuxListItem.tappable(title: IuxButton(...))` does not compile.
      const IuxListItem row = IuxListItem(
        title: 'Order 3141',
        subtitle: 'Delivered',
        trailingText: '82.40',
      );

      expect(row.title, isA<String>());
      expect(row.subtitle, isA<String>());
      expect(row.trailingText, isA<String>());
    });
  });

  group('a tappable row is one control that reads out everything it shows', () {
    Future<void> pumpTappable(
      WidgetTester tester, {
      String title = 'Order 3141',
      String? subtitle = 'Delivered on Tuesday',
      String? trailingText = '82.40 EUR',
      String? semanticLabel,
      String? hint,
      VoidCallback? onActivate,
      bool autofocus = false,
      IuxThemeConfiguration configuration = const IuxThemeConfiguration(),
    }) =>
        pump(
          tester,
          IuxListItem.tappable(
            title: title,
            subtitle: subtitle,
            trailingText: trailingText,
            semanticLabel: semanticLabel,
            hint: hint,
            autofocus: autofocus,
            onActivate: onActivate ?? () {},
          ),
          configuration: configuration,
        );

    testWidgets('it is announced as an enabled button',
        (WidgetTester tester) async {
      await pumpTappable(tester);

      expect(
        tester.getSemantics(find.byType(IuxListItem)),
        isSemantics(
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          hasTapAction: true,
        ),
      );
    });

    testWidgets('it announces the title, the subtitle and the value',
        (WidgetTester tester) async {
      // Excluding descendant semantics — what a button does with its own
      // label — would delete the status and the amount from the interface of
      // every screen-reader user.
      await pumpTappable(tester);

      final String label =
          announced(tester.getSemantics(find.byType(IuxListItem)));
      expect(label, contains('Order 3141'));
      expect(label, contains('Delivered on Tuesday'));
      expect(label, contains('82.40 EUR'));
    });

    testWidgets('the whole row is a single stop, not one stop per line',
        (WidgetTester tester) async {
      await pumpTappable(tester);

      expect(
        stopsBelow(tester.getSemantics(find.byType(IuxListItem))),
        0,
        reason: 'a row that is one control must not offer its lines as '
            'separate stops, or the user cannot tell which one activates',
      );
    });

    testWidgets('a supplied name is read before the row text, not instead',
        (WidgetTester tester) async {
      await pumpTappable(tester, semanticLabel: 'Backup from yesterday');

      final String label =
          announced(tester.getSemantics(find.byType(IuxListItem)));
      expect(label, contains('Backup from yesterday'));
      expect(
        label,
        contains('Order 3141'),
        reason: 'a name that replaced the content would trade one problem for '
            'a worse one',
      );
    });

    testWidgets('the hint says what activating does',
        (WidgetTester tester) async {
      await pumpTappable(tester, hint: 'Opens the order');

      expect(
        tester.getSemantics(find.byType(IuxListItem)).getSemanticsData().hint,
        contains('Opens the order'),
      );
    });

    testWidgets('one tap activates it exactly once',
        (WidgetTester tester) async {
      int calls = 0;
      await pumpTappable(tester, onActivate: () => calls++);

      await tester.tap(tapRegion());
      await tester.pumpAndSettle();

      expect(calls, 1);
    });

    testWidgets('Enter and Space activate it', (WidgetTester tester) async {
      int calls = 0;
      await pumpTappable(tester, autofocus: true, onActivate: () => calls++);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(
        calls,
        2,
        reason: 'a row reached by keyboard or D-pad has to activate without a '
            'pointer, like any other control',
      );
    });

    testWidgets('taking focus does not move the layout',
        (WidgetTester tester) async {
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);

      await pump(
        tester,
        IuxListItem.tappable(
          title: 'Order 3141',
          onActivate: () {},
          focusNode: node,
        ),
      );
      final Rect resting = tester.getRect(find.byType(IuxListItem));

      node.requestFocus();
      await tester.pumpAndSettle();

      expect(
        tester.getRect(find.byType(IuxListItem)),
        resting,
        reason: 'a row that grew when it took focus would push the rest of '
            'the list down, and for a screen-magnifier user that can move the '
            'focused row off screen',
      );
    });

    testWidgets('the whole row responds, edge to edge',
        (WidgetTester tester) async {
      // The focus ring reserves a gap on every side. If the gesture sat
      // inside it, every row would carry an invisible band at its edge where
      // a tap does nothing — which is where a thumb reaching across a phone
      // lands.
      await pump(
        tester,
        IuxListItem.tappable(title: 'Order 3141', onActivate: () {}),
      );

      expect(
        tester.getRect(tapRegion()),
        tester.getRect(find.byType(IuxListItem)),
      );
    });

    testWidgets('a nameless row is refused', (WidgetTester tester) async {
      expect(
        () => IuxListItem.tappable(title: '', onActivate: () {}),
        throwsAssertionError,
      );
    });

    testWidgets('it meets the touch target floor at every density',
        (WidgetTester tester) async {
      for (final IuxDensity density in IuxDensity.values) {
        await pumpTappable(
          tester,
          subtitle: null,
          trailingText: null,
          configuration: IuxThemeConfiguration(
            profile: IuxAccessibilityProfile(density: density),
          ),
        );

        final Size size = tester.getSize(tapRegion());
        expect(
          size.height,
          greaterThanOrEqualTo(IuxTouchTarget.minimum),
          reason: '${density.name} produced a row ${size.height} tall. '
              'Density tightens the space between rows; it never shrinks '
              'what a finger has to hit',
        );
      }
    });

    testWidgets('a comfortable target preference enlarges it',
        (WidgetTester tester) async {
      await pumpTappable(
        tester,
        subtitle: null,
        trailingText: null,
        configuration: const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(
            touchTarget: IuxTouchTargetPreference.comfortable,
          ),
        ),
      );

      expect(
        tester.getSize(tapRegion()).height,
        greaterThanOrEqualTo(IuxTouchTarget.comfortable),
      );
    });
  });

  group('a selectable row is a checkbox in disguise', () {
    Future<void> pumpSelectable(
      WidgetTester tester, {
      IuxSelectionState selected = IuxSelectionState.unselected,
      ValueChanged<bool>? onSelectedChanged,
      IuxThemeConfiguration configuration = const IuxThemeConfiguration(),
    }) =>
        pump(
          tester,
          IuxListItem.selectable(
            title: 'March invoice',
            subtitle: 'Paid',
            selected: selected,
            onSelectedChanged: onSelectedChanged ?? (bool _) {},
          ),
          configuration: configuration,
        );

    testWidgets('it announces a checked state rather than a button',
        (WidgetTester tester) async {
      await pumpSelectable(tester, selected: IuxSelectionState.selected);

      expect(
        tester.getSemantics(find.byType(IuxListItem)),
        isSemantics(
          hasCheckedState: true,
          isChecked: true,
          isButton: false,
          hasTapAction: true,
          isEnabled: true,
        ),
      );
    });

    testWidgets('an unchosen row announces the unchecked state',
        (WidgetTester tester) async {
      await pumpSelectable(tester);

      expect(
        tester.getSemantics(find.byType(IuxListItem)),
        isSemantics(hasCheckedState: true, isChecked: false),
      );
    });

    testWidgets('it still reads out the content it shows',
        (WidgetTester tester) async {
      await pumpSelectable(tester);

      final String label =
          announced(tester.getSemantics(find.byType(IuxListItem)));
      expect(label, contains('March invoice'));
      expect(label, contains('Paid'));
    });

    testWidgets('activating it asks for the opposite selection',
        (WidgetTester tester) async {
      final List<bool> asked = <bool>[];
      await pumpSelectable(tester, onSelectedChanged: asked.add);

      await tester.tap(tapRegion());
      await tester.pumpAndSettle();

      expect(asked, <bool>[true]);
    });

    testWidgets('a chosen row asks to be unchosen',
        (WidgetTester tester) async {
      final List<bool> asked = <bool>[];
      await pumpSelectable(
        tester,
        selected: IuxSelectionState.selected,
        onSelectedChanged: asked.add,
      );

      await tester.tap(tapRegion());
      await tester.pumpAndSettle();

      expect(asked, <bool>[false]);
    });

    testWidgets('the row does not choose itself', (WidgetTester tester) async {
      // The parent owns the answer. A row that marked itself and then failed
      // to save would be showing the user something untrue.
      await pumpSelectable(tester, onSelectedChanged: (bool _) {});

      await tester.tap(tapRegion());
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.byType(IuxListItem)),
        isSemantics(isChecked: false),
      );
    });

    testWidgets('a chosen row carries a mark, not only a colour',
        (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in _profiles) {
        await pumpSelectable(
          tester,
          selected: IuxSelectionState.selected,
          configuration: configuration,
        );
        expect(
          find.byIcon(Icons.check),
          findsOneWidget,
          reason: 'colour is the one signal a user may be unable to read, and '
              'on a chosen row it is otherwise the only one — failed on '
              '$configuration',
        );

        await pumpSelectable(tester, configuration: configuration);
        expect(
          find.byIcon(Icons.check),
          findsNothing,
          reason: 'an unchosen row must not show the mark of a chosen one',
        );
      }
    });

    testWidgets('a chosen row also changes surface',
        (WidgetTester tester) async {
      await pumpSelectable(tester, selected: IuxSelectionState.selected);
      final BuildContext context = tester.element(find.byType(IuxListItem));
      final IuxSemanticColors colors = IuxSemanticColors.of(context);

      expect(
        IuxListItemResolver.resolve(context, selected: true).background,
        colors.surface.selected,
      );
      expect(IuxListItemResolver.resolve(context).background, isNull);
    });

    testWidgets('a partly chosen row is refused', (WidgetTester tester) async {
      expect(
        () => IuxListItem.selectable(
          title: 'March invoice',
          selected: IuxSelectionState.partial,
          onSelectedChanged: (bool _) {},
        ),
        throwsAssertionError,
      );
    });

    testWidgets('it meets the touch target floor', (WidgetTester tester) async {
      await pumpSelectable(tester);

      expect(
        tester.getSize(tapRegion()).height,
        greaterThanOrEqualTo(IuxTouchTarget.minimum),
      );
    });
  });

  group('a plain row is not a control', () {
    testWidgets('it is not announced as a button', (WidgetTester tester) async {
      await pump(tester, const IuxListItem(title: 'Postcode'));

      expect(
        tester.getSemantics(find.byType(IuxListItem)),
        isSemantics(
            isButton: false, hasTapAction: false, hasCheckedState: false),
      );
    });

    testWidgets('its lines are read as one item', (WidgetTester tester) async {
      await pump(
        tester,
        const IuxListItem(
          title: 'Postcode',
          subtitle: 'Delivery address',
          trailingText: '75011',
        ),
      );

      final SemanticsNode node = tester.getSemantics(find.byType(IuxListItem));
      expect(stopsBelow(node), 0);
      expect(announced(node), contains('Postcode'));
      expect(announced(node), contains('75011'));
    });

    testWidgets('a trailing control on a plain row stays its own stop',
        (WidgetTester tester) async {
      final List<String> pressed = <String>[];
      await pump(
        tester,
        IuxListItem(
          title: 'Postcode',
          trailingAction: control('Edit', () => pressed.add('edit')),
        ),
      );

      expect(
        stopsBelow(tester.getSemantics(find.byType(IuxListItem))),
        2,
        reason: 'a row that is not a control must not absorb its own control '
            'into one node: it would stop being somewhere the user can land',
      );

      await tester.tap(find.bySemanticsLabel('Edit'));
      await tester.pumpAndSettle();
      expect(pressed, <String>['edit']);
    });

    testWidgets('it is exactly as tall as an interactive row',
        (WidgetTester tester) async {
      // A plain row reserves the gap an interactive one keeps for its focus
      // ring. Without that, a list mixing the two has rows of two heights and
      // the difference reads as a rendering fault rather than as a difference
      // in behaviour.
      await pump(tester, const IuxListItem(title: 'Postcode'));
      final double plain = tester.getSize(find.byType(IuxListItem)).height;

      await pump(
        tester,
        IuxListItem.tappable(title: 'Postcode', onActivate: () {}),
      );

      expect(tester.getSize(find.byType(IuxListItem)).height, plain);
    });

    testWidgets('an empty title is refused', (WidgetTester tester) async {
      expect(() => IuxListItem(title: ''), throwsAssertionError);
    });

    testWidgets('an empty subtitle is refused', (WidgetTester tester) async {
      expect(
        () => IuxListItem(title: 'Postcode', subtitle: ''),
        throwsAssertionError,
      );
    });
  });

  group('long content, which is where a row fails first', () {
    /// The case the component exists to survive: everything at once, enlarged,
    /// on the narrowest screen an Android phone reports.
    Future<void> pumpCrowded(WidgetTester tester, {double scale = 2}) => pump(
          tester,
          IuxListItem.tappable(
            title: 'Order 3141 for Aleksandra Wiśniewska-Kowalczyk',
            subtitle: 'Handed to the carrier, expected between Tuesday and '
                'Thursday next week',
            trailingText: '1 284,90 EUR',
            leading: const Icon(Icons.local_shipping),
            onActivate: () {},
            trailingAction: control('Delete', () {}),
          ),
          textScale: scale,
          size: const Size(320, 480),
        );

    testWidgets('a title, a subtitle, a value and an icon survive 200% on 320',
        (WidgetTester tester) async {
      await pumpCrowded(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('nothing in the row is ellipsised, at any scale',
        (WidgetTester tester) async {
      for (final double scale in <double>[1, 1.3, 2]) {
        await pumpCrowded(tester, scale: scale);

        for (final Text text in tester.widgetList<Text>(
          find.descendant(
            of: find.byType(IuxListItem),
            matching: find.byType(Text),
          ),
        )) {
          expect(
            text.overflow,
            isNot(TextOverflow.ellipsis),
            reason: 'truncating a row loses the only thing that identifies '
                'the item — failed at scale $scale on "${text.data}"',
          );
          expect(text.maxLines, isNull);
        }
      }
    });

    testWidgets('the value moves under the text once text is enlarged',
        (WidgetTester tester) async {
      await pumpCrowded(tester, scale: 1);
      final Rect besideTitle = tester.getRect(find.text('1 284,90 EUR'));
      final Rect title = tester.getRect(
        find.text('Order 3141 for Aleksandra Wiśniewska-Kowalczyk'),
      );
      expect(
        besideTitle.left,
        greaterThanOrEqualTo(title.right),
        reason: 'at a normal scale the value belongs at the end of the row',
      );

      await pumpCrowded(tester);
      expect(
        tester.getRect(find.text('1 284,90 EUR')).top,
        greaterThan(
          tester
              .getRect(
                find.text('Order 3141 for Aleksandra Wiśniewska-Kowalczyk'),
              )
              .top,
        ),
        reason: 'shrinking the value instead of stacking it is what produces '
            'the clipped amounts users report as "the app ignores my text '
            'size"',
      );
    });

    testWidgets('a long value never squeezes the title',
        (WidgetTester tester) async {
      await pump(
        tester,
        const IuxListItem(
          title: 'Order 3141',
          trailingText: '1 284 902,90 EUR',
        ),
        size: const Size(320, 480),
      );

      final double title = tester.getSize(find.text('Order 3141')).width;
      final double value = tester.getSize(find.text('1 284 902,90 EUR')).width;

      expect(
        title,
        greaterThan(value),
        reason: 'the title identifies the item, so it is the part that keeps '
            'the space and the value is the part that wraps',
      );
    });

    testWidgets('a title that needs three lines gets three lines',
        (WidgetTester tester) async {
      await pump(
        tester,
        const IuxListItem(
          title: 'Your parcel was handed to the carrier and is expected to '
              'arrive between Tuesday and Thursday next week',
        ),
        size: const Size(320, 480),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(IuxListItem)).height,
        greaterThan(IuxTouchTarget.minimum),
        reason: 'a row that stayed one line tall while holding four lines of '
            'text would be clipping them',
      );
    });
  });

  group('a row and the control beside it, which only fail together', () {
    /// The scales the audit measures, and the screen it measures them on.
    const List<double> scales = <double>[1, 1.5, 2, 3];
    const Size small = Size(320, 640);

    /// A status that is wide enough to matter and short enough to be real.
    const IuxStatusIndicator delivered = IuxStatusIndicator(
      status: IuxStatus.success('Delivered'),
    );

    /// The combination: a tappable row with a status beside it.
    ///
    /// `IUX-LISTITEM-TRAILING-001`. The point of this test is the *pair*.
    /// Neither half overflows on its own — the indicator wraps its own label
    /// when something bounds it, and the row wraps its title when something is
    /// left for it — which is exactly why no component test found this and why
    /// the two are pumped separately below as the control.
    Widget combined() => IuxListItem.tappable(
          title: 'Order 3141',
          subtitle: 'Handed to the carrier on Monday',
          onActivate: () {},
          hint: 'Opens the order',
          trailingAction: delivered,
        );

    testWidgets(
        'the pair fits a 320 pixel row at 100, 150, 200 and 300 per cent',
        (WidgetTester tester) async {
      for (final double scale in scales) {
        await pump(tester, combined(), textScale: scale, size: small);

        // DebugOverflowIndicatorMixin reports a render object's overflow once
        // per lifetime, so this assertion is only worth anything because every
        // case ends by tearing the tree down (IUX-QA-VACUOUS-003). Without the
        // teardown the run passes vacuously from the second case on.
        expect(
          tester.takeException(),
          isNull,
          reason: 'at ${scale}x the row overflowed: measured 34 pixels over at '
              '200% and 180 at 300% before the trailing control was given a '
              'ceiling (WCAG 2.2 SC 1.4.4)',
        );

        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('the title keeps a column it can be read in, before that',
        (WidgetTester tester) async {
      // The half of this defect no exception reported. On the way up to the
      // overflow the title's box was measured at 75.8 pixels at 100%, 2.8 at
      // 150% and zero at 200% — one character to a line, then none — and
      // nothing was thrown until 200%. An assertion on `takeException` alone
      // would have called 150% healthy.
      for (final double scale in scales) {
        await pump(tester, combined(), textScale: scale, size: small);

        expect(
          tester.getSize(find.text('Order 3141')).width,
          greaterThan(IuxTouchTarget.minimum),
          reason: 'at ${scale}x the title was squeezed into a column narrower '
              'than a touch target, which is not a title any more',
        );

        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('neither half overflows alone, which is why this needed a pair',
        (WidgetTester tester) async {
      // The control. If either of these failed, the defect would have been
      // found by that component's own suite and this group would be in the
      // wrong file.
      for (final double scale in scales) {
        await pump(
          tester,
          IuxListItem.tappable(
            title: 'Order 3141',
            subtitle: 'Handed to the carrier on Monday',
            onActivate: () {},
            hint: 'Opens the order',
          ),
          textScale: scale,
          size: small,
        );
        expect(
          tester.takeException(),
          isNull,
          reason: 'the row alone at ${scale}x',
        );
        await tester.pumpWidget(const SizedBox.shrink());

        await pump(tester, delivered, textScale: scale, size: small);
        expect(
          tester.takeException(),
          isNull,
          reason: 'the indicator alone at ${scale}x',
        );
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('the row keeps the larger share of the width, at every scale',
        (WidgetTester tester) async {
      // Not merely "nothing threw". A row whose text region had been squeezed
      // to nothing would also report no overflow, and would be useless: the
      // title is the only thing that tells this item from the next one.
      for (final double scale in scales) {
        await pump(tester, combined(), textScale: scale, size: small);

        final double region = tester.getSize(find.text('Order 3141')).width;
        final double control =
            tester.getSize(find.byType(IuxStatusIndicator)).width;

        expect(
          control,
          lessThan(region),
          reason: 'at ${scale}x the status took more of the row than the text '
              'that identifies it',
        );

        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('a control that already fits is not resized',
        (WidgetTester tester) async {
      // The ceiling is a maximum, never a tight width, so it has to be
      // invisible wherever there was room. Measured against the same indicator
      // shrink-wrapped on its own, on a window wide enough that its natural
      // width is under the share — which is the ordinary case, and the one a
      // fix for the narrow case must not disturb.
      const Size wide = Size(640, 640);

      await pump(
        tester,
        const Row(
            mainAxisSize: MainAxisSize.min, children: <Widget>[delivered]),
        size: wide,
      );
      final double natural =
          tester.getSize(find.byType(IuxStatusIndicator)).width;

      await tester.pumpWidget(const SizedBox.shrink());
      await pump(tester, combined(), size: wide);

      expect(
        tester.getSize(find.byType(IuxStatusIndicator)).width,
        moreOrLessEquals(natural, epsilon: 0.5),
        reason: 'there was room for the control at its natural size, so '
            'bounding it must have changed nothing',
      );
    });

    testWidgets('the two targets still cannot overlap',
        (WidgetTester tester) async {
      // The guarantee the arrangement exists for, re-checked at the scale that
      // used to break the layout: bounding the control must not have let it
      // slide under the row's target.
      await pump(tester, combined(), textScale: 2, size: small);

      final Rect row = tester.getRect(tapRegion());
      final Rect control = tester.getRect(find.byType(IuxStatusIndicator));

      expect(row.overlaps(control), isFalse);
      expect(
        control.left - row.right,
        greaterThanOrEqualTo(kIuxMinimumTargetSpacing),
        reason: 'the spacing floor between two adjacent targets is the reason '
            'this arrangement is provided rather than left to a call site',
      );
    });
  });

  group('a group of rows', () {
    Widget threeRows() => IuxListGroup(
          children: <Widget>[
            IuxListItem.tappable(title: 'Street', onActivate: () {}),
            IuxListItem.tappable(title: 'City', onActivate: () {}),
            IuxListItem.tappable(title: 'Postcode', onActivate: () {}),
          ],
        );

    testWidgets('three rows draw two separators', (WidgetTester tester) async {
      await pump(tester, threeRows());

      expect(
        find.byType(IuxListSeparator),
        findsNWidgets(2),
        reason: 'three rows have two boundaries between them, and none around '
            'the outside where the group border already is',
      );
    });

    testWidgets('three rows are three stops, not one paragraph',
        (WidgetTester tester) async {
      // The opposite decision from a tappable row, and the reason both are
      // written down: that row is one control, so it is one stop; a group is
      // several items, so a user has to be able to move between them.
      await pump(tester, threeRows());

      expect(stopsBelow(tester.getSemantics(find.byType(IuxListGroup))), 3);
    });

    testWidgets('a group publishes a container and no heading',
        (WidgetTester tester) async {
      await pump(tester, threeRows());

      expect(
        tester.getSemantics(find.byType(IuxListGroup)),
        isSemantics(isHeader: false),
      );
    });

    testWidgets('a section around a group supplies the heading',
        (WidgetTester tester) async {
      await pump(
        tester,
        IuxSection(title: 'Delivery', children: <Widget>[threeRows()]),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('Delivery')),
        isSemantics(isHeader: true, label: 'Delivery'),
      );
    });

    testWidgets('a group keeps its outline once the theme is flattened',
        (WidgetTester tester) async {
      await pump(
        tester,
        threeRows(),
        configuration: const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(
            visualStimulation: IuxVisualStimulation.reduced,
          ),
        ),
      );

      expect(
        IuxGeometryTheme.of(tester.element(find.byType(IuxListGroup)))
            .elevationRaised,
        0,
        reason: 'the premise of this test: the theme has removed elevation',
      );

      final BoxDecoration decoration = surfaceDecoration(tester);
      expect(decoration.border, isNotNull);
      expect(decoration.boxShadow, isNull);
    });

    testWidgets('a group never casts a shadow, at any profile',
        (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in _profiles) {
        await pump(tester, threeRows(), configuration: configuration);

        expect(
          surfaceDecoration(tester).boxShadow,
          isNull,
          reason: 'a shadow is invisible in dark conditions and removed under '
              'reduced visual stimulation, so it is never the signal — '
              'failed on $configuration',
        );
      }
    });

    testWidgets('an empty group is refused', (WidgetTester tester) async {
      await pump(tester, const IuxListGroup(children: <Widget>[]));

      expect(tester.takeException(), isAssertionError);
    });

    testWidgets('the group adds no padding of its own',
        (WidgetTester tester) async {
      // A row's padding has to be inside its target. A group that padded its
      // children would make the visible row larger than the area that
      // responds, and the user would find out by tapping somewhere that does
      // nothing.
      await pump(tester, threeRows());

      final Rect group = tester.getRect(find.byType(IuxListGroup));
      final Rect first = tester.getRect(tapRegion());
      final double border =
          IuxGeometryTheme.of(tester.element(find.byType(IuxListGroup)))
              .borderWidth;

      expect(first.left - group.left, lessThanOrEqualTo(border));
    });

    testWidgets('a separator can be used on its own in a ListView',
        (WidgetTester tester) async {
      // The reason the separator is public: a long list is a ListView, not a
      // group, and a list whose separators are hand-drawn drifts from the
      // ones the rest of the application uses.
      await pump(
        tester,
        SizedBox(
          height: 400,
          child: ListView.separated(
            itemCount: 3,
            separatorBuilder: (BuildContext _, int __) =>
                const IuxListSeparator(),
            itemBuilder: (BuildContext _, int index) =>
                IuxListItem(title: 'Row $index'),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(IuxListSeparator), findsNWidgets(2));
    });
  });

  group('resilience', () {
    testWidgets('every form renders right to left',
        (WidgetTester tester) async {
      await pump(
        tester,
        IuxListGroup(
          children: <Widget>[
            const IuxListItem(title: 'الرمز البريدي', trailingText: '٧٥٠١١'),
            IuxListItem.tappable(title: 'الطلب ٣١٤١', onActivate: () {}),
            IuxListItem.selectable(
              title: 'فاتورة مارس',
              selected: IuxSelectionState.selected,
              onSelectedChanged: (bool _) {},
            ),
          ],
        ),
        direction: TextDirection.rtl,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('الطلب ٣١٤١'), findsOneWidget);
      expect(find.text('٧٥٠١١'), findsOneWidget);
    });

    testWidgets('the value sits at the reading end in either direction',
        (WidgetTester tester) async {
      await pump(
        tester,
        const IuxListItem(title: 'Postcode', trailingText: '75011'),
      );
      expect(
        tester.getRect(find.text('75011')).left,
        greaterThan(tester.getRect(find.text('Postcode')).left),
      );

      await pump(
        tester,
        const IuxListItem(title: 'Postcode', trailingText: '75011'),
        direction: TextDirection.rtl,
      );
      expect(
        tester.getRect(find.text('75011')).left,
        lessThan(tester.getRect(find.text('Postcode')).left),
        reason: 'a value pinned to the physical right reads as belonging to '
            'the row above in an Arabic interface',
      );
    });

    testWidgets('every form renders on every theme profile',
        (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in _profiles) {
        await pump(
          tester,
          IuxListGroup(
            children: <Widget>[
              IuxListItem(
                title: 'Postcode',
                trailingText: '75011',
                trailingAction: control('Edit', () {}),
              ),
              IuxListItem.tappable(
                title: 'Order 3141',
                subtitle: 'Delivered',
                onActivate: () {},
              ),
              IuxListItem.selectable(
                title: 'March invoice',
                selected: IuxSelectionState.selected,
                onSelectedChanged: (bool _) {},
              ),
            ],
          ),
          configuration: configuration,
        );

        expect(tester.takeException(), isNull, reason: '$configuration');
        expect(find.text('Order 3141'), findsOneWidget);
        expect(find.text('March invoice'), findsOneWidget);
      }
    });

    testWidgets('a group survives 200% text on a small screen',
        (WidgetTester tester) async {
      await pump(
        tester,
        IuxListGroup(
          children: <Widget>[
            IuxListItem.selectable(
              title: '12 Rue des Fleurs, Building C, Staircase 3',
              subtitle: 'Leave with the concierge if nobody answers',
              trailingText: '75011 Paris',
              selected: IuxSelectionState.selected,
              onSelectedChanged: (bool _) {},
            ),
            IuxListItem.tappable(
              title: 'Order 3141 was delivered on Tuesday',
              onActivate: () {},
              trailingAction: control('Delete', () {}),
            ),
          ],
        ),
        textScale: 2,
        size: const Size(320, 480),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('motion', () {
    Finder pressLayer() => find
        .descendant(
          of: find.byType(IuxListItem),
          matching: find.byType(AnimatedOpacity),
        )
        .first;

    Future<void> pumpTappable(
      WidgetTester tester,
      IuxMotionPreference motion,
    ) =>
        pump(
          tester,
          IuxListItem.tappable(title: 'Order 3141', onActivate: () {}),
          configuration: IuxThemeConfiguration(
            profile: IuxAccessibilityProfile(motion: motion),
          ),
        );

    testWidgets('no motion removes the fade, not the pressed state',
        (WidgetTester tester) async {
      await pumpTappable(tester, IuxMotionPreference.none);

      expect(
        tester.widget<AnimatedOpacity>(pressLayer()).duration,
        Duration.zero,
      );

      final TestGesture gesture =
          await tester.startGesture(tester.getCenter(tapRegion()));
      await tester.pump();

      expect(
        tester.widget<AnimatedOpacity>(pressLayer()).opacity,
        1,
        reason: 'removing the animation must never remove the information it '
            'carried: the press is still visible, it simply does not fade',
      );

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('reduced motion shortens the fade rather than removing it',
        (WidgetTester tester) async {
      await pumpTappable(tester, IuxMotionPreference.standard);
      final Duration full =
          tester.widget<AnimatedOpacity>(pressLayer()).duration;

      await pumpTappable(tester, IuxMotionPreference.reduced);
      final Duration reduced =
          tester.widget<AnimatedOpacity>(pressLayer()).duration;

      expect(reduced, lessThan(full));
      expect(reduced, greaterThan(Duration.zero));
    });
  });

  group('the row carries no business meaning', () {
    testWidgets('it emits no feedback of its own', (WidgetTester tester) async {
      // No haptic, no announcement, no snack bar. Those belong to the parent,
      // which is the only place that knows whether anything succeeded.
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

      await pump(
        tester,
        IuxListItem.selectable(
          title: 'March invoice',
          selected: IuxSelectionState.unselected,
          onSelectedChanged: (bool _) {},
        ),
      );
      await tester.tap(tapRegion());
      await tester.pumpAndSettle();

      expect(
        platform.where((MethodCall c) => c.method.startsWith('HapticFeedback')),
        isEmpty,
      );
    });
  });
}
