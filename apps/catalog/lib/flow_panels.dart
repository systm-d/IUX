import 'package:flutter/material.dart';
import 'package:iux_flutter/iux_flutter.dart';

import 'catalog_chrome.dart';
import 'catalog_overlays.dart';
import 'catalog_testable.dart';

/// The patterns that run when there is nothing to show, or it failed.
///
/// Every one of these is a screen a user reaches on their worst day: a list
/// with nothing in it, a request that did not come back, a permission they
/// once refused. They are also the screens least often built, because a
/// developer testing their own feature has data, a connection and every
/// permission granted.
///
/// So the harness supplies the bad day. Each panel switches between the
/// branches by hand, and several of them build the limitation the
/// documentation records rather than avoiding it.
///
/// The onboarding flow at the end is the one exception to the "worst day"
/// framing, and it earns its place here for the opposite reason: it is the
/// screen a user reaches on their *first* day, before they have asked for
/// anything at all. Everything it costs is charged to somebody who opened the
/// application to do something else — which is why the branch that matters
/// most in it is the one where they leave.
class FlowPanels extends StatelessWidget {
  /// Creates the pattern harness.
  const FlowPanels({
    super.key,
    required this.longLabels,
    required this.overlays,
  });

  /// Whether samples use text of translated length.
  final bool longLabels;

  /// The page's overlay owner, which the destructive flow depends on.
  final CatalogOverlays overlays;

  @override
  Widget build(BuildContext context) => Column(
        children: <Widget>[
          _EmptyStatePanel(longLabels: longLabels),
          _ErrorRecoveryPanel(longLabels: longLabels),
          _LoadingRetryPanel(longLabels: longLabels),
          _PermissionPanel(longLabels: longLabels),
          _DestructiveFlowPanel(longLabels: longLabels, overlays: overlays),
          _DisclosurePanel(longLabels: longLabels),
          _OnboardingPanel(longLabels: longLabels),
          const _FlowRefusalPanel(),
        ],
      );
}

/// The words the pattern harness uses.
abstract final class _Copy {
  static const String shortGuidance =
      'Create one from the button above, or ask a colleague to share theirs.';
  static const String longGuidance =
      'Erstellen Sie eine Rechnung über die Schaltfläche oben, oder bitten '
      'Sie eine Kollegin darum, Ihnen ihre freizugeben — beides führt zum '
      'selben Ergebnis.';

  static const String shortFailure = 'The invoice service did not answer.';
  static const String longFailure =
      'Der Rechnungsdienst hat nicht geantwortet. Möglicherweise besteht '
      'derzeit keine Verbindung zum Firmennetzwerk.';

  static String guidance({required bool long}) =>
      long ? longGuidance : shortGuidance;

  static String failure({required bool long}) =>
      long ? longFailure : shortFailure;
}

/// Which absence is being shown.
enum _Absence {
  /// Nothing has ever been created, and the user can create one.
  nothingYet('nothing created yet — with a way to create one'),

  /// Nothing has ever been created, and creating is somebody else's job.
  nothingYetNoAction('nothing created yet — guidance only, no control'),

  /// A filter matched nothing. The way back is required by the type.
  noMatches('no matches — the reset is not optional'),

  /// The user may not see this, and can ask.
  restricted('access restricted — with a way to ask'),

  /// The list is empty because the work is finished.
  finished('nothing left to do — the one cause owing no way forward');

  const _Absence(this.title);

  final String title;
}

class _EmptyStatePanel extends StatefulWidget {
  const _EmptyStatePanel({required this.longLabels});

  final bool longLabels;

  @override
  State<_EmptyStatePanel> createState() => _EmptyStatePanelState();
}

class _EmptyStatePanelState extends State<_EmptyStatePanel> {
  _Absence _absence = _Absence.nothingYet;
  IuxEmptyStateArrival _arrival = IuxEmptyStateArrival.afterAChange;
  int _acted = 0;

  IuxEmptyStateAction _action(String label, String announced) =>
      IuxEmptyStateAction(
        label: label,
        action: IuxActionDescriptor(
          semantics: IuxActionSemantics(label: announced),
        ),
        onActivate: () => setState(() => _acted++),
      );

  IuxEmptyStateCause get _cause => switch (_absence) {
        _Absence.nothingYet => IuxNothingCreatedYet(
            create: _action('New invoice', 'Create the first invoice'),
          ),
        _Absence.nothingYetNoAction => const IuxNothingCreatedYet(),
        _Absence.noMatches => IuxNoMatches(
            reset: _action('Clear the filters', 'Clear every filter'),
          ),
        _Absence.restricted => IuxAccessRestricted(
            request: _action('Ask for access', 'Ask for access to invoices'),
          ),
        _Absence.finished => const IuxNothingLeftToDo(),
      };

  /// The guidance, which is not decoration in two of these branches.
  ///
  /// `IuxNothingCreatedYet` with neither a control nor guidance asserts, and
  /// so does `IuxAccessRestricted`: a cause that owes the user a way forward
  /// and supplies neither is a dead end, which is the one arrangement the
  /// pattern exists to refuse. `IuxNothingLeftToDo` is the exemption, because
  /// finishing is not a problem to be solved.
  String? get _guidance => switch (_absence) {
        _Absence.finished => null,
        _ => _Copy.guidance(long: widget.longLabels),
      };

