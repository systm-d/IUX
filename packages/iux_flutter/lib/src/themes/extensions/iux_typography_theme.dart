import 'package:flutter/material.dart';

import '../../foundations/iux_foundations.dart';
import '../iux_theme_configuration.dart';

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
  });

  /// Resolves the typography for a configuration.
  factory IuxTypographyTheme.resolve(IuxThemeConfiguration configuration) {
    final String? family = configuration.typography.fontFamily;
    final List<String>? fallback = configuration.typography.fontFamilyFallback;

    TextStyle style(double size, double height, FontWeight weight) => TextStyle(
          fontSize: size,
          height: height / size,
          fontWeight: weight,
          fontFamily: family,
          fontFamilyFallback: fallback,
        );

    return IuxTypographyTheme(
      display: style(45, 52, FontWeight.w400),
      headline: style(32, 40, FontWeight.w400),
      title: style(22, 28, FontWeight.w500),
      body: style(16, 24, FontWeight.w400),
      label: style(14, 20, FontWeight.w500),
      supporting: style(14, 20, FontWeight.w400),
    );
  }

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

  /// Returns the style for a role.
  TextStyle forRole(IuxTypographyRole role) => switch (role) {
        IuxTypographyRole.display => display,
        IuxTypographyRole.headline => headline,
        IuxTypographyRole.title => title,
        IuxTypographyRole.body => body,
        IuxTypographyRole.label => label,
        IuxTypographyRole.supporting => supporting,
      };

  /// Resolves the typography installed on the ambient theme.
  static IuxTypographyTheme of(BuildContext context) =>
      Theme.of(context).extension<IuxTypographyTheme>() ??
      (throw FlutterError(
        'No IuxTypographyTheme found. Install an IUX theme on your '
        'MaterialApp, for example theme: IuxTheme.light().',
      ));

  /// Builds the Material text theme corresponding to these roles.
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
  }) =>
      IuxTypographyTheme(
        display: display ?? this.display,
        headline: headline ?? this.headline,
        title: title ?? this.title,
        body: body ?? this.body,
        label: label ?? this.label,
        supporting: supporting ?? this.supporting,
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
          other.supporting == supporting;

  @override
  int get hashCode =>
      Object.hash(display, headline, title, body, label, supporting);
}
