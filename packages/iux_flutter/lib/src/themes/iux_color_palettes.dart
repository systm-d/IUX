import 'package:flutter/foundation.dart';

import '../foundations/iux_foundations.dart';
import '../semantics/colors/iux_action_colors.dart';
import '../semantics/colors/iux_border_colors.dart';
import '../semantics/colors/iux_content_colors.dart';
import '../semantics/colors/iux_feedback_colors.dart';
import '../semantics/colors/iux_primitive_colors.dart';
import '../semantics/colors/iux_state_colors.dart';
import '../semantics/colors/iux_surface_colors.dart';
import '../semantics/iux_semantic_colors.dart';

/// The four role mappings IUX ships, one per usage condition.
///
/// Contrast is combinable with brightness, so high contrast exists for dark as
/// well as light. An engine offering only "high contrast light" would leave a
/// user who needs both without an option.
///
/// Every mapping is `const`: resolving a theme is a table lookup, not a
/// computation, so nothing is generated per frame.
///
/// All pairs are measured in `test/themes/theme_contrast_test.dart`, and the
/// colours a button actually paints are measured again, after resolution, in
/// `test/themes/button_distinguishability_test.dart`. The second file exists
/// because this one was measured and still shipped a role nobody could see:
/// `action.tertiary` differed from `action.secondary` by a single `border`
/// entry that no variant painted, and in two of these four mappings not even
/// by that. Both intents now carry their difference in `foreground`, which
/// every unfilled variant paints — tertiary in the profile's supporting
/// neutral, secondary in the accent. Neither is quieter than the other by
/// contrast; the accent is what one has and the other does not.
@internal
abstract final class IuxColorPalettes {
  /// Returns the mapping for a brightness and contrast combination.
  static IuxSemanticColors resolve(
    Brightness brightness,
    IuxContrast contrast,
  ) =>
      switch ((brightness, contrast)) {
        (Brightness.light, IuxContrast.standard) => light,
        (Brightness.light, IuxContrast.high) => highContrastLight,
        (Brightness.dark, IuxContrast.standard) => dark,
        (Brightness.dark, IuxContrast.high) => highContrastDark,
      };

