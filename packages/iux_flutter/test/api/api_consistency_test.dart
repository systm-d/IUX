// Cross-cutting API consistency, decided by a machine where a machine can
// decide (IUX-039).
//
// Forty missions built this surface, many in parallel. Each decided locally
// and defensibly; the risk is that the decisions do not agree with one
// another. `component_standard_test.dart` already enforces the mechanical half
// of the Component Standard *within* a component. This file enforces the
// agreements *between* components — the ones nobody owns, and which therefore
// drift.
//
// Several tests below pin a defect rather than a guarantee. Each says so, and
// each names what the correct behaviour would be, so that fixing the defect
// fails the test and the fix cannot land silently. That is the idiom
// IUX-008.9 established: pin it, then flip it.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

/// Every Dart source under `lib/src`, with comments removed.
///
/// Comments are stripped for the same reason `component_standard_test.dart`
/// strips them: a docstring that *names* an identifier is not a use of it, and
/// counting prose as a consumer is how a dead field survives an audit.
Map<String, String> _sources() {
  final Map<String, String> out = <String, String>{};
  for (final FileSystemEntity entity
      in Directory('lib/src').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final StringBuffer buffer = StringBuffer();
    bool inBlockComment = false;
    for (String line in entity.readAsLinesSync()) {
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
      if (marker >= 0 && !line.substring(0, marker).contains("'")) {
        line = line.substring(0, marker);
      }
      buffer.writeln(line);
    }
    out[entity.path] = buffer.toString();
  }
  return out;
}

/// The body of `class`/`enum` [name], brace-matched from its declaration.
String? _declarationBody(String source, RegExp head) {
  final RegExpMatch? match = head.firstMatch(source);
  if (match == null) return null;
  final int open = source.indexOf('{', match.start);
  if (open < 0) return null;
  int depth = 0;
  for (int i = open; i < source.length; i++) {
    if (source[i] == '{') depth++;
    if (source[i] == '}') {
      depth--;
      if (depth == 0) return source.substring(open + 1, i);
    }
  }
  return null;
}

