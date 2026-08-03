/// Public API for the IUX Flutter package.
///
/// The primitive palette in `src/semantics/colors/iux_primitive_colors.dart`
/// is deliberately absent: components resolve semantic roles, never raw
/// colors, so exposing primitives would let a component bypass the contrast
/// guarantees a theme is responsible for.
library;

export 'src/foundations/iux_foundations.dart';
export 'src/semantics/colors/iux_action_colors.dart';
export 'src/semantics/colors/iux_border_colors.dart';
export 'src/semantics/colors/iux_content_colors.dart';
export 'src/semantics/colors/iux_feedback_colors.dart';
export 'src/semantics/colors/iux_state_colors.dart';
export 'src/semantics/colors/iux_surface_colors.dart';
export 'src/semantics/iux_semantic_colors.dart';
export 'src/utilities/iux.dart';
