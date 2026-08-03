# IUX Component Standard

The rules every IUX component follows. Missions from IUX-008.2 onward apply
this document rather than restating it.

Where this document and a mission disagree, `PROJECT_PROMPT.md` decides.

## 1. What a component is

A component is a reusable interface element that expresses an **intent** and
holds no application knowledge.

It contains no business logic, no network, no storage, no navigation, and no
brand identity. It renders state it is given and reports interaction it
receives.

## 2. The layers a component may use

```text
Foundations      IuxSpacing, IuxTouchTarget, IuxDensity…
Semantic tokens  IuxSemanticColors and its role groups
Themes           IuxTypographyTheme, IuxGeometryTheme, IuxMotionTheme,
                 IuxAccessibilityTheme, IuxFeedbackTheme
Runtime          IuxAccessibility, IuxMotionPolicy, IuxSemantics,
                 IuxTapTarget, IuxFocusRing, IuxFeedbackScope
Layout           IuxSurface, IuxSection, IuxGap, IuxTargetSpacing
```

A component never reaches around these. Concretely, it never:

| Never | Use instead |
| --- | --- |
| a `Color` literal | `IuxSemanticColors.of(context)` |
| `MediaQuery` for a preference | `IuxAccessibility.of(context)` |
| a hardcoded `Duration` | `IuxMotionPolicy.resolve(...)` |
| `HapticFeedback` directly | `IuxFeedbackScope.of(context).emit(...)` |
| `SemanticsService.announce` | `IuxSemantics.liveRegion`, or the feedback engine |
| a bare `Semantics` widget | the `IuxSemantics` helpers |
| its own minimum size | `IuxTapTarget` |
| a hardcoded spacing number | `IuxGap`, `IuxInsets` |

`packages/iux_flutter/test/components/component_standard_test.dart` enforces
the mechanical half of this table. A checklist nobody runs is a wish; a test is
a rule.

## 3. State is owned by the parent

A component never decides that an operation succeeded, failed, or finished. It
cannot know, and a component that guesses will eventually report a success that
did not happen.

```dart
// Wrong: the component owns the outcome.
IuxButton(onPressed: () async { await save(); showSuccess(); })

// Right: the parent owns it and tells the component what to render.
IuxButton(
  action: descriptor,          // idle | inProgress | succeeded | failed
  onPressed: controller.save,
)
```

This is why the feedback engine has no `onSuccess` hook anywhere.

## 4. Intent, not appearance

A component takes an intent and resolves the appearance itself.

```dart
IuxButton(intent: IuxActionIntent.destructive)   // yes
IuxButton(color: Colors.red, elevation: 4)       // no
```

An API that accepts a colour has already lost the contrast guarantee: the theme
can no longer be held responsible for something a call site overrode.

## 5. Accessibility is part of "done"

A component is not finished until all of the following hold. These are not
stretch goals.

- **Name.** Every interactive element has an accessible name. An icon-only
  control without one is unusable with a screen reader.
- **Role and state.** Expressed through `IuxSemantics`, including disabled and
  selected. Disabled is announced, not merely greyed.
- **Target.** At least `IuxAccessibility.minimumTouchTarget`, via
  `IuxTapTarget`. Adjacent targets keep `kIuxMinimumTargetSpacing` between
  them.
- **Focus.** Visible, distinct from selection, and it does not move the layout
  when it appears.
- **Keyboard.** Reachable and activatable without a pointer.
- **Text scaling.** Works at 200%. No fixed heights, no clipped labels.
- **Colour.** Never the only carrier of meaning.
- **Reduced motion.** Every animation goes through `IuxMotionPolicy`.
- **Long text.** Wraps rather than clips.

## 6. States a component must handle

| State | Requirement |
| --- | --- |
| default | the resting appearance |
| focused | visible indicator, distinct from selected |
| pressed | perceptible without relying on hover |
| disabled | announced, and readable — IUX holds 3:1 here |
| loading | progress semantics; a static alternative when motion is off |
| error | a message, never a colour alone |
| empty | explained, with a way forward when one exists |

A component that cannot express one of these states should say so in its
documentation rather than leave the caller to discover it.

## 7. API conventions

- Constructor parameters are named; positional parameters are reserved for the
  single obvious child.
- `required` for anything without a safe default. A default that is wrong half
  the time is worse than a compiler error.
- No ambiguous booleans. `enabled: false` is fine; `mode: true` is not — use an
  enum.
- No parameter exists without a demonstrated need. Twenty optional parameters
  is a signal the component is doing two jobs.
- Callbacks are named for what happened (`onPressed`), not for what should
  follow (`onSave`).
- Nullable callback means "not available"; it must also produce disabled
  semantics, so the two cannot drift.

## 8. Composition over configuration

A component that needs a new visual mode is usually two components, or a
pattern. Adding a fourteenth enum value to keep one class is how a component
becomes unmaintainable.

## 9. Motion

Every animation declares a role:

```dart
final motion = IuxMotionPolicy.resolve(context, role: IuxMotionRole.stateChange);
```

Decorative motion is the default assumption for anything that cannot be
justified. Removing an animation must never remove the information it carried.

## 10. Feedback

A component emits feedback only when the parent supplies the event. It never
vibrates directly, never announces directly, and never shows a snack bar
itself.

## 11. Documentation

Every public component documents: purpose, when to use, when **not** to use,
accessibility constraints, states, parameters, examples, evidence, and known
limitations.

"When not to use" is the section most often omitted and the most useful: it is
what stops a component being applied to a problem it does not solve.

## 12. Testing

| Level | Covers |
| --- | --- |
| unit | pure logic, resolution, value semantics |
| widget | states, interactions, callbacks |
| accessibility | semantics, focus, target size, text scaling |
| contract | the rules in §2, enforced mechanically |

A behaviour without a test is a behaviour that will regress. Tests assert
behaviour, not pixels.

## 13. Catalog

Every component appears in the catalog showing its states, its variants, and
what it refuses to do. The catalog explains the component; it does not
advertise it.

## 14. Definition of done

- [ ] answers a real user need
- [ ] uses the layers in §2 and nothing below them
- [ ] all applicable states in §6
- [ ] every item in §5
- [ ] documented per §11, including limitations
- [ ] tested per §12
- [ ] present in the catalog
- [ ] `dart format`, `flutter analyze`, `flutter test` all clean
- [ ] evidence registry updated for any UX decision
- [ ] ADR written for any architectural decision

## Limits of this document

- The mechanical rules are enforced; the judgement ones are not. No test can
  tell whether a label is understandable.
- TalkBack, Voice Access and keyboard behaviour need a device. Widget tests
  approximate them and no more.
- The state list in §6 is not exhaustive for every component type.

## Evidence level

Context dependent. This is IUX governance, not an external standard, though
the accessibility requirements in §5 restate obligations that are.

## Sources

- WCAG 2.2 — SC 1.4.1, 1.4.3, 1.4.4, 1.4.11, 2.1.1, 2.4.7, 2.5.8, 4.1.2.
- Android accessibility guidance.
- `PROJECT_PROMPT.md` §19–23, §42–45, §55–57.
