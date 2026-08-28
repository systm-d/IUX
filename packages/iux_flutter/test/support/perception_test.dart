import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'perception.dart';

/// Checks the instruments before anything is allowed to use them.
///
/// `perception.dart` reproduces three published algorithms from memory of
/// secondary circulation. That is exactly the kind of citation
/// `research/README.md` refuses to let into a register `Sources` line — so
/// these checks are what the measurements actually rest on until somebody
/// reads the primaries. A number produced by an unverified implementation is
/// worse than no number, because it looks like evidence.
void main() {
  const Color black = Color(0xFF000000);
  const Color white = Color(0xFFFFFFFF);
  const Color red = Color(0xFFFF0000);
  const Color green = Color(0xFF00FF00);
  const Color blue = Color(0xFF0000FF);
  const Color yellow = Color(0xFFFFFF00);
  const Color grey = Color(0xFF808080);

  group('APCA reproduces its published extremes', () {
    // The two values APCA-W3 0.98G-4g is most often quoted by. Getting both
    // within a rounding error exercises every constant in the algorithm at
    // once — the transfer exponent, both normalisation pairs, the scale and
    // the low-clip offset — so it is a far stronger check than its size
    // suggests.
    test('black text on white measures Lc 106', () {
      expect(ApcaContrast.lc(black, white), closeTo(106.04, 0.5));
    });

    test('white text on black measures Lc -108', () {
      expect(ApcaContrast.lc(white, black), closeTo(-107.88, 0.5));
    });

    test('it is asymmetric, which is the whole point', () {
      // A WCAG ratio is 21:1 both ways. APCA is not, because dark-on-light and
      // light-on-dark are not equally legible at equal ratio.
      expect(
        ApcaContrast.lc(black, white).abs(),
        isNot(closeTo(ApcaContrast.lc(white, black).abs(), 0.5)),
      );
    });

    test('a colour on itself has no contrast', () {
      expect(ApcaContrast.lc(grey, grey), 0);
    });

    test('polarity carries the sign', () {
      expect(ApcaContrast.lc(black, white), greaterThan(0));
      expect(ApcaContrast.lc(white, black), lessThan(0));
    });
  });

  group('Oklab behaves like a perceptual space', () {
    test('white is fully light and has no chroma', () {
      final OklabColor w = OklabColor.fromColor(white);
      expect(w.l, closeTo(1.0, 0.001));
      expect(w.chroma, closeTo(0, 0.001));
    });

    test('black is fully dark', () {
      expect(OklabColor.fromColor(black).l, closeTo(0, 0.001));
    });

    test('a neutral grey has no chroma', () {
      expect(OklabColor.fromColor(grey).chroma, closeTo(0, 0.001));
    });

    test('lightness is monotonic along a grey ramp', () {
      double lightness(int v) =>
          OklabColor.fromColor(Color.fromARGB(255, v, v, v)).l;
      double previous = -1;
      for (int v = 0; v <= 255; v += 15) {
        final double current = lightness(v);
        expect(current, greaterThan(previous));
        previous = current;
      }
    });

    test('the primaries land where Oklab says they do', () {
      // Ottosson's own worked values for the sRGB primaries. Recalled rather
      // than read, so the tolerance is loose: this is here to catch a
      // transposed matrix, not to certify a decimal.
      final OklabColor r = OklabColor.fromColor(red);
      expect(r.l, closeTo(0.628, 0.01));
      expect(r.a, closeTo(0.225, 0.01));
      expect(r.b, closeTo(0.126, 0.01));

      final OklabColor g = OklabColor.fromColor(green);
      expect(g.l, closeTo(0.866, 0.01));
      expect(g.a, closeTo(-0.234, 0.01));

      final OklabColor b = OklabColor.fromColor(blue);
      expect(b.l, closeTo(0.452, 0.01));
      expect(b.b, closeTo(-0.312, 0.01));
    });

    test('distance is zero to itself and symmetric', () {
      final OklabColor a = OklabColor.fromColor(red);
      final OklabColor b = OklabColor.fromColor(blue);
      expect(a.distanceTo(a), closeTo(0, 0.0001));
      expect(a.distanceTo(b), closeTo(b.distanceTo(a), 0.0001));
    });
  });

  group('the dichromacy matrices transcribe correctly', () {
    // Every row of every matrix must sum to 1, or a neutral would pick up a
    // cast. A transposed digit almost always breaks this, so it is the
    // cheapest available check on the transcription — and it is a property of
    // the published matrices rather than of any value recalled from them.
    test('a neutral grey passes through unchanged', () {
      for (final ColourVisionDeficiency d in ColourVisionDeficiency.values) {
        final Color simulated = ColourVision.simulate(grey, d);
        expect(
          OklabColor.fromColor(simulated)
              .distanceTo(OklabColor.fromColor(grey)),
          lessThan(0.5),
          reason: '${d.name} tinted a neutral, so its rows do not sum to 1',
        );
      }
    });

    test('white and black are fixed points', () {
      // Compared perceptually rather than with `==`: the round trip through
      // linear RGB lands a floating-point hair off, and an exact colour
      // comparison would fail on arithmetic rather than on meaning.
      for (final ColourVisionDeficiency d in ColourVisionDeficiency.values) {
        for (final Color neutral in <Color>[white, black]) {
          expect(
            OklabColor.fromColor(ColourVision.simulate(neutral, d))
                .distanceTo(OklabColor.fromColor(neutral)),
            lessThan(0.5),
            reason: d.name,
          );
        }
      }
    });

    /// How far apart two colours are in hue, optionally as [d] would see them.
    ///
    /// Chromatic rather than total: a dichromacy is defined by losing a colour
    /// axis, and protanopia darkens a saturated red so severely that the two
    /// stay far apart in lightness long after their hues have merged.
    double hueGap(Color a, Color b, [ColourVisionDeficiency? d]) {
      Color seen(Color c) => d == null ? c : ColourVision.simulate(c, d);
      return OklabColor.fromColor(seen(a))
          .chromaticDistanceTo(OklabColor.fromColor(seen(b)));
    }

    test('the red–green axis collapses for both red- and green-blindness', () {
      final double normal = hueGap(red, green);
      for (final ColourVisionDeficiency d in <ColourVisionDeficiency>[
        ColourVisionDeficiency.protanopia,
        ColourVisionDeficiency.deuteranopia,
      ]) {
        final double simulated = hueGap(red, green, d);
        expect(
          simulated,
          lessThan(normal / 3),
          reason: 'red and green are $normal apart in hue and $simulated under '
              '${d.name} — the defining collapse did not happen, so the matrix '
              'is not doing what that eye does',
        );
      }
    });

    test('tritanopia collapses blue against yellow, and spares red', () {
      expect(
        hueGap(blue, yellow, ColourVisionDeficiency.tritanopia),
        lessThan(hueGap(blue, yellow) / 3),
      );
      // The discriminating check: a blue-blind eye still separates red from
      // green. A matrix that collapsed everything would pass the test above
      // and fail this one.
      expect(
        hueGap(red, green, ColourVisionDeficiency.tritanopia),
        greaterThan(hueGap(red, green) / 2),
      );
    });
  });
}
