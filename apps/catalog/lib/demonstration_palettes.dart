import 'package:flutter/material.dart';
import 'package:iux_flutter/iux_flutter.dart';

/// Temporary role mappings used by the catalog to visualise semantic roles.
///
/// These are demonstrations, not themes, and not part of the IUX API. The
/// package deliberately exports no palette: until IUX-004 delivers the theme
/// engine, a consumer supplies its own values, which is exactly what the
/// catalog does here. This file is expected to disappear at that point.
///
/// The values mirror the ones the package tests measure, so what the catalog
/// shows is what the contrast contracts assert.
abstract final class CatalogPalettes {
  static const Color _neutral0 = Color(0xFFFFFFFF);
  static const Color _neutral5 = Color(0xFFF6F7F9);
  static const Color _neutral10 = Color(0xFFECEEF2);
  static const Color _neutral20 = Color(0xFFDCE0E7);
  static const Color _neutral30 = Color(0xFFC0C6D0);
  static const Color _neutral40 = Color(0xFF98A0AE);
  static const Color _neutral45 = Color(0xFF7E8693);
  static const Color _neutral50 = Color(0xFF6B7382);
  static const Color _neutral60 = Color(0xFF4C5462);
  static const Color _neutral70 = Color(0xFF343B47);
  static const Color _neutral80 = Color(0xFF222834);
  static const Color _neutral90 = Color(0xFF151A23);
  static const Color _neutral95 = Color(0xFF0D1119);

  static const Color _accent20 = Color(0xFF0A2C63);
  static const Color _accent30 = Color(0xFF0F4289);
  static const Color _accent40 = Color(0xFF1560B0);
  static const Color _accent70 = Color(0xFF8FBEEF);
  static const Color _accent80 = Color(0xFFBAD8F7);
  static const Color _accent90 = Color(0xFFDDEBFB);

  static const Color _critical20 = Color(0xFF5E0A0E);
  static const Color _critical30 = Color(0xFF8A1017);
  static const Color _critical40 = Color(0xFFB41720);
  static const Color _critical70 = Color(0xFFF29A9E);
  static const Color _critical80 = Color(0xFFF8C6C8);
  static const Color _critical90 = Color(0xFFFBE3E4);

  static const Color _positive30 = Color(0xFF0A5330);
  static const Color _positive40 = Color(0xFF0F6E41);
  static const Color _positive70 = Color(0xFF7FC9A2);
  static const Color _positive90 = Color(0xFFDDF2E7);

  static const Color _caution30 = Color(0xFF5E3F00);
  static const Color _caution40 = Color(0xFF7D5400);
  static const Color _caution70 = Color(0xFFEEBB3E);
  static const Color _caution90 = Color(0xFFFCEFCF);

  /// A light role mapping.
  static const IuxSemanticColors light = IuxSemanticColors(
    content: IuxContentColors(
      primary: _neutral90,
      secondary: _neutral60,
      tertiary: _neutral50,
      disabled: _neutral45,
      inverse: _neutral5,
      onAction: _neutral0,
      link: _accent30,
    ),
    surface: IuxSurfaceColors(
      base: _neutral0,
      subtle: _neutral5,
      raised: _neutral0,
      overlay: _neutral0,
      interactive: _neutral5,
      selected: _accent90,
      disabled: _neutral10,
      inverse: _neutral95,
    ),
    border: IuxBorderColors(
      standard: _neutral45,
      subtle: _neutral20,
      strong: _neutral60,
      interactive: _neutral50,
      focus: _accent40,
      selected: _accent40,
      disabled: _neutral30,
      error: _critical40,
    ),
    action: IuxActionColorSet(
      primary: IuxActionColors(
        foreground: _neutral0,
        background: _accent40,
        border: _accent40,
        hoveredBackground: _accent30,
        pressedBackground: _accent20,
        disabledForeground: _neutral45,
        disabledBackground: _neutral10,
      ),
      secondary: IuxActionColors(
        foreground: _accent30,
        background: _neutral0,
        border: _neutral45,
        hoveredBackground: _neutral5,
        pressedBackground: _neutral10,
        disabledForeground: _neutral45,
        disabledBackground: _neutral10,
      ),
      tertiary: IuxActionColors(
        foreground: _accent30,
        background: _neutral0,
        border: _neutral0,
        hoveredBackground: _neutral5,
        pressedBackground: _neutral10,
        disabledForeground: _neutral45,
        disabledBackground: _neutral10,
      ),
      destructive: IuxActionColors(
        foreground: _neutral0,
        background: _critical40,
        border: _critical40,
        hoveredBackground: _critical30,
        pressedBackground: _critical20,
        disabledForeground: _neutral45,
        disabledBackground: _neutral10,
      ),
    ),
    feedback: IuxFeedbackColorSet(
      info: IuxFeedbackRoleColors(
        content: _accent30,
        surface: _accent90,
        border: _accent40,
        icon: _accent30,
      ),
      success: IuxFeedbackRoleColors(
        content: _positive30,
        surface: _positive90,
        border: _positive40,
        icon: _positive30,
      ),
      warning: IuxFeedbackRoleColors(
        content: _caution30,
        surface: _caution90,
        border: _caution40,
        icon: _caution30,
      ),
      error: IuxFeedbackRoleColors(
        content: _critical30,
        surface: _critical90,
        border: _critical40,
        icon: _critical30,
      ),
    ),
    state: IuxStateColors(
      focus: _accent40,
      selected: _accent40,
      hovered: _neutral5,
      pressed: _neutral10,
      dragged: _neutral20,
    ),
  );

