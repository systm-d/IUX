# Empty state

## Purpose

Say why a region holds nothing, and give the user the way out that actually
belongs to that situation.

```dart
IuxEmptyState(
  cause: IuxNoMatches(
    reset: IuxEmptyStateAction(
      label: l10n.showAll,
      action: IuxActionDescriptor(
        semantics: IuxActionSemantics(label: l10n.showAllInvoices),
      ),
      onActivate: controller.clearFilters,
    ),
  ),
  title: l10n.noInvoicesMatchTheseFilters,
  guidance: l10n.tryAWiderDateRange,
  arrival: IuxEmptyStateArrival.afterAChange,
)
```

## "Empty" is not one state

This is the whole argument of the pattern, so it comes before the API.

Four situations put nothing on a screen, and they leave the user in four
different places:

| Situation | The user's position | The way out |
| --- | --- | --- |
| `IuxNothingCreatedYet` | nothing has ever been here | make the first one |
| `IuxNoMatches` | it is here, and you excluded it | widen what you asked for |
| `IuxAccessRestricted` | it is here, and you may not see it | obtain access |
| `IuxNothingLeftToDo` | it was here and you dealt with it | none is owed |

A single `EmptyState(title, message)` makes those indistinguishable, and the
mistake that follows is always the same one: **an exit that belongs to a
different situation.** "Add your first invoice" under a filter that hid forty of
them. "Clear the filters" on a collection that has never held anything. "Retry"
on either. Each is a control that cannot work, offered to a user who has no
other information to go on — and who, having pressed it and seen nothing change,
now has less confidence in the screen than before.

So the situation carries its own exit, and the wrong pairing is not validated at
runtime. It does not compile:

```dart
// The reset is required. There is no way to build this situation without one.
IuxNoMatches(reset: …)

// There is no parameter to pass. The user is not short of anything.
const IuxNothingLeftToDo()
```

### Search and filter are one situation

A search that matched nothing and a filter that matched nothing put the user in
the same place: the content exists, and the criteria they set excluded it. The
exit is the same — widen or drop the criteria — and the only thing that
genuinely differs is the wording, which is the caller's in every IUX API. Two
types would have identical shapes, identical behaviour, and would make the
caller choose between them for no consequence.

### Why the reset is required and the others are optional

`IuxNoMatches` is the one situation where the emptiness is the user's own doing,
which is what makes it recoverable. The criteria were set through the interface,
so the interface can always unset them: unlike a create action, there is no case
where the callback cannot be written.

And the failure it prevents is the one users get stuck in most often — a filter
applied three screens ago, collapsed behind a control that is now scrolled off,
leaving a permanently empty list with no visible cause.

It does not have to *clear everything*. "Search all folders", "Include
archived", "Show the last year instead" are all resets: what matters is that
activating it returns content, so the user learns the criteria were the reason.
Do not point it at the control the user would have to find anyway — a reset
labelled "Open filters" hands them back the same search they are already lost
in.

