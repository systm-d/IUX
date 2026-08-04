# Destructive action

## Purpose

Run an action worth being careful about, and ask the user first — only when
asking is actually the kinder answer.

```dart
// Reversible. It runs on the first tap, and the page offers the way back.
final controller = IuxDestructiveActionController(
  action: IuxActionDescriptor.destructive(
    semantics: IuxActionSemantics(label: l10n.archiveMarchInvoice),
    reversibility: IuxActionReversibility.reversible,
    confirmation: IuxConfirmationPolicy.none,
  ),
  onConfirmed: model.archive,
);

IuxDestructiveAction(label: l10n.archive, controller: controller);
```

## Undo beats confirmation. Start there

This is the whole argument of the pattern, so it comes before the API.

A confirmation charges **every** user an extra step to prevent a mistake
**most** of them will never make. An undo charges nothing until somebody
actually errs. And an undo helps a user a confirmation cannot: the person who
meant to press the button and was wrong about what it did. They confirm the
dialog too — they were sure, they were simply mistaken — and only the undo
gives them anything back.

There is a second cost, and it is the one that compounds. Confirming every
delete teaches people that dialogs are noise between them and their work. They
learn to dismiss without reading, and the habit does not distinguish the
trivial confirmation from the one that mattered. **Confirming everything is
indistinguishable, in effect, from confirming nothing.**

So the action model already refuses to make destruction imply confirmation:

```dart
// Destructive and reversible. Nothing here says "ask first".
IuxActionDescriptor.destructive(
  semantics: IuxActionSemantics(label: l10n.archiveThisInvoice),
  reversibility: IuxActionReversibility.reversible,
  confirmation: IuxConfirmationPolicy.none,
)
```

And this pattern refuses the contradiction outright: an action declared
`IuxActionReversibility.reversible` that also asks to be confirmed fails on an
assertion, with the reason in the message. If going back is genuinely slow,
partial or manual, that is not `reversible` — the model has
`IuxActionReversibility.difficultToReverse` for exactly that, and it confirms
without complaint.

### Offering the undo

The undo belongs to the parent, and the pattern deliberately does not model it.
The undo *window* — how long the application holds a deleted row before it
commits — is a decision about data, not about pixels, and no widget can know
it. Tying it to how long something happens to be painted is how "Undo" becomes
a promise the interface breaks for the slowest users first.

Use a transient message with an action. A message carrying an action does not
expire, so the offer is not a race:

```dart
IuxTransientLayer(
  message: model.lastArchived == null
      ? null
      : IuxTransientMessage(
          text: l10n.invoiceArchived,
          dismissLabel: l10n.dismissArchivedNotice,
          action: IuxTransientAction(
            label: l10n.undo,
            semanticLabel: l10n.undoArchivingTheMarchInvoice,
            onActivate: model.restore,
          ),
        ),
  onDismissed: model.clearArchivedNotice,
  child: page,
)
```

## Use when

- An action deletes, revokes, discards or overwrites, **and** the way back is
  slow, partial or absent.
- An action is irreversible without being destructive — sending a message,
  submitting a bid, publishing. `IuxActionIntent.destructive` is not required;
  `IuxActionDescriptor.hasSeriousConsequence` is the property that matters.
- A destructive action that needs no confirmation at all. The call site is the
  same, which is the point: turning the confirmation on or off is one word in
  the descriptor.

## Do not use when

- **The action can be undone.** Offer the undo. The pattern will refuse the
  combination anyway.
- **The consequence cannot be stated.** If you cannot write the sentence that
  says what the user loses, there is nothing to confirm — a confirmation whose
  message is "Are you sure?" asks the user to weigh an outcome nobody described,
  so the only thing they can answer is whether they trust their memory of what
  they just tapped.
- **The action is a step in a flow the user is already committed to.** The last
  page of a checkout does not need a confirmation on top of itself.
- **The control has no label.** There is no icon-only form of this widget, and
  that is not an oversight: an unlabelled control is the easiest one to hit by
  accident, which is the failure a destructive action can least afford.

