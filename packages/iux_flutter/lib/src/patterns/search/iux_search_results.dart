import 'package:flutter/widgets.dart';

import '../../accessibility/iux_semantics.dart';
import '../../layout/iux_spacing_primitives.dart';
import '../../semantics/iux_semantic_colors.dart';
import '../../themes/extensions/iux_typography_theme.dart';
import '../empty/iux_empty_state.dart';
import '../empty/iux_empty_state_model.dart';
import '../error/iux_recovery_route.dart';
import '../loading/iux_load_state.dart';
import '../loading/iux_loading_retry.dart';

/// Why a summary that says nothing is refused.
const String _kEmptySummary =
    'A search that has answered must say what it answered. An empty summary '
    'leaves a screen-reader user with a list that changed and nothing to say '
    'it did — which is the whole reason this parameter exists — and leaves a '
    'sighted user with no count. It is also the title of the empty state when '
    'nothing matched, so an empty string would produce a screen that says '
    'nothing at all. Return the localised sentence: "12 results for shoes", '
    '"Nothing matches shoes".';

/// What a settled search is announced and shown as, in the caller's words.
///
/// Called with what the search produced, so it cannot disagree with the state
/// that produced it — which is the reason this is a function and not a `String`
/// parameter sitting beside [IuxSearchResults.results]. A caller passing both a
/// state and a sentence about it would eventually pass a stale sentence, and
/// the stale one is what a screen-reader user hears.
///
/// It has to answer both cases, because a search that matched nothing has
/// answered too:
///
/// ```dart
/// summary: (BuildContext context, List<Order> orders) => orders.isEmpty
///     ? l10n.nothingMatches(query)
///     : l10n.resultCount(orders.length, query),
/// ```
///
/// Every word of it is the caller's, already localised. Counting is not
/// language-independent — the plural rules for "1 result" and "12 results"
/// differ between languages and some have six forms — so a framework composing
/// this would be composing it wrongly for most of the world.
///
/// It receives a [BuildContext] so that the localisation lookup can be made
/// where the sentence is used, which is what lets the wording follow a locale
/// change without the parent rebuilding its state.
typedef IuxSearchSummary<T> = String Function(
  BuildContext context,
  List<T> results,
);

