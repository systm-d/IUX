import 'package:flutter/material.dart';
import 'package:iux_flutter/iux_flutter.dart';

import 'catalog_chrome.dart';
import 'catalog_testable.dart';

/// Forms, and what happens to a user who gets one wrong.
///
/// The interesting behaviour of a form is not the layout: it is where focus
/// lands when a submission is refused, what the summary says, and whether the
/// user can reach the question that failed. Every panel here is driven by
/// getting something wrong on purpose.
class FormPanels extends StatelessWidget {
  /// Creates the form harness.
  const FormPanels({super.key, required this.longLabels});

  /// Whether samples use labels of translated length.
  final bool longLabels;

  @override
  Widget build(BuildContext context) => Column(
        children: <Widget>[
          _FormPanel(longLabels: longLabels),
          const _SummaryPanel(),
          _GuidedFormPanel(longLabels: longLabels),
        ],
      );
}

/// One question of the harness.
class _Question {
  _Question({
    required this.label,
    required this.longLabel,
    required this.help,
    required this.rejection,
    required this.accepts,
  });

  final String label;
  final String longLabel;
  final String help;
  final String rejection;
  final bool Function(String) accepts;

  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();

  /// Whether the user has typed in this field at all.
  bool edited = false;

  /// The verdict the parent has reached, which the pattern only reads.
  IuxInputValidation verdict = const IuxInputValidation.notValidated();

  String name({required bool long}) => long ? longLabel : label;

  /// Reaches a verdict, which is the application's job and never the form's.
  void check() => verdict = accepts(controller.text)
      ? const IuxInputValidation.valid()
      : IuxInputValidation.invalid(rejection);

  void dispose() {
    controller.dispose();
    focusNode.dispose();
  }
}

List<_Question> _questions() => <_Question>[
      _Question(
        label: 'Name on the invoice',
        longLabel: 'Name der rechnungsempfangenden Person oder Organisation',
        help: 'As it should appear on the document.',
        rejection: 'Enter the name the invoice is addressed to',
        accepts: (String value) => value.trim().isNotEmpty,
      ),
      _Question(
        label: 'Email',
        longLabel: 'E-Mail-Adresse für den Zahlungsbestätigungsversand',
        help: 'The receipt goes here.',
        rejection: 'That address has no @ in it',
        accepts: (String value) => value.contains('@'),
      ),
      _Question(
        label: 'Amount',
        longLabel: 'Rechnungsbetrag in Euro, ohne Währungszeichen',
        help: 'Digits only.',
        rejection: 'Enter an amount using digits only',
        accepts: (String value) =>
            value.isNotEmpty && int.tryParse(value) != null,
      ),
    ];

class _FormPanel extends StatefulWidget {
  const _FormPanel({required this.longLabels});

  final bool longLabels;

  @override
  State<_FormPanel> createState() => _FormPanelState();
}

class _FormPanelState extends State<_FormPanel> {
  final List<_Question> _fields = _questions();

  bool _withSummary = true;
  IuxValidationTiming _timing = IuxValidationTiming.onBlur;
  int _submitted = 0;
  int _blocked = 0;

