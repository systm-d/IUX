import 'package:flutter/material.dart';
import 'package:iux_flutter/iux_flutter.dart';

import 'button_scenarios.dart';
import 'catalog_chrome.dart';
import 'semantics_readout.dart';

/// The button system, put under the conditions it is most likely to fail in.
///
/// Every panel states what would count as a failure before it shows anything.
/// A panel that only shows a control in a good light is a screenshot, and a
/// screenshot cannot be wrong.
///
/// Drive it from the conditions above: the accessibility profile, the text
/// scale up to 300%, and the long label. The combinations worth looking at
/// hardest are 300% with a long label, and any profile at high contrast.
class ButtonPanels extends StatelessWidget {
  /// Creates the button harness.
  const ButtonPanels({
    super.key,
    required this.scenarios,
    required this.longLabels,
  });

  /// The state the two stateful scenarios need.
  final ButtonScenarios scenarios;

  /// Whether the samples use a label of translated length.
  final bool longLabels;

  @override
  Widget build(BuildContext context) => Column(
        children: <Widget>[
          _EmphasisPanel(longLabels: longLabels),
          _IconActionPanel(longLabels: longLabels),
          _AvailabilityPanel(longLabels: longLabels),
          const _FocusPanel(),
          _OperationPanel(longLabels: longLabels),
          _WrappingPanel(longLabels: longLabels),
          _AsyncPanel(scenarios: scenarios, longLabels: longLabels),
          _DestructivePanel(scenarios: scenarios),
          const _RefusalPanel(),
        ],
      );
}

/// The visible label for the current setting.
String _label(bool long) => ButtonCopy.label(long: long);

/// A descriptor naming one intent, announced with the row it belongs to.
IuxActionDescriptor _descriptor(
  IuxActionIntent intent, {
  required bool long,
  IuxActionAvailability availability = IuxActionAvailability.enabled,
  IuxActionOperation operation = IuxActionOperation.idle,
  String? unavailabilityReason,
}) =>
    IuxActionDescriptor(
      intent: intent,
      availability: availability,
      operation: operation,
      semantics: IuxActionSemantics(
        label: ButtonCopy.announced(long: long),
        unavailabilityReason: unavailabilityReason,
      ),
    );

class _EmphasisPanel extends StatelessWidget {
  const _EmphasisPanel({required this.longLabels});

  final bool longLabels;

  /// The variants a labelled button may take.
  ///
  /// `IuxButtonVariant.icon` is absent because the constructor asserts against
  /// it: an icon variant is a square target carrying no label, so it cannot
  /// describe a button that has one.
  static const List<IuxButtonVariant> _variants = <IuxButtonVariant>[
    IuxButtonVariant.filled,
    IuxButtonVariant.outlined,
    IuxButtonVariant.tonal,
    IuxButtonVariant.text,
  ];

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);

    return CatalogPanel(
      title: 'Emphasis and meaning',
      description: 'Variant is emphasis; intent is meaning. The two are set '
          'separately, so every cell below is a legal combination — except '
          'one, which the resolver refuses. Look for a pair whose label stops '
          'being readable against its container in high contrast, and for a '
          'row that stops wrapping when the label grows.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final IuxActionIntent intent
              in IuxActionIntent.values) ...<Widget>[
            CatalogSubheading('intent: ${intent.name}'),
            Wrap(
              spacing: geometry.spacingXs,
              runSpacing: geometry.spacingXs,
              children: <Widget>[
                for (final IuxButtonVariant variant in _variants)
                  if (_isRefused(intent, variant))
                    _RefusedCell(label: variant.name)
                  else
                    CatalogSample(
                      caption: variant.name,
                      child: IuxButton(
                        label: _label(longLabels),
                        variant: variant,
                        action: _descriptor(intent, long: longLabels),
                        onActivate: () {},
                      ),
                    ),
              ],
            ),
            SizedBox(height: geometry.spacingSm),
          ],
          const CatalogNote(
            'destructive + tonal is refused by IuxButtonResolver. Tonal '
            'carries intent through its border rather than its fill, which is '
            'not enough separation for an action that destroys data. The '
            'refusal is an assertion, so it exists in debug and profile and '
            'not in a release build.',
          ),
        ],
      ),
    );
  }

  static bool _isRefused(IuxActionIntent intent, IuxButtonVariant variant) =>
      // A tonal destructive is refused because the tint reads as an ordinary
      // surface. A filled secondary or tertiary is refused because the
      // semantic layer models both as unfilled, so the fill was accepted and
      // silently discarded — measured identical to `text` before it was
      // asserted.
      (intent == IuxActionIntent.destructive &&
          variant == IuxButtonVariant.tonal) ||
      (variant == IuxButtonVariant.filled &&
          (intent == IuxActionIntent.secondary ||
              intent == IuxActionIntent.tertiary));
}