  /// Whether the cause on screen offers the user anything to press.
  ///
  /// Two of the five deliberately do not: guidance-only and "nothing left to
  /// do", which is the one cause that owes the user no way forward. Framing
  /// those would put "Test it" around a paragraph.
  bool get _responds => switch (_absence) {
        _Absence.nothingYet ||
        _Absence.noMatches ||
        _Absence.restricted =>
          true,
        _Absence.nothingYetNoAction || _Absence.finished => false,
      };

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);

    final Widget sample = IuxSurface(
      role: IuxSurfaceRole.subtle,
      bordered: true,
      padding: IuxInsets.surface(context),
      child: IuxEmptyState(
        cause: _cause,
        title: widget.longLabels
            ? 'Noch keine Rechnungen in diesem Zeitraum'
            : 'No invoices yet',
        guidance: _guidance,
        arrival: _arrival,
        illustration: Icons.inbox_outlined,
      ),
    );

    return CatalogPanel(
      title: 'Nothing to show, and why',
      description: 'An empty list is not a state — it is five different '
          'situations that happen to render the same number of rows, and the '
          'user needs to know which one they are in. The cause is a sealed '
          'type rather than a flag, so "empty" alone is not expressible. Walk '
          'the five and read what changes: the title, the guidance, and '
          'whether there is anything to press.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CatalogChoice<_Absence>(
            label: 'Cause',
            value: _absence,
            values: _Absence.values,
            naming: (_Absence value) => value.title,
            onChanged: (_Absence value) => setState(() => _absence = value),
          ),
          CatalogChoice<IuxEmptyStateArrival>(
            label: 'Arrival',
            value: _arrival,
            values: IuxEmptyStateArrival.values,
            naming: (IuxEmptyStateArrival value) => value.name,
            onChanged: (IuxEmptyStateArrival value) =>
                setState(() => _arrival = value),
          ),
          SizedBox(height: geometry.spacingXs),
          if (_responds)
            CatalogTestable(
              what: 'Press the control the cause offers: the count below '
                  'climbs. Two of the five causes offer none at all, and then '
                  'this frame is not here.',
              child: sample,
            )
          else
            sample,
          SizedBox(height: geometry.spacingXs),
          CatalogRows(<(String, String)>[
            ('The control was activated', '$_acted time(s)'),
          ]),
          const CatalogNote(
            'The arrival decides whether the block is a live region. Arriving '
            'after a change — a filter the user just applied — it announces '
            'itself, because the user acted and is waiting for the result. '
            'Arriving with the screen it does not: a screen that announces its '
            'own emptiness before the user has done anything is talking over '
            'the heading they were about to hear.',
          ),
          const CatalogNote(
            'A live region is a request, not a guarantee. The widget test can '
            'assert that the flag reached the node and no further; whether '
            'TalkBack speaks it, and when, is Android\'s decision. Nothing '
            'essential rides on it — the same words are on screen either way.',
          ),
          const CatalogNote(
            'No count anywhere. "0 of 42 invoices" is the caller\'s sentence '
            'for the same reason the validation summary\'s count is a '
            'function: plural forms differ by language, and IUX composes no '
            'user-facing text.',
          ),
        ],
      ),
    );
  }
}

/// Which way out of a failure the pattern is offering.
enum _Route {
  /// The same request, again.
  retry('retry'),

  /// The same request, again, while it is already running.
  retryRunning('retry — already running'),

  /// A different route to the same goal.
  alternative('an alternative route'),

  /// No route at all, and words instead.
  unrecoverable('unrecoverable — guidance instead of a control');

  const _Route(this.title);

  final String title;
}

class _ErrorRecoveryPanel extends StatefulWidget {
  const _ErrorRecoveryPanel({required this.longLabels});

  final bool longLabels;

  @override
  State<_ErrorRecoveryPanel> createState() => _ErrorRecoveryPanelState();
}

class _ErrorRecoveryPanelState extends State<_ErrorRecoveryPanel> {
  _Route _route = _Route.retry;
  int _retries = 0;
  int _alternatives = 0;

  IuxRecoveryRoute get _recovery => switch (_route) {
        _Route.retry => IuxRetryRoute(
            label: 'Try again',
            onRetry: () => setState(() => _retries++),
          ),
        _Route.retryRunning => IuxRetryRoute(
            label: 'Try again',
            onRetry: () => setState(() => _retries++),
            isRunning: true,
            busyHint: 'Asking the invoice service again',
          ),
        _Route.alternative => IuxAlternativeRoute(
            action: IuxNamedAction(
              label: 'Open the saved copy',
              onActivate: () => setState(() => _alternatives++),
            ),
          ),
        _Route.unrecoverable => IuxUnrecoverable(
            guidance: widget.longLabels
                ? 'Diese Rechnung wurde vor der Archivierung gelöscht und '
                    'kann nicht wiederhergestellt werden. Die Buchhaltung '
                    'hält eine Papierkopie.'
                : 'This invoice was deleted before it was archived. '
                    'Accounting keeps a paper copy.',
          ),
      };

