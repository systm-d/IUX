import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

void main() {
  test('exposes package metadata from its public entry point', () {
    expect(Iux.packageName, 'iux_flutter');
    expect(Iux.version, isNotEmpty);
  });

  group('public API contract', () {
    // Only the export directives matter here. Matching raw substrings would
    // also match the prose that explains why something is not exported.
    final List<String> exports = File('lib/iux_flutter.dart')
        .readAsLinesSync()
        .where((String line) => line.trimLeft().startsWith('export '))
        .toList();

    test('the primitive palette stays internal', () {
      expect(exports, isNotEmpty);
      expect(
        exports.where((String line) => line.contains('iux_primitive_colors')),
        isEmpty,
        reason: 'exporting primitives would let a component bypass the '
            'contrast guarantees a theme is responsible for',
      );
    });

    test('nothing is exported from outside the public layers', () {
      // This assertion has narrowed twice as the framework grew: it once
      // banned components, then everything but patterns. Patterns shipped
      // with IUX-008.7, so what remains is the real invariant — every export
      // belongs to a layer the standard names, and a stray directory would
      // have to be added here deliberately.
      const Set<String> layers = <String>{
        'accessibility',
        'actions',
        'components',
        'feedback',
        'foundations',
        'inputs',
        'layout',
        'motion',
        'patterns',
        'semantics',
        'themes',
        'utilities',
      };
      for (final String line in exports) {
        final RegExpMatch? match =
            RegExp(r"export 'src/([^/]+)/").firstMatch(line);
        expect(match, isNotNull, reason: 'unparseable export: $line');
        expect(
          layers,
          contains(match!.group(1)),
          reason: '${match.group(1)} is not one of the layers the component '
              'standard names',
        );
      }
    });

    test('primitive names describe a hue and a level, not an identity', () {
      final Iterable<String> names = RegExp(r'static const Color (\w+)')
          .allMatches(
            File('lib/src/semantics/colors/iux_primitive_colors.dart')
                .readAsStringSync(),
          )
          .map((RegExpMatch match) => match.group(1)!);

      expect(names, isNotEmpty);
      for (final String name in names) {
        expect(
          name,
          matches(RegExp(r'^(neutral|accent|critical|positive|caution)\d+$')),
          reason: '"$name" must name a ramp and a level, never a brand',
        );
      }
    });

    test('public role names describe intent rather than appearance', () {
      // A role named after a hue would become a lie the moment a theme
      // changed that hue.
      final Iterable<String> sources = Directory('lib/src/semantics')
          .listSync(recursive: true)
          .whereType<File>()
          .where((File file) => !file.path.contains('primitive'))
          .map((File file) => file.readAsStringSync());

      for (final String source in sources) {
        for (final String hue in <String>['blue', 'red', 'green', 'amber']) {
          expect(
            source,
            isNot(contains('final Color $hue')),
            reason: 'a role must express intent, not a hue',
          );
        }
      }
    });
  });
}