/// The half of a search that answers: the wait, the results and their count,
/// nothing matching, or the failure and the way out of it.
///
/// ```dart
/// IuxSearchResults<Order>(
///   results: controller.results,
///   summary: (BuildContext context, List<Order> orders) => orders.isEmpty
///       ? l10n.nothingMatches(controller.query)
///       : l10n.resultCount(orders.length),
///   searchingLabel: l10n.searchingYourOrders,
///   failureCategoryLabel: l10n.error,
///   recovery: IuxRetryRoute(
///     label: l10n.tryAgain,
///     onRetry: controller.search,
///   ),
///   reset: IuxEmptyStateAction(
///     label: l10n.clearTheSearch,
///     action: const IuxActionDescriptor(
///       semantics: IuxActionSemantics(label: 'Clear the search'),
///     ),
///     onActivate: controller.clear,
///   ),
///   builder: (BuildContext context, List<Order> orders) => OrderList(orders),
/// )
/// ```
///
/// **Use it** below an [IuxSearchField], for the region the query drives.
///
/// **Do not mount it before a search has been run.** An empty box has not
/// asked anything, so there is no answer to show; a region that rendered
/// "Nothing matches" for a query nobody typed would be telling the user their
/// search failed before they made one. What a search screen shows before the
/// first query — recent searches, suggestions the application curates, a
/// prompt, or nothing at all — is the caller's screen and this widget declines
/// to guess at it. Mount it once there is a query, and take it down when the
/// query goes.
///
/// **Do not use it for a filtered list.** A list the user narrows with chips or
/// a date range is not waiting on anything: it is `IuxEmptyState` with
/// [IuxNoMatches] when the filters exclude everything, and the list itself
/// otherwise. This widget's whole shape assumes an operation that can be waited
/// on and can fail.
///
/// **It runs no query.** [results] is produced by the parent, and nothing here
/// starts a search, decides one finished, or retries one. See
/// [IuxLoadState].
///
/// ## A search is a load, and this is not a second state machine
///
/// [results] is [IuxLoadState], the same sealed value every other waited-on
/// region in IUX uses, and this widget composes [IuxLoadingRetry] rather than
/// switching over it again. Everything that follows from that is inherited: the
/// wait cannot be on screen beside the results, an error cannot outlive the
/// retry that cleared it, and a fourth state added to [IuxLoadState] later
/// fails to compile here rather than falling through to a blank region.
///
/// There is deliberately no `IuxSearchState`. A search that is running, a
/// search that answered and a search that broke are a load's three states
/// wearing a different word, and a second vocabulary for them would mean two
/// places to get the invariant right.
///
/// **Nothing matching is not a fourth state.** The search succeeded and what
/// came back has no rows in it, so it is [IuxLoadState.ready] with an empty
/// list — and this widget names the situation for the caller, with
/// [IuxNoMatches], which is the one [IuxEmptyStateCause] that fits: the content
/// is there and the criteria the user set exclude all of it. That is also why
/// [reset] is required rather than optional. `IuxNoMatches` insists on a way
/// out because the criteria were set through the interface and can therefore
/// always be unset by it, and a search with no results and no way back is the
/// most common dead end in the category.
///
/// ## Exactly one thing is announced per search
///
/// A sighted user sees the list change. A screen-reader user is told nothing at
/// all unless something says so — the rows are replaced, the caret is still in
/// the box, and no focus has moved. WCAG 2.2 SC 4.1.3 is the criterion, and a
/// live region is the mechanism.
///
/// The hard part is not saying it, it is saying it **once**:
///
/// | The search is | What is announced | By |
/// | --- | --- | --- |
/// | running | what is being searched | `IuxLoadingIndicator`, carrying [searchingLabel] |
/// | answered with rows | [summary] | the status line above the results |
/// | answered with nothing | [summary] | `IuxEmptyState`'s own live region |
/// | broken | the category and the message | `IuxErrorRecovery` |
///
/// The empty branch takes [IuxEmptyStateArrival.afterAChange] and therefore
/// announces itself, so this widget adds **no** status line there — the two
/// together would say the same sentence twice, once as a status and once as a
/// heading. That arrival is not configurable, and it is right unconditionally
/// here for a reason that does not hold for empty states generally: a search
/// result region only ever changes because the user typed something. It is
/// always "after a change", because there is no other way to arrive at it.
///
/// **The status line is on screen as well as announced.** Not because the count
/// is unavailable otherwise — a sighted user can see rows — but because
/// "twelve" and "two hundred" are not distinguishable at a glance, and because
/// a live region is a request rather than a guarantee. Nothing essential is
/// lost when the platform declines to speak it: the same words are on screen.
///
/// ## Debounce is the caller's, and there is no timer here
///
/// This widget holds no delay, and neither does [IuxSearchField]. It is the
/// position `IuxLoadingRetry` already takes, for the same reason: a widget that
/// chose its branch from wall-clock time rather than from the state it was
/// handed would render differently from an identical sibling, and that is the
/// one property the whole design rests on. IUX does not run the query, so it
/// has nothing to delay.
///
/// What the caller must do instead is not optional. A query fired on every
/// keystroke enters [IuxLoadState.loading] on every keystroke, and each entry
/// mounts a live region: measured over a five-character query, that is five
/// interruptions from the wait alone, before the results have said anything —
/// and with the status line it is ten. A screen-reader user cannot type through
/// that. Wait for a pause in the typing before running the query. See
/// `docs/patterns/search.md` for the window and the measurement.
///
/// WCAG 2.2 SC 2.2.1 (Timing Adjustable) is satisfied by imposing no limit at
/// all. Nothing here expires, removes content on a schedule or requires the
/// user to act within any interval, and a caller's trailing-edge debounce sets
/// no limit either — it restarts with every keystroke, so a user typing one
/// character a minute is never cut off. A *fixed* interval that ran the query
/// whether or not the user had finished would be a different matter, and is
/// why the guidance is "wait for a pause" rather than "poll".
///
/// ## There is no suggestion list, and that is measured rather than argued
///
/// A suggestion list attached to a text box is a combo box. It has a role
/// (`combobox`), a relationship to the list it controls, an announced count, an
/// active-descendant that moves without focus moving, and keyboard expectations
/// — arrow keys traverse the suggestions while the caret stays in the box —
/// and none of that is optional: a suggestion list without them is a set of
/// tappable words that a screen-reader user is never told exists.
///
/// Flutter 3.44.8 declares `SemanticsRole.comboBox` and does not implement it.
/// A node carrying that role throws
/// `Missing checks for role SemanticsRole.comboBox` from the framework's own
/// debug role checks the moment it reaches the semantics update — which is to
/// say the role cannot be used at all, not merely that it announces nothing.
/// A test in `test/patterns/iux_search_test.dart` pins that, so the day it is
/// implemented is visible.
///
/// Shipping suggestions anyway would mean a list with no role, and
/// `PROJECT_PROMPT.md` §19 does not permit public API whose only effect is an
/// unverified announcement. So there are none. An application that needs them
/// today owns the list and its semantics, knowing what it is taking on.
///
/// ## Known limitations
///
/// **The region must be given a bounded height.** The results branch puts
/// [builder]'s widget in an `Expanded` below the status line, because a result
/// list scrolls and a scrolling list has to be told how tall it is. Place this
/// inside an `Expanded`, a `SizedBox` or anything else that bounds it. Given
/// unbounded height it fails on Flutter's own unbounded-constraints assertion,
/// which names the problem, rather than laying out silently wrongly.
///
/// **Nothing here scrolls.** The status line, the wait, the empty state and
/// the failure are all placed rather than wrapped in a scroll view: a region
/// inside a list that already scrolls must not introduce a second one. A very
/// long summary at a large text scale wraps rather than truncating, and takes
/// the height it needs from the results below it.
///
/// **A live region is a request, not a guarantee.** Whether the platform speaks
/// it, and when, is the platform's decision; a widget test can assert that the
/// node carries the flag and no more, so TalkBack stays a manual check.
///
/// **The count is not announced when it does not change.** Android speaks a
/// polite live region when its content changes, so two consecutive searches
/// that both return twelve results produce one announcement rather than two.
/// That is the platform's behaviour and IUX does not work around it: forcing a
/// re-announcement would mean composing a string that differs from the last
/// one, which is exactly the thing this library refuses to do.
class IuxSearchResults<T> extends StatelessWidget {
  /// Creates the answering half of a search.
  const IuxSearchResults({
    super.key,
    required this.results,
    required this.summary,
    required this.searchingLabel,
    required this.failureCategoryLabel,
    required this.recovery,
    required this.reset,
    required this.builder,
    this.noMatchesGuidance,
  }) : assert(
          noMatchesGuidance == null || noMatchesGuidance.length > 0,
          'Empty guidance is the same as no guidance, and says so less '
          'clearly. Omit the parameter, or pass the localised sentence that '
          'tells the user how to search differently.',
        );

