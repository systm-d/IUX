# Typography

## Purpose

Typography roles express hierarchy without selecting a brand font. A component
asks `IuxTypographyTheme` for what a piece of text *is* — `display`,
`headline`, `title`, `body`, `label`, `supporting`, `overline` — and the
resolved theme decides the size, the line height, the weight and, for one
role, the letter spacing. One role, `identifier`, also has a face of its own. Final themes resolve readable styles that remain
compatible with Flutter text scaling.

## Roles

| Role | Size | Line height | Weight | Letter spacing |
| --- | --- | --- | --- | --- |
| `display` | 45 | 52 | w400 | — |
| `headline` | 32 | 40 | w400 | — |
| `title` | 22 | 28 | w500 | — |
| `body` | 16 | 24 | w400 | — |
| `label` | 14 | 20 | w500 | — |
| `supporting` | 14 | 20 | w400 | — |
| `overline` | 14 | 20 | w600 | 0.8 |
| `identifier` | 16 | 24 | w400 | — |

No size is below 14 logical pixels — the ramp's own floor, held even by the
two roles that already sit on it (`label`, `supporting`) and by the one this
document adds (`overline`). `docs/components/component-standard.md` §5 calls
this out by name: "text scaling. Works at 200%." — the floor is what keeps
that guarantee from starting at an unreadable size in the first place.

Text scaling is deliberately *not* applied inside the theme. Flutter applies
the user's scale factor at paint time (`TextStyle.getTextStyle`, via the
ambient `TextScaler`), so baking it into the theme's `fontSize` values would
apply it twice.

## The overline, and what IUX refuses to do with it

The pilot's maquette (`docs/maquettes/01-saisons.png`, in the application
repository) sets `SAISON EN COURS` and `AUTRES SAISONS` in small, letter-spaced
capitals above the group each one names. None of the six original roles
produces that register — `IuxSectionHeader` renders its title in `title`,
22/28, which is a heading font, not a label — so `overline` is a seventh role,
not a variant of a component. The maquette's need is generic — any grouped
list can carry a line that names the group above it — and coupling that
typographic decision to one component would duplicate a size, weight and
spacing choice the ramp already owns everywhere else, the same reasoning that
keeps `title` and `label` out of individual components' APIs.

**IUX does not write the capitals.** `overline` supplies the weight and the
letter spacing; the string stays exactly what the caller passed. A `String`
this role is applied to is expected to already be — or, in the common case,
to already read as — capitalised prose, but the transformation is the
caller's, not the theme's, for a reason that is not stylistic:

- **`String.toUpperCase()` in Dart takes no locale and is wrong for more than
  one language, measured this round on Dart 3.12.2:**
  `'i'.toUpperCase()` returns `'I'` (the plain, dotless capital) rather than
  Turkish `'İ'` (dotted) — Dart has no way to express "this is Turkish text"
  to the call, so the dotted lowercase *i* that starts words like *İstanbul*
  is uppercased wrong, silently, every time. `'ß'.toUpperCase()` returns
  `'ß'` unchanged — German capitalisation expects `SS`, and Dart's
  `toUpperCase()` does not perform that expansion at all, leaving a lowercase
  letter sitting inside what was meant to read as capitals. A role that
  applied `toUpperCase()` to whatever string arrived would get both wrong for
  some caller, eventually, and would get it wrong exactly where nobody is
  looking: a label, not the sentence a reviewer reads twice.
- **A screen reader is handed a word, not letters.** `SAISON EN COURS` and
  `Saison en cours` are the same string as far as TalkBack or VoiceOver is
  concerned — both are read as the word "saison". A widget that forced
  capitals by transforming the string, rather than by styling it, would in
  some configurations change what gets announced from a word read normally to
  letters spelled out one at a time. Styling the *rendering* through
  `TextStyle` never touches the string a screen reader receives; transforming
  the string itself risks exactly that.

The register is therefore carried entirely by weight and letter spacing, not
by size: `overline` and `label` sit at the same 14/20, and the only other
thing separating a 14-pixel label from a 14-pixel overline is that the
overline is heavier (w600 against w500) and spaced (0.8 logical pixels of
`letterSpacing`, against none). A caller that wants a group name to *read* in
capitals still writes them into the string — `'SAISON EN COURS'` in French,
whatever the equivalent is in a script with no case at all — because only the
caller knows what the target language and script actually need.

**What happens to that spacing when the user asks for larger text.** Flutter's
`TextScaler` scales `fontSize` at paint time but passes `letterSpacing`
through unscaled (verified this round against
`packages/flutter/lib/src/painting/text_style.dart`, `getTextStyle`: the
`fontSize` branch multiplies by the scaler, the `letterSpacing` field is
copied straight to the `ui.TextStyle`). `overline`'s 0.8px tracking is
therefore *fixed*, not proportional: at the default scale it is 5.7% of the
14px em; at 200% text, where the glyphs paint at 28px, the same 0.8px is
2.9% of the em. The tracking tightens, relatively, as text grows. That is the
safe direction — a user who asked for larger text because small text is hard
to read is not helped by letters that also grow farther apart — and the
alternative (deriving `letterSpacing` from the ambient scale so the ratio
holds) was rejected for the same reason the theme reads no `MediaQuery`
anywhere else: `IuxTypographyTheme` resolves once, from a configuration, with
no `BuildContext` in scope; recomputing a style from the ambient text scale is
something only the widget painting the text could do, and none does today.

