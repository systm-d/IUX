import 'package:flutter/material.dart';

import '../../foundations/iux_foundations.dart';
import '../iux_theme_configuration.dart';

/// How far apart an overline's letters are set, in logical pixels.
///
/// A choice rather than a measurement, and it is what carries the register:
/// at the same size and one weight apart, spacing is the difference between a
/// control label and a line that names a group. Small enough that a long
/// German compound does not stretch past the card it sits over.
///
/// Fixed in logical pixels rather than expressed as a fraction of the size,
/// which matters once the user's text scale changes: Flutter's `TextScaler`
/// multiplies `fontSize` at paint time (`TextStyle.getTextStyle`) but passes
/// `letterSpacing` through untouched, so this value stays 0.8px whether the
/// overline is painted at 14px or, at 200% text, at 28px. Relative to the
/// glyphs the tracking therefore *tightens* as text grows — from 5.7% of the
/// em down to 2.9% — which is the safe direction: tracking that widened
/// instead would add gaps between already-larger letters, which is the
/// opposite of what a user asking for larger text needs. A value expressed in
/// em and recomputed from the ambient scale was considered and rejected for
/// the same reason `IuxTypographyTheme` never reads `MediaQuery` at all: the
/// theme resolves once, outside any `BuildContext`, and re-deriving it at
/// paint time would belong to the component painting the text, not to the
/// theme supplying its style.
const double _overlineTracking = 0.8;

/// Text styles for each semantic typography role.
///
/// Roles describe what a piece of text *is*, not how large it should be. A
/// component asks for `title` or `supporting`; the theme decides the metrics,
/// which is what keeps hierarchy consistent across an application.
///
/// No size is below 14 logical pixels. Line heights are generous enough that
/// a long language — German compounds, Finnish, Vietnamese diacritics — does
/// not collide with the line above.
///
/// Text scaling is deliberately *not* applied here. Flutter applies the user's
/// scale factor at paint time, so baking it into the theme would apply it
/// twice.
@immutable
final class IuxTypographyTheme extends ThemeExtension<IuxTypographyTheme> {
  /// Creates a set of role styles.
  const IuxTypographyTheme({
    required this.display,
    required this.headline,
    required this.title,
    required this.body,
    required this.label,
    required this.supporting,
    required this.overline,
    required this.identifier,
  });

  /// Resolves the typography for a configuration.
  factory IuxTypographyTheme.resolve(IuxThemeConfiguration configuration) {
    final String? family = configuration.typography.fontFamily;
    final List<String>? fallback = configuration.typography.fontFamilyFallback;

    TextStyle style(
      double size,
      double height,
      FontWeight weight, {
      double? letterSpacing,
    }) =>
        TextStyle(
          fontSize: size,
          height: height / size,
          fontWeight: weight,
          letterSpacing: letterSpacing,
          fontFamily: family,
          fontFamilyFallback: fallback,
          fontFeatures: _figures,
        );

    return IuxTypographyTheme(
      display: style(45, 52, FontWeight.w400),
      headline: style(32, 40, FontWeight.w400),
      title: style(22, 28, FontWeight.w500),
      body: style(16, 24, FontWeight.w400),
      label: style(14, 20, FontWeight.w500),
      supporting: style(14, 20, FontWeight.w400),
      // At the ramp's floor, like `label` and `supporting`: an overline is
      // read once per group, and shrinking it below 14 is exactly the trade a
      // design system makes when it decides small caps look tidy.
      overline:
          style(14, 20, FontWeight.w600, letterSpacing: _overlineTracking),
      // Body metrics, because a string read character by character is the
      // text that most needs room, and the running-text size is the one the
      // ramp already trusts for reading.
      identifier: TextStyle(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w400,
        fontFamily:
            configuration.typography.identifierFontFamily ?? _platformMonospace,
        fontFamilyFallback: <String>[
          // A brand monospace face missing a glyph falls back to the
          // platform's, which is still monospace, before the application's
          // own fallbacks for other scripts.
          if (configuration.typography.identifierFontFamily != null)
            _platformMonospace,
          ...?fallback,
        ],
        fontFeatures: _identifierFeatures,
      ),
    );
  }

  /// The generic family Android resolves to its system monospace face.
  static const String _platformMonospace = 'monospace';

  /// What an identifier asks of its face, beyond being monospace.
  ///
  /// - **A slashed zero** (`zero`), so `0` cannot be read as `O`. A request: a
  ///   face without the alternate ignores it, which is why the choice of
  ///   face matters — see `IuxTypographyConfiguration.identifierFontFamily`.
  /// - **No ligatures** (`liga` and `calt` off). Programming faces draw `->`,
  ///   `!=` or `www` as one shape, which is right in code and wrong in a string
  ///   the user copies character by character. JetBrains Mono, which one of the
  ///   applications behind systm-d/IUX#66 ships, does exactly this.
  /// - **Tabular figures**, like every other role, although a monospace face
  ///   already has them.
  static const List<FontFeature> _identifierFeatures = <FontFeature>[
    FontFeature.tabularFigures(),
    FontFeature.slashedZero(),
    FontFeature.disable('liga'),
    FontFeature.disable('calt'),
  ];

