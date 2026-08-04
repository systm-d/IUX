import 'package:flutter/material.dart';
import 'package:iux_flutter/iux_flutter.dart';

import 'catalog_chrome.dart';
import 'catalog_testable.dart';
import 'semantics_readout.dart';

/// The text field and the selection controls, under the same three axes.
///
/// The interesting failures here are invisible ones: a field whose error is
/// drawn in red and announced as nothing, a checkbox whose third state has no
/// name, a required field that is announced as optional. Every panel that
/// depends on what a screen reader hears prints the semantics node instead of
/// describing it.
class InputPanels extends StatelessWidget {
  /// Creates the input harness.
  const InputPanels({super.key, required this.longLabels});

  /// Whether samples use a label of translated length.
  final bool longLabels;

  @override
  Widget build(BuildContext context) => Column(
        children: <Widget>[
          _TextFieldPanel(longLabels: longLabels),
          _ValidationPanel(longLabels: longLabels),
          _ContentTypePanel(longLabels: longLabels),
          _SelectionPanel(longLabels: longLabels),
          const _SelectionRefusalPanel(),
        ],
      );
}

/// The words the input harness uses.
abstract final class _Copy {
  /// A short field name.
  static const String shortLabel = 'Email';

  /// A field name of the length a translation produces.
  static const String longLabel =
      'E-Mail-Adresse für den Zahlungsbestätigungsversand';

  /// The help sentence, short and long.
  static const String shortHelp = 'We only use this for receipts.';
  static const String longHelp =
      'Diese Adresse wird ausschließlich für den Versand von '
      'Zahlungsbestätigungen und Rechnungsanhängen verwendet.';

  static String label({required bool long}) => long ? longLabel : shortLabel;

  static String help({required bool long}) => long ? longHelp : shortHelp;
}

/// A descriptor for one field of the harness.
IuxInputDescriptor _descriptor({
  required bool long,
  IuxInputAvailability availability = IuxInputAvailability.enabled,
  IuxInputRequirement requirement = IuxInputRequirement.optional,
  IuxInputValidation validation = const IuxInputValidation.notValidated(),
  String? helpText,
  String? unavailabilityReason,
}) =>
    IuxInputDescriptor(
      semantics: IuxInputSemantics(
        label: _Copy.label(long: long),
        hint: 'Used for the receipt',
        unavailabilityReason: unavailabilityReason,
      ),
      availability: availability,
      requirement: requirement,
      validation: validation,
      helpText: helpText,
    );

class _TextFieldPanel extends StatefulWidget {
  const _TextFieldPanel({required this.longLabels});

  final bool longLabels;

  @override
  State<_TextFieldPanel> createState() => _TextFieldPanelState();
}

class _TextFieldPanelState extends State<_TextFieldPanel> {
  final Map<String, TextEditingController> _controllers =
      <String, TextEditingController>{};

  TextEditingController _controllerFor(String key, String initial) =>
      _controllers.putIfAbsent(
        key,
        () => TextEditingController(text: initial),
      );