## API

### `IuxDestructiveActionController`

Owned, created and disposed by the parent, like a `TextEditingController`.

| Member | Meaning |
| --- | --- |
| `action` | the descriptor to render; hand it to the trigger |
| `prompt` | the wording, or null when the action asks for none |
| `isConfirming` | whether the user has been asked and has not answered |
| `dialog` | the `IuxDialog` to hand to `IuxModalLayer`, or null |
| `activate()` | attempts an activation and says what became of it |
| `confirm()` | records "go ahead" and runs the action |
| `cancel()` | records "leave it alone"; nothing runs |
| `update(...)` | replaces the action and the wording together |

`activate()` asks `IuxActionPolicy` with `confirmed: false`. That single
argument is the difference between this pattern and a plain button: `IuxButton`
and `IuxAsyncActionController` both evaluate with `confirmed: true`, because
obtaining the answer is a pattern's job — this pattern's.

### `IuxConfirmationPrompt`

Four required, caller-localised strings: `title`, `consequence`, `confirmLabel`,
`keepLabel`. None has a default, because the framework composes no user-facing
text and would otherwise ship one language inside another.

`consequence` is the one to labour over. Write what the action costs — "The
files leave this device and the shared folder" — not what the user already
suspects — "This cannot be undone".

### `IuxDestructiveAction`

The trigger. A thin widget over `IuxButton`, and the thin part is the point: it
routes activation through the controller instead of calling the caller's
callback directly.

| Parameter | Meaning |
| --- | --- |
| `label` | the visible text; required and non-empty |
| `controller` | the parent-owned confirmation state |
| `icon`, `variant`, `expand`, `focusNode`, `busyHint` | as on `IuxButton` |

There is **no `autofocus`**. A control that deletes something and takes focus on
arrival is one Enter press away from running, pressed by a keyboard user who was
still reading the page.

## Where the dialog goes

The pattern puts nothing on screen. The parent places the dialog, at page level,
where dialogs go:

```dart
ListenableBuilder(
  listenable: controller,
  builder: (BuildContext context, Widget? child) => IuxModalLayer(
    dialog: controller.dialog,
    child: IuxPage(child: content),
  ),
)
```

A pattern that pushed a route would be deciding navigation, which belongs to the
application. A pattern that opened its own overlay from wherever the button
happened to sit would be deciding layering, which is how two modals end up open
at once with the way out of neither visible.

## What it refuses to present

`IuxConfirmationPolicy` had four values, and this pattern refused two of them on
an assertion rather than approximating them. **IUX-039 removed those two from
the type**, on this section's own reasoning plus one measurement it did not
have: this pattern's refusal was the *only* reading either policy ever received
anywhere, and every other control — including a plain `IuxButton` — ran
`onActivate` on the first ordinary tap whatever the policy said. A member of a
sealed safety type that nothing honours is a precaution the caller states and
the user never receives.

The reasoning is kept here rather than deleted, because it is the argument a
future pattern that owns more of the screen will have to answer before re-adding
either member.

- **`IuxConfirmByHold`.** Deliberate by construction and it avoids a second
  screen, but it is invisible to a screen reader unless it is announced, and it
  is hard to perform with tremor or limited dexterity. It may therefore never be
  the only way to reach an action — and a single control has no way to offer a
  second route to itself. A pattern that owns more of the screen (a row with an
  overflow menu, a detail page) can present hold *alongside* something else;
  this one cannot.

  There is a second, smaller reason: a hold threshold is a duration, and IUX has
  no token for one. `IuxMotionPolicy` resolves *motion* durations, and a gesture
  threshold is not motion. Inventing a number here would put an untunable,
  untokenised 800 ms in front of the users least able to beat it.

- **`IuxConfirmByDoubleActivation`.** Arming a control in place needs either a
  disarm timeout the user has to beat — the same race — or a visible way back,
  which one button has nowhere to put. Left armed with no way back, it is a
  destructive control sitting in a state the user did not choose.

