/// Perceptual measurements of colour, available to tests only.
///
/// `contrast.dart` implements WCAG 2.x, which is the contract IUX ships
/// against and will keep shipping against. This file is the second opinion.
///
/// **Why a second opinion at all.** The evidence register already says it, in
/// its own voice and twice: *"WCAG 2.x contrast correlates imperfectly with
/// perceived contrast. APCA is a candidate successor that IUX has not
/// adopted."* `IUX-PALETTE-HEADROOM-001` is what that admission costs — a
/// warning role measured 9.60:1, which the ratio calls excellent, while the
/// first user to see it said the colours were too dark and resembled each
/// other. Two perceptual failures, neither of which a contrast ratio can
/// represent:
///
/// - **Appearance.** A ratio is symmetric and polarity-blind. It cannot say
///   that dark-on-light and light-on-dark at the same ratio do not read alike.
/// - **Confusability.** A ratio compares a colour to its *background*. Nothing
///   in WCAG compares two semantic roles to *each other*, so "the warning looks
///   like the error" is unrepresentable — even though it is the complaint that
///   was actually filed.
///
/// Everything here is pure arithmetic on sRGB. No lab, no participants, no
/// dependencies. It measures models of perception, which is not the same as
/// measuring perception — see the limits on each function.
///
/// **Nothing here is asserted until it has been checked against published
/// reference values.** `perception_test.dart` does that first, and the rest of
/// the suite is only entitled to these numbers if those checks pass.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Accessible Perceptual Contrast Algorithm — lightness contrast, `Lc`.
///
/// The candidate contrast method for WCAG 3, by Andrew Somers. Unlike a WCAG
/// 2.x ratio it is **signed and asymmetric**: swapping text and background does
/// not give the same magnitude, because dark-on-light and light-on-dark are not
/// equally legible at equal ratio. Positive `Lc` is dark text on a light
/// background; negative is the reverse.
///
/// **Status: a candidate, not a standard.** WCAG 3 is not a recommendation and
/// APCA has been contested. IUX's use of it is therefore deliberately narrow —
/// measure it *alongside* the WCAG 2.x ratio and record where the two disagree.
/// A disagreement is information; it is not a licence to drop the ratio, which
/// remains the thing conformance is claimed against.
abstract final class ApcaContrast {
  // Constants of APCA-W3 0.98G-4g. Reproduced rather than derived; the
  // reference checks in perception_test.dart are what make them trustworthy.
  static const double _mainTrc = 2.4;
  static const double _rCo = 0.2126729;
  static const double _gCo = 0.7151522;
  static const double _bCo = 0.0721750;
  static const double _normBg = 0.56;
  static const double _normTxt = 0.57;
  static const double _revTxt = 0.62;
  static const double _revBg = 0.65;
  static const double _blackThreshold = 0.022;
  static const double _blackClamp = 1.414;
  static const double _scale = 1.14;
  static const double _lowOffset = 0.027;
  static const double _lowClip = 0.1;
  static const double _deltaYMin = 0.0005;

  /// Screen luminance `Y`, with the black soft-clamp APCA applies.
  ///
  /// Not the WCAG relative luminance: the exponent is 2.4 on the whole channel
  /// rather than the piecewise sRGB transfer function, and very dark values are
  /// lifted so that near-black pairs do not report contrast the eye cannot use.
  static double screenLuminance(Color color) {
    assert(
      color.a == 1.0,
      'A translucent colour has no luminance of its own, only one relative to '
      'whatever happens to be behind it.',
    );
    double channel(double c) => math.pow(c, _mainTrc).toDouble();
    final double y = _rCo * channel(color.r) +
        _gCo * channel(color.g) +
        _bCo * channel(color.b);
    return y < _blackThreshold
        ? y + math.pow(_blackThreshold - y, _blackClamp).toDouble()
        : y;
  }