  /// Standard contrast, light conditions.
  static const IuxSemanticColors light = IuxSemanticColors(
    content: IuxContentColors(
      primary: IuxPrimitiveColors.neutral90,
      secondary: IuxPrimitiveColors.neutral60,
      tertiary: IuxPrimitiveColors.neutral50,
      disabled: IuxPrimitiveColors.neutral45,
      inverse: IuxPrimitiveColors.neutral5,
      onAction: IuxPrimitiveColors.neutral0,
      // One rung lighter than it was, and the reason is the profile below
      // rather than this one. At `accent30` a link measured 9.72:1 on white —
      // past AAA in the *standard* profile — which left `highContrastLight`
      // one rung to distinguish itself with, and made "increase contrast" a
      // setting that returned almost nothing. It also read, to the first user
      // who saw the light theme, as "too dark, dark blue, dark green, dark
      // red, it is too much": four roles darkened until they resembled each
      // other more than they resembled their own meanings.
      //
      // 6.30:1 here. Comfortably past the 4.5:1 AA asks for body text, short
      // of the 7:1 of AAA on purpose, so that the profile whose whole job is
      // contrast has three rungs of headroom instead of one.
      // IUX-PALETTE-HEADROOM-001.
      //
      // It now matches the accent an unfilled *primary* button paints, which
      // is the right neighbour: both are the accent applied to text on the
      // page. `action.secondary.foreground` stays a rung darker and cannot
      // follow — see there.
      link: IuxPrimitiveColors.accent40,
    ),
    surface: IuxSurfaceColors(
      base: IuxPrimitiveColors.neutral0,
      subtle: IuxPrimitiveColors.neutral5,
      raised: IuxPrimitiveColors.neutral0,
      overlay: IuxPrimitiveColors.neutral0,
      // Two rungs below `subtle`, and that gap is the whole point: this used
      // to be `neutral5` as well, so a filled editable field and a read-only
      // one were the same colour (IUX-SURFACE-001). `neutral10` is taken by
      // `disabled`, so `neutral20` is the first step that separates from both
      // while keeping the value at 13.17:1, the supporting content at 5.76:1
      // and the outline at 3.60:1 on the fill itself.
      interactive: IuxPrimitiveColors.neutral20,
      selected: IuxPrimitiveColors.accent90,
      disabled: IuxPrimitiveColors.neutral10,
      inverse: IuxPrimitiveColors.neutral95,
    ),
    border: IuxBorderColors(
      standard: IuxPrimitiveColors.neutral45,
      subtle: IuxPrimitiveColors.neutral20,
      strong: IuxPrimitiveColors.neutral60,
      interactive: IuxPrimitiveColors.neutral50,
      focus: IuxPrimitiveColors.accent40,
      selected: IuxPrimitiveColors.accent40,
      disabled: IuxPrimitiveColors.neutral30,
      error: IuxPrimitiveColors.critical40,
    ),
    action: IuxActionColorSet(
      primary: IuxActionColors(
        foreground: IuxPrimitiveColors.neutral0,
        background: IuxPrimitiveColors.accent40,
        hoveredBackground: IuxPrimitiveColors.accent30,
        pressedBackground: IuxPrimitiveColors.accent20,
        disabledForeground: IuxPrimitiveColors.neutral45,
        disabledBackground: IuxPrimitiveColors.neutral10,
      ),
      secondary: IuxActionColors(
        // Stays at `accent30` while `content.link` moves to `accent40`, and
        // that is forced rather than chosen. On every unfilled variant this
        // colour *is* the intent — `IuxButtonThemeResolver` derives primary's
        // accent from `action.primary.background`, which is `accent40`, and
        // secondary's from this field. Moving it here makes an outlined,
        // tonal, text or icon secondary byte-identical to the same primary,
        // which `button_distinguishability_test.dart` catches immediately:
        // twelve collisions, measured. The two intents have to differ by
        // something, and the palette has already spent every other axis.
        foreground: IuxPrimitiveColors.accent30,
        background: IuxPrimitiveColors.neutral0,
        hoveredBackground: IuxPrimitiveColors.neutral5,
        pressedBackground: IuxPrimitiveColors.neutral10,
        disabledForeground: IuxPrimitiveColors.neutral45,
        disabledBackground: IuxPrimitiveColors.neutral10,
      ),
      tertiary: IuxActionColors(
        foreground: IuxPrimitiveColors.neutral60,
        background: IuxPrimitiveColors.neutral0,
        hoveredBackground: IuxPrimitiveColors.neutral5,
        pressedBackground: IuxPrimitiveColors.neutral10,
        disabledForeground: IuxPrimitiveColors.neutral45,
        disabledBackground: IuxPrimitiveColors.neutral10,
      ),
      destructive: IuxActionColors(
        foreground: IuxPrimitiveColors.neutral0,
        background: IuxPrimitiveColors.critical40,
        hoveredBackground: IuxPrimitiveColors.critical30,
        pressedBackground: IuxPrimitiveColors.critical20,
        disabledForeground: IuxPrimitiveColors.neutral45,
        disabledBackground: IuxPrimitiveColors.neutral10,
      ),
    ),
    // Every content and icon role here is one rung lighter than it was, for
    // the reason `content.link` records: at level 30 all four measured between
    // 9.16:1 and 9.72:1 on white, so the standard profile was already past AAA
    // and `highContrastLight` — which sits at level 10 — had nothing left to
    // add that a user would notice. Level 40 measures 5.21:1 to 5.86:1 on the
    // tinted surface each one sits on, and 5.94:1 to 6.81:1 on the base.
    //
    // The borders stay where they are. They now match their own content
    // colour, which is what a tinted panel wants: one hue, one weight, and the
    // 3:1 SC 1.4.11 asks of an outline still measured on the base surface.
    feedback: IuxFeedbackColorSet(
      info: IuxFeedbackRoleColors(
        content: IuxPrimitiveColors.accent40,
        surface: IuxPrimitiveColors.accent90,
        border: IuxPrimitiveColors.accent40,
        icon: IuxPrimitiveColors.accent40,
      ),
      success: IuxFeedbackRoleColors(
        content: IuxPrimitiveColors.positive40,
        surface: IuxPrimitiveColors.positive90,
        border: IuxPrimitiveColors.positive40,
        icon: IuxPrimitiveColors.positive40,
      ),
      // The one role where a rung was not enough. Held above 4.5:1 on white a
      // yellow stops being a yellow: `caution30` and `caution40` used to be
      // `#5E3F00` and `#7D5400`, which read as khaki browns rather than as a
      // warning, and a consuming application had to leave the ramp to get one
      // anybody recognised. The dark end of the caution ramp is now orange —
      // see `IuxPrimitiveColors` for why the ramp bends and the light end does
      // not. `#A34A00`, 5.94:1 on white and 5.20:1 on `caution90`.
      warning: IuxFeedbackRoleColors(
        content: IuxPrimitiveColors.caution40,
        surface: IuxPrimitiveColors.caution90,
        border: IuxPrimitiveColors.caution40,
        icon: IuxPrimitiveColors.caution40,
      ),
      error: IuxFeedbackRoleColors(
        content: IuxPrimitiveColors.critical40,
        surface: IuxPrimitiveColors.critical90,
        border: IuxPrimitiveColors.critical40,
        icon: IuxPrimitiveColors.critical40,
      ),
    ),
    state: IuxStateColors(
      focus: IuxPrimitiveColors.accent40,
      selected: IuxPrimitiveColors.accent40,
      hovered: IuxPrimitiveColors.neutral5,
      pressed: IuxPrimitiveColors.neutral10,
      dragged: IuxPrimitiveColors.neutral20,
    ),
  );