/// A cell standing in for a combination the framework will not build.
class _RefusedCell extends StatelessWidget {
  const _RefusedCell({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme type = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);

    return CatalogSample(
      caption: label,
      child: Container(
        constraints: BoxConstraints(minHeight: geometry.minimumTouchTarget),
        padding: EdgeInsets.symmetric(horizontal: geometry.spacingSm),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(
            color: colors.border.subtle,
            width: geometry.borderWidth,
          ),
        ),
        child: Text(
          'refused',
          style: type.label.copyWith(color: colors.content.secondary),
        ),
      ),
    );
  }
}

class _IconActionPanel extends StatelessWidget {
  const _IconActionPanel({required this.longLabels});

  final bool longLabels;

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);

    return CatalogPanel(
      title: 'Icon actions',
      description: 'The glyph stays small; the region that responds does not. '
          'The measured size below each control is the region, and it must '
          'never fall under the floor the profile resolved — at any text '
          'scale. Raise the scale and watch both numbers.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          IuxTargetSpacing(
            axis: Axis.horizontal,
            children: <Widget>[
              for (final (IuxActionIntent intent, IconData icon, String name)
                  in <(IuxActionIntent, IconData, String)>[
                (IuxActionIntent.primary, Icons.check, 'Accept the invoice'),
                (IuxActionIntent.secondary, Icons.search, 'Search invoices'),
                (IuxActionIntent.tertiary, Icons.close, 'Close this panel'),
                (
                  IuxActionIntent.destructive,
                  Icons.delete_outline,
                  'Delete this row'
                ),
              ])
                CatalogMeasured(
                  child: IuxIconButton(
                    icon: icon,
                    action: IuxActionDescriptor(
                      intent: intent,
                      role: IuxActionRole.custom,
                      semantics: IuxActionSemantics(label: name),
                    ),
                    onActivate: () {},
                  ),
                ),
            ],
          ),
          SizedBox(height: geometry.spacingXs),
          const CatalogNote(
            'There is no label parameter and no way to omit the accessible '
            'name: it comes from the descriptor, which the action model '
            'already requires to be non-empty. An icon-only control without a '
            'name is unusable with a screen reader, so the state is '
            'unrepresentable rather than checked.',
          ),
          const CatalogNote(
            'The icon-only destructive action here has no confirmation. It is '
            'shown because the API allows it, not because it is advisable: an '
            'unlabelled control is the easiest one to hit by accident.',
          ),
          if (longLabels)
            const CatalogNote(
              'The long-label setting changes nothing here. An icon action has '
              'no visible text to grow, so translation length reaches it only '
              'through the announced name.',
            ),
        ],
      ),
    );
  }
}

class _AvailabilityPanel extends StatelessWidget {
  const _AvailabilityPanel({required this.longLabels});

  final bool longLabels;

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);

    return CatalogPanel(
      title: 'Unavailable, with and without a reason',
      description: 'The two disabled buttons look identical. They are not: one '
          'explains itself and one leaves the user unable to tell whether they '
          'did something wrong or the feature does not apply. The readout '
          'below each is the semantics node the framework published.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const CatalogSubheading('available'),
          IuxButton(
            label: _label(longLabels),
            action: _descriptor(IuxActionIntent.primary, long: longLabels),
            onActivate: () {},
          ),
          SizedBox(height: geometry.spacingSm),
          const CatalogSubheading('unavailable, no reason given'),
          SemanticsReadout(
            child: IuxButton(
              label: _label(longLabels),
              action: _descriptor(
                IuxActionIntent.primary,
                long: longLabels,
                availability: IuxActionAvailability.disabled,
              ),
              onActivate: () {},
            ),
          ),
          SizedBox(height: geometry.spacingSm),
          const CatalogSubheading('unavailable, reason given'),
          SemanticsReadout(
            child: IuxButton(
              label: _label(longLabels),
              action: _descriptor(
                IuxActionIntent.primary,
                long: longLabels,
                availability: IuxActionAvailability.disabled,
                unavailabilityReason:
                    'Add a payment method before sending an invoice',
              ),
              onActivate: () {},
            ),
          ),
          const CatalogNote(
            'IUX holds a disabled control to 3:1 rather than letting it fade '
            'out of legibility. Check it in every profile: a disabled label '
            'nobody can read is a control nobody can identify, which is worse '
            'than one that is merely unavailable.',
          ),
        ],
      ),
    );
  }
}

