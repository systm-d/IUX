import 'package:flutter/material.dart';
import 'package:iux_flutter/iux_flutter.dart';

import 'catalog_chrome.dart';
import 'catalog_overlays.dart';
import 'catalog_testable.dart';

/// The things that appear over the page, and the one that appears under it.
///
/// Everything here is a value the page places rather than a route something
/// pushed. That is the whole architecture of this family: a modal is a layer,
/// so the application can always see how many are open and what is underneath
/// them, and two-at-once is an assertion rather than a stack nobody can leave.
///
/// The cost is plumbing, and the harness pays it in full — the panels below
/// hand a builder up to the page and the page owns every layer. If the wiring
/// looks like a lot, it is a lot everywhere, and that is worth seeing.
class OverlayPanels extends StatelessWidget {
  /// Creates the overlay harness.
  const OverlayPanels({
    super.key,
    required this.longLabels,
    required this.overlays,
  });

  /// Whether samples use text of translated length.
  final bool longLabels;

  /// The page's overlay owner.
  final CatalogOverlays overlays;

  @override
  Widget build(BuildContext context) => Column(
        children: <Widget>[
          _DialogPanel(longLabels: longLabels, overlays: overlays),
          _SheetPanel(longLabels: longLabels, overlays: overlays),
          _TransientPanel(longLabels: longLabels, overlays: overlays),
          _TooltipPanel(longLabels: longLabels),
          const _OverlayRefusalPanel(),
        ],
      );
}

class _DialogPanel extends StatefulWidget {
  const _DialogPanel({required this.longLabels, required this.overlays});

  final bool longLabels;
  final CatalogOverlays overlays;

  @override
  State<_DialogPanel> createState() => _DialogPanelState();
}

class _DialogPanelState extends State<_DialogPanel> {
  static const String _answered = 'dialog.answered';
  static const String _dismissed = 'dialog.dismissed';

  int _actionCount = 2;
  bool _withContent = false;

