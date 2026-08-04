# IuxDialog

## Purpose

Stop the interface, state one thing, and wait for an answer the user alone can
give.

```dart
Scaffold(
  body: IuxModalLayer(
    dialog: state.confirmingDelete
        ? IuxDialog(
            title: 'Delete this invoice?',
            message: 'The invoice and its attachments are removed permanently.',
            dismissLabel: 'Keep it',
            onDismissed: controller.closeDialog,
            actions: <IuxDialogAction>[
              IuxDialogAction(
                label: 'Delete',
                action: const IuxActionDescriptor.destructive(
                  semantics: IuxActionSemantics(
                    label: 'Delete the March invoice',
                  ),
                ),
                onActivate: controller.confirmDelete,
              ),
            ],
          )
        : null,
    child: IuxPage(child: content),
  ),
)
```

## Use when

The user cannot continue without answering, and the answer changes what happens
next:

- a consequence that cannot be undone, or is expensive to undo;
- a conflict only the user can resolve — two versions of the same document;
- a permission that must be granted before the feature can run at all.

## Do not use when

This is the section that matters. A dialog is an interruption, and most things
put in one did not need to interrupt.

- **The page could show it inline.** A dialog costs the user their place. A
  message that belongs under the field it concerns should sit there, where it
  stays readable while they act on it. An alert that says "Saved" is a dialog
  that exists to be dismissed.
- **The action is trivially reversible.** Confirming every delete trains users
  to dismiss confirmations without reading them, which is how the one that
  mattered gets dismissed too. An undo is almost always kinder than a
  confirmation, and it costs the user nothing when they were right the first
  time. `IuxActionDescriptor.reversibility` is where that judgement is
  recorded.
- **It is a form.** A dialog that hosts fields is a page in a box, and a page
  in a box is what stops fitting at 200% text on a small screen — with a
  keyboard covering half of what is left. Use a page.
- **The user did not ask for it.** An interruption nobody caused is an
  interruption they will dismiss reflexively, and the next one after it.
- **There are more than two choices.** Three or more is a menu; a menu belongs
  on a page or in a sheet where it can be read at leisure. The constructor
  asserts this.

`IuxConfirmationPolicy` is modelled on the action, not here. A dialog is *one*
way to obtain a confirmation — hold-to-confirm, double activation and a typed
confirmation phrase are others, and nothing in the action model imposes this
one.

## It is a layer, not a route

`IuxDialog` never calls `Navigator`. The Component Standard forbids it (§2),
and the reason is not stylistic: the back stack, deep links and state
restoration belong to the application, and a component that quietly pushes onto
them cannot be reasoned about from the call site.

So the parent owns a flag, and the dialog exists exactly while the flag is
true. `IuxModalLayer` places it over the page. The consequences are worth
stating plainly:

| Consequence | What it means for you |
| --- | --- |
| The dialog cannot leak | There is no code path that pops the wrong route or forgets to pop at all. |
| The page stays mounted behind it | Scroll position, controllers and animations survive; nothing is rebuilt on close. |
| The system back button does not reach it | You wire it, in one place, with the same callback. |

```dart
PopScope(
  canPop: !state.confirmingDelete,
  onPopInvokedWithResult: (bool didPop, Object? result) {
    if (!didPop) controller.closeDialog();
  },
  child: IuxModalLayer(dialog: ..., child: ...),
)
```

This is deliberate rather than an oversight: `PopScope` is navigation, and
navigation is the parent's. Putting it two lines from the flag the parent
already owns is clearer than hiding it inside a component.

## Insets

The dialog applies its own `SafeArea`. Do not place it inside an `IuxPage`:
the page has already consumed the system insets and applied its padding, and
the dialog would be inset a second time from a notch that is only there once.
That is what `IuxPageInsets` exists to prevent, and a dialog is exactly where
it bites. `IuxModalLayer` makes the dialog a *sibling* of the page for this
reason.

## API

### `IuxDialog`

