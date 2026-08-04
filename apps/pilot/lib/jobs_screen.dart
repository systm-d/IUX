import 'package:flutter/widgets.dart';
import 'package:iux_flutter/iux_flutter.dart';

import 'jobs.dart';
import 'screen_frame.dart';
import 'strings.dart';

/// The round: a wait, a failure, an absence, a search and a list.
///
/// The one screen that exercises all four branches of `IuxLoadState` against
/// real data the user changes from two other screens.
///
/// ## Why this does not use `IuxSearchResults`
///
/// It did, and the pattern cannot be used here. Two reasons, and the second is
/// the one that ended it.
///
/// 1. **It has one empty branch and this screen needs two.** `IuxSearchResults`
///    hard-codes `IuxNoMatches` and requires a `reset` action, so a round that
///    has never held a visit is reported as "no matches — clear the search"
///    while the search box is empty. "Nothing exists yet" and "your filter
///    excluded everything" are the two causes `IuxEmptyStateCause` exists to
///    keep apart, and the search pattern can only express one of them.
/// 2. **Its ready branch cannot be placed on an `IuxPage`.** It wraps the
///    caller's list in an `Expanded`, and `IuxPage` scrolls by default, so the
///    first non-empty result throws *RenderFlex children have non-zero flex but
///    incoming height constraints are unbounded* at
///    `iux_search_results.dart:341`. The documented placement — inside an
///    `Expanded` or a `SizedBox` — means giving up `IuxPage`, which is the only
///    thing in the framework that knows the page insets and the reading width.
///
/// So the screen composes `IuxSearchField`, `IuxEmptyState` and `IuxListGroup`
/// itself. What that costs is the status line: the count that `IuxSearchResults`
/// announces lives in a private `_IuxSearchStatus`, so the live region below is
/// a reimplementation.
class JobsScreen extends StatefulWidget {
  /// Creates the list screen.
  const JobsScreen({
    super.key,
    required this.jobs,
    required this.onCreateRequested,
    required this.onOpen,
  });

  /// The round.
  final JobStore jobs;

  /// Asks the shell to move to the creation screen.
  final VoidCallback onCreateRequested;

  /// Asks the shell to open one visit.
  final ValueChanged<Job> onOpen;

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _reload() {
    widget.jobs.load(failureMessage: Strings.jobsLoadFailed);
  }

  void _clearSearch() {
    _search.clear();
    setState(() => _query = '');
  }

  List<Job> _matching(List<Job> all) {
    final String needle = _query.trim().toLowerCase();
    if (needle.isEmpty) return all;
    return <Job>[
      for (final Job job in all)
        if (job.reference.toLowerCase().contains(needle) ||
            job.site.toLowerCase().contains(needle))
          job,
    ];
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.jobs,
        builder: (BuildContext context, Widget? child) => PilotScreen(
          title: Strings.jobsTitle,
          child: IuxLoadingRetry<List<Job>>(
            state: widget.jobs.state,
            loadingLabel: Strings.jobsLoading,
            failureCategoryLabel: Strings.errorCategory,
            recovery: IuxRetryRoute(
              label: Strings.retry,
              onRetry: _reload,
              busyHint: Strings.retryBusy,
            ),
            builder: _buildRound,
          ),
        ),
      );

  Widget _buildRound(BuildContext context, List<Job> all) {
    if (all.isEmpty) {
      return IuxEmptyState(
        cause: IuxNothingCreatedYet(
          create: IuxEmptyStateAction(
            label: Strings.jobsEmptyAction,
            action: const IuxActionDescriptor.primary(
              semantics: IuxActionSemantics(label: Strings.jobsEmptyAction),
              role: IuxActionRole.navigate,
            ),
            onActivate: widget.onCreateRequested,
          ),
        ),
        title: Strings.jobsEmptyTitle,
        guidance: Strings.jobsEmptyGuidance,
        arrival: IuxEmptyStateArrival.withTheScreen,
      );
    }

    final List<Job> shown = _matching(all);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        IuxSearchField(
          label: Strings.searchLabel,
          controller: _search,
          clearLabel: Strings.searchClear,
          placeholder: Strings.searchPlaceholder,
          onChanged: (String value) => setState(() => _query = value),
        ),
        const IuxGap.standard(),
        if (shown.isEmpty)
          IuxEmptyState(
            cause: IuxNoMatches(
              reset: IuxEmptyStateAction(
                label: Strings.jobsNoMatchesAction,
                action: const IuxActionDescriptor(
                  semantics:
                      IuxActionSemantics(label: Strings.jobsNoMatchesAction),
                ),
                onActivate: _clearSearch,
              ),
            ),
            title: Strings.jobsNoMatchesTitle,
            guidance: Strings.jobsNoMatchesGuidance,
          )
        else ...<Widget>[
          _ResultCount(text: Strings.jobsCount(shown.length, all.length)),
          const IuxGap.tight(),
          _JobList(jobs: shown, onOpen: widget.onOpen),
        ],
      ],
    );
  }
}

/// How many visits are showing, said once to a screen reader.
///
/// A reimplementation of the private `_IuxSearchStatus` inside
/// `IuxSearchResults`. It is here because the pattern that owns it cannot be
/// placed on this screen; see the class documentation above.
class _ResultCount extends StatelessWidget {
  const _ResultCount({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final IuxTypographyTheme type = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);
    return IuxSemantics.liveRegion(
      label: text,
      child: ExcludeSemantics(
        child: Text(
          text,
          style: type.supporting.copyWith(color: colors.content.secondary),
        ),
      ),
    );
  }
}

/// The rows themselves.
///
/// The status is `trailingText` rather than an `IuxStatusIndicator` in
/// `trailingAction`, and that is a defect worked around rather than a design
/// choice. `IuxListItem` lays its trailing control out as a non-flexible child
/// of a `Row`, so the control takes its full intrinsic width and the `Expanded`
/// holding the row's own text absorbs whatever is left — including a negative
/// remainder. On a 320-pixel window:
///
/// ```dart
/// IuxListItem.tappable(
///   title: 'WO-4471',
///   subtitle: '18 Mill Lane',
///   trailingAction: IuxStatusIndicator(status: IuxStatus.neutral('Scheduled')),
///   onActivate: () {},
/// )
/// ```
///
/// is clean at 100% and 150%, overflows by **68 pixels** at 200% and by **214**
/// at 300%. Neither the row alone nor the indicator alone overflows: it is the
/// composition of two IUX components, both behaving as documented.
class _JobList extends StatelessWidget {
  const _JobList({required this.jobs, required this.onOpen});

  final List<Job> jobs;
  final ValueChanged<Job> onOpen;

  @override
  Widget build(BuildContext context) => IuxListGroup(
        children: <Widget>[
          for (final Job job in jobs)
            IuxListItem.tappable(
              title: job.reference,
              subtitle: job.site,
              trailingText: _stateWord(job),
              semanticLabel: Strings.jobRowLabel(
                job.reference,
                job.site,
                _stateWord(job),
              ),
              hint: Strings.jobRowHint,
              onActivate: () => onOpen(job),
            ),
        ],
      );

  /// What the row says, and what a screen reader hears.
  ///
  /// An urgent visit says so instead of saying "Scheduled": the row has one
  /// trailing slot, and of the two facts the one the user acts on is urgency.
  static String _stateWord(Job job) => switch (job.state) {
        JobState.done => Strings.stateDone,
        JobState.scheduled => job.priority == JobPriority.urgent
            ? Strings.priorityUrgent
            : Strings.stateScheduled,
      };
}
