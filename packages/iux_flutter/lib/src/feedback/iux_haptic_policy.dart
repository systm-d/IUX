import 'package:flutter/services.dart';

import 'iux_feedback_event.dart';

/// The physical signal a role is allowed to produce.
enum IuxHapticPattern {
  /// Nothing.
  none,

  /// The lightest available tick, used for choices.
  selection,

  /// A light tap, used for a completed reversible action.
  light,

  /// A firmer tap, used when the user should pause.
  medium,

  /// The firmest tap, used for failures and irreversible consequences.
  heavy,
}

/// Maps feedback roles to haptic patterns, and performs them.
///
/// Constraints this encodes, so no component has to remember them:
///
/// - nothing vibrates continuously;
/// - progress never vibrates, because an ongoing operation would mean
///   repeated vibration;
/// - one event produces at most one haptic;
/// - haptics never carry information on their own — a user with the phone on
///   a desk, or with reduced sensation, must lose nothing.
abstract final class IuxHapticPolicy {
  /// The pattern a role is permitted.
  static IuxHapticPattern patternFor(IuxFeedbackRole role) {
    if (!role.mayVibrate) return IuxHapticPattern.none;
    return switch (role) {
      IuxFeedbackRole.interaction => IuxHapticPattern.selection,
      IuxFeedbackRole.selection => IuxHapticPattern.selection,
      IuxFeedbackRole.confirmation => IuxHapticPattern.light,
      IuxFeedbackRole.success => IuxHapticPattern.light,
      IuxFeedbackRole.warning => IuxHapticPattern.medium,
      IuxFeedbackRole.error => IuxHapticPattern.heavy,
      IuxFeedbackRole.destructive => IuxHapticPattern.heavy,
      IuxFeedbackRole.progress => IuxHapticPattern.none,
    };
  }

  /// Performs [pattern].
  ///
  /// Whether anything is felt depends on the device and on the platform's own
  /// haptic setting, neither of which Flutter reports. That is one more reason
  /// a haptic may never be the only signal.
  static Future<void> perform(IuxHapticPattern pattern) => switch (pattern) {
        IuxHapticPattern.none => Future<void>.value(),
        IuxHapticPattern.selection => HapticFeedback.selectionClick(),
        IuxHapticPattern.light => HapticFeedback.lightImpact(),
        IuxHapticPattern.medium => HapticFeedback.mediumImpact(),
        IuxHapticPattern.heavy => HapticFeedback.heavyImpact(),
      };
}
