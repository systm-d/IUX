import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    IuxAccessibilityProfile profile = const IuxAccessibilityProfile(),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: IuxTheme.light(profile: profile),
        home: Scaffold(body: Center(child: child)),
      ),
    );
    // Theme changes animate; settle so resolved values are the requested ones.
    await tester.pumpAndSettle();
  }

  group('IuxTapTarget', () {
    testWidgets('grows the interactive region without growing the child',
        (WidgetTester tester) async {
      await pump(
        tester,
        const IuxTapTarget(
          semanticLabel: 'Dismiss',
          child: SizedBox(key: Key('icon'), width: 20, height: 20),
        ),
      );

      final Size child = tester.getSize(find.byKey(const Key('icon')));
      final Size target = tester.getSize(find.byType(IuxTapTarget));

      expect(child, const Size(20, 20), reason: 'the icon stays small');
      expect(target.width, greaterThanOrEqualTo(IuxTouchTarget.minimum));
      expect(target.height, greaterThanOrEqualTo(IuxTouchTarget.minimum));
    });

    testWidgets('honours a comfortable target preference',
        (WidgetTester tester) async {
      await pump(
        tester,
        const IuxTapTarget(
          semanticLabel: 'Dismiss',
          child: SizedBox(width: 20, height: 20),
        ),
        profile: const IuxAccessibilityProfile(
          touchTarget: IuxTouchTargetPreference.comfortable,
        ),
      );

      final Size target = tester.getSize(find.byType(IuxTapTarget));
      expect(target.height, greaterThanOrEqualTo(IuxTouchTarget.comfortable));
    });

    testWidgets('an override may raise the minimum but never lower it',
        (WidgetTester tester) async {
      await pump(
        tester,
        const IuxTapTarget(
          semanticLabel: 'Dismiss',
          minimumSize: 24,
          child: SizedBox(width: 20, height: 20),
        ),
      );
      expect(
        tester.getSize(find.byType(IuxTapTarget)).height,
        greaterThanOrEqualTo(IuxTouchTarget.minimum),
        reason: 'a component must not be able to opt out of the floor',
      );
    });

    testWidgets('responds across the whole region, not only the child',
        (WidgetTester tester) async {
      int taps = 0;
      await pump(
        tester,
        IuxTapTarget(
          semanticLabel: 'Dismiss',
          onTap: () => taps++,
          child: const SizedBox(width: 8, height: 8),
        ),
      );

      final Rect region = tester.getRect(find.byType(IuxTapTarget));
      // A corner of the target, far outside the 8x8 child.
      await tester.tapAt(region.topLeft + const Offset(4, 4));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('reports its label and disabled state to assistive technology',
        (WidgetTester tester) async {
      await pump(
        tester,
        const IuxTapTarget(
          semanticLabel: 'Dismiss',
          enabled: false,
          child: SizedBox(width: 20, height: 20),
        ),
      );
      expect(
        tester.getSemantics(find.byType(IuxTapTarget)),
        matchesSemantics(label: 'Dismiss', hasEnabledState: true),
      );
    });
  });

  group('IuxFocusRing', () {
    testWidgets('reserves its gap whether or not it is drawn',
        (WidgetTester tester) async {
      // Gaining focus must not move the element: a moving target is hard to
      // follow, and under magnification it can leave the viewport.
      await pump(
        tester,
        const IuxFocusRing(
          focused: false,
          child: SizedBox(key: Key('a'), width: 40, height: 40),
        ),
      );
      final Rect unfocused = tester.getRect(find.byKey(const Key('a')));

      await pump(
        tester,
        const IuxFocusRing(
          focused: true,
          child: SizedBox(key: Key('a'), width: 40, height: 40),
        ),
      );
      final Rect focused = tester.getRect(find.byKey(const Key('a')));

      expect(focused, equals(unfocused));
    });
  });

  group('IuxFocusable', () {
    testWidgets('takes focus and activates from the keyboard',
        (WidgetTester tester) async {
      int activations = 0;
      await pump(
        tester,
        IuxFocusable(
          autofocus: true,
          onActivate: () => activations++,
          child: const SizedBox(width: 40, height: 40),
        ),
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(activations, 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(activations, 2);
    });

    testWidgets('ignores keys it does not handle', (WidgetTester tester) async {
      int activations = 0;
      await pump(
        tester,
        IuxFocusable(
          autofocus: true,
          onActivate: () => activations++,
          child: const SizedBox(width: 40, height: 40),
        ),
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.pump();
      expect(activations, 0);
    });
  });

  group('IuxSemantics', () {
    testWidgets('an action reports its name, role and state',
        (WidgetTester tester) async {
      await pump(
        tester,
        IuxSemantics.action(
          label: 'Save',
          hint: 'Stores your changes',
          child: const SizedBox(width: 40, height: 40),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Save')),
        matchesSemantics(
          label: 'Save',
          hint: 'Stores your changes',
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
        ),
      );
    });

    testWidgets('a busy action says so, since silence is ambiguous',
        (WidgetTester tester) async {
      await pump(
        tester,
        IuxSemantics.action(
          label: 'Save',
          busy: true,
          child: const SizedBox(width: 40, height: 40),
        ),
      );
      final SemanticsNode node =
          tester.getSemantics(find.bySemanticsLabel('Save'));
      expect(node.hint, contains('In progress'));
    });

    testWidgets('a decorative image is hidden rather than described',
        (WidgetTester tester) async {
      await pump(
        tester,
        IuxSemantics.image(
          label: '',
          child: const SizedBox(width: 40, height: 40),
        ),
      );
      expect(
        find.descendant(
          of: find.byType(Center),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a header is exposed so a screen reader can jump to it',
        (WidgetTester tester) async {
      await pump(
        tester,
        IuxSemantics.header(
          label: 'Payment',
          child: const SizedBox(width: 40, height: 40),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Payment')),
        matchesSemantics(label: 'Payment', isHeader: true),
      );
    });
  });

  group('IuxMotionPolicy', () {
    Future<IuxMotionDecision> decide(
      WidgetTester tester, {
      required IuxMotionRole role,
      required IuxAccessibilityProfile profile,
    }) async {
      late IuxMotionDecision decision;
      await tester.pumpWidget(
        MaterialApp(
          theme: IuxTheme.light(profile: profile),
          home: Builder(
            builder: (BuildContext context) {
              decision = IuxMotionPolicy.resolve(context, role: role);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      return decision;
    }

    testWidgets('decoration is dropped when less movement is requested',
        (WidgetTester tester) async {
      final IuxMotionDecision allowed = await decide(
        tester,
        role: IuxMotionRole.decorative,
        profile: const IuxAccessibilityProfile(
          motion: IuxMotionPreference.standard,
        ),
      );
      expect(allowed.isInstant, isFalse);

      final IuxMotionDecision dropped = await decide(
        tester,
        role: IuxMotionRole.decorative,
        profile: const IuxAccessibilityProfile(
          motion: IuxMotionPreference.reduced,
        ),
      );
      expect(dropped.isInstant, isTrue);
    });

    testWidgets('essential motion survives a reduced preference, shortened',
        (WidgetTester tester) async {
      final IuxMotionDecision standard = await decide(
        tester,
        role: IuxMotionRole.essential,
        profile: const IuxAccessibilityProfile(
          motion: IuxMotionPreference.standard,
        ),
      );
      final IuxMotionDecision reduced = await decide(
        tester,
        role: IuxMotionRole.essential,
        profile: const IuxAccessibilityProfile(
          motion: IuxMotionPreference.reduced,
        ),
      );

      expect(reduced.isInstant, isFalse,
          reason: 'reduced motion keeps what carries meaning');
      expect(reduced.duration, lessThan(standard.duration));
    });

    testWidgets('no motion removes even essential movement',
        (WidgetTester tester) async {
      final IuxMotionDecision decision = await decide(
        tester,
        role: IuxMotionRole.essential,
        profile: const IuxAccessibilityProfile(
          motion: IuxMotionPreference.none,
        ),
      );
      expect(decision.isInstant, isTrue);
    });

    testWidgets('it works without an IUX theme installed',
        (WidgetTester tester) async {
      late IuxMotionDecision decision;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              decision = IuxMotionPolicy.resolve(
                context,
                role: IuxMotionRole.essential,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(decision.isInstant, isFalse);
    });
  });
}