  /// Whether the route on screen offers anything a press can reach.
  ///
  /// The running retry is the one that has to be measured rather than assumed:
  /// it looks exactly like the idle one and its node offers the focus action
  /// and *not* tap, because the policy declines a second activation. The
  /// unrecoverable route offers words instead of a control by design.
  bool get _responds => switch (_route) {
        _Route.retry || _Route.alternative => true,
        _Route.retryRunning || _Route.unrecoverable => false,
      };

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);

    final Widget sample = IuxErrorRecovery(
      route: _recovery,
      categoryLabel: 'Error',
      message: _Copy.failure(long: widget.longLabels),
    );

    return CatalogPanel(
      title: 'A failure, and the way out of it',
      description: 'Three shapes of exit and one refusal to pretend there is '
          'one. The route is a sealed type, so a failure with no way out has '
          'to say so in words rather than by rendering a message and stopping '
          '— which is what a dead end looks like when nobody decided to build '
          'it.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CatalogChoice<_Route>(
            label: 'Route',
            value: _route,
            values: _Route.values,
            naming: (_Route value) => value.title,
            onChanged: (_Route value) => setState(() => _route = value),
          ),
          SizedBox(height: geometry.spacingXs),
          if (_responds)
            CatalogTestable(
              what: 'Press the way out: the count below climbs. Switch to the '
                  'running retry and this frame goes — that control is not '
                  'accepting a press, and nothing about it says so.',
              child: sample,
            )
          else
            sample,
          SizedBox(height: geometry.spacingXs),
          CatalogRows(<(String, String)>[
            ('Retries', '$_retries'),
            ('Alternative taken', '$_alternatives'),
          ]),
          const CatalogNote(
            'The category word is the caller\'s and it is required. Colour '
            'alone does not say "error", and a red block with no word is a red '
            'block to a user who cannot see red — which is the whole of '
            'IUX-A11Y-004 in one parameter.',
          ),
          const CatalogNote(
            'Whether a failure is worth retrying is not checked and cannot be. '
            'A retry offered for a deleted invoice is a button that fails '
            'identically every time, and only the application knows the '
            'difference. That is why IuxUnrecoverable exists as a peer rather '
            'than as a null route.',
          ),
          const CatalogNote(
            'The "already running" route is the one to look at with the '
            'semantics tree in mind. A running retry used to be announced as '
            '*unavailable* and dropped out of the focus order, because one '
            'flag fed both the announced enabled state and the focus node. '
            'IuxButton now keeps the focus, reports itself enabled, carries '
            'its busyHint and offers the focus action but not tap — measured, '
            'not read — and docs/patterns/loading-and-retry.md and the '
            'IuxLoadingRetry docstring agree about it, which they did not '
            'while this note was first written.',
          ),
          const CatalogNote(
            'One control, and no error code. A failure the user must resolve '
            'by choosing between three things is a decision, and a decision '
            'belongs on a screen where the options sit side by side. There is '
            'deliberately no slot that would tempt an application to print a '
            'stack trace at a user.',
          ),
        ],
      ),
    );
  }
}

class _LoadingRetryPanel extends StatefulWidget {
  const _LoadingRetryPanel({required this.longLabels});

  final bool longLabels;

  @override
  State<_LoadingRetryPanel> createState() => _LoadingRetryPanelState();
}

class _LoadingRetryPanelState extends State<_LoadingRetryPanel> {
  IuxLoadState<String> _state = const IuxLoadState<String>.loading();
  int _retries = 0;

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme type = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);

    final Map<String, IuxLoadState<String>> states =
        <String, IuxLoadState<String>>{
      'loading': const IuxLoadState<String>.loading(),
      'ready': IuxLoadState<String>.ready(
        widget.longLabels
            ? 'Zahlungsbestätigung für die Märzrechnung der Nordwind GmbH, '
                'einschließlich dreier Anhänge.'
            : 'The March invoice arrived.',
      ),
      'failed': IuxLoadState<String>.failed(
        message: _Copy.failure(long: widget.longLabels),
      ),
    };

    final Widget region = IuxLoadingRetry<String>(
      state: _state,
      loadingLabel: 'Fetching the March invoice',
      failureCategoryLabel: 'Error',
      recovery: IuxRetryRoute(
        label: 'Try again',
        onRetry: () => setState(() {
          _retries++;
          _state = states['ready']!;
        }),
      ),
      builder: (BuildContext context, String value) => Text(
        value,
        style: type.body.copyWith(color: colors.content.primary),
      ),
    );

    return CatalogPanel(
      title: 'Waiting, arriving, failing',
      description: 'One region, three branches, and no fourth. There is no '
          '"loaded but empty" branch, because empty is a cause rather than a '
          'load state and IuxEmptyState owns it — a region that rendered a '
          'blank list on success would be the failure the empty-state pattern '
          'exists to prevent, reached by a different road.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CatalogChoice<String>(
            label: 'Load state',
            value: states.entries
                .firstWhere((MapEntry<String, IuxLoadState<String>> entry) =>
                    entry.value.runtimeType == _state.runtimeType)
                .key,
            values: states.keys.toList(),
            naming: (String value) => value,
            onChanged: (String value) =>
                setState(() => _state = states[value]!),
          ),
          SizedBox(height: geometry.spacingXs),
          // Only the failed branch has anything in it to press. Waiting and
          // arrived are a label and a paragraph, and a frame around either
          // would be telling the reader to press a sentence.
          if (_state is IuxLoadFailed<String>)
            CatalogTestable(
              what: 'Press "Try again": the content arrives and the retry '
                  'count climbs. Do it with a keyboard and watch where focus '
                  'lands — the control you pressed is gone by then.',
              child: region,
            )
          else
            region,
          SizedBox(height: geometry.spacingXs),
          CatalogRows(<(String, String)>[('Retries', '$_retries')]),
          const CatalogNote(
            'Press "Try again" with a keyboard rather than a finger. The '
            'control the user just activated is unmounted when the content '
            'arrives, so Flutter hands focus back to the nearest enclosing '
            'scope and the user resumes somewhere they did not ask to be. The '
            'pattern refuses to paper over it: every fix is a focus move onto '
            'a node that would itself vanish, which is two interruptions in '
            'place of one.',
            finding: true,
          ),
          const CatalogNote(
            'Nothing scrolls. At 300% with long labels the arrived branch is '
            'several lines and the region simply grows — the page scrolls, not '
            'the region. A block placed inside a list that already scrolls '
            'must not introduce a second one, which is the same rule the '
            'search results and the empty state both inherit.',
          ),
        ],
      ),
    );
  }
}

/// Where in a permission conversation the user is.
enum _Moment {
  /// Nothing has been asked yet.
  before('before asking'),

