# Looking for something that is not here

IUX leaves some things out on purpose, and every one of those refusals is
argued — in the documentation of the component that does not have the thing.
That is exactly where someone who is looking for it and cannot find it will
never read. You cannot search for what does not exist, so the reasoning was
only ever found by people who already knew it was there.

The first migration of an existing application onto IUX showed what that costs.
Of six reports it produced, **two were refusals already written down**: one
asked for an error tone on a transient message, which `IuxTransientTone`
explains at length it will never have; the other asked for an obscured text
field, and its closing paragraph reconstructed, nearly word for word, the reason
`IuxTextContent` gives for not having one. Both reporters were right about what
they needed. Neither could have found the answer where it was kept.

So this page collects them in the place you look when something is missing.

**How to read it.** The table is the quick answer. Below it, each entry quotes
the refusal verbatim from the source and names the file. A test
(`test/package/deliberately_absent_test.dart`) checks every quote against its
file and every alternative against the library, so this page cannot go on
claiming a refusal the code no longer makes, or recommend something that does
not exist.

## Quick answer

| You are looking for | Use instead |
| --- | --- |
| a password or token field | `IuxPasswordField` |
| a number field | `IuxTextContent.text`, validated by the parent |
| a `textInputAction` | nothing: it follows from `IuxTextContent` |
| per-keystroke validation on a form | the parent's own controller |
| an error or warning toast | `IuxAlert`, or `IuxDialog` when the user must answer |
| a colour, radius or elevation parameter | the theme, once, for the whole application |
| a theme class for one component | the semantic palette, geometry and typography |
| a tappable image or avatar | `IuxCard.tappable`, or an `IuxIconButton` beside it |
| a standalone radio button | `IuxRadioGroup` |
| a status dot with no label | `IuxStatusIndicator`, which always draws its label |
| icon-only navigation | labelled destinations, always |
| scrollable tabs | fewer tabs; the strip wraps when its words do not fit |
| `autofocus` on a destructive control | nothing, deliberately |
| an `async` `onPressed` | `IuxAsyncActionButton` and an `IuxAsyncOutcome` |
| `debounce` or `throttle` on an action | a timer the application owns |
| a link or control inside a tooltip | `IuxContextualHelp` |
| an `empty` loading state | `IuxEmptyState` |

---

## Inputs

### A password or token field

