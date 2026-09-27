import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Keeps `docs/components/deliberately-absent.md` true.
///
/// That page exists because IUX's refusals were argued in the documentation of
/// the component that lacks the thing — which is exactly where someone looking
/// for it never reads. Collecting them in one place fixes where they are found
/// and creates a second copy that can drift from the first. This makes the
/// drift fail loudly instead.
///
/// Two checks, and each one is the page's promise read back to it:
///
/// 1. **Every quoted refusal is still in its source.** The page quotes each
///    refusal verbatim and names the file. If the refusal is reworded or
///    withdrawn, the page would go on telling integrators something the code no
///    longer says.
/// 2. **Every alternative it recommends exists.** A page that sends someone to
///    a component that is not there is worse than no page. The first draft of
///    this one named `IuxAsyncButton`; the widget is `IuxAsyncActionButton`.
///
/// The same defect class as `IUX-FOCUS-RING-001`, where three documents
/// described a focus ring the paint did not draw. Documentation that no test
/// reads is a claim nobody is checking.
void main() {
  final File page = File('../../docs/components/deliberately-absent.md');
  final Directory library = Directory('lib/src');

  /// Whitespace collapsed to single spaces, so a quote reflowed across
  /// different line lengths still matches its source.
  String flatten(String text) => text.replaceAll(RegExp(r'\s+'), ' ').trim();

  /// The dartdoc of [file], with the comment markers removed, as one line.
  String dartdocOf(File file) => flatten(
        file
            .readAsLinesSync()
            .map((String line) => line.trimLeft())
            .where((String line) => line.startsWith('///'))
            .map((String line) => line.replaceFirst(RegExp(r'^/// ?'), ''))
            .join(' '),
      );

  /// Each blockquote on the page, paired with the `Source:` line after it.
  List<(String, String)> quotations(String markdown) {
    final List<(String, String)> found = <(String, String)>[];
    final List<String> lines = markdown.split('\n');
    for (int i = 0; i < lines.length; i++) {
      if (!lines[i].startsWith('>')) continue;
      final List<String> quote = <String>[];
      while (i < lines.length && lines[i].startsWith('>')) {
        quote.add(lines[i].replaceFirst(RegExp(r'^> ?'), ''));
        i++;
      }
      while (i < lines.length && lines[i].trim().isEmpty) {
        i++;
      }
      final RegExpMatch? source = i < lines.length
          ? RegExp(r'^Source: `([^`]+)`').firstMatch(lines[i])
          : null;
      if (source != null) found.add((flatten(quote.join(' ')), source[1]!));
    }
    return found;
  }

  /// Every `Iux…` name the library declares, and every file's text by path.
  final Map<String, String> sources = <String, String>{
    for (final File file in library
        .listSync(recursive: true)
        .whereType<File>()
        .where((File f) => f.path.endsWith('.dart')))
      file.path: file.readAsStringSync(),
  };

  /// Every `Iux…` type the library declares, with the text of its file.
  final Map<String, String> declared = <String, String>{
    for (final String text in sources.values)
      for (final RegExpMatch m in RegExp(
        r'\b(?:class|enum|mixin|typedef|extension)\s+(Iux\w+)',
      ).allMatches(text))
        m[1]!: text,
  };

  /// Whether `Iux…` or `Iux….member` names something that exists.
  ///
  /// A member is looked for in the file that declares its type, as a word —
  /// a named constructor, a static, an enum value. Lenient on purpose: this
  /// is here to catch a recommendation of something that is not there, and a
  /// wrong type name, the mistake it was written after, fails on the first
  /// line.
  bool exists(String name) {
    final List<String> parts = name.split('.');
    final String? home = declared[parts.first];
    if (home == null) return false;
    if (parts.length == 1) return true;
    return RegExp('\\b${RegExp.escape(parts[1])}\\b').hasMatch(home);
  }

  test('the page is where this test thinks it is, and says something', () {
    expect(page.existsSync(), isTrue);
    expect(
      quotations(page.readAsStringSync()),
      hasLength(greaterThanOrEqualTo(15)),
      reason: 'every refusal on the page is quoted; if this drops sharply the '
          'page lost its evidence, or this parser lost the page',
    );
  });

  test('every quoted refusal is still in the file it is attributed to', () {
    for (final (String quote, String path)
        in quotations(page.readAsStringSync())) {
      final File source = File('../../$path');
      expect(source.existsSync(), isTrue, reason: '$path no longer exists');
      expect(
        dartdocOf(source),
        contains(quote),
        reason: 'the page quotes a refusal that $path no longer makes, in '
            'these words:\n  "$quote"\nEither the code changed its mind — '
            'then the page must too — or the quote was edited away from its '
            'source.',
      );
    }
  });

  test('every alternative the page recommends exists', () {
    final String markdown = page.readAsStringSync();

    // The two places the page tells someone what to use: the "Use instead"
    // lines and the second column of the quick-answer table.
    final List<String> advice = <String>[
      for (final RegExpMatch m in RegExp(
        r'\*\*Use instead:\*\*(.*?)(?=\n\n)',
        dotAll: true,
      ).allMatches(markdown))
        m[1]!,
      for (final String line in markdown.split('\n'))
        if (line.startsWith('| ') &&
            !line.startsWith('| You are') &&
            !line.startsWith('| ---'))
          line.split('|')[2],
    ];
    expect(advice, isNotEmpty);

    final Set<String> named = <String>{
      for (final String sentence in advice)
        for (final RegExpMatch m
            in RegExp(r'`(Iux[\w.]*)`').allMatches(sentence))
          m[1]!,
    };
    expect(named, isNotEmpty);

    final List<String> missing =
        named.where((String name) => !exists(name)).toList()..sort();
    expect(
      missing,
      isEmpty,
      reason: 'the page recommends things the library does not have: '
          '${missing.join(', ')}',
    );
  });
}