  /// The user said no, and may be asked once more.
  refused('after a refusal — with a second ask'),

  /// The user said no and the offer is not repeated.
  refusedFinal('after a refusal — no second ask'),

  /// Android will not show the sheet again.
  blocked('the system will not ask — settings only'),

  /// Android will not show the sheet again and there is nowhere to send them.
  blockedNoRoute('the system will not ask — guidance only');

  const _Moment(this.title);

  final String title;
}

class _PermissionPanel extends StatefulWidget {
  const _PermissionPanel({required this.longLabels});

  final bool longLabels;

  @override
  State<_PermissionPanel> createState() => _PermissionPanelState();
}

class _PermissionPanelState extends State<_PermissionPanel> {
  _Moment _moment = _Moment.before;
  int _asked = 0;
  int _declined = 0;

  IuxNamedAction _ask(String label) => IuxNamedAction(
        label: label,
        onActivate: () => setState(() => _asked++),
      );

  IuxNamedAction get _decline => IuxNamedAction(
        label: 'Not now',
        onActivate: () => setState(() => _declined++),
      );

  IuxPermissionMoment get _permission => switch (_moment) {
        _Moment.before => IuxBeforeAsking(
            ask: _ask('Allow the camera'),
            decline: _decline,
          ),
        _Moment.refused => IuxAfterRefusal(
            askAgain: _ask('Allow the camera'),
            decline: _decline,
          ),
        _Moment.refusedFinal => IuxAfterRefusal(decline: _decline),
        _Moment.blocked => IuxSystemWillNotAsk(
            openSettings: _ask('Open the settings'),
            decline: _decline,
          ),
        _Moment.blockedNoRoute => IuxSystemWillNotAsk(decline: _decline),
      };

  /// Guidance, which two of these moments cannot do without.
  ///
  /// A moment with neither a control nor guidance asserts. Unlike the empty
  /// state there is no exempt moment: a permission conversation with no way
  /// forward and nothing to read is a screen that asks for something and
  /// offers no way to give it.
  String? get _guidance => switch (_moment) {
        _Moment.refusedFinal =>
          'Photographs can still be chosen from the gallery instead.',
        _Moment.blockedNoRoute =>
          'Android will not ask again. Camera access can be restored from '
              'Settings, under Apps.',
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);

    return CatalogPanel(
      title: 'Asking for a permission, at four different moments',
      description: 'The same permission, and four conversations that are not '
          'interchangeable. Asking again after a refusal is a different act '
          'from asking the first time, and both are different from telling '
          'somebody the system will no longer ask at all. The moment is a '
          'sealed type so that a screen offering "Allow" when Android will '
          'never show the sheet — a button that provably does nothing — is not '
          'constructible.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CatalogChoice<_Moment>(
            label: 'Moment',
            value: _moment,
            values: _Moment.values,
            naming: (_Moment value) => value.title,
            onChanged: (_Moment value) => setState(() => _moment = value),
          ),
          SizedBox(height: geometry.spacingXs),
          CatalogTestable(
            what: 'Press either control: the counts below change. "Not now" is '
                'there at every moment — a rationale the user can only agree '
                'to is not a rationale — so there is always something here '
                'that answers.',
            child: IuxSurface(
              role: IuxSurfaceRole.subtle,
              bordered: true,
              padding: IuxInsets.surface(context),
              child: IuxPermissionRationale(
                moment: _permission,
                title: widget.longLabels
                    ? 'Zugriff auf die Kamera für das Abfotografieren von Belegen'
                    : 'Photograph a receipt',
                reason: widget.longLabels
                    ? 'Die Kamera wird ausschließlich verwendet, um Belege '
                        'direkt an eine Rechnung anzuhängen. Es werden keine '
                        'Aufnahmen gespeichert oder übertragen.'
                    : 'The camera is used only to attach a receipt to an '
                        'invoice. Nothing is stored or sent anywhere else.',
                guidance: _guidance,
                illustration: Icons.photo_camera_outlined,
              ),
            ),
          ),
          SizedBox(height: geometry.spacingXs),
          CatalogRows(<(String, String)>[
            ('Asked', '$_asked'),
            ('Declined', '$_declined'),
          ]),
          const CatalogNote(
            'The decline is required at every moment. A rationale the user can '
            'only agree to is not a rationale, and "Not now" that quietly does '
            'nothing is worse than no control — so the parent supplies the '
            'callback and the type refuses to let it be omitted.',
          ),
          const CatalogNote(
            'Nothing here reads the real permission status, and nothing can. A '
            'caller who passes "before asking" for a permanently denied '
            'permission renders a button that will never open a sheet, and no '
            'assertion catches it: the framework has no way to know. The type '
            'prevents the arrangement it can see, not the lie it cannot.',
          ),
          const CatalogNote(
            'The pattern starts no loop, and nothing here can stop an '
            'application asking on every launch. Cadence is the parent\'s, and '
            'it is the difference between a rationale and a nag.',
          ),
        ],
      ),
    );
  }
}

/// How much the destruction takes away, and what is offered against it.
enum _Safeguard {
  /// A few things, taken back with an undo.
  itemsUndo('items — an undo instead of a question'),

  /// A few things, asked about first.
  itemsConfirm('items — a question instead of an undo'),

  /// Everything, asked about first. The only safeguard available here.
  everythingConfirm('everything — a question, and no undo is permitted');

  const _Safeguard(this.title);

  final String title;
}

class _DestructiveFlowPanel extends StatefulWidget {
  const _DestructiveFlowPanel({
    required this.longLabels,
    required this.overlays,
  });

  final bool longLabels;
  final CatalogOverlays overlays;

  @override
  State<_DestructiveFlowPanel> createState() => _DestructiveFlowPanelState();
}

