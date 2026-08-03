import 'package:iux_flutter/iux_flutter.dart';
import 'package:iux_flutter/src/semantics/colors/iux_primitive_colors.dart';

/// Temporary role mappings used to exercise the semantic layer.
///
/// These are demonstrations, not themes. They exist so the contrast contracts
/// can be tested against real values before IUX-004 builds the theme engine,
/// and they are not exported from the package. IUX-004 replaces them with
/// resolved themes; this file is expected to disappear then.
abstract final class IuxDemonstrationPalettes {
  /// A light role mapping satisfying the documented contrast contracts.
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
        border: IuxPrimitiveColors.accent40,
        hoveredBackground: IuxPrimitiveColors.accent30,
        pressedBackground: IuxPrimitiveColors.accent20,
        disabledForeground: IuxPrimitiveColors.neutral45,
        disabledBackground: IuxPrimitiveColors.neutral10,
      ),
      secondary: IuxActionColors(
        foreground: IuxPrimitiveColors.accent30,
        background: IuxPrimitiveColors.neutral0,
        border: IuxPrimitiveColors.neutral45,
        hoveredBackground: IuxPrimitiveColors.neutral5,
        pressedBackground: IuxPrimitiveColors.neutral10,
        disabledForeground: IuxPrimitiveColors.neutral45,
        disabledBackground: IuxPrimitiveColors.neutral10,
      ),
      tertiary: IuxActionColors(
        foreground: IuxPrimitiveColors.accent30,
        background: IuxPrimitiveColors.neutral0,
        border: IuxPrimitiveColors.neutral0,
        hoveredBackground: IuxPrimitiveColors.neutral5,
        pressedBackground: IuxPrimitiveColors.neutral10,
        disabledForeground: IuxPrimitiveColors.neutral45,
        disabledBackground: IuxPrimitiveColors.neutral10,
      ),
      destructive: IuxActionColors(
        foreground: IuxPrimitiveColors.neutral0,
        background: IuxPrimitiveColors.critical40,
        border: IuxPrimitiveColors.critical40,
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

  /// A dark role mapping satisfying the documented contrast contracts.
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
        border: IuxPrimitiveColors.accent70,
        hoveredBackground: IuxPrimitiveColors.accent80,
        pressedBackground: IuxPrimitiveColors.accent90,
        disabledForeground: IuxPrimitiveColors.neutral50,
        disabledBackground: IuxPrimitiveColors.neutral80,
      ),
      secondary: IuxActionColors(
        foreground: IuxPrimitiveColors.accent70,
        background: IuxPrimitiveColors.neutral90,
        border: IuxPrimitiveColors.neutral50,
        hoveredBackground: IuxPrimitiveColors.neutral80,
        pressedBackground: IuxPrimitiveColors.neutral70,
        disabledForeground: IuxPrimitiveColors.neutral50,
        disabledBackground: IuxPrimitiveColors.neutral80,
      ),
      tertiary: IuxActionColors(
        foreground: IuxPrimitiveColors.accent70,
        background: IuxPrimitiveColors.neutral90,
        border: IuxPrimitiveColors.neutral90,
        hoveredBackground: IuxPrimitiveColors.neutral80,
        pressedBackground: IuxPrimitiveColors.neutral70,
        disabledForeground: IuxPrimitiveColors.neutral50,
        disabledBackground: IuxPrimitiveColors.neutral80,
      ),
      destructive: IuxActionColors(
        foreground: IuxPrimitiveColors.neutral95,
        background: IuxPrimitiveColors.critical70,
        border: IuxPrimitiveColors.critical70,
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
}
