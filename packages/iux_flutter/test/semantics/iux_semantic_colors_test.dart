import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

void main() {
  // Sourced from the theme engine rather than a fixture, so these tests
  // exercise the values IUX actually ships.
  final IuxSemanticColors light =
      IuxTheme.resolve(const IuxThemeConfiguration()).colors;
  final IuxSemanticColors dark = IuxTheme.resolve(
    const IuxThemeConfiguration(brightness: Brightness.dark),
  ).colors;

  group('copyWith', () {
    test('replaces every group, not only the first one', () {
      // Guards the defect this mission remediates: the previous implementation
      // accepted a single parameter, silently discarding the others.
      final IuxSemanticColors copy = light.copyWith(
        content: dark.content,
        surface: dark.surface,
        border: dark.border,
        action: dark.action,
        feedback: dark.feedback,
        comparison: dark.comparison,
        state: dark.state,
        avatarAccent: dark.avatarAccent,
      );
      expect(copy, equals(dark));
    });

    test('preserves the groups that were not supplied', () {
      final IuxSemanticColors copy = light.copyWith(content: dark.content);
      expect(copy.content, equals(dark.content));
      expect(copy.surface, equals(light.surface));
      expect(copy.border, equals(light.border));
      expect(copy.action, equals(light.action));
      expect(copy.feedback, equals(light.feedback));
      expect(copy.comparison, equals(light.comparison));
      expect(copy.state, equals(light.state));
      expect(copy.avatarAccent, equals(light.avatarAccent));
    });

    test('reaches every role of every group', () {
      const Color probe = Color(0xFF123456);
      expect(light.content.copyWith(link: probe).link, probe);
      expect(light.surface.copyWith(inverse: probe).inverse, probe);
      expect(light.border.copyWith(error: probe).error, probe);
      expect(light.state.copyWith(dragged: probe).dragged, probe);
      expect(
        light.action.primary
            .copyWith(disabledBackground: probe)
            .disabledBackground,
        probe,
      );
      expect(light.feedback.error.copyWith(icon: probe).icon, probe);
      expect(light.comparison.above.copyWith(mark: probe).mark, probe);
      expect(
        light.comparison
            .copyWith(
              at: light.comparison.above,
            )
            .at,
        light.comparison.above,
      );
      expect(light.avatarAccent.one.copyWith(icon: probe).icon, probe);
      expect(
        light.avatarAccent
            .copyWith(
              four: light.avatarAccent.one,
            )
            .four,
        light.avatarAccent.one,
      );
    });

    test('an empty copy equals the original', () {
      expect(light.copyWith(), equals(light));
    });
  });

  group('lerp', () {
    test('is exact at both bounds', () {
      expect(light.lerp(dark, 0), equals(light));
      expect(light.lerp(dark, 1), equals(dark));
    });

    test('produces an intermediate value strictly between the bounds', () {
      final IuxSemanticColors mid = light.lerp(dark, 0.5);
      expect(mid, isNot(equals(light)));
      expect(mid, isNot(equals(dark)));
      expect(
        mid.content.primary,
        Color.lerp(light.content.primary, dark.content.primary, 0.5),
      );
      expect(
        mid.action.destructive.background,
        Color.lerp(
          light.action.destructive.background,
          dark.action.destructive.background,
          0.5,
        ),
      );
    });

    test('returns itself when the other extension is absent', () {
      expect(light.lerp(null, 0.5), equals(light));
    });
  });

  group('equality', () {
    test('two identical mappings are equal and share a hash code', () {
      final IuxSemanticColors copy = light.copyWith();
      expect(copy, equals(light));
      expect(copy.hashCode, equals(light.hashCode));
    });

    test('a single changed role breaks equality', () {
      final IuxSemanticColors changed = light.copyWith(
        state: light.state.copyWith(focus: const Color(0xFF010203)),
      );
      expect(changed, isNot(equals(light)));
    });
  });

  group('resolution from context', () {
    testWidgets('resolves the extension installed on the theme',
        (WidgetTester tester) async {
      late IuxSemanticColors resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: <ThemeExtension<dynamic>>[light]),
          home: Builder(
            builder: (BuildContext context) {
              resolved = IuxSemanticColors.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(resolved, equals(light));
    });

    testWidgets('fails loudly when no IUX theme is installed',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              IuxSemanticColors.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      final Object? error = tester.takeException();
      expect(error, isA<FlutterError>());
      expect(
        error.toString(),
        contains('No IuxSemanticColors found'),
        reason: 'a missing theme must be diagnosable, not silently replaced',
      );
    });

    testWidgets('maybeOf returns null instead of throwing',
        (WidgetTester tester) async {
      IuxSemanticColors? resolved;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              resolved = IuxSemanticColors.maybeOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(resolved, isNull);
    });
  });
}