  /// Every digit IUX draws takes the same width, in every role.
  ///
  /// A column of times whose digits shift by a pixel or two a row is harder to
  /// scan, and hardest for the readers already scanning slowly. That makes
  /// alignment a legibility property — the family of the contrast and target
  /// floors IUX owns — rather than something each application applies by hand.
  /// Three did: terminus at about twenty call sites, disconnected, and
  /// sentinel at ninety-five, each declaring a monospace family and laying it
  /// over the resolved style (systm-d/IUX#66).
  ///
  /// **Every role rather than the ones that "carry values"**, because roles do
  /// not carry values: components do, and most of them take a `String`, which
  /// is exactly why the workaround stopped at the application's own text. A
  /// list row's trailing time, a table cell, a chart label all resolve from
  /// these roles, so the feature reaches them without any of them changing.
  /// The cost is tabular digits in running prose, where a "1" sits in a
  /// slightly wider slot than it would. In an interface made mostly of short
  /// labels and values, that is the right side of the trade.
  ///
  /// **A feature, not a family**, and the limit that follows is stated rather
  /// than hidden: it asks the face for its tabular figures, and a face without
  /// them ignores the request. The platform default on Android has them. A
  /// brand face may not, and nothing here can tell.
  ///
  /// **It does not make an interface monospace, and that is a second need.**
  /// A commit hash, a token or a code is read character by character, and what
  /// it needs is letters that cannot be mistaken for each other — `0` and `O`,
  /// `1`, `l` and `I`. Aligned digits do nothing for that.
  /// That need is [identifier]'s (`IUX-TYPOGRAPHY-IDENTIFIER-001`).
  static const List<FontFeature> _figures = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  /// The largest role, for a single short statement per screen.
  final TextStyle display;

  /// A section-level heading.
  final TextStyle headline;

  /// The title of a grouped block, such as a card.
  final TextStyle title;

  /// Running text. The default for anything a user must read.
  final TextStyle body;

  /// A control label, such as a button or field name.
  final TextStyle label;

  /// Help text, captions and secondary annotations.
  final TextStyle supporting;

  /// The short, spaced line that names the group underneath it.
  ///
  /// Drawn in the capitals the caller wrote. See [IuxTypographyRole.overline]
  /// for why IUX does not produce them itself.
  final TextStyle overline;

  /// A string read one character at a time, in a monospace face.
  ///
  /// See [IuxTypographyRole.identifier]. `IuxIdentifier` draws one and also
  /// tells a screen reader to spell it out.
  final TextStyle identifier;

  /// Returns the style for a role.
  TextStyle forRole(IuxTypographyRole role) => switch (role) {
        IuxTypographyRole.display => display,
        IuxTypographyRole.headline => headline,
        IuxTypographyRole.title => title,
        IuxTypographyRole.body => body,
        IuxTypographyRole.label => label,
        IuxTypographyRole.supporting => supporting,
        IuxTypographyRole.overline => overline,
        IuxTypographyRole.identifier => identifier,
      };

  /// Resolves the typography installed on the ambient theme.
  static IuxTypographyTheme of(BuildContext context) =>
      Theme.of(context).extension<IuxTypographyTheme>() ??
      (throw FlutterError(
        'No IuxTypographyTheme found. Install an IUX theme on your '
        'MaterialApp, for example theme: IuxTheme.light().',
      ));

  /// Builds the Material text theme corresponding to these roles.
  ///
  /// [overline] and [identifier] have no slot here, deliberately. Material 3 removed its own
  /// `overline` and every remaining slot is already answered by another role;
  /// filling one twice would leave `Theme.of(context).textTheme` and
  /// `IuxTypographyTheme` disagreeing about what that slot means. A component
  /// that needs the role asks the extension for it.
  TextTheme toTextTheme() => TextTheme(
        displayLarge: display,
        displayMedium: display,
        displaySmall: headline,
        headlineLarge: headline,
        headlineMedium: headline,
        headlineSmall: title,
        titleLarge: title,
        titleMedium: title,
        titleSmall: label,
        bodyLarge: body,
        bodyMedium: body,
        bodySmall: supporting,
        labelLarge: label,
        labelMedium: label,
        labelSmall: supporting,
      );

  @override
  IuxTypographyTheme copyWith({
    TextStyle? display,
    TextStyle? headline,
    TextStyle? title,
    TextStyle? body,
    TextStyle? label,
    TextStyle? supporting,
    TextStyle? overline,
    TextStyle? identifier,
  }) =>
      IuxTypographyTheme(
        display: display ?? this.display,
        headline: headline ?? this.headline,
        title: title ?? this.title,
        body: body ?? this.body,
        label: label ?? this.label,
        supporting: supporting ?? this.supporting,
        overline: overline ?? this.overline,
        identifier: identifier ?? this.identifier,
      );

  @override
  IuxTypographyTheme lerp(
    covariant ThemeExtension<IuxTypographyTheme>? other,
    double t,
  ) {
    if (other is! IuxTypographyTheme) return this;
    return IuxTypographyTheme(
      display: TextStyle.lerp(display, other.display, t)!,
      headline: TextStyle.lerp(headline, other.headline, t)!,
      title: TextStyle.lerp(title, other.title, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      label: TextStyle.lerp(label, other.label, t)!,
      supporting: TextStyle.lerp(supporting, other.supporting, t)!,
      overline: TextStyle.lerp(overline, other.overline, t)!,
      identifier: TextStyle.lerp(identifier, other.identifier, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxTypographyTheme &&
          other.display == display &&
          other.headline == headline &&
          other.title == title &&
          other.body == body &&
          other.label == label &&
          other.supporting == supporting &&
          other.overline == overline &&
          other.identifier == identifier;

  @override
  int get hashCode => Object.hash(
        display,
        headline,
        title,
        body,
        label,
        supporting,
        overline,
        identifier,
      );
}
