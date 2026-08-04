import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:iux_flutter/iux_flutter.dart';

/// How soon a visit needs making.
enum JobPriority {
  /// The default.
  routine,

  /// Listed above the routine ones.
  urgent,
}

/// Whether the visit has happened.
enum JobState {
  /// Planned, not yet made.
  scheduled,

  /// Made.
  done,
}

/// One visit on a round.
@immutable
class Job {
  /// Creates a visit.
  const Job({
    required this.id,
    required this.reference,
    required this.site,
    required this.priority,
    this.notes,
    this.state = JobState.scheduled,
  });

  /// Identity, stable across edits to the reference.
  final String id;

  /// The code on the work order.
  final String reference;

  /// Where the visit is.
  final String site;

  /// How soon it is needed.
  final JobPriority priority;

  /// Anything the caller should read first.
  final String? notes;

  /// Whether it has happened.
  final JobState state;

  /// Returns a copy with [state] changed.
  Job completed() => Job(
        id: id,
        reference: reference,
        site: site,
        priority: priority,
        notes: notes,
        state: JobState.done,
      );
}

/// The round: the application's own state, owned by the application.
///
/// Deliberately not an IUX concern. Every IUX pattern in this application
/// reports intent and leaves the store to decide what it means — which is the
/// division of labour the framework asks for, and which is also why the store
/// has to model the load lifecycle itself with [IuxLoadState].
class JobStore extends ChangeNotifier {
  /// Creates an empty, not-yet-loaded round.
  JobStore();

  /// How long a simulated fetch takes.
  ///
  /// Short enough not to be tedious, long enough that the wait is visible.
  static const Duration latency = Duration(milliseconds: 600);

  IuxLoadState<List<Job>> _state = const IuxLoadState<List<Job>>.loading();
  List<Job> _jobs = const <Job>[];
  bool _failNextLoad = false;
  int _sequence = 0;

  /// The load lifecycle, as an IUX pattern consumes it.
  IuxLoadState<List<Job>> get state => _state;

  /// Whether the next [load] should fail, so the failure branch is reachable.
  bool get failNextLoad => _failNextLoad;
  set failNextLoad(bool value) {
    if (_failNextLoad == value) return;
    _failNextLoad = value;
    notifyListeners();
  }

  /// Visits still to make.
  int get outstanding =>
      _jobs.where((Job job) => job.state == JobState.scheduled).length;

  /// Whether the round holds anything at all.
  ///
  /// Reads the store rather than [state] so a settings screen can ask the
  /// question while the list screen is between loads.
  bool get isEmpty => _jobs.isEmpty;

  /// Fetches the round, failing once if [failNextLoad] was set.
  Future<void> load({required String failureMessage}) async {
    _state = const IuxLoadState<List<Job>>.loading();
    notifyListeners();
    await Future<void>.delayed(latency);
    if (_failNextLoad) {
      _failNextLoad = false;
      _state = IuxLoadState<List<Job>>.failed(message: failureMessage);
    } else {
      _state = IuxLoadState<List<Job>>.ready(_ordered);
    }
    notifyListeners();
  }

  /// Adds a visit and returns it.
  Job add({
    required String reference,
    required String site,
    required JobPriority priority,
    String? notes,
  }) {
    final Job job = Job(
      id: 'job-${_sequence++}',
      reference: reference,
      site: site,
      priority: priority,
      notes: notes,
    );
    _jobs = <Job>[..._jobs, job];
    _publish();
    return job;
  }

  /// Whether a reference is already on the round.
  bool holdsReference(String reference) => _jobs.any(
        (Job job) =>
            job.reference.toLowerCase() == reference.toLowerCase().trim(),
      );

  /// Returns the visit with [id], or null once it has been removed.
  Job? find(String id) {
    for (final Job job in _jobs) {
      if (job.id == id) return job;
    }
    return null;
  }

  /// Records a visit as made.
  void complete(String id) {
    _jobs = <Job>[
      for (final Job job in _jobs)
        if (job.id == id) job.completed() else job,
    ];
    _publish();
  }

  /// Removes a visit, remembering where it was so [restore] can undo it.
  void remove(String id) {
    _removedIndex = _jobs.indexWhere((Job job) => job.id == id);
    if (_removedIndex < 0) return;
    _removed = _jobs[_removedIndex];
    _jobs = <Job>[..._jobs]..removeAt(_removedIndex);
    _publish();
  }

  Job? _removed;
  int _removedIndex = -1;

  /// Puts the last removed visit back where it was.
  void restore() {
    final Job? job = _removed;
    if (job == null) return;
    _jobs = <Job>[..._jobs]..insert(_removedIndex.clamp(0, _jobs.length), job);
    _removed = null;
    _removedIndex = -1;
    _publish();
  }

  /// Empties the round. There is no way back from this one.
  void clear() {
    _jobs = const <Job>[];
    _removed = null;
    _removedIndex = -1;
    _publish();
  }

  /// Urgent first, then insertion order.
  List<Job> get _ordered => <Job>[
        for (final Job job in _jobs)
          if (job.priority == JobPriority.urgent) job,
        for (final Job job in _jobs)
          if (job.priority == JobPriority.routine) job,
      ];

  void _publish() {
    if (_state is IuxLoadReady<List<Job>>) {
      _state = IuxLoadState<List<Job>>.ready(_ordered);
    }
    notifyListeners();
  }
}
