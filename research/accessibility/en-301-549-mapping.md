# EN 301 549 — what IUX can already claim, and what nobody here has read

**Status: started, and deliberately not finished.** The clause column is empty
and stays empty until somebody reads the standard. What is filled in is our own
side — measured from this repository, verifiable by anyone with a checkout.

Two things came out of starting it that are worth more than the mapping would
have been if it had been written from memory, and both are below.

---

## Finding 1 — half of systm-d/IUX#44 was aimed at the wrong document

The issue asked for a mapping against **EN 301 549 and RGAA**, on the reasoning
that RGAA is what a French audit tests against. The second half is wrong, and
in a way that matters for the application driving this work.

**The RGAA's technical method covers web technologies only** — HTML, CSS,
JavaScript, ARIA — and explicitly does not cover native mobile applications.
For those, the European standard applies directly. IUX is a Flutter framework
producing native Android interfaces, so **the RGAA's 106 criteria do not apply
to it at all**, and an audit of an application built on IUX would not be run
against them.

Two other referentials are in the picture and neither was in the issue:

- **RAAM**, published by Luxembourg's Service Information et Presse, is a
  referential for native mobile applications that verifies conformance against
  EN 301 549. RAAM 2.0 adopts the RGAA's thematic structure, which is probably
  why the two are so easily confused. **This is the document that would have
  answered the question the issue was really asking**, and it is the one to
  read first.
- **RGAA 5** is reported to be in preparation at DINUM for late 2026, adding
  criteria for native iOS and Android applications and moving to WCAG 2.2. If
  that lands, the issue's original framing becomes correct — later.

Recorded because it cost nothing to find and would have cost a great deal to
discover after writing a mapping against the wrong criteria set.

---

## Finding 2 — the standard could not be read from here

Every primary source is unreachable from this environment. `etsi.org`,
`w3.org`, `accessibilite.numerique.gouv.fr`, `accessibilite.public.lu` and
`europa.eu` are all refused by the network egress proxy; `developer.android.com`
is not. So the standard, the referentials and even WCAG itself cannot be
fetched here, while the Android platform documentation can.

**This is why the clause column is empty rather than filled in from
recollection.** `research/README.md` is explicit that a citation nobody here
has read is a lead rather than a source, and a clause number quoted from a
commercial summary is exactly the failure `IUX-RESEARCH-GAP-001` reported, one
level up. Everything in the *Leads* section below is marked accordingly and
none of it may be promoted into a register `Sources` line by anyone who has not
opened the document.

**What finishing this needs is one person with a PDF reader**, not more work
here. EN 301 549 is published free of charge by ETSI, which is the whole reason
this was the cheaper of the two standards issues.

---

## Finding 3 — what IUX can already count

Measured from `docs/evidence/` at the commit this file was added. No reading
required, and this half of the mapping is finished:

| | count |
| --- | --- |
| register entries | 166 |
| entries citing a WCAG 2.2 success criterion | 85 |
| entries at level `standard` | 87 |
| **distinct success criteria cited** | **29** |

The 29, in order:

> 1.1.1 · 1.3.3 · 1.4.1 · 1.4.3 · 1.4.4 · 1.4.6 · 1.4.10 · 1.4.11 · 1.4.12 ·
> 1.4.13 · 2.1.1 · 2.1.2 · 2.2.1 · 2.2.2 · 2.3.3 · 2.4.3 · 2.4.6 · 2.4.7 ·
> 2.4.11 · 2.5.1 · 2.5.3 · 2.5.5 · 2.5.8 · 3.2.2 · 3.3.1 · 3.3.3 · 3.3.4 ·
> 4.1.2 · 4.1.3

Each is asserted by tests rather than claimed, which is the part of this
project that is genuinely strong. **What none of it establishes is coverage.**
Twenty-nine criteria named is not "twenty-nine criteria met" and is certainly
not "the criteria that apply are met" — the denominator is in the document
nobody here has opened, and some of these are cited in passing rather than
carried.

---

## The delta — where a mapping would actually earn its keep

The point of this exercise was never the WCAG overlap, which is large and
already tested. It is the requirements that are **not** WCAG, because those are
the ones no test in this repository was written against.

