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
///   emptyCause: IuxNoMatches(
///     reset: IuxEmptyStateAction(
///       label: l10n.clearTheSearch,
///       action: const IuxActionDescriptor(
///         semantics: IuxActionSemantics(label: 'Clear the search'),
///       ),
///       onActivate: controller.clear,
///     ),
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
/// list, and the caller names the situation with [emptyCause].
///
/// This widget used to name it instead, always as [IuxNoMatches], and requiring
/// its reset. That was wrong for the case that matters most: a collection that
/// has never held anything is not a collection whose criteria excluded
/// everything, and reporting "nothing matches, clear the search" beside an
/// empty search box tells a new user that they searched badly when nobody has
/// put anything there yet — and hands them a reset that returns them to the
/// same nothing. Keeping those apart is the whole reason [IuxEmptyStateCause]
/// exists, and a pattern that can only express one of its four situations has
/// taken the decision away from the only party that can make it. See
/// [emptyCause].
///
/// ## Where this can be placed
///
/// Anywhere. The results branch reads the height it was handed and lays itself
/// out accordingly, which removes the choice a caller used to have to make and
/// get right:
///
/// | The height it is given | What it does | Who scrolls |
/// | --- | --- | --- |
/// | bounded — an `Expanded`, a `SizedBox` | fills it, list flexed | the list |
/// | unbounded — `IuxPage`, `ListView`, a sliver | measures itself | the caller |
///
/// The constraints answer the question a parameter would have asked, and they
/// answer it correctly for the caller who never read this paragraph. Every
/// vertical scroll view in Flutter hands its children an unbounded height —
/// that is what makes it a scroll view — so a region inside one is told so, and
/// a region given a bounded height was told the size of a box by something that
/// will not scroll it. It is the same discriminator `IuxEmptyState` and
/// `IuxPermissionRationale` use for the same reason (`IUX-A11Y-REACH-001`).
///
/// **What the caller owes in each case is different, and only one of them is a
/// trap.** Under a bounded height the region flexes the widget [builder]
/// returns, so a `ListView` there scrolls inside the space left under the
/// status line. Under an unbounded height there is nothing to flex against, so
/// [builder] must return something that measures itself — a `Column`, an
/// `IuxListGroup`, or a `ListView` with `shrinkWrap: true` — which is what a
/// caller writes inside a scrolling page anyway. A scrolling list handed an
/// unbounded height fails on Flutter's own assertion, naming the problem.
///
/// Before this, the pattern put [builder]'s widget in an unconditional
/// `Expanded`, so the first non-empty result inside `IuxPage` — which scrolls
/// by default — threw *RenderFlex children have non-zero flex but incoming
/// height constraints are unbounded*, and the documented way out was to give up
/// `IuxPage` and with it the page insets and the reading width
/// (`IUX-SEARCH-RESULTS-001`).
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
/// **This region introduces no scroll view of its own.** The status line, the
/// wait and the failure are placed rather than wrapped: a region inside a list
/// that already scrolls must not introduce a second one. A very long summary at
/// a large text scale wraps rather than truncating, and takes the height it
/// needs from the results below it. The one exception is the branch that has
/// nothing to show, where `IuxEmptyState` scrolls itself under a bounded height
/// so that its way out cannot be pushed off a short viewport — and only under a
/// bounded height, so it is still never a second scrollable inside the
/// caller's.
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
    required this.emptyCause,
    required this.builder,
    this.emptyGuidance,
  }) : assert(
          emptyGuidance == null || emptyGuidance.length > 0,
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

  /// Why a settled search has nothing in it, and what the user does about it.
  ///
  /// Only used when [results] is ready with an empty list, and it is the
  /// caller's because this widget cannot know it. A search returning nothing
  /// says one of several different things:
  ///
  /// | The collection | The cause | The way out |
  /// | --- | --- | --- |
  /// | holds items the query excluded | [IuxNoMatches] | a reset |
  /// | has never held anything | [IuxNothingCreatedYet] | create the first one |
  /// | holds items this user may not see | [IuxAccessRestricted] | ask for access |
  ///
  /// Those are not shades of the same screen. "Nothing matches, clear the
  /// search" beside an empty search box, on an account that has never had an
  /// order in it, tells the user their query was wrong when the truth is that
  /// there is nothing to find — and it offers them a reset that will return
  /// them to the same nothing. [IuxEmptyStateCause] exists precisely to keep
  /// those apart, and this widget used to hard-code the first row of the table
  /// and require its reset (`IUX-SEARCH-RESULTS-001`).
  ///
  /// The way out travels inside the cause rather than beside it, which is
  /// [IuxEmptyState]'s design and the reason this is one parameter and not two:
  /// [IuxNoMatches] takes a reset and requires one, [IuxNothingCreatedYet]
  /// takes the control that creates the first item, and there is no way to pair
  /// a situation with the wrong exit.
  ///
  /// A reset does not have to clear the box. "Search everywhere", "Include
  /// archived" and "Search the last year instead" are all resets — what matters
  /// is that activating it returns content, so the user learns the query was
  /// the reason. Do not point it at the control the user would have to find
  /// anyway: a reset labelled "Open the search" hands them back the box they
  /// are already stuck in.
  ///
  /// Compute it from the same state that produced [results]:
  ///
  /// ```dart
  /// emptyCause: controller.hasAnyOrders
  ///     ? IuxNoMatches(reset: clearTheSearch)
  ///     : IuxNothingCreatedYet(create: placeYourFirstOrder),
  /// ```
  final IuxEmptyStateCause emptyCause;

  /// Builds the region from what the search produced.
  ///
  /// Called only for a non-empty result, so there is neither a state nor an
  /// emptiness left to check inside it. Reuses `IuxLoadingRetry`'s builder type
  /// because it is the same contract: the value, not the state.
  final IuxLoadedBuilder<List<T>> builder;

  /// A second sentence shown when the search came back with nothing, already
  /// localised.
  ///
  /// What would find something, or what would put something there: "Try a
  /// shorter word", "Order numbers need the leading zeros", "Your orders appear
  /// here once you have placed one". Optional, because [emptyCause] usually
  /// carries a way out already and `IuxEmptyState` only insists on one of the
  /// two.
  final String? emptyGuidance;

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
            // The caller's, not this widget's. A search that came back with
            // nothing has at least four different reasons behind it and they
            // need four different sentences and four different ways out; only
            // the parent knows which one applies, because only the parent knows
            // what is in the collection being searched. See [emptyCause].
            cause: emptyCause,
            title: text,
            guidance: emptyGuidance,
            // Not configurable, and not a default. A search result region is
            // only ever reached by asking, so it is always a change the user
            // made — which is exactly when an empty state must announce
            // itself. Its live region is the announcement for this branch, and
            // the reason no status line is added below.
            arrival: IuxEmptyStateArrival.afterAChange,
          );
        }

        // The constraints decide, not a parameter. See "Where this can be
        // placed" in the class documentation: a bounded height was handed down
        // by something that will not scroll, so the list takes what is left
        // and scrolls inside it; an unbounded height is what every vertical
        // scroll view gives its children, so the region measures itself and
        // lets the caller's scroll view carry it.
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final Widget results = builder(context, value);

            return Column(
              mainAxisSize: constraints.hasBoundedHeight
                  ? MainAxisSize.max
                  : MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _IuxSearchStatus(summary: text),
                const IuxGap.tight(),
                // A flex under a bounded height and a plain child under an
                // unbounded one. Both spellings are wrong in the other's
                // situation, which is the whole defect: a flex child of a
                // Column with no end throws on Flutter's own unbounded
                // assertion, and a plain child under a bounded height would let
                // a long list overflow the box it was given instead of
                // scrolling inside it.
                if (constraints.hasBoundedHeight)
                  Expanded(child: results)
                else
                  results,
              ],
            );
          },
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
