import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// No file carries the remains of a merge.
///
/// **This exists because the register was mangled by one and nothing noticed.**
/// Resolving a conflict by deleting the three marker lines welds together
/// whatever the boundary happened to cut through. In a Dart file that is caught
/// on the next build, loudly. In `docs/evidence/` it is caught by nobody: the
/// file still renders, the headings still line up, and an entry now says half
/// of one thing and half of another.
///
/// The register is this project's memory and the one artefact whose corruption
/// is silent, which is the same argument `IUX-REGISTER-001` makes for checking
/// that citations resolve. A marker left behind is the cheapest possible
/// version of that failure and it is mechanical to catch.
///
/// It checks the whole repository rather than the library, because the failure
/// is about the merge and not about the language.
void main() {
  final Directory repository = Directory('../..');

  /// Directories whose contents are generated, vendored, or not ours.
  bool isOurs(String path) =>
      !path.contains('/.git/') &&
      !path.contains('/.dart_tool/') &&
      !path.contains('/build/') &&
      !path.contains('/ios/') &&
      !path.contains('/android/');

  /// The three lines `git` leaves behind, anchored to the start of a line.
  ///
  /// `=======` is deliberately required to be the whole line: a row of equals
  /// signs is ordinary Markdown underlining, and matching it loosely would fail
  /// on prose that is perfectly fine.
  final RegExp marker = RegExp(
    r'^(<{7}[ \t]|>{7}[ \t]|={7}$)',
    multiLine: true,
  );

  test('no file in the repository carries a conflict marker', () {
    final List<String> offenders = <String>[];

    for (final FileSystemEntity entity
        in repository.listSync(recursive: true)) {
      if (entity is! File) continue;
      if (!isOurs(entity.path)) continue;
      if (!(entity.path.endsWith('.dart') ||
          entity.path.endsWith('.md') ||
          entity.path.endsWith('.yaml'))) {
        continue;
      }
      // This file names the markers in order to look for them, so it is the one
      // file that cannot be checked against itself.
      if (entity.path.endsWith('no_conflict_markers_test.dart')) continue;

      if (marker.hasMatch(entity.readAsStringSync())) {
        offenders.add(entity.path);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'A merge was resolved by deleting the markers rather than the '
          'conflict. Take one side of the file whole and re-apply the other '
          "side's change to it — stripping the three lines welds together "
          'whatever the boundary cut through.',
    );
  });
}
