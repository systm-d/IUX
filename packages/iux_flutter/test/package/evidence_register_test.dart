import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every `IUX-*` identifier the codebase cites must have an entry behind it.
///
/// The register is the project's memory. A component comment, a test, a
/// changelog line or a research file says "see `IUX-FEEDBACK-004`" and expects
/// the reader to find a level, a scope, a source and a limit at the other end.
/// When the entry is not there the citation is worse than nothing: it looks
/// like evidence, and it costs the reader the time it takes to search before
/// they can conclude there is none.
///
/// **Three identifiers were in exactly that state at once** — cited in earnest
/// by source and documentation, with no entry anywhere. All three have since
/// been written up, so this test passes on the day it is added. That is the
/// point: it exists to stop the fourth, not to report the first three. The
/// register is appended to by hand at the end of a piece of work, which is the
/// moment a deadline is nearest and an ID is most likely to be cited from the
/// code and never registered.
///
/// It deliberately does **not** check the reverse. An entry nobody cites yet is
/// fine — it may be recording a decision whose code has not landed, or one that
/// is true of the whole framework rather than of any one file.
///
/// The third check is the same defect one step further in. An ID may carry more
/// than one entry — the register uses that deliberately, a finding first and its
/// fix later — and a reader following a citation lands on the earliest one. Three
/// IDs let that reader stop at a Status line that had been overtaken elsewhere.
/// So a superseded entry must now say so and name what continues it: the
/// citation has to resolve to something still true, not merely to something.
void main() {
  final Directory repository = Directory('../..');
  final Directory evidence = Directory('../../docs/evidence');

  /// Directories whose contents are generated, vendored, or not ours.
  bool isOurs(String path) =>
      !path.contains('/.git/') &&
      !path.contains('/.dart_tool/') &&
      !path.contains('/build/') &&
      !path.contains('/ios/') &&
      !path.contains('/android/');

  /// An identifier as the register writes them: `IUX-`, a name, three digits.
  ///
  /// Anchored to three digits so that prose about "IUX-006 onward" — a mission
  /// number, which is a different naming scheme the register also uses in its
  /// `Scope` lines — is not mistaken for an entry identifier.
  final RegExp identifier = RegExp(r'\bIUX-[A-Z]+[A-Z0-9-]*-\d{3}\b');

  /// The two shapes an evidence file declares an entry in: a prose heading in
  /// `semantic-tokens-and-accessibility.md`, a table row in `foundations.md`.
  final RegExp declaration = RegExp(
    r'^(?:### |\| )(IUX-[A-Z]+[A-Z0-9-]*-\d{3})\b',
    multiLine: true,
  );

  List<File> filesUnder(Directory directory, Set<String> extensions) =>
      directory
          .listSync(recursive: true)
          .whereType<File>()
          .where((File file) => isOurs(file.path))
          .where((File file) =>
              extensions.any((String suffix) => file.path.endsWith(suffix)))
          .toList();

  /// Every identifier declared by an entry of its own, in either register file.
  Map<String, List<String>> declarations() {
    final Map<String, List<String>> found = <String, List<String>>{};
    for (final File file in filesUnder(evidence, <String>{'.md'})) {
      for (final RegExpMatch match
          in declaration.allMatches(file.readAsStringSync())) {
        found.putIfAbsent(match.group(1)!, () => <String>[]).add(file.path);
      }
    }
    return found;
  }

  test('the evidence register is where this test thinks it is', () {
    // Without this, a moved directory would make every check below pass
    // vacuously — nothing cited, nothing declared, nothing missing.
    expect(evidence.existsSync(), isTrue);
    expect(declarations(), isNotEmpty);
  });

  test('every cited identifier has an entry of its own', () {
    final Map<String, List<String>> declared = declarations();
    final Map<String, Set<String>> dangling = <String, Set<String>>{};

    for (final File file in filesUnder(repository, <String>{'.dart', '.md'})) {
      for (final RegExpMatch match
          in identifier.allMatches(file.readAsStringSync())) {
        final String id = match.group(0)!;
        if (!declared.containsKey(id)) {
          dangling.putIfAbsent(id, () => <String>{}).add(file.path);
        }
      }
    }

    expect(
      dangling,
      isEmpty,
      reason: 'These identifiers are cited and have no entry:\n'
          '${dangling.entries.map((MapEntry<String, Set<String>> e) => '  ${e.key} — cited in ${e.value.join(', ')}').join('\n')}\n'
          'Either add the entry, or stop citing an ID that promises one.',
    );
  });

  test('a superseded entry says so, and names what continues it', () {
    // An ID legitimately carries more than one entry. The register uses this
    // deliberately: the first entry records a finding, a later one under the
    // same ID records the fix or the refinement, and its title says which —
    // "the scroll loss also disposed the opener (FIXED)", "refined by the
    // pilot". That is a good convention and this test does not forbid it.
    //
    // What it forbids is the version that misleads. A reader following a
    // citation lands on the *first* entry, reads a Status line that was true
    // when it was written — `IUX-OVERLAY-001` said "open, and deliberately not
    // fixed here" for as long as it took to fix it elsewhere — and has nothing
    // telling them to read on. Three IDs were in that state, which is the same
    // defect the test above catches, one step further in: the citation
    // resolves, and resolves to something that is no longer true.
    const String marker = '**Superseded below.**';
    final RegExp entryStart = RegExp(r'^### ', multiLine: true);

    for (final File file in filesUnder(evidence, <String>{'.md'})) {
      final String content = file.readAsStringSync();
      final List<int> starts =
          entryStart.allMatches(content).map((m) => m.start).toList();
      if (starts.isEmpty) continue;

      /// The body of each entry, from its heading to the next one.
      String bodyAt(int index) => content.substring(
            starts[index],
            index + 1 < starts.length ? starts[index + 1] : content.length,
          );

      final Map<String, List<int>> positions = <String, List<int>>{};
      for (int i = 0; i < starts.length; i++) {
        final RegExpMatch? match = declaration.firstMatch(bodyAt(i));
        if (match != null) {
          positions.putIfAbsent(match.group(1)!, () => <int>[]).add(i);
        }
      }

      for (final MapEntry<String, List<int>> entry in positions.entries) {
        if (entry.value.length < 2) continue;
        // Every entry but the last one must point forward.
        for (final int index in entry.value.take(entry.value.length - 1)) {
          expect(
            bodyAt(index),
            contains(marker),
            reason: '${entry.key} has ${entry.value.length} entries in '
                '${file.path}, and the one at position ${index + 1} does not '
                'carry "$marker". A reader arriving from a citation stops '
                'there and takes its Status for the current one. Add the '
                'pointer, or merge the entries.',
          );
        }
      }
    }
  });
}