  /// Where the search has got to.
  ///
  /// Owned by the parent and never produced here. An empty list is a result
  /// rather than a failure: the search answered, and nothing matched.
  final IuxLoadState<List<T>> results;

  /// What the settled search is called, in the caller's words.
  ///
  /// Used twice and never composed: as the announced and visible status when
  /// something matched, and as the empty state's title when nothing did. See
  /// [IuxSearchSummary].
  final IuxSearchSummary<T> summary;

  /// What is being searched, already localised.
  ///
  /// Describe the work, not the widget: "Searching your orders", not
  /// "Loading". It is what a screen reader hears while the search runs and what
  /// stays on screen in place of the moving bar when the user has asked for no
  /// motion, so it has to stand on its own in both roles.
  ///
  /// Required in every branch, for the reason `IuxLoadingRetry` requires its
  /// own: a label that only had to exist in the branch that uses it is a label
  /// a caller discovers is missing on the slow search they could not reproduce.
  final String searchingLabel;

  /// The localised word for the failure category — "Error", "Erreur".
  ///
  /// Passed to `IuxErrorRecovery`, which requires it because it is the only
  /// carrier of the category that survives a screen reader, a monochrome
  /// display and an inverted one (WCAG SC 1.4.1).
  final String failureCategoryLabel;

