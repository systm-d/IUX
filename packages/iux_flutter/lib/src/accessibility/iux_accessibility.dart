import 'package:flutter/material.dart';

import '../foundations/iux_foundations.dart';
import '../themes/extensions/iux_accessibility_theme.dart';

/// The accessibility preferences actually in force, for one `BuildContext`.
///
/// A theme records what the *application* asked for. The platform records what
/// the *user* asked for. This reconciles the two, and it is the single place
/// where that reconciliation happens — a component reads the result and never
/// consults `MediaQuery` itself.
///
/// ```dart
/// final a11y = IuxAccessibility.of(context);
/// if (a11y.allowsNonEssentialMotion) { ... }
/// ```
@immutable
final class IuxAccessibility {
  /// Creates a resolved runtime state.
  const IuxAccessibility({
    required this.contrast,
    required this.motion,
    required this.density,
    required this.touchTarget,
    required this.visualStimulation,
    required this.textScaler,
    required this.boldText,
    required this.invertColors,
    required this.screenReaderExpected,
  });

  /// Resolves the preferences in force at [context].
  ///
  /// Falls back to platform values alone when no IUX theme is installed, so
  /// this stays usable during incremental adoption.
  ///
  /// **One accessor per value, never `MediaQuery.of`.** The two resolve the
  /// same six values; they differ in what the caller is then rebuilt for.
  /// `MediaQuery.of` registers a dependency on *every* aspect of the media
  /// query, so a caller reading it was rebuilt by the software keyboard
  /// opening, by a notch being reported and by the device rotating — none of
  /// which can change any value here, and all of which are frequent.
  ///
  /// Measured on a realistic screen, one frame after the change
  /// (IUX-PERF-001): a keyboard rebuilt 114 elements through `MediaQuery.of`
  /// and rebuilds **8** now, a notch 101 and **8**, a rotation 130 and **26**.
  /// Enlarging the text is 140 either way, because text scale is one of the six
  /// and every one of those rebuilds is required. Every resolved value is
  /// identical either way — the dependency narrowed, the answer did not — and
  /// both halves of that are pinned by
  /// `test/performance/rebuild_scope_test.dart`.
  static IuxAccessibility of(BuildContext context) {
    final IuxAccessibilityProfile requested =
        Theme.of(context).extension<IuxAccessibilityTheme>()?.profile ??
            const IuxAccessibilityProfile();

    return IuxAccessibility(
      contrast: _strongerContrast(
        requested.contrast,
        MediaQuery.highContrastOf(context),
      ),
      motion: _strongerMotion(
        requested.motion,
        MediaQuery.disableAnimationsOf(context),
      ),
      density: requested.density,
      touchTarget: requested.touchTarget,
      visualStimulation: requested.visualStimulation,
      textScaler: MediaQuery.textScalerOf(context),
      boldText: MediaQuery.boldTextOf(context),
      invertColors: MediaQuery.invertColorsOf(context),
      screenReaderExpected: MediaQuery.accessibleNavigationOf(context),
    );
  }

  /// The contrast level in force.
  final IuxContrast contrast;

  /// The motion preference in force. Never [IuxMotionPreference.system]: the
  /// platform has been consulted by the time this exists.
  final IuxMotionPreference motion;

  /// The requested information density.
  final IuxDensity density;

  /// The requested interactive target size.
  final IuxTouchTargetPreference touchTarget;

  /// The requested level of non-essential visual activity.
  final IuxVisualStimulation visualStimulation;

  /// The platform text scaling to apply.
  final TextScaler textScaler;

  /// Whether the platform asked for heavier text.
  final bool boldText;

  /// Whether the platform is inverting colours.
  ///
  /// When true, a component should avoid compensating: the inversion is the
  /// user's choice and second-guessing it produces unpredictable results.
  final bool invertColors;

  /// Whether assistive navigation is expected to be active.
  ///
  /// Useful for deciding whether an announcement will be heard. It is a hint,
  /// not a guarantee: never gate essential behaviour on it, because a false
  /// negative would silently remove that behaviour.
  final bool screenReaderExpected;

  /// Whether motion that carries no information is permitted.
  bool get allowsNonEssentialMotion =>
      motion == IuxMotionPreference.standard &&
      visualStimulation == IuxVisualStimulation.standard;

  /// Whether motion should be removed entirely rather than shortened.
  bool get suppressesAllMotion => motion == IuxMotionPreference.none;

  /// Whether contrast has been reinforced, by the application or the platform.
  bool get isHighContrast => contrast == IuxContrast.high;

  /// The smallest interactive dimension permitted here.
  double get minimumTouchTarget =>
      touchTarget == IuxTouchTargetPreference.comfortable
          ? IuxTouchTarget.comfortable
          : IuxTouchTarget.minimum;

  /// Whether text is enlarged enough that a horizontal layout should reflow.
  ///
  /// The threshold is a heuristic, not a standard. Above roughly 1.3x, a row
  /// of label and value stops fitting on common phone widths and needs to
  /// stack instead of shrink — shrinking is what produces the clipped labels
  /// users report as "the setting has no effect".
  bool get prefersStackedLayout => textScaler.scale(16) / 16 >= 1.3;

  /// Applies the platform text scaling to a size.
  double scaleText(double fontSize) => textScaler.scale(fontSize);

  /// The platform preference can strengthen what the application asked for,
  /// never weaken it.
  ///
  /// A user who enabled high contrast at the system level did so for a reason.
  /// An application that requested standard contrast did so without knowing
  /// that. Between the two, the accommodation wins.
  static IuxContrast _strongerContrast(
    IuxContrast requested,
    bool platformHighContrast,
  ) =>
      platformHighContrast ? IuxContrast.high : requested;

  /// Same rule for motion, with one extra case: [IuxMotionPreference.system]
  /// carries no opinion at all and simply adopts the platform's.
  static IuxMotionPreference _strongerMotion(
    IuxMotionPreference requested,
    bool platformDisablesAnimations,
  ) {
    if (requested == IuxMotionPreference.system) {
      return platformDisablesAnimations
          ? IuxMotionPreference.reduced
          : IuxMotionPreference.standard;
    }
    if (platformDisablesAnimations &&
        requested == IuxMotionPreference.standard) {
      return IuxMotionPreference.reduced;
    }
    return requested;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxAccessibility &&
          other.contrast == contrast &&
          other.motion == motion &&
          other.density == density &&
          other.touchTarget == touchTarget &&
          other.visualStimulation == visualStimulation &&
          other.textScaler == textScaler &&
          other.boldText == boldText &&
          other.invertColors == invertColors &&
          other.screenReaderExpected == screenReaderExpected;

  @override
  int get hashCode => Object.hash(
        contrast,
        motion,
        density,
        touchTarget,
        visualStimulation,
        textScaler,
        boldText,
        invertColors,
        screenReaderExpected,
      );
}