## Figures: every digit takes the same width

Every role resolves with `FontFeature.tabularFigures()`. A column of times,
counts or amounts lines up, wherever it is drawn — including inside components
that take a `String` and give the application no style to change.

That last clause is why this lives in the roles. Three applications needed
aligned figures and each applied a monospace family over IUX's styles by hand:
terminus at about twenty call sites, disconnected, and sentinel at ninety-five
(systm-d/IUX#66). The workaround reached only their own text; a list row's
trailing time or a table cell stayed proportional, and the interface was half
aligned. Roles do not carry values — components do — so the feature is on every
role, and every component inherits it without changing.

**Two limits, stated rather than hidden.**

- **It is a request to the face.** A face that has tabular figures honours it;
  one that does not ignores it, and nothing here can tell. The Android platform
  default has them. A brand face passed through
  `IuxTypographyConfiguration.fontFamily` may not — check it before relying on
  alignment.
- **It does not make anything monospace, and that is a second need.** A commit
  hash, a token or a recovery code is read one character at a time, and what it
  needs is letters that cannot be mistaken for each other: `0` and `O`; `1`,
  `l` and `I`. Aligned digits do nothing for that. That is the `identifier`
  role, below.

The cost is tabular digits in running prose, where a `1` sits in a slightly
wider slot than a proportional face would give it. In an interface made mostly
of short labels and values, that is the right side of the trade.

## Identifiers: a face of their own

`identifier` is the one role that does not take `fontFamily`. It resolves to the
platform's monospace face, or to `IuxTypographyConfiguration.identifierFontFamily`
when the application names one, and it asks that face for three things:

| Feature | Why |
| --- | --- |
| `zero` — slashed zero | `0` is not `O` |
| `liga` and `calt` off | a programming face draws `->`, `!=` or `www` as one shape; an identifier is copied character by character |
| `tnum` | like every role |

It is a family rather than a feature because being monospace is a property of
the face, not a request to it — the same reason the issue that asked for it gave
(systm-d/IUX#66). Three applications had each laid a monospace family over IUX's
styles by hand, at up to ninety-five call sites; one gave up and set
`fontFamily` to a monospace face, which put the whole interface, prose
included, in a typewriter face. A family per role lets the type scale say which
text is which.

Metrics are `body`'s: a string read one character at a time is the text that
most needs room, and 16/24 is the size the ramp already trusts for reading.

The role gives the shapes; `IuxIdentifier` also gives the announcement — a
screen reader told to spell the string out. See
[identifier.md](../components/identifier.md). `IUX-TYPOGRAPHY-IDENTIFIER-001`.

## Best practices

- Use `overline` for the line that names the group beneath it — a card, a
  list section, a settings page — not for a heading a screen reader should
  land on. `IuxSectionHeader` already exposes its title through
  `IuxSemantics.header`; an `overline` used as a heading needs the same
  treatment at the call site, and nothing in the role provides it implicitly.
- Pair it with a muted content colour (`IuxSemanticColors.content.secondary`
  in the catalog sample) rather than the primary content colour: the group it
  names is what carries the visual weight, not the label above it.

## Anti-patterns

- **An overline used in place of a heading.** It identifies what follows; it
  does not title it, and nothing routes it into the accessibility tree as a
  header the way `IuxSemantics.header` does for `title`.
- **Calling `.toUpperCase()` on the string before handing it to `overline`.**
  Even where it happens to be correct for the language at hand, it is a
  decision the role deliberately leaves at the call site — see above.

## Limits

- **The identifier's slashed zero is requested, not guaranteed**, for the same
  reason: a monospace face without the alternate draws its ordinary zero. Name a
  face that has one.
- **Tabular figures are requested, not guaranteed.** See "Figures" above: a
  face without them ignores the request, and `flutter_test` cannot tell the two
  apart, because its test face draws every glyph at one width already.

- **The role provides the register, not the capitals.** Nothing checks that a
  caller passing lowercase text gets an overline that reads as one, and
  nothing should — the role is also correct for a script with no case.
- **`overline`'s letter spacing does not grow with text scale**, and nothing
  in this package derives one that does; see "What happens to that spacing"
  above. A future component that wanted spacing proportional to the *painted*
  size, rather than the theme's base size, would have to compute it itself
  from `MediaQuery.textScalerOf(context)` — `IuxTypographyTheme` cannot, since
  it resolves outside any `BuildContext`.
- **Whether 0.8 logical pixels reads as "spaced" against every font a caller
  supplies is not something this package can guarantee.** `letterSpacing` is
  set in absolute pixels rather than relative to `fontSize` specifically so a
  long compound word does not stretch further than intended, but a
  condensed or a very wide custom font family was not measured against it.