class _FocusPanel extends StatelessWidget {
  const _FocusPanel();

  @override
  Widget build(BuildContext context) => const CatalogPanel(
        title: 'Focus',
        description: 'Attach a keyboard, or a D-pad, and move between these. '
            'The ring must be visible in every profile, must stay distinct '
            'from selection, and must not move the layout when it appears. '
            'The middle control is unavailable and must be skipped entirely — '
            'a focus stop that cannot be activated is a dead end the user has '
            'to escape.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            IuxTargetSpacing(
              axis: Axis.horizontal,
              children: <Widget>[
                IuxButton(
                  label: 'First',
                  variant: IuxButtonVariant.outlined,
                  action: IuxActionDescriptor(
                    semantics: IuxActionSemantics(label: 'First control'),
                  ),
                  onActivate: _noop,
                ),
                IuxButton(
                  label: 'Unavailable',
                  variant: IuxButtonVariant.outlined,
                  action: IuxActionDescriptor(
                    availability: IuxActionAvailability.disabled,
                    semantics: IuxActionSemantics(
                      label: 'Unavailable control',
                      unavailabilityReason: 'Nothing is selected',
                    ),
                  ),
                  onActivate: _noop,
                ),
                IuxButton(
                  label: 'Third',
                  variant: IuxButtonVariant.outlined,
                  action: IuxActionDescriptor(
                    semantics: IuxActionSemantics(label: 'Third control'),
                  ),
                  onActivate: _noop,
                ),
              ],
            ),
            CatalogNote(
              'The ring is drawn by IuxFocusable, not by the button. '
              'IuxButtonTokens.focused exists, IuxButtonResolver accepts a '
              'focused argument and sets it — and no button widget passes it '
              'and nothing reads it. The equivalent token on the text field is '
              'consumed; this one is dead public surface, so anyone building a '
              'control from the resolver gets a token that silently means '
              'nothing.',
              finding: true,
            ),
          ],
        ),
      );
}

class _OperationPanel extends StatelessWidget {
  const _OperationPanel({required this.longLabels});

  final bool longLabels;

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);

    return CatalogPanel(
      title: 'Where the operation is',
      description: 'A plain IuxButton renders whatever lifecycle the parent '
          'reports. These four descriptors differ only in that value. Compare '
          'them: if two of them are indistinguishable, the state they name is '
          'not being carried by anything a user can perceive.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: geometry.spacingXs,
            runSpacing: geometry.spacingXs,
            children: <Widget>[
              for (final IuxActionOperation operation
                  in IuxActionOperation.values)
                CatalogSample(
                  caption: operation.name,
                  child: IuxButton(
                    label: _label(longLabels),
                    action: _descriptor(
                      IuxActionIntent.primary,
                      long: longLabels,
                      operation: operation,
                    ),
                    onActivate: () {},
                  ),
                ),
            ],
          ),
          const CatalogNote(
            'idle, inProgress, succeeded and failed resolve to the same '
            'colours. IuxButtonStateResolver computes loading, success and '
            'error, but IuxButtonResolver gives all three the resting palette, '
            'so a plain IuxButton carrying a failed operation is '
            'pixel-identical to one that never ran.',
            finding: true,
          ),
          SizedBox(height: geometry.spacingSm),
          const CatalogSubheading('inProgress, with no busy hint'),
          const SemanticsReadout(
            child: IuxButton(
              label: 'Send',
              action: IuxActionDescriptor(
                intent: IuxActionIntent.primary,
                operation: IuxActionOperation.inProgress,
                semantics: IuxActionSemantics(label: 'Send the March invoice'),
              ),
              onActivate: _noop,
            ),
          ),
          const CatalogNote(
            'A running action with the default repeat policy is not '
            'activatable, so the button is published as disabled and drops out '
            'of focus traversal — while looking exactly like an available one. '
            'A keyboard user standing on it when the operation starts loses '
            'their place, and a screen-reader user is told the control is '
            'disabled rather than busy. IuxAsyncActionButton avoids this by '
            'swapping the label and supplying busyHint; a plain IuxButton '
            'given operation: inProgress does not.',
            finding: true,
          ),
          SizedBox(height: geometry.spacingSm),
          const CatalogSubheading('inProgress, with a busy hint supplied'),
          const SemanticsReadout(
            child: IuxButton(
              label: 'Sending…',
              busyHint: 'Sending',
              action: IuxActionDescriptor(
                intent: IuxActionIntent.primary,
                operation: IuxActionOperation.inProgress,
                semantics: IuxActionSemantics(label: 'Send the March invoice'),
              ),
              onActivate: _noop,
            ),
          ),
          const CatalogNote(
            'The hint arrives, and the control is still published as disabled. '
            'The hint is the only thing distinguishing busy from unavailable.',
          ),
        ],
      ),
    );
  }
}