class _DestructiveFlowPanelState extends State<_DestructiveFlowPanel> {
  _Safeguard _safeguard = _Safeguard.itemsUndo;

  static const IuxConfirmationPrompt _itemsPrompt = IuxConfirmationPrompt(
    title: 'Delete the March invoice?',
    consequence: 'The invoice and its three attachments leave this device and '
        'the shared folder. Accounting keeps no copy.',
    confirmLabel: 'Delete the invoice',
    keepLabel: 'Keep the invoice',
  );

  static const IuxConfirmationPrompt _everythingPrompt = IuxConfirmationPrompt(
    title: 'Close this workspace?',
    consequence: 'Every invoice, payment and customer in it is removed for all '
        'four members. Nothing here can be recovered afterwards.',
    confirmLabel: 'Close the workspace',
    keepLabel: 'Keep the workspace',
  );

  void _choose(_Safeguard value) {
    setState(() => _safeguard = value);
    switch (value) {
      case _Safeguard.itemsUndo:
        widget.overlays.reconfigure(
          scope: IuxDestructiveScope.items,
          wayBack: widget.overlays.undoOffer,
        );
      case _Safeguard.itemsConfirm:
        widget.overlays.reconfigure(
          scope: IuxDestructiveScope.items,
          wayBack: const IuxNoWayBack(),
          prompt: _itemsPrompt,
        );
      case _Safeguard.everythingConfirm:
        widget.overlays.reconfigure(
          scope: IuxDestructiveScope.everything,
          wayBack: const IuxNoWayBack(),
          prompt: _everythingPrompt,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);

    return CatalogPanel(
      title: 'Destroying something, proportionately',
      description: 'One question decides the safeguard: could the user list '
          'what they are about to lose? A draft, forty-one selected photos, '
          'one person\'s access — they can, so an undo is enough and asking '
          'first would charge every user a step to prevent a mistake most of '
          'them never make. An account or a workspace — they cannot, so the '
          'question comes first and an undo is refused outright.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CatalogChoice<_Safeguard>(
            label: 'Safeguard',
            value: _safeguard,
            values: _Safeguard.values,
            naming: (_Safeguard value) => value.title,
            onChanged: _choose,
          ),
          SizedBox(height: geometry.spacingXs),
          CatalogTestable(
            what: 'With an undo it deletes at once and offers the way back on '
                'the strip at the bottom edge; with a question it opens the '
                'confirmation over the page first. The count below is net of '
                'undos.',
            child: IuxDestructiveFlow(
              label: widget.longLabels
                  ? 'Die Märzrechnung endgültig löschen'
                  : 'Delete',
              controller: widget.overlays.flow,
            ),
          ),
          SizedBox(height: geometry.spacingXs),
          CatalogRows(<(String, String)>[
            ('Destroyed, net of undos', '${widget.overlays.destroyed}'),
            (
              'Asks before running',
              widget.overlays.flow.asksFirst ? 'yes' : 'no'
            ),
          ]),
          const CatalogNote(
            'An undo offer replaces the question rather than joining it. A '
            'prompt beside an undo is refused, because the wording would never '
            'be shown — and a flow that both asked and offered a way back '
            'would be charging the user twice for one decision.',
          ),
          const CatalogNote(
            'The undo travels on the transient strip, which holds one message '
            'and no history. Delete twice in quick succession and the second '
            'notice replaces the first, taking the first way back with it. '
            'That is the one place the channel\'s replacement rule costs the '
            'user something they needed, and where several destructions can be '
            'in flight the way back belongs somewhere durable — a trash the '
            'user can open, which is IuxNoWayBack with the route named in the '
            'consequence.',
            finding: true,
          ),
          const CatalogNote(
            'This panel only works because the page places both layers. With '
            'no IuxModalLayer the confirmation is computed and never shown; '
            'with no IuxTransientLayer the way back is computed and never '
            'offered, and the deletion simply happens with nothing said. '
            'Nothing detects either, because nothing can from where the '
            'trigger sits — which makes "the parent must place both layers" a '
            'documentation rule guarding a silent data-loss bug.',
            finding: true,
          ),
          const CatalogNote(
            'Switching to another section while a notice is up loses the '
            'offer, exactly as navigating away from a page would. The notice '
            'is page state the parent owns, and if a destruction is worth '
            'reversing after a navigation it is worth a trash instead.',
          ),
        ],
      ),
    );
  }
}

class _DisclosurePanel extends StatefulWidget {
  const _DisclosurePanel({required this.longLabels});

  final bool longLabels;

  @override
  State<_DisclosurePanel> createState() => _DisclosurePanelState();
}

