# Research

This directory holds the evidence behind IUX decisions that **standards do not
settle**.

It is separate from `docs/evidence/semantic-tokens-and-accessibility.md`, and
the split is the point. The register records *what was decided and how sure we
are*; it has 156 entries and it is good at its job. This directory is where the
uncertain ones are worked on — the questions that have to be answered before an
entry can move off `hypothesis`.

## What this directory is not, today

**It is not a bibliography, and it does not yet contain one.** For most of this
project's life it contained nothing but a README describing subdirectories that
were never created, while the framework was described as producing interfaces
that are *ergonomic*. That gap was reported by an integrator
(`IUX-RESEARCH-GAP-001`), and closing it starts with saying plainly what the
register actually rests on.

Measured on the register as it stands:

| | count |
| --- | --- |
| entries | 156 |
| at level `standard` | 74 |
| mentioning a WCAG success criterion | 74 |
| citing Nielsen Norman Group | 4 |
| citing Fitts, Hick, ISO 9241, or any primary reading-rate or working-memory literature | **0** |

`Hick` appears twice and `Miller` once — both in prose arguing *against* a naive
application of the law, not as support for a rule.

So: **IUX is a rigorously tested WCAG-conformance and semantics library.** That
is a great deal, it is measured rather than asserted, and it is not the same
thing as an ergonomics library. Where the second claim is made, it is an
ambition, and `README.md` and `PROJECT_PROMPT.md` §8 now say so.

## What counts as a source here

In descending order of what it settles:

1. **A standard or a normative specification.** WCAG, ISO, an Android platform
   guarantee. These produce `standard`-level entries and mostly do not need this
   directory.
2. **A primary study or a meta-analysis**, read, with its population and task
   recorded. A reading-rate figure measured on undergraduates reading prose for
   comprehension does not transfer to somebody glancing at a notice while doing
   something else — and that difference is usually the whole question.
3. **A secondary summary** (Nielsen Norman Group, Baymard, a textbook). Useful
   for finding the primary work. Not a substitute for it.
4. **Our own measurement**, on hardware, with the method written down.

**A citation nobody here has read is a lead, not a source.** Files in this
directory mark leads as such, explicitly, and a lead may never be promoted into
the register's `Sources` line until somebody has read the thing and written
down what it actually says. Half the value of a well-known result is knowing
what it does *not* cover, and that half is only available to a reader.

## What goes in a file

One question per file or per section, and each one carries:

- **The rule as implemented**, with the constant or the code that holds it.
- **What supports it today** — honestly, including "an argument and nothing
  else".
- **What would settle it**: the measurement or the reading that would move the
  register entry off `hypothesis`, stated concretely enough that somebody could
  go and do it.
- **Leads**, marked unverified, with why each one might bear on the question.
- **What we would do if the answer went the other way.** A question whose two
  answers produce the same code is not worth researching.

## Layout

- `hci/` — attention, reading, memory, motor control. `open-questions.md` is the
  current backlog: five rules the framework enforces today on an argument alone.
- `accessibility/`, `android/`, `ux/` — not yet created. They will be, when
  there is something to put in them; an empty directory is the failure this
  directory is recovering from.

## Status

Nothing in this directory has been validated on hardware or against a read
primary source. It is a backlog with a method, which is more than the empty
directory it replaces and less than the research programme the name promises.
Both halves of that sentence are meant.
