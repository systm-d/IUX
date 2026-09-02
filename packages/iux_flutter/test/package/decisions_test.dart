import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The decisions this repository has taken, and the shape their records keep.
///
/// A manifest rather than a directory listing, for the reason
/// `press_feedback_sweep_test.dart` is one: a list kept complete by
/// remembering is a list that is complete until the next entry. Naming the
/// decision here first, and letting the test fail until the file exists, is
/// what makes an ADR part of a change rather than something written afterwards
/// if there is time.
///
/// The titles are the ones the files carry, verbatim after `# ADR-00NN: `.
///
/// **What this cannot check.** Nothing here reads an argument. A record that
/// states a decision, dates it, and never says why is green in this file, and
/// so is one whose reasoning is wrong. The manifest catches the two failures a
/// machine can see — a decision taken and never written down, and a record that
/// drifted out of the shape the others keep so that no reader or tool can scan
/// them together. Judging the content is a reviewer's job and stays one.
const Map<int, String> _decisions = <int, String>{
  1: 'Lightweight monorepo repository structure',
  2: "Semantic colours and Flutter's `ColorScheme`",
  3: 'Theme engine architecture',
  4: 'Composable accessibility profiles',
  5: 'Accessibility runtime',
  6: 'Motion and feedback engine',
  7: 'Layout primitives',
  8: 'Component standard, enforced where it can be',
  9: 'Action model as orthogonal dimensions',
  10: 'IUX draws charts',
  11: 'Icons on tabs, for a measured quantity',
  12: 'A dense row folds rather than overflows',
};

void main() {
  final Directory decisions = Directory('../../docs/decisions');

  /// The file name a record keeps: `ADR-0007-layout-primitives.md`.
  final RegExp record = RegExp(r'^ADR-(\d{4})-[a-z0-9-]+\.md$');

  String pad(int number) => number.toString().padLeft(4, '0');

  /// Every name in the directory that claims to be a record, sorted.
  ///
  /// Claims, rather than is: a name that starts with `ADR-` and gets the rest
  /// wrong is the case this list exists to surface, so the filter is loose on
  /// purpose and the check downstream is the strict one.
  List<String> claimants() => decisions
      .listSync()
      .whereType<File>()
      .map((File file) => file.uri.pathSegments.last)
      .where((String name) => name.startsWith('ADR-'))
      .toList()
    ..sort();

  File fileFor(int number) => decisions.listSync().whereType<File>().firstWhere(
        (File file) =>
            file.uri.pathSegments.last.startsWith('ADR-${pad(number)}-'),
        orElse: () => File('${decisions.path}/ADR-${pad(number)}-MISSING.md'),
      );

  group('every decision this repository took has a record', () {
    test('the directory is where the tests expect it', () {
      // Without this, a moved or emptied directory would make the reverse
      // check below pass vacuously: nothing on disk names nothing unlisted.
      expect(decisions.existsSync(), isTrue);
      expect(claimants(), isNotEmpty);
    });

    for (final MapEntry<int, String> decision in _decisions.entries) {
      test('ADR-${pad(decision.key)} exists and is titled as listed', () {
        final File file = fileFor(decision.key);
        expect(
          file.existsSync(),
          isTrue,
          reason: 'ADR-${pad(decision.key)} is listed in this manifest and no '
              'file provides it. Write docs/decisions/ADR-${pad(decision.key)}'
              '-<title-in-dashes>.md, or remove the entry.',
        );
        expect(
          file.readAsLinesSync().first,
          '# ADR-${pad(decision.key)}: ${decision.value}',
          reason: 'The heading and the manifest disagree, so one of them is '
              'describing a decision the other did not take.',
        );
      });
    }

    test('no record exists that the manifest does not name', () {
      final List<String> onDisk = claimants();

      expect(
        onDisk.where((String name) => !record.hasMatch(name)),
        isEmpty,
        reason: 'A file named like a record but not quite is a record nothing '
            'finds: not this manifest, not a reader scanning the directory, '
            'not a link written from memory. Name it '
            'ADR-<four digits>-<title-in-dashes>.md.',
      );

      final List<int> numbers = onDisk
          .map((String name) => record.firstMatch(name))
          .whereType<RegExpMatch>()
          .map((RegExpMatch match) => int.parse(match.group(1)!))
          .toList();

      expect(
        numbers.where((int number) => !_decisions.containsKey(number)),
        isEmpty,
        reason:
            'A record on disk that this manifest does not name is a decision '
            'the repository took and this test does not know about, so '
            'nothing here holds it to the shape. Add it to the manifest.',
      );

      expect(
        numbers.toSet(),
        hasLength(numbers.length),
        reason:
            'Two files claim the same ADR number. A citation to it resolves '
            'to whichever the filesystem lists first, which is not a choice '
            'anybody made.',
      );
    });
  });

  group('a record keeps the shape the others keep', () {
    for (final int number in _decisions.keys) {
      test('ADR-${pad(number)} carries its header and its argument', () {
        final File file = fileFor(number);
        expect(
          file.existsSync(),
          isTrue,
          reason: 'ADR-${pad(number)} is listed in this manifest and no file '
              'provides it, so there is no shape to check.',
        );

        final List<String> lines = file.readAsLinesSync();
        expect(
          lines.any((String line) => line.startsWith('- Status: ')),
          isTrue,
          reason: 'A record with no status cannot be told from a draft. Nine '
              'of the ten first ADRs write it as a list item; that is the '
              'form.',
        );
        expect(
          lines.any((String line) => line.startsWith('- Date: ')),
          isTrue,
          reason: 'A decision with no date cannot be read against the state of '
              'the repository when it was taken.',
        );
        expect(
          lines.contains('## Context'),
          isTrue,
          reason: 'Without the context, a future reader can only obey the '
              'decision or overturn it, never judge whether it still applies.',
        );
        expect(
          lines.any(
            (String line) => line == '## Decision' || line == '## Decisions',
          ),
          isTrue,
          reason: 'A record that never states its decision is a discussion.',
        );
      });
    }
  });
}