class _DisclosurePanelState extends State<_DisclosurePanel> {
  IuxDisclosureState _state = const IuxDisclosureState.collapsed();
  bool _held = false;
  bool _helpExpanded = false;

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme type = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);

    return CatalogPanel(
      title: 'Content that is not on screen yet',
      description: 'Three states, not two booleans. "Collapsed while the '
          'content must be dealt with" is the defect, and it is unconstructible '
          'rather than asserted — held open removes the toggle entirely and '
          'turns the summary into a heading, because an ignored toggle '
          'announces "expanded, button" and then does nothing.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CatalogChoice<bool>(
            label: 'Held open',
            value: _held,
            values: const <bool>[false, true],
            naming: (bool value) => value ? 'held open' : 'the user decides',
            onChanged: (bool value) => setState(() {
              _held = value;
              _state = value
                  ? const IuxDisclosureState.heldOpen()
                  : const IuxDisclosureState.collapsed();
            }),
          ),
          SizedBox(height: geometry.spacingXs),
          CatalogTestable(
            what: 'Opens and closes it. Type in the box, close it, open it '
                'again — the text is gone. Held open, the toggle is removed '
                'entirely and the summary is only a heading: there is nothing '
                'left to press, and that is the point of the third state.',
            child: IuxProgressiveDisclosure(
              summary: widget.longLabels
                  ? 'Zustelloptionen und abweichende Rechnungsanschrift'
                  : 'Delivery options',
              state: _state,
              onExpandedChanged: (bool expanded) => setState(() {
                if (_held) return;
                _state = expanded
                    ? const IuxDisclosureState.expanded()
                    : const IuxDisclosureState.collapsed();
              }),
              child: const _VolatileNote(),
            ),
          ),
          SizedBox(height: geometry.spacingXs),
          CatalogRows(<(String, String)>[
            ('State', _state.runtimeType.toString()),
          ]),
          const CatalogNote(
            'Open it, type something into the box, close it, open it again. '
            'The text is gone. A collapsed section is unmounted, so any state '
            'living inside it dies with it — which is the price of the '
            'guarantee rather than an oversight, and the reason a form section '
            'behind a disclosure has to hoist its controllers above it. This '
            'box deliberately does not.',
            finding: true,
          ),
          const CatalogNote(
            'Four things may never be disclosed: a required input, an error or '
            'its cause, the way out, and anything that costs money or consent. '
            'Exactly one of the four is enforced by a type. No widget can read '
            'a subtree and decide whether it holds a required field, and a '
            'guarantee that is a guess is worse than none — so the other three '
            'are documentation and say so.',
          ),
          const CatalogNote(
            'Revealing is eager. A section holding two hundred rows builds two '
            'hundred rows the moment it opens, and at 300% that is a frame '
            'budget as well as a scroll.',
          ),
          SizedBox(height: geometry.spacingSm),
          const CatalogSubheading('the same control, inside contextual help'),
          CatalogTestable(
            what: 'Opens and closes the help. It is the same control as the '
                'one above, built a second time — press both and look for a '
                'difference.',
            child: IuxContextualHelp(
              label: 'What is a payment reference?',
              help: 'The reference is printed on the invoice, above the total. '
                  'Quoting it lets accounting match your payment '
                  'automatically.',
              expanded: _helpExpanded,
              onExpandedChanged: (bool value) =>
                  setState(() => _helpExpanded = value),
            ),
          ),
          SizedBox(height: geometry.spacingXxs),
          Text(
            'Its state is a bool where the pattern above uses a sealed type, '
            'so "held open" has no equivalent here: a help panel the user may '
            'not close is not expressible, which is the right refusal reached '
            'by accident rather than by design.',
            style: type.supporting.copyWith(color: colors.content.secondary),
          ),
          const CatalogNote(
            'The row above is the same disclosure control with a leading help '
            'glyph — same semantics, same focusable, same floor, same chevron, '
            'implemented a second time in lib/src/components/help/. Recorded '
            'as IUX-DISCLOSURE-004, open, and reported by IUX-035 across an '
            'ownership boundary. Two *widgets* stay justified: prose has no '
            'focus order and cannot be left half filled, and a revealed form '
            'section is both. It is the control underneath that exists twice.',
            finding: true,
          ),
        ],
      ),
    );
  }
}

/// A note whose text is deliberately not hoisted above the disclosure.
///
/// Written the way a caller writes it before discovering the rule: the
/// controller belongs to the revealed subtree, so closing the section disposes
/// it and the user's typing goes with it. Hoisting it into the panel's own
/// state is the fix, and doing that here would hide the behaviour the panel is
/// meant to demonstrate.
class _VolatileNote extends StatefulWidget {
  const _VolatileNote();

  @override
  State<_VolatileNote> createState() => _VolatileNoteState();
}

class _VolatileNoteState extends State<_VolatileNote> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IuxTextField(
        input: const IuxInputDescriptor(
          semantics: IuxInputSemantics(
            label: 'Delivery note',
            hint: 'Anything the courier should know',
          ),
          helpText: 'Type here, close this section, then open it again.',
        ),
        controller: _controller,
        onChanged: (String _) {},
      );
}

/// What the step on screen is showing beyond its two sentences.
enum _StepShows {
  /// The ordinary step: a title and the sentence that has to earn the screen.
  sentences('two sentences — the ordinary step'),

  /// The one setting the documentation says is worth choosing up front.
  setting('a setting worth choosing up front'),

  /// The thing onboarding is traditionally used for, and must not be.
  permission('a permission request — the anti-pattern');

  const _StepShows(this.title);

  final String title;
}

class _OnboardingPanel extends StatefulWidget {
  const _OnboardingPanel({required this.longLabels});

  final bool longLabels;

  @override
  State<_OnboardingPanel> createState() => _OnboardingPanelState();
}

class _OnboardingPanelState extends State<_OnboardingPanel> {
  /// Owned here, because the pattern never advances itself.
  int _step = 0;

  _StepShows _shows = _StepShows.sentences;

  /// Whether the flow is squeezed into the narrowest Android width.
  ///
  /// The catalog's text-scale axis is global; its width is whatever window the
  /// harness is running in. The combination that actually breaks a row of
  /// controls is *both* — 300% text in 320dp — and this chip is the only way
  /// to reach it on a desktop or a tablet.
  bool _narrow = false;

  bool _weekly = false;
  int _left = 0;
  int _finished = 0;
  int _asked = 0;
  int _refused = 0;

  static const double _smallPhoneWidth = 320;

