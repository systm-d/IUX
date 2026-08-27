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
///
/// The same exclusion has now deleted three different things. It took `onTap`
/// first (IUX-005 to IUX-011), and it takes the `Focus` widget's own
/// `focusable`/`focused`/`onFocus` annotations, which is IUX-A11Y-FOCUS-001 —
/// fixed for `IuxButton` at IUX-038 and left in place at every other call site,
/// because nothing mechanical was watching the call sites. The second group
/// below watches them.
void main() {
  final List<File> sources = Directory('lib/src')
      .listSync(recursive: true)
      .whereType<File>()
      .where((File file) => file.path.endsWith('.dart'))
      .toList();

  test('the library has sources to check', () {
    expect(sources, isNotEmpty);
  });

  group('a node announced as a control offers something to activate', () {
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
            reason: 'a Semantics node in ${source.path} can announce itself '
                'as a button — the flag is `true` or computed — without an '
                'onTap. If excludeSemantics is also set — and it '
                'is, wherever the name is being replaced — the child\'s own '
                'tap action is gone too, so a screen reader announces a '
                'button and activating it does nothing.\n\nThe call:\n'
                '${call.text}',
          );
        }
      });
    }
  });

  // The group above reads bare `Semantics(` calls, so it never looked inside a
  // control that composes an IuxSemantics helper instead — which is every
  // control IUX ships. The helper writes `button: true` and `onTap:` in its own
  // source, so it satisfies that scan on behalf of all of them while its
  // callers pass neither. Three controls were announced as buttons with no tap
  // action at all under exactly that blind spot.
  group('a control built on an excluding helper names its focus node', () {
    for (final File source in sources) {
      // Comments are stripped: the helper's own doc comment carries a worked
      // example, and half a dozen files mention the helper in prose.
      final String text = _withoutComments(source.readAsStringSync());
      if (!_composesExcludingHelper(text)) continue;

      test(source.path, () {
        for (final _SemanticsCall call in _helperCalls(text)) {
          expect(
            call.namesFocusNode,
            isTrue,
            reason: 'An excluding IuxSemantics helper in ${source.path} is '
                'composed without a focusNode. The helper sets '
                'excludeSemantics in order to control the announced name, '
                'which deletes the '
                'Focus widget\'s own focusable/focused/onFocus annotations '
                'from the subtree. Without the node named here the control '
                'declares no focusable state at all and assistive technology '
                'has no way to move accessibility focus onto it — WCAG 2.2 '
                'SC 4.1.2, IUX-A11Y-FOCUS-001.\n\nThe call:\n${call.text}',
          );
          expect(
            call.offersActivation,
            isTrue,
            reason: 'An excluding IuxSemantics helper in ${source.path} is '
                'composed without an onTap. The same exclusion removes the '
                'child\'s own tap action, so it is announced as a control and '
                'a screen-reader double-tap does nothing — IUX-011, which '
                'shipped for six missions.\n\nThe call:\n${call.text}',
          );
        }

        expect(
          text.contains('IuxFocusNodeOwner('),
          isTrue,
          reason: 'a control in ${source.path} composes an excluding '
              'IuxSemantics helper without routing through '
              'IuxFocusNodeOwner. The node it names '
              'has to be the same node IuxFocusable holds, and it is usually '
              'null at the call site, so the alternative is four lines — hold '
              'a fallback, create it lazily, prefer the caller\'s, dispose '
              'only the one it owns — copied at every call site. The copy '
              'most easily forgotten is the disposal.',
        );
      });
    }
  });
}

/// [source] with every whole-line comment removed.
///
/// Coarse on purpose: it does not try to understand a trailing comment or a
/// string that happens to contain `//`. It only has to stop prose and doc
/// samples that name the helper from being read as call sites, and a
/// whole-line rule does that without ever removing an argument.
String _withoutComments(String source) => source
    .split('\n')
    .where((String line) => !line.trimLeft().startsWith('//'))
    .join('\n');

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

  /// Whether this node may announce itself as a button.
  ///
  /// Anything but a literal `false`, which is wider than it looks and is the
  /// point. The predicate used to require a literal `true`, so
  /// `Semantics(button: onTap != null, …)` — the whole of `IuxTapTarget` — was
  /// never examined, and it shipped announcing a button with nothing to
  /// activate (`IUX-TAPTARGET-ACTION-001`). A node whose button flag is
  /// computed is exactly the node most worth checking: it is a button
  /// *sometimes*, and the sometimes is where the action goes missing.
  bool get declaresButton =>
      RegExp(r'\bbutton:\s*(?!false\b)\S').hasMatch(_ownArguments);

  /// A node may be activated through `onTap`, or through the platform's
  /// increase/decrease pair, or by a slider's own gestures.
  bool get offersActivation => RegExp(
        r'\b(onTap|onIncrease|onDecrease|onLongPress|onDismissed)\s*:',
      ).hasMatch(_ownArguments);

  /// Whether this call tells the node which focus node it describes.
  bool get namesFocusNode => RegExp(r'\bfocusNode\s*:').hasMatch(_ownArguments);
}

Iterable<_SemanticsCall> _semanticsCalls(String source) =>
    _callsTo(source, RegExp(r'(?<![A-Za-z_$.])Semantics\('));

/// The helpers that replace the announced name and therefore delete the
/// subtree — including the `Focus` widget's own annotations.
///
/// `IuxSemantics.header`, `.image` and `.disabled` exclude too, and are absent
/// on purpose: none of them describes something the user can focus.
final RegExp _excludingHelper = RegExp(r'\bIuxSemantics\.(action|selection)\(');

bool _composesExcludingHelper(String source) =>
    _excludingHelper.hasMatch(source);

Iterable<_SemanticsCall> _helperCalls(String source) =>
    _callsTo(source, _excludingHelper);

Iterable<_SemanticsCall> _callsTo(String source, RegExp opening) sync* {
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