  /// The signed `Lc` of [text] against [background].
  ///
  /// Roughly: `|Lc|` 90 is comfortable for body text, 75 the working minimum,
  /// 60 for large or heavy text, 45 for larger and bolder still, and 30 the
  /// absolute floor below which text is spot-readable at best. Those bands are
  /// APCA's own guidance and are not thresholds IUX has adopted.
  static double lc(Color text, Color background) {
    final double yText = screenLuminance(text);
    final double yBackground = screenLuminance(background);

    if ((yBackground - yText).abs() < _deltaYMin) return 0;

    if (yBackground > yText) {
      // Dark text on a light background.
      final double sapc = (math.pow(yBackground, _normBg) -
              math.pow(yText, _normTxt)) *
          _scale;
      return sapc < _lowClip ? 0 : (sapc - _lowOffset) * 100;
    }

    // Light text on a dark background.
    final double sapc =
        (math.pow(yBackground, _revBg) - math.pow(yText, _revTxt)) * _scale;
    return sapc > -_lowClip ? 0 : (sapc + _lowOffset) * 100;
  }
}

/// A colour in Oklab, and the perceptual distance between two of them.
///
/// Oklab (Björn Ottosson, 2020; `oklab()` in CSS Color 4) is a perceptually
/// near-uniform space: equal numeric distances correspond to roughly equal
/// perceived differences, which is exactly what "do these two roles look alike"
/// needs and what a contrast ratio cannot provide.
///
/// **This is the instrument `IUX-PALETTE-HEADROOM-001` was missing.** The
/// report said the four content roles had "darkened until they resembled each
/// other more than their own meanings". That is a distance between two
/// foreground colours, and nothing in WCAG measures it.
@immutable
class OklabColor {
  const OklabColor(this.l, this.a, this.b);

  /// Converts an opaque sRGB colour.
  factory OklabColor.fromColor(Color color) {
    double linear(double c) => c <= 0.04045
        ? c / 12.92
        : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

    final double r = linear(color.r);
    final double g = linear(color.g);
    final double b = linear(color.b);

    final double lCone = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b;
    final double mCone = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b;
    final double sCone = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b;

    final double lRoot = math.pow(lCone, 1 / 3).toDouble();
    final double mRoot = math.pow(mCone, 1 / 3).toDouble();
    final double sRoot = math.pow(sCone, 1 / 3).toDouble();

    return OklabColor(
      0.2104542553 * lRoot + 0.7936177850 * mRoot - 0.0040720468 * sRoot,
      1.9779984951 * lRoot - 2.4285922050 * mRoot + 0.4505937099 * sRoot,
      0.0259040371 * lRoot + 0.7827717662 * mRoot - 0.8086757660 * sRoot,
    );
  }

  /// Perceived lightness, 0 (black) to 1 (white).
  final double l;

  /// Green–red axis.
  final double a;

  /// Blue–yellow axis.
  final double b;

  /// Chroma — distance from the neutral axis. Zero is a grey.
  double get chroma => math.sqrt(a * a + b * b);

  /// Hue angle in degrees, meaningless at very low [chroma].
  double get hue {
    final double degrees = math.atan2(b, a) * 180 / math.pi;
    return degrees < 0 ? degrees + 360 : degrees;
  }

  /// Perceptual distance to [other], on the ×100 scale this project reports in.
  ///
  /// A difference of about 2 is the smallest most people notice side by side.
  /// Distances used as a *separation* requirement should be far larger: two
  /// roles that must never be confused across a screen, glanced at rather than
  /// compared, need tens rather than units.
  double distanceTo(OklabColor other) {
    final double dl = l - other.l;
    final double da = a - other.a;
    final double db = b - other.b;
    return math.sqrt(dl * dl + da * da + db * db) * 100;
  }

  /// Distance ignoring lightness — how far apart the two *hues* are.
  ///
  /// [distanceTo] is the right measure of "can these be told apart", because
  /// lightness is a real channel and a user may well separate two roles by it
  /// alone. This one answers a narrower question: has the **colour** changed.
  ///
  /// It exists because the wider measure cannot verify a dichromacy
  /// simulation. Protanopia darkens a saturated red severely, so red and green
  /// stay far apart in [distanceTo] even once their hues have collapsed into
  /// the same yellow — the transform looked broken when it was working. The
  /// defining property of a dichromacy is the loss of one chromatic axis, and
  /// this is the only measure that can see it.
  double chromaticDistanceTo(OklabColor other) {
    final double da = a - other.a;
    final double db = b - other.b;
    return math.sqrt(da * da + db * db) * 100;
  }
}