  /// Builds the dialog once, from values, and hands the page a constant.
  ///
  /// Written this way when opening a modal still rebuilt the page's subtree
  /// and disposed this panel with it — IUX-OVERLAY-001 — so that a builder
  /// reading `_actionCount`, or `context` at all, could not be reading a
  /// widget that no longer existed. That defect is closed: `IuxModalLayer`
  /// keeps the page in the tree whether or not anything is open.
  ///
  /// The shape stays, because it is the better one on its own merits: a value
  /// built once from what the panel knows is easier to read than a closure
  /// whose result depends on when it is called.
  void _open() {
    final CatalogOverlays overlays = widget.overlays;
    final bool long = widget.longLabels;

    final IuxDialog value = IuxDialog(
      title: long
          ? 'Die Märzrechnung an die Nordwind GmbH senden?'
          : 'Send the March invoice?',
      message: long
          ? 'Die Rechnung wird sofort an die hinterlegte E-Mail-Adresse '
              'zugestellt und kann danach nicht mehr zurückgezogen werden.'
          : 'It goes to the address on the account and cannot be recalled.',
      dismissLabel: 'Close',
      onDismissed: () {
        overlays.record(_dismissed);
        overlays.closeModal();
      },
      content: _withContent ? const _SlotNote() : null,
      actions: <IuxDialogAction>[
        for (final (String label, String announced, bool primary)
            in <(String, String, bool)>[
          ('Send it', 'Send the March invoice now', true),
          ('Not yet', 'Leave the invoice unsent', false),
        ].take(_actionCount))
          IuxDialogAction(
            label: label,
            action: primary
                ? IuxActionDescriptor.primary(
                    semantics: IuxActionSemantics(label: announced),
                  )
                : IuxActionDescriptor(
                    role: IuxActionRole.dismiss,
                    semantics: IuxActionSemantics(label: announced),
                  ),
            onActivate: () {
              overlays.record(_answered);
              overlays.closeModal();
            },
          ),
      ],
    );

    overlays.showDialog(() => value);
  }

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);

    return CatalogPanel(
      title: 'A question that stops everything',
      description: 'At most two actions, and a dismissal that is separate from '
          'both. Two, because a third makes it a decision rather than a '
          'question, and a decision belongs on a screen where the options sit '
          'side by side and the user can read them without one of them being '
          'the default. Open it at 300% and check that nothing clips.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CatalogChoice<int>(
            label: 'Actions',
            value: _actionCount,
            values: const <int>[0, 1, 2],
            naming: (int value) => '$value',
            onChanged: (int value) => setState(() => _actionCount = value),
          ),
          CatalogChoice<bool>(
            label: 'Content slot',
            value: _withContent,
            values: const <bool>[false, true],
            naming: (bool value) => value ? 'filled' : 'empty',
            onChanged: (bool value) => setState(() => _withContent = value),
          ),
          SizedBox(height: geometry.spacingXs),
          CatalogTestable(
            what: 'Opens the dialog over the whole page. Answering it or '
                'dismissing it changes the counts below — and focus lands on '
                'the dialog itself rather than on either action.',
            child: IuxButton(
              label: 'Ask the question',
              action: const IuxActionDescriptor(
                semantics: IuxActionSemantics(
                  label: 'Open the confirmation dialog',
                ),
              ),
              onActivate: _open,
            ),
          ),
          SizedBox(height: geometry.spacingXs),
          CatalogRows(<(String, String)>[
            ('Answered', '${widget.overlays.tally(_answered)}'),
            ('Dismissed', '${widget.overlays.tally(_dismissed)}'),
          ]),
          const CatalogNote(
            'Those two counters live on the page rather than in this panel '
            'because, until IUX-OVERLAY-001 was closed, they had to. Opening a '
            'modal rebuilt the page\'s subtree, so a panel that had been '
            'scrolled to was disposed by that rebuild and its callbacks then '
            'fired on a dead State: "setState() called after dispose()", '
            'thrown from the tap that answered the dialog. The recorded '
            'symptom was a lost scroll position; the one nobody had written '
            'down was that the widget which opened the modal did not survive '
            'to see the answer. IuxModalLayer now keeps the page mounted, so '
            'neither happens — and this panel is no longer disposed by the '
            'button in it.',
            finding: true,
          ),
          const CatalogNote(
            'Focus lands on the panel, never on an action. A dialog that '
            'focused its confirm control would make Enter the answer before '
            'the user has read the question — and the more dangerous the '
            'question, the more likely somebody is holding Enter down from '
            'whatever they were doing before it appeared.',
          ),
          const CatalogNote(
            'Zero actions is legal and is the "we are telling you something" '
            'shape: the dismissal is the only way out and it is always there. '
            'Note that the dismissal is not one of the two — a dialog with two '
            'actions has three ways to leave it.',
          ),
          const CatalogNote(
            'The system back button does not dismiss it unless the page adds a '
            'PopScope. This catalog does not, so on a device the back gesture '
            'goes to whatever is behind the catalog while a dialog is open. '
            'That is the price of not calling Navigator, it is stated rather '
            'than hidden — and IuxNavigationDrawer makes the opposite choice, '
            'so the library answers Android\'s most practised gesture two '
            'different ways depending on which overlay is open.',
            finding: true,
          ),
          const CatalogNote(
            'There is no exit animation, because the page removes the value '
            'from the tree and there is no frame left in which to animate a '
            'departure. The entrance is animated and the exit is instant, '
            'which is asymmetric and visible.',
          ),
        ],
      ),
    );
  }
}

/// The dialog's optional content slot, filled.
///
/// A widget rather than a `Text` built at the call site, so its colours are
/// resolved from where the dialog is finally placed rather than from the panel
/// that asked for it — which is a page away and may not exist by then.
class _SlotNote extends StatelessWidget {
  const _SlotNote();

  @override
  Widget build(BuildContext context) => Text(
        'A widget slot. Everything inside it — contrast, target sizes, '
        'reading order — is the caller\'s, which is why it should stay text '
        'and short lists.',
        style: IuxTypographyTheme.of(context).supporting.copyWith(
              color: IuxSemanticColors.of(context).content.secondary,
            ),
      );
}

class _SheetPanel extends StatefulWidget {
  const _SheetPanel({required this.longLabels, required this.overlays});

  final bool longLabels;
  final CatalogOverlays overlays;

  @override
  State<_SheetPanel> createState() => _SheetPanelState();
}

class _SheetPanelState extends State<_SheetPanel> {
  static const String _dismissed = 'sheet.dismissed';

  /// Owned by the page's lifetime, not this panel's.
  ///
  /// The sheet outlives the panel that opened it — see the dialog panel — so a
  /// controller disposed with this `State` would be disposed while the field
  /// built on it is still on screen.
  static final TextEditingController _note = TextEditingController();

  bool _withField = false;