  /// What the user can do about a search that broke.
  ///
  /// A search is usually safe to repeat, so [IuxRetryRoute] is usually right —
  /// but not always, and the choice stays the caller's. See
  /// [IuxRecoveryRoute] for which failures may honestly be retried.
  final IuxRecoveryRoute recovery;

  /// How the user gets back to results when nothing matched.
  ///
  /// Required, because [IuxNoMatches] requires it: the query was set through
  /// the interface, so the interface can always unset it, and a search with no
  /// results and no way back is a dead end the user has to find their own way
  /// out of.
  ///
  /// It does not have to clear the box. "Search everywhere", "Include archived"
  /// and "Search the last year instead" are all resets — what matters is that
  /// activating it returns content, so the user learns the query was the
  /// reason. Do not point it at the control the user would have to find anyway:
  /// a reset labelled "Open the search" hands them back the box they are
  /// already stuck in.
  final IuxEmptyStateAction reset;

  /// Builds the region from what the search produced.
  ///
  /// Called only for a non-empty result, so there is neither a state nor an
  /// emptiness left to check inside it. Reuses `IuxLoadingRetry`'s builder type
  /// because it is the same contract: the value, not the state.
  final IuxLoadedBuilder<List<T>> builder;

  /// A second sentence shown when nothing matched, already localised.
  ///
  /// What would find something: "Try a shorter word", "Order numbers need the
  /// leading zeros". Optional, because [reset] is already a way out and
  /// `IuxEmptyState` only insists on one of the two.
  final String? noMatchesGuidance;

  @override
  Widget build(BuildContext context) {
    return IuxLoadingRetry<List<T>>(
      state: results,
      loadingLabel: searchingLabel,
      failureCategoryLabel: failureCategoryLabel,
      recovery: recovery,
      // One switch, and it is IuxLoadingRetry's. The only decision left here is
      // what a ready search looks like, which is the one decision this pattern
      // exists to make.
      builder: (BuildContext context, List<T> value) {
        final String text = summary(context, value);
        assert(text.length > 0, _kEmptySummary);

        if (value.isEmpty) {
          return IuxEmptyState(
            cause: IuxNoMatches(reset: reset),
            title: text,
            guidance: noMatchesGuidance,
            // Not configurable, and not a default. A search result region is
            // only ever reached by asking, so it is always a change the user
            // made — which is exactly when an empty state must announce
            // itself. Its live region is the announcement for this branch, and
            // the reason no status line is added below.
            arrival: IuxEmptyStateArrival.afterAChange,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _IuxSearchStatus(summary: text),
            const IuxGap.tight(),
            // Expanded rather than a plain child: a result list scrolls, and a
            // scrolling list has to be told how tall it is. See the note on
            // bounded height in the class documentation.
            Expanded(child: builder(context, value)),
          ],
        );
      },
    );
  }
}

/// The count, announced once and left on screen.
///
/// A live region rather than an announcement, for the reason every other IUX
/// status uses one: Android deprecated `announceForAccessibility` because it
/// clears TalkBack's speech queue, so an announcement cuts off whatever the
/// user was listening to — which, during a search, is frequently the query they
/// are still typing. A live region is spoken in place, once, and the user can
/// go back over it.
///
/// The visible text repeats the label verbatim, so it is excluded from the
/// semantic tree; left in, the line would be read once as the region's label
/// and once as its content.
class _IuxSearchStatus extends StatelessWidget {
  const _IuxSearchStatus({required this.summary});

  final String summary;

  @override
  Widget build(BuildContext context) {
    final IuxTypographyTheme type = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);

    return IuxSemantics.liveRegion(
      label: summary,
      child: IuxSemantics.decorative(
        child: Text(
          summary,
          // Secondary rather than tertiary. The count qualifies the list below
          // it rather than being incidental to it — it is the one carrier of a
          // status message (SC 4.1.3) on this screen, and the tertiary role is
          // reserved for content nobody has to read.
          style: type.body.copyWith(color: colors.content.secondary),
          // No line limit and no ellipsis at any text size. A truncated count
          // is a count, and truncation gets worse exactly when someone has
          // enlarged their text because they were struggling to read.
          softWrap: true,
        ),
      ),
    );
  }
}