The clauses below are named from secondary summaries and **are leads**. They
are recorded as *questions to put to the standard*, with IUX's candidate answer
beside each, so that a reader with the document can confirm or delete a row
rather than start from nothing.

| what to look up | why IUX cares | candidate answer, unverified |
| --- | --- | --- |
| Requirements on exposing accessibility information through the platform's own accessibility services (reported as clause 11.5; on Android, `AccessibilityNodeInfo`) | This is IUX's entire proposition | **Strongest on paper, weakest in evidence.** Every claim is measured on Flutter's semantics tree under `flutter_test` — a model of what an assistive service would be *told*. `IUX-MANUAL-001`: no TalkBack session has ever been run. A clause about the platform service is a clause this project cannot yet answer. |
| Requirements on not disrupting the platform's accessibility features (reported as clause 11.6) | Nothing in the register is written against this framing | Unknown. `IUX-FOCUS-*` and the modal layer work are the neighbouring ground, and none of it was written as "does not disrupt". |
| Requirements on following platform user preferences — reported as units, colour, contrast, font type, font size, focus cursor (clause 11.7) | The four theme profiles and `IuxAccessibility.scaleText` exist for exactly this | **Probably IUX's best answer in the whole document, and it is claimed against nothing.** Light/dark × standard/high contrast are resolved and tested on all four; text scale is honoured and asserted. `IUX-RUNTIME-*` and `IUX-THEME-*` carry it. Confirm whether "font type" is in scope, because IUX does not honour a platform font choice. |
| Generic requirements — reported as clause 5, covering closed functionality, preservation of accessibility information, biometrics | A component library may be out of scope for most of it | Probably mostly not applicable to a library, and worth writing down as *not applicable, checked* rather than left silent. |
| Documentation and support-service requirements | Nothing in the repository addresses them | Out of scope for the library, in scope for a consuming application. The useful output is a note telling an integrator that. |
| Which version is the harmonised one, cited in the Official Journal | Determines what an audit today actually tests against | V3.2.1 (2021-03) is reported current; a V4.1.0 final draft is reported dated 2026-06. **Check this first** — it decides which document the rest of the work reads. |

The recurring shape is worth naming: **the clauses IUX is most likely to
satisfy are the ones it has never claimed, and the clause at the centre of its
proposition is the one it cannot yet evidence.** That asymmetry is the finding
this file exists to record, and it does not depend on any clause number being
right.

---

## What would finish this

1. Fetch EN 301 549 from ETSI, note the version and date, and **check first
   which version is harmonised**.
2. Replace the *what to look up* column with real clause numbers and verbatim
   requirement text. Delete every row the document does not support — some of
   the six above will be wrong.
3. For each clause that applies to a UI component library, record the verdict:
   *covered*, *partially covered*, *not applicable to a library*, or *nothing*,
   with the register entries and tests that carry it.
4. Read RAAM, not RGAA, for the mobile audit method. The output an integrator
   actually wants is: **which criteria does a team inherit by using IUX, and
   which stay theirs.** That is the deliverable with the shortest path to being
   useful to somebody.
5. Only then, promote anything into a register `Sources` line.

---

## Leads (unverified — none of these has been read here)

- **EN 301 549**, published free by ETSI. V3.2.1 (2021-03) reported as the
  current harmonised version; V4.1.0 final draft reported 2026-06, with changes
  concentrated in real-time text and new annexes mapping to Directives
  2016/2102 and 2019/882.
- **RAAM**, Service Information et Presse, Luxembourg — the mobile referential.
  The document Finding 1 says should have been in the issue.
- **RGAA 4.1**, DINUM — web only, and therefore **not** applicable to IUX.
  Recorded here so the next person does not reach for it by reflex, which is
  precisely what happened when the issue was written.
- **RGAA 5**, reported in preparation at DINUM for late 2026 with native mobile
  criteria and WCAG 2.2. Worth re-checking before doing this work, because it
  may change which referential is the right one to map against.
- Directive 2019/882 (the European Accessibility Act) and Directive 2016/2102.
  Which one binds a given application decides whether any of this is optional,
  and neither has been read here either.
