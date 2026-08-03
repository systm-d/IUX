import 'package:flutter/foundation.dart';

/// Why a failure with no wording is refused.
const String _kEmptyMessage =
    'A failed load must say what went wrong. An empty message leaves the user '
    'a region that stopped working and a control called "Try again" with no '
    'account of why it is there — and colour alone is not perceivable by '
    'everyone. Pass the localised sentence. An exception is not a sentence: '
    'map IuxAsyncFailure.raised to wording of your own before it reaches this '
    'constructor.';

/// Where one load has got to.
///
/// ```dart
/// IuxLoadState<List<Order>> state = const IuxLoadState<List<Order>>.loading();
/// state = IuxLoadState<List<Order>>.ready(orders);
/// state = IuxLoadState<List<Order>>.failed(message: l10n.ordersUnavailable);
/// ```
///
/// **Sealed, and that is the whole point.** Loading, loaded and failed are one
/// value, not three booleans. The bug this removes is the one every hand-rolled
/// load state eventually ships: `isLoading` left true beside a populated list,
/// or an error cleared without the spinner being restarted, so the region shows
/// two answers at once or none at all. Neither is constructible here — there is
/// exactly one state object, and the exhaustiveness checker will not let a
/// `switch` forget a case when a fourth one is added.
///
/// **The parent owns it.** Nothing in IUX produces an [IuxLoadState]. A
/// framework that watched a `Future` and declared success when it completed
/// would be claiming an outcome only the caller can know — a request can come
/// back 500 without throwing, and a save can return having written nothing.
/// This is the same position `IuxAsyncOutcome` takes for actions, for the same
/// reason.
///
/// ## Driving it from an `IuxAsyncActionController`
///
/// The async action model already owns the run: it flips to
/// `IuxActionOperation.inProgress` before the first await, drops repeat
/// activations, and discards results from superseded runs. Map its state onto
/// this one rather than reimplementing any of that:
///
/// ```dart
/// IuxLoadState<List<Order>> get state {
///   final IuxAsyncActionState run = controller.value;
///   if (run.isRunning) return const IuxLoadState<List<Order>>.loading();
///   final IuxAsyncFailure? failure = run.failure;
///   if (failure == null) return IuxLoadState<List<Order>>.ready(_orders);
///   return IuxLoadState<List<Order>>.failed(
///     // isExplained is false for an exception. Showing one to a user
///     // explains nothing and often leaks internals.
///     message: failure.isExplained ? failure.message! : l10n.ordersUnavailable,
///   );
/// }
/// ```
///
/// ## There is no `empty`
///
/// An empty result is not a state of the *operation* — the load succeeded, and
/// what came back has no rows in it. That distinction matters because the two
/// need different things from the interface: a failure needs an explanation and
/// a retry, an empty result needs to say why it is empty and what would fill
/// it, which is a screen region with its own wording and its own call to
/// action.
///
/// It matters more than that, in fact. `IuxEmptyStateCause` already refuses to
/// treat "empty" as one situation: a collection nobody has filled, a filter
/// that excluded everything and an account without permission are three
/// different screens with three different exits, and the pairing is
/// unrepresentable rather than validated. A fourth `IuxLoadState.empty` here
/// would flatten all of that back into one word and put the interface's most
/// common mis-pairing — "Add your first invoice" under a filter that hid forty
/// of them — one enum value away again.
///
/// So an empty result is [IuxLoadState.ready] carrying an empty value, and the
/// call site names the situation:
///
/// ```dart
/// builder: (BuildContext context, List<Order> orders) => orders.isEmpty
///     ? IuxEmptyState(
///         cause: IuxNoMatches(reset: clearFilters),
///         title: l10n.noOrdersMatchTheseFilters,
///       )
///     : OrderList(orders),
/// ```
///
/// The invariant survives: exactly one branch is on screen either way. What is
/// avoided is this pattern owning the wording of an empty state, which belongs
/// to `IuxEmptyState` and would otherwise have two homes. `IuxEmptyState`
/// makes the same division from the other side — it tells the caller to reach
/// for it "once `IuxLoadState` is ready with an empty value" — so the two
/// patterns meet at exactly one point and neither knows the other's vocabulary.
///
/// ## Identity
///
/// Every subclass compares on [Object.runtimeType] rather than on a type test.
/// The distinction is invisible until this class is generic, and it is: Dart
/// generics are covariant, so `IuxLoadReady<int>` *is* an `IuxLoadReady<Object>`
/// and a type test would call the two equal in one direction and unequal in the
/// other, while [hashCode] — which folds `T` in — called them different values
/// throughout. An asymmetric `==` with disagreeing hash codes is not a
/// theoretical complaint: it is a value that can be put into a `Set` twice and
/// looked up out of a `Map` never.
@immutable
sealed class IuxLoadState<T> {
  /// Creates a load state.
  const IuxLoadState();