  @override
  void dispose() {
    for (final _Question field in _fields) {
      field.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final bool long = widget.longLabels;

    return CatalogPanel(
      title: 'A form that refuses',
      description: 'Submit it empty. The pattern never disables the submit '
          'control — a button that refuses to be pressed cannot say why, and '
          'the user is left guessing which of three questions is at fault. It '
          'accepts the press, refuses the submission, and moves focus to the '
          'list of problems. Turn the summary off and watch where focus goes '
          'instead.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CatalogChoice<bool>(
            label: 'Summary',
            value: _withSummary,
            values: const <bool>[true, false],
            naming: (bool value) => value ? 'present' : 'absent',
            onChanged: (bool value) => setState(() => _withSummary = value),
          ),
          CatalogChoice<IuxValidationTiming>(
            label: 'Timing',
            value: _timing,
            values: IuxValidationTiming.values,
            naming: (IuxValidationTiming value) => value.name,
            onChanged: (IuxValidationTiming value) =>
                setState(() => _timing = value),
          ),
          SizedBox(height: geometry.spacingXs),
          CatalogTestable(
            what: 'Press the submit control with the questions empty. The '
                'submission is refused, the counts below change, and focus '
                'moves to the list of problems — a move a sighted reader may '
                'not notice, so look for where the outline lands.',
            child: IuxForm(
              timing: _timing,
              summary: _withSummary
                  ? IuxValidationSummaryLabels(
                      categoryLabel: 'Error',
                      navigationHint: 'Go to this question',
                      describeCount: (int count) => count == 1
                          ? '1 question needs your attention'
                          : '$count questions need your attention',
                    )
                  : null,
              submit: IuxFormSubmit(
                label: long ? 'Rechnung jetzt absenden' : 'Send the invoice',
                action: const IuxActionDescriptor.primary(
                  semantics: IuxActionSemantics(label: 'Send the invoice'),
                ),
                onSubmit: () => setState(() => _submitted++),
                onBlocked: () => setState(() => _blocked++),
              ),
              sections: <IuxFormSection>[
                IuxFormSection(
                  title: long ? 'Angaben zur Rechnung' : 'Invoice details',
                  description: 'Every question here is required.',
                  fields: <IuxFormField>[
                    for (final _Question field in _fields)
                      IuxFormField(
                        input: _inputFor(field, long: long),
                        focusNode: field.focusNode,
                        edited: field.edited,
                        onValidationRequested: (IuxValidationTrigger _) =>
                            setState(field.check),
                        // The descriptor and the node come back out of the
                        // field rather than being written a second time: two
                        // copies is how a summary entry comes to point at a
                        // node no box holds.
                        builder: (BuildContext context, IuxFormField entry) =>
                            IuxTextField(
                          input: entry.input,
                          controller: field.controller,
                          focusNode: entry.focusNode,
                          onChanged: (String _) => setState(() {
                            field.edited = true;
                          }),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: geometry.spacingSm),
          CatalogRows(<(String, String)>[
            ('Submissions the parent received', '$_submitted'),
            ('Submissions the form refused', '$_blocked'),
          ]),
          const CatalogNote(
            'A refused submission never reaches the parent. The form can see '
            'that a question is already wrong, and sending it on so the parent '
            'can refuse it a second time helps nobody.',
          ),
          const CatalogNote(
            'With the summary absent, focus goes to the first rejected field '
            'instead. That is the honest fallback and it is worse: the user '
            'arrives at one problem with no idea there are two more.',
          ),
          const CatalogNote(
            'onBlur only checks a field the user actually edited. Tab straight '
            'through all three without typing and nothing is rejected — an '
            'error about a value somebody was never given the chance to get '
            'wrong is an error about nothing.',
          ),
          const CatalogNote(
            'The required marker is missing from every field above. IUX-009 '
            'deferred it to IUX-012, which does not own the field widget, so '
            '"required" reaches the semantics node and nothing on screen says '
            'it. The documented workaround is a sentence in the section '
            'description, which is what the description here is doing.',
            finding: true,
          ),
        ],
      ),
    );
  }

  IuxInputDescriptor _inputFor(_Question field, {required bool long}) =>
      IuxInputDescriptor(
        semantics: IuxInputSemantics(
          label: field.name(long: long),
          hint: field.help,
        ),
        requirement: IuxInputRequirement.required,
        validation: field.verdict,
        helpText: field.help,
      );
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel();

  @override
  Widget build(BuildContext context) => CatalogPanel(
        title: 'The summary on its own',
        description: 'Three problems, each one a control that travels to the '
            'question. It is deliberately not a live region: focus lands on it '
            'when a submission is refused, and a live region announcing itself '
            'in the same frame would put two utterances in one breath — the '
            'user hears half of each.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            IuxValidationSummary(
              categoryLabel: 'Error',
              message: '3 questions need your attention',
              navigationHint: 'Go to this question',
              entries: <IuxValidationSummaryEntry>[
                for (final (String label, String message) in <(String, String)>[
                  ('Name on the invoice', 'Enter the name it is addressed to'),
                  ('Email', 'That address has no @ in it'),
                  (
                    'Amount',
                    'Enter an amount using digits only, with no currency '
                        'symbol and no spaces'
                  ),
                ])
                  IuxValidationSummaryEntry(
                    label: label,
                    message: message,
                    onActivate: () {},
                  ),
              ],
            ),
            const CatalogNote(
              'The count sentence is the caller\'s: plural forms differ by '
              'language and IUX composes no user-facing text. That is why '
              'describeCount is a function rather than a string — a number and '
              'a sentence passed separately eventually disagree.',
            ),
            const CatalogNote(
              'Entries do not say which section or step they came from. In a '
              'form with "Address" on two steps, the labels the parent supplies '
              'are the only thing distinguishing them.',
            ),
          ],
        ),
      );
}

class _GuidedFormPanel extends StatefulWidget {
  const _GuidedFormPanel({required this.longLabels});

