# Button variants and icon actions

Extends `IuxButton` with a glyph, and adds `IuxIconButton` for an action that
has no room for a label.

Variant resolution itself lives in the button theme — see
`docs/buttons/theme.md`. This document is about what the widgets do with it.

## Variant is emphasis, intent is meaning

| Variant | Weight | Labelled | Icon-only | Intents |
| --- | --- | --- | --- | --- |
| `filled` | most prominent | yes | yes | primary, destructive |
| `outlined` | outline on the page | yes | yes | all |
| `tonal` | soft container | yes | yes | all but destructive |
| `text` | label only, no container | yes | yes | all |
| `icon` | square target, no label | **no** | default | all |

The same action can be prominent on one screen and discreet on another without
changing what it does. That is why emphasis is a separate axis from
`IuxActionDescriptor.intent`, and why nothing about a variant changes whether
the action runs, how a repeat is handled, or what a screen reader hears. Every
variant activates identically, and there is a test that says so.

`IuxButton` refuses `IuxButtonVariant.icon`. It describes a control with no
label, so it cannot describe a button that has one. The assertion names
`IuxIconButton` rather than leaving the caller to guess.

### Two combinations are refused

The last column is not decoration. Two cells of the variant × intent grid are
assertions, not appearances:

- **`tonal` + `destructive`.** Tonal carries intent through its border rather
  than its fill, which is not enough separation for an action that destroys
  data.
- **`filled` + `secondary` or `tertiary`.** The semantic layer models both
  intents unfilled: their background *is* the page surface and their accent
  lives in the foreground. So `filled` painted the page over the page and
  produced a control with no container at all — measured byte-identical to
  `text`, which is a button a user cannot identify as one (WCAG 2.2 SC 1.4.11).
  Until IUX-039 the request was accepted and discarded in silence, which is
  worse than a refusal because the call site reads as if it worked.

Inventing a fill for those two intents was refused rather than deferred: one
filled action per group is what makes the primary readable as the primary, and
a second fill takes that away from every screen at once. If an action really is
the dominant one, say so with `IuxActionIntent.primary`.

`test/themes/button_distinguishability_test.dart` sweeps the whole legal grid
on all four theme profiles and requires every cell to differ from every other.
Two variants that resolve to one appearance mean one of them is not a variant.

## IuxIconButton

```dart
IuxIconButton(
  icon: Icons.close,
  action: const IuxActionDescriptor(
    semantics: IuxActionSemantics(label: 'Close'),
    role: IuxActionRole.dismiss,
  ),
  onActivate: controller.close,
)
```

### Use when

The label genuinely does not fit and the glyph is already understood —
closing, going back, searching. A row of controls in an app bar is the usual
case.

### Do not use when

- **The glyph has to be guessed.** Icons are the least discoverable form of a
  control, and unlike a label there is nothing to read. Reach for `IuxButton`
  first and drop the label only when space forces it.
- **The action is destructive and unconfirmed.** An unlabelled control is the
  easiest one to hit by accident, and the one hardest to recognise afterwards.
- **You would need a tooltip to make it usable.** That is the same problem
  stated differently.

### There is no `label` parameter

The accessible name comes from `IuxActionSemantics.label`, which the action
model already requires to be non-empty. There is no way to construct an
`IuxIconButton` without a name — not a validation, an absence of the code path.

This is the single most important property of the widget. An icon-only control
without a name is one a screen-reader user cannot identify, activate
deliberately, or describe to anyone else.

The glyph itself is excluded from the semantic tree. Two nodes for one control
makes a screen-reader user swipe twice to pass a single button, and the second
stop says nothing useful.

### Small to look at, large to hit

The glyph stays around 20 logical pixels; the region that responds to it meets
the resolved touch target floor — 48, or 56 under a comfortable preference.
They are two measurements, resolved separately:

- enlarging the glyph to fill the target would make every icon action shout;
- shrinking the target to the glyph would make it hard to hit.