  /// The load is running and nothing has come back yet.
  const factory IuxLoadState.loading() = IuxLoadInProgress<T>;

  /// The load finished and produced [value].
  ///
  /// "Produced" includes producing nothing worth showing — see the note on
  /// empty results above.
  const factory IuxLoadState.ready(T value) = IuxLoadReady<T>;

  /// The load did not finish, for a reason the caller can put in words.
  const factory IuxLoadState.failed({required String message}) =
      IuxLoadFailed<T>;
}

/// The load is running.
///
/// Carries nothing, and the omission is deliberate rather than minimal. What is
/// being waited on is a string the interface shows — `IuxLoadingRetry`'s
/// `loadingLabel`, required and never composed by IUX — not data the state
/// holds. Keeping it on the widget means the wording can follow a locale change
/// without the parent constructing a new state, and means a state object can be
/// compared for equality without comparing prose.
///
/// It carries no fraction either. A load whose extent the caller can count is a
/// different widget: see the note on determinate progress in
/// `docs/patterns/loading-and-retry.md`. Adding a value here later is an
/// additive change to this class and to nothing else, which is the point of
/// leaving it out until something asks for it.
@immutable
final class IuxLoadInProgress<T> extends IuxLoadState<T> {
  /// States that the load is running.
  const IuxLoadInProgress();

  // runtimeType, not a type test. See the note on identity in [IuxLoadState].
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other.runtimeType == runtimeType;

  @override
  int get hashCode => Object.hash(IuxLoadInProgress, T);

  @override
  String toString() => 'IuxLoadState<$T>.loading()';
}

/// The load finished and produced a value.
@immutable
final class IuxLoadReady<T> extends IuxLoadState<T> {
  /// States that the load finished, producing [value].
  const IuxLoadReady(this.value);

  /// What came back.
  ///
  /// May be empty, and an empty value is not a failure: the load did what it
  /// was asked to do. The call site decides what an empty one looks like.
  final T value;

  // runtimeType, not a type test. See the note on identity in [IuxLoadState].
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxLoadReady<T> &&
          other.runtimeType == runtimeType &&
          other.value == value;

  @override
  int get hashCode => Object.hash(IuxLoadReady, T, value);

  @override
  String toString() => 'IuxLoadState<$T>.ready($value)';
}

/// The load did not finish.
///
/// Carries the wording and not the way out. That division is deliberate: what
/// the user can do about a failure is an `IuxRecoveryRoute`, which holds
/// callbacks and is therefore neither `const` nor comparable by value, and
/// folding one in here would cost this class both properties for something the
/// widget already requires. `IuxLoadingRetry` takes the route and hands both
/// to `IuxErrorRecovery`, which is the pattern that owns what a failed region
/// looks like.
@immutable
final class IuxLoadFailed<T> extends IuxLoadState<T> {
  /// States that the load failed, for the reason given in [message].
  const IuxLoadFailed({required this.message})
      : assert(message.length > 0, _kEmptyMessage);

  /// What went wrong, already localised.
  ///
  /// Required, and never composed by IUX. It has to answer two questions and
  /// not one: what happened, and whether trying again is worth the user's
  /// time. "Something went wrong" answers neither and spends their attention
  /// to say so.
  ///
  /// There is no way to put an exception on screen through this type. That is
  /// deliberate and it is the same rule `IuxAsyncFailure.isExplained` exists to
  /// enforce: a stack trace explains nothing to the person reading it and
  /// frequently leaks internals.
  final String message;

  // runtimeType, not a type test. See the note on identity in [IuxLoadState].
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IuxLoadFailed<T> &&
          other.runtimeType == runtimeType &&
          other.message == message;

  @override
  int get hashCode => Object.hash(IuxLoadFailed, T, message);

  @override
  String toString() => 'IuxLoadState<$T>.failed($message)';
}
