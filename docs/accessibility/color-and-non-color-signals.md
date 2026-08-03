# Colour and non-colour signals

## The rule

> No important state may be communicated by colour alone.

This is absolute in IUX. It is not a recommendation to weigh against visual
preference, and a component that violates it is not finished.

## Why

Colour fails in more situations than it is usually credited with:

- colour vision deficiency affects roughly 1 in 12 men and 1 in 200 women;
- a screen reader conveys no colour at all;
- sunlight, low-quality displays and night filters distort hue;
- a user may have overridden colours through a platform accessibility setting;
- a monochrome or e-ink display has no hue to convey.

A state carried only by hue is therefore invisible to a substantial share of
users under ordinary conditions.

## Required complements

For each semantic family, at least one non-colour signal must accompany the
colour.

| Family | Colour signal | Required complement |
| --- | --- | --- |
| feedback | `feedback.*.surface` | icon and wording |
| error | `border.error` | message, and error semantics |
| destructive action | `action.destructive` | wording, confirmation |
| selection | `surface.selected` | checkmark or `selected` semantics |
| focus | `border.focus` | visible geometry, focus semantics |
| disabled | `content.disabled` | disabled semantics |
| link | `content.link` | underline or explicit affordance |
| required field | — | text label, not an asterisk alone |

## How to check

Render the screen in a single hue. Every state that disappears was being
carried by colour alone.

The catalog includes a section that does exactly this, so the check is a
routine step rather than an audit performed once.

## Rules

1. Colour reinforces meaning; it never carries it.
2. A complement must be perceivable by a screen reader, not merely visible.
3. An icon without a label is not sufficient when the icon is ambiguous.

## Limits

- This rule does not make an interface accessible on its own. Reading order,
  target size, motion, timing and language remain separate obligations.
- Automated tests can verify that an icon slot is populated. They cannot
  verify that the wording is understandable, which requires human review.

## Evidence level

Standard.

## Sources

- WCAG 2.2 — SC 1.4.1 Use of Color, level A.
- WCAG 2.2 — SC 3.3.1 Error Identification.
- Android accessibility guidance — do not rely on colour alone.