Both used to be modelled in `IuxActionModel` on the grounds that they are real
techniques worth naming. Naming a technique nothing performs turned out to cost
more than it bought: see `docs/components/action-model.md`.

## Behaviour

| The user does | What happens |
| --- | --- |
| activates, no confirmation policy | `onConfirmed` runs immediately |
| activates, confirmation policy | the dialog opens; nothing runs |
| activates while unavailable | nothing; `blockedReason` is `unavailable` |
| activates while running | nothing; `blockedReason` is `alreadyInProgress` |
| activates twice before answering | one question, not two |
| confirms | the question closes, then `onConfirmed` runs, exactly once |
| dismisses, taps the scrim, or presses Escape | the question closes; nothing runs |

`confirm()` closes the question *before* running the action, so the parent's
callback never observes a decision that is still open and focus is already on
its way back to whatever held it.

## Accessibility

| Guarantee | Where it comes from |
| --- | --- |
| The trigger is named | `IuxActionSemantics.label`, required non-empty by the model |
| The announced name may be fuller than the visible one | `label` and `semantics.label` are separate |
| Disabled is announced, with a reason | `IuxButton`, from `unavailabilityReason` |
| Target size, focus ring, keyboard activation | `IuxButton` → `IuxTapTarget`, `IuxFocusable` |
| The confirmation announces itself as a route | `IuxDialog` → `IuxSemantics.route` |
| Focus is trapped in the confirmation and restored on close | `IuxDialog`, plus a node the controller owns — see below |
| **Focus never lands on the confirming choice** | `IuxDialog` focuses its panel |
| The page behind is removed from the semantic tree | `IuxDialog` → `BlockSemantics` |
| Escape, the scrim and the labelled way out are one outcome | `IuxDialog.onDismissed`, wired to `cancel()` |
| The consequence wraps at 200% text and scrolls | `IuxDialog` |

The confirming choice carries the *action's* semantics, not the word on the
button: a screen-reader user who swipes onto it hears "Delete the three selected
files", not "Delete".

### The trigger's focus node lives on the controller

`IuxDestructiveAction.focusNode` is optional, and when it is omitted the
controller lends the trigger one of its own rather than the widget creating it.
That is not tidiness. **The widget does not survive its own confirmation.**
`IuxModalLayer` adds a `Stack` when the dialog opens and removes it when the
dialog closes, so the page changes depth in the element tree twice and the
trigger is rebuilt from scratch both times — taking a widget-owned focus node
down with it while `IuxDialog` was still holding that node as the place to send
focus back to. `IuxFocus.restore` then found a node with no context and did
nothing.

Measured on a page of four controls, with no `focusNode` supplied: cancelling
the confirmation left focus on the page's root scope and cost **three Tab
presses** to get back to the trigger; afterwards, **zero**. Flutter's own dialog
costs zero, which is the bar WCAG 2.2 SC 2.4.3 sets
(IUX-DESTRUCTIVE-FOCUS-001).

The controller is the parent's and outlives the rebuild, so the node does too;
it is created on first use, so a caller who owns the node pays nothing. One
consequence worth stating: a single controller drives a single trigger. Two
`IuxDestructiveAction`s sharing one controller would share one node, and they
already share one dialog, so the arrangement was never meaningful.

**Still needs a device.** TalkBack reading order, Voice Access labelling and
physical keyboard traversal are approximated by widget tests and no more.

## Themes and tokens

Nothing in this pattern draws. Every colour, radius, spacing and duration is
resolved by `IuxButton` and `IuxDialog` from the theme, so light, dark, high
contrast, reduced motion and reduced visual stimulation are inherited rather
than re-implemented. The pattern names no colour, and a destructive action is
never signalled by colour alone — the wording carries it.

## Anti-patterns

```dart
// No. IuxButton evaluates with confirmed: true, so the descriptor asks to be
// confirmed, the code compiles, and nobody is ever asked.
IuxButton(label: 'Delete', action: confirmingAction, onActivate: model.delete)
```

