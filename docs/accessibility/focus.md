# Focus

## Intention

Make focus visible, stable and distinguishable — from one implementation
rather than one per component.

## Widgets

```dart
IuxFocusable(
  onActivate: submit,
  child: const Text('Continue'),
)
```

`IuxFocusable` gives keyboard focus, a visible ring and Enter/Space activation
in one widget. `IuxFocusRing` draws the indicator alone, for components that
manage their own focus node.

## The ring reserves its space

The gap around the child is reserved whether or not the ring is drawn.

Gaining focus therefore never shifts the layout. The alternative — adding a
border on focus — moves every sibling by a few pixels each time focus changes,
which is hard to follow visually and, under screen magnification, can push the
focused element out of the viewport entirely.

## Drawn outside, never over

The ring is a foreground decoration around the element, not across it. WCAG 2.2
added SC 2.4.11 (Focus Not Obscured) precisely because indicators that overlap
their own content are common and unusable.

## Focus is not selection

Focus says where the keyboard is. Selection says what the user chose. They use
different roles (`state.focus`, `state.selected`) and must stay visually
distinct: a list that draws them identically cannot be operated by keyboard,
because the user loses track of their own position.

## Restoration

```dart
final previous = IuxFocus.current(context);
await showSomething();
IuxFocus.restore(previous);
```

Restoring focus after an overlay closes is what keeps a keyboard or
screen-reader user from being dropped back at the top of the page every time.
Dialogs and sheets (IUX-016, IUX-017) will use this.

## Rules

1. Focus is never removed without an equally visible replacement.
2. `IuxFocus.unfocus` dismisses a keyboard. It is never a way to hide a focus
   indicator.
3. High contrast thickens the ring; it does not merely recolour it.

## Limits

- Focus traversal order follows the widget tree. A visual order that differs
  from the tree order needs `FocusTraversalGroup`, which IUX does not wrap yet.
- Activation handles Enter and Space. Other activation keys are
  platform-specific and left to the component.

## Evidence level

Standard.

## Sources

- WCAG 2.2 — SC 2.4.7 Focus Visible, SC 2.4.11 Focus Not Obscured,
  SC 2.1.1 Keyboard.
