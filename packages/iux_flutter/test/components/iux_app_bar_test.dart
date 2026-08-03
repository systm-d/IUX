import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';
// whoever owns `lib/iux_flutter.dart`, and this mission does not.

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

/// A title long enough that no phone width fits it on one line.
const String _longTitle = 'Quarterly delivery exceptions';

void main() {
  /// Puts the bar where it is meant to go: the top of a `Scaffold` body, with
  /// the page below it. Deliberately not `Scaffold.appBar` — see the group
  /// "it composes with Scaffold rather than replacing AppBar".
  Future<void> pump(
    WidgetTester tester,
    Widget bar, {
    IuxThemeConfiguration configuration = const IuxThemeConfiguration(),
    TextDirection direction = TextDirection.ltr,
    double textScale = 1,
    Size size = const Size(400, 800),
    EdgeInsets padding = EdgeInsets.zero,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: size,
          padding: padding,
          textScaler: TextScaler.linear(textScale),
        ),
        child: MaterialApp(
          theme: IuxTheme.fromConfiguration(configuration),
          home: Directionality(
            textDirection: direction,
            child: Scaffold(
              body: Column(
                children: <Widget>[
                  bar,
                  const Expanded(child: SizedBox.expand()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  IuxIconButton action(
    IconData icon,
    String label, {
    VoidCallback? onActivate,
  }) =>
      IuxIconButton(
        icon: icon,
        action: IuxActionDescriptor(
          semantics: IuxActionSemantics(label: label),
        ),
        onActivate: onActivate ?? () {},
      );

  /// The rect of the nth control in the bar, leading first.
  Rect control(WidgetTester tester, int index) =>
      tester.getRect(find.byType(IuxIconButton).at(index));

  group('the title', () {
    testWidgets('it names the screen', (WidgetTester tester) async {
      await pump(tester, const IuxAppBar(title: 'Orders'));

      expect(find.text('Orders'), findsOneWidget);
    });

    testWidgets('it is a heading a screen reader can jump to',
        (WidgetTester tester) async {
      await pump(tester, const IuxAppBar(title: 'Orders'));

      final SemanticsNode node = tester.getSemantics(find.text('Orders'));
      expect(node.label, 'Orders');
      expect(node.flagsCollection.isHeader, isTrue);
    });

    testWidgets('it is never configured to truncate',
        (WidgetTester tester) async {
      await pump(tester, const IuxAppBar(title: _longTitle));

      final Text text = tester.widget<Text>(find.text(_longTitle));
      expect(text.maxLines, isNull);
      expect(text.overflow, isNot(TextOverflow.ellipsis));
      expect(text.softWrap, isTrue);
    });

    testWidgets('a long title wraps onto more lines rather than being cut',
        (WidgetTester tester) async {
      await pump(
        tester,
        const IuxAppBar(title: 'Orders'),
        size: const Size(320, 640),
      );
      final double oneLine = tester.getSize(find.text('Orders')).height;

      await pump(
        tester,
        const IuxAppBar(title: _longTitle),
        size: const Size(320, 640),
      );
      final double wrapped = tester.getSize(find.text(_longTitle)).height;

      expect(wrapped, greaterThan(oneLine));
      expect(tester.takeException(), isNull);
    });

    testWidgets('an empty title is unrepresentable',
        (WidgetTester tester) async {
      expect(() => IuxAppBar(title: ''), throwsAssertionError);
    });

    testWidgets('with no controls it takes the whole width',
        (WidgetTester tester) async {
      await pump(
        tester,
        const IuxAppBar(title: _longTitle),
        size: const Size(320, 640),
      );

      // The full width less the bar's own padding, and nothing else.
      expect(
          tester.getSize(find.text(_longTitle)).width, greaterThan(320 * 0.9));
    });
  });

  group('200% text on a 320-pixel screen', () {
    /// The case the component exists for: the narrowest place in an
    /// application, at the largest text a user is likely to ask for, with a way
    /// back and two actions already taking the width.
    Future<void> pumpWorstCase(
      WidgetTester tester, {
      IuxThemeConfiguration configuration = const IuxThemeConfiguration(),
      String title = _longTitle,
    }) =>
        pump(
          tester,
          IuxAppBar(
            title: title,
            leading: IuxAppBarLeading.back(
              label: 'Back to orders',
              onActivate: () {},
            ),
            actions: <IuxIconButton>[
              action(Icons.search, 'Search'),
              action(Icons.more_vert, 'More'),
            ],
          ),
          configuration: configuration,
          textScale: 2,
          size: const Size(320, 640),
        );

    testWidgets('the row gives way, not the title',
        (WidgetTester tester) async {
      await pumpWorstCase(tester);

      final Rect title = tester.getRect(find.text(_longTitle));
      final Rect back = control(tester, 0);

      // The title is below the controls, not squeezed between them.
      expect(title.top, greaterThanOrEqualTo(back.bottom));
      // And it starts at the leading edge of the bar rather than after the
      // back affordance.
      expect(title.left, lessThan(back.right));
    });

    testWidgets('the title keeps almost the whole width',
        (WidgetTester tester) async {
      await pumpWorstCase(tester);

      expect(
          tester.getSize(find.text(_longTitle)).width, greaterThan(320 * 0.85));
    });

    testWidgets('the bar grows instead of clipping',
        (WidgetTester tester) async {
      await pumpWorstCase(tester);

      // Taller than any fixed app bar height would have allowed, which is the
      // whole reason this is not a PreferredSizeWidget.
      expect(tester.getSize(find.byType(IuxAppBar)).height, greaterThan(56));
      expect(tester.takeException(), isNull);
    });

    testWidgets('nothing is truncated and nothing overflows, on any profile',
        (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in _profiles) {
        await pumpWorstCase(tester, configuration: configuration);

        final Text text = tester.widget<Text>(find.text(_longTitle));
        expect(text.maxLines, isNull);
        expect(text.overflow, isNot(TextOverflow.ellipsis));
        expect(
          tester.getSize(find.text(_longTitle)).width,
          greaterThan(320 * 0.85),
        );
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('every control still meets the touch target floor',
        (WidgetTester tester) async {
      await pumpWorstCase(tester);

      for (int i = 0; i < 3; i++) {
        final Rect rect = control(tester, i);
        expect(rect.width, greaterThanOrEqualTo(IuxTouchTarget.minimum));
        expect(rect.height, greaterThanOrEqualTo(IuxTouchTarget.minimum));
      }
    });

    testWidgets('adjacent controls keep the minimum separation',
        (WidgetTester tester) async {
      await pumpWorstCase(tester);

      for (int i = 1; i < 3; i++) {
        expect(
          control(tester, i).left - control(tester, i - 1).right,
          greaterThanOrEqualTo(kIuxMinimumTargetSpacing),
        );
      }
    });

    testWidgets('the reading order is still controls then heading',
        (WidgetTester tester) async {
      await pumpWorstCase(tester);

      final List<String> spoken = <String>[];
      void visit(SemanticsNode node) {
        final String label = node.getSemanticsData().label;
        if (label.isNotEmpty) spoken.add(label);
        node.visitChildren((SemanticsNode child) {
          visit(child);
          return true;
        });
      }

      visit(tester.getSemantics(find.byType(IuxAppBar)));
      expect(spoken, <String>['Back to orders', 'Search', 'More', _longTitle]);
    });
  });

  group('when the title fits, it keeps the row', () {
    testWidgets('a short title shares the row with the controls',
        (WidgetTester tester) async {
      await pump(
        tester,
        IuxAppBar(
          title: 'Home',
          leading: IuxAppBarLeading.back(label: 'Back', onActivate: () {}),
          actions: <IuxIconButton>[action(Icons.search, 'Search')],
        ),
        size: const Size(320, 640),
      );

      final Rect title = tester.getRect(find.text('Home'));
      final Rect back = control(tester, 0);
      final Rect search = control(tester, 1);

      expect(title.left, greaterThan(back.right));
      expect(title.right, lessThanOrEqualTo(search.left));
    });

    testWidgets('a long title leaves the row even at ordinary text size',
        (WidgetTester tester) async {
      await pump(
        tester,
        IuxAppBar(
          title: _longTitle,
          leading: IuxAppBarLeading.back(label: 'Back', onActivate: () {}),
          actions: <IuxIconButton>[
            action(Icons.search, 'Search'),
            action(Icons.more_vert, 'More'),
          ],
        ),
        size: const Size(320, 640),
      );

      // Three controls on a 320-pixel screen leave the title too little room
      // to be worth sharing, whatever the text size.
      expect(
        tester.getRect(find.text(_longTitle)).top,
        greaterThanOrEqualTo(control(tester, 0).bottom),
      );
    });
  });

  group('the way out', () {
    testWidgets('it is named, and the name is the caller\'s',
        (WidgetTester tester) async {
      await pump(
        tester,
        IuxAppBar(
          title: 'Orders',
          leading: IuxAppBarLeading.back(
            label: 'Retour aux commandes',
            onActivate: () {},
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byType(IuxIconButton)),
        matchesSemantics(
          label: 'Retour aux commandes',
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          hasTapAction: true,
        ),
      );
    });

    testWidgets('an unnamed way out is unrepresentable',
        (WidgetTester tester) async {
      expect(
        () => IuxAppBarLeading.back(label: '', onActivate: () {}),
        throwsAssertionError,
      );
      expect(
        () => IuxAppBarLeading.close(label: '', onActivate: () {}),
        throwsAssertionError,
      );
    });

    testWidgets('it reports intent once per activation',
        (WidgetTester tester) async {
      int calls = 0;
      await pump(
        tester,
        IuxAppBar(
          title: 'Orders',
          leading: IuxAppBarLeading.back(
            label: 'Back',
            onActivate: () => calls++,
          ),
        ),
      );

      await tester.tap(find.byType(IuxIconButton));
      await tester.pumpAndSettle();

      expect(calls, 1);
    });

    testWidgets('back and close are different affordances',
        (WidgetTester tester) async {
      const IuxAppBarLeading back = IuxAppBarLeading.back(
        label: 'Back',
        onActivate: _noop,
      );
      const IuxAppBarLeading close = IuxAppBarLeading.close(
        label: 'Close',
        onActivate: _noop,
      );

      expect(back.icon, isNot(close.icon));
      expect(back.action.role, IuxActionRole.navigate);
      expect(close.action.role, IuxActionRole.dismiss);
    });

    testWidgets('the arrow mirrors itself right-to-left',
        (WidgetTester tester) async {
      // The affordance points out of the screen in both reading directions,
      // and it does so because the glyph declares it rather than because the
      // component branches on the locale.
      expect(Icons.arrow_back.matchTextDirection, isTrue);
    });

    testWidgets('a root screen draws none', (WidgetTester tester) async {
      await pump(tester, const IuxAppBar(title: 'Orders'));

      expect(find.byType(IuxIconButton), findsNothing);
    });
  });

  group('actions', () {
    testWidgets('each one is announced by its own name',
        (WidgetTester tester) async {
      await pump(
        tester,
        IuxAppBar(
          title: 'Orders',
          actions: <IuxIconButton>[
            action(Icons.search, 'Search'),
            action(Icons.filter_list, 'Filter'),
          ],
        ),
      );

      expect(tester.getSemantics(find.byIcon(Icons.search)).label, 'Search');
      expect(
          tester.getSemantics(find.byIcon(Icons.filter_list)).label, 'Filter');
    });

    testWidgets('one reports its own activation', (WidgetTester tester) async {
      int calls = 0;
      await pump(
        tester,
        IuxAppBar(
          title: 'Orders',
          actions: <IuxIconButton>[
            action(Icons.search, 'Search', onActivate: () => calls++),
          ],
        ),
      );

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      expect(calls, 1);
    });

    testWidgets('a disabled one is announced, not merely greyed',
        (WidgetTester tester) async {
      await pump(
        tester,
        IuxAppBar(
          title: 'Orders',
          actions: <IuxIconButton>[
            IuxIconButton(
              icon: Icons.share,
              action: const IuxActionDescriptor(
                semantics: IuxActionSemantics(
                  label: 'Share',
                  unavailabilityReason: 'Nothing selected',
                ),
                availability: IuxActionAvailability.disabled,
              ),
              onActivate: () {},
            ),
          ],
        ),
      );

      expect(
        tester.getSemantics(find.byIcon(Icons.share)),
        matchesSemantics(
          label: 'Share',
          hint: 'Nothing selected',
          isButton: true,
          hasEnabledState: true,
        ),
      );
    });

    testWidgets('a fourth action is refused', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: IuxTheme.fromConfiguration(const IuxThemeConfiguration()),
          home: IuxAppBar(
            title: 'Orders',
            actions: <IuxIconButton>[
              action(Icons.search, 'Search'),
              action(Icons.filter_list, 'Filter'),
              action(Icons.share, 'Share'),
              action(Icons.more_vert, 'More'),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isA<AssertionError>());
    });

    testWidgets('three are accepted', (WidgetTester tester) async {
      await pump(
        tester,
        IuxAppBar(
          title: 'Orders',
          actions: <IuxIconButton>[
            action(Icons.search, 'Search'),
            action(Icons.filter_list, 'Filter'),
            action(Icons.more_vert, 'More'),
          ],
        ),
      );

      expect(find.byType(IuxIconButton), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });
  });

  group('direction, insets and shape', () {
    testWidgets('right-to-left puts the way out on the trailing edge',
        (WidgetTester tester) async {
      await pump(
        tester,
        IuxAppBar(
          title: 'الطلبات',
          leading: IuxAppBarLeading.back(label: 'رجوع', onActivate: () {}),
          actions: <IuxIconButton>[action(Icons.search, 'بحث')],
        ),
        direction: TextDirection.rtl,
        size: const Size(320, 640),
      );

      expect(control(tester, 0).right, greaterThan(160));
      expect(control(tester, 1).right, lessThan(160));
      expect(tester.takeException(), isNull);
    });

    testWidgets('it consumes the top system inset itself',
        (WidgetTester tester) async {
      await pump(
        tester,
        IuxAppBar(
          title: 'Orders',
          leading: IuxAppBarLeading.back(label: 'Back', onActivate: () {}),
        ),
        padding: const EdgeInsets.only(top: 40),
      );

      // Which is why the page below it must be IuxPageInsets.bottomOnly: the
      // inset has already been spent here.
      expect(control(tester, 0).top, greaterThanOrEqualTo(40));
      expect(
        tester.getSize(find.byType(IuxAppBar)).height,
        greaterThanOrEqualTo(40 + IuxTouchTarget.minimum),
      );
    });

    testWidgets('it is at least as tall as a control it can hold',
        (WidgetTester tester) async {
      await pump(tester, const IuxAppBar(title: 'Orders'));

      expect(
        tester.getSize(find.byType(IuxAppBar)).height,
        greaterThanOrEqualTo(IuxTouchTarget.minimum),
      );
    });

    testWidgets('it draws a measurable boundary against the page',
        (WidgetTester tester) async {
      const IuxThemeConfiguration configuration = IuxThemeConfiguration();
      await pump(
        tester,
        const IuxAppBar(title: 'Orders'),
        configuration: configuration,
      );

      final BoxDecoration decoration = tester
          .widget<DecoratedBox>(
            find
                .descendant(
                  of: find.byType(IuxAppBar),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          )
          .decoration as BoxDecoration;
      final IuxSemanticColors colors = IuxTheme.fromConfiguration(configuration)
          .extension<IuxSemanticColors>()!;

      expect(decoration.color, colors.surface.base);
      expect(
          (decoration.border! as Border).bottom.color, colors.border.standard);
      // No shadow: a boundary a visual-stimulation preference can delete is
      // not a boundary.
      expect(decoration.boxShadow, isNull);
    });

    testWidgets('it renders on every theme profile',
        (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in _profiles) {
        await pump(
          tester,
          IuxAppBar(
            title: 'Orders',
            leading: IuxAppBarLeading.back(label: 'Back', onActivate: () {}),
            actions: <IuxIconButton>[action(Icons.search, 'Search')],
          ),
          configuration: configuration,
        );

        expect(find.text('Orders'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('removing motion removes nothing', (WidgetTester tester) async {
      await pump(
        tester,
        IuxAppBar(
          title: _longTitle,
          leading: IuxAppBarLeading.back(label: 'Back', onActivate: () {}),
        ),
      );
      final Size standard = tester.getSize(find.byType(IuxAppBar));

      await pump(
        tester,
        IuxAppBar(
          title: _longTitle,
          leading: IuxAppBarLeading.back(label: 'Back', onActivate: () {}),
        ),
        configuration: const IuxThemeConfiguration(
          profile: IuxAccessibilityProfile(motion: IuxMotionPreference.none),
        ),
      );

      // The bar has no motion of its own, so there is nothing for a preference
      // to take away.
      expect(tester.getSize(find.byType(IuxAppBar)), standard);
      expect(find.text(_longTitle), findsOneWidget);
    });
  });

  group('it composes with Scaffold rather than replacing AppBar', () {
    test('it is not a PreferredSizeWidget', () {
      // Deliberate. Scaffold.appBar caps its child at a height read before
      // layout, with no access to the text scale, the width or the number of
      // lines the title will take. A height fixed in advance and a title that
      // must not be truncated cannot both hold.
      expect(
        const IuxAppBar(title: 'Orders'),
        isNot(isA<PreferredSizeWidget>()),
      );
    });

    testWidgets('it does not build a Material AppBar',
        (WidgetTester tester) async {
      await pump(tester, const IuxAppBar(title: 'Orders'));

      expect(find.byType(AppBar), findsNothing);
    });
  });
}

void _noop() {}