```dart
// No. A confirmation on an action the user can undo costs everyone a step and
// protects nobody. Refused on an assertion.
IuxActionDescriptor.destructive(
  semantics: IuxActionSemantics(label: 'Archive'),
  reversibility: IuxActionReversibility.reversible,
  confirmation: IuxConfirmBeforeExecution(),
)
```

```dart
// No. "Are you sure?" describes nothing. Say what is lost.
IuxConfirmationPrompt(
  title: 'Warning',
  consequence: 'Are you sure?',
  confirmLabel: 'OK',
  keepLabel: 'Cancel',
)
```

```dart
// No. The action's own callback bypasses the controller, so the confirmation
// is decoration.
IuxDestructiveAction(label: 'Delete', controller: controller);
onSomethingElse: model.delete;
```

## States

| State | Source |
| --- | --- |
| default, focused, pressed, disabled | `IuxButton`, from the descriptor |
| in progress | `IuxActionDescriptor.operation`, still the parent's |
| asking | `isConfirming`, set by `activate()` |
| answered | `confirm()` or `cancel()`, both the user's |

There is **no error state**. Whether the deletion failed is the parent's to
report: drive an `IuxAsyncActionController` from `onConfirmed` and feed its
`descriptor` back through `update(...)`, or show an `IuxAlert` beside the
content.

## Limits

- **The parent must place the dialog.** With no `IuxModalLayer` reading
  `controller.dialog`, the confirmation is computed and never shown, and the
  trigger looks inert. Nothing detects this, because nothing can from where the
  button sits. It is the price of not owning layering, and it is stated rather
  than hidden.
- **Hold and double activation are not presented.** See above.
- **No undo is modelled.** The pattern refuses to let a confirmation stand in
  for an undo, and documents the recipe, but does not implement the offer — the
  undo window is application data policy.
- **No feedback is emitted.** A component emits feedback only when the parent
  supplies the event; emit from `onConfirmed` through `IuxFeedbackScope`.
- **One action per controller.** A bulk toolbar with three destructive actions
  holds three controllers, and only one confirmation can be open at a time
  because `IuxModalLayer` has one slot.
- **The assertions are debug-only.** A release build with a reversible,
  confirming action will confirm it. The rules are teaching tools, not runtime
  guards.
- **Not in the catalog yet.** `apps/catalog` is outside this mission's scope;
  IUX-008.8 and IUX-032 pick it up.

## Evidence level

| Rule | Level | Source |
| --- | --- | --- |
| A confirmation states its consequence rather than asking a question | Strong guidance | NN/g, confirmation dialogs; WCAG 2.2 SC 3.3.4 |
| Undo is preferred to confirmation for reversible actions | Strong guidance | NN/g, error prevention and undo; ISO 9241-110 controllability |
| Destruction does not imply confirmation | Strong guidance | NN/g; `docs/components/dialog.md` |
| Focus never lands on the confirming choice | Strong guidance | WAI-ARIA APG, dialog pattern, "least destructive action" |
| Irreversible actions get an explicit confirmation step | Standard | WCAG 2.2 SC 3.3.4 (Error Prevention) |
| Every control is named and its state announced | Standard | WCAG 2.2 SC 4.1.2 |
| Hold-to-confirm must never be the only route | Standard | WCAG 2.2 SC 2.5.1, 2.5.7 |
| Refusing reversible + confirmation on an assertion | Brand choice | IUX governance, PROJECT_PROMPT.md §18, §22 |

## Sources

- WCAG 2.2 — SC 2.1.1, 2.4.3, 2.5.1, 3.3.4, 4.1.2.
- WAI-ARIA Authoring Practices, dialog (modal) pattern.
- Nielsen Norman Group, on confirmation dialogs, undo and error prevention.
- `PROJECT_PROMPT.md` §18 (error prevention), §22 (hard to misuse), §52
  (safety), §57 (patterns).
- `docs/components/component-standard.md` §2, §3, §5, §7, §11.
- `docs/components/dialog.md`, `docs/components/transient-feedback.md`,
  `docs/components/action-model.md`.
