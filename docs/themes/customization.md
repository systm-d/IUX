# Customisation

## Intention

Allow controlled customisation at the theme level, and nowhere else.

## What can be customised

### Font family

```dart
IuxTheme.light(
  typography: const IuxTypographyConfiguration(
    fontFamily: 'Atkinson Hyperlegible',
    fontFamilyFallback: <String>['Noto Sans'],
  ),
)
```

Sizes, weights and line heights stay under IUX control. They are what the
readability and text-scaling guarantees rest on, and a theme that let an
application set an 11-pixel body style would be offering a way to break its own
contract.

### Semantic colours

```dart
IuxTheme.withSemanticColors(configuration, brandColors);
```

Roles change; everything reading them keeps working. See
[brand-theme-guidelines.md](brand-theme-guidelines.md) — the caller takes on
the contrast contracts.

### Preferences

Anything expressible through `IuxAccessibilityProfile`.

## What cannot be customised

There is no API to restyle an individual component. That is deliberate.

Per-component overrides are how a design system stops being one: two screens
drift apart, the difference is invisible in review, and the theme no longer
describes what the application looks like. Worse, a per-component colour
override bypasses the contrast contracts entirely — the tests still pass while
the shipped interface no longer holds.

If a component needs an appearance the theme cannot express, that is a gap in
the roles, and the fix belongs in the roles.

## Limits

- Customising semantic colours transfers responsibility for contrast to the
  caller. IUX can no longer guarantee what it cannot measure.
- The font family applies to every role. Per-role families are not supported.

## Evidence level

Context dependent. This is an IUX governance decision about what a design
system owes its users, not an external standard.
