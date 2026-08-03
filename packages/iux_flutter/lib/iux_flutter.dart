/// Public API for the IUX Flutter package.
///
/// The primitive palette in `src/semantics/colors/iux_primitive_colors.dart`
/// is deliberately absent: components resolve semantic roles, never raw
/// colors, so exposing primitives would let a component bypass the contrast
/// guarantees a theme is responsible for.
library;

export 'src/accessibility/iux_accessibility.dart';
export 'src/accessibility/iux_focus.dart';
export 'src/accessibility/iux_motion_policy.dart';
export 'src/accessibility/iux_semantics.dart';
export 'src/accessibility/iux_touch_target.dart';
export 'src/foundations/iux_foundations.dart';
export 'src/semantics/colors/iux_action_colors.dart';
export 'src/semantics/colors/iux_border_colors.dart';
export 'src/semantics/colors/iux_content_colors.dart';
export 'src/semantics/colors/iux_feedback_colors.dart';
export 'src/semantics/colors/iux_state_colors.dart';
export 'src/semantics/colors/iux_surface_colors.dart';
export 'src/semantics/iux_semantic_colors.dart';
export 'src/themes/extensions/iux_accessibility_theme.dart';
export 'src/themes/extensions/iux_geometry_theme.dart';
export 'src/themes/extensions/iux_motion_theme.dart';
export 'src/themes/extensions/iux_typography_theme.dart';
export 'src/themes/iux_resolved_theme.dart';
export 'src/themes/iux_theme.dart';
export 'src/themes/iux_theme_configuration.dart';
export 'src/utilities/iux.dart';
