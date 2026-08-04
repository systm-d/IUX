import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Mechanical enforcement of the defect that shipped to a real device.
///
/// The package draws Material glyphs — `Icons.check` and `Icons.remove` are the
/// selection controls' marks, and `IuxIcon` takes arbitrary `IconData` — while
/// its `pubspec.yaml` did not declare `uses-material-design: true`. Flutter
/// aggregates that flag across an application *and its dependencies*, so its
/// absence here meant every consumer had to know to add it, and the catalog
/// did not.
///
/// **The failure is silent and total.** No exception, no warning, no analyzer
/// complaint: every glyph simply renders blank. A radio group whose state
/// changes correctly but whose mark is invisible reads, to anyone holding the
/// phone, as a radio group that does not work — and so does every icon button,
/// every status indicator and every checkbox. It was reported as "many
/// components do not work", which is exactly what it looks like.
///
/// No widget test can catch it. The test font used by `flutter_test` draws
/// every glyph as a filled box regardless of what the pubspec declares, so all
/// 1976 tests passed against a package that shipped no icons at all. This is
/// the class of defect that needs a device or a check like this one.
void main() {
  group('a package that draws Material glyphs declares the font', () {
    test('lib references Material icons', () {
      // If this ever stops being true the assertion below is no longer
      // load-bearing, and should be removed rather than left to pass
      // vacuously.
      final Iterable<File> sources = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((File file) => file.path.endsWith('.dart'));

      final List<String> users = <String>[
        for (final File source in sources)
          if (RegExp(r'(?<![A-Za-z_$.])Icons\.')
              .hasMatch(source.readAsStringSync()))
            source.path,
      ];

      expect(
        users,
        isNotEmpty,
        reason: 'this test exists because the library draws Material glyphs; '
            'if it no longer does, delete it',
      );
    });

    test('pubspec.yaml declares uses-material-design', () {
      final List<String> lines = File('pubspec.yaml').readAsLinesSync();

      // Only a real declaration counts. A commented-out one is what this
      // check exists to catch.
      final bool declared = lines.any(
        (String line) =>
            !line.trimLeft().startsWith('#') &&
            RegExp(r'^\s+uses-material-design:\s*true\s*$').hasMatch(line),
      );

      expect(
        declared,
        isTrue,
        reason: 'Without it every Material glyph in this package renders '
            'blank, on every consumer, with no error of any kind. The '
            'selection controls lose the mark that says which option is '
            'chosen; IuxIcon draws nothing at all. It reads as a broken '
            'component rather than a missing font, which is why it reached a '
            'real device before anyone noticed.',
      );
    });
  });
}