/// A callback that does nothing, so a sample can be `const`.
void _noop() {}

class _WrappingPanel extends StatelessWidget {
  const _WrappingPanel({required this.longLabels});

  final bool longLabels;

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final String label = _label(longLabels);

    return CatalogPanel(
      title: 'Room to wrap',
      description: 'A label is never truncated: an action the user cannot read '
          'is an action they cannot identify, and truncation gets worse '
          'exactly when someone has enlarged their text. Set the text scale to '
          '300% and turn long labels on. Nothing here may clip, and no black '
          'and yellow overflow stripe may appear.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const CatalogSubheading('natural width'),
          CatalogMeasured(
            child: IuxButton(
              label: label,
              action: _descriptor(IuxActionIntent.primary, long: longLabels),
              onActivate: () {},
            ),
          ),
          SizedBox(height: geometry.spacingSm),
          const CatalogSubheading('expand: fills the width it is offered'),
          IuxButton(
            label: label,
            expand: true,
            action: _descriptor(IuxActionIntent.primary, long: longLabels),
            onActivate: () {},
          ),
          SizedBox(height: geometry.spacingSm),
          const CatalogSubheading('squeezed into 140 logical pixels'),
          SizedBox(
            width: 140,
            child: IuxButton(
              label: label,
              action: _descriptor(IuxActionIntent.secondary, long: longLabels),
              onActivate: () {},
            ),
          ),
          SizedBox(height: geometry.spacingSm),
          const CatalogSubheading(
              'with a leading icon, which takes its own width'),
          SizedBox(
            width: 140,
            child: IuxButton(
              label: label,
              icon: Icons.send,
              action: _descriptor(IuxActionIntent.secondary, long: longLabels),
              onActivate: () {},
            ),
          ),
          SizedBox(height: geometry.spacingSm),
          const CatalogSubheading('two actions sharing one row'),
          IuxTargetSpacing(
            axis: Axis.horizontal,
            children: <Widget>[
              const IuxButton(
                label: 'Keep it',
                variant: IuxButtonVariant.outlined,
                action: IuxActionDescriptor(
                  role: IuxActionRole.dismiss,
                  semantics: IuxActionSemantics(label: 'Keep the invoice'),
                ),
                onActivate: _noop,
              ),
              IuxButton(
                label: label,
                action: _descriptor(IuxActionIntent.primary, long: longLabels),
                onActivate: () {},
              ),
            ],
          ),
          const CatalogNote(
            'IuxTargetSpacing keeps the two apart by the minimum target '
            'spacing, so a mistap on one does not land on the other, and it is '
            'a Wrap rather than a Row: when they no longer fit side by side '
            'they move to a second line instead of overflowing. Check at 300% '
            'that the order still reads correctly once they do — the dismissal '
            'ends up above the confirming action, not beside it.',
          ),
          SizedBox(height: geometry.spacingSm),
          const CatalogSubheading('inside a Center, which used to be a defect'),
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: IuxSemanticColors.of(context).border.subtle,
                width: geometry.borderWidth,
              ),
            ),
            child: const Center(
              child: IuxButton(
                label: 'Send',
                action: IuxActionDescriptor.primary(
                  semantics:
                      IuxActionSemantics(label: 'Send the March invoice'),
                ),
                onActivate: _noop,
              ),
            ),
          ),
          const CatalogNote(
            'IUX-008.4 shipped a button that grew to fill whatever its parent '
            'offered — a 792-pixel target that still announced itself as a '
            'button. The box above is 120 tall; the button must not be.',
          ),
        ],
      ),
    );
  }
}

class _AsyncPanel extends StatelessWidget {
  const _AsyncPanel({required this.scenarios, required this.longLabels});