| Parameter | Required | Note |
| --- | --- | --- |
| `title` | yes | the question or the consequence; also the announced route name |
| `message` | yes | what actually happens, in plain language |
| `dismissLabel` | yes | the visible text of the way out |
| `onDismissed` | yes | scrim, Escape and the dismissal button all call this |
| `actions` | no | at most two choices beside the dismissal |
| `content` | no | detail under the message — a list of affected items, not a form |

### `IuxDialogAction`

| Parameter | Required | Note |
| --- | --- | --- |
| `label` | yes | the visible text |
| `action` | yes | an `IuxActionDescriptor`: intent, availability, semantics |
| `onActivate` | yes | called once; the dialog performs nothing itself |

### `IuxModalLayer`

| Parameter | Required | Note |
| --- | --- | --- |
| `child` | yes | the page the dialog interrupts |
| `dialog` | no | the dialog currently open, or null |

One slot, not a list: a second dialog cannot open over the first. Stacked
dialogs are the clearest way to lose a user, because the way out of the top one
is not the way out of the flow and neither is visible from the other.

There is no colour, radius, elevation, duration or `barrierDismissible`
parameter, and there will not be one. See "What it refuses to do" below.

## Behaviour

| Event | Result |
| --- | --- |
| opens | focus moves into the dialog; the route is announced; the page leaves the semantic tree |
| Escape | `onDismissed` |
| tap on the scrim | `onDismissed` |
| tap on the dismissal button | `onDismissed` |
| tap on the panel itself | nothing — a tap on the padding is not a dismissal |
| a choice is activated | that choice's `onActivate`; the dialog stays open |
| removed from the tree | focus returns to whatever held it when the dialog opened |

The dialog never closes itself. Closing is a state change, the parent owns the
state, and a dialog that closed itself would leave the parent's flag saying it
was still open.

## Accessibility

- **Focus enters, is trapped, and is restored.** Focus moves into the dialog on
  open, Tab and arrow traversal cycle inside it, and on close it returns to the
  node that held it when the dialog opened — not to wherever it drifted while
  the page was blocked. A user who is dropped back at the top of the page after
  every dialog cannot use the application.
- **Focus lands on the panel, not on a choice.** A dialog that focuses its
  confirming action turns a keypress already in flight into a confirmation
  nobody read. The way out is the first control reached by Tab.
- **The route is scoped and named.** `scopesRoute` and `namesRoute` carry the
  title, so assistive technology announces the change of context instead of
  leaving the user to discover it.
- **The page behind leaves the semantic tree.** A control that reads out but no
  longer responds is worse than one that is gone.
- **The scrim is not announced.** It dismisses, but the dismissal button says
  the same thing in words. An unlabelled tappable region reachable only by
  swiping is a control the user cannot verify before activating.
- **Everything scrolls, including the buttons.** Pinning the action row looks
  tidier until 200% text on a 320x480 screen, where the pinned row and the
  title together leave no room for the message. Content that cannot be reached
  is content the user cannot consent to.
- **The title is a heading**, so a screen-reader user can jump to it.
- **Long text wraps and is never truncated**, at every level of the panel.
- **Right-to-left** mirrors the button order: the way out stays first in
  reading order, which puts it on the right in RTL.

**Verified in widget tests.** Still requires manual checking on device:
TalkBack reading order and route announcement, Voice Access naming, D-pad
traversal, and the system back gesture with the `PopScope` above.

## Themes and motion

Every colour is resolved from `IuxSemanticColors`; the panel is
`IuxSurfaceRole.overlay`, bordered as well as elevated, because elevation
resolves to zero under a reduced visual stimulation preference and the edge of
a dialog is not something that may quietly disappear.

The scrim has no semantic role of its own in IUX. It is derived: whichever of
`surface.base` and `surface.inverse` the theme resolved *darker*, at 60%
opacity. Choosing by measured luminance rather than by brightness is what stops
the scrim brightening what it covers in dark conditions — a fixed "inverse
surface" would raise the background's luminance and push it towards the dialog
it is supposed to sit behind. A dedicated scrim role would be better, and
belongs to the semantic layer rather than to this component.

