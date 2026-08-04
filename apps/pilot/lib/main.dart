import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iux_flutter/iux_flutter.dart';

import 'job_detail_screen.dart';
import 'jobs.dart';
import 'jobs_screen.dart';
import 'new_job_screen.dart';
import 'settings_screen.dart';
import 'strings.dart';

void main() {
  runApp(const PilotApp());
}

/// A small application built entirely on IUX, to find out what that is like.
///
/// It is a round of field visits: a list that can be waiting, broken, empty or
/// full; a form that refuses bad values and says why; a detail screen with one
/// slow action and one destructive one; and a settings screen that changes the
/// theme, asks for a permission and can empty the round for good.
///
/// The theme configuration lives here because it is the one piece of state the
/// whole tree depends on, and `MaterialApp.theme` is where IUX plugs in.
class PilotApp extends StatefulWidget {
  /// Creates the application.
  const PilotApp({super.key});

  @override
  State<PilotApp> createState() => _PilotAppState();
}

class _PilotAppState extends State<PilotApp> {
  IuxThemeConfiguration _configuration = const IuxThemeConfiguration();

  @override
  Widget build(BuildContext context) => IuxFeedbackScope(
        child: MaterialApp(
          title: Strings.appName,
          theme: IuxTheme.fromConfiguration(_configuration),
          home: PilotShell(
            configuration: _configuration,
            onConfigurationChanged: (IuxThemeConfiguration value) =>
                setState(() => _configuration = value),
          ),
        ),
      );
}

/// The navigation frame, and the single place overlays are allowed to live.
///
/// Three screens report intent; this decides what it means. It also owns every
/// piece of state that outlives a screen — the round, the permission answer,
/// the destructive controller behind "clear the round" — because a tab that
/// owned its own would lose it the moment the user looked at another one.
class PilotShell extends StatefulWidget {
  /// Creates the shell.
  const PilotShell({
    super.key,
    required this.configuration,
    required this.onConfigurationChanged,
  });

  /// The theme in force, so settings can show and change it.
  final IuxThemeConfiguration configuration;

  /// Reports a theme change to the application root.
  final ValueChanged<IuxThemeConfiguration> onConfigurationChanged;

  @override
  State<PilotShell> createState() => _PilotShellState();
}

class _PilotShellState extends State<PilotShell> {
  final JobStore _jobs = JobStore();
  late final IuxDestructiveFlowController _clearRound;

  int _destination = 0;
  ReminderPermission _permission = ReminderPermission.notAsked;

  /// The one transient slot the whole shell has.
  ///
  /// `IuxTransientLayer` holds a single message, so every screen under it
  /// competes for the same slot and the shell is the only place that can
  /// arbitrate. Two notices arriving together means one of them is not shown.
  IuxTransientMessage? _notice;

