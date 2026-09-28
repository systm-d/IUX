# IuxIdentifier — a string read one character at a time

```dart
IuxIdentifier(value: commit.shortHash)
```

A commit hash, a version, a token, a recovery code, a booking reference: a
string a user compares, copies or reads aloud character by character. It is
drawn in the `identifier` typography role — a monospace face, a slashed zero,
no ligatures — and announced so a screen reader spells it out.

## Use when

- The user has to match it against something else: a hash in a log, a code in
  an email, a reference on a receipt.
- The user may have to read it aloud or type it elsewhere.

## Do not use when

- **It is a number.** A count, a duration or a time is read as a number, and
  every IUX role already draws digits at one width, so a column of them lines
  up without this. Spelling "1 2 4 7" out instead of "one thousand two hundred
  and forty-seven" helps nobody.
- **It is a word.** A product or project name is read as a word even when it
  is short and odd-looking.
- **It is secret.** A token the user is typing belongs in `IuxPasswordField`,
  which hides it and offers the switch that shows it.

## Why a widget and not only a role

The role gives the shapes: `0` against `O`, `1` against `l` and `I`. It cannot
give the announcement. A screen reader meeting `a1b2c3` guesses — it may try to
say it as a word, read "a one b two c three", or skip letters it takes for
punctuation. `IuxIdentifier` marks the whole string with Flutter's
`SpellOutStringAttribute`, which asks the platform's text-to-speech to read each
character in turn. The visible `Text` is excluded from the tree so the string is
not also announced a second time without the attribute.

## The face

The role asks for the platform's monospace face unless the application names
another, once, at the theme root:

```dart
IuxThemeConfiguration(
  typography: IuxTypographyConfiguration(
    identifierFontFamily: 'Atkinson Hyperlegible Mono',
  ),
)
```

Choose a face that separates the confusable characters — a slashed or dotted
zero, a `1` with a flag and a foot — because that is the reason the role exists.
The prose face (`fontFamily`) does not reach this role, and this one does not
reach prose: an application that set `fontFamily` to a monospace face to get its
hashes right can now drop that and keep proportional text everywhere else.

## Accessibility

- Spelled out, character by character, by TalkBack. Checking it on a device is
  `IUX-MANUAL-001` check F8.
- The string is the whole accessible name. Say what the identifier is in the
  text beside it — a row titled "Commit" — not inside it.
- Wraps at any character rather than truncating: an identifier has no word
  breaks, and the characters an ellipsis would hide are the ones that tell two
  of them apart.

## Limits

- **The slashed zero and the ligature switch are requests to the face.** A face
  without a slashed-zero alternate draws its ordinary zero, and nothing here can
  tell. `flutter_test` cannot either: its test face draws every glyph as the
  same box.
- **`monospace` is a generic family Android resolves to its system face.** Other
  platforms may not; name a family if the application ships beyond Android.
- **Spelled in full.** A forty-character hash is a long announcement. Show the
  short form the user actually compares.
- **Not selectable.** Copying a token is a real need, and selection brings
  handles, a toolbar and its own focus behaviour. It is left to a later change
  rather than half-done here.
- **Inside other components, a string is still a string.** `IuxListItem` and
  `IuxDataTable` draw what they are given in their own roles, so a hash passed
  to one is drawn proportionally and not spelled out. Put an `IuxIdentifier`
  where the component takes a widget, or beside it.

Recorded as `IUX-TYPOGRAPHY-IDENTIFIER-001`.