  @override
  void dispose() {
    for (final TextEditingController controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final bool long = widget.longLabels;

    return CatalogPanel(
      title: 'Availability, and what it costs the caret',
      description: 'Three availabilities that look like three shades of the '
          'same box. Read-only still lets the user select and copy the value; '
          'disabled does not, and a value nobody can copy is a value nobody '
          'can quote to support. Choosing disabled for a field that is merely '
          'not editable is the most common mistake this enum exists to make '
          'visible.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CatalogTestable(
            what: 'Type in the first one. The second takes the caret and lets '
                'you copy but refuses your typing, and the third answers '
                'nothing at all — both of those are the specimen rather than '
                'a fault.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (final (IuxInputAvailability availability, String note)
                    in <(IuxInputAvailability, String)>[
                  (IuxInputAvailability.enabled, 'editable'),
                  (
                    IuxInputAvailability.readOnly,
                    'read-only — selectable, not typed'
                  ),
                  (
                    IuxInputAvailability.disabled,
                    'disabled — nothing is reachable'
                  ),
                ]) ...<Widget>[
                  CatalogSubheading(note),
                  IuxTextField(
                    input: _descriptor(
                      long: long,
                      availability: availability,
                      helpText: _Copy.help(long: long),
                      unavailabilityReason:
                          availability == IuxInputAvailability.disabled
                              ? 'Sign in before changing your email'
                              : null,
                    ),
                    controller: _controllerFor(
                      availability.name,
                      'maria.costa@example.org',
                    ),
                    onChanged: (String _) {},
                  ),
                  SizedBox(height: geometry.spacingSm),
                ],
              ],
            ),
          ),
          const CatalogSubheading('required, with the semantics node printed'),
          SemanticsReadout(
            child: IuxTextField(
              input: _descriptor(
                long: long,
                requirement: IuxInputRequirement.required,
                helpText: _Copy.help(long: long),
              ),
              controller: _controllerFor('required', ''),
              placeholder: 'name@example.org',
              onChanged: (String _) {},
            ),
          ),
          const CatalogNote(
            'The readout reports a field, so "Role: (not a button)" and '
            '"Activatable: no" are correct rather than a defect — a text field '
            'is edited, not activated. What matters is the name, and that the '
            'hint arrived. Note that the required marker is not here: IUX-009 '
            'deferred it and IUX-012 does not own the field, so "required" '
            'reaches the node and nothing on screen says it.',
          ),
          const CatalogNote(
            'Help text and the error message are adjacent nodes, not an '
            'association: Flutter has no aria-describedby. A user landing '
            'directly on the box hears the label and the hint and not the help '
            'until they swipe to it. Pairing helpText with the hint is the '
            'workaround, and it is a workaround.',
          ),
        ],
      ),
    );
  }
}

class _ValidationPanel extends StatefulWidget {
  const _ValidationPanel({required this.longLabels});

  final bool longLabels;

  @override
  State<_ValidationPanel> createState() => _ValidationPanelState();
}

class _ValidationPanelState extends State<_ValidationPanel> {
  final Map<String, TextEditingController> _controllers =
      <String, TextEditingController>{};

  @override
  void dispose() {
    for (final TextEditingController controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final bool long = widget.longLabels;

    const List<(String, IuxInputValidation)> states =
        <(String, IuxInputValidation)>[
      ('notValidated', IuxInputValidation.notValidated()),
      ('validating', IuxInputValidation.validating(message: 'Checking…')),
      ('valid', IuxInputValidation.valid(message: 'That address works')),
      ('invalid', IuxInputValidation.invalid('That address has no @ in it')),
    ];

    return CatalogPanel(
      title: 'Every validation state at once',
      description: 'Four states, one above the other, so a pair that reads the '
          'same is obvious. The failure to look for is colour doing the work '
          'alone: turn on high contrast, then look again at valid against '
          'invalid without reading the words.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final (String name, IuxInputValidation validation)
              in states) ...<Widget>[
            CatalogSubheading(name),
            IuxTextField(
              input: _descriptor(
                long: long,
                requirement: IuxInputRequirement.required,
                validation: validation,
              ),
              controller: _controllers.putIfAbsent(
                name,
                () => TextEditingController(text: 'maria.costa'),
              ),
              onChanged: (String _) {},
            ),
            SizedBox(height: geometry.spacingSm),
          ],
          const CatalogNote(
            'The validating state carries a message and no motion. There is no '
            'spinner in this component for the same reason there is none in '
            'the async button: under a no-motion preference a spinner is the '
            'only carrier of the state and would be removed, leaving nothing.',
          ),
          const CatalogNote(
            'The message under the box is not a live region. A field that '
            'announced every keystroke\'s verdict would talk over the user as '
            'they type; the form pattern is what announces a rejection, once, '
            'when the user asked for a verdict by submitting.',
          ),
        ],
      ),
    );
  }
}