/// The three dichromacies, simulated on an sRGB colour.
enum ColourVisionDeficiency {
  /// Red cone absent. Roughly 1% of men.
  protanopia,

  /// Green cone absent. The most common, roughly 1% of men.
  deuteranopia,

  /// Blue cone absent. Rare, and not sex-linked.
  tritanopia,
}

/// Simulates dichromatic vision.
///
/// **What this is for.** `IuxInlineFeedback` argues in its own source that its
/// category "survives deuteranopia and a black-and-white screenshot", and
/// `docs/components/inline-feedback.md` repeats it. Nothing anywhere simulates
/// it. This turns that argument into a measurement — the same move
/// `press_feedback_sweep_test.dart` made for a press.
///
/// **Limits, and the first is load-bearing.**
///
/// - **The matrices are a lead, not a source.** They are the severity-1.0
///   matrices attributed to Machado, Oliveira and Fernandes (2009), reproduced
///   here from secondary circulation. Nobody working on this repository has
///   read that paper, and `research/README.md` is explicit that such a citation
///   may not enter a register `Sources` line until somebody has. The
///   behavioural checks in `perception_test.dart` are what these currently
///   rest on: they establish that the transform does what a dichromacy does,
///   not that it does it to the published precision.
/// - **Dichromacy is the severe end.** Anomalous trichromacy — far more common
///   — is a partial shift this does not model.
/// - **A simulation is not a person.** It answers "would these two still differ
///   numerically", never "could somebody use this".
abstract final class ColourVision {
  static const Map<ColourVisionDeficiency, List<List<double>>> _matrices =
      <ColourVisionDeficiency, List<List<double>>>{
    ColourVisionDeficiency.protanopia: <List<double>>[
      <double>[0.152286, 1.052583, -0.204868],
      <double>[0.114503, 0.786281, 0.099216],
      <double>[-0.003882, -0.048116, 1.051998],
    ],
    ColourVisionDeficiency.deuteranopia: <List<double>>[
      <double>[0.367322, 0.860646, -0.227968],
      <double>[0.280085, 0.672501, 0.047413],
      <double>[-0.011820, 0.042940, 0.968881],
    ],
    ColourVisionDeficiency.tritanopia: <List<double>>[
      <double>[1.255528, -0.076749, -0.178779],
      <double>[-0.078411, 0.930809, 0.147602],
      <double>[0.004733, 0.691367, 0.303900],
    ],
  };

  /// [color] as it would appear under [deficiency].
  ///
  /// **The matrix is applied in linear RGB, not to the encoded channels.** It
  /// models how light reaches a cone that is not there, and light adds
  /// linearly; the sRGB channels do not. Applying it to encoded values instead
  /// gets the arithmetic right and the physics wrong, and the result is not
  /// subtly off — under protanopia it pushed red and green *further apart*
  /// (52 to 63 in Oklab) when a red-blind eye is defined by bringing them
  /// together. The behavioural checks in `perception_test.dart` caught it;
  /// nothing about the numbers looked wrong until they were asked to mean
  /// something.
  static Color simulate(Color color, ColourVisionDeficiency deficiency) {
    final List<List<double>> m = _matrices[deficiency]!;

    double toLinear(double c) => c <= 0.04045
        ? c / 12.92
        : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
    double toEncoded(double c) {
      final double v = c.clamp(0.0, 1.0);
      return v <= 0.0031308
          ? 12.92 * v
          : 1.055 * math.pow(v, 1 / 2.4).toDouble() - 0.055;
    }

    final double r = toLinear(color.r);
    final double g = toLinear(color.g);
    final double b = toLinear(color.b);

    return Color.from(
      alpha: color.a,
      red: toEncoded(m[0][0] * r + m[0][1] * g + m[0][2] * b),
      green: toEncoded(m[1][0] * r + m[1][1] * g + m[1][2] * b),
      blue: toEncoded(m[2][0] * r + m[2][1] * g + m[2][2] * b),
    );
  }
}