Motion is a fade and nothing else, declared as `IuxMotionRole.enter`. Travel
across the screen is a known vestibular trigger and this transition carries no
information that movement would add. A reduced preference shortens it; no
motion removes it, and the dialog is fully visible on the first frame rather
than flickering through a zero-length animation.

There is no exit animation. The parent removes the dialog from the tree and a
widget cannot outlive its own removal. Nothing is lost: the absence of the
dialog carries no information the fade would have explained.

## What it refuses to do

```dart
// Wrong: the dialog is asked to perform the deletion and close itself.
IuxDialogAction(onActivate: () async { await delete(); close(); })

// Right: the parent owns both.
IuxDialogAction(onActivate: controller.confirmDelete)
```

```dart
// Wrong: a dialog with no way out.
// Unrepresentable — onDismissed and dismissLabel are required.
```

```dart
// Wrong: a scrim that ignores taps.
// There is no barrierDismissible flag. A dialog whose scrim silently does
// nothing is indistinguishable from one that is broken, and the user has no
// way to tell which they are looking at.
```

```dart
// Wrong: confirming an action the user can simply undo.
IuxDialog(title: 'Archive this?', ...)   // archiving is reversible
// Right: archive it, and offer undo.
```

## States

| State | Source |
| --- | --- |
| open, closed | the parent's flag, via `IuxModalLayer.dialog` |
| a choice enabled or disabled | that choice's `IuxActionDescriptor.availability` |
| a choice in progress | `IuxActionDescriptor.operation` — still the parent's |
| focused | internal; the panel first, then the controls |

There is no loading state for the dialog as a whole and no error state. A
dialog that waits on a network call while blocking the interface is a dialog
the user cannot escape; report progress on the page, or on the choice itself
through its descriptor.

## Limits

- **The system back button does not dismiss it** unless the parent adds the
  `PopScope` above. This is the price of not calling `Navigator`, and it is
  stated rather than hidden.
- **No exit animation**, for the reason above.
- **One dialog at a time**, by construction. Sequential dialogs are the
  parent's business; nested ones are refused.
- **`content` is a widget slot**, so the contrast and target guarantees inside
  it are the caller's. Keep it to text and short lists.
- **The keyboard inset is not consumed.** The dialog holds no input, so there
  is nothing to lift above a keyboard; that is IUX-017's problem for sheets.
- **The scrim colour is derived, not declared.** See "Themes and motion".
- ~~Route scoping uses a bare `Semantics`~~ — **Fermé.** Le runtime expose désormais les helpers manquants (`IuxSemantics.selection`, `.radioGroup`, `.field`, `.route`, `.contentAction`, `.contentContainer`) et le composant les utilise. Voir `docs/accessibility/semantics.md`.
## Evidence level

| Rule | Level | Source |
| --- | --- | --- |
| Focus moves into the dialog and returns on close | Standard | WCAG 2.2 SC 2.4.3, 2.1.1, 2.1.2 |
| Focus is trapped while the dialog is open | Standard | WAI-ARIA Authoring Practices, dialog pattern |
| The route is scoped and named | Standard | Android accessibility guidance; Flutter route semantics |
| The content scrolls at 200% text | Standard | WCAG 2.2 SC 1.4.4, 1.4.10 |
| Escape, scrim and cancel are the same outcome | Strong guidance | WAI-ARIA APG; Material guidance |
| Focus lands on the panel, not on a choice | Strong guidance | WAI-ARIA APG, "least destructive action" |
| Confirmations should be rare and reversibility preferred | Strong guidance | Nielsen Norman Group, error prevention and undo |
| Scrim opacity of 60% | Brand choice | not a measured optimum |

## Sources

- WCAG 2.2 — SC 1.4.4, 1.4.10, 2.1.1, 2.1.2, 2.4.3, 2.4.7, 4.1.2.
- WAI-ARIA Authoring Practices, dialog (modal) pattern.
- Android accessibility guidance.
- Nielsen Norman Group, on confirmation dialogs and undo.
- `docs/components/component-standard.md` §2, §3, §5, §11.