The glyph does scale with the user's text scale. For an icon-only button the
glyph is the entire content, and leaving it at 20 for someone who asked for
200% keeps unreadable exactly the thing they cannot read. The container grows
with it, so the target never shrinks.

## An icon beside a label

```dart
IuxButton(
  label: l10n.add,
  icon: Icons.add,
  action: const IuxActionDescriptor.primary(
    semantics: IuxActionSemantics(label: 'Add'),
  ),
  onActivate: controller.add,
)
```

- **`IconData`, not `Widget`.** The button then sizes and colours the glyph
  from the same tokens as the label, so an icon cannot arrive carrying a
  colour that fails against the container it sits on. A widget slot hands that
  guarantee back to the call site — the same reason there is no `color`
  parameter.
- **Redundant by design.** The glyph repeats what the label says and is left
  out of the announcement. An icon carrying information the label does not is
  information a screen-reader user never receives.
- **Leading only.** A glyph after the label reads as a disclosure indicator
  rather than as part of the name, and a screen where some buttons lead with
  their icon and others trail it costs the user a scan on every row.
- **Reading order, not screen order.** Right-to-left puts the glyph on the
  right without the widget being told which language it is in.
- The label still wraps once the glyph has taken its share of the width.
  Adding an icon must not turn a wrapping button into an overflowing one.

## Size

A button takes the space it needs and no more.

`expand` claims the width, and only the width. Height always follows the
content, so a button inside a `Center` or an `Expanded` stays the size of a
button. Where no width is on offer — an unbounded row — `expand: true` fails
loudly rather than quietly ignoring what the caller asked for.

**To stack full-width buttons, use `IuxTargetSpacing`.** Its vertical axis lays
out in a column, which has a width to give, and it keeps the target-separation
floor between the two — which a `Column` and an `IuxGap` do not:

```dart
IuxTargetSpacing(
  children: <Widget>[
    IuxButton(label: 'Save', expand: true, /* … */),
    IuxButton(label: 'Discard', expand: true, /* … */),
  ],
)
```

