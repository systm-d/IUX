/// Public API for the IUX Flutter package.
///
/// The primitive palette in `src/semantics/colors/iux_primitive_colors.dart`
/// is deliberately absent: components resolve semantic roles, never raw
/// colors, so exposing primitives would let a component bypass the contrast
/// guarantees a theme is responsible for.
library;

export 'src/accessibility/iux_accessibility.dart';
export 'src/accessibility/iux_focus.dart';
export 'src/accessibility/iux_semantics.dart';
export 'src/accessibility/iux_touch_target.dart';
export 'src/actions/iux_action_descriptor.dart';
export 'src/actions/iux_action_model.dart';
export 'src/components/button/iux_button.dart';
export 'src/feedback/iux_feedback_controller.dart';
export 'src/feedback/iux_feedback_event.dart';
export 'src/feedback/iux_feedback_theme.dart';
export 'src/feedback/iux_haptic_policy.dart';
export 'src/foundations/iux_foundations.dart';
export 'src/layout/iux_content_width.dart';
export 'src/layout/iux_layout_class.dart';
export 'src/layout/iux_page.dart';
export 'src/layout/iux_section.dart';
export 'src/layout/iux_spacing_primitives.dart';
export 'src/layout/iux_surface.dart';
export 'src/motion/iux_motion_policy.dart';
export 'src/motion/iux_motion_role.dart';
export 'src/semantics/colors/iux_action_colors.dart';
export 'src/semantics/colors/iux_border_colors.dart';
export 'src/semantics/colors/iux_content_colors.dart';
export 'src/semantics/colors/iux_feedback_colors.dart';
export 'src/semantics/colors/iux_state_colors.dart';
export 'src/semantics/colors/iux_surface_colors.dart';
export 'src/semantics/iux_semantic_colors.dart';
export 'src/themes/extensions/iux_accessibility_theme.dart';
export 'src/themes/extensions/iux_button_theme.dart';
export 'src/themes/extensions/iux_geometry_theme.dart';
export 'src/themes/extensions/iux_motion_theme.dart';
export 'src/themes/extensions/iux_typography_theme.dart';
export 'src/themes/iux_resolved_theme.dart';
export 'src/themes/iux_theme.dart';
export 'src/themes/iux_theme_configuration.dart';
export 'src/utilities/iux.dart';