**Use instead:** `IuxPasswordField`, with an `IuxSecretPurpose` saying whether
it is a sign-in password, a new one, or a token pasted from elsewhere. The
refusal below described a component rather than a missing flag before that
component existed; it was built from the refusal when the first migrated
application needed it (systm-d/IUX#67). `IuxTextField` still cannot conceal a
value, and a test holds that.

> There is no `password` value. An obscured field owes the user a way to
> reveal what they typed — otherwise a motor or dyslexic user cannot check a
> long password before submitting it — and that reveal control is a second
> interactive element with its own name, state and announcement. It is a
> component, not an enum value.

Source: `packages/iux_flutter/lib/src/components/input/iux_text_field.dart`

### A number field

**Use instead:** `IuxTextContent.text`, with the parent validating the shape it
expects. The three fields a `number` value would have hidden are not built.

> There is no `number` value either. "A number" is three different fields: a
> quantity, a formatted code, and a currency amount, each with its own
> keyboard, grouping and validation. Naming them all `number` would give the
> caller a value that is right a third of the time.

Source: `packages/iux_flutter/lib/src/components/input/iux_text_field.dart`

### A `textInputAction`

**Use instead:** nothing. The action key follows from the `IuxTextContent` you
already chose.

> There is no `textInputAction` parameter, because a call site holding one
> could ask for the search key on a phone-number field, and the point of
> [content] is that the five settings it implies cannot contradict each other.

Source: `packages/iux_flutter/lib/src/components/input/iux_text_field.dart`

### Per-keystroke validation on a form

**Use instead:** the parent's own controller, which already sees every
keystroke.

> There is no `onChange` value, and its absence is deliberate rather than an
> omission. The form never sees a keystroke: the value lives in the parent's
> controller and goes straight from the field to the parent.

Source: `packages/iux_flutter/lib/src/patterns/form/iux_form_model.dart`

## Feedback

### An error or warning toast

**Use instead:** `IuxAlert`, which stays until the parent removes it, or
`IuxDialog` when the user has to answer before continuing. A failure the user
is meant to act on — a pipeline that went red, a server that could not be
reached — is exactly the case this refusal exists for.

> There is no `error` and no `warning` here, and there will not be one. A
> failure that vanishes on a timer is a failure the user cannot act on: they
> looked away, or they were three words into another sentence, and the only
> account of what went wrong left the screen while they were not watching.

Source: `packages/iux_flutter/lib/src/components/transient/iux_transient_message.dart`

Notice what that argument is made of. The case *for* an error tone is usually
made on accessibility grounds — a user who glances rather than reads gets no
cue that anything is wrong. The refusal is made on the same grounds, and it is
the stronger one: a user who glanced away gets nothing at all, because the
message has gone.

## Controls, media and theming

### A colour, radius or elevation parameter

**Use instead:** the theme, configured once for the whole application —
`IuxThemeConfiguration`, or `IuxTheme.withSemanticColors` for a full brand
palette.

> There is no colour, radius, elevation or duration parameter, and there will
> not be one. An API that accepts a colour has already lost the contrast
> guarantee: the theme can no longer be held responsible for something a call
> site overrode.

Source: `packages/iux_flutter/lib/src/components/button/iux_button.dart`

`IuxCard` and `IuxTextField` make the same refusal in the same words.

### A theme class for one component

**Use instead:** the semantic palette, the geometry and the typography, which
every component already reads.

> There is no `IuxListTheme`, for the same reason there is no selection
> theme: every decision a row makes is already carried by the semantic
> palette, the geometry and the typography an application configures once.

Source: `packages/iux_flutter/lib/src/components/list/iux_list_tokens.dart`

The tabs, navigation, transient, progress, status, tooltip, chart and icon
components refuse a theme class of their own for the same reason.

### A tappable image or avatar

**Use instead:** `IuxCard.tappable` around the block the picture belongs to, or
an `IuxIconButton` beside the picture when the picture itself is the thing to
change.

> **Do not use it as a control.** There is no `onTap`. A tappable picture is a
> control with no name, no role, no focus ring and no target floor; put an
> `IuxButton` beside it, or make the surrounding block one `IuxCard.tappable`,
> which announces itself once and says what activating it does.

Source: `packages/iux_flutter/lib/src/components/media/iux_image.dart`

### A standalone radio button

**Use instead:** `IuxRadioGroup`, which names the question and owns the
answer.

> **There is no standalone radio widget, and there will not be one.** A radio
> outside a group announces itself as one of one and never says what the
> choice is about, and nothing in the layout tells a sighted user that two
> distant radios are related.

Source: `packages/iux_flutter/lib/src/components/selection/iux_selection_controls.dart`

### A status dot with no label

**Use instead:** `IuxStatusIndicator`, which always draws its label.

> **Accessibility.** There is no `showLabel` flag and no dot-only form, and
> there will not be one. A coloured dot with no words is the single most
> common "colour alone" failure in this category: it says nothing to a screen
> reader, nothing on a monochrome or sun-washed screen, and nothing to a user
> who cannot separate the hues.

Source: `packages/iux_flutter/lib/src/components/status/iux_status_indicator.dart`

### `autofocus` on a destructive control

**Use instead:** nothing, deliberately.

> **There is no `autofocus`, and there will not be one.** A control that
> deletes something and takes focus on arrival is one Enter press away from
> running, pressed by a keyboard user who was still reading the page.

Source: `packages/iux_flutter/lib/src/patterns/destructive/iux_destructive_action.dart`

### An `async` `onPressed`

**Use instead:** `IuxAsyncActionButton`, whose operation returns an
`IuxAsyncOutcome` saying what actually happened.

> There is no `onPressed: () async { ... }` here, and there will not be: a
> completed future means a function returned, not that a payment went
> through.

Source: `packages/iux_flutter/lib/src/components/button/iux_async_button.dart`

### `debounce` or `throttle` on an action

**Use instead:** a timer the application owns, and `IuxActionRepeatPolicy` for
the part that is a statement of intent.

> There is no `debounce` or `throttle`. Both need a duration, which does not
> belong in an enum, and both are timing mechanics rather than a statement of
> intent. An application that needs them owns the timer.

Source: `packages/iux_flutter/lib/src/actions/iux_action_model.dart`

### A link or a control inside a tooltip

**Use instead:** `IuxContextualHelp`.

> It shows text. There is no rich content, no link and no control inside a
> tooltip, and there will not be: anything a user can interact with has to be
> reachable, and this box is reachable only by the three routes above.

Source: `packages/iux_flutter/lib/src/components/help/iux_tooltip.dart`

## Navigation

### Icon-only destinations

**Use instead:** labelled destinations. The label is not optional anywhere.

> There is no `labelBehavior`, no `showLabel`, and no icon-only form. An icon
> on its own is a guess: the conventional ones (house, magnifier) are learned,
> the rest are not, and the user finds out which kind they are looking at by
> tapping.

Source: `packages/iux_flutter/lib/src/components/navigation/iux_navigation_destination.dart`

### Scrollable tabs

**Use instead:** fewer tabs. The strip wraps onto another row when its words no
longer fit on one.

> There is no scrollable mode and there will not be one. A strip that scrolls
> hides views off the edge of the screen, and a user who cannot see that there
> are more has no way to learn it

Source: `packages/iux_flutter/lib/src/components/tabs/iux_tabs.dart`

## Loading

### An `empty` loading state

**Use instead:** `IuxEmptyState`, which says why the result is empty and what
would fill it.

> An empty result is not a state of the *operation* — the load succeeded, and
> what came back has no rows in it.

Source: `packages/iux_flutter/lib/src/patterns/loading/iux_load_state.dart`

---

## When the thing you need is on this page

The refusals are arguments, and an argument can be wrong. If one of them costs
your application something real, the right move is an issue that answers the
argument quoted here — not a workaround that routes around it. Two of the
entries above were reached that way by integrators before this page existed,
and in both cases the report was worth having even though the refusal stood.
