import 'package:flutter/foundation.dart';

/// What a feedback event means for the user.
///
/// Distinct from `IuxFeedbackRoleColors`, which describes how a *message* is
/// painted. This describes what *happened*, and drives which channels respond.
enum IuxFeedbackRole {
  /// An interaction was registered — a press, a toggle.
  ///
  /// The lightest role. Frequent, so it must stay nearly imperceptible.
  interaction,

  /// A choice was recorded.
  selection,

  /// A reversible action completed.
  confirmation,

  /// An operation the user initiated completed.
  success,

  /// An operation is under way.
  ///
  /// Never haptic: an ongoing operation would mean repeated vibration.
  progress,

  /// Something the user should weigh before continuing.
  warning,

  /// An operation failed and needs a recovery path.
  error,

  /// An irreversible action is about to happen, or just did.
  ///
  /// The strongest role, deliberately: this is the one moment where an
  /// interruption is proportionate.
  destructive,
}

/// How strongly a role may present itself.
enum IuxFeedbackIntensity {
  /// No perceptible signal beyond the visual state itself.
  none,

  /// Barely perceptible. Suitable for something that happens constantly.
  subtle,

  /// Clearly perceptible without demanding attention.
  moderate,

  /// Demands attention. Reserved for consequences.
  strong,
}

/// A feedback event, supplied by the parent.
///
/// The runtime never infers that something succeeded, failed or finished. It
/// cannot know, and a framework that guesses will eventually announce a
/// success that did not happen. The parent owns the state and emits the event.
///
/// Immutable, and free of business logic. [semanticMessage] is supplied
/// already localised by the caller: the engine holds roles, never user-facing
/// strings, so it can never leak an English sentence into a Japanese app.
@immutable
final class IuxFeedbackEvent {
  /// Creates a feedback event.
  const IuxFeedbackEvent({
    required this.role,
    this.semanticMessage,
    this.allowHaptics = true,
    this.allowAnnouncement = true,
    this.dedupeKey,
  });

  /// An interaction was registered.
  const IuxFeedbackEvent.interaction({bool allowHaptics = true})
      : this(role: IuxFeedbackRole.interaction, allowHaptics: allowHaptics);

  /// A choice was recorded.
  const IuxFeedbackEvent.selection({
    String? semanticMessage,
    bool allowHaptics = true,
  }) : this(
          role: IuxFeedbackRole.selection,
          semanticMessage: semanticMessage,
          allowHaptics: allowHaptics,
        );

  /// An operation the user initiated completed.
  const IuxFeedbackEvent.success({
    String? semanticMessage,
    bool allowHaptics = true,
    String? dedupeKey,
  }) : this(
          role: IuxFeedbackRole.success,
          semanticMessage: semanticMessage,
          allowHaptics: allowHaptics,
          dedupeKey: dedupeKey,
        );

  /// Something the user should weigh before continuing.
  const IuxFeedbackEvent.warning({
    String? semanticMessage,
    bool allowHaptics = true,
    String? dedupeKey,
  }) : this(
          role: IuxFeedbackRole.warning,
          semanticMessage: semanticMessage,
          allowHaptics: allowHaptics,
          dedupeKey: dedupeKey,
        );

  /// An operation failed.
  const IuxFeedbackEvent.error({
    String? semanticMessage,
    bool allowHaptics = true,
    String? dedupeKey,
  }) : this(
          role: IuxFeedbackRole.error,
          semanticMessage: semanticMessage,
          allowHaptics: allowHaptics,
          dedupeKey: dedupeKey,
        );

  /// An irreversible action is about to happen, or just did.
  const IuxFeedbackEvent.destructive({
    String? semanticMessage,
    bool allowHaptics = true,
    String? dedupeKey,
  }) : this(
          role: IuxFeedbackRole.destructive,
          semanticMessage: semanticMessage,
          allowHaptics: allowHaptics,
          dedupeKey: dedupeKey,
        );

  /// What happened.
  final IuxFeedbackRole role;

  /// A localised message for assistive technology, or null for none.
  ///
  /// Supplied by the caller. The engine never composes user-facing text.
  final String? semanticMessage;

  /// Whether this event may produce haptic feedback.
  ///
  /// Set false when the caller already produced one for the same action;
  /// double feedback for a single event is worse than none.
  final bool allowHaptics;

  /// Whether this event may be announced.
  ///
  /// Set false when the message is already visible in a live region, which
  /// would otherwise make the user hear it twice.
  final bool allowAnnouncement;

  /// Identity used to suppress repeats, defaulting to the role and message.
  ///
  /// Give two logically identical events the same key so a retry loop does
  /// not vibrate five times.
  final String? dedupeKey;

  /// The key actually used for deduplication.
  String get effectiveDedupeKey =>
      dedupeKey ?? '${role.name}:${semanticMessage ?? ''}';

  /// Returns a copy with the given values replaced.
  IuxFeedbackEvent copyWith({
    IuxFeedbackRole? role,
    String? semanticMessage,
    bool? allowHaptics,
    bool? allowAnnouncement,
    String? dedupeKey,
  }) =>
      IuxFeedbackEvent(
        role: role ?? this.role,
        semanticMessage: semanticMessage ?? this.semanticMessage,
        allowHaptics: allowHaptics ?? this.allowHaptics,
        allowAnnouncement: allowAnnouncement ?? this.allowAnnouncement,
        dedupeKey: dedupeKey ?? this.dedupeKey,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxFeedbackEvent &&
          other.role == role &&
          other.semanticMessage == semanticMessage &&
          other.allowHaptics == allowHaptics &&
          other.allowAnnouncement == allowAnnouncement &&
          other.dedupeKey == dedupeKey;

  @override
  int get hashCode => Object.hash(
        role,
        semanticMessage,
        allowHaptics,
        allowAnnouncement,
        dedupeKey,
      );

  @override
  String toString() => 'IuxFeedbackEvent(${role.name})';
}

/// The intensity each role is permitted, and whether it may be announced.
extension IuxFeedbackRoleBehaviour on IuxFeedbackRole {
  /// How strongly this role may present itself.
  IuxFeedbackIntensity get intensity => switch (this) {
        IuxFeedbackRole.interaction => IuxFeedbackIntensity.subtle,
        IuxFeedbackRole.selection => IuxFeedbackIntensity.subtle,
        IuxFeedbackRole.confirmation => IuxFeedbackIntensity.subtle,
        IuxFeedbackRole.success => IuxFeedbackIntensity.moderate,
        IuxFeedbackRole.progress => IuxFeedbackIntensity.none,
        IuxFeedbackRole.warning => IuxFeedbackIntensity.moderate,
        IuxFeedbackRole.error => IuxFeedbackIntensity.strong,
        IuxFeedbackRole.destructive => IuxFeedbackIntensity.strong,
      };

  /// Whether an announcement for this role should interrupt.
  ///
  /// Only failures and irreversible consequences do. Interrupting for a
  /// success trains users to turn announcements off, at which point the
  /// failures stop being heard too.
  bool get interrupts =>
      this == IuxFeedbackRole.error || this == IuxFeedbackRole.destructive;

  /// Whether this role may ever produce haptic feedback.
  ///
  /// Progress may not: an ongoing operation would mean repeated vibration.
  bool get mayVibrate => this != IuxFeedbackRole.progress;
}