class _ContentTypePanel extends StatefulWidget {
  const _ContentTypePanel({required this.longLabels});

  final bool longLabels;

  @override
  State<_ContentTypePanel> createState() => _ContentTypePanelState();
}

class _ContentTypePanelState extends State<_ContentTypePanel> {
  final Map<IuxTextContent, TextEditingController> _controllers =
      <IuxTextContent, TextEditingController>{};

  @override
  void dispose() {
    for (final TextEditingController controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);

    return CatalogPanel(
      title: 'What kind of text this is',
      description: 'The content type picks the keyboard, the autofill hint and '
          'the semantic input type together, so they cannot disagree. On a '
          'device, tap each one and watch the keyboard change; in this '
          'harness, what you can check is that multiline is the only one that '
          'grows.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CatalogTestable(
            what: 'Type in each of them. On a device the keyboard changes with '
                'the kind of text; in this harness, multiline is the only one '
                'that grows as you type.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (final IuxTextContent content
                    in IuxTextContent.values) ...<Widget>[
                  CatalogSubheading(content.name),
                  IuxTextField(
                    content: content,
                    input: IuxInputDescriptor(
                      semantics: IuxInputSemantics(
                        label: widget.longLabels
                            ? '${_Copy.longLabel} — ${content.name}'
                            : content.name,
                      ),
                    ),
                    controller: _controllers.putIfAbsent(
                      content,
                      TextEditingController.new,
                    ),
                    placeholder: 'type here',
                    onChanged: (String _) {},
                  ),
                  SizedBox(height: geometry.spacingXs),
                ],
              ],
            ),
          ),
          CatalogRows(<(String, String)>[
            ('Content types offered', '${IuxTextContent.values.length}'),
            (
              'A search type among them',
              IuxTextContent.values
                      .any((IuxTextContent value) => value.name == 'search')
                  ? 'yes — SemanticsInputType.search is reachable'
                  : 'no — SemanticsInputType.search is unreachable'
            ),
          ]),
          const CatalogNote(
            'The row above is read off the enum rather than written down, and '
            'it used to answer no: IUX-TEXTFIELD-GAPS-001 was three gaps, and '
            'the missing search member was the one visible from here. Two are '
            'closed. search maps to SemanticsInputType.search, and onSubmitted '
            'exists — measured, it fires with the text when the action key is '
            'pressed, and the key itself is resolved from content rather than '
            'named by the caller, so a phone-number field cannot be given a '
            '"search" key. onSubmitted on a multiline field asserts, because '
            'there the action key is the newline key and the callback could '
            'never fire.',
          ),
          const CatalogNote(
            'The third gap is refused rather than deferred: there is no '
            'trailing-control slot inside the box, and there will not be. A '
            'control in there is a second interactive element inside a node '
            'announced as one text field, and the target floor settles it — a '
            'target meeting the minimum leaves too little of a small-screen '
            'field for text, and one that fits is below the minimum. A control '
            'beside the box is the arrangement that works, which is what '
            'IuxSearchField does.',
          ),
          const CatalogNote(
            'There is no obscured mode, so no password field can be built '
            'here. That is a refusal rather than a gap: an obscured box needs '
            'a reveal control, an autofill contract and a rule about screen '
            'readers reading characters aloud, and half of one is worse than '
            'none.',
          ),
        ],
      ),
    );
  }
}

class _SelectionPanel extends StatefulWidget {
  const _SelectionPanel({required this.longLabels});

  final bool longLabels;

  @override
  State<_SelectionPanel> createState() => _SelectionPanelState();
}

class _SelectionPanelState extends State<_SelectionPanel> {
  IuxSelectionState _all = IuxSelectionState.partial;
  bool _receipts = true;
  bool _reminders = false;
  bool _sync = true;
  String? _channel = 'email';

