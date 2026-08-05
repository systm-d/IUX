import 'package:flutter/widgets.dart';
import 'package:iux_flutter/iux_flutter.dart';

import 'jobs.dart';
import 'screen_frame.dart';
import 'strings.dart';

/// Adding a visit: two text fields, a choice, a switch and a summary.
///
/// The whole of validation lives here. `IuxForm` decides *when* a check is
/// worth running and nothing about whether a value is acceptable, which is the
/// right division — and which means this screen holds, per validated field, a
/// controller, a focus node, an edited flag, and a validation object with the
/// rule that produces it. Four pieces of state for one text box, all of them
/// the application's.
///
/// ## What used to be repeated, and no longer is
///
/// The descriptor and the focus node used to be written out twice — once on
/// `IuxFormField` and once on the widget inside it — with nothing checking that
/// the two agreed. `IuxFormField` now takes a `builder` and hands the field
/// back to it, so `field.input` and `field.focusNode` are *the* descriptor and
/// *the* node rather than a second copy; and `IuxFormSection` refuses in debug
/// a field whose node no widget below it holds.
///
/// That check is what the priority field would have failed. `IuxRadioGroup`
/// took no `focusNode` at all, so [_priorityNode] was handed to the form and
/// adopted by nothing: had a rule ever been attached to the priority, its
/// summary entry would have left focus on the summary and sent the user
/// nowhere. The group now takes one, and lands it on the first option.
///
/// [_priorityNode] is referenced from the doc above; it is a private field of
/// the state class below.
class NewJobScreen extends StatefulWidget {
  /// Creates the creation screen.
  const NewJobScreen({
    super.key,
    required this.jobs,
    required this.onAdded,
    required this.remindersEnabled,
    required this.onReminderRequested,
  });

  /// The round the visit is added to.
  final JobStore jobs;

  /// Reports the added visit so the shell can announce it and move on.
  final ValueChanged<Job> onAdded;

  /// Whether notification permission has been granted.
  final bool remindersEnabled;

  /// Asks the shell to open the permission conversation.
  final VoidCallback onReminderRequested;

  @override
  State<NewJobScreen> createState() => _NewJobScreenState();
}

class _NewJobScreenState extends State<NewJobScreen> {
  final TextEditingController _reference = TextEditingController();
  final TextEditingController _site = TextEditingController();
  final TextEditingController _notes = TextEditingController();

  final FocusNode _referenceNode = FocusNode(debugLabel: 'reference');
  final FocusNode _siteNode = FocusNode(debugLabel: 'site');
  final FocusNode _notesNode = FocusNode(debugLabel: 'notes');
  final FocusNode _priorityNode = FocusNode(debugLabel: 'priority');
  final FocusNode _reminderNode = FocusNode(debugLabel: 'reminder');

  bool _referenceEdited = false;
  bool _siteEdited = false;

  IuxInputValidation _referenceCheck = const IuxInputValidation.notValidated();
  IuxInputValidation _siteCheck = const IuxInputValidation.notValidated();

  JobPriority _priority = JobPriority.routine;
  bool _reminder = false;

  @override
  void dispose() {
    _reference.dispose();
    _site.dispose();
    _notes.dispose();
    _referenceNode.dispose();
    _siteNode.dispose();
    _notesNode.dispose();
    _priorityNode.dispose();
    _reminderNode.dispose();
    super.dispose();
  }

  IuxInputValidation _checkReference() {
    final String value = _reference.text.trim();
    if (value.isEmpty) {
      return const IuxInputValidation.invalid(Strings.formReferenceMissing);
    }
    if (widget.jobs.holdsReference(value)) {
      return const IuxInputValidation.invalid(Strings.formReferenceDuplicate);
    }
    return const IuxInputValidation.valid();
  }

  IuxInputValidation _checkSite() => _site.text.trim().isEmpty
      ? const IuxInputValidation.invalid(Strings.formSiteMissing)
      : const IuxInputValidation.valid();

  void _submit() {
    if (_referenceCheck.isInvalid || _siteCheck.isInvalid) return;
    final Job job = widget.jobs.add(
      reference: _reference.text.trim(),
      site: _site.text.trim(),
      priority: _priority,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );
    _reference.clear();
    _site.clear();
    _notes.clear();
    setState(() {
      _referenceEdited = false;
      _siteEdited = false;
      _referenceCheck = const IuxInputValidation.notValidated();
      _siteCheck = const IuxInputValidation.notValidated();
      _priority = JobPriority.routine;
      _reminder = false;
    });
    widget.onAdded(job);
  }