  void _open() {
    final CatalogOverlays overlays = widget.overlays;
    final bool long = widget.longLabels;

    final IuxBottomSheet value = IuxBottomSheet(
      title: long ? 'Zustelloptionen für die Märzrechnung' : 'Delivery options',
      dismissLabel: 'Close',
      onDismissed: () {
        overlays.record(_dismissed);
        overlays.closeModal();
      },
      child: _withField
          ? IuxTextField(
              input: const IuxInputDescriptor(
                semantics: IuxInputSemantics(
                  label: 'A note for the courier',
                  hint: 'Focus this and watch the sheet lift',
                ),
              ),
              controller: _note,
              onChanged: (String _) {},
            )
          : IuxListGroup(
              children: <Widget>[
                for (final String option in <String>[
                  'Email the invoice',
                  'Post the invoice',
                  'Download a copy',
                ])
                  IuxListItem.tappable(
                    title: option,
                    hint: 'Chooses how the invoice is sent',
                    onActivate: overlays.closeModal,
                  ),
              ],
            ),
    );

    overlays.showSheet(() => value);
  }

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);

    return CatalogPanel(
      title: 'A panel from the bottom edge',
      description: 'A dialog asks a question; a sheet offers a set of choices '
          'that did not fit beside the thing they act on. It takes at most '
          '60% of the screen and its content is a widget slot, so everything '
          'inside it — contrast, targets, reading order — belongs to whoever '
          'filled it. Put a field in it and focus the field to watch the '
          'keyboard lift.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CatalogChoice<bool>(
            label: 'Contents',
            value: _withField,
            values: const <bool>[false, true],
            naming: (bool value) => value ? 'a text field' : 'a list of rows',
            onChanged: (bool value) => setState(() => _withField = value),
          ),
          SizedBox(height: geometry.spacingXs),
          CatalogTestable(
            what: 'Opens the sheet from the bottom edge. Choosing a row closes '
                'it; with the field in it instead, focusing the field lifts '
                'the sheet clear of the keyboard.',
            child: IuxButton(
              label: 'Open the sheet',
              action: const IuxActionDescriptor(
                semantics: IuxActionSemantics(label: 'Open the options sheet'),
              ),
              onActivate: _open,
            ),
          ),
          SizedBox(height: geometry.spacingXs),
          CatalogRows(<(String, String)>[
            ('Dismissed', '${widget.overlays.tally(_dismissed)}'),
            (
              'Keyboard inset now',
              IuxInsets.keyboard(context).toStringAsFixed(0)
            ),
          ]),
          const CatalogNote(
            'The lift is the residue rather than the inset: the sheet raises '
            'itself by whatever the keyboard took that the box it was given '
            'has not already absorbed. Lifting by the whole inset on a '
            'Scaffold that had already resized would move the sheet twice as '
            'far as the keyboard is tall.',
          ),
          const CatalogNote(
            'There is no drag, by decision. A drag is neither announced nor '
            'reliably performable with a motor impairment, so the named '
            'dismissal is the only way out — which is one way out for '
            'everybody rather than a fast one for some and a hidden one for '
            'the rest.',
          ),
          const CatalogNote(
            'The panel is rounded on all four corners including the two '
            'against the screen edge, because IuxSurface has one radius. '
            'Rounding only the top needs a corner option on the surface layer, '
            'which is a change to layout rather than to this component.',
          ),
          const CatalogNote(
            'This panel used to record that docs/components/bottom-sheet.md '
            'still opened its Limits with "IuxModalLayer cannot hold it" while '
            'the sheet slot already existed. The page marks that limit closed '
            'now. The slot is what this panel uses — IuxModalLayer takes '
            'dialog, sheet and drawer and asserts at most one — and it is why '
            'nothing here builds a Stack of its own.',
          ),
        ],
      ),
    );
  }
}

class _TransientPanel extends StatefulWidget {
  const _TransientPanel({required this.longLabels, required this.overlays});

  final bool longLabels;
  final CatalogOverlays overlays;

  @override
  State<_TransientPanel> createState() => _TransientPanelState();
}

class _TransientPanelState extends State<_TransientPanel> {
  static const String _undone = 'transient.undone';

  IuxTransientTone _tone = IuxTransientTone.neutral;
  bool _withAction = false;