  List<IuxOnboardingStep> get _steps {
    final bool long = widget.longLabels;
    final Widget? content = switch (_shows) {
      _StepShows.sentences => null,
      _StepShows.setting => IuxCheckbox(
          label: long ? 'Jeden Montag erinnern' : 'Remind me every Monday',
          input: const IuxInputDescriptor(
            semantics: IuxInputSemantics(
              label: 'Remind me every Monday',
              hint: 'Can be changed later in Settings',
            ),
          ),
          value: _weekly
              ? IuxSelectionState.selected
              : IuxSelectionState.unselected,
          onChanged: (bool selected) => setState(() => _weekly = selected),
        ),
      _StepShows.permission => IuxPermissionRationale(
          moment: IuxBeforeAsking(
            ask: IuxNamedAction(
              label: 'Allow the camera',
              onActivate: () => setState(() => _asked++),
            ),
            decline: IuxNamedAction(
              label: 'Not now',
              onActivate: () => setState(() => _refused++),
            ),
          ),
          title: 'Photograph a receipt',
          reason: 'The camera is used only to attach a receipt to an invoice. '
              'Nothing is stored or sent anywhere else.',
        ),
    };

    return <IuxOnboardingStep>[
      IuxOnboardingStep(
        title: long
            ? 'Behalten Sie Ihre Ausgaben im Blick'
            : 'Track what you '
                'spend',
        body: long
            ? 'Fotografierte Belege werden ausschließlich auf diesem Gerät '
                'gelesen und niemals hochgeladen.'
            : 'Receipts are read on this device and never uploaded.',
        // Each label names the step it leads to, which is the whole reason it
        // lives on the step. This one points at "Set a budget".
        forwardLabel:
            long ? 'Sehen, wie Budgets funktionieren' : 'See how budgets work',
        content: content,
      ),
      IuxOnboardingStep(
        title: long ? 'Legen Sie ein Monatsbudget fest' : 'Set a budget',
        body: long
            ? 'Wir melden uns, sobald Sie sich der festgelegten Grenze nähern.'
            : 'We tell you when you are close to it.',
        // Points at "Share it". Under the old single-string parameter this
        // control also read "See how budgets work", on the step that came
        // after budgets — which is the defect systm-d/IUX#52 reported.
        forwardLabel:
            long ? 'Im Haushalt teilen' : 'Share it with the household',
        content: content,
      ),
      IuxOnboardingStep(
        title: long ? 'Teilen Sie es im Haushalt' : 'Share it',
        body: long
            ? 'Alle im Haushalt sehen dieselben Zahlen, ohne ein zweites Konto.'
            : 'Everyone in the household sees the same figures.',
        // The last step names nothing: `finish` is what is drawn here.
        content: content,
      ),
    ];
  }

  /// How many controls the step on screen is carrying, and what they do.
  ///
  /// Counted from the state rather than from the tree, so the arithmetic the
  /// documentation warns about is visible before the reader has to count
  /// buttons by eye. Back is neither a way forward nor a refusal: it is the
  /// way out of a mistake.
  (int, int, int) get _arithmetic {
    final int back = _step > 0 ? 1 : 0;
    final int forward = 1 + (_shows == _StepShows.permission ? 1 : 0);
    final int refusing = 1 + (_shows == _StepShows.permission ? 1 : 0);
    return (back + forward + refusing, forward, refusing);
  }

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final bool long = widget.longLabels;
    final (int controls, int forward, int refusing) = _arithmetic;

    final Widget flow = IuxOnboardingFlow(
      steps: _steps,
      currentStep: _step,
      onStepChanged: (int next) => setState(() => _step = next),
      describePosition: (int step, int count) => '$step of $count',
      backLabel: long ? 'Zurück' : 'Back',
      skip: IuxNamedAction(
        label: long ? 'Einrichtung überspringen' : 'Skip setup',
        onActivate: () => setState(() => _left++),
      ),
      finish: IuxNamedAction(
        label: long ? 'Ledger jetzt verwenden' : 'Start using Ledger',
        onActivate: () => setState(() => _finished++),
      ),
    );

    final Widget sample = IuxSurface(
      role: IuxSurfaceRole.subtle,
      bordered: true,
      padding: IuxInsets.surface(context),
      child: flow,
    );

