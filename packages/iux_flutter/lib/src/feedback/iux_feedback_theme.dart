import 'package:flutter/material.dart';

/// Application-level policy for how feedback is delivered.
///
/// Separate from the semantic colours, which say how a message *looks*. This
/// says which channels are permitted at all — a decision an application makes
/// once, not per component.
@immutable
final class IuxFeedbackTheme extends ThemeExtension<IuxFeedbackTheme> {
  /// Creates a feedback policy.
  const IuxFeedbackTheme({
    this.hapticsEnabled = true,
    this.announcementsEnabled = true,
    this.dedupeWindow = const Duration(milliseconds: 600),
  });

  /// Whether haptic feedback may be produced.
  ///
  /// Applications serving contexts where a phone must stay silent and still —
  /// a hospital ward, a meeting — turn this off globally rather than
  /// per call site.
  final bool hapticsEnabled;

  /// Whether announcements may be sent.
  final bool announcementsEnabled;

  /// How long an identical event is suppressed after one is delivered.
  ///
  /// Guards the common case where a parent and a component both report the
  /// same outcome, and the case where a retry loop fires repeatedly. Chosen
  /// long enough to absorb a double emission, short enough that a genuine
  /// second attempt still registers.
  final Duration dedupeWindow;

  /// Resolves the feedback policy installed on the ambient theme.
  ///
  /// Falls back to permissive defaults: an application that has not configured
  /// feedback should still get it, rather than silently getting none.
  static IuxFeedbackTheme of(BuildContext context) =>
      Theme.of(context).extension<IuxFeedbackTheme>() ??
      const IuxFeedbackTheme();

  @override
  IuxFeedbackTheme copyWith({
    bool? hapticsEnabled,
    bool? announcementsEnabled,
    Duration? dedupeWindow,
  }) =>
      IuxFeedbackTheme(
        hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
        announcementsEnabled: announcementsEnabled ?? this.announcementsEnabled,
        dedupeWindow: dedupeWindow ?? this.dedupeWindow,
      );

  @override
  IuxFeedbackTheme lerp(
    covariant ThemeExtension<IuxFeedbackTheme>? other,
    double t,
  ) {
    // Channel permissions are categorical: there is no state between "haptics
    // allowed" and "haptics forbidden", and a half-applied permission is worse
    // than either end.
    if (other is! IuxFeedbackTheme) return this;
    return t < 0.5 ? this : other;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxFeedbackTheme &&
          other.hapticsEnabled == hapticsEnabled &&
          other.announcementsEnabled == announcementsEnabled &&
          other.dedupeWindow == dedupeWindow;

  @override
  int get hashCode =>
      Object.hash(hapticsEnabled, announcementsEnabled, dedupeWindow);
}