  IuxInputDescriptor get _referenceInput => IuxInputDescriptor(
        semantics: const IuxInputSemantics(label: Strings.formReference),
        requirement: IuxInputRequirement.required,
        helpText: Strings.formReferenceHelp,
        validation: _referenceCheck,
      );

  IuxInputDescriptor get _siteInput => IuxInputDescriptor(
        semantics: const IuxInputSemantics(label: Strings.formSite),
        requirement: IuxInputRequirement.required,
        helpText: Strings.formSiteHelp,
        validation: _siteCheck,
      );

  static const IuxInputDescriptor _notesInput = IuxInputDescriptor(
    semantics: IuxInputSemantics(label: Strings.formNotes),
    helpText: Strings.formNotesHelp,
  );

  static const IuxInputDescriptor _priorityInput = IuxInputDescriptor(
    semantics: IuxInputSemantics(label: Strings.formPriority),
    helpText: Strings.formPriorityHelp,
  );

  static const IuxInputDescriptor _reminderInput = IuxInputDescriptor(
    semantics: IuxInputSemantics(label: Strings.formReminder),
    helpText: Strings.formReminderHelp,
  );

  @override
  Widget build(BuildContext context) => PilotScreen(
        title: Strings.formTitle,
        child: IuxForm(
          summary: const IuxValidationSummaryLabels(
            categoryLabel: Strings.formSummaryCategory,
            describeCount: Strings.formSummaryCount,
            navigationHint: Strings.formSummaryHint,
          ),
          submit: IuxFormSubmit(
            label: Strings.formSubmit,
            action: const IuxActionDescriptor.primary(
              semantics: IuxActionSemantics(label: Strings.formSubmit),
            ),
            onSubmit: _submit,
          ),
          sections: <IuxFormSection>[
            IuxFormSection(
              title: Strings.formSectionIdentity,
              description: Strings.formSectionIdentityNote,
              fields: <IuxFormField>[
                IuxFormField(
                  input: _referenceInput,
                  focusNode: _referenceNode,
                  edited: _referenceEdited,
                  onValidationRequested: (IuxValidationTrigger _) =>
                      setState(() => _referenceCheck = _checkReference()),
                  builder: (BuildContext context, IuxFormField field) =>
                      IuxTextField(
                    input: field.input,
                    controller: _reference,
                    focusNode: field.focusNode,
                    placeholder: Strings.formReferencePlaceholder,
                    onChanged: (String _) =>
                        setState(() => _referenceEdited = true),
                  ),
                ),
                IuxFormField(
                  input: _siteInput,
                  focusNode: _siteNode,
                  edited: _siteEdited,
                  onValidationRequested: (IuxValidationTrigger _) =>
                      setState(() => _siteCheck = _checkSite()),
                  builder: (BuildContext context, IuxFormField field) =>
                      IuxTextField(
                    input: field.input,
                    controller: _site,
                    focusNode: field.focusNode,
                    onChanged: (String _) => setState(() => _siteEdited = true),
                  ),
                ),
              ],
            ),
            IuxFormSection(
              title: Strings.formSectionExtras,
              fields: <IuxFormField>[
                IuxFormField(
                  input: _notesInput,
                  focusNode: _notesNode,
                  builder: (BuildContext context, IuxFormField field) =>
                      IuxTextField(
                    input: field.input,
                    controller: _notes,
                    focusNode: field.focusNode,
                    content: IuxTextContent.multiline,
                    onChanged: (String _) {},
                  ),
                ),
                IuxFormField(
                  input: _priorityInput,
                  focusNode: _priorityNode,
                  builder: (BuildContext context, IuxFormField field) =>
                      IuxRadioGroup<JobPriority>(
                    label: Strings.formPriority,
                    input: field.input,
                    focusNode: field.focusNode,
                    value: _priority,
                    options: const <IuxRadioOption<JobPriority>>[
                      IuxRadioOption<JobPriority>(
                        value: JobPriority.routine,
                        label: Strings.priorityRoutine,
                      ),
                      IuxRadioOption<JobPriority>(
                        value: JobPriority.urgent,
                        label: Strings.priorityUrgent,
                      ),
                    ],
                    onChanged: (JobPriority value) =>
                        setState(() => _priority = value),
                  ),
                ),
                IuxFormField(
                  input: _reminderInput,
                  focusNode: _reminderNode,
                  builder: (BuildContext context, IuxFormField field) =>
                      IuxSwitch(
                    label: Strings.formReminder,
                    input: field.input,
                    focusNode: field.focusNode,
                    value: IuxSelectionState.fromSelected(_reminder),
                    onChanged: (bool value) {
                      setState(() => _reminder = value);
                      if (value && !widget.remindersEnabled) {
                        widget.onReminderRequested();
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}