void main() {
  final Map<String, String> sources = _sources();

  group('an exported type nobody needs is a defect (§19)', () {
    // The generalisation of IUX-BUTTON-DEAD-001. That finding was about a
    // *field* nothing read, and `component_standard_test.dart` now watches
    // every `Iux*Tokens` field for it. The same failure exists one level up: a
    // whole enum can be declared, exported, documented and never resolved.
    //
    // An enum is alive if either something outside its file names it, or its
    // own file resolves its members (a `switch` that turns them into pixels).
    // Zero of both means no caller can tell it apart from a comment.
    test('every enum in lib/src is referenced or resolved', () {
      final List<String> dead = <String>[];
      for (final MapEntry<String, String> entry in sources.entries) {
        for (final RegExpMatch match
            in RegExp(r'\benum\s+(Iux\w+)\s*\{').allMatches(entry.value)) {
          final String name = match.group(1)!;
          final RegExp named = RegExp('\\b$name\\b');
          final bool referencedElsewhere = sources.entries.any(
            (MapEntry<String, String> other) =>
                other.key != entry.key && named.hasMatch(other.value),
          );
          final bool resolvedHere = RegExp('\\b$name\\.').hasMatch(entry.value);
          if (!referencedElsewhere && !resolvedHere) dead.add(name);
        }
      }

      // This list was `['IuxElevation']` until IUX-039 deleted that enum:
      // four members, exported through the barrel, and named nowhere in lib/,
      // test/ or apps/. Elevation is expressed by IuxSurface's own
      // IuxSurfaceRole and by IuxGeometryTheme.elevationRaised /
      // .elevationModal, neither of which went through it.
      //
      // Equality rather than containment, on purpose: an empty list is now the
      // guarantee, so a *new* dead enum fails this.
      expect(
        dead..sort(),
        isEmpty,
        reason: 'an enum that is neither referenced nor resolved is public API '
            'with nothing behind it (PROJECT_PROMPT §19). Either resolve it or '
            'delete it.',
      );
    });

    // Guard for the two tests below. They both work by rendering a button
    // twice and asserting the two are *equal*, and an equality assertion is
    // exactly the shape that passes for the wrong reason — six vacuous tests
    // have been found in this project, and two of them were assertions that
    // could not fail. So first prove the comparison can tell two buttons
    // apart at all, using a field the package genuinely resolves.
    testWidgets('the comparison used below notices a real difference',
        (WidgetTester tester) async {
      Future<String> render(IuxActionAvailability availability) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: IuxTheme.fromConfiguration(const IuxThemeConfiguration()),
            home: Scaffold(
              body: IuxButton(
                label: 'Save',
                action: IuxActionDescriptor(
                  semantics: const IuxActionSemantics(
                    label: 'Save',
                    unavailabilityReason: 'Fill the form in first',
                  ),
                  availability: availability,
                ),
                onActivate: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        return tester
            .getSemantics(find.bySemanticsLabel('Save'))
            .toStringDeep();
      }

      expect(
        await render(IuxActionAvailability.enabled),
        isNot(await render(IuxActionAvailability.disabled)),
        reason: 'if this ever passes, the two tests below prove nothing',
      );
    });

    testWidgets('IuxActionDescriptor.importance reaches the screen',
        (WidgetTester tester) async {
      // This test used to assert the opposite, and passed: `importance` was
      // stored, copied by copyWith, compared in ==, folded into hashCode — and
      // read by nothing in lib/, so high, medium and low rendered identically.
      // That is precisely the shape IUX-BUTTON-DEAD-001 described: "the value
      // is computed, stored, compared in `==` and hashed. It simply never
      // reaches a pixel."
      //
      // IUX-039 gave it the one job that is neither a duplicate of the variant
      // nor a second colour channel: it chooses the container an action is
      // drawn in when the call site names no variant. All three values must
      // now differ from one another, which is the whole claim.
      //
      // Measured rather than grepped, because `.importance` is a common enough
      // name that a textual scan could be fooled by another class's field —
      // the false negative `component_standard_test.dart` documents.
      Future<BoxDecoration> pump(IuxActionImportance importance) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: IuxTheme.fromConfiguration(const IuxThemeConfiguration()),
            home: Scaffold(
              body: IuxButton(
                label: 'Save',
                action: IuxActionDescriptor(
                  semantics: const IuxActionSemantics(label: 'Save'),
                  intent: IuxActionIntent.primary,
                  importance: importance,
                ),
                onActivate: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        return tester
            .widget<AnimatedContainer>(find.byType(AnimatedContainer))
            .decoration! as BoxDecoration;
      }

      final BoxDecoration high = await pump(IuxActionImportance.high);
      final BoxDecoration medium = await pump(IuxActionImportance.medium);
      final BoxDecoration low = await pump(IuxActionImportance.low);

      const String why = 'IuxActionImportance is a three-member public enum. '
          'Two members that resolve to the same container are one member and '
          'a synonym (PROJECT_PROMPT §19).';
      expect(<Object?>[
        high.color,
        high.border
      ], isNot(<Object?>[medium.color, medium.border]), reason: why);
      expect(<Object?>[
        medium.color,
        medium.border
      ], isNot(<Object?>[low.color, low.border]), reason: why);
      expect(<Object?>[
        high.color,
        high.border
      ], isNot(<Object?>[low.color, low.border]), reason: why);
    });

    testWidgets('IuxActionRole changes nothing observable either',
        (WidgetTester tester) async {
      // IuxActionRole documented itself as "used for semantics, feedback and
      // pattern selection". Measured, it drives none of the three: the only
      // reads of IuxActionDescriptor.role in lib/ are two debug assertions
      // (undo-must-be-reversible, and IuxEmptyStateAction refusing `retry`).
      //
      // IUX-039 kept the enum and corrected the docstring instead of wiring or
      // shrinking it, and this test stays green on purpose. Unlike
      // `importance`, role is not a knob whose effect is missing: it is a
      // vocabulary whose value is what it *forbids*, and error prevention is
      // §22's whole subject. Rendering it would also help exactly one kind of
      // user — two buttons differing only by role would differ for a sighted
      // reader and not for a screen-reader one, which the component standard
      // refuses.
      //
      // One correction to the finding that produced this test: it recorded
      // confirm, edit and select as "never constructed, in lib/, test/ or
      // apps/". `IuxActionRole.confirm` is constructed at
      // apps/pilot/lib/job_detail_screen.dart:71. edit and select remain
      // unused, which is what an unused member of a caller-facing vocabulary
      // looks like — not a defect.
      Future<String> announce(IuxActionRole role) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: IuxTheme.fromConfiguration(const IuxThemeConfiguration()),
            home: Scaffold(
              body: IuxButton(
                label: 'Go',
                action: IuxActionDescriptor(
                  semantics: const IuxActionSemantics(label: 'Go'),
                  role: role,
                ),
                onActivate: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        return tester.getSemantics(find.bySemanticsLabel('Go')).toStringDeep();
      }

      expect(
        await announce(IuxActionRole.select),
        await announce(IuxActionRole.custom),
        reason: 'a role the semantics layer never reads tells assistive '
            'technology nothing, whatever its docstring claims. Resolve it or '
            'shrink the enum to the members that do something '
            '(PROJECT_PROMPT §19).',
      );
    });

    test('every IuxConfirmationPolicy member is honoured by something', () {
      // IuxConfirmationPolicy was sealed with four members. Exactly one type
      // in the package evaluates a confirmation policy —
      // IuxDestructiveActionController — and it asserts that the policy is
      // either IuxNoConfirmation or IuxConfirmBeforeExecution. So
      // IuxConfirmByHold and IuxConfirmByDoubleActivation were exported,
      // documented, constructible, and honoured by nothing at all: measured,
      // `IuxButton` with IuxConfirmByHold ran onActivate on the first ordinary
      // tap. IUX-039 removed both.
      //
      // This was adjacent to IUX-BUTTON-CONFIRM-001 but not the same finding:
      // that one was a policy one widget honoured and three ignored. These two
      // were honoured by *zero*. Both are now closed, and by opposite moves —
      // these two left the type, while the surviving member got the rule that
      // whoever honours it strips it before delegating, and whatever cannot
      // present it refuses it rather than dropping it in silence.
      //
      // The guarantee is now structural, so a fifth member cannot be added
      // without something reading it. Source-level rather than rendered,
      // because "is honoured" is not a pixel: it is whether any file outside
      // the model performs a type test against the member.
      final String model = sources.entries
          .firstWhere((MapEntry<String, String> e) =>
              e.key.endsWith('iux_action_model.dart'))
          .value;
      final List<String> members = RegExp(
        r'final class (Iux\w+) extends IuxConfirmationPolicy',
      ).allMatches(model).map((RegExpMatch m) => m.group(1)!).toList()
        ..sort();

      expect(
          members, <String>['IuxConfirmBeforeExecution', 'IuxNoConfirmation'],
          reason: 'sanity: the scan found the wrong set of members');

      for (final String member in members) {
        final bool honoured = sources.entries.any(
          (MapEntry<String, String> e) =>
              !e.key.endsWith('iux_action_model.dart') &&
              RegExp('is\\s+$member\\b').hasMatch(e.value),
        );
        expect(
          honoured,
          isTrue,
          reason: '$member is a member of a sealed *safety* type that nothing '
              'reads. A caller who states a precaution and receives none is '
              'worse off than one who states nothing, because the call site '
              'reads as if the user were being asked (PROJECT_PROMPT §5, §22). '
              'Either something evaluates it, or it leaves the type.',
        );
      }
    });
  });

  group('the same concept keeps one name', () {
    test('IuxNamedAction and IuxTransientAction are still the same type', () {
      // Two public value types, declared in different files by different
      // missions, with byte-identical shape: {required label, required
      // onActivate, semanticLabel?}, the same effectiveSemanticLabel getter,
      // the same == and the same hashCode. Nothing distinguishes them but the
      // name, and the names force a caller with one to rebuild it as the other
      // to move a control from a banner into a snack bar.
      //
      // Half of the fix has landed: `IuxInlineFeedbackAction` is now
      // `IuxNamedAction`, a name about the shape rather than about one of the
      // five places it is used. The other half is one line in
      // `lib/src/components/transient/iux_transient_message.dart` — delete
      // `IuxTransientAction` and type `IuxTransientMessage.action` as
      // `IuxNamedAction` — and this test stays until it lands.
      List<String> fieldsOf(String className) {
        for (final String source in sources.values) {
          final String? body = _declarationBody(
            source,
            RegExp('^final class $className \\{', multiLine: true),
          );
          if (body == null) continue;
          return RegExp(r'^  final [\w<>?, ]+? (\w+);', multiLine: true)
              .allMatches(body)
              .map((RegExpMatch m) => m.group(1)!)
              .toList()
            ..sort();
        }
        return <String>['<not found>'];
      }

      final List<String> inline = fieldsOf('IuxNamedAction');
      expect(inline, <String>['label', 'onActivate', 'semanticLabel']);
      expect(
        fieldsOf('IuxTransientAction'),
        inline,
        reason: 'these two declare the same fields and mean the same thing. '
            'One of them should be the other (PROJECT_PROMPT §19: "Existe-t-il '
            'déjà une API similaire ?"). Until then, this test makes the '
            'duplication visible: change one and you are told the other '
            'exists.',
      );
    });

    test('`summary` names three unrelated types', () {
      // The worst of the two naming failures: not one concept under several
      // names, but several concepts under one. A caller who has learned what
      // `summary:` means on IuxProgressiveDisclosure has learned something
      // false about IuxForm.
      final Map<String, String> declared = <String, String>{};
      for (final String source in sources.values) {
        String? owner;
        for (final String line in source.split('\n')) {
          // Any class resets the owner, including a private one: without
          // that, a private widget's field is attributed to the last public
          // class seen — which is exactly how _IuxSearchStatus.summary hid
          // IuxSearchResults.summary the first time this was written.
          final RegExpMatch? head = RegExp(
            r'^(?:final\s+|sealed\s+|base\s+)*class\s+(_?\w+)',
          ).firstMatch(line);
          if (head != null) owner = head.group(1);
          final RegExpMatch? field =
              RegExp(r'^  final ([\w<>?, ]+?) summary;').firstMatch(line);
          if (field != null && owner != null && owner.startsWith('Iux')) {
            declared[owner] = field.group(1)!;
          }
        }
      }

      expect(
        declared,
        <String, String>{
          'IuxProgressiveDisclosure': 'String',
          'IuxForm': 'IuxValidationSummaryLabels?',
          'IuxGuidedForm': 'IuxValidationSummaryLabels',
          'IuxSearchResults': 'IuxSearchSummary<T>',
        },
        reason: 'one parameter name, three meanings: the visible headline of a '
            'collapsed section, the labels of a validation-error summary, and '
            'a function that counts search results. Rename at least the first '
            'and the last — `headline` and `describeResults` say what they '
            'are. A fourth meaning appearing here is the failure this test '
            'exists to catch.',
      );
    });

    testWidgets(
        'busyLabel and busyHint do different things under near-identical names',
        (WidgetTester tester) async {
      // Six public constructors take `busyHint`; one takes `busyLabel`. The
      // difference is real but undiscoverable from the names: `busyHint` is
      // optional and only appends to the announcement, while `busyLabel` is
      // required and *replaces the visible text* as well.
      //
      // Measured, so the divergence is a fact rather than a reading of two
      // docstrings.
      final IuxAsyncActionController controller = IuxAsyncActionController(
        action: const IuxActionDescriptor(
          semantics: IuxActionSemantics(label: 'Pay'),
        ),
        operation: (IuxAsyncActionSignal signal) async {
          await Future<void>.delayed(const Duration(seconds: 1));
          return const IuxAsyncOutcome.succeeded();
        },
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: IuxTheme.fromConfiguration(const IuxThemeConfiguration()),
          home: Scaffold(
            body: Column(
              children: <Widget>[
                IuxButton(
                  label: 'Save draft',
                  busyHint: 'Saving',
                  action: const IuxActionDescriptor(
                    semantics: IuxActionSemantics(label: 'Save draft'),
                    operation: IuxActionOperation.inProgress,
                  ),
                  onActivate: () {},
                ),
                IuxAsyncActionButton(
                  controller: controller,
                  label: 'Pay',
                  busyLabel: 'Paying',
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Pay'));
      await tester.pump();

      // busyHint: the visible label is untouched.
      expect(find.text('Save draft'), findsOneWidget);
      expect(find.text('Saving'), findsNothing);

      // busyLabel: the visible label is replaced.
      expect(find.text('Pay'), findsNothing);
      expect(
        find.text('Paying'),
        findsOneWidget,
        reason: 'busyLabel replaces the visible text and busyHint does not, '
            'and no caller could guess that from the names. Either both are '
            'busyHint and the label swap becomes its own parameter, or the '
            'six optional busyHints become busyLabels. Pick one '
            '(PROJECT_PROMPT §19).',
      );

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    });

    test('the dismissal callback is past tense everywhere but one', () {
      // §7 of the Component Standard: "Callbacks are named for what happened
      // (onPressed), not for what should follow (onSave)." Four public widgets
      // said onDismiss and one said onDismissed, and iux_transient_layer.dart
      // used *both* spellings internally, which is how you could tell it was
      // an accident rather than a distinction. By the standard's own rule the
      // minority spelling was the correct one, so it won.
      //
      // IuxNavigationDrawer is the one left, because that file belonged to a
      // concurrent mission. One line, and this expectation becomes
      // `imperative, isEmpty`.
      final Set<String> imperative = <String>{};
      final Set<String> pastTense = <String>{};
      for (final MapEntry<String, String> entry in sources.entries) {
        String? owner;
        for (final String line in entry.value.split('\n')) {
          final RegExpMatch? head =
              RegExp(r'^(?:final\s+)?class\s+(_?\w+)').firstMatch(line);
          if (head != null) owner = head.group(1);
          if (owner == null || !owner.startsWith('Iux')) continue;
          if (RegExp(r'^  final VoidCallback onDismiss;').hasMatch(line)) {
            imperative.add(owner);
          }
          if (RegExp(r'^  final VoidCallback onDismissed;').hasMatch(line)) {
            pastTense.add(owner);
          }
        }
      }

      expect(
        <String>{...imperative, ...pastTense}.length,
        greaterThan(1),
        reason: 'sanity: the scan found nothing',
      );
      expect(
        pastTense,
        <String>{
          'IuxTransientLayer',
          'IuxDialog',
          'IuxBottomSheet',
          'IuxInlineFeedbackDismissal',
        },
        reason: 'one spelling, not two. Component Standard §7: a callback is '
            'named for what happened.',
      );
      expect(
        imperative,
        <String>{'IuxNavigationDrawer'},
        reason: 'the last imperative spelling. Renaming '
            'IuxNavigationDrawer.onDismiss to onDismissed finishes '
            'IUX-API-NAMING-001 and this expectation becomes isEmpty.',
      );
    });
  });

  group('sealed types agree on how they are built', () {
    // Eight sealed types model "which situation is this". Three fronted their
    // members with `const factory` redirects and five expected the caller to
    // name the subclass. Both are reasonable; having both was not — a caller
    // wrote `IuxLoadState.loading()` on one line and `IuxNoWayBack()` on the
    // next, for the same modelling idea.
    //
    // The factory convention won, because it is additive: the subclass names
    // still work, so nothing that named one had to change, and the sealed
    // type became the one place a caller has to look to find out which
    // situations exist.
    test('every sealed situation type fronts its members with a factory', () {
      final Set<String> withFactories = <String>{};
      final Set<String> withoutFactories = <String>{};
      for (final String source in sources.values) {
        for (final RegExpMatch match in RegExp(
          r'^sealed class (Iux\w+)(?:<[^>]*>)?\s*\{',
          multiLine: true,
        ).allMatches(source)) {
          final String name = match.group(1)!;
          final String? body = _declarationBody(
            source,
            RegExp('^sealed class $name(?:<[^>]*>)?\\s*\\{', multiLine: true),
          );
          if (body == null) continue;
          if (body.contains('const factory ')) {
            withFactories.add(name);
          } else {
            withoutFactories.add(name);
          }
        }
      }

      expect(
        withFactories,
        <String>{
          'IuxLoadState',
          'IuxDisclosureState',
          'IuxAsyncOutcome',
          'IuxEmptyStateCause',
          'IuxPermissionMoment',
          'IuxRecoveryRoute',
          'IuxWayBack',
          // Added by IuxPlaceMap: whether the map zooms, and if it does, how
          // somebody zooms it without a pinch. Follows the convention this
          // census exists to hold — `const factory IuxMapZoom.controls` and
          // `const factory IuxMapZoom.fixed`.
          'IuxMapZoom',
        },
      );
      expect(
        withoutFactories,
        <String>{'IuxConfirmationPolicy'},
        reason: 'the last sealed type still expecting the caller to name a '
            'subclass. It lives in lib/src/actions/, which belonged to a '
            'concurrent mission; adding `const factory '
            'IuxConfirmationPolicy.beforeExecution()` beside its existing '
            '`none` finishes IUX-API-NAMING-001 and this expectation becomes '
            'isEmpty. A new sealed type must land in one of these sets '
            'deliberately, which is what this test is for.',
      );
    });

    test('the factory redirects build the members they name', () {
      // The scan above reads source. This builds one member of each family the
      // fix touched and compares it with the subclass call it redirects to, so
      // a factory whose signature drifted from its subclass is a failure here
      // rather than a surprise at a call site.
      void same(Object viaFactory, Object viaSubclass) {
        expect(viaFactory, viaSubclass);
        expect(viaFactory.runtimeType, viaSubclass.runtimeType);
      }

      void nothing() {}

      same(
        const IuxRecoveryRoute.unrecoverable(guidance: 'Nothing was charged'),
        const IuxUnrecoverable(guidance: 'Nothing was charged'),
      );
      same(
        IuxRecoveryRoute.retry(label: 'Try again', onRetry: nothing),
        IuxRetryRoute(label: 'Try again', onRetry: nothing),
      );
      same(const IuxWayBack.none(), const IuxNoWayBack());
      same(
        IuxWayBack.undo(
          notice: 'Invoice archived',
          undoLabel: 'Undo',
          dismissLabel: 'Dismiss the archived-invoice notice',
          onUndo: nothing,
        ),
        IuxUndoOffer(
          notice: 'Invoice archived',
          undoLabel: 'Undo',
          dismissLabel: 'Dismiss the archived-invoice notice',
          onUndo: nothing,
        ),
      );
      same(
        const IuxEmptyStateCause.nothingLeftToDo(),
        const IuxNothingLeftToDo(),
      );
      final IuxNamedAction decline =
          IuxNamedAction(label: 'Not now', onActivate: nothing);
      final IuxNamedAction ask =
          IuxNamedAction(label: 'Choose camera access', onActivate: nothing);
      same(
        IuxPermissionMoment.beforeAsking(ask: ask, decline: decline),
        IuxBeforeAsking(ask: ask, decline: decline),
      );
      same(
        IuxPermissionMoment.systemWillNotAsk(decline: decline),
        IuxSystemWillNotAsk(decline: decline),
      );
    });

    test('every sealed situation type is required except one', () {
      // IuxRecoveryRoute, IuxWayBack, IuxDisclosureState, IuxPermissionMoment,
      // IuxLoadState and IuxEmptyStateCause are all `required` at their
      // consumer: having no way out is something somebody stated, which is the
      // whole argument of IUX-DESTRUCTIVE-FLOW-002.
      //
      // IuxConfirmationPolicy is the exception. It is defaulted on
      // IuxActionDescriptor, so "this action needs no confirmation" is the one
      // safety-relevant answer in the package that nobody has to give.
      final String descriptor = sources.entries
          .firstWhere((MapEntry<String, String> e) =>
              e.key.endsWith('iux_action_descriptor.dart'))
          .value;

      expect(
        descriptor.contains('this.confirmation = IuxConfirmationPolicy.none'),
        isTrue,
        reason: 'IuxConfirmationPolicy is the only sealed type in the package '
            'reachable without the caller naming a member. Every other one is '
            'required at its consumer. If confirmation became required too, '
            'this test should be deleted — and that would be the consistent '
            'end state.',
      );

      for (final MapEntry<String, String> required in <String, String>{
        'iux_error_recovery.dart': 'required this.route',
        'iux_loading_retry.dart': 'required this.state',
        'iux_progressive_disclosure.dart': 'required this.state',
        'iux_permission_rationale.dart': 'required this.moment',
        'iux_empty_state.dart': 'required this.cause',
      }.entries) {
        final String source = sources.entries
            .firstWhere(
                (MapEntry<String, String> e) => e.key.endsWith(required.key))
            .value;
        expect(
          source.contains(required.value),
          isTrue,
          reason: '${required.key} must keep its sealed situation required',
        );
      }
    });

    test('only IuxEmptyStateCause takes a descriptor it did not build', () {
      // Three sealed families derive their IuxActionDescriptor from the words
      // and callbacks the caller supplied: IuxRecoveryRoute, IuxPermissionMoment
      // and IuxWayBack. One accepts a finished descriptor from the caller —
      // and is the only one that then needs defensive assertions to police
      // what it was handed.
      final String model = sources.entries
          .firstWhere((MapEntry<String, String> e) =>
              e.key.endsWith('iux_empty_state_model.dart'))
          .value;

      expect(model.contains('final IuxActionDescriptor action;'), isTrue);
      expect(
        RegExp(r'assert\(\s*action\.').allMatches(model).length,
        greaterThanOrEqualTo(2),
        reason: 'accepting a caller-built descriptor is what forces '
            'IuxEmptyStateAction to assert that the role is not retry, that '
            'the confirmation is none, and that a disabled action explains '
            'itself. The three siblings that derive need no such checks. That '
            'asymmetry is the cost of the inconsistency, and it is measured '
            'here so a fourth family does not copy the wrong sibling.',
      );
    });
  });

  group('constructor shape', () {
    test('only the two row constructors reach eleven parameters', () {
      // §20 names an eleven-parameter widget as the shape to avoid, and
      // IUX-038 used that rule to refuse a refactor. Measured across all 59
      // public widget constructors, exactly one already sat at eleven —
      // so the rule was applied to block new work while an existing widget
      // sat over the line.
      //
      // Worth saying plainly: none of IuxListItem.selectable's eleven is a
      // styling knob. §20's complaint is about colour/elevation/radius/shadow,
      // and this is content slots plus focus plumbing. The arity is real; the
      // shape §20 warns about is not. That is a reason to weigh arity less,
      // not a reason to ignore it.
      //
      // IuxListItem.tappable joined it at IUX-LISTITEM-STATE-001, and the
      // argument it had to win is written here rather than in a commit
      // message, because this list is where the next arrival will be weighed.
      // The eleventh is `disclosure`, and it is a §21 parameter: it names
      // where activation leads — `opensScreen` — and not what to draw. The
      // component refuses to derive it, because only the caller knows whether
      // `onActivate` pushes a route, expands something in place, or leaves the
      // application; and it refuses to assume it, because a chevron on a row
      // that opens a browser promises a screen the back button returns from.
      // Deriving it would have kept the arity and cost the truth. The
      // alternative measured against it was a fourth named constructor, which
      // would have duplicated all ten of the others to express one bit.
      //
      // Both rows being at eleven is now the ceiling, not the trend. A third
      // constructor arriving here, or a twelfth parameter on either of these
      // two, is still the signal §20 describes.
      final Map<String, int> arity = <String, int>{};
      for (final String source in sources.values) {
        final List<String> lines = source.split('\n');
        String? owner;
        bool isWidget = false;
        for (int i = 0; i < lines.length; i++) {
          final RegExpMatch? head = RegExp(
            r'^(?:final\s+)?class\s+(\w+)(?:<[^>]*>)?\s+extends\s+(\w+)',
          ).firstMatch(lines[i]);
          if (head != null) {
            owner = head.group(1);
            isWidget = head.group(2) == 'StatelessWidget' ||
                head.group(2) == 'StatefulWidget';
          }
          final RegExpMatch? ctor =
              RegExp(r'^  (?:const\s+)?(\w+)(?:\.(\w+))?\(\s*\{?\s*$')
                  .firstMatch(lines[i]);
          if (ctor == null ||
              owner == null ||
              !isWidget ||
              !owner.startsWith('Iux') ||
              ctor.group(1) != owner) {
            continue;
          }
          int count = 0;
          for (int j = i + 1; j < lines.length; j++) {
            final String line = lines[j].trim();
            if (line.startsWith('})') || line.startsWith(')')) break;
            if (line.startsWith('super.key')) continue;
            if (RegExp(r'^(?:required\s+)?\S.*,$').hasMatch(line)) count++;
          }
          final String name =
              ctor.group(2) == null ? owner : '$owner.${ctor.group(2)}';
          arity[name] = count;
        }
      }

      expect(arity.length, greaterThan(50),
          reason: 'sanity: the scan found '
              'almost no constructors, so the regex has drifted');

      final List<String> atEleven = arity.entries
          .where((MapEntry<String, int> e) => e.value >= 11)
          .map((MapEntry<String, int> e) => '${e.key}(${e.value})')
          .toList()
        ..sort();

      expect(
        atEleven,
        <String>['IuxListItem.selectable(11)', 'IuxListItem.tappable(11)'],
        reason: 'PROJECT_PROMPT §20. A twelfth parameter on any widget, or a '
            'third widget reaching eleven, is the signal that a component is '
            'doing two jobs. Full ranking: '
            '${(arity.entries.toList()..sort((MapEntry<String, int> a, MapEntry<String, int> b) => b.value.compareTo(a.value))).take(6).map((MapEntry<String, int> e) => '${e.key}=${e.value}').join(', ')}',
      );
    });
  });
}
