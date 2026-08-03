import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';
// Imported from source rather than from the barrel: IUX-022 does not own
// lib/iux_flutter.dart, so the exports are added by whoever integrates the
// mission. The behaviour asserted here is the same either way.

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// A decoded picture, for the tests that need one to arrive.
  ///
  /// Built once here rather than inside each test: decoding goes through the
  /// engine, and a `testWidgets` body runs in a fake-async zone where that
  /// callback never returns. `setUpAll` runs outside it.
  late ui.Image decoded;

  setUpAll(() async {
    decoded = await createTestImage(width: 64, height: 64);
  });

  tearDownAll(() => decoded.dispose());

  // Each fake provider below is its own cache key, but the cache is global and
  // a stale entry would let one test observe another test's picture.
  setUp(() => PaintingBinding.instance.imageCache.clear());

  Future<void> host(
    WidgetTester tester,
    Widget child, {
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
          // Keyed by configuration so a test that switches profiles gets the
          // new theme outright rather than a cross-fade whose colours belong
          // to neither.
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

  /// Resolves what a widget would paint under [configuration], without
  /// rendering one.
  Future<T> resolve<T>(
    WidgetTester tester,
    IuxThemeConfiguration configuration,
    T Function(BuildContext context) resolver, {
    double textScale = 1,
  }) async {
    late T resolved;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: MaterialApp(
          key: ValueKey<IuxThemeConfiguration>(configuration),
          theme: IuxTheme.fromConfiguration(configuration),
          home: Builder(
            builder: (BuildContext context) {
              resolved = resolver(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return resolved;
  }

  IuxSemanticColors colorsOf(IuxThemeConfiguration configuration) =>
      IuxTheme.resolve(configuration).colors;

  // ==========================================================================
  // The decision the caller cannot avoid
  // ==========================================================================

  group('a picture must declare whether it says anything', () {
    test('a meaningful description refuses to be empty', () {
      // The whole mission rests on this. An empty description on a meaningful
      // image produces an image node with no name: the user is told something
      // is there and refused any way to know what. It is made unconstructable
      // rather than discouraged.
      expect(
        () => IuxImageDescription.meaningful(''),
        throwsAssertionError,
      );
    });

    test('decoration is declared, never inferred from a missing string', () {
      // The two states are recorded separately so that a forgotten description
      // and a deliberate absence of one cannot become the same value in a
      // release build, where the assertion above no longer runs.
      const IuxImageDescription decorative = IuxImageDescription.decorative();
      expect(decorative.isDecorative, isTrue);
      expect(decorative.isMeaningful, isFalse);
      expect(decorative.description, isEmpty);

      const IuxImageDescription meaningful =
          IuxImageDescription.meaningful('Blue running shoe, side view');
      expect(meaningful.isDecorative, isFalse);
      expect(meaningful.isMeaningful, isTrue);
      expect(meaningful.description, 'Blue running shoe, side view');
    });

    test('the meaning travels with the words and cannot be separated', () {
      const IuxImageDescription a = IuxImageDescription.meaningful('Receipt');
      expect(a, const IuxImageDescription.meaningful('Receipt'));
      expect(a, isNot(const IuxImageDescription.meaningful('Invoice')));
      expect(a, isNot(const IuxImageDescription.decorative()));
      expect(
        a.hashCode,
        const IuxImageDescription.meaningful('Receipt').hashCode,
      );
      expect(a.toString(), contains('Receipt'));
      expect(
        const IuxImageDescription.decorative().toString(),
        contains('decorative'),
      );
    });
  });

  // ==========================================================================
  // IuxIcon
  // ==========================================================================

  group('a glyph says what it was told to say, and nothing when it was not',
      () {
    testWidgets('a meaningful glyph is announced as a named image',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(
        tester,
        const IuxIcon(
          icon: Icons.lock_outline,
          description: IuxImageDescription.meaningful('Private album'),
        ),
      );

      expect(find.bySemanticsLabel('Private album'), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(IuxIcon)).flagsCollection.isImage,
        isTrue,
      );
      handle.dispose();
    });

    testWidgets('a decorative glyph produces no node at all',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(
        tester,
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IuxIcon(
              icon: Icons.delete_outline,
              description: IuxImageDescription.decorative(),
            ),
            Text('Delete'),
          ],
        ),
      );

      // Drawn, and skipped. A row whose glyph repeats its label costs a
      // screen-reader user one extra stop on every visit and tells them
      // nothing they did not already have.
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(IuxIcon)).flagsCollection.isImage,
        isFalse,
      );
      expect(find.bySemanticsLabel('Delete'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the glyph grows with the text it sits beside',
        (WidgetTester tester) async {
      final IuxIconTokens single = await resolve(
        tester,
        const IuxThemeConfiguration(),
        (BuildContext context) => IuxIconResolver.resolve(context),
      );
      final IuxIconTokens doubled = await resolve(
        tester,
        const IuxThemeConfiguration(),
        (BuildContext context) => IuxIconResolver.resolve(context),
        textScale: 2,
      );

      // A glyph that stayed 24 pixels while its label doubled is a glyph the
      // person who enlarged their text can no longer see — and when it is the
      // only content in its slot, that is the whole row lost.
      expect(doubled.size, greaterThan(single.size));
      expect(doubled.size, single.size * 2);
    });

    testWidgets('the glyph is scaled once, not twice',
        (WidgetTester tester) async {
      await host(
        tester,
        const IuxIcon(
          icon: Icons.lock_outline,
          description: IuxImageDescription.decorative(),
        ),
        textScale: 2,
      );

      // Flutter would scale an Icon again at paint time on top of the size the
      // resolver already scaled, enlarging the glyph twice as fast as the text.
      final Icon icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.applyTextScaling, isFalse);
      expect(icon.size, 48);
    });

    testWidgets('emphasis names a content role, never a colour',
        (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in _profiles) {
        final IuxSemanticColors colors = colorsOf(configuration);

        final IuxIconTokens primary = await resolve(
          tester,
          configuration,
          (BuildContext context) => IuxIconResolver.resolve(context),
        );
        final IuxIconTokens secondary = await resolve(
          tester,
          configuration,
          (BuildContext context) => IuxIconResolver.resolve(
            context,
            emphasis: IuxIconEmphasis.secondary,
          ),
        );

        expect(primary.color, colors.content.primary);
        expect(secondary.color, colors.content.secondary);
      }
    });

    testWidgets('a small glyph is smaller than a standalone one, everywhere',
        (WidgetTester tester) async {
      final IuxIconTokens small = await resolve(
        tester,
        const IuxThemeConfiguration(),
        (BuildContext context) =>
            IuxIconResolver.resolve(context, size: IuxIconSize.small),
      );
      final IuxIconTokens standard = await resolve(
        tester,
        const IuxThemeConfiguration(),
        (BuildContext context) => IuxIconResolver.resolve(context),
      );
      expect(small.size, lessThan(standard.size));
    });

    testWidgets('a glyph renders on every theme profile',
        (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in _profiles) {
        await host(
          tester,
          const IuxIcon(
            icon: Icons.lock_outline,
            description: IuxImageDescription.meaningful('Private'),
          ),
          configuration: configuration,
        );
        expect(tester.takeException(), isNull);
        expect(find.bySemanticsLabel('Private'), findsOneWidget);
      }
    });
  });

  // ==========================================================================
  // IuxAvatar — the initials are not the name
  // ==========================================================================

  group('an avatar announces a person, never their initials', () {
    testWidgets('the name is announced and the initials never are',
        (WidgetTester tester) async {
      await host(
        tester,
        const IuxAvatar(name: 'Maria Costa', initials: 'MC'),
      );

      // "MC" spoken to a screen reader is a spelling, not a person. The
      // separation is structural: there is no arrangement of parameters that
      // gets the initials announced.
      expect(find.text('MC'), findsOneWidget);
      expect(find.bySemanticsLabel('Maria Costa'), findsOneWidget);
      expect(find.bySemanticsLabel('MC'), findsNothing);
    });

    testWidgets('a decorative avatar announces nothing at all',
        (WidgetTester tester) async {
      await host(
        tester,
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IuxAvatar.decorative(initials: 'MC'),
            Text('Maria Costa'),
          ],
        ),
      );

      // The row already carries the name. Announcing the circle as well turns
      // a list of twenty participants into forty utterances carrying twenty
      // facts.
      expect(find.text('MC'), findsOneWidget);
      expect(find.bySemanticsLabel('MC'), findsNothing);
      expect(find.bySemanticsLabel('Maria Costa'), findsOneWidget);
    });

    test('a named avatar refuses an empty name', () {
      expect(() => IuxAvatar(name: ''), throwsAssertionError);
    });

    test('empty initials are refused rather than drawn', () {
      // An empty string draws an empty circle, which reads as a rendering
      // failure. Null is the supported way to say "no initials" and produces
      // the neutral glyph.
      expect(
        () => IuxAvatar(name: 'Maria Costa', initials: ''),
        throwsAssertionError,
      );
      expect(() => IuxAvatar.decorative(initials: ''), throwsAssertionError);
    });

    testWidgets('no photograph and no initials leaves a glyph, not a hole',
        (WidgetTester tester) async {
      await host(tester, const IuxAvatar(name: 'Maria Costa'));

      // A glyph claims nothing about who this is, which is the right thing to
      // claim when the application could not build initials for the script the
      // name is written in.
      expect(find.byType(Icon), findsOneWidget);
      expect(find.bySemanticsLabel('Maria Costa'), findsOneWidget);
    });

    testWidgets('the circle grows with the text inside it',
        (WidgetTester tester) async {
      final IuxAvatarTokens single = await resolve(
        tester,
        const IuxThemeConfiguration(),
        (BuildContext context) => IuxAvatarResolver.resolve(context),
      );
      final IuxAvatarTokens doubled = await resolve(
        tester,
        const IuxThemeConfiguration(),
        (BuildContext context) => IuxAvatarResolver.resolve(context),
        textScale: 2,
      );
      final IuxAvatarTokens large = await resolve(
        tester,
        const IuxThemeConfiguration(),
        (BuildContext context) =>
            IuxAvatarResolver.resolve(context, size: IuxAvatarSize.large),
      );

      expect(doubled.diameter, single.diameter * 2);
      expect(large.diameter, greaterThan(single.diameter));
    });

    testWidgets('the initials stay readable on the circle, on every profile',
        (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in _profiles) {
        final IuxAvatarTokens tokens = await resolve(
          tester,
          configuration,
          (BuildContext context) => IuxAvatarResolver.resolve(context),
        );
        expect(
          ContrastMetric.ratio(tokens.foreground, tokens.background),
          greaterThanOrEqualTo(ContrastMetric.normalText),
          reason: 'initials on the avatar surface, $configuration',
        );
      }
    });

    testWidgets('an avatar renders on every theme profile',
        (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in _profiles) {
        await host(
          tester,
          const IuxAvatar(name: 'Maria Costa', initials: 'MC'),
          configuration: configuration,
        );
        expect(tester.takeException(), isNull);
        expect(find.bySemanticsLabel('Maria Costa'), findsOneWidget);
      }
    });

    testWidgets('an avatar reads the same way right to left',
        (WidgetTester tester) async {
      await host(
        tester,
        const IuxAvatar(name: 'مريم', initials: 'م'),
        direction: TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
      expect(find.bySemanticsLabel('مريم'), findsOneWidget);
    });
  });

  // ==========================================================================
  // IuxAvatar — a photograph that never arrives
  // ==========================================================================

  group('an avatar never shows a blank circle', () {
    testWidgets('a photograph that fails leaves the initials and the name',
        (WidgetTester tester) async {
      await host(
        tester,
        IuxAvatar(
          name: 'Maria Costa',
          initials: 'MC',
          image: _UnavailableImage(),
        ),
      );
      await tester.pumpAndSettle();

      // Offline, 404, malformed file, revoked URL: the user sees what they saw
      // a moment earlier. There is nothing to report because the photograph
      // carried nothing the name did not.
      expect(tester.takeException(), isNull);
      expect(find.text('MC'), findsOneWidget);
      expect(find.bySemanticsLabel('Maria Costa'), findsOneWidget);
    });

    testWidgets('a photograph that has not arrived yet leaves the initials',
        (WidgetTester tester) async {
      await host(
        tester,
        IuxAvatar(
          name: 'Maria Costa',
          initials: 'MC',
          image: _PendingImage(),
        ),
      );

      // The slow case, which is the common one. A circle that is empty until
      // the network answers is a circle the user cannot interpret, and on a
      // bad connection it is empty for a long time.
      expect(find.text('MC'), findsOneWidget);
      expect(find.bySemanticsLabel('Maria Costa'), findsOneWidget);
    });

    testWidgets('a photograph that fails with no initials leaves the glyph',
        (WidgetTester tester) async {
      await host(
        tester,
        IuxAvatar(name: 'Maria Costa', image: _UnavailableImage()),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(Icon), findsOneWidget);
      expect(find.bySemanticsLabel('Maria Costa'), findsOneWidget);
    });

    testWidgets('a photograph that arrives replaces the fallback, not the name',
        (WidgetTester tester) async {
      await host(
        tester,
        IuxAvatar(
          name: 'Maria Costa',
          initials: 'MC',
          image: _ReadyImage(decoded),
        ),
      );

      expect(find.text('MC'), findsNothing);
      expect(find.byType(RawImage), findsOneWidget);
      // The accessible name does not depend on whether the picture loaded.
      expect(find.bySemanticsLabel('Maria Costa'), findsOneWidget);
    });

    testWidgets('a loaded photograph adds no announcement of its own',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(
        tester,
        IuxAvatar(
          name: 'Maria Costa',
          initials: 'MC',
          image: _ReadyImage(decoded),
        ),
      );

      final SemanticsNode node = tester.getSemantics(find.byType(IuxAvatar));
      expect(node.flagsCollection.isImage, isTrue);
      expect(node.getSemanticsData().label, 'Maria Costa');
      handle.dispose();
    });
  });

  // ==========================================================================
  // IuxAvatar — never a control
  // ==========================================================================

  group('an avatar is not a control, so it can live inside one', () {
    testWidgets('it advertises no button role and no tap action',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(
        tester,
        const IuxAvatar(name: 'Maria Costa', initials: 'MC'),
      );

      final SemanticsNode node = tester.getSemantics(find.byType(IuxAvatar));
      expect(node.flagsCollection.isButton, isFalse);
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.tap),
        isFalse,
        reason: 'an avatar that answered a double-tap would be a control with '
            'no name and no target floor',
      );
      handle.dispose();
    });

    testWidgets('a tappable card accepts an avatar without complaint',
        (WidgetTester tester) async {
      await host(
        tester,
        IuxCard.tappable(
          semanticLabel: 'Maria Costa, open profile',
          onActivate: () {},
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IuxAvatar.decorative(initials: 'MC'),
              Text('Maria Costa'),
            ],
          ),
        ),
      );
      // The card's debug guard walks its content after the first frame and
      // throws on any nested control. An avatar that were independently
      // tappable would fail here — which is the reason it is not.
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  // ==========================================================================
  // IuxImage — the frame, and what it says in each state
  // ==========================================================================

  group('a picture reserves its frame before it exists', () {
    test('an aspect ratio that cannot describe a box is refused', () {
      expect(
        () => IuxImage(
          image: _PendingImage(),
          description: const IuxImageDescription.decorative(),
          aspectRatio: 0,
        ),
        throwsAssertionError,
      );
      expect(
        () => IuxImage(
          image: _PendingImage(),
          description: const IuxImageDescription.decorative(),
          aspectRatio: -1,
        ),
        throwsAssertionError,
      );
      expect(
        () => IuxImage(
          image: _PendingImage(),
          description: const IuxImageDescription.decorative(),
          aspectRatio: double.infinity,
        ),
        throwsAssertionError,
      );
    });

    testWidgets('the box is the reserved size before the picture arrives',
        (WidgetTester tester) async {
      await host(
        tester,
        SizedBox(
          width: 300,
          child: IuxImage(
            image: _PendingImage(),
            description: const IuxImageDescription.meaningful('A receipt'),
            aspectRatio: 2,
          ),
        ),
      );

      // A frame that grew on arrival would move everything below it, on the
      // slow connections where the delay is longest and a finger is already
      // travelling toward whatever was there.
      expect(tester.getSize(find.byType(IuxImage)), const Size(300, 150));
    });

    testWidgets('the box keeps its size once the picture arrives',
        (WidgetTester tester) async {
      await host(
        tester,
        SizedBox(
          width: 300,
          child: IuxImage(
            image: _ReadyImage(decoded),
            description: const IuxImageDescription.meaningful('A receipt'),
            aspectRatio: 2,
          ),
        ),
      );

      expect(tester.getSize(find.byType(IuxImage)), const Size(300, 150));
      expect(find.byType(RawImage), findsOneWidget);
    });
  });

  group('a picture says what it was told to say, in every state', () {
    testWidgets('a loaded meaningful picture is a named image node',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(
        tester,
        IuxImage(
          image: _ReadyImage(decoded),
          description: const IuxImageDescription.meaningful(
            'Blue running shoe, side view',
          ),
          aspectRatio: 1,
        ),
      );

      final SemanticsNode node = tester.getSemantics(find.byType(IuxImage));
      expect(node.flagsCollection.isImage, isTrue);
      expect(node.getSemanticsData().label, 'Blue running shoe, side view');
      handle.dispose();
    });

    testWidgets('a loaded decorative picture is not in the tree at all',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(
        tester,
        IuxImage(
          image: _ReadyImage(decoded),
          description: const IuxImageDescription.decorative(),
          aspectRatio: 1,
        ),
      );

      expect(
        tester.getSemantics(find.byType(IuxImage)).flagsCollection.isImage,
        isFalse,
      );
      handle.dispose();
    });

    testWidgets('a picture still loading is already named',
        (WidgetTester tester) async {
      await host(
        tester,
        IuxImage(
          image: _PendingImage(),
          description: const IuxImageDescription.meaningful('A receipt'),
          aspectRatio: 1,
        ),
      );

      // What a browser does with alt text. The alternative — announcing
      // "loading" — either interrupts the user for something that resolves in
      // a second, or leaves the node nameless until it does.
      expect(find.bySemanticsLabel('A receipt'), findsOneWidget);
    });

    testWidgets('nothing spins while a picture loads',
        (WidgetTester tester) async {
      await host(
        tester,
        IuxImage(
          image: _PendingImage(),
          description: const IuxImageDescription.decorative(),
          aspectRatio: 1,
        ),
      );

      // One indicator per picture turns a scrolling list into a field of
      // moving parts, and a reduced-motion profile removes every one of them,
      // leaving nothing in their place. The filled frame is the signal.
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });
  });

  // ==========================================================================
  // IuxImage — failure
  // ==========================================================================

  group('a picture that fails hands over what it was carrying', () {
    testWidgets('the description is drawn in the picture’s place',
        (WidgetTester tester) async {
      await host(
        tester,
        SizedBox(
          width: 300,
          child: IuxImage(
            image: _UnavailableImage(),
            description: const IuxImageDescription.meaningful(
              'Sales rose 20% in the third quarter',
            ),
            aspectRatio: 2,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // The information the picture carried survives the picture. Nothing is
      // invented: the words on screen are the words the caller already wrote.
      expect(find.text('Sales rose 20% in the third quarter'), findsOneWidget);
    });

    testWidgets('a distinct shape says "missing", not a shade of grey',
        (WidgetTester tester) async {
      await host(
        tester,
        SizedBox(
          width: 300,
          child: IuxImage(
            image: _UnavailableImage(),
            description: const IuxImageDescription.meaningful('A receipt'),
            aspectRatio: 2,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Render the screen in one hue and every state that disappears was
      // carried by colour alone. A glyph and an outline both survive it.
      final IuxImageTokens tokens = await resolve(
        tester,
        const IuxThemeConfiguration(),
        IuxImageResolver.resolve,
      );
      await host(
        tester,
        SizedBox(
          width: 300,
          child: IuxImage(
            image: _UnavailableImage(),
            description: const IuxImageDescription.meaningful('A receipt'),
            aspectRatio: 2,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(tokens.unavailableGlyph), findsOneWidget);
    });

    testWidgets('the failed picture is announced as text, not as an image',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(
        tester,
        SizedBox(
          width: 300,
          child: IuxImage(
            image: _UnavailableImage(),
            description: const IuxImageDescription.meaningful('A receipt'),
            aspectRatio: 2,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final SemanticsNode node = tester.getSemantics(find.text('A receipt'));
      expect(node.getSemanticsData().label, 'A receipt');
      // There is no image any more. A node that still claimed to be one would
      // describe something the user cannot reach.
      expect(node.flagsCollection.isImage, isFalse);
      handle.dispose();
    });

    testWidgets('the glyph adds no second announcement of its own',
        (WidgetTester tester) async {
      await host(
        tester,
        SizedBox(
          width: 300,
          child: IuxImage(
            image: _UnavailableImage(),
            description: const IuxImageDescription.meaningful('A receipt'),
            aspectRatio: 2,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Exactly one node carries the sentence. A glyph announced beside it
      // would be a second utterance saying nothing new.
      expect(find.bySemanticsLabel('A receipt'), findsOneWidget);
    });

    testWidgets(
        'a decorative picture that fails says nothing and shows nothing',
        (WidgetTester tester) async {
      await host(
        tester,
        SizedBox(
          width: 300,
          child: IuxImage(
            image: _UnavailableImage(),
            description: const IuxImageDescription.decorative(),
            aspectRatio: 2,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Nothing was lost, so nothing is reported. A broken-picture glyph here
      // would be an error message about a non-event.
      expect(tester.takeException(), isNull);
      expect(find.byType(Icon), findsNothing);
      expect(find.byType(Text), findsNothing);
      // The frame keeps its space so the page does not reflow around an
      // absence.
      expect(tester.getSize(find.byType(IuxImage)), const Size(300, 150));
    });

    testWidgets('the reserved height is a floor, so a long description fits',
        (WidgetTester tester) async {
      const String long =
          'Quarterly revenue by region: northern Europe rose 20%, southern '
          'Europe fell 4%, and the remaining regions were unchanged from the '
          'previous quarter.';

      await host(
        tester,
        // A scroll view, because that is where a picture lives on a real page,
        // and because the replacement text is allowed to be taller than the
        // frame it replaced. A picture pinned inside a fixed-height box has
        // nowhere to put the sentence; see the limits in docs/components.
        SingleChildScrollView(
          child: SizedBox(
            width: 300,
            child: IuxImage(
              image: _UnavailableImage(),
              description: const IuxImageDescription.meaningful(long),
              aspectRatio: 3,
            ),
          ),
        ),
        textScale: 2,
      );
      await tester.pumpAndSettle();

      // Clipping the text that replaced the picture would lose the information
      // twice — and it would happen at exactly the text size a user chose in
      // order to read it.
      expect(tester.takeException(), isNull);
      expect(find.text(long), findsOneWidget);
      expect(
        tester.getSize(find.byType(IuxImage)).height,
        greaterThan(100),
        reason: 'the frame grew past the reserved 300/3 to fit the sentence',
      );
    });

    testWidgets('the replacement text stays readable on every profile',
        (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in _profiles) {
        final IuxImageTokens tokens = await resolve(
          tester,
          configuration,
          IuxImageResolver.resolve,
        );
        expect(
          ContrastMetric.ratio(tokens.textStyle.color!, tokens.background),
          greaterThanOrEqualTo(ContrastMetric.normalText),
          reason: 'replacement text on the frame, $configuration',
        );
        expect(
          ContrastMetric.ratio(tokens.border, tokens.background),
          greaterThanOrEqualTo(ContrastMetric.nonText),
          reason: 'frame outline, $configuration',
        );
      }
    });

    testWidgets('a failed picture renders on every theme profile',
        (WidgetTester tester) async {
      for (final IuxThemeConfiguration configuration in _profiles) {
        await host(
          tester,
          SizedBox(
            width: 300,
            child: IuxImage(
              image: _UnavailableImage(),
              description: const IuxImageDescription.meaningful('A receipt'),
              aspectRatio: 2,
            ),
          ),
          configuration: configuration,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('A receipt'), findsOneWidget);
      }
    });
  });

  // ==========================================================================
  // IuxImage — never a control, and never a network client
  // ==========================================================================

  group('a picture is presentation and nothing else', () {
    testWidgets('it advertises no button role and no tap action',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await host(
        tester,
        IuxImage(
          image: _ReadyImage(decoded),
          description: const IuxImageDescription.meaningful('A receipt'),
          aspectRatio: 1,
        ),
      );

      final SemanticsNode node = tester.getSemantics(find.byType(IuxImage));
      expect(node.flagsCollection.isButton, isFalse);
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
      handle.dispose();
    });

    testWidgets('the parent owns the provider, and it is never replaced',
        (WidgetTester tester) async {
      final _ReadyImage provider = _ReadyImage(decoded);
      await host(
        tester,
        IuxImage(
          image: provider,
          description: const IuxImageDescription.decorative(),
          aspectRatio: 1,
        ),
      );

      // No cache of its own, no retry, no placeholder URL: the provider the
      // caller passed is the provider that resolves.
      expect(
        tester.widget<Image>(find.byType(Image)).image,
        same(provider),
      );
    });

    testWidgets('a picture reads the same way right to left',
        (WidgetTester tester) async {
      await host(
        tester,
        SizedBox(
          width: 300,
          child: IuxImage(
            image: _UnavailableImage(),
            description: const IuxImageDescription.meaningful('إيصال'),
            aspectRatio: 2,
          ),
        ),
        direction: TextDirection.rtl,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('إيصال'), findsOneWidget);
    });
  });

  // ==========================================================================
  // Token value semantics
  // ==========================================================================

  group('resolved tokens are values, so a rebuild is not a repaint', () {
    testWidgets('identical conditions resolve to identical tokens',
        (WidgetTester tester) async {
      final IuxIconTokens iconA = await resolve(
        tester,
        const IuxThemeConfiguration(),
        (BuildContext context) => IuxIconResolver.resolve(context),
      );
      final IuxIconTokens iconB = await resolve(
        tester,
        const IuxThemeConfiguration(),
        (BuildContext context) => IuxIconResolver.resolve(context),
      );
      expect(iconA, iconB);
      expect(iconA.hashCode, iconB.hashCode);

      final IuxAvatarTokens avatarA = await resolve(
        tester,
        const IuxThemeConfiguration(),
        (BuildContext context) => IuxAvatarResolver.resolve(context),
      );
      final IuxAvatarTokens avatarB = await resolve(
        tester,
        const IuxThemeConfiguration(),
        (BuildContext context) => IuxAvatarResolver.resolve(context),
      );
      expect(avatarA, avatarB);
      expect(avatarA.hashCode, avatarB.hashCode);

      final IuxImageTokens imageA = await resolve(
        tester,
        const IuxThemeConfiguration(),
        IuxImageResolver.resolve,
      );
      final IuxImageTokens imageB = await resolve(
        tester,
        const IuxThemeConfiguration(),
        IuxImageResolver.resolve,
      );
      expect(imageA, imageB);
      expect(imageA.hashCode, imageB.hashCode);
    });

    testWidgets('different conditions resolve to different tokens',
        (WidgetTester tester) async {
      final IuxIconTokens light = await resolve(
        tester,
        const IuxThemeConfiguration(),
        (BuildContext context) => IuxIconResolver.resolve(context),
      );
      final IuxIconTokens dark = await resolve(
        tester,
        const IuxThemeConfiguration(brightness: Brightness.dark),
        (BuildContext context) => IuxIconResolver.resolve(context),
      );
      expect(light, isNot(dark));
    });
  });
}

/// A picture that is already decoded.
///
/// Widget tests cannot load a real network image, and a component that
/// presents pictures has to be tested against pictures. Each instance is its
/// own cache key, so one test cannot inherit another test's result.
class _ReadyImage extends ImageProvider<_ReadyImage> {
  _ReadyImage(this.image);

  final ui.Image image;

  @override
  Future<_ReadyImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<_ReadyImage>(this);

  @override
  ImageStreamCompleter loadImage(
    _ReadyImage key,
    ImageDecoderCallback decode,
  ) =>
      OneFrameImageStreamCompleter(
        // Cloned, because the completer disposes the ImageInfo it was given
        // once nothing is listening. Without this the second test to use the
        // shared picture would be handed a disposed one.
        SynchronousFuture<ImageInfo>(ImageInfo(image: image.clone())),
      );
}

/// A picture that never arrives: offline, or a connection that is simply slow.
class _PendingImage extends ImageProvider<_PendingImage> {
  @override
  Future<_PendingImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<_PendingImage>(this);

  @override
  ImageStreamCompleter loadImage(
    _PendingImage key,
    ImageDecoderCallback decode,
  ) =>
      OneFrameImageStreamCompleter(Completer<ImageInfo>().future);
}

/// A picture that fails: a 404, a revoked URL, a malformed file.
class _UnavailableImage extends ImageProvider<_UnavailableImage> {
  @override
  Future<_UnavailableImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<_UnavailableImage>(this);

  @override
  ImageStreamCompleter loadImage(
    _UnavailableImage key,
    ImageDecoderCallback decode,
  ) =>
      OneFrameImageStreamCompleter(
        Future<ImageInfo>.error(
          Exception('the picture could not be fetched'),
        ),
      );
}