  String _optionLabel(String short, String long) =>
      widget.longLabels ? long : short;

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);

    return CatalogPanel(
      title: 'Choosing, in the three shapes it takes',
      description: 'A checkbox answers "which of these", a switch answers "is '
          'this on", a radio group answers "which one". They are three '
          'questions, not one control with three skins. The partial checkbox '
          'is the state most often drawn and least often announced: check what '
          'the readout says about it.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CatalogTestable(
            what: 'Changes the choices. "Everything" turns the two under it on '
                'and off with it; "Reminders" is disabled on purpose and will '
                'not respond — that is the specimen, not a fault.',
            child: IuxSelectionGroup(
              label: _optionLabel(
                'Notifications',
                'Benachrichtigungen zur Zahlungsbestätigung',
              ),
              children: <Widget>[
                IuxCheckbox(
                  label: _optionLabel(
                    'Everything',
                    'Alle Benachrichtigungen aktivieren',
                  ),
                  input: const IuxInputDescriptor(
                    semantics: IuxInputSemantics(
                      label: 'Every notification',
                      hint: 'Turns the two below on or off together',
                    ),
                  ),
                  value: _all,
                  onChanged: (bool selected) => setState(() {
                    _all = selected
                        ? IuxSelectionState.selected
                        : IuxSelectionState.unselected;
                    _receipts = selected;
                    _reminders = selected;
                  }),
                ),
                IuxCheckbox(
                  label: _optionLabel('Receipts', 'Zahlungsbestätigungen'),
                  input: const IuxInputDescriptor(
                    semantics: IuxInputSemantics(label: 'Receipts'),
                    helpText: 'One message per payment.',
                  ),
                  value: _receipts
                      ? IuxSelectionState.selected
                      : IuxSelectionState.unselected,
                  onChanged: (bool selected) =>
                      setState(() => _receipts = selected),
                ),
                IuxCheckbox(
                  label: _optionLabel('Reminders', 'Zahlungserinnerungen'),
                  input: const IuxInputDescriptor(
                    semantics: IuxInputSemantics(label: 'Reminders'),
                    availability: IuxInputAvailability.disabled,
                  ),
                  value: _reminders
                      ? IuxSelectionState.selected
                      : IuxSelectionState.unselected,
                  onChanged: (bool selected) =>
                      setState(() => _reminders = selected),
                ),
              ],
            ),
          ),
          SizedBox(height: geometry.spacingSm),
          const CatalogSubheading('the partial box, with its node printed'),
          SemanticsReadout(
            child: IuxCheckbox(
              label: 'Every notification',
              input: const IuxInputDescriptor(
                semantics: IuxInputSemantics(label: 'Every notification'),
              ),
              value: IuxSelectionState.partial,
              onChanged: (bool _) {},
            ),
          ),
          const CatalogNote(
            'The readout prints name, hint, role, enabled and tap. It does not '
            'print the checked state, because the probe was written for '
            'actions — so what it shows here is that the control is named and '
            'reachable, and the mixed state has to be checked with TalkBack on '
            'a device. That the harness cannot see it is worth knowing: it is '
            'the property most likely to be missing.',
          ),
          SizedBox(height: geometry.spacingSm),
          const CatalogSubheading('a switch'),
          CatalogTestable(
              what: 'Turns it on and off. It applies at once — there is no '
                  'submit behind it.',
              child: IuxSwitch(
                label: _optionLabel(
                  'Sync over mobile data',
                  'Synchronisierung über Mobilfunkverbindung zulassen',
                ),
                input: const IuxInputDescriptor(
                  semantics: IuxInputSemantics(label: 'Sync over mobile data'),
                  helpText: 'Applies immediately.',
                ),
                value: _sync
                    ? IuxSelectionState.selected
                    : IuxSelectionState.unselected,
                onChanged: (bool selected) => setState(() => _sync = selected),
              )),
          const CatalogNote(
            'A switch applies at once and a checkbox waits for a submit. '
            'Nothing in the API enforces that — both take the same callback — '
            'so a switch inside a form with a Save button is a contradiction '
            'the framework cannot catch and the user pays for.',
          ),
          SizedBox(height: geometry.spacingSm),
          const CatalogSubheading('a radio group'),
          CatalogTestable(
              what:
                  'Moves the choice. "Fax" is unavailable on purpose and will '
                  'not respond — that is the specimen, not a fault.',
              child: IuxRadioGroup<String>(
                label: _optionLabel(
                  'How to send the receipt',
                  'Wie soll die Zahlungsbestätigung zugestellt werden',
                ),
                input: const IuxInputDescriptor(
                  semantics:
                      IuxInputSemantics(label: 'How to send the receipt'),
                  requirement: IuxInputRequirement.required,
                ),
                value: _channel,
                options: <IuxRadioOption<String>>[
                  IuxRadioOption<String>(
                    value: 'email',
                    label: _optionLabel('Email', 'Per E-Mail zustellen'),
                    helpText: 'Arrives within a minute.',
                  ),
                  IuxRadioOption<String>(
                    value: 'post',
                    label: _optionLabel('Post', 'Per Briefpost zustellen'),
                    helpText: 'Three to five working days.',
                  ),
                  const IuxRadioOption<String>(
                    value: 'fax',
                    label: 'Fax',
                    unavailabilityReason: 'No fax number on this account',
                  ),
                ],
                onChanged: (String value) => setState(() => _channel = value),
              )),
          const CatalogNote(
            'There is no arrow-key traversal inside the group: every option is '
            'its own Tab stop. Flutter\'s own RadioGroup adds arrows and skips '
            'unselected options; IUX does not, so a D-pad user presses down '
            'once per option instead of once per group. More presses, and no '
            'option is unreachable — which is the trade, stated rather than '
            'hidden.',
          ),
          const CatalogNote(
            'The unavailable option keeps its reason, and the group name may '
            'be read twice — once from the group container and once from the '
            'heading. Both are ordinary fieldset behaviour and both need a '
            'device to confirm.',
          ),
          const CatalogNote(
            'Each of these now publishes a focusable flag and a focus action '
            'on its own node — measured on the checkbox, the switch and a '
            'radio option. None of them did until IUX-038: the subtree is '
            'excluded to control the announced name, and the Focus widget\'s '
            'annotation went with it, so keyboard focus worked while assistive '
            'technology had no way to move accessibility focus onto the '
            'control. That was IUX-A11Y-FOCUS-001, and the fix is the same one '
            'the button section shows: the helper is handed the node the '
            'control actually focuses, and republishes the state and the '
            'action itself.',
          ),
          const CatalogNote(
            'What a device is still owed: the flag reaching the node is not '
            'the same as TalkBack acting on it, and nothing in this project '
            'has been validated on a real device with a screen reader.',
          ),
        ],
      ),
    );
  }
}

class _SelectionRefusalPanel extends StatelessWidget {
  const _SelectionRefusalPanel();

  @override
  Widget build(BuildContext context) => const CatalogPanel(
        title: 'What the input API refuses',
        description: 'Assertions, so none of them exists in a release build. '
            'They are not demonstrated here, because a demonstration would '
            'stop the application.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CatalogRows(<(String, String)>[
              ('a field with no name', 'announced as "edit box" and nothing'),
              ('an empty placeholder', 'pass null rather than an empty string'),
              ('an empty help text', 'reserves a line and says nothing'),
              ('a switch with a partial value', 'no indeterminate switch'),
              ('a radio option with a partial value', 'no tri-state radio'),
              ('an unlabelled checkbox', 'a question the user has to guess'),
              ('an unnamed selection group', 'probably not a set at all'),
            ]),
            CatalogNote(
              'A checkbox and a switch both take IuxSelectionState, and only '
              'the checkbox may carry partial. The refusal is an assertion at '
              'build rather than a type, so the illegal state is expressible: '
              'the enum could have been split and was not.',
            ),
          ],
        ),
      );
}
