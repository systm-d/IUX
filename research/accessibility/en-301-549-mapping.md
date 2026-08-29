# EN 301 549 — read, mapped, and what is still missing

**Status: the clause column is filled from the document.** The standard was
fetched from ETSI, opened and read on 2026-08-29. So was RAAM. What follows
separates, line by line, what the document says from what this repository can
show, and it deletes the leads the document does not support.

`research/README.md` is explicit that a citation nobody here has read is a lead
rather than a source. The rows below are no longer leads. **One thing still is,
and it is flagged in its own section**: the Implementing Decision that performs
the harmonisation could not be retrieved, and what replaces it is named.

---

## What was actually read

| document | how | provenance |
| --- | --- | --- |
| **EN 301 549 V3.2.1 (2021-03)**, 186 pp. | `etsi.org/deliver/etsi_en/301500_301599/301549/03.02.01_60/en_301549v030201p.pdf` | sha256 `1eee3a18…5b49`, 2 285 361 bytes, PDF creation date 2021-03-19 |
| **Final draft EN 301 549 V4.1.0 (2026-06)**, 280 pp. | `…/04.01.00_30/en_301549v040100va.pdf` | sha256 `c2247f2d…0672`, PDF creation date 2026-06-17 |
| **Draft EN 301 549 V4.1.0 (2025-11)**, 278 pp. | `…/04.01.00_20/en_301549v040100ev.pdf` | sha256 `c516fdcb…03cf`, PDF creation date 2025-11-07 |
| **RAAM 1.1**, 108 criteria | `accessibilite.public.lu/fr/raam1.1/referentiel-technique.html` | sha256 `73c98421…58d8`, published 2025-02-24 |

The 403 that `research/README.md` recorded against `etsi.org` was a
**user-agent filter, not an egress block** — the same URL returns 200 with a
browser `User-Agent`. That is worth writing down because it means the wall the
previous attempt hit was one layer thinner than it looked, and the same may be
true of other hosts it listed.

**EUR-Lex is genuinely unreachable**, and differently: it answers `202` with a
zero-byte body to every automated request, including through a fetch tool. That
is the one gap below.

---

## Finding 1 — the version question, answered

**EN 301 549 V3.2.1 (2021-03) is the version to read.** Three independent
confirmations, in descending order of what they settle:

1. **The ETSI directory itself.** Only `03.02.01_60` carries the `_60`
   publication suffix. V4.1.0 exists solely as `04.01.00_20` and
   `04.01.00_30`.