  /// Standard contrast, dark conditions.
  ///
  /// The base surface is not pure black. A fully black background removes the
  /// ability to express elevation through surface contrast, which is the only
  /// elevation signal that survives in dark conditions.
  static const IuxSemanticColors dark = IuxSemanticColors(
    content: IuxContentColors(
      primary: IuxPrimitiveColors.neutral5,
      secondary: IuxPrimitiveColors.neutral30,
      tertiary: IuxPrimitiveColors.neutral40,
      disabled: IuxPrimitiveColors.neutral50,
      inverse: IuxPrimitiveColors.neutral90,
      onAction: IuxPrimitiveColors.neutral95,
      link: IuxPrimitiveColors.accent70,
    ),
    surface: IuxSurfaceColors(
      base: IuxPrimitiveColors.neutral90,
      subtle: IuxPrimitiveColors.neutral80,
      raised: IuxPrimitiveColors.neutral70,
      overlay: IuxPrimitiveColors.neutral80,
      // Darker than the page rather than lighter, which is the opposite
      // direction from every other surface here and is forced by measurement
      // rather than chosen for looks. `neutral80` is `subtle`, `disabled` and
      // `state.hovered` all at once, and the only lighter step left,
      // `neutral70`, drops `border.interactive` to 2.36:1 on the fill — below
      // the 3:1 an outline owes under SC 1.4.11. Descending to `neutral95`
      // keeps the outline at 3.96:1 and the value at 17.63:1, and reads as a
      // well cut into the page, which is what a field is.
      interactive: IuxPrimitiveColors.neutral95,
      selected: IuxPrimitiveColors.accent20,
      disabled: IuxPrimitiveColors.neutral80,
      inverse: IuxPrimitiveColors.neutral5,
    ),
    border: IuxBorderColors(
      standard: IuxPrimitiveColors.neutral50,
      subtle: IuxPrimitiveColors.neutral70,
      strong: IuxPrimitiveColors.neutral40,
      interactive: IuxPrimitiveColors.neutral50,
      focus: IuxPrimitiveColors.accent70,
      selected: IuxPrimitiveColors.accent70,
      disabled: IuxPrimitiveColors.neutral70,
      error: IuxPrimitiveColors.critical70,
    ),
    action: IuxActionColorSet(
      primary: IuxActionColors(
        foreground: IuxPrimitiveColors.neutral95,
        background: IuxPrimitiveColors.accent70,
        hoveredBackground: IuxPrimitiveColors.accent80,
        pressedBackground: IuxPrimitiveColors.accent90,
        disabledForeground: IuxPrimitiveColors.neutral50,
        disabledBackground: IuxPrimitiveColors.neutral80,
      ),
      secondary: IuxActionColors(
        foreground: IuxPrimitiveColors.accent80,
        background: IuxPrimitiveColors.neutral90,
        hoveredBackground: IuxPrimitiveColors.neutral80,
        pressedBackground: IuxPrimitiveColors.neutral70,
        disabledForeground: IuxPrimitiveColors.neutral50,
        disabledBackground: IuxPrimitiveColors.neutral80,
      ),
      tertiary: IuxActionColors(
        foreground: IuxPrimitiveColors.neutral30,
        background: IuxPrimitiveColors.neutral90,
        hoveredBackground: IuxPrimitiveColors.neutral80,
        pressedBackground: IuxPrimitiveColors.neutral70,
        disabledForeground: IuxPrimitiveColors.neutral50,
        disabledBackground: IuxPrimitiveColors.neutral80,
      ),
      destructive: IuxActionColors(
        foreground: IuxPrimitiveColors.neutral95,
        background: IuxPrimitiveColors.critical70,
        hoveredBackground: IuxPrimitiveColors.critical80,
        pressedBackground: IuxPrimitiveColors.critical90,
        disabledForeground: IuxPrimitiveColors.neutral50,
        disabledBackground: IuxPrimitiveColors.neutral80,
      ),
    ),
    feedback: IuxFeedbackColorSet(
      info: IuxFeedbackRoleColors(
        content: IuxPrimitiveColors.accent70,
        surface: IuxPrimitiveColors.neutral80,
        border: IuxPrimitiveColors.accent70,
        icon: IuxPrimitiveColors.accent70,
      ),
      success: IuxFeedbackRoleColors(
        content: IuxPrimitiveColors.positive70,
        surface: IuxPrimitiveColors.neutral80,
        border: IuxPrimitiveColors.positive70,
        icon: IuxPrimitiveColors.positive70,
      ),
      warning: IuxFeedbackRoleColors(
        content: IuxPrimitiveColors.caution70,
        surface: IuxPrimitiveColors.neutral80,
        border: IuxPrimitiveColors.caution70,
        icon: IuxPrimitiveColors.caution70,
      ),
      error: IuxFeedbackRoleColors(
        content: IuxPrimitiveColors.critical70,
        surface: IuxPrimitiveColors.neutral80,
        border: IuxPrimitiveColors.critical70,
        icon: IuxPrimitiveColors.critical70,
      ),
    ),
    state: IuxStateColors(
      focus: IuxPrimitiveColors.accent70,
      selected: IuxPrimitiveColors.accent70,
      hovered: IuxPrimitiveColors.neutral80,
      pressed: IuxPrimitiveColors.neutral70,
      dragged: IuxPrimitiveColors.neutral60,
    ),
  );

