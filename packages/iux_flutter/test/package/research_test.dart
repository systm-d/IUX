import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Mechanical enforcement of a promise the repository made and did not keep.
///
/// `PROJECT_PROMPT.md` §3 requires decisions to rest on serious research and
/// says an intuition is not a proof. `research/README.md` described
/// subdirectories for accessibility, Android, HCI and UX material. For the
/// whole life of the project **`research/` contained that README and nothing
/// else** — no subdirectory, no source, no note — while the framework was
/// described as producing interfaces that are ergonomic.
///
/// Nothing caught it, because nothing was looking. A missing directory throws
/// no exception and fails no analyzer: the charter and the artefact simply
/// disagreed, in a place nobody had reason to open. It took an integrator
/// migrating a real application to notice (`IUX-RESEARCH-GAP-001`).
///
/// This is the cheapest possible guard against the same silence returning. It
/// does not — and cannot — check that what is in there is any good. What it
/// checks is that the directory the charter leans on is not empty, and that a
/// subdirectory created to hold material actually holds some.
void main() {
  // Resolved from the package directory, which is where `flutter test` runs.
  final Directory research = Directory('../../research');

  test('the research directory the charter leans on exists', () {
    expect(
      research.existsSync(),
      isTrue,
      reason: 'PROJECT_PROMPT.md §3 and §8 both point at research/. A charter '
          'that names a directory which is not there is a charter nobody can '
          'follow.',
    );
  });

  test('it holds something other than its own README', () {
    final List<String> documents = research
        .listSync(recursive: true)
        .whereType<File>()
        .map((File file) => file.uri.pathSegments.last)
        .where((String name) => name.endsWith('.md'))
        .where((String name) => name != 'README.md')
        .toList();

    expect(
      documents,
      isNotEmpty,
      reason: 'research/ is back to holding only a README, which is the state '
          'IUX-RESEARCH-GAP-001 reported: a directory that describes what it '
          'would contain and contains nothing. Either put the material back or '
          'change what README.md and PROJECT_PROMPT.md §8 claim rests on it.',
    );
  });

  test('every subdirectory in it holds a document', () {
    for (final Directory subdirectory
        in research.listSync().whereType<Directory>()) {
      final Iterable<File> documents = subdirectory
          .listSync(recursive: true)
          .whereType<File>()
          .where((File file) => file.path.endsWith('.md'));

      expect(
        documents,
        isNotEmpty,
        reason: '${subdirectory.path} is an empty promise — the exact shape of '
            'the original defect, one level down. A subdirectory should be '
            'created when there is something to put in it, not in advance.',
      );
    }
  });
}