  IuxTransientMessage _message({required bool long}) {
    final CatalogOverlays overlays = widget.overlays;
    return IuxTransientMessage(
      text: long
          ? 'Die Märzrechnung wurde archiviert und erscheint nicht mehr in '
              'der Liste der offenen Posten.'
          : 'The March invoice was archived',
      dismissLabel: 'Dismiss',
      tone: _tone,
      action: _withAction
          ? IuxTransientAction(
              label: 'Undo',
              onActivate: () {
                overlays.record(_undone);
                overlays.dismissNotice();
              },
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final bool long = widget.longLabels;
    final IuxTransientMessage message = _message(long: long);
    final Duration? dwell = IuxTransientTiming.resolve(context, message);

    return CatalogPanel(
      title: 'A message that leaves on its own',
      description: 'One message at a time, no queue and no history: what this '
          'replaces cannot be recovered, which is the property that makes the '
          'channel dangerous and the reason nothing important may travel on '
          'it. Show one, then show another before it goes, and watch the first '
          'disappear unread.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CatalogChoice<IuxTransientTone>(
            label: 'Tone',
            value: _tone,
            values: IuxTransientTone.values,
            naming: (IuxTransientTone value) => value.name,
            onChanged: (IuxTransientTone value) =>
                setState(() => _tone = value),
          ),
          CatalogChoice<bool>(
            label: 'Action',
            value: _withAction,
            values: const <bool>[false, true],
            naming: (bool value) => value ? 'an undo' : 'none',
            onChanged: (bool value) => setState(() => _withAction = value),
          ),
          SizedBox(height: geometry.spacingXs),
          CatalogTestable(
            what: 'Shows a message at the bottom edge that leaves on its own. '
                'Press "Replace it" before the first one goes and watch the '
                'first disappear unread — nothing recovers it.',
            child: IuxTargetSpacing(
              axis: Axis.horizontal,
              children: <Widget>[
                IuxButton(
                  label: 'Show it',
                  action: const IuxActionDescriptor(
                    semantics: IuxActionSemantics(
                      label: 'Show the transient message',
                    ),
                  ),
                  onActivate: () =>
                      widget.overlays.showNotice(_message(long: long)),
                ),
                IuxButton(
                  label: 'Replace it',
                  variant: IuxButtonVariant.outlined,
                  action: const IuxActionDescriptor(
                    semantics: IuxActionSemantics(
                      label: 'Replace the transient message with another',
                      hint: 'The first one is lost',
                    ),
                  ),
                  onActivate: () => widget.overlays.showNotice(
                    const IuxTransientMessage(
                      text: 'The April invoice was archived too',
                      dismissLabel: 'Dismiss',
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: geometry.spacingXs),
          CatalogRows(<(String, String)>[
            ('Undo pressed', '${widget.overlays.tally(_undone)}'),
            (
              'Reading time for this text',
              '${IuxTransientTiming.readingTime(message.text).inMilliseconds} ms'
            ),
            ('Floor', '${IuxTransientTiming.minimum.inMilliseconds} ms'),
            (
              'This message expires after',
              dwell == null ? 'never' : '${dwell.inMilliseconds} ms'
            ),
            (
              'Screen reader expected',
              IuxAccessibility.of(context).screenReaderExpected ? 'yes' : 'no'
            ),
          ]),
          const CatalogNote(
            'Turn the action on and read the expiry row again. A message '
            'carrying an action never leaves on its own, because a timer that '
            'took the undo away would be a timer racing the user — and the '
            'user loses that race precisely when they are slowest. The cost is '
            'that a parent who never clears it leaves it there indefinitely.',
          ),
          const CatalogNote(
            'Nothing expires at all when a screen reader is expected, '
            'including a message with no action. The hint is '
            'MediaQueryData.accessibleNavigation, which is a hint rather than a '
            'guarantee, so a sighted user with any assistive service running '
            'gets the persistent behaviour too.',
          ),
          const CatalogNote(
            'Two tones and no more: neutral and success. There is no error '
            'tone, and that is the channel\'s central rule rather than an '
            'omission — a failure that scrolls away unread is a failure the '
            'user never learns about. Failures go to IuxAlert, which stays.',
          ),
          const CatalogNote(
            'The reading rate is calibrated for Latin script at ten characters '
            'a second. Thirty characters of Japanese carry far more than '
            'thirty of English, so a dense script gets a shorter dwell than it '
            'deserves; the floor absorbs short messages and longer ones in '
            'such scripts are under-served.',
          ),
          const CatalogNote(
            'At 300% with long labels a message can be taller than the space '
            'above the bottom edge, and the top of it is clipped by the '
            'screen. It does not scroll and it will not: a transient message '
            'that needs scrolling is not transient. Turn on long labels, go to '
            '300%, and show one.',
            finding: true,
          ),
        ],
      ),
    );
  }
}

class _TooltipPanel extends StatelessWidget {
  const _TooltipPanel({required this.longLabels});

  final bool longLabels;

  /// A message past the eighty-rune ceiling.
  ///
  /// Not passed to the widget: the assertion fires in `initState`, which would
  /// stop the harness. `isWithinBounds` is public precisely so a caller can
  /// ask before building, and printing its answer is the demonstration.
  static const String _overlong =
      'Die Zahlungsreferenz steht oben rechts auf der Rechnung und wird von '
      'der Buchhaltung zur automatischen Zuordnung Ihrer Zahlung verwendet.';

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final IuxTypographyTheme type = IuxTypographyTheme.of(context);
    final IuxSemanticColors colors = IuxSemanticColors.of(context);

    const String short = 'Search the invoices by reference or by customer';

    return CatalogPanel(
      title: 'A tooltip, which nobody can find',
      description: 'Long-press the glyph below, or Tab to it. Nothing on '
          'screen says the gesture exists, and nothing announces it — which is '
          'why the one rule about this component is that nothing on it may be '
          'essential. It is a convenience for people who already know, and the '
          'information has to be somewhere else as well.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CatalogTestable(
            what: 'Long-press the glyph, or move keyboard focus to it: the '
                'message appears above it. An ordinary tap does nothing — the '
                'control is here to carry the tooltip, and nothing on screen '
                'says the gesture exists.',
            child: Row(
              children: <Widget>[
                IuxTooltip(
                  message: short,
                  child: IuxIconButton(
                    icon: Icons.search,
                    action: const IuxActionDescriptor(
                      semantics: IuxActionSemantics(
                        label: 'Search the invoices',
                      ),
                    ),
                    onActivate: () {},
                  ),
                ),
                SizedBox(width: geometry.spacingSm),
                Text(
                  'Long press, or focus it',
                  style:
                      type.supporting.copyWith(color: colors.content.secondary),
                ),
              ],
            ),
          ),
          SizedBox(height: geometry.spacingXs),
          CatalogRows(<(String, String)>[
            ('Ceiling', '$kIuxTooltipMaximumCharacters runes'),
            ('This message', '${short.runes.length} runes'),
            ('Within bounds', '${IuxTooltip.isWithinBounds(short)}'),
            (
              'A translated one',
              '${_overlong.runes.length} runes — '
                  '${IuxTooltip.isWithinBounds(_overlong)}'
            ),
          ]),
          const CatalogNote(
            'The last row is the one that matters, and its number is read off '
            'the string rather than written down here. A message that fits in '
            'English runs well past the ceiling in German and asserts — in '
            'debug, in initState, after the screen was built, and only if '
            'somebody long presses the right glyph on the right locale. '
            'isWithinBounds is public so a caller can ask first, and a caller '
            'who does not ask ships a crash that only speakers of one language '
            'ever reach.',
            finding: true,
          ),
          const CatalogNote(
            'One line and eighty runes, both enforced. The ceiling is what '
            'stops a tooltip becoming the only place information could live: '
            'anything that needs a paragraph needs to be on the screen.',
          ),
          const CatalogNote(
            'The child must be exactly one control, because its semantics are '
            'merged into a single node. A row of three controls wrapped in one '
            'tooltip is announced as one control, and nothing detects it.',
          ),
          const CatalogNote(
            'The outline is measured against the theme\'s page surface, not '
            'against whatever is actually behind the tooltip. Over a '
            'photograph the 3:1 guarantee does not hold, and no component can '
            'make it hold without inspecting its own backdrop.',
          ),
        ],
      ),
    );
  }
}