  @override
  void initState() {
    super.initState();
    _clearRound = IuxDestructiveFlowController(
      semantics: _clearSemantics,
      scope: IuxDestructiveScope.everything,
      wayBack: const IuxNoWayBack(),
      prompt: const IuxConfirmationPrompt(
        title: Strings.settingsClearTitle,
        consequence: Strings.settingsClearConsequence,
        confirmLabel: Strings.settingsClearConfirm,
        keepLabel: Strings.settingsClearKeep,
      ),
      availability: IuxActionAvailability.disabled,
      onDestroy: _clear,
    );
    _jobs.addListener(_syncClearAvailability);
    // Not in `build`: the first load notifies listeners, and a notification
    // during a build is an error. The framework has no opinion here — this is
    // a plain Flutter constraint — but it is the shape every IUX pattern that
    // reads an `IuxLoadState` forces on its caller.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _jobs.load(failureMessage: Strings.jobsLoadFailed);
    });
  }

  @override
  void dispose() {
    _jobs.removeListener(_syncClearAvailability);
    _clearRound.dispose();
    _jobs.dispose();
    super.dispose();
  }

  /// The name of the clear action, which changes when it becomes unavailable.
  ///
  /// A disabled action must say why it is disabled — the framework asserts it
  /// in three separate places — so the reason is part of the semantics rather
  /// than of the control.
  IuxActionSemantics get _clearSemantics => IuxActionSemantics(
        label: Strings.settingsClear,
        unavailabilityReason:
            _jobs.isEmpty ? Strings.settingsClearNothing : null,
      );

  /// Keeps the destructive controller in step with the round.
  ///
  /// The controller is imperative and the round is not, so something has to
  /// push one into the other. It cannot be done from `build`: `update` calls
  /// `notifyListeners`, and notifying during a build throws.
  void _syncClearAvailability() {
    _clearRound.update(
      semantics: _clearSemantics,
      scope: IuxDestructiveScope.everything,
      wayBack: const IuxNoWayBack(),
      prompt: const IuxConfirmationPrompt(
        title: Strings.settingsClearTitle,
        consequence: Strings.settingsClearConsequence,
        confirmLabel: Strings.settingsClearConfirm,
        keepLabel: Strings.settingsClearKeep,
      ),
      availability: _jobs.isEmpty
          ? IuxActionAvailability.disabled
          : IuxActionAvailability.enabled,
    );
  }

  void _clear() {
    _jobs.clear();
    // The destructive pattern emits no feedback of its own — deliberately, and
    // documented. `IuxAsyncActionButton` does the opposite: it takes the event
    // through the outcome and emits it for you. Same concept, two contracts,
    // so this call site exists and the one on the detail screen's completion
    // does not.
    //
    // No `semanticMessage`: the transient notice below is a live region
    // carrying the same sentence, and an announcement as well would say it
    // twice. That leaves the haptic, which is the half a live region cannot
    // do.
    unawaited(
      IuxFeedbackScope.of(context).emit(
        context,
        const IuxFeedbackEvent.destructive(),
      ),
    );
    _post(
      const IuxTransientMessage(
        text: Strings.settingsCleared,
        dismissLabel: Strings.settingsClearedDismiss,
      ),
    );
  }

  void _post(IuxTransientMessage message) {
    setState(() => _notice = message);
  }

  void _dismissNotice() => setState(() => _notice = null);

  void _handleAdded(Job job) {
    _post(
      IuxTransientMessage(
        text: Strings.formAdded(job.reference),
        dismissLabel: Strings.formAddedDismiss,
        tone: IuxTransientTone.success,
      ),
    );
    setState(() => _destination = 0);
  }

  void _open(Job job) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => JobDetailScreen(
          jobs: _jobs,
          jobId: job.id,
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[_jobs, _clearRound]),
        builder: (BuildContext context, Widget? child) => Scaffold(
          // `IuxDialog` does not answer the Android back button, by design:
          // back is navigation and navigation is the application's. So every
          // application that shows one writes this, and an application that
          // forgets it ships a modal the platform's own primary gesture cannot
          // dismiss. Android is this project's platform priority, which makes
          // it the one place the omission is least affordable.
          body: PopScope(
            canPop: _clearRound.dialog == null,
            onPopInvokedWithResult: (bool didPop, Object? result) {
              if (!didPop) _clearRound.cancel();
            },
            child: _shell(context),
          ),
        ),
      );

  /// The navigation, the overlays, and the screen currently showing.
  ///
  /// The modal layer is outside the navigation and the transient layer is
  /// inside it, and the order is not a preference.
  ///
  /// A dialog must cover the navigation: it is a question, and a user who can
  /// change section while it is open answers it about a screen they have left.
  /// A transient notice must not: `IuxTransientLayer` pins its message to the
  /// bottom of whatever it wraps and reserves no space for it, so wrapped
  /// around the whole shell it lands on top of the bottom navigation bar.
  /// Measured on a 360x800 window: the notice occupies y 712-760, the three
  /// destinations sit at y 740-786, and all three report `hitTestable = 0` for
  /// the whole dwell — a minimum of four seconds, which by design cannot be
  /// shortened. Every "visit added" would have cost the user their ability to
  /// change section.
  Widget _shell(BuildContext context) => IuxModalLayer(
        dialog: _clearRound.dialog,
        child: IuxAdaptiveNavigation(
          label: Strings.navigationLabel,
          selectedIndex: _destination,
          onDestinationSelected: (int index) =>
              setState(() => _destination = index),
          destinations: <IuxNavigationDestination>[
            IuxNavigationDestination(
              label: Strings.navJobs,
              icon: Icons.list_outlined,
              selectedIcon: Icons.list,
              badge: _jobs.outstanding == 0
                  ? null
                  : IuxBadge.count(
                      count: '${_jobs.outstanding}',
                      label: Strings.outstandingBadge(_jobs.outstanding),
                    ),
            ),
            const IuxNavigationDestination(
              label: Strings.navNew,
              icon: Icons.add_circle_outline,
              selectedIcon: Icons.add_circle,
            ),
            const IuxNavigationDestination(
              label: Strings.navSettings,
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings,
            ),
          ],
          child: IuxTransientLayer(
            message: _notice,
            onDismissed: _dismissNotice,
            child: switch (_destination) {
              0 => JobsScreen(
                  jobs: _jobs,
                  onCreateRequested: () => setState(() => _destination = 1),
                  onOpen: _open,
                ),
              1 => NewJobScreen(
                  jobs: _jobs,
                  onAdded: _handleAdded,
                  remindersEnabled: _permission == ReminderPermission.granted,
                  onReminderRequested: () => setState(() => _destination = 2),
                ),
              _ => SettingsScreen(
                  configuration: widget.configuration,
                  onConfigurationChanged: widget.onConfigurationChanged,
                  permission: _permission,
                  onPermissionChanged: (ReminderPermission value) =>
                      setState(() => _permission = value),
                  clearRound: _clearRound,
                ),
            },
          ),
        ),
      );
}