`create` and `request` are optional because plenty of collections are filled by
somebody else. An employee's payslips appear when payroll files them; access is
sometimes only an administrator's to grant. Offering "Add one" there would be a
control that cannot work. The guidance carries the way out instead, and the
pattern requires it — see [The dead end](#the-dead-end).

## Use when

- a list, grid, table or search result has come back with nothing in it;
- a screen has no content yet and the user is entitled to know why;
- a permission was declined and the content behind it is now unreachable;
- the user has emptied a queue and the emptiness is the outcome they wanted.

## Do not use when

- **a load is still running.** "Nothing here" is a statement the interface
  cannot support until the answer has arrived. Show progress, and reach for this
  once `IuxLoadState` is ready with an empty value.
- **the request failed.** A collection that is empty because nothing came back
  is not empty, it failed. An empty state explains an answer; an error explains
  a breakdown and offers a retry. `IuxEmptyStateAction` refuses
  `IuxActionRole.retry` so the line cannot be blurred here by accident.
- **the feature is not built yet.** A region waiting on somebody's roadmap is
  not empty for a reason the user can act on, and this pattern would tell them
  it is.
- **one row is missing from a list that has others.** The list is not empty;
  that is a per-row state.

## API

### `IuxEmptyStateCause`

Sealed. Adding a fifth situation is a deliberate, reviewable change rather than
a value someone appends to an enum, and every member answers
`requiresWayForward` for itself instead of leaving a `switch` somewhere to be
forgotten.

| Member | Carries | `requiresWayForward` |
| --- | --- | --- |
| `IuxNothingCreatedYet({create})` | an optional create action | `true` |
| `IuxNoMatches({required reset})` | a required reset | `true` |
| `IuxAccessRestricted({request})` | an optional request action | `true` |
| `IuxNothingLeftToDo()` | nothing, structurally | `false` |

`IuxNothingLeftToDo` takes no action, and that is a limit rather than an
oversight. Every other situation leaves the user short of something, so the
pattern insists on a way forward; here they are not short of anything, and a
button would be the interface inventing work — "Review something else" sends a
user who has just finished back into a queue they emptied on purpose. Making
that unrepresentable is what stops it becoming the escape hatch for "I could not
think of an action", which would put the words "all done" under every genuinely
broken screen in an application.

Do not use it for a collection that has never held anything. "You are all caught
up" on a first run congratulates the user for work they have not done, and hides
the fact that this is where their work would go. That is `IuxNothingCreatedYet`.

`IuxAccessRestricted` presents the *consequence*, not the request. It asks the
operating system for nothing, does not know whether a permission was declined
once or permanently, and holds no rationale copy — what `onActivate` opens is
the parent's decision. Explaining why an application needs a permission before
asking is a flow of its own (IUX-031) and a different moment in the user's day.

### `IuxEmptyStateAction`

| Parameter | Meaning |
| --- | --- |
| `label` | the visible text, already localised |
| `action` | the same `IuxActionDescriptor` every IUX control takes |
| `onActivate` | called once per accepted activation |
| `busyHint` | announced after the name while the action runs |

It is **not** a second action model. Availability that follows the network, an
operation driven by an `IuxAsyncActionController`, and an announced name fuller
than the visible one all work here exactly as they do on an `IuxButton` —
"Show all" on screen, "Show all invoices" in a screen reader.

Three combinations are refused, each because it would otherwise be dropped in
silence:

- **a confirmation policy.** An empty state holds no dialog and nowhere to put a
  second question, so the policy would be ignored and the action would run on
  the first tap while the call site read as though the user were being asked.
  Nothing reached from an empty state should need confirming anyway — creating,
  widening and requesting are all additive. A control that genuinely destroys
  something belongs elsewhere on the screen, as an `IuxDestructiveAction`.
- **`IuxActionRole.retry`.** See "Do not use when", above.
- **an unavailable action with no `unavailabilityReason`.** Everywhere else in
  IUX that is bad; here it is the whole screen. The user faces a blank page and
  one greyed control, with no way to tell whether they did something wrong,
  whether the feature does not apply, or whether the application is broken — and
  a disabled control leaves the focus order on Android, so a screen-reader user
  cannot even reach it to wonder.

The constructor is not `const`. Two of its assertions read a field of `action`,
and Dart cannot evaluate a field access inside a `const` constructor's
assertion. Nothing is lost: `onActivate` is a closure or a tear-off, so no call
site could have written `const IuxEmptyStateAction(...)` in the first place.

### `IuxEmptyState`

| Parameter | Meaning |
| --- | --- |
| `cause` | why there is nothing here, and therefore what the exit is |
| `title` | what is missing, already localised. Required |
| `guidance` | what would put something here. Optional, except below |
| `arrival` | whether this is announced. Defaults to `afterAChange` |
| `illustration` | a decorative glyph. Carries nothing |

`title` names the thing rather than the state: "No invoices match these filters"
rather than "No results". The user knows the region is empty — they are looking
at it — so a title that only restates that spends their attention and returns
nothing.

The widget's constructor stays `const`, so the dead-end check runs at build
time. It reads a getter on `cause`, and a getter call is not a constant
expression; this is the same division `IuxDestructiveActionController` makes.

## The dead end

An empty state with no way out is a screen that tells the user they are stuck
and declines to say what would help. It is the single most common failure of the
pattern, and it is the one assertion that cannot be replaced by a type: a
situation that owes a way forward must offer **either** an action **or**
`guidance`.

```dart
// Refused: nothing has ever been here, and nothing says what would change that.
IuxEmptyState(cause: IuxNothingCreatedYet(), title: l10n.noProjectsYet)

// Accepted: the sentence is the way out. It is simply made of words.
IuxEmptyState(
  cause: const IuxNothingCreatedYet(),
  title: l10n.noPayslipsYet,
  guidance: l10n.payslipsAppearOncePayrollFilesThem,
)
```

Guidance that works answers two questions: *what* makes something appear here,
and *who* makes it happen. "Your payslips appear here once payroll files them"
answers both. "No data available" answers neither.

`IuxNothingLeftToDo` is exempt, because the user is not short of anything.

## Arrival, and the silence problem

**This is the dimension a screen-reader user notices most, and the one
frameworks leave out.** A list that empties under a filter is silent: the rows
are gone, the explanation is on screen, and nothing tells the person who cannot
see it that anything happened. They are left holding a screen they have no
reason to re-read.

The pattern cannot work this out for itself. A widget being built for the first
time looks identical whether it arrived with the screen or replaced forty rows a
moment ago; only the parent knows which.

| Value | Meaning | Effect |
| --- | --- | --- |
| `afterAChange` | the content emptied while the user was looking | live region |
| `withTheScreen` | the screen already had nothing in it on arrival | none |

`afterAChange` is the default because the asymmetry is not symmetric. Used there
by mistake, a screen that opened empty is announced once more than it needed to
be — noise. Used the other way by mistake, a list that emptied says nothing at
all, and silence is indistinguishable from an application that has hung.

Say `withTheScreen` only when it is true. It is a claim about where the user came
from, not a way of quietening a screen.

Arrival is orthogonal to the cause on purpose: any situation can arrive either
way — a collection is empty on first run *and* empty again after its last item
is deleted — so folding this into the cause would double the number of
situations and still get the pairing wrong.

## Behaviour

- The parent decides whether this widget is on screen. Nothing here inspects a
  collection, and nothing hides itself on activation: whether the collection is
  still empty afterwards is something only the parent can know, and a pattern
  that hid itself would hide a state that is still true.
- The exit is an `IuxButton`, so availability, repeat handling and the running
  state come from `IuxActionDescriptor` exactly as they do everywhere else.
- Nothing is animated. The block appearing is not a change the user needs help
  following, and an animation would delay the announcement to save nothing.
- No feedback is emitted. A component emits feedback only when the parent
  supplies the event.
- No surface and no border are drawn. An empty region is already surrounded by
  the space its content would have occupied, and a card around it would suggest
  there is an object here when the point is that there is not.

## States

| State | Source |
| --- | --- |
| default | the cause, the title and the guidance |
| focused, pressed | `IuxButton`, on the exit |
| disabled | `IuxActionDescriptor.availability`, and it must say why |
| in progress | `IuxActionDescriptor.operation`, still the parent's |
| announced | `IuxEmptyStateArrival.afterAChange` |

There is **no loading state and no error state.** Those are separate patterns,
and the boundary is stated in "Do not use when" rather than blurred by a fourth
enum value here.

## Reaching the way out

**A way out the user cannot reach is not a way out.** The exit is last, under the
sentences that explain it, so it is the first thing to leave a short viewport.
Measured on a 320×640 screen, with a glyph, a title and a one-line guidance, in a
`Center` with nothing else on the page:

| Text scale | Exit at | Hit-testable | Activations | Overflow |
| --- | --- | --- | --- | --- |
| 100% | y 406–462 | 1 | 1 | none |
| 150% | y 529–585 | 1 | 1 | none |
| 200% | y 712–776 | **0** | **0** | 136 px |
| 300% | y 1512–1656 | **0** | **0** | 1016 px |

That is WCAG 2.2 SC 1.4.4 and SC 1.4.10 failing on the only control on the
screen, and the mitigation — put it inside something scrollable — was documented
and was not the default. Nothing made it the default, which is the defect.

So the block scrolls itself **when, and only when, it is given a bounded
height**. That is the whole rule, and it is read off the constraints rather than
asked for in a parameter:

- Every vertical scroll view in Flutter hands its children an unbounded height —
  that is what makes it a scroll view. A block embedded in a list, a page or a
  sheet that already scrolls therefore sees an unbounded height and adds nothing,
  so the rule that it must not introduce a second scroll view holds structurally
  rather than by convention. There is no flag to forget and none to get wrong.
- A block given a bounded height has been told the size of the box it may occupy
  by something that is not going to scroll it. That is where the difference is a
  reachable control or a dead screen.

```dart
// Scrolls itself: nothing above is going to.
Center(child: IuxEmptyState(...))

// Adds nothing: the page is the scroll view, and one is the right number.
IuxPage(child: IuxEmptyState(...))
ListView(children: <Widget>[IuxEmptyState(...)])
CustomScrollView(slivers: <Widget>[SliverToBoxAdapter(child: IuxEmptyState(...))])
```

**Nothing moves where nothing was wrong.** A `SingleChildScrollView` sizes itself
to its child up to the height it was given, so a block that fits keeps its size
and its position — it is still centred by whatever centres it — and reports no
scroll extent, so it accepts no drag and the gesture goes to whatever is above
it.

**It does not make a 900-pixel block fit in 640 pixels.** Reaching the exit at
200% still means scrolling to it; SC 1.4.10 asks for one direction of scrolling,
not for none. What changed is that scrolling to it is possible: at every scale
above, the exit is now hit-testable after one drag and takes its tap.

## Accessibility

- **The message is one stop.** The title and the guidance are merged into a
  single semantic node, so a screen-reader user hears the whole explanation as
  one utterance rather than landing on two fragments.
- **The exit stays a control of its own.** Merged into the message it would be
  announced and unreachable, which is the trap `IuxSemantics.contentAction`
  documents. The block uses `IuxSemantics.contentContainer`, so every child
  keeps its node.
- **Emptying is announced.** With `afterAChange` the message node is a live
  region: the platform reads it once, in place, and the user can go back over
  it. `IuxSemantics.liveRegion` is used rather than a direct announcement,
  because an announcement on Android clears TalkBack's speech queue and cuts off
  whatever the user was listening to.
- **Focus is not moved.** This is the opposite choice from
  `IuxValidationSummary`, which takes focus when a submission is refused, and
  the difference is where the user is standing. A refused submission happens
  after the user pressed a button and is waiting; a list emptying under a filter
  happens while their hands are in the search field, and moving focus out of it
  would interrupt typing to announce the consequence of what they are still
  typing.
- **The illustration carries nothing** (WCAG SC 1.1.1). It is excluded from the
  semantic tree outright rather than described, because a description of
  decoration is noise a screen-reader user steps through on every visit. It
  cannot be the only carrier of the message, because `title` is required and
  must not be empty.
- **Nothing is carried by colour.** The message is words; the exit is a labelled
  control.
- **Text scaling.** No line limits and no ellipsis, at any scale. Half a
  sentence about why a screen is empty is an explanation the user cannot act on,
  and truncation gets worse exactly when someone has enlarged their text because
  they were struggling to read.

Manual validation still required: TalkBack (that the live region is spoken, and
spoken once), Voice Access, and a physical keyboard reaching the exit.

## Themes and tokens

Everything is resolved from the theme. The title takes `IuxTypographyTheme.title`
over `content.primary`; the guidance takes `body` over `content.secondary`; the
glyph is an `IuxIcon` at secondary emphasis; spacing comes from `IuxGap`. There
is no colour, radius or duration parameter, and there will not be one.

## Anti-patterns

| Instead of | Do |
| --- | --- |
| "No data" | name the thing: "No invoices match these filters" |
| "Add your first invoice" under an active filter | `IuxNoMatches` with a reset |
| "You're all caught up!" on a first run | `IuxNothingCreatedYet` |
| "Try again" over an empty result | report the failure with the error pattern |
| an illustration and no words | the words are the message; the glyph qualifies it |
| an empty state while the request is in flight | show progress |
| a reset labelled "Open filters" | a reset that returns content on activation |
| hiding the empty state when the action is pressed | let the parent decide |

## Limits

- **A live region is a request, not a guarantee.** Whether the platform speaks
  it, and when, is the platform's decision. A widget test can assert the node
  carries the flag and no more, so TalkBack remains a manual check. Nothing
  essential depends on the announcement — the same words are on screen either
  way.
- **One case is left standing.** The block scrolls only where it was given a
  bounded height, so a caller who places it in an unbounded, non-scrolling
  context — a `Column` inside a fixed-height box — still owns that overflow,
  because a scroll view cannot be built in an unbounded height at all. Flutter
  reports it as a flex overflow, which is the same report every other widget in
  that column gets.
- **Intrinsic dimensions are not available.** The constraints are read through a
  layout builder, so a caller wrapping the block in an `IntrinsicHeight` is told
  so by Flutter rather than given a wrong number.
- **No count is offered.** "0 of 42 invoices" is a sentence the caller writes,
  for the same reason the validation summary's count is a function: plural forms
  differ by language and IUX composes no user-facing text.
- **The assertions are debug-only.** A release build with a dead end will render
  one. The rules are teaching tools, not runtime guards.
- **One exit.** A situation the user must resolve by choosing between three
  things is a decision, and a decision belongs somewhere they can read the
  options side by side.
- **Not in the catalog yet.** `apps/catalog` is outside this mission's scope.

## Evidence level

| Rule | Level | Source |
| --- | --- | --- |
| An empty state explains the cause and offers a way forward | Strong guidance | NN/g, empty states; Material Design |
| An empty result and a failed request are different states | Strong guidance | NN/g; Material Design, error states |
| A filtered-to-nothing result offers a way to widen the criteria | Strong guidance | NN/g, search and filter; Baymard, no-results pages |
| A change of content is announced to assistive technology | Standard | WCAG 2.2 SC 4.1.3 (Status Messages) |
| Decorative imagery is hidden rather than described | Standard | WCAG 2.2 SC 1.1.1 |
| Meaning is never carried by colour alone | Standard | WCAG 2.2 SC 1.4.1 |
| Every control is named and its state announced | Standard | WCAG 2.2 SC 4.1.2 |
| Text stays readable when enlarged | Standard | WCAG 2.2 SC 1.4.4 |
| Content stays reachable at 320 px with one direction of scrolling | Standard | WCAG 2.2 SC 1.4.10 (Reflow) |
| Reading the constraints rather than taking a "I already scroll" flag | Brand choice | IUX governance, `PROJECT_PROMPT.md` §20, §22 — a default nobody has to remember |
| Four causes rather than three or five | Brand choice | IUX governance; see "Search and filter are one situation" |
| Refusing a dead end on an assertion | Brand choice | IUX governance, PROJECT_PROMPT.md §22 |
| `afterAChange` as the default arrival | Hypothesis | reasoned from the asymmetry of the two failures; needs TalkBack validation |

## Sources

- WCAG 2.2 — SC 1.1.1, 1.4.1, 1.4.4, 1.4.10, 2.4.7, 4.1.2, 4.1.3.
- Android accessibility guidance, live regions and `announceForAccessibility`
  deprecation.
- Nielsen Norman Group, on empty states, blank slates and no-results pages.
- Baymard Institute, on no-results and filtering.
- Material Design, empty states.
- `PROJECT_PROMPT.md` §5 (priorities), §17 (cognitive load), §19–22 (API
  design), §57 (patterns).
- `docs/components/component-standard.md` §2, §3, §5, §6, §7, §11.
- `docs/components/action-model.md`, `docs/patterns/guided-form.md`,
  `docs/patterns/destructive-action.md`.
