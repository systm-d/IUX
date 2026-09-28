import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

import '../support/contrast.dart';

/// A tag's tone: an accent dot, never a fill (systm-d/IUX#71, ADR-0016).
const List<(String, IuxThemeConfiguration)> _profiles =
    <(String, IuxThemeConfiguration)>[
  ('light', IuxThemeConfiguration()),
  ('dark', IuxThemeConfiguration(brightness: Brightness.dark)),
  (
    'light high contrast',
    IuxThemeConfiguration(
      profile: IuxAccessibilityProfile(contrast: IuxContrast.high),
    )
  ),
  (
    'dark high contrast',
    IuxThemeConfiguration(
      brightness: Brightness.dark,
      profile: IuxAccessibilityProfile(contrast: IuxContrast.high),
    )
  ),
];

void main() {
  Future<void> host(
    WidgetTester tester,
    Widget child, {
    IuxThemeConfiguration configuration = const IuxThemeConfiguration(),
    TextDirection direction = TextDirection.ltr,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: const Size(400, 800),
          textScaler: TextScaler.linear(textScale),
        ),
        child: MaterialApp(
          key: ValueKey<IuxThemeConfiguration>(configuration),
          theme: IuxTheme.fromConfiguration(configuration),
          home: Directionality(
            textDirection: direction,
            child: Scaffold(body: Center(child: child)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The accent dot inside a tag, found by its circle shape.
  Finder dot() => find.descendant(
        of: find.byType(IuxTagChip),
        matching: find.byWidgetPredicate(
          (Widget w) =>
              w is DecoratedBox &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).shape == BoxShape.circle,
        ),
      );

  Color dotColour(WidgetTester tester) =>
      (tester.widget<DecoratedBox>(dot()).decoration as BoxDecoration).color!;

  /// The tag's own pill, the outermost decorated box.
  BoxDecoration pill(WidgetTester tester) => tester
      .widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(IuxTagChip),
              matching: find.byType(DecoratedBox),
            )
            .first,
      )
      .decoration as BoxDecoration;

  IuxAvatarAccentRoleColors accent(IuxSemanticColors c, IuxAvatarTone tone) =>
      switch (tone) {
        IuxAvatarTone.one => c.avatarAccent.one,
        IuxAvatarTone.two => c.avatarAccent.two,
        IuxAvatarTone.three => c.avatarAccent.three,
        IuxAvatarTone.four => c.avatarAccent.four,
      };

  group('the tone is a dot in the avatar\'s colour', () {
    for (final (String name, IuxThemeConfiguration configuration)
        in _profiles) {
      for (final IuxAvatarTone tone in IuxAvatarTone.values) {
        testWidgets('$name, ${tone.name}', (WidgetTester tester) async {
          late IuxSemanticColors colors;
          late IuxChipTokens tokens;
          await host(
            tester,
            Builder(
              builder: (BuildContext context) {
                colors = IuxSemanticColors.of(context);
                tokens =
                    IuxChipResolver.resolve(context, IuxChipState.readOnly);
                return IuxTagChip(label: 'Library', tone: tone);
              },
            ),
            configuration: configuration,
          );

          // The same colour an avatar of this tone is filled with, so the two
          // match when they stand for the same thing.
          expect(dotColour(tester), accent(colors, tone).surface);

          // Visible against the tag it sits in. It carries no information the
          // words do not, so 1.4.11 does not strictly apply; a dot nobody can
          // see would still be a broken promise.
          final double ratio =
              ContrastMetric.ratio(dotColour(tester), tokens.background);
          expect(ratio, greaterThanOrEqualTo(3),
              reason: '$name ${tone.name}: ${ratio.toStringAsFixed(2)}:1');

          // The pill is untouched: never an action fill, whatever the tone.
          final BoxDecoration box = pill(tester);
          expect(box.color, tokens.background);
          expect(box.color, isNot(colors.action.primary.background));
          expect(box.color, isNot(colors.action.destructive.background));
        });
      }
    }
  });

  group('why the accent is not the fill', () {
    test('filled, tone one would be the primary button, to the value', () {
      // The measurement ADR-0016 rests on. If this stops being true in some
      // profile, the argument for a dot weakens there — revisit the record,
      // do not delete the test.
      for (final (String name, IuxThemeConfiguration configuration)
          in _profiles) {
        if (configuration.profile.contrast == IuxContrast.high &&
            configuration.brightness == Brightness.light) {
          continue;
        }
        final IuxSemanticColors c = IuxTheme.resolve(configuration).colors;
        expect(c.avatarAccent.one.surface, c.action.primary.background,
            reason: name);
      }
    });
  });

  group('it is never announced', () {
    testWidgets('a toned tag reads exactly like an untoned one',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(
          tester, const IuxTagChip(label: 'Library', tone: IuxAvatarTone.two));
      expect(
        tester.getSemantics(find.bySemanticsLabel('Library')),
        matchesSemantics(label: 'Library'),
      );
      handle.dispose();
    });
  });

  group('no tone, no dot', () {
    testWidgets('an untoned tag draws only its words',
        (WidgetTester tester) async {
      await host(tester, const IuxTagChip(label: 'Library'));
      expect(dot(), findsNothing);
    });
  });

  group('it holds in the removable form', () {
    testWidgets('the dot leads, the button still removes',
        (WidgetTester tester) async {
      int removed = 0;
      await host(
        tester,
        IuxTagChip.removable(
          label: 'acme',
          removeLabel: 'Remove acme',
          onRemove: () => removed++,
          tone: IuxAvatarTone.three,
        ),
      );
      expect(dot(), findsOneWidget);
      expect(
        tester.getCenter(dot()).dx,
        lessThan(tester.getCenter(find.text('acme')).dx),
      );
      await tester.tap(find.byIcon(Icons.close));
      expect(removed, 1);
    });
  });

  group('it survives the conditions the library promises', () {
    testWidgets('right to left, the dot leads at the reading start',
        (WidgetTester tester) async {
      await host(
        tester,
        const IuxTagChip(label: 'Library', tone: IuxAvatarTone.one),
        direction: TextDirection.rtl,
      );
      expect(
        tester.getCenter(dot()).dx,
        greaterThan(tester.getCenter(find.text('Library')).dx),
      );
    });

    testWidgets('at 200% text the dot grows with the words',
        (WidgetTester tester) async {
      await host(
          tester, const IuxTagChip(label: 'Library', tone: IuxAvatarTone.one));
      final double small = tester.getSize(dot()).width;
      await host(
        tester,
        const IuxTagChip(label: 'Library', tone: IuxAvatarTone.one),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(dot()).width, greaterThan(small));
    });
  });
}