  final ButtonScenarios scenarios;
  final bool longLabels;

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);

    return CatalogPanel(
      title: 'An action that takes time',
      description: 'Three seconds of work, and the operation decides what it '
          'reports. There is no spinner anywhere in this component: under a '
          'no-motion preference a spinner would be the only carrier of the '
          'busy state and would be removed, so the busy state is a word '
          'instead. Set motion to none above and check the busy state still '
          'reads.',
      child: ListenableBuilder(
        listenable: scenarios,
        builder: (BuildContext context, Widget? child) {
          final IuxAsyncActionState state = scenarios.async.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CatalogChoice<AsyncOutcomeChoice>(
                label: 'Outcome',
                value: scenarios.outcome,
                values: AsyncOutcomeChoice.values,
                naming: (AsyncOutcomeChoice value) => value.name,
                onChanged: scenarios.chooseOutcome,
              ),
              CatalogChoice<IuxActionCancellation>(
                label: 'Cancellation',
                value: scenarios.cancellation,
                values: IuxActionCancellation.values,
                naming: (IuxActionCancellation value) => value.name,
                onChanged: scenarios.chooseCancellation,
              ),
              CatalogChoice<IuxActionRepeatPolicy>(
                label: 'Repeat',
                value: scenarios.repeat,
                values: IuxActionRepeatPolicy.values,
                naming: (IuxActionRepeatPolicy value) => value.name,
                onChanged: scenarios.chooseRepeat,
              ),
              CatalogNote(
                state.isRunning
                    ? 'The three choices above are frozen while the operation '
                        'runs: the controller refuses to be redescribed '
                        'mid-run.'
                    : 'Start the action, then try tapping it again before it '
                        'finishes.',
              ),
              SizedBox(height: geometry.spacingXs),
              IuxAsyncActionButton(
                controller: scenarios.async,
                label: _label(longLabels),
                busyLabel: 'Sending…',
                cancelLabel: scenarios.cancelLabel,
              ),
              SizedBox(height: geometry.spacingSm),
              CatalogRows(<(String, String)>[
                ('Lifecycle', state.operation.name),
                ('Runs started', state.generation.toString()),
                (
                  'Stop requested',
                  state.cancellationRequested ? 'yes' : 'no',
                ),
                (
                  'Failure carries wording',
                  switch (state.failure) {
                    null => 'no failure',
                    final IuxAsyncFailure failure =>
                      failure.isExplained ? 'yes' : 'no — it was raised',
                  },
                ),
              ]),
              SizedBox(height: geometry.spacingXs),
              IuxButton(
                label: 'Reset',
                variant: IuxButtonVariant.text,
                action: const IuxActionDescriptor(
                  semantics: IuxActionSemantics(
                    label: 'Reset the demonstration action',
                  ),
                ),
                onActivate: scenarios.resetAsync,
              ),
              const CatalogNote(
                'The raised outcome finishes with no wording and nothing on '
                'screen: the failure message only appears when the operation '
                'supplied one, and the failed button is drawn exactly like an '
                'idle one. An exception is not a sentence and the framework '
                'refuses to invent one — but the result is a control that ran, '
                'failed, and says nothing at all until the parent maps the '
                'error to words.',
                finding: true,
              ),
              const CatalogNote(
                'With repeat: allow, a second activation starts a second run '
                'and the first result is discarded. Watch "Runs started" climb '
                'while the lifecycle stays inProgress.',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DestructivePanel extends StatelessWidget {
  const _DestructivePanel({required this.scenarios});

  final ButtonScenarios scenarios;

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);

    return CatalogPanel(
      title: 'An action worth being careful about',
      description: 'Two ways to protect one invoice. The reversible one runs '
          'on the first tap and offers a way back; the irreversible one asks '
          'first. The pattern refuses to confirm something reversible, because '
          'confirming everything trains people to dismiss confirmations '
          'unread.',
      child: ListenableBuilder(
        listenable: scenarios,
        builder: (BuildContext context, Widget? child) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const CatalogSubheading(
                'reversible — runs immediately, undo offered'),
            IuxTargetSpacing(
              axis: Axis.horizontal,
              children: <Widget>[
                IuxDestructiveAction(
                  label: 'Archive',
                  controller: scenarios.archive,
                ),
                if (scenarios.archived)
                  IuxButton(
                    label: 'Undo',
                    variant: IuxButtonVariant.outlined,
                    action: const IuxActionDescriptor(
                      role: IuxActionRole.undo,
                      semantics: IuxActionSemantics(
                        label: 'Undo archiving the March invoice',
                      ),
                    ),
                    onActivate: scenarios.restore,
                  ),
              ],
            ),
            CatalogNote(
              scenarios.archived
                  ? 'Archived. The undo offer is the parent\'s: how long an '
                      'application holds an archived row before committing is '
                      'not something a widget can know.'
                  : 'Nothing has been archived yet.',
            ),
            SizedBox(height: geometry.spacingSm),
            const CatalogSubheading('irreversible — asks first'),
            IuxDestructiveAction(
              label: 'Delete',
              controller: scenarios.delete,
            ),
            CatalogNote(
              scenarios.deleted
                  ? 'Deleted, after the confirmation was answered.'
                  : 'Nothing has been deleted yet. Activating this opens the '
                      'confirmation through the page\'s IuxModalLayer — with '
                      'no such layer reading controller.dialog, the '
                      'confirmation would be computed, never shown, and the '
                      'button would appear inert.',
            ),
            SizedBox(height: geometry.spacingSm),
            const CatalogSubheading('the same descriptor on a plain IuxButton'),
            IuxButton(
              label: 'Delete',
              action: const IuxActionDescriptor.destructive(
                semantics: IuxActionSemantics(
                  label: 'Delete the March invoice without asking',
                ),
              ),
              onActivate: scenarios.runUnguarded,
            ),
            CatalogNote(
              'Ran ${scenarios.unguardedRuns} time(s) without anybody being '
              'asked. IuxButton evaluates an action with the confirmation '
              'treated as already obtained, because obtaining it belongs to a '
              'pattern. The descriptor says "confirm me", the code compiles, '
              'and nobody is ever asked — which is why IuxDestructiveAction '
              'exists. Nothing at the call site distinguishes the two, and '
              'nothing warns.',
              finding: true,
            ),
            SizedBox(height: geometry.spacingSm),
            IuxButton(
              label: 'Restore everything',
              variant: IuxButtonVariant.text,
              action: const IuxActionDescriptor(
                role: IuxActionRole.undo,
                semantics:
                    IuxActionSemantics(label: 'Restore the demonstration'),
              ),
              onActivate: scenarios.restore,
            ),
          ],
        ),
      ),
    );
  }
}

