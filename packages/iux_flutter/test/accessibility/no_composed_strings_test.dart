import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Mechanical enforcement of the rule that already failed once.
///
/// `IuxSemantics.action` composed the English literal `'In progress'` into the
/// hint of any running action. Every non-English application built on IUX
/// would have shipped that word untranslated, in the one place a
/// screen-reader user cannot ignore. It was caught during IUX-008.6 and
/// replaced by a caller-supplied `busyHint`.
///
/// The rule is that the framework holds roles, never words: every string the
/// user reads or hears arrives from the caller, already localised. That rule
/// is invisible at review time, because a literal in the right place looks
/// like a sensible default rather than a bug.
///
/// Developer-facing text is a different thing and stays: assertion messages,
/// `FlutterError` diagnostics and documentation exist to be read by whoever
/// wired the API up wrong, and they are never spoken to a user.
///
/// **What counts as a word.** This test flags a literal that contains letters,
/// and allows one made only of punctuation and space. That line is deliberate,
/// and it was drawn after the first version of this test flagged
/// `'$categoryLabel. $message'` in the validation summary along with
/// `IuxSemantics._joinHint`.
///
/// Those are not words. They join two of the caller's own strings with a full
/// stop, which a text-to-speech engine reads as a pause rather than as
/// orthography — the point is prosody, not punctuation, and the same pause is
/// wanted in every language. Both sites already document that reasoning. A
/// literal containing letters has no such defence: it ships untranslated in
/// every application built on IUX, and the user cannot work around it.
///
/// The residual assumption is recorded rather than hidden: a framework that
/// joins with `.` is choosing a separator on the caller's behalf, and a
/// language whose sentence separator is not a full stop gets a slightly wrong
/// glyph in exchange for the right pause. If that trade ever needs revisiting,
/// this test is what keeps the count reviewable. It was two when this was
/// written and IUX-036's onboarding heading made it three — the number is
/// deliberately not restated here, because a count in a comment goes stale
/// silently while the rule does not.
void main() {
  group('the framework composes no user-facing strings', () {
    // Properties whose value is read aloud or painted on screen.
    const List<String> spokenProperties = <String>[
      'label',
      'hint',
      'tooltip',
      'semanticLabel',
      'increasedValue',
      'decreasedValue',
      'value',
      'attributedLabel',
    ];

    final List<File> sources = Directory('lib/src')
        .listSync(recursive: true)
        .whereType<File>()
        .where((File file) => file.path.endsWith('.dart'))
        .toList();

    test('the library has sources to check', () {
      expect(sources, isNotEmpty);
    });

    for (final File source in sources) {
      test(source.path, () {
        final List<String> offences = <String>[];
        final List<String> lines = source.readAsLinesSync();

        /// Every literal on [line] that contains a letter.
        ///
        /// Scanning the whole line rather than only what follows the colon is
        /// the point. The first version of this test required the quote to
        /// come straight after the property, and a probe reproducing the
        /// original defect behind a conditional —
        /// `hint: busy ? 'In progress' : null` — walked straight past it. A
        /// literal does not stop being a word because a ternary is holding it.
        List<String> wordsIn(String line) {
          final List<String> words = <String>[];
          for (final RegExpMatch match
              in RegExp(r"'((?:[^'\\\n]|\\.)*)'").allMatches(line)) {
            // An interpolation is the caller's value, never IUX's own text,
            // and punctuation between two of them is a pause rather than a
            // word — see the note above the test.
            final String literal =
                match.group(1)!.replaceAll(RegExp(r'\$\{[^}]*\}|\$\w+'), '');
            if (RegExp(r'\p{L}', unicode: true).hasMatch(literal)) {
              words.add(match.group(0)!);
            }
          }
          return words;
        }

        for (int index = 0; index < lines.length; index++) {
          final String line = lines[index];
          final String trimmed = line.trimLeft();

          // Documentation and comments explain the code to a developer.
          if (trimmed.startsWith('//')) continue;
          // A `Text(...)` inside a doc comment is an example, not a widget.
          if (trimmed.startsWith('///')) continue;

          // A trailing comment is prose, and prose quotes things.
          final int comment = line.indexOf('//');
          final String code = comment < 0 ? line : line.substring(0, comment);

          for (final String property in spokenProperties) {
            // `label: 'Send'` — a literal where a caller's word belongs.
            // `label: label`, `label: widget.label`, `label: null` are fine.
            if (!RegExp('\\b$property:').hasMatch(code)) continue;
            final List<String> words = wordsIn(code);
            if (words.isEmpty) continue;

            offences.add('  ${index + 1}: ${line.trim()}');
            break;
          }

          // A painted literal is the same violation wearing a widget.
          if (RegExp(r'(?<![A-Za-z_$.])Text\(').hasMatch(code) &&
              wordsIn(code).isNotEmpty) {
            offences.add('  ${index + 1}: ${line.trim()}');
          }
        }

        expect(
          offences,
          isEmpty,
          reason:
              'the framework composed a user-facing string in ${source.path}. '
              'Every word the user reads or hears arrives from the caller, '
              'already localised — a literal here ships untranslated in every '
              'application built on IUX, and the user cannot work around it.'
              '\n\n${offences.join('\n')}\n\n'
              'If this is developer-facing text, it belongs in an assert or a '
              'FlutterError, not in a spoken property.',
        );
      });
    }
  });
}