  /// High contrast, light conditions.
  ///
  /// High contrast does not raise every value uniformly. It targets what
  /// carries meaning — content, borders that identify a control, focus and
  /// engagement states — while leaving decorative separation alone, so the
  /// interface gains legibility without becoming a grid of hard lines.
  ///
  /// Only one intent may reach for the neutral extreme when it is engaged.
  /// Both accent ramps are compressed here, so a third engaged step has to
  /// come from somewhere, and this mapping used to take it from black for
  /// primary *and* destructive — which made a pressed "Delete" byte-identical
  /// to a pressed "Save" in the profile whose whole purpose is separation, and
  /// at the one moment the user commits. Primary keeps the extreme; destructive
  /// stays inside its own hue, one rung lighter at rest so it has two steps to
  /// deepen through. It gives up a little contrast at rest — 9.69:1 rather
  /// than 13.76:1, both far above the 4.5:1 required — and keeps being red
  /// when it matters.
  static const IuxSemanticColors highContrastLight = IuxSemanticColors(
    content: IuxContentColors(
      primary: IuxPrimitiveColors.neutral100,
      secondary: IuxPrimitiveColors.neutral80,
      tertiary: IuxPrimitiveColors.neutral70,
      disabled: IuxPrimitiveColors.neutral60,
      inverse: IuxPrimitiveColors.neutral0,
      onAction: IuxPrimitiveColors.neutral0,
      link: IuxPrimitiveColors.accent20,
    ),
    surface: IuxSurfaceColors(
      base: IuxPrimitiveColors.neutral0,
      subtle: IuxPrimitiveColors.neutral10,
      raised: IuxPrimitiveColors.neutral0,
      overlay: IuxPrimitiveColors.neutral0,
      // `neutral10` is `subtle` and `neutral20` is `disabled`, so the first
      // step that separates from both is `neutral30`. High contrast can afford
      // it: the value measures 12.23:1 there and the outline 8.61:1.
      interactive: IuxPrimitiveColors.neutral30,
      selected: IuxPrimitiveColors.accent90,
      disabled: IuxPrimitiveColors.neutral20,
      inverse: IuxPrimitiveColors.neutral100,
    ),
    border: IuxBorderColors(
      standard: IuxPrimitiveColors.neutral80,
      subtle: IuxPrimitiveColors.neutral50,
      strong: IuxPrimitiveColors.neutral100,
      interactive: IuxPrimitiveColors.neutral80,
      focus: IuxPrimitiveColors.accent20,
      selected: IuxPrimitiveColors.accent20,
      disabled: IuxPrimitiveColors.neutral50,
      error: IuxPrimitiveColors.critical20,
    ),
    action: IuxActionColorSet(
      primary: IuxActionColors(
        foreground: IuxPrimitiveColors.neutral0,
        background: IuxPrimitiveColors.accent20,
        hoveredBackground: IuxPrimitiveColors.accent10,
        pressedBackground: IuxPrimitiveColors.neutral100,
        disabledForeground: IuxPrimitiveColors.neutral60,
        disabledBackground: IuxPrimitiveColors.neutral20,
      ),
      secondary: IuxActionColors(
        foreground: IuxPrimitiveColors.accent10,
        background: IuxPrimitiveColors.neutral0,
        hoveredBackground: IuxPrimitiveColors.neutral10,
        pressedBackground: IuxPrimitiveColors.neutral20,
        disabledForeground: IuxPrimitiveColors.neutral60,
        disabledBackground: IuxPrimitiveColors.neutral20,
      ),
      tertiary: IuxActionColors(
        foreground: IuxPrimitiveColors.neutral80,
        background: IuxPrimitiveColors.neutral0,
        hoveredBackground: IuxPrimitiveColors.neutral10,
        pressedBackground: IuxPrimitiveColors.neutral20,
        disabledForeground: IuxPrimitiveColors.neutral60,
        disabledBackground: IuxPrimitiveColors.neutral20,
      ),
      destructive: IuxActionColors(
        foreground: IuxPrimitiveColors.neutral0,
        background: IuxPrimitiveColors.critical30,
        hoveredBackground: IuxPrimitiveColors.critical20,
        pressedBackground: IuxPrimitiveColors.critical10,
        disabledForeground: IuxPrimitiveColors.neutral60,
        disabledBackground: IuxPrimitiveColors.neutral20,
      ),
    ),
    feedback: IuxFeedbackColorSet(
      info: IuxFeedbackRoleColors(
        content: IuxPrimitiveColors.accent10,
        surface: IuxPrimitiveColors.accent90,
        border: IuxPrimitiveColors.accent20,
        icon: IuxPrimitiveColors.accent10,
      ),
      success: IuxFeedbackRoleColors(
        content: IuxPrimitiveColors.positive10,
        surface: IuxPrimitiveColors.positive90,
        border: IuxPrimitiveColors.positive20,
        icon: IuxPrimitiveColors.positive10,
      ),
      warning: IuxFeedbackRoleColors(
        content: IuxPrimitiveColors.caution10,
        surface: IuxPrimitiveColors.caution90,
        border: IuxPrimitiveColors.caution20,
        icon: IuxPrimitiveColors.caution10,
      ),
      error: IuxFeedbackRoleColors(
        content: IuxPrimitiveColors.critical10,
        surface: IuxPrimitiveColors.critical90,
        border: IuxPrimitiveColors.critical20,
        icon: IuxPrimitiveColors.critical10,
      ),
    ),
    state: IuxStateColors(
      focus: IuxPrimitiveColors.accent20,
      selected: IuxPrimitiveColors.accent20,
      hovered: IuxPrimitiveColors.neutral10,
      pressed: IuxPrimitiveColors.neutral20,
      dragged: IuxPrimitiveColors.neutral30,
    ),
  );