  /// A dark role mapping.
  static const IuxSemanticColors dark = IuxSemanticColors(
    content: IuxContentColors(
      primary: _neutral5,
      secondary: _neutral30,
      tertiary: _neutral40,
      disabled: _neutral50,
      inverse: _neutral90,
      onAction: _neutral95,
      link: _accent70,
    ),
    surface: IuxSurfaceColors(
      base: _neutral90,
      subtle: _neutral80,
      raised: _neutral70,
      overlay: _neutral80,
      interactive: _neutral80,
      selected: _accent20,
      disabled: _neutral80,
      inverse: _neutral5,
    ),
    border: IuxBorderColors(
      standard: _neutral50,
      subtle: _neutral70,
      strong: _neutral40,
      interactive: _neutral50,
      focus: _accent70,
      selected: _accent70,
      disabled: _neutral70,
      error: _critical70,
    ),
    action: IuxActionColorSet(
      primary: IuxActionColors(
        foreground: _neutral95,
        background: _accent70,
        border: _accent70,
        hoveredBackground: _accent80,
        pressedBackground: _accent90,
        disabledForeground: _neutral50,
        disabledBackground: _neutral80,
      ),
      secondary: IuxActionColors(
        foreground: _accent70,
        background: _neutral90,
        border: _neutral50,
        hoveredBackground: _neutral80,
        pressedBackground: _neutral70,
        disabledForeground: _neutral50,
        disabledBackground: _neutral80,
      ),
      tertiary: IuxActionColors(
        foreground: _accent70,
        background: _neutral90,
        border: _neutral90,
        hoveredBackground: _neutral80,
        pressedBackground: _neutral70,
        disabledForeground: _neutral50,
        disabledBackground: _neutral80,
      ),
      destructive: IuxActionColors(
        foreground: _neutral95,
        background: _critical70,
        border: _critical70,
        hoveredBackground: _critical80,
        pressedBackground: _critical90,
        disabledForeground: _neutral50,
        disabledBackground: _neutral80,
      ),
    ),
    feedback: IuxFeedbackColorSet(
      info: IuxFeedbackRoleColors(
        content: _accent70,
        surface: _neutral80,
        border: _accent70,
        icon: _accent70,
      ),
      success: IuxFeedbackRoleColors(
        content: _positive70,
        surface: _neutral80,
        border: _positive70,
        icon: _positive70,
      ),
      warning: IuxFeedbackRoleColors(
        content: _caution70,
        surface: _neutral80,
        border: _caution70,
        icon: _caution70,
      ),
      error: IuxFeedbackRoleColors(
        content: _critical70,
        surface: _neutral80,
        border: _critical70,
        icon: _critical70,
      ),
    ),
    state: IuxStateColors(
      focus: _accent70,
      selected: _accent70,
      hovered: _neutral80,
      pressed: _neutral70,
      dragged: _neutral60,
    ),
  );
}
