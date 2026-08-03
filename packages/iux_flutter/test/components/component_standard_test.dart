import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Enforces the mechanical half of the Component Standard.
///
/// A checklist nobody runs is a wish. These rules are the ones a machine can
/// decide, so they are decided by a machine — leaving human review for the
/// judgement that actually needs it, such as whether a label is
/// understandable.
///
/// Scope: `lib/src/components/` and `lib/src/patterns/`, the layers that are
/// forbidden from reaching below the runtime. The runtime and theme layers
/// legitimately use the primitives listed here, so they are excluded.
void main() {
  final Directory lib = Directory('lib/src');

  /// Component and pattern sources, which are the ones the standard binds.
  List<File> componentSources() {
    if (!lib.existsSync()) return <File>[];
    return lib
        .listSync(recursive: true)
        .whereType<File>()
        .where((File file) => file.path.endsWith('.dart'))
        .where((File file) =>
            file.path.contains('/components/') ||
            file.path.contains('/patterns/'))
        .toList();
  }

  /// Strips comments and doc comments so prose explaining a rule is not
  /// mistaken for a violation of it.
  String code(File file) {
    final StringBuffer buffer = StringBuffer();
    bool inBlockComment = false;
    for (String line in file.readAsLinesSync()) {
      final String trimmed = line.trimLeft();
      if (inBlockComment) {
        if (trimmed.contains('*/')) inBlockComment = false;
        continue;
      }
      if (trimmed.startsWith('/*')) {
        if (!trimmed.contains('*/')) inBlockComment = true;
        continue;
      }
      if (trimmed.startsWith('//')) continue;
      final int marker = line.indexOf('//');
      if (marker >= 0) line = line.substring(0, marker);
      buffer.writeln(line);
    }
    return buffer.toString();
  }

  void forbid(
    String description,
    Pattern pattern, {
    required String instead,
  }) {
    test(description, () {
      final List<String> offenders = <String>[];
      for (final File file in componentSources()) {
        if (code(file).contains(pattern)) offenders.add(file.path);
      }
      expect(
        offenders,
        isEmpty,
        reason: '$description\nUse $instead instead.\n'
            'See docs/components/component-standard.md §2.',
      );
    });
  }

  group('a component never reaches below the layers it is given', () {
    forbid(
      'no colour literal',
      RegExp(r'Color\(0x'),
      instead: 'IuxSemanticColors.of(context)',
    );

    forbid(
      'no Material colour constant',
      RegExp(r'\bColors\.\w+'),
      instead: 'a semantic role from IuxSemanticColors',
    );

    forbid(
      'no MediaQuery for a preference',
      RegExp(r'MediaQuery\.\w*[Oo]f\('),
      instead: 'IuxAccessibility.of(context)',
    );

    forbid(
      'no direct haptic call',
      RegExp(r'\bHapticFeedback\.'),
      instead: 'IuxFeedbackScope.of(context).emit(...)',
    );

    forbid(
      'no direct screen-reader announcement',
      RegExp(r'\bSemanticsService\.'),
      instead: 'IuxSemantics.liveRegion or the feedback engine',
    );

    forbid(
      'no hardcoded animation duration',
      RegExp(r'Duration\(milliseconds:\s*\d'),
      instead: 'IuxMotionPolicy.resolve(context, role: ...)',
    );

    forbid(
      'no navigation from a component',
      RegExp(r'Navigator\.'),
      instead: 'a callback the parent handles',
    );

    forbid(
      'no snack bar shown by a component',
      RegExp(r'ScaffoldMessenger\.'),
      instead: 'a callback the parent handles',
    );

    forbid(
      'no network access',
      RegExp(r'''\b(HttpClient|http\.get|Dio\()'''),
      instead: 'data supplied by the parent',
    );
  });

  group('the public API keeps its shape', () {
    final String barrel = File('lib/iux_flutter.dart').readAsStringSync();
    final List<String> exports = barrel
        .split('\n')
        .where((String line) => line.trimLeft().startsWith('export '))
        .toList();

    test('the primitive palette is never exported', () {
      expect(
        exports.where((String l) => l.contains('iux_primitive_colors')),
        isEmpty,
      );
    });

    test('every exported path exists', () {
      for (final String line in exports) {
        final RegExpMatch? match = RegExp(r"export '([^']+)'").firstMatch(line);
        expect(match, isNotNull, reason: 'unparseable export: $line');
        final String path = match!.group(1)!;
        expect(
          File('lib/$path').existsSync(),
          isTrue,
          reason: '$path is exported but missing',
        );
      }
    });

    test('exports are sorted, so the barrel stays reviewable', () {
      final List<String> sorted = List<String>.of(exports)..sort();
      expect(exports, equals(sorted));
    });
  });

  group('documentation keeps pace with the code', () {
    test('every component and pattern file is documented at the top', () {
      final List<String> undocumented = <String>[];
      for (final File file in componentSources()) {
        final List<String> lines = file.readAsLinesSync();
        final bool hasDoc =
            lines.any((String l) => l.trimLeft().startsWith('///'));
        if (!hasDoc) undocumented.add(file.path);
      }
      expect(undocumented, isEmpty);
    });

    test('the standard itself is present', () {
      // A rule with no written rationale becomes folklore; the test points at
      // the document, so the document cannot quietly disappear.
      expect(
        File('../../docs/components/component-standard.md').existsSync(),
        isTrue,
      );
    });
  });
}
