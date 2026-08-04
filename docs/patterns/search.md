# Search

## Purpose

Give a search two halves that cannot disagree: a box that is named, always
clearable and never resizes under the user's fingers, and a region that shows
the wait, the results and their count, nothing matching, or the failure and the
way out of it — one of those at a time, and exactly one thing announced per
search.

The example below places the results in an `Expanded`, which is required and
which means **this composition cannot sit inside an `IuxPage`**. Read
[Known limitations](#known-limitations) before using it: on the framework's own
page widget the first non-empty result throws.

```dart
Column(
  children: <Widget>[
    IuxSearchField(
      label: l10n.searchYourOrders,
      clearLabel: l10n.clearTheSearch,
      placeholder: l10n.orderNumberOrCustomer,
      controller: _query,
      onChanged: controller.queryChanged,
    ),
    Expanded(
      child: IuxSearchResults<Order>(
        results: controller.results,
        summary: (BuildContext context, List<Order> orders) => orders.isEmpty
            ? l10n.nothingMatches(controller.query)
            : l10n.resultCount(orders.length),
        searchingLabel: l10n.searchingYourOrders,
        failureCategoryLabel: l10n.error,
        recovery: IuxRetryRoute(label: l10n.tryAgain, onRetry: controller.search),
        reset: IuxEmptyStateAction(
          label: l10n.clearTheSearch,
          action: const IuxActionDescriptor(
            semantics: IuxActionSemantics(label: 'Clear the search'),
          ),
          onActivate: controller.clear,
        ),
        builder: (BuildContext context, List<Order> orders) => OrderList(orders),
      ),
    ),
  ],
)
```

## Two widgets, not one

There is no `IuxSearchExperience` widget, and the reason is layout rather than
taste. On Android the query box very often lives in the app bar while the
results fill the body; a single widget spanning both would force them adjacent
and would be unusable for the most common arrangement of the thing it models.
`IuxSearchField` and `IuxSearchResults` are placed independently and share no
state, because the state they would share is the parent's anyway.

They are still one pattern: the field's `onChanged` is what eventually produces
the region's `IuxLoadState`, and the two documents below — what is announced,
and when the query may be run — only make sense together.

## The defect this exists to remove

Not the widgets. `IuxTextField`, `IuxIconButton`, `IuxLoadingRetry` and
`IuxEmptyState` all existed before this pattern and it draws none of them. What
it contributes is four things a hand-built search gets wrong, in roughly the
order they are shipped:

| The defect | What the user gets |
| --- | --- |
| the results change and nothing says so | a screen-reader user is told nothing at all: no focus moved, the caret is still in the box, and the rows they cannot see have been replaced |
| a query per keystroke | an announcement per keystroke, so nobody using TalkBack can type the query at all |
| "No results" with no way back | a dead end reached by typing one character too many, with the query scrolled off the top |
| the clear control appears with the first character | the box resizes on the keystroke that starts the search, moving the caret under the finger |

The first two are the interesting ones and the rest of this document is mostly
about them.

## A search is a load

`IuxSearchResults.results` is `IuxLoadState<List<T>>` — the same sealed value
every other waited-on region in IUX uses — and the widget composes
`IuxLoadingRetry` rather than switching over it a second time.

| The search is | `IuxLoadState` | What is on screen |
| --- | --- | --- |
| running | `IuxLoadInProgress` | `IuxLoadingIndicator`, carrying `searchingLabel` |
| answered with rows | `IuxLoadReady` with a non-empty list | the status line, then `builder`'s widget |
| answered with nothing | `IuxLoadReady` with an empty list | `IuxEmptyState` with `IuxNoMatches` |
| broken | `IuxLoadFailed` | `IuxErrorRecovery`, carrying the message and the route |

**There is deliberately no `IuxSearchState`.** A search that is running, one
that answered and one that broke are a load's three states wearing a different
word. A second vocabulary for them would mean two places to keep the invariant
that a region shows one of those and never two — which is the invariant IUX-030
exists for, and the one that hand-built searches lose first.

**Nothing matching is not a fourth state**, for the reason IUX-030 gives at
length: the search succeeded and what came back has no rows in it. What this
pattern adds over `IuxLoadingRetry` is that it *names* that situation rather
than leaving it to the builder. The cause is `IuxNoMatches` — the content is
there and the criteria the user set exclude all of it — which is the one
`IuxEmptyStateCause` that fits a search, and which IUX-028 already argues covers
search and filter together because they put the user in the same place with the
same way out.

That is also why `reset` is **required**. `IuxNoMatches` insists on a way back,
because the query was set through the interface and can therefore always be
unset by it, and "no results with no way back" is the most common dead end in
this category. It does not have to clear the box: "Search everywhere", "Include
archived" and "Search the last year instead" are all resets. What matters is
that activating it returns content, so the user learns the query was the reason.

**The region is not mounted before a search has been run.** An empty box has not
asked anything, so there is nothing to answer; a region rendering "Nothing
matches" for a query nobody typed tells the user their search failed before they
made one. What a search screen shows first — recent searches, a curated
suggestion, a prompt, nothing — is the caller's screen, and this pattern
declines to guess at it. That is a documented rule rather than an enforced one,
because the widget cannot see the query and a widget that took the query in
order to check it would be taking it for no other purpose.

## Exactly one thing is announced per settled search

A sighted user sees the list change. A screen-reader user is told **nothing** —
no focus moved, the caret is still in the box, and the rows are simply
different. WCAG 2.2 SC 4.1.3 (Status Messages) is the criterion and a live region
is the mechanism.

The hard part is not saying it. It is saying it once.

| The search is | Announced | By |
| --- | --- | --- |
| running | `searchingLabel` | `IuxLoadingIndicator`'s live region |
| answered with rows | `summary(context, results)` | the status line above the results |
| answered with nothing | `summary(context, const [])` | `IuxEmptyState`'s own live region |
| broken | `"$categoryLabel. $message"` | `IuxErrorRecovery`'s live region |

Every branch has exactly one, and the widget test walks the real semantics tree
to check it rather than asserting prose: `liveRegions(tester)` collects every
node carrying the live-region flag that is not merged into its parent, and each
branch returns a list of length one.

**The empty branch is where this was nearly got wrong.** The obvious
implementation puts the status line above every ready result and lets
`IuxEmptyState` announce as well — and then a search that matched nothing says
the same sentence twice, once as a status and once as a heading. So the status
line exists only when something matched, and the empty branch's announcement is
the empty state's own.

`IuxEmptyStateArrival.afterAChange` is passed explicitly and is not
configurable. For empty states generally the arrival is a real question — a
screen that opened empty should not announce itself — but a search result region
is only ever reached by asking. There is no way to arrive at it except by
typing, so it is always after a change.

**The summary is a function of the result, not a string beside it.**

```dart
typedef IuxSearchSummary<T> = String Function(BuildContext, List<T> results);
```

A `String` parameter sitting next to `results` would eventually be a stale
`String` parameter sitting next to `results`, and the stale one is what the
screen-reader user hears. Computed from the value, it cannot disagree with the
state that produced it.

Every word of it is the caller's. Counting is not language-independent — plural
rules differ between languages and some have six forms — so a framework
composing "12 results" would be composing it wrongly for most of the world.

**The status line is on screen as well as announced.** Not because the count is
otherwise unavailable — a sighted user can see rows — but because "twelve" and
"two hundred" are not distinguishable at a glance, and because a live region is
a request rather than a guarantee. Nothing essential is lost when the platform
declines to speak it: the same words are on screen.

**One thing the platform decides and IUX does not work around.** Android speaks
a polite live region when its content *changes*, so two consecutive searches
that both return twelve results produce one announcement rather than two.
Forcing a second one would mean composing a string that differs from the last —
precisely what this library refuses to do.

## Debounce is the caller's, and it is not optional

Neither widget holds a timer. This is IUX-030's position applied unchanged: a
widget that chose its branch from wall-clock time rather than from the state it
was handed would render differently from an identical sibling, and that is the
one property the whole design rests on. IUX does not run the query, so it has
nothing to delay.

What the caller must do instead is not a nicety.

**What was measured.** `test/patterns/iux_search_test.dart` drives a
five-character query with no pause waited for — a query per keystroke, which is
what `onChanged` invites — and counts the live regions the semantics tree
actually produces:

| Query length | Live regions announced |
| --- | --- |
| 5 characters, no debounce | **10** — five identical "Searching your orders", five counts |
| 5 characters, one pause | **2** — one wait, one count |

Five of the ten are the same sentence. A screen-reader user cannot type through
that, and it is not a screen-reader-only problem: the same cadence flashes the
results region between a wait and a list on every keystroke.

**So: run the query when the typing stops, not when it happens.**

**Choosing the delay, and why the obvious number is wrong.** The window is
bounded at both ends:

- **Below it**, the debounce fires between characters instead of between
  queries, which is the ten-announcement case with extra steps. The interval
  between keystrokes for a competent typist on a hardware keyboard is roughly
  **200–300 ms** (40–60 wpm at five characters per word); on a phone's soft
  keyboard it is slower still.
- **Above it**, the search stops answering. Miller (1968) and Nielsen (1993)
  independently put the limit of the user's uninterrupted flow of thought at
  about **1 s**; a delay approaching that, plus the query's own round trip, is a
  search that feels broken.

The obvious move is to tune the delay to a typist's rhythm — around 250 ms — and
that is the wrong end of the window to aim at. **A delay tuned to a fast typist
fires after every single character for a slow one**, and the users who type most
slowly are disproportionately the users of screen readers, switch access and
on-screen keyboards. The noisy case is not the average user; it is the user this
pattern exists to protect. Prefer the longer end, and prefer "the user has
stopped" to any fixed interval.

**What WCAG says about all this.** SC 2.2.1 (Timing Adjustable) is satisfied by
imposing no limit at all. Nothing in this pattern expires, removes content on a
schedule or requires the user to act within any interval. A caller's
trailing-edge debounce sets no limit either: it restarts with every keystroke, so
a user typing one character a minute is never cut off — they simply get one
search per character, which is a noise problem and not a conformance one. A
*fixed interval* that ran the query whether or not the user had finished would
be a different matter, and is why the guidance above is "wait for a pause"
rather than "poll".

## There is no suggestion list, and that is measured rather than argued

A suggestion list attached to a text box is a combo box, and a combo box is not
a visual arrangement. It has a role, a relationship to the list it controls, an
announced count, an active descendant that moves while focus stays in the box,
and keyboard expectations to match. A suggestion list without them is a set of
tappable words that a screen-reader user is never told exists.

**Flutter 3.44.8 declares `SemanticsRole.comboBox` and does not implement it.**
The framework's own debug role checks route it to `_unimplemented`, so a node
carrying the role throws

```text
Missing checks for role SemanticsRole.comboBox
```

the moment it reaches a semantics update. The role cannot be used at all — this
is not the weaker claim that it announces nothing. A test pins that behaviour so
the day it is implemented is visible.

Shipping suggestions anyway would mean a list with no role, and
`PROJECT_PROMPT.md` §19 does not permit public API whose only effect is an
unverified announcement. So there are none. An application that needs them today
owns the list and its semantics, knowing what it is taking on.

## Clearing

**The clear control is not optional and cannot be turned off.** `clearLabel` is
required, not nullable. A box full of text with no way to empty it leaves the
user holding backspace, which is a motor-accessibility problem before it is an
annoyance and gets worse the longer the query.

**It is a control beside the box, not a glyph inside it.** A target inside a
target is two hit regions competing for the same pixels: a tap near the trailing
edge either clears the query or places the caret, and which one it did is
invisible until the results change. Outside, it is a real `IuxIconButton`, which
means the touch-target floor, the focus ring, the announced name and keyboard
activation are the button's rather than reimplemented.

**What it actually measures**, pinned in the tests:

| Profile | Control | Target floor | Gap to the box |
| --- | --- | --- | --- |
| standard | 56 × 56 | 48 (`IuxTouchTarget.minimum`) | 8.0 (`kIuxMinimumTargetSpacing`) |
| comfortable | 64 × 64 | 56 (`IuxTouchTarget.comfortable`) | 9.0 |

Target size alone does not prevent mis-taps — two 48-pixel targets touching each
other still produce them — which is why the gap is held at the floor as well
(SC 2.5.8). The row is bottom-aligned, and that puts the control level with the
box to the pixel: the field block this widget permits is a name, a gap and the
box, with nothing below it. Centring would hang the control half the name's
height too low.

**Its space is reserved whether or not it is shown.** A control that appeared
with the first character would resize the box on the keystroke that starts the
query, moving the caret under the user's finger and, for someone using a screen
magnifier, moving the thing they are looking at. The reserved slot costs one
target's width and buys a box that never changes size. While it is hidden the
control is out of the semantic tree, out of the focus order and not hit-testable,
so nobody is offered a control that would do nothing.

**Clearing returns focus to the box.** This is a deliberate exception to the rule
`IuxLoadingRetry` and `IuxEmptyState` follow, and the difference is who asked. A
load resolving happens *to* the user. Clearing is something they did, by
activating a control that then ceases to exist — and leaving focus alone hands it
back to the nearest enclosing scope, which is the defect IUX-030 documents and
cannot fix from its side. Here it can be fixed, and the destination is not a
guess: the only reason to empty a search box is to put something else in it.

**What a screen reader hears** as a result is the box's own name and its now
empty value, in the platform's words and the user's language. Nothing announces
"cleared", because nothing needs to: the field says what it is and that it is
empty. The trade is that focusing the box reopens the software keyboard for a
user who had dismissed it, which is the smaller cost — a user who has just
emptied their query is about to type.

## What the framework refuses to hold

**The query.** `IuxSearchField` writes to the caller's controller in exactly one
place, the clear control, and reports it through the same `onChanged` Flutter
calls when the user types a character. There is no second callback for clearing
and therefore no second callback to forget.

**The search.** Nothing here starts one, decides one finished, retries one or
times one out. See `IuxLoadState`.

**The history.** Recent searches are user data — a record of what somebody
looked for, frequently the most sensitive thing an application holds. Whether
they are kept, where, whether they survive a sign-out and whether they are
synced are privacy decisions with legal weight in several jurisdictions, and a
framework that quietly kept a list would be making them on the application's
behalf.

## What is not covered

**Submitting.** `IuxTextField` exposes neither `textInputAction` nor
`onSubmitted`, so this pattern cannot give the software keyboard a "Search" key
and cannot report the user pressing it. The query reaches the caller only
through `onChanged`, and Enter dismisses the keyboard and does nothing else.
This is a gap in `IuxTextField` rather than a decision here; see "Defects found"
below.

**The search-box input type.** `SemanticsInputType.search` exists in Flutter and
would be the honest value, but it is reachable only through `IuxTextContent`,
which has no `search` member. The box is announced as an ordinary text field
carrying the caller's name. Whether Android's TalkBack distinguishes the two
input types at all is unverified, so this is recorded as a gap rather than as a
defect with a known cost.

**Filters and facets.** Narrowing a list by choosing among known values is a
selection control, not a query the user composes. `IuxEmptyState` with
`IuxNoMatches` already covers a filter that excluded everything.

**Highlighting the matched term.** A framework that emboldened substrings would
be deciding what matched, which only the search knows, and would be composing
rich text out of the caller's data.

**Paging and infinite scroll.** `builder` receives the current page as a list;
how more of it arrives is the caller's.

**A determinate wait.** Inherited from `IuxLoadingRetry`: the wait is
indeterminate, and a search whose extent the caller can count places its own
indicator.

## Known limitations

**The results region must be given a bounded height, and this rules out
`IuxPage`** (`IUX-SEARCH-RESULTS-001`). The results branch puts `builder`'s
widget in an `Expanded` below the status line, because a result list scrolls and
a scrolling list has to be told how tall it is. Given unbounded height it fails
on Flutter's own unbounded-constraints assertion — which names the problem
rather than laying out silently wrongly, but still throws.

**`IuxPage` scrolls by default, so it supplies exactly the unbounded height this
pattern cannot take.** The first non-empty result throws *RenderFlex children
have non-zero flex but incoming height constraints are unbounded*. The
documented remedy — place it inside an `Expanded` or a `SizedBox` — therefore
means giving up `IuxPage`, which is the only thing in the framework that knows
the page insets and the reading width. There is no arrangement that keeps both.

**It has one empty branch where a list usually needs two.** `IuxSearchResults`
hard-codes `IuxNoMatches` and **requires** a `reset`, so a collection that has
never held anything is reported as "no matches, clear the search" beside an
empty search box. "Nothing exists yet" and "your filter excluded everything" are
two of the four situations `IuxEmptyStateCause` exists to keep apart, and this
pattern can express one of them.

**Consequence for a real screen.** A searchable list on an `IuxPage`, which is
the ordinary case, cannot use this pattern at all today. Compose
`IuxSearchField`, `IuxEmptyState` and the list directly; the cost is the status
line, whose count lives in a private widget and has to be reimplemented. Worked
example in `apps/pilot/lib/jobs_screen.dart`.

**Nothing scrolls.** A very long summary at a large text scale wraps rather than
truncating, and takes the height it needs from the results below it — in a short
enough viewport it overflows. This is `IuxLoadingRetry`'s and `IuxEmptyState`'s
documented behaviour and is inherited: a region inside a list that already
scrolls must not introduce a second one.

**A live region is a request, not a guarantee.** Whether the platform speaks it,
and when, is the platform's decision. A widget test asserts that the node carries
the flag and no more, so TalkBack stays a manual check.

**Activating the reset loses keyboard focus.** Inherited from `IuxEmptyState`
and `IuxButton`, and documented at length in `docs/patterns/loading-and-retry.md`
under the same heading. Clearing through `IuxSearchField` does not have this
problem, because that control moves focus deliberately.

**Manual validation still owed.** TalkBack ordering and announcement timing
across the four branches, and in particular whether a real device coalesces two
live regions arriving in consecutive frames; TalkBack's reading of the box after
clearing; Voice Access activation of the clear control; D-pad traversal from the
box to the clear control and into the results.

## Defects found in code this pattern does not own

1. **`IuxTextField` cannot submit.** No `textInputAction`, no `onSubmitted`. A
   search that should run when the user presses the keyboard's action key cannot
   be built on it. Adding both is additive.
2. **`IuxTextContent` has no `search` member**, so `SemanticsInputType.search` is
   unreachable from any IUX field. Adding one is additive and mechanical — the
   resolution extension already maps every other member.
3. **`IuxTextField` has no trailing-control slot.** Not a defect in itself — this
   pattern argues a control beside the box is better than one inside it — but it
   is the reason the choice was not available.

## Evidence level

| Rule | Level | Source |
| --- | --- | --- |
| A search is a load and reuses its states | Strong guidance | NN/g, application states; IUX-030 |
| A result change is announced without moving focus | Standard | WCAG 2.2 SC 4.1.3 (Status Messages) |
| A search that matched nothing offers a way back | Standard | WCAG 2.2 SC 3.3.3, via `IuxNoMatches` |
| The count is on screen as well as announced | Strong guidance | NN/g, search results; WCAG 2.2 SC 1.4.1 by analogy |
| Interactive targets meet 48 dp with 8 dp between them | Standard | WCAG 2.2 SC 2.5.8; Android accessibility guidance |
| Text stays readable when enlarged | Standard | WCAG 2.2 SC 1.4.4 |
| Motion is reduced or removed without losing the information | Standard | WCAG 2.2 SC 2.3.3 |
| No time limit is imposed on the user | Standard | WCAG 2.2 SC 2.2.1 (satisfied by imposing none) |
| ~1 s is the limit of uninterrupted flow of thought | Strong guidance | Miller 1968; Nielsen 1993 |
| ~200–300 ms between keystrokes for a competent typist | Context dependent | typing-rate arithmetic from 40–60 wpm; varies enormously with motor ability |
| 10 announcements for a five-character undebounced query | Standard (measured) | `test/patterns/iux_search_test.dart` |
| 56 × 56 control, 8 dp gap, level with the box | Standard (measured) | `test/patterns/iux_search_test.dart` |
| `SemanticsRole.comboBox` is unusable in Flutter 3.44.8 | Standard (measured) | `test/patterns/iux_search_test.dart`; Flutter `_DebugSemanticsRoleChecks` |
| Tuning the debounce to the slowest typist rather than the average | Hypothesis | reasoned from who is harmed by the noisy case; needs user validation |
| Returning focus to the box after clearing | Hypothesis | reasoned from why anyone clears a search; needs TalkBack validation |
| Reserving the clear control's space rather than animating it in | Brand choice | IUX governance; layout stability over density |
| Two widgets rather than one `IuxSearchExperience` | Brand choice | IUX governance; forced by app-bar placement |

## Sources

- WCAG 2.2 — SC 1.4.1, 1.4.4, 2.2.1, 2.3.3, 2.5.8, 3.3.3, 4.1.2, 4.1.3.
- Android accessibility guidance; TalkBack live-region behaviour.
- W3C ARIA Authoring Practices, combobox pattern (for what a suggestion list
  owes the user, which is why none is shipped).
- Miller, R. B. (1968), *Response time in man-computer conversational
  transactions*.
- Nielsen, J. (1993), *Usability Engineering*, chapter on response times.
- Nielsen Norman Group, search results pages and empty search results.
- `PROJECT_PROMPT.md` §5 (priorities), §9 (evidence levels), §19–23 (API
  design), §29 (patterns).
- `docs/components/component-standard.md` §2, §3, §5, §6, §7, §11.
- `docs/patterns/loading-and-retry.md`, `docs/patterns/empty-state.md`,
  `docs/patterns/error-recovery.md`, `docs/inputs/`.
