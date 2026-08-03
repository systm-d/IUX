import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Enforces the mechanical half of the Component Standard over `lib/src/inputs`.
///
/// `test/components/component_standard_test.dart` scopes itself to
/// `lib/src/components/` and `lib/src/patterns/`. The input foundations sit
/// outside both, so without this file the same rules would be enforced for the
/// button and merely hoped for here. A checklist nobody runs is a wish.
void main() {
  final Directory inputs = Directory('lib/src/inputs');

  List<File> sources() {
    if (!inputs.existsSync()) return <File>[];
    return inputs
        .listSync(recursive: true)
        .whereType<File>()
        .where((File file) => file.path.endsWith('.dart'))
        .toList();
  }

  /// Strips comments so prose explaining a rule is not mistaken for a
  /// violation of it.
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

  void forbid(String description, Pattern pattern, {required String instead}) {
    test(description, () {
      final List<String> offenders = <String>[];
      for (final File file in sources()) {
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

  group('the input layer never reaches below the layers it is given', () {
    test('there is something to check', () {
      // A rule that silently matches nothing passes forever.
      expect(sources(), isNotEmpty);
    });

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
      'no hardcoded animation duration',
      RegExp(r'Duration\(milliseconds:\s*\d'),
      instead: 'IuxMotionPolicy.resolve(context, role: ...)',
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
      'no navigation from an input',
      RegExp(r'Navigator\.'),
      instead: 'a callback the parent handles',
    );

    forbid(
      'no snack bar shown by an input',
      RegExp(r'ScaffoldMessenger\.'),
      instead: 'a callback the parent handles',
    );

    forbid(
      'no network access',
      RegExp(r'''\b(HttpClient|http\.get|Dio\()'''),
      instead: 'data supplied by the parent',
    );

    forbid(
      'no hardcoded spacing or size',
      RegExp(r'EdgeInsets\.(all|symmetric|only)\([^)]*\d'),
      instead: 'IuxGeometryTheme spacing steps',
    );
  });

  group('the input foundations invent no user-facing text', () {
    test('no caller string is ever interpolated outside toString', () {
      // Every string a user reads arrives already localised from the caller.
      // A framework-authored "This field is required" would be the wrong
      // language, the wrong wording, or both. toString is diagnostic output
      // that no user sees, so its whole body is excluded rather than the
      // individual lines that happen to mention a field.
      final RegExp interpolation = RegExp(r'\$\{?(label|message|helpText)\b');
      final List<String> offenders = <String>[];
      for (final File file in sources()) {
        bool inToString = false;
        for (final String line in code(file).split('\n')) {
          if (line.contains('String toString()')) inToString = true;
          if (inToString) {
            if (line.trimRight().endsWith(';')) inToString = false;
            continue;
          }
          if (interpolation.hasMatch(line)) {
            offenders.add('${file.path}: ${line.trim()}');
          }
        }
      }
      expect(offenders, isEmpty);
    });
  });

  group('documentation keeps pace with the code', () {
    test('every input source is documented at the top', () {
      final List<String> undocumented = <String>[];
      for (final File file in sources()) {
        final bool documented = file
            .readAsLinesSync()
            .any((String line) => line.trimLeft().startsWith('///'));
        if (!documented) undocumented.add(file.path);
      }
      expect(undocumented, isEmpty);
    });

    test('the written rationale is present', () {
      // A rule with no written rationale becomes folklore.
      expect(File('../../docs/inputs/input-model.md').existsSync(), isTrue);
      expect(File('../../docs/inputs/theme.md').existsSync(), isTrue);
    });
  });
}
