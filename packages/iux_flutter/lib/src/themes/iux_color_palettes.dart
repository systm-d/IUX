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
      link: IuxPrimitiveColors.accent30,
    ),
    surface: IuxSurfaceColors(
      base: IuxPrimitiveColors.neutral0,
      subtle: IuxPrimitiveColors.neutral5,
      raised: IuxPrimitiveColors.neutral0,
      overlay: IuxPrimitiveColors.neutral0,
      interactive: IuxPrimitiveColors.neutral5,
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
    feedback: IuxFeedbackColorSet(
      info: IuxFeedbackRoleColors(
        content: IuxPrimitiveColors.accent30,
        surface: IuxPrimitiveColors.accent90,
        border: IuxPrimitiveColors.accent40,
        icon: IuxPrimitiveColors.accent30,
      ),
      success: IuxFeedbackRoleColors(
        content: IuxPrimitiveColors.positive30,
        surface: IuxPrimitiveColors.positive90,
        border: IuxPrimitiveColors.positive40,
        icon: IuxPrimitiveColors.positive30,
      ),
      warning: IuxFeedbackRoleColors(
        content: IuxPrimitiveColors.caution30,
        surface: IuxPrimitiveColors.caution90,
        border: IuxPrimitiveColors.caution40,
        icon: IuxPrimitiveColors.caution30,
      ),
      error: IuxFeedbackRoleColors(
        content: IuxPrimitiveColors.critical30,
        surface: IuxPrimitiveColors.critical90,
        border: IuxPrimitiveColors.critical40,
        icon: IuxPrimitiveColors.critical30,
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
      interactive: IuxPrimitiveColors.neutral80,
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
      interactive: IuxPrimitiveColors.neutral10,
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
      interactive: IuxPrimitiveColors.neutral80,
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
