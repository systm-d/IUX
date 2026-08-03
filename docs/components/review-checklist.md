# Component review checklist

Run before merging any component. The mechanical rules are already enforced by
`test/components/component_standard_test.dart`; what follows is the judgement
that a machine cannot make.

## Architecture

- [ ] Does it use the runtime rather than reimplementing it?
- [ ] Are responsibilities separated — does it do exactly one thing?
- [ ] Would this be two components, or a pattern?

## API

- [ ] Can it be understood without reading the documentation?
- [ ] Can it be used correctly on the first attempt?
- [ ] Does every parameter earn its place?
- [ ] Are intents explicit rather than encoded in booleans?
- [ ] Does a nullable callback also produce disabled semantics?

## Accessibility

- [ ] Does every interactive element have an accessible name?
- [ ] Is the name *understandable*, not merely present?
- [ ] Is focus visible, and distinct from selection?
- [ ] Does gaining focus leave the layout where it was?
- [ ] Targets at least the resolved minimum, spaced at least 8 apart?
- [ ] Usable at a 200% text scale without clipping?
- [ ] Does every state survive with colour removed?
- [ ] Does every animation declare a motion role?
- [ ] Does removing the animation remove any information?

## UX

- [ ] Are all applicable states from the standard handled?
- [ ] Is feedback proportionate to the consequence?
- [ ] Is each animation answering a question?
- [ ] Is a destructive action distinguishable by more than colour?

## Code and documentation

- [ ] Behaviour tested, not pixels?
- [ ] Does the documentation say when **not** to use this?
- [ ] Are known limitations written down?
- [ ] Evidence registry updated for any UX decision?
- [ ] ADR written for any architectural decision?

## Release

- [ ] `dart format .`
- [ ] `flutter analyze` on package and catalog
- [ ] `flutter test` on package and catalog
- [ ] catalog updated
- [ ] CHANGELOG updated

## What this checklist cannot do

It cannot tell you whether the component solves a real problem, whether its
wording is clear to someone who did not write it, or whether TalkBack reads it
sensibly. Those need a person, and the last needs a device.
