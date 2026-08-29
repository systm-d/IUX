import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iux_flutter/iux_flutter.dart';
import 'package:iux_flutter/src/accessibility/iux_category_glyphs.dart';

/// The channel that works when the colour channel does not.
///
/// `IUX-PALETTE-PERCEPTION-001` measured the four `feedback.content` colours
/// under simulated dichromacy and found `success` and `error` **0.4 apart** in
/// the dark high contrast profile — the same colour, under the most common
/// dichromacy, for the pair whose confusion costs the most. Every profile has
/// at least one pair below the threshold at which two colours are told apart.
///
/// That makes the glyph load-bearing rather than reinforcing, and this file
/// holds the two properties a unit test can actually establish about it: that
/// the four shapes are four, and that the two components drawing them agree.
///
/// **What it cannot establish is whether they read as four shapes to a
/// person.** Icons render here through a substitute font in which every glyph
/// is an identical square — this library once shipped with no icons at all for
/// weeks while the whole suite passed. The silhouettes are confirmed on a
/// device, under `IUX-MANUAL-001`.
void main() {
  test('the four categories are four shapes', () {
    expect(
      IuxCategoryGlyphs.all.toSet(),
      hasLength(IuxCategoryGlyphs.all.length),
      reason: 'two categories share a glyph, which leaves them separated by '
          'colour alone — and the measurement says colour does not separate '
          'them',
    );
  });

  test('error does not wear the shape of the category it is confused with', () {
    // The specific regression this set was changed to fix, asserted as itself
    // rather than left to the distinctness check above — which `error_outline`
    // passed, being a different code point from `check_circle_outline` while
    // being the same silhouette.
    //
    // A circled "!" is the obvious glyph for an error and was the one in place.
    // It put `error` in a family of three circles, opposite `success`, and the
    // measurement says those two are the pair with no colour left between them.
    expect(
      IuxCategoryGlyphs.error,
      isNot(Icons.error_outline),
      reason: 'error is back to a circle, which is the shape family success '
          'and info are already in. See IuxCategoryGlyphs for why that is the '
          'one family it cannot be in.',
    );
    expect(IuxCategoryGlyphs.error, Icons.report_outlined);
  });

  test('the two components that draw a category agree about its shape', () {
    // They had separate maps that happened to agree, held together by nothing.
    // The first edit to one would have made the same category two shapes
    // depending on which component the user met it in — and because both maps
    // were internally consistent, both components' own tests would still have
    // passed.
    const Map<IuxStatusTone, IconData> expected = <IuxStatusTone, IconData>{
      IuxStatusTone.neutral: IuxCategoryGlyphs.info,
      IuxStatusTone.success: IuxCategoryGlyphs.success,
      IuxStatusTone.warning: IuxCategoryGlyphs.warning,
      IuxStatusTone.error: IuxCategoryGlyphs.error,
    };

    for (final IuxStatusTone tone in IuxStatusTone.values) {
      expect(
        IuxStatusResolver.glyph(tone),
        expected[tone],
        reason: 'IuxStatusIndicator draws ${tone.name} with a shape the shared '
            'definition does not name',
      );
    }
  });

  testWidgets('inline feedback draws the shared shapes too', (tester) async {
    // Reached through the resolver rather than the constant, so this fails if
    // the component stops consulting the shared definition at all.
    final Map<IuxFeedbackCategory, IconData> drawn =
        <IuxFeedbackCategory, IconData>{};
    await tester.pumpWidget(
      MaterialApp(
        theme: IuxTheme.fromConfiguration(const IuxThemeConfiguration()),
        home: Builder(
          builder: (BuildContext context) {
            for (final IuxFeedbackCategory category
                in IuxFeedbackCategory.values) {
              drawn[category] =
                  IuxInlineFeedbackResolver.resolve(context, category).glyph;
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(drawn[IuxFeedbackCategory.info], IuxCategoryGlyphs.info);
    expect(drawn[IuxFeedbackCategory.success], IuxCategoryGlyphs.success);
    expect(drawn[IuxFeedbackCategory.warning], IuxCategoryGlyphs.warning);
    expect(drawn[IuxFeedbackCategory.error], IuxCategoryGlyphs.error);
  });

  testWidgets('the transient layer draws the same success shape', (
    tester,
  ) async {
    // A third component drawing one of the four. `IuxTransientTone` has only
    // `neutral` and `success` — nothing under a timer may be an error or a
    // warning — so it takes one glyph from the set, and it is the one whose
    // colour is measured closest to error's.
    IconData? glyph;
    await tester.pumpWidget(
      MaterialApp(
        theme: IuxTheme.fromConfiguration(const IuxThemeConfiguration()),
        home: Builder(
          builder: (BuildContext context) {
            glyph = IuxTransientResolver.resolve(
              context,
              IuxTransientTone.success,
            ).glyph;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(glyph, IuxCategoryGlyphs.success);
  });

  test('the resting category is the same shape under both names', () {
    // `IuxStatusTone.neutral` and `IuxFeedbackCategory.info` are the same
    // category named twice. A reader meeting an "i" in a status chip and an "i"
    // in a banner should be meeting one idea, and the two enums existing is not
    // a reason for them to diverge.
    expect(
      IuxStatusResolver.glyph(IuxStatusTone.neutral),
      IuxCategoryGlyphs.info,
    );
  });
}
