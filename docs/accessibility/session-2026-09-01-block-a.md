# Device session — 2026-09-01, Block A

The second device session, and the first with a **listener**. Block A was run by
the repository owner with TalkBack speaking; the previous session
(`session-2026-08-31-pixel7.md`) had reached only the node tree.

## What it ran on

| | |
| --- | --- |
| device | **Pixel 7** (`panther`), serial `34031FDH2006JT` |
| Android | **17** (SDK 37) |
| TalkBack | **17.0.1.926549743** — measured over `adb` on this phone the previous day, not read off the screen during the run |
| build | catalog debug APK from `main` at `977184b` |
| run by | the repository owner, listening |

## Scope, and it is narrow

**Block A only.** Blocks B to F were not attempted. In particular:

- **D3** — a real task on a real screen at a real accessibility setting — was
  not run.
- **F6** — the four feedback glyphs under the phone's **greyscale filter**,
  named at arm's length by shape alone — was not run. It is the check the
  mission named as the one no test here can replace, and it remains outstanding.

**systm-d/IUX#17 therefore stays open.** A partial run is recorded as partial.

## Result

**No defect was reported.** The protocol's own instruction is to report only
what fails or surprises, and nothing was raised.

Two things about that are worth writing down rather than leaving as a tick.

### A8 was looked for and not heard — and the code says why

The protocol says of A8: *"Expect a defect; describe it."* It says that because
`IUX-GUIDED-FORM-LIVE-001` was open against exactly this — a live region firing
in the same frame as a focus move.

**Nothing overlapped, and nothing was cut off.** Asked directly, the answer was
no.

That negative is corroborated rather than standing alone. `IuxGuidedForm` today
**contains no live region at all** — there is no `liveRegion` anywhere in
`lib/src/patterns/form/`. It announces a step change by moving focus to the
heading. The collision the entry describes cannot occur, because one of its two
halves no longer exists.

The entry's title already said `(FIXED)`; its `Status` line still said `open`.
The device run and the source agree, and the `Status` line was the stale half.

### What was not captured, and should have been

The protocol asks two questions that expect prose rather than a verdict, and
**neither answer was recorded**:

- **A6** asks for *"the two exact sentences"* TalkBack speaks for a read-only
  field and a disabled one, because Android resolves `readOnly || !enabled` and
  a disabled field therefore also publishes `isReadOnly`. The two announcements
  may well be identical, which would be a real defect that a clean verdict
  hides. **Unknown.**
- **A5** asks whether a row and its status read as two stops or one run-on
  sentence, at the phone's largest font. **Unknown.**

A pass on those checks is not the same as an answer to them.

## What this session establishes

- **TalkBack speaks the catalog audibly**, and a person navigating it with
  TalkBack reported nothing broken across Block A.
- **One open register entry is refuted**, with source corroboration.

## What it does not

- Five of six blocks, including both checks the mission ranked after A.
- Every specific announcement. No utterance was transcribed, by the listener or
  by the tooling — TalkBack's speech is not capturable over `adb`, which the
  previous session established.
- The five newest components — `IuxSelectField`, `IuxDataTable`,
  `IuxDateField`, `IuxSlider`, `IuxTimelineChart` — have no blocks in the
  protocol and were not covered by any check here.
- One device, one Android version, one TalkBack, one listener.
