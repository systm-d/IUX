import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:iux_flutter/iux_flutter.dart';

import 'jobs.dart';
import 'screen_frame.dart';
import 'strings.dart';

/// One visit, with the two things that can be done to it.
///
/// A pushed route rather than a tab, and it therefore places its own
/// `IuxModalLayer` and `IuxTransientLayer`. Both are per-route in this
/// framework: the shell's layers are underneath this route and cannot be
/// reached from it, so every route that opens a dialog or offers an undo pays
/// for both again.
class JobDetailScreen extends StatefulWidget {
  /// Creates the detail screen.
  const JobDetailScreen({
    super.key,
    required this.jobs,
    required this.jobId,
    required this.onClose,
  });

  /// The round.
  final JobStore jobs;

  /// Which visit is on screen.
  final String jobId;

  /// Leaves the screen. The route is the application's, not the component's.
  final VoidCallback onClose;

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  late final IuxDestructiveFlowController _delete;
  late final IuxAsyncActionController _complete;

  /// The reference, kept because the visit itself stops existing when it is
  /// removed and the undo notice still has to name it.
  late String _reference;

  @override
  void initState() {
    super.initState();
    _reference = widget.jobs.find(widget.jobId)?.reference ?? '';
    _delete = IuxDestructiveFlowController(
      semantics: const IuxActionSemantics(label: Strings.detailDelete),
      scope: IuxDestructiveScope.items,
      wayBack: IuxUndoOffer(
        notice: Strings.detailDeletedNotice(_reference),
        undoLabel: Strings.detailUndo,
        dismissLabel: Strings.detailDismissNotice,
        onUndo: () {
          widget.jobs.restore();
          setState(() {});
        },
      ),
      onDestroy: () {
        widget.jobs.remove(widget.jobId);
        setState(() {});
      },
    );
    _complete = IuxAsyncActionController(
      action: const IuxActionDescriptor.primary(
        semantics: IuxActionSemantics(label: Strings.detailComplete),
        role: IuxActionRole.confirm,
      ),
      operation: (IuxAsyncActionSignal signal) async {
        await Future<void>.delayed(JobStore.latency);
        if (signal.isCancellationRequested) {
          return const IuxAsyncOutcome.cancelled();
        }
        widget.jobs.complete(widget.jobId);
        return const IuxAsyncOutcome.succeeded(
          feedback: IuxFeedbackEvent.success(
            semanticMessage: Strings.detailCompleted,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _delete.dispose();
    _complete.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[widget.jobs, _delete]),
        builder: (BuildContext context, Widget? child) {
          final Job? job = widget.jobs.find(widget.jobId);
          return IuxModalLayer(
            dialog: _delete.dialog,
            child: IuxTransientLayer(
              message: _delete.notice,
              onDismissed: _delete.dismissNotice,
              child: PilotScreen(
                title: job?.reference ?? _reference,
                leading: IuxAppBarLeading.back(
                  label: Strings.detailBack,
                  onActivate: widget.onClose,
                ),
                child: job == null ? _gone : _details(job),
              ),
            ),
          );
        },
      );

  /// What is left after the visit has been removed and the undo not taken.
  Widget get _gone => const IuxEmptyState(
        cause: IuxNothingLeftToDo(),
        title: Strings.detailGoneTitle,
        guidance: Strings.detailGoneGuidance,
      );

  Widget _details(Job job) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          IuxStatusIndicator(
            status: job.state == JobState.done
                ? const IuxStatus.success(Strings.stateDone)
                : job.priority == JobPriority.urgent
                    ? const IuxStatus.warning(Strings.priorityUrgent)
                    : const IuxStatus.neutral(Strings.stateScheduled),
          ),
          const IuxGap.between(),
          IuxCard(
            child: IuxSection(
              title: Strings.detailSection,
              children: <Widget>[
                _Line(label: Strings.detailSite, value: job.site),
                _Line(
                  label: Strings.detailPriority,
                  value: job.priority == JobPriority.urgent
                      ? Strings.priorityUrgent
                      : Strings.priorityRoutine,
                ),
                _Line(
                  label: Strings.detailNotes,
                  value: job.notes ?? Strings.detailNoNotes,
                ),
              ],
            ),
          ),
          const IuxGap.between(),
          // Two stacked full-width controls is the obvious layout here, and
          // `IuxTargetSpacing(axis: Axis.vertical)` is the widget that exists
          // to guarantee the gap between them. It cannot hold them: see
          // IUX-EXPAND-CRASH-001 and the note in the mission report. A Column
          // plus IuxGap works and gives up the guarantee.
          if (job.state == JobState.scheduled) ...<Widget>[
            IuxAsyncActionButton(
              controller: _complete,
              label: Strings.detailComplete,
              busyLabel: Strings.detailCompleteBusy,
              expand: true,
            ),
            const IuxGap.standard(),
          ],
          IuxDestructiveFlow(
            label: Strings.detailDelete,
            controller: _delete,
            variant: IuxButtonVariant.outlined,
            expand: true,
          ),
        ],
      );
}

/// A labelled line inside the details card.
class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final IuxTypographyTheme type = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: type.label.copyWith(color: colors.content.secondary),
          ),
          Text(value, style: type.body.copyWith(color: colors.content.primary)),
        ],
      ),
    );
  }
}