class _OverlayRefusalPanel extends StatelessWidget {
  const _OverlayRefusalPanel();

  @override
  Widget build(BuildContext context) => const CatalogPanel(
        title: 'What the overlays refuse',
        description: 'Assertions, so a release build has none of them. The '
            'tooltip\'s two fire in initState rather than in the constructor, '
            'so they are reached only when the widget is actually built.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CatalogRows(<(String, String)>[
              ('two modals in one layer', 'the way out of neither is visible'),
              ('three dialog actions', 'a decision, not a question'),
              ('a dialog with no message', 'a title is not an explanation'),
              (
                'a dialog with no dismissal',
                'no way out that is not an answer'
              ),
              ('a tooltip over eighty runes', 'it became the only place'),
              ('a tooltip with a newline', 'the same, by another route'),
              ('a tooltip with no Overlay above it', 'nowhere to appear'),
              ('an empty transient message', 'a strip saying nothing'),
              ('a zero or negative dwell', 'gone before it was read'),
            ]),
            CatalogNote(
              'There is no error tone on the transient channel and no way to '
              'add one, which is a refusal by omission rather than by '
              'assertion — the enum has two members. It is the strongest '
              'refusal in this family and the only one a release build still '
              'honours.',
            ),
          ],
        ),
      );
}
