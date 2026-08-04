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

## A control announces the focus it holds

Keyboard focus and *announced* focus are two different things, and a control
can have the first without the second. `IuxSemantics.action` and
`IuxSemantics.selection` both set `excludeSemantics` in order to control the
announced name, and that exclusion deletes everything the `IuxFocusable`
subtree contributed — including the `Focus` widget's own `focusable`, `focused`
and `onFocus` annotations. A control built that way looks correct, tabs
correctly, draws its ring correctly, and tells the platform nothing:

```text
                     isFocused          actions
IUX control          Tristate.none      [tap]
ElevatedButton       Tristate.isFalse   [tap, focus]
```

`Tristate.none` means the node declares no focusable state *at all*, and the
missing `SemanticsAction.focus` means assistive technology cannot move
accessibility focus onto the control programmatically — a screen-reader user
can only arrive by swiping there. WCAG 2.2 SC 4.1.2. This is
`IUX-A11Y-FOCUS-001`, and it is the third thing the same exclusion has silently
deleted; it took `onTap` first, from IUX-005 until IUX-011.

So `IuxSemantics.action` publishes the focus state and the `focus` action
itself, naming the focus node the control actually focuses. The two widgets
have to name the **same** node — otherwise the platform is told about a focus
that lives somewhere else, which is a subtler version of the same defect and
one that a flag check cannot see. `IuxFocusNodeOwner` supplies that one node:

```dart
IuxFocusNodeOwner(
  focusNode: widget.focusNode,          // the caller's, or null
  debugLabel: label,
  builder: (BuildContext context, FocusNode node) => IuxSemantics.action(
    label: label,
    onTap: activate,
    focusNode: node,                    // the node announced
    focusable: available,
    child: IuxFocusable(
      focusNode: node,                  // and the node held — the same one
      onActivate: activate,
      child: visual,
    ),
  ),
)
```

It is deliberately unexported. Its only correct use is inside a control, and
the four lines it replaces — hold a fallback, create it lazily, prefer the
caller's, dispose only the one it owns — are four lines that would eventually
disagree at nine call sites. The one most easily forgotten is the disposal.

**Every control that composes an excluding helper goes through it, and that is
enforced rather than remembered.**
`test/accessibility/announced_controls_test.dart` refuses a call site that
passes no `focusNode` or no `onTap`, and refuses a file that composes such a
helper without naming `IuxFocusNodeOwner`.
`test/accessibility/control_focus_semantics_test.dart` measures every control
against Flutter's own equivalent and drives
`performAction(SemanticsAction.focus)` on each one — because a node can
advertise the action, report the flag, and still move no focus at all.

`IuxSemantics.header`, `.image` and `.disabled` exclude too and are deliberately
outside this rule: none of them describes something the user can focus.

An unavailable control is the exception, and deliberately: it declares no
focusable state rather than declaring itself unfocused, because it has left the
focus order entirely. Announcing "not focused" for something that can never be
focused describes a state it does not have.

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
4. A visible ring is half the answer. The node has to say it is focusable and
   offer `SemanticsAction.focus`, and the node it names has to be the node the
   control holds.

## Limits

- Focus traversal order follows the widget tree. A visual order that differs
  from the tree order needs `FocusTraversalGroup`, which IUX does not wrap yet.
- Activation handles Enter and Space. Other activation keys are
  platform-specific and left to the component.
- `onFocus` is withheld on iOS, following Flutter, for an open engine defect
  (flutter/flutter#150030). The flag is published there; the action is not.
- Widget tests measure the semantics tree, not a screen reader. That
  `performAction(SemanticsAction.focus)` moves focus is proof the wiring is
  connected, not proof TalkBack or VoiceOver does the expected thing with it.

## Evidence level

Standard.

## Sources

- WCAG 2.2 — SC 2.4.7 Focus Visible, SC 2.4.11 Focus Not Obscured,
  SC 2.1.1 Keyboard.