2. **The documents' own cover pages.** V3.2.1 reads `HARMONISED EUROPEAN
   STANDARD`. Both V4.1.0 files read `Draft` and `Final draft` respectively.
   **V4.1.0 is not published**, as of the date of this file.
3. **RAAM 1.1**, a national audit referential published 2025-02-24, states that
   it verifies conformance against *"la norme européenne EN 301 549 v.3.2.1"*.
   An audit authority is testing against V3.2.1 today.

The previous leads said *"V3.2.1 (2021-03) reported current; V4.1.0 final draft
reported 2026-06"*. **Both halves were right**, and are now sourced.

### The one thing still unread, and what stands in for it

Harmonisation is conferred by citation in the Official Journal, not by the
cover page — V3.2.1's own foreword is careful about this, saying conformance
confers presumption *"Once the present document is cited in the Official
Journal"*. That is conditional language, so **the standard cannot settle its own
harmonised status.**

The Implementing Decision that does could not be retrieved: EUR-Lex returns
`202` with an empty body to `curl` and to a fetch tool alike, for the HTML, the
PDF and the ELI URL.

What was read instead is the **European Commission's own page** on the Web
Accessibility Directive (`digital-strategy.ec.europa.eu`), which states that
`EN 301 549 v3.2.1` was *"harmonised on 18 August 2021"* by Implementing
Decision **(EU) 2021/1339**, superseding V2.1.2 harmonised by **(EU) 2018/2048**.

**This is the Commission describing its own act, not the act.** By the ladder in
`research/README.md` it is a strong secondary source, and it agrees with RAAM
and with the ETSI directory. It is enough to decide which document to read. It
is **not** enough for a legal conformance claim, and nothing here should be
written as though the Decision had been read.

---

## Finding 2 — audit of the previous leads

The instruction was to delete every row the document does not support. Here is
what happened to the six.

| lead | verdict |
| --- | --- |
| Exposing accessibility information through platform accessibility services = **11.5** | **Confirmed.** 11.5 *Interoperability with assistive technology*; 11.5.2 *Accessibility services*. |
| Not disrupting the platform's accessibility features = **11.6** | **Corrected.** 11.6 is *Documented accessibility usage*. No-disruption is **11.6.2** alone. 11.6.1 is a different requirement that applies only *"Where software is a platform"* — so it does not bind IUX. |
| Platform user preferences — units, colour, contrast, font type, font size, focus cursor = **11.7** | **Confirmed verbatim**, and the list is exactly those six. |
| **Clause 5** generic: closed functionality, preservation of accessibility information, biometrics | **Confirmed but incomplete, in the way that mattered.** Those three exist (5.1, 5.4, 5.3) and are all out of scope. The lead **missed 5.6 and 5.9**, which are the two clause-5 requirements that actually bind a component library. See the delta. |
| Documentation and support services | **Confirmed** as clause 12. |
| Which version is harmonised | **Answered** above. |

Four survived, one was wrong in its clause title, and one was incomplete in a
way that hid two real requirements. That is roughly the error rate the previous
file predicted for numbers taken from commercial summaries.

---

## Finding 3 — our own side, re-measured

The previous count was anchored to the commit that added the file. Re-measured
on `fd33610`:

| | then | now |
| --- | --- | --- |
| register entries | 166 | **169** |
| at level `standard` | 87 | **89** |
| distinct WCAG success criteria cited | 29 | **31** |

`1.3.1` and `2.4.4` joined the set. This work adds one further entry,
`IUX-EN301549-001`, taking the register to 170; the row above is the state of
`fd33610`, before it. The caveat is unchanged and is the point:
**thirty-one criteria named is not thirty-one criteria met**, and clause 11 now
supplies the denominator that was missing.

---

## The clause map

Scope note from the document: clause 11.0 lists **mobile applications** among the
software clause 11 governs, and states that requirements in 11.1 to 11.5 apply to
software that is not a web page. IUX is in scope for clause 11. Clauses 9 and 10
(web content, non-web documents) are not IUX's.

| clause | requirement (title) | applies to a component library? | verdict |
| --- | --- | --- | --- |
| 5.1 | Closed functionality | No — IUX ships open functionality | **not applicable, checked** |
| 5.2 | Activation of accessibility features | Application-level | **not applicable, checked** |
| 5.3 | Biometrics | No — IUX has no identification component | **not applicable, checked** |
| 5.4 | Preservation of accessibility information during conversion | No — IUX converts nothing | **not applicable, checked** |
| 5.5.1 | Means of operation — no grasping/pinching/twisting | Yes, read as complex gestures | **covered by construction, unclaimed** — the library registers no `onPan*`, `onScale*` or drag recogniser anywhere in `lib/src/`. No entry says so. |
| 5.5.2 | Operable parts discernibility without vision | Hardware | **not applicable, checked** |
| **5.6.1** | **Locking/toggle status via touch or sound** | **Yes — `IuxSwitch`, `IuxCheckbox`** | **partially covered, unclaimed** — state is exposed to semantics; no entry is written against this clause. |
| **5.6.2** | **Locking/toggle status visually determinable** | **Yes** | **partially covered, unclaimed** — both controls render an indicator; again unclaimed. |
| 5.7 / 5.8 | Key repeat, double-strike | Hardware keyboards | **not applicable, checked** |
| **5.9** | **Simultaneous user actions** | **Yes** | **covered by construction, unclaimed** — no multi-pointer recogniser in the library. |
| 11.1–11.4 | Perceivable / Operable / Understandable / Robust | Yes | **this is where the 31 criteria live.** Harmonised with WCAG2ICT; the existing register carries this ground and carries it well. |
| **11.5.2.5–.17** | **Role, state, boundary, name, description, values, label and parent-child relationships, text, actions, focus and selection tracking, change notification — all *"programmatically determinable by assistive technologies"* using the platform accessibility services of 11.5.2.3** | **Yes — this is the whole proposition** | **asserted on a model, never observed.** See below. |
| 11.6.1 | User control of accessibility features | No — *"Where software is a platform"* | **not applicable, checked** |
| **11.6.2** | **No disruption of accessibility features** | **Yes** | **nothing.** No entry in 169 is written against this framing. |
| **11.7** | **User preferences** | **Yes** | **partially covered — and it is IUX's best answer.** Itemised below. |
| 11.8 | Authoring tools | No | **not applicable, checked** |
| 12 | Documentation and support services | Integrator's | **not applicable to the library, in scope for the application** |

### 11.5 — the clause at the centre, and the exact size of the gap

11.5.2.3 requires software to *use the applicable documented platform
accessibility services*, and 11.5.2.5 to 11.5.2.17 each require some property to
be *"programmatically determinable by assistive technologies"* **by using those
services**.

On Android those services are `AccessibilityNodeInfo`. **Every claim in this
repository is measured one layer above it** — on Flutter's semantics tree, inside
`flutter_test`. The semantics tree is the input Flutter hands to the platform
layer, so the argument that one implies the other is a good argument. It is an
argument.

The standard even describes IUX's position in its own words, at 11.5.2.3:

> *"It is best practice to develop software using toolkits that automatically
> implement the underlying platform accessibility services."*

That sentence is the strongest external support this project's premise has, and
it makes the missing observation sharper rather than softer: the toolkit is
best practice **because** it implements the platform services, and nobody here
has looked at the platform services. `IUX-MANUAL-001` is the entry that says so.

### 11.7 — itemised against the six things the clause names

Verbatim: *"…shall follow the values of the user preferences for platform
settings for: units of measurement, colour, contrast, font type, font size, and
focus cursor except where they are overridden by the user."*

Read against `lib/src/accessibility/iux_accessibility.dart`:

| the clause's item | IUX | verdict |
| --- | --- | --- |
| units of measurement | nothing reads a platform unit preference | **nothing** — likely genuinely inapplicable, but unchecked either way |
| colour | `MediaQuery.invertColorsOf`, plus light/dark resolution | **partially covered** |
| contrast | `MediaQuery.highContrastOf`, four resolved mappings | **covered** |
| **font type** | **nothing reads a platform font choice** | **nothing — and the previous file predicted exactly this** |
| font size | `MediaQuery.textScalerOf`, honoured and asserted | **covered** |
| focus cursor | no platform focus-cursor preference is read | **nothing** |

So the clause the previous file called *"probably IUX's best answer in the whole
document"* is **three of six covered, one partial, two absent**. It is still the
best answer, and it is now a specific one rather than a hopeful one. NOTE 3 to
the clause matters for the two absences: additional values are permitted *"as
long as there is one mode where the application will follow the system
settings"*.

---

## The delta — requirements that are not WCAG and that nothing here addresses

This is the deliverable; the rest is accounting around it. Four items, and they
are small and sharp rather than sprawling:

1. **11.6.2 — no disruption of documented platform accessibility features.**
   Nothing. The neighbouring ground is the focus and modal-layer work, none of
   which was written as *"does not disrupt"*. RAAM makes this its criterion
   **12.3**, at level A, with no WCAG correspondence at all — so an audit tests
   it directly and no WCAG-derived test in this repository can answer it.
2. **11.7 font type, focus cursor, units of measurement.** Three of the six
   platform preferences are not read.
3. **5.6.1 / 5.6.2 — toggle control status, non-visually *and* visually.**
   `IuxSwitch` and `IuxCheckbox` almost certainly satisfy both; **no entry
   claims it**, and RAAM makes it criterion **5.5** at level A with no WCAG
   correspondence.
4. **5.5.1 and 5.9 — complex gestures and simultaneous actions.** Satisfied by
   construction, claimed nowhere. RAAM criteria **11.10** and **11.11**.

Items 3 and 4 are the cheap ones: the behaviour exists and the register is
simply silent. Item 1 is the real hole. Item 2 is a design decision that has
never been taken deliberately.

**And the asymmetry the previous file named survives the reading, sharpened:**
the requirements IUX most likely satisfies (11.7 platform preferences, 5.6, 5.9)
have never been claimed, and the requirement at the centre of its proposition
(11.5) is the one it cannot evidence. Reading the document did not overturn that
finding; it gave it clause numbers.

---

## RAAM 1.1 — what a team inherits by using IUX, and what stays theirs

**RAAM 1.1**, Service information et presse, Luxembourg, published 2025-02-24,
**108 criteria**, verifying EN 301 549 V3.2.1 clauses 5, 6, 7, 10, 11 and 12.

> **Correction to the previous file's lead**: it named **RAAM 2.0** as adopting
> the RGAA's thematic structure. There is no RAAM 2.0 — `raam2.0` is a 404 on
> the publisher's own site and **1.1 is current**. The lead was wrong and is
> deleted.

RAAM does something valuable that this repository would otherwise have had to do
by hand: **every criterion carries its own EN 301 549 clause correspondence.**
Distribution over the 108, by theme:

| theme | criteria | who owns it once IUX is adopted |
| --- | --- | --- |
| 1 Images | 9 | **shared** — IUX supplies the mechanism, the team supplies the alternatives |
| 2 Colour | 4 | **largely inherited** — palette and contrast are IUX's |
| 3 Multimedia | 18 | **theirs** — IUX ships no media player |
| 4 Tables | 5 | **theirs** |
| 5 Components | 5 | **largely inherited** — this is IUX's core |
| 6 Links, 7 Structure | 4 | **shared** |
| 8 Presentation | 7 | **largely inherited** |
| 9 Forms | 12 | **shared** — IUX supplies fields, labels and error mechanics |
| 10 Navigation | 4 | **shared** |
| 11 Consultation | 16 | **shared** |
| 12 Documentation | 4 | **theirs**, except 12.3 which is IUX's and unaddressed |
| 13 Editing tools | 6 | **theirs** |
| 14 Support services | 3 | **theirs** |
| 15 Two-way communication | 11 | **theirs** |

Level split across the 108: **83 at A, 25 at AA**.

**34 of the 108 have no WCAG correspondence at all.** Those are the ones a
WCAG-derived test suite structurally cannot reach, and they are listed in the
delta above where they touch a component library. The rest — 3.14–3.18, 11.14,
11.15, 11.16, 12.1, 12.2, 12.4, 13.x, 14.x, 15.x — are media, biometrics, key
repeat, documentation, authoring and telephony: **the integrator's, and worth
telling them so explicitly.**

The single most load-bearing criterion for this project is **RAAM 5.1** —
*"Chaque composant d'interface est-il, si nécessaire, compatible avec les
technologies d'assistance ?"* — which alone maps to **nine** sub-clauses of
11.5.2 plus 11.6.2, and whose evaluation method begins *"Activer le lecteur
d'écran"*. **That is the audit step this repository has never performed.**

---

## What is still not established

- **The Implementing Decision has not been read.** EUR-Lex is unreachable by
  automation. The Commission's own page stands in for it and is labelled as such.
- **No verdict here has been checked against clause 11.1–11.4 line by line.**
  The 31 criteria are asserted by tests; whether each *EN clause* built on them
  is met is a separate pass this file does not claim to have done.
- **Nothing was promoted into a register `Sources` line by this work** beyond the
  entry that records it. The clause numbers above are now readable by anyone with
  the same PDF; the conformance verdicts are this repository's own reading of
  its own code and remain reviewable.
- **V4.1.0 was downloaded but not mapped.** It is a draft. Worth a re-read when
  it publishes, because it is 94 pages longer than V3.2.1.
