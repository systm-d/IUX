import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';

/// The identifier role: a string read one character at a time
/// (systm-d/IUX#66).
void main() {
  IuxTypographyTheme resolve([
    IuxTypographyConfiguration typography = const IuxTypographyConfiguration(),
  ]) =>
      IuxTypographyTheme.resolve(
        IuxThemeConfiguration(typography: typography),
      );

  group('it has a face of its own', () {
    test('the platform monospace face by default', () {
      expect(resolve().identifier.fontFamily, 'monospace');
    });

    test('the application names another once, at the theme root', () {
      // The workaround it replaces: ninety-five call sites in one application
      // each laying a family over a resolved style.
      final TextStyle identifier = resolve(
        const IuxTypographyConfiguration(
          identifierFontFamily: 'Atkinson Hyperlegible Mono',
        ),
      ).identifier;
      expect(identifier.fontFamily, 'Atkinson Hyperlegible Mono');
      expect(
        identifier.fontFamilyFallback,
        isNotNull,
        reason: 'a brand face missing a glyph must fall back to a monospace '
            'one, not to proportional text',
      );
      expect(identifier.fontFamilyFallback!.first, 'monospace');
    });

    test('prose keeps its face, so the interface is not all typewriter', () {
      // The other half of the workaround: setting fontFamily to a monospace
      // face put a whole application in one, prose included.
      final IuxTypographyTheme type = resolve(
        const IuxTypographyConfiguration(
          fontFamily: 'Brand Sans',
          identifierFontFamily: 'Brand Mono',
        ),
      );
      expect(type.body.fontFamily, 'Brand Sans');
      expect(type.identifier.fontFamily, 'Brand Mono');
    });

    test("the application's script fallbacks still apply", () {
      final TextStyle identifier = resolve(
        const IuxTypographyConfiguration(
          fontFamilyFallback: <String>['Noto Sans Arabic'],
        ),
      ).identifier;
      expect(identifier.fontFamilyFallback, contains('Noto Sans Arabic'));
    });
  });

  group('it asks the face for characters that cannot be confused', () {
    final List<FontFeature> features = resolve().identifier.fontFeatures!;

    test('a slashed zero, so 0 is not O', () {
      expect(features, contains(const FontFeature.slashedZero()));
    });

    test('no ligatures, so no two characters are drawn as one', () {
      expect(features, contains(const FontFeature.disable('liga')));
      expect(features, contains(const FontFeature.disable('calt')));
    });

    test('tabular figures, like every other role', () {
      expect(features, contains(const FontFeature.tabularFigures()));
    });
  });

  group('it keeps the ramp\'s promises', () {
    test('no smaller than body, the size the ramp trusts for reading', () {
      final IuxTypographyTheme type = resolve();
      expect(type.identifier.fontSize, type.body.fontSize);
      expect(type.identifier.height, type.body.height);
    });

    test('it takes part in equality, copy and interpolation', () {
      final IuxTypographyTheme a = resolve();
      final IuxTypographyTheme b = resolve(
        const IuxTypographyConfiguration(identifierFontFamily: 'Other Mono'),
      );
      expect(a == b, isFalse,
          reason: 'two themes differing only in the identifier are different');
      expect(a.copyWith(identifier: b.identifier).identifier, b.identifier);
      expect(a.lerp(b, 1).identifier.fontFamily, 'Other Mono');
      expect(a.forRole(IuxTypographyRole.identifier), a.identifier);
    });

    test('the configuration compares its new field', () {
      const IuxTypographyConfiguration a = IuxTypographyConfiguration();
      const IuxTypographyConfiguration b =
          IuxTypographyConfiguration(identifierFontFamily: 'Mono');
      expect(a == b, isFalse);
      expect(a.copyWith(identifierFontFamily: 'Mono'), b);
      expect(a.copyWith(identifierFontFamily: 'Mono').hashCode, b.hashCode);
    });
  });
}