  final bool longLabels;

  @override
  State<_GuidedFormPanel> createState() => _GuidedFormPanelState();
}

class _GuidedFormPanelState extends State<_GuidedFormPanel> {
  final List<_Question> _fields = _questions();
  int _step = 0;
  int _submitted = 0;

  @override
  void dispose() {
    for (final _Question field in _fields) {
      field.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final IuxGeometryTheme geometry = IuxGeometryTheme.of(context);
    final bool long = widget.longLabels;

    return CatalogPanel(
      title: 'The same questions, one step at a time',
      description: 'Forward is never blocked. A step that refuses to advance '
          'is worse than a button that refuses to submit, because the question '
          'at fault may not even be on screen. Everything is checked at the '
          'end, where the summary can travel to any of it. Press Continue '
          'twice without answering anything, then press submit.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CatalogTestable(
            what: 'Press Continue twice without answering anything, then '
                'submit. Forward is never blocked; the refusal comes at the '
                'end, and every step change moves focus to the step heading — '
                'which a sighted reader may not see happen.',
            child: IuxGuidedForm(
              currentStep: _step,
              onStepChanged: (int next) => setState(() => _step = next),
              describePosition: (int step, int count) => 'Step $step of $count',
              backLabel: 'Back',
              forwardLabel: long ? 'Weiter zum nächsten Schritt' : 'Continue',
              summary: IuxValidationSummaryLabels(
                categoryLabel: 'Error',
                navigationHint: 'Go to this question',
                describeCount: (int count) => count == 1
                    ? '1 question needs your attention'
                    : '$count questions need your attention',
              ),
              submit: IuxFormSubmit(
                label: long ? 'Rechnung jetzt absenden' : 'Send the invoice',
                action: const IuxActionDescriptor.primary(
                  semantics: IuxActionSemantics(label: 'Send the invoice'),
                ),
                onSubmit: () => setState(() => _submitted++),
              ),
              steps: <IuxGuidedFormStep>[
                for (final _Question field in _fields)
                  IuxGuidedFormStep(
                    title: field.name(long: long),
                    description: field.help,
                    sections: <IuxFormSection>[
                      IuxFormSection(
                        fields: <IuxFormField>[
                          IuxFormField(
                            input: _inputFor(field, long: long),
                            focusNode: field.focusNode,
                            edited: field.edited,
                            onValidationRequested: (IuxValidationTrigger _) =>
                                setState(field.check),
                            builder:
                                (BuildContext context, IuxFormField entry) =>
                                    IuxTextField(
                              input: entry.input,
                              controller: field.controller,
                              focusNode: entry.focusNode,
                              onChanged: (String _) => setState(() {
                                field.edited = true;
                              }),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
          SizedBox(height: geometry.spacingSm),
          CatalogRows(<(String, String)>[
            ('Step showing', '${_step + 1} of ${_fields.length}'),
            ('Submissions the parent received', '$_submitted'),
          ]),
          const CatalogNote(
            'Focus lands on the step heading at every change — one node '
            'carrying position, title and description together — because the '
            'user pressed Continue and is waiting. Arriving from a summary '
            'entry lands on the field instead: they asked for a box, not a '
            'lecture about a step.',
          ),
          const CatalogNote(
            'There is no progress bar, deliberately. IuxProgressIndicator is a '
            'live region, so drawing one would put a second utterance in the '
            'same frame as the focus move. The position sentence is the '
            'carrier, and it is a function of step and count so the two cannot '
            'drift.',
          ),
          const CatalogNote(
            'A summary entry for a question on another step still travels to '
            'it. That is why the summary is required here where IuxForm allows '
            'null: the fallback of focusing the first rejected field is '
            'impossible when that field is not mounted, and a refusal that is '
            'invisible and unreachable is a dead end.',
          ),
          const CatalogNote(
            'Nothing here reviews the answers before submission. A '
            'confirmation page listing what the user said, with a way back to '
            'each step, is a screen the application builds out of these same '
            'steps — and on an irreversible submission it is the difference '
            'between a form and a trap.',
          ),
        ],
      ),
    );
  }

  IuxInputDescriptor _inputFor(_Question field, {required bool long}) =>
      IuxInputDescriptor(
        semantics: IuxInputSemantics(
          label: field.name(long: long),
          hint: field.help,
        ),
        requirement: IuxInputRequirement.required,
        validation: field.verdict,
        helpText: field.help,
      );
}
