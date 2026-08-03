import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Internal primitive palette used to build IUX semantic roles.
///
/// Primitives describe a hue and a level. They carry no meaning, no brand and
/// no interface intent. Components must never read a primitive: they resolve a
/// semantic role, which a theme maps to one of these values.
///
/// Levels are ordered by increasing perceptual darkness for a given hue, so a
/// higher level is always darker. This ordering is what lets a theme pick a
/// contrasting pair without measuring colors at runtime.
///
/// This class is deliberately not exported from `package:iux_flutter`.
@internal
abstract final class IuxPrimitiveColors {
  // Neutral ramp. Used for surfaces, content and borders.

  /// Lightest neutral, used as a base surface in light conditions.
  static const Color neutral0 = Color(0xFFFFFFFF);

  /// Near-white neutral used to separate a subtle surface from the base.
  static const Color neutral5 = Color(0xFFF6F7F9);

  /// Light neutral used for grouped or recessed surfaces.
  static const Color neutral10 = Color(0xFFECEEF2);

  /// Light neutral used for subtle borders in light conditions.
  static const Color neutral20 = Color(0xFFDCE0E7);

  /// Mid-light neutral used for standard borders in light conditions.
  static const Color neutral30 = Color(0xFFC0C6D0);

  /// Mid neutral used for strong borders in dark conditions.
  static const Color neutral40 = Color(0xFF98A0AE);

  /// Mid neutral used for disabled content and standard borders in light
  /// conditions.
  ///
  /// Calibrated so that disabled content keeps a 3:1 ratio against both the
  /// base surface and the disabled surface. WCAG exempts inactive controls
  /// from a contrast minimum; IUX deliberately holds the ratio instead.
  static const Color neutral45 = Color(0xFF7E8693);

  /// Mid-dark neutral used for secondary content in light conditions.
  static const Color neutral50 = Color(0xFF6B7382);

  /// Dark neutral used for strong borders and tertiary content.
  static const Color neutral60 = Color(0xFF4C5462);

  /// Dark neutral used for raised surfaces in dark conditions.
  static const Color neutral70 = Color(0xFF343B47);

  /// Darker neutral used for subtle surfaces in dark conditions.
  static const Color neutral80 = Color(0xFF222834);

  /// Very dark neutral used as a base surface in dark conditions.
  ///
  /// Deliberately not pure black: a fully black surface removes the ability to
  /// express elevation through surface contrast alone.
  static const Color neutral90 = Color(0xFF151A23);

  /// Deepest neutral used for inverse surfaces in light conditions.
  static const Color neutral95 = Color(0xFF0D1119);

  /// Pure black, reserved for cases requiring maximum separation.
  static const Color neutral100 = Color(0xFF000000);

  // Accent ramp. Used for primary actions, links and informational feedback.

  /// Deepest accent, used for content on light accent surfaces.
  static const Color accent20 = Color(0xFF0A2C63);

  /// Dark accent used for accent content on light surfaces.
  static const Color accent30 = Color(0xFF0F4289);

  /// Accent used for primary action surfaces in light conditions.
  static const Color accent40 = Color(0xFF1560B0);

  /// Light accent used for accent content on dark surfaces.
  static const Color accent70 = Color(0xFF8FBEEF);

  /// Lighter accent used for accent surfaces in dark conditions.
  static const Color accent80 = Color(0xFFBAD8F7);

  /// Lightest accent used for informational surfaces in light conditions.
  static const Color accent90 = Color(0xFFDDEBFB);

  // Critical ramp. Used for destructive actions and error feedback.

  /// Deepest critical value, used for content on light critical surfaces.
  static const Color critical20 = Color(0xFF5E0A0E);

  /// Dark critical value used for critical content on light surfaces.
  static const Color critical30 = Color(0xFF8A1017);

  /// Critical value used for destructive action surfaces in light conditions.
  static const Color critical40 = Color(0xFFB41720);

  /// Light critical value used for critical content on dark surfaces.
  static const Color critical70 = Color(0xFFF29A9E);

  /// Lighter critical value used for critical surfaces in dark conditions.
  static const Color critical80 = Color(0xFFF8C6C8);

  /// Lightest critical value used for error surfaces in light conditions.
  static const Color critical90 = Color(0xFFFBE3E4);

  // Positive ramp. Used for success feedback.

  /// Deepest positive value, used for content on light positive surfaces.
  static const Color positive20 = Color(0xFF06381F);

  /// Dark positive value used for positive content on light surfaces.
  static const Color positive30 = Color(0xFF0A5330);

  /// Positive value used for positive surfaces in light conditions.
  static const Color positive40 = Color(0xFF0F6E41);

  /// Light positive value used for positive content on dark surfaces.
  static const Color positive70 = Color(0xFF7FC9A2);

  /// Lighter positive value used for positive surfaces in dark conditions.
  static const Color positive80 = Color(0xFFB4E2C8);

  /// Lightest positive value used for success surfaces in light conditions.
  static const Color positive90 = Color(0xFFDDF2E7);

  // Caution ramp. Used for warning feedback.

  /// Deepest caution value, used for content on light caution surfaces.
  static const Color caution20 = Color(0xFF402A00);

  /// Dark caution value used for caution content on light surfaces.
  static const Color caution30 = Color(0xFF5E3F00);

  /// Caution value used for caution surfaces in light conditions.
  static const Color caution40 = Color(0xFF7D5400);

  /// Light caution value used for caution content on dark surfaces.
  static const Color caution70 = Color(0xFFEEBB3E);

  /// Lighter caution value used for caution surfaces in dark conditions.
  static const Color caution80 = Color(0xFFF7D88F);

  /// Lightest caution value used for warning surfaces in light conditions.
  static const Color caution90 = Color(0xFFFCEFCF);
}
