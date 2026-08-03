import 'package:flutter/material.dart';

import '../accessibility/iux_semantics.dart';
import 'iux_feedback_event.dart';
import 'iux_feedback_theme.dart';
import 'iux_haptic_policy.dart';

/// What actually happened when an event was emitted.
///
/// Returned rather than discarded so a caller can tell the difference between
/// "delivered" and "silently dropped", and so tests can assert it.
@immutable
final class IuxFeedbackOutcome {
  /// Creates an outcome.
  const IuxFeedbackOutcome({
    required this.hapticPerformed,
    required this.announced,
    required this.suppressedAsDuplicate,
  });

  /// Whether a haptic was produced.
  final bool hapticPerformed;

  /// Whether an announcement was delivered.
  final bool announced;

  /// Whether the event was dropped as a repeat of a recent one.
  final bool suppressedAsDuplicate;

  /// Whether any channel responded.
  ///
  /// False is normal — haptics may be disabled, announcements unsupported —
  /// which is exactly why the visual state must always carry the information
  /// on its own.
  bool get anyChannelResponded => hapticPerformed || announced;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxFeedbackOutcome &&
          other.hapticPerformed == hapticPerformed &&
          other.announced == announced &&
          other.suppressedAsDuplicate == suppressedAsDuplicate;

  @override
  int get hashCode =>
      Object.hash(hapticPerformed, announced, suppressedAsDuplicate);

  @override
  String toString() => 'IuxFeedbackOutcome(haptic: $hapticPerformed, '
      'announced: $announced, duplicate: $suppressedAsDuplicate)';
}

/// Delivers feedback events across the permitted channels.
///
/// Owned by an [IuxFeedbackScope] rather than being a global singleton: a
/// singleton cannot be configured per subtree, cannot be replaced in a test
/// without leaking state between them, and hides who is emitting what.
///
/// The controller decides *how* an event is delivered. It never decides *that*
/// one occurred — the parent owns the state and emits explicitly.
class IuxFeedbackController {
  /// Creates a controller.
  ///
  /// [now] is injectable so deduplication can be tested without waiting in
  /// real time.
  IuxFeedbackController({DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  String? _lastKey;
  DateTime? _lastAt;

  /// Delivers [event] at [context].
  Future<IuxFeedbackOutcome> emit(
    BuildContext context,
    IuxFeedbackEvent event,
  ) async {
    final IuxFeedbackTheme policy = IuxFeedbackTheme.of(context);

    if (_isDuplicate(event, policy.dedupeWindow)) {
      return const IuxFeedbackOutcome(
        hapticPerformed: false,
        announced: false,
        suppressedAsDuplicate: true,
      );
    }
    _remember(event);

    final bool haptic = event.allowHaptics &&
        policy.hapticsEnabled &&
        IuxHapticPolicy.patternFor(event.role) != IuxHapticPattern.none;
    if (haptic) {
      await IuxHapticPolicy.perform(IuxHapticPolicy.patternFor(event.role));
    }

    bool announced = false;
    final String? message = event.semanticMessage;
    if (event.allowAnnouncement &&
        policy.announcementsEnabled &&
        message != null &&
        message.isNotEmpty &&
        context.mounted) {
      announced = event.role.interrupts
          ? await IuxAnnouncement.assertive(context, message)
          : await IuxAnnouncement.polite(context, message);
    }

    return IuxFeedbackOutcome(
      hapticPerformed: haptic,
      announced: announced,
      suppressedAsDuplicate: false,
    );
  }

  /// Forgets the last event, so an identical one is delivered again.
  ///
  /// Use when a genuinely new attempt should be reported even though it looks
  /// the same as the previous one.
  void reset() {
    _lastKey = null;
    _lastAt = null;
  }

  bool _isDuplicate(IuxFeedbackEvent event, Duration window) {
    if (_lastKey != event.effectiveDedupeKey || _lastAt == null) return false;
    return _now().difference(_lastAt!) < window;
  }

  void _remember(IuxFeedbackEvent event) {
    _lastKey = event.effectiveDedupeKey;
    _lastAt = _now();
  }
}

/// Provides an [IuxFeedbackController] to a subtree.
///
/// ```dart
/// IuxFeedbackScope(
///   child: MyApp(),
/// )
/// ```
///
/// Then, from anywhere below:
///
/// ```dart
/// IuxFeedbackScope.of(context).emit(
///   context,
///   IuxFeedbackEvent.success(semanticMessage: l10n.savedMessage),
/// );
/// ```
class IuxFeedbackScope extends StatefulWidget {
  /// Provides a controller to [child].
  const IuxFeedbackScope({super.key, required this.child, this.controller});

  /// The subtree that can emit feedback.
  final Widget child;

  /// An externally owned controller, for tests or for shared state.
  final IuxFeedbackController? controller;

  /// The controller in scope.
  ///
  /// Throws when no scope is installed, rather than silently discarding
  /// feedback: a missing scope means a user is receiving nothing, which is a
  /// defect that must surface in development rather than in the field.
  static IuxFeedbackController of(BuildContext context) {
    final _IuxFeedbackProvider? provider =
        context.dependOnInheritedWidgetOfExactType<_IuxFeedbackProvider>();
    if (provider != null) return provider.controller;
    throw FlutterError.fromParts(<DiagnosticsNode>[
      ErrorSummary('No IuxFeedbackScope found.'),
      ErrorDescription(
        'Feedback events are delivered by a controller provided by an '
        'IuxFeedbackScope. No scope encloses this widget, so the event would '
        'have been discarded.',
      ),
      ErrorHint('Wrap your application in an IuxFeedbackScope.'),
    ]);
  }

  /// The controller in scope, or null when none is installed.
  static IuxFeedbackController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_IuxFeedbackProvider>()
      ?.controller;

  @override
  State<IuxFeedbackScope> createState() => _IuxFeedbackScopeState();
}

class _IuxFeedbackScopeState extends State<IuxFeedbackScope> {
  late IuxFeedbackController _controller =
      widget.controller ?? IuxFeedbackController();

  @override
  void didUpdateWidget(IuxFeedbackScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null && widget.controller != _controller) {
      _controller = widget.controller!;
    }
  }

  @override
  Widget build(BuildContext context) => _IuxFeedbackProvider(
        controller: _controller,
        child: widget.child,
      );
}

class _IuxFeedbackProvider extends InheritedWidget {
  const _IuxFeedbackProvider({
    required this.controller,
    required super.child,
  });

  final IuxFeedbackController controller;

  @override
  bool updateShouldNotify(_IuxFeedbackProvider oldWidget) =>
      controller != oldWidget.controller;
}