    return CatalogPanel(
      title: 'An introduction the user did not ask for',
      description: 'Every other stepped pattern here exists because the user '
          'started something. This one exists because the application did, and '
          'that single fact is where all of its decisions come from. Walk it '
          'with the exit in mind: it is on every step, including the last, it '
          'is a full control rather than a grey word, and there is no '
          'parameter anywhere that removes it.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CatalogChoice<int>(
            label: 'Step',
            value: _step,
            values: const <int>[0, 1, 2],
            naming: (int value) => '${value + 1} of 3',
            onChanged: (int value) => setState(() => _step = value),
          ),
          CatalogChoice<_StepShows>(
            label: 'Step shows',
            value: _shows,
            values: _StepShows.values,
            naming: (_StepShows value) => value.title,
            onChanged: (_StepShows value) => setState(() => _shows = value),
          ),
          CatalogChoice<bool>(
            label: 'Window',
            value: _narrow,
            values: const <bool>[false, true],
            naming: (bool value) =>
                value ? '320dp — the narrowest phone' : 'the page width',
            onChanged: (bool value) => setState(() => _narrow = value),
          ),
          SizedBox(height: geometry.spacingXs),
          // Always framed. Unlike every other panel in this section there is
          // no branch in which the sample stops answering a press: a flow with
          // nothing to press would be a flow with no way out, and that is the
          // one arrangement this pattern makes unconstructible.
          CatalogTestable(
            what: 'Walks the flow. The exit is on every step including the '
                'last, and pressing it leaves without finishing — the two '
                'counts below are what an application uses to tell the '
                'difference. Nothing advances on its own, however long you '
                'wait.',
            child: _narrow
                ? Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: SizedBox(width: _smallPhoneWidth, child: sample),
                  )
                : sample,
          ),
          SizedBox(height: geometry.spacingXs),
          CatalogRows(<(String, String)>[
            ('Step showing', '${_step + 1} of 3'),
            ('How this flow ended', '$_left left, $_finished finished'),
            (
              'Controls on this screen',
              '$controls — $forward forward, $refusing refusing'
            ),
            if (_shows == _StepShows.permission)
              ('Permission', '$_asked asked, $_refused refused'),
          ]),
          const CatalogNote(
            'The last step is the one to look at. The control that ends the '
            'flow appears and the forward control goes, but the exit stays — '
            'drawn as a full button beside it, with the same target floor and '
            'the same place in the reading order. Removing it there is the '
            'anti-pattern the whole pattern is built against, and there is no '
            'parameter that could.',
          ),
          const CatalogNote(
            'Press a Step chip above rather than the flow\'s own controls and '
            'watch where the focus outline goes: it leaves the chip and lands '
            'on the step heading. The flow moves focus on any currentStep '
            'change and cannot tell a press inside it from a parent that '
            'changed the index for a reason of its own — which is what this '
            'chip is. Measured here, and the alternative is worse: a flow that '
            'only moved focus after its own request would arm a pending move '
            'and eventually announce nothing at all, which is IUX-039\'s '
            'finding against the two forms.',
            finding: true,
          ),
          const CatalogNote(
            'Switch "Step shows" to the permission request and read the '
            'arithmetic above: five controls, two of which go forward and two '
            'of which refuse, and the user has to work out which of the four '
            'leaves what. IUX-031\'s guarantees travel with the rationale — it '
            'still requires a reason and still draws its decline as a peer — '
            'but nothing repairs the count. That is the concrete reason to ask '
            'at the feature instead, and no assertion can see it.',
            finding: true,
          ),
          const CatalogNote(
            'The flow\'s exit is not a permission decline. Leaving says '
            'nothing about a question that was put inside one of the screens '
            'the user left, and an application that records it as an answer '
            'has recorded something the user never said.',
          ),
          const CatalogNote(
            'Set the window to 320dp and the text scale to 300%. The three '
            'controls wrap onto three rows rather than overflowing, every one '
            'stays whole and within the width, and the exit keeps the target '
            'floor. What does not survive is equal height: at 200% in 320dp '
            'the exit measures 106dp against the finishing control\'s 144, '
            'because two labels of different lengths wrap onto different '
            'numbers of lines. Both are still full buttons, which is the '
            'asymmetry the pattern actually refuses.',
          ),
          const CatalogNote(
            'There is no dot row, and the position is text. A row of decorated '
            'boxes carries position through shape and place alone, and '
            'produces no semantic node at all — measured in the pattern\'s own '
            'test, which builds the naive version deliberately as evidence for '
            'not shipping one.',
          ),
          const CatalogNote(
            'Nothing auto-advances and nothing swipes. A screen that replaces '
            'itself is a time limit on reading, and a horizontal drag has no '
            'name, no focus stop and no D-pad equivalent — on Android it is '
            'TalkBack\'s own gesture, so it never reaches the application. '
            'Wait as long as you like above: the step does not move.',
          ),
          const CatalogNote(
            'Nothing here scrolls. At 300% the block simply grows and the '
            'catalog page scrolls, which is the same rule the empty state and '
            'the search results inherit: a block placed inside a list that '
            'already scrolls must not introduce a second one.',
          ),
        ],
      ),
    );
  }
}

class _FlowRefusalPanel extends StatelessWidget {
  const _FlowRefusalPanel();

  @override
  Widget build(BuildContext context) => const CatalogPanel(
        title: 'What these patterns refuse',
        description: 'Assertions, so a release build has none of them. They '
            'are not demonstrated, because a demonstration would stop the '
            'application.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CatalogRows(<(String, String)>[
              ('an empty state with no way forward', 'a dead end'),
              ('an empty-state action carrying a confirmation', 'unhonoured'),
              ('an empty-state action with the retry role', 'not a retry'),
              ('a no-matches cause with no reset', 'not expressible at all'),
              ('a rationale with no control and no guidance', 'a dead end'),
              (
                'an undo offer for "everything"',
                'nobody can tell they need it'
              ),
              ('a prompt beside an undo offer', 'wording never shown'),
              ('no prompt and no way back', 'destruction with no question'),
              ('an empty disclosure summary', 'a control naming nothing'),
              ('an empty failure message', 'a red block saying nothing'),
              ('an onboarding flow of one step', 'a screen, not a flow'),
              ('a step outside the flow', 'it would announce "4 of 3"'),
              ('an onboarding step with no title', 'focus lands nowhere named'),
              ('an onboarding step with no body', 'a screen bought for a noun'),
              ('an unnamed back or forward control', 'announced as "button"'),
            ]),
            CatalogNote(
              'The last five are the onboarding flow\'s, and its most '
              'load-bearing refusal is not on the list because it is not an '
              'assert at all: skip and finish are required parameters, so an '
              'introduction with no way out does not compile. That is the one '
              'guarantee here a release build cannot lose.',
            ),
            CatalogNote(
              'The undo refusal is the interesting one. An undo protects only '
              'somebody who can tell they need it: a user who deleted the '
              'wrong draft knows at once, and a user who deleted an account '
              'cannot inspect what went and has usually already left the '
              'screen carrying the offer. So "everything" plus an undo is '
              'refused, and the scope parameter exists for that one refusal.',
            ),
            CatalogNote(
              'Every one of these is an assert. A release build with a dead '
              'end will render the dead end. They catch a developer, never a '
              'user — which is worth stating in the same breath as the rules '
              'themselves.',
            ),
          ],
        ),
      );
}
