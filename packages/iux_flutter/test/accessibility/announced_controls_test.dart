import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Mechanical enforcement of the defect that shipped once already.
///
/// `IuxSemantics.action` sets `excludeSemantics`, which replaces the child's
/// announced name — and deletes the child gesture detector's tap action along
/// with it. Every IUX button was announced as a button and offered nothing to
/// activate, so a screen-reader double-tap did nothing at all. The control was
/// visible, correctly named, and unusable. It was present from IUX-005 until a
/// subagent flagged it during IUX-011.
///
/// Two regression tests now cover the buttons themselves. This file covers the
/// shape: anywhere in the library that announces a node as a button must also
/// give that node something to activate. A reviewer will not catch this by
/// reading, because the broken version reads as correct.
void main() {
  group('a node announced as a control offers something to activate', () {
    final List<File> sources = Directory('lib/src')
        .listSync(recursive: true)
        .whereType<File>()
        .where((File file) => file.path.endsWith('.dart'))
        .toList();

    test('the library has sources to check', () {
      expect(sources, isNotEmpty);
    });

    for (final File source in sources) {
      final String text = source.readAsStringSync();
      // Cheap pre-filter. Most files compose no Semantics at all.
      if (!text.contains('Semantics(')) continue;

      test(source.path, () {
        for (final _SemanticsCall call in _semanticsCalls(text)) {
          if (!call.declaresButton) continue;
          expect(
            call.offersActivation,
            isTrue,
            reason: 'a Semantics node in ${source.path} sets button: true '
                'without an onTap. If excludeSemantics is also set — and it '
                'is, wherever the name is being replaced — the child\'s own '
                'tap action is gone too, so a screen reader announces a '
                'button and activating it does nothing.\n\nThe call:\n'
                '${call.text}',
          );
        }
      });
    }
  });
}

/// One `Semantics(...)` invocation, extracted with balanced parentheses.
///
/// A regex over the whole call would stop at the first `)` inside a nested
/// widget and read the arguments of something else entirely.
class _SemanticsCall {
  const _SemanticsCall(this.text);

  final String text;

  /// The argument list of this call only, with nested calls removed.
  ///
  /// Without this, a `Semantics(button: true, child: IconButton(onTap: ...))`
  /// would look like it carried an `onTap` of its own.
  String get _ownArguments {
    final StringBuffer buffer = StringBuffer();
    int depth = 0;
    // Skip past `Semantics(` itself, then copy only what sits at depth 0.
    for (int i = text.indexOf('(') + 1; i < text.length; i++) {
      final String character = text[i];
      if (character == '(' || character == '[' || character == '{') depth++;
      if (character == ')' || character == ']' || character == '}') depth--;
      if (depth < 0) break;
      if (depth == 0) buffer.write(character);
    }
    return buffer.toString();
  }

  bool get declaresButton =>
      RegExp(r'\bbutton:\s*true').hasMatch(_ownArguments);

  /// A node may be activated through `onTap`, or through the platform's
  /// increase/decrease pair, or by a slider's own gestures.
  bool get offersActivation => RegExp(
        r'\b(onTap|onIncrease|onDecrease|onLongPress|onDismiss)\s*:',
      ).hasMatch(_ownArguments);
}

Iterable<_SemanticsCall> _semanticsCalls(String source) sync* {
  final RegExp opening = RegExp(r'(?<![A-Za-z_$.])Semantics\(');
  for (final RegExpMatch match in opening.allMatches(source)) {
    int depth = 0;
    int end = match.end - 1;
    for (int i = match.end - 1; i < source.length; i++) {
      final String character = source[i];
      if (character == '(') depth++;
      if (character == ')') {
        depth--;
        if (depth == 0) {
          end = i;
          break;
        }
      }
    }
    yield _SemanticsCall(source.substring(match.start, end + 1));
  }
}