This was `IUX-EXPAND-CRASH-001`: the primitive was a `Wrap` on both axes, a
vertical `Wrap` offers its children no width, and the commonest layout anyone
writes was the one that threw. Measured on a 320-wide surface at 100, 150, 200
and 300% text, the pair now lays out with both buttons at the full 320 and
16 px between the hit areas. See
[layout](../layout/overview.md#spacing-between-targets) for why a `Column` and
an `IuxGap` is not the same thing — with bare targets it measures 4 px, half
the floor.

Where there is genuinely no width — a `Row` without an `Expanded`, a
horizontally scrolling view — `expand: true` still fails, and the message now
names the arrangement that works instead of only the constraint that was
invalid.

## API

| Parameter | Widget | Required | Note |
| --- | --- | --- | --- |
| `icon` | both | icon button only | `IconData`; leading on a labelled button |
| `label` | `IuxButton` | yes | must not be empty |
| `action` | both | yes | carries the accessible name |
| `onActivate` | both | yes | once per accepted gesture |
| `variant` | both | no | labelled: from the action. Icon: `icon` |
| `autofocus`, `focusNode` | both | no | focus handling |
| `expand` | `IuxButton` | no | width only |
| `busyHint` | both | no | announced while running; silent if omitted |

`IuxIconButton` defaults to `IuxButtonVariant.icon` rather than deriving one
from the action. Icon actions usually appear several to a row, and a row of
containers competes with the content it sits above.

A labelled button that names no variant derives one from the action, through
`IuxButtonResolver.defaultVariantFor` — intent says which containers exist,
importance picks a rung:

| | primary, destructive | secondary, tertiary |
| --- | --- | --- |
| `high` | `filled` | `outlined` |
| `medium` | `outlined` | `tonal` |
| `low` | `text` | `text` |

There was a single `IuxButtonTheme.variant` constant here until IUX-039, and it
was `filled` for every intent. Since a plain `IuxActionDescriptor` is secondary,
the most ordinary button in the package resolved to a fill equal to the page and
an outline of width zero. One value cannot be the right default for four
intents. Deriving a default is not the same failure as discarding a request: a
call site that names `variant:` always gets it, or an assertion saying why it
cannot have it.

## Anti-patterns

```dart
// Wrong: an icon nobody has to recognise, on the action that loses data.
IuxIconButton(icon: Icons.delete, action: destructive, onActivate: erase)

// Also wrong: a label, but an IuxButton will not present the confirmation the
// descriptor asks for. It evaluates the action with confirmed: true.
IuxButton(label: l10n.delete, action: destructive, onActivate: erase)

// Right: the pattern that asks.
IuxDestructiveAction(label: l10n.delete, controller: controller)
```

```dart
// Wrong: the glyph carries meaning the label does not.
IuxButton(label: 'Export', icon: Icons.lock)   // "…and it is encrypted"

// Right: say it where everyone can read it.
IuxButton(label: 'Export encrypted', icon: Icons.lock)
```

```dart
// Wrong: a labelled button asking for the icon variant.
IuxButton(label: 'Close', variant: IuxButtonVariant.icon)   // asserts
```

## Accessibility

- Every control is announced as a button, with its name and enabled state,
  whether or not it has visible text.
- A disabled control explains itself when the caller supplied
  `unavailabilityReason`.
- Enter and Space activate; a disabled control is skipped by focus traversal,
  and so is a running one — see Limits.
- The target meets the floor at every density and under a comfortable
  preference; the glyph does not have to grow to match it.
- The glyph scales with text.
- Verified on light, dark, high contrast light and high contrast dark.

**Verified in widget tests.** Still requires a device: TalkBack reading order
across a row of icon actions, Voice Access naming of an unlabelled control,
D-pad traversal.

## Limits

- **No tooltip.** A sighted user still has to recognise the glyph, and nothing
  here helps them. Contextual help is IUX-018; until then, an icon action whose
  meaning is not obvious should keep its label.
- **No loading or result state in the glyph.** Nothing replaces the icon while
  an operation runs, and the container does not recolour for a result either:
  `succeeded` and `failed` resolve to the same palette as `idle`. Measured in
  IUX-008.9 — see [button.md](button.md) *States*.
- **There is no elevation, and no switch that offers one.** `elevateFilled`
  and `IuxButtonTokens.elevation` were removed at IUX-038 (§19): the value was
  computed, travelled, and was read by nothing, so the theme could ask for a
  shadow and be ignored in silence. See [theme.md](../buttons/theme.md).
- **There is no `focused` token, and the ring is drawn outside.** The
  indicator comes from `IuxFocusable` drawing an `IuxFocusRing` around the
  container. `IuxButtonTokens.focused` existed until IUX-038 and no button ever
  set it; re-adding it would mean painting the ring in the container's own
  decoration, over the content it identifies.
- **`IuxButtonShape.full` rounds against the target floor**, not against the
  button's actual height, so a button enlarged by text scaling is rounded
  rather than fully stadium-shaped. Inherited from IUX-008.4.
- **Icon scaling is uncapped.** At very large text scales the glyph, and the
  target with it, become large. That is the same trade the label makes.

## Evidence level

Standard for the accessible name, the target floor, text scaling and contrast —
these restate WCAG and Android obligations.

Strong guidance for preferring a labelled button over an icon-only one, and for
the leading icon position.

Context dependent for the variant taxonomy and for the default variant of an
icon action.

## Sources

- WCAG 2.2 — SC 1.4.4 (resize text), SC 2.1.1 (keyboard), SC 2.4.7 (focus
  visible), SC 2.5.8 (target size), SC 4.1.2 (name, role, value).
- Android accessibility guidance — labelling controls without visible text.
- Nielsen Norman Group — icon usability; recognition over recall.
- `PROJECT_PROMPT.md` §16, §19–23.
- `docs/components/component-standard.md` §4, §5, §7.