class _RefusalPanel extends StatelessWidget {
  const _RefusalPanel();

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);

    return CatalogPanel(
      title: 'What the API refuses, and what it does not',
      description: 'These combinations fail on an assertion rather than being '
          'silently corrected: quietly repairing a contradiction hides the '
          'fact that the caller believed something untrue. They are not '
          'demonstrated here, because a demonstration would stop the '
          'application.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const CatalogRows(<(String, String)>[
            ('IuxButton with an empty label', 'use IuxIconButton'),
            (
              'IuxButton with variant: icon',
              'an icon variant carries no label'
            ),
            ('destructive + tonal', 'not enough separation for data loss'),
            ('disabled + inProgress', 'what cannot start cannot be running'),
            ('hold-to-confirm + disabled', 'a disabled control cannot be held'),
            (
              'role: undo + irreversible',
              'undoing is a reversal by definition'
            ),
            ('expand + cancelLabel', 'no width is left for the second control'),
            (
              'async busyLabel empty',
              'no motion means the word is all there is'
            ),
            (
              'cancellation: required with no cancelLabel',
              'a promised exit with no exit'
            ),
            (
              'cancelLabel with cancellation: notSupported',
              'a control that refuses to do anything'
            ),
            ('reversible + confirmation', 'undo beats confirmation'),
            (
              'confirmation policy with no prompt',
              'a control that does nothing'
            ),
            ('prompt with no confirmation policy', 'nobody is ever asked'),
            (
              'hold or double activation in the destructive pattern',
              'neither is reachable by a screen reader from one control'
            ),
          ]),
          SizedBox(height: geometry.spacingXs),
          const CatalogNote(
            'Every one of these is an assert, so none of them exists in a '
            'release build. A release build renders destructive + tonal as a '
            'quiet container and runs a confirming action without asking. The '
            'assertions catch a developer, not a user.',
            finding: true,
          ),
          const CatalogNote(
            'Not refused, and arguably should be: two primary actions in one '
            'group, an icon-only destructive action with no confirmation, and '
            'a plain IuxButton carrying a confirmation policy. The first two '
            'are judgement calls a machine cannot make; the third is checkable '
            'and is not checked.',
          ),
        ],
      ),
    );
  }
}