  /// High contrast, dark conditions.
  ///
  /// The base is near-black rather than pure black, for the same reason as the
  /// standard dark mapping: surface contrast remains the only usable elevation
  /// signal, and pure black leaves nothing to descend from.
  ///
  /// Destructive brightens within its own hue instead of ending at white, for
  /// the reason given on [highContrastLight]: two intents that both reach for
  /// the neutral extreme when pressed are one intent.
  static const IuxSemanticColors highContrastDark = IuxSemanticColors(
    content: IuxContentColors(
      primary: IuxPrimitiveColors.neutral0,
      secondary: IuxPrimitiveColors.neutral20,
      tertiary: IuxPrimitiveColors.neutral30,
      disabled: IuxPrimitiveColors.neutral40,
      inverse: IuxPrimitiveColors.neutral95,
      onAction: IuxPrimitiveColors.neutral95,
      link: IuxPrimitiveColors.accent80,
    ),
    surface: IuxSurfaceColors(
      base: IuxPrimitiveColors.neutral95,
      subtle: IuxPrimitiveColors.neutral80,
      raised: IuxPrimitiveColors.neutral70,
      overlay: IuxPrimitiveColors.neutral80,
      // Below the page, for the reason given on [dark], and one rung further
      // because the page here is already `neutral95`. `neutral80` is `subtle`
      // and `neutral70` is `disabled`, so descending is the only direction
      // left; it puts the value at 21:1 and the outline at 12.23:1.
      interactive: IuxPrimitiveColors.neutral100,
      selected: IuxPrimitiveColors.accent20,
      disabled: IuxPrimitiveColors.neutral70,
      inverse: IuxPrimitiveColors.neutral0,
    ),
    border: IuxBorderColors(
      standard: IuxPrimitiveColors.neutral30,
      subtle: IuxPrimitiveColors.neutral60,
      strong: IuxPrimitiveColors.neutral0,
      interactive: IuxPrimitiveColors.neutral30,
      focus: IuxPrimitiveColors.accent80,
      selected: IuxPrimitiveColors.accent80,
      disabled: IuxPrimitiveColors.neutral60,
      error: IuxPrimitiveColors.critical80,
    ),
    action: IuxActionColorSet(
      primary: IuxActionColors(
        foreground: IuxPrimitiveColors.neutral95,
        background: IuxPrimitiveColors.accent80,
        hoveredBackground: IuxPrimitiveColors.accent90,
        pressedBackground: IuxPrimitiveColors.neutral0,
        disabledForeground: IuxPrimitiveColors.neutral40,
        disabledBackground: IuxPrimitiveColors.neutral70,
      ),
      secondary: IuxActionColors(
        foreground: IuxPrimitiveColors.accent90,
        background: IuxPrimitiveColors.neutral95,
        hoveredBackground: IuxPrimitiveColors.neutral80,
        pressedBackground: IuxPrimitiveColors.neutral70,
        disabledForeground: IuxPrimitiveColors.neutral40,
        disabledBackground: IuxPrimitiveColors.neutral70,
      ),
      tertiary: IuxActionColors(
        foreground: IuxPrimitiveColors.neutral20,
        background: IuxPrimitiveColors.neutral95,
        hoveredBackground: IuxPrimitiveColors.neutral80,
        pressedBackground: IuxPrimitiveColors.neutral70,
        disabledForeground: IuxPrimitiveColors.neutral40,
        disabledBackground: IuxPrimitiveColors.neutral70,
      ),
      destructive: IuxActionColors(
        foreground: IuxPrimitiveColors.neutral95,
        background: IuxPrimitiveColors.critical70,
        hoveredBackground: IuxPrimitiveColors.critical80,
        pressedBackground: IuxPrimitiveColors.critical90,
        disabledForeground: IuxPrimitiveColors.neutral40,
        disabledBackground: IuxPrimitiveColors.neutral70,
      ),
    ),
    feedback: IuxFeedbackColorSet(
      info: IuxFeedbackRoleColors(
        content: IuxPrimitiveColors.accent80,
        surface: IuxPrimitiveColors.neutral80,
        border: IuxPrimitiveColors.accent80,
        icon: IuxPrimitiveColors.accent80,
      ),
      success: IuxFeedbackRoleColors(
        content: IuxPrimitiveColors.positive80,
        surface: IuxPrimitiveColors.neutral80,
        border: IuxPrimitiveColors.positive80,
        icon: IuxPrimitiveColors.positive80,
      ),
      warning: IuxFeedbackRoleColors(
        content: IuxPrimitiveColors.caution80,
        surface: IuxPrimitiveColors.neutral80,
        border: IuxPrimitiveColors.caution80,
        icon: IuxPrimitiveColors.caution80,
      ),
      error: IuxFeedbackRoleColors(
        content: IuxPrimitiveColors.critical80,
        surface: IuxPrimitiveColors.neutral80,
        border: IuxPrimitiveColors.critical80,
        icon: IuxPrimitiveColors.critical80,
      ),
    ),
    state: IuxStateColors(
      focus: IuxPrimitiveColors.accent80,
      selected: IuxPrimitiveColors.accent80,
      hovered: IuxPrimitiveColors.neutral80,
      pressed: IuxPrimitiveColors.neutral70,
      dragged: IuxPrimitiveColors.neutral60,
    ),
  );
}
