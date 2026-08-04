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
/// controller, a focus node, an edited flag, a validation object and the rule
/// that produces it. Five pieces of state for one text box, all of them the
/// application's, and three of them repeated verbatim between `IuxFormField`
/// and the widget inside it: the descriptor is passed twice and the focus node
/// is passed twice, with nothing checking that the two agree. The form's own
/// documentation calls that "the one mistake this API can still make".
///
/// ## The orphan focus node
///
/// `IuxFormField.focusNode` is required, and it is the link between an entry in
/// the error summary and the box the user has to go and fix. `IuxRadioGroup`
/// takes no `focusNode` parameter at all, so [_priorityNode] below is created,
/// handed to the form, disposed here — and adopted by nothing. If a rule were
/// ever attached to the priority, its summary entry would move focus to a node
/// attached to no widget, and the user would be sent nowhere. Nothing asserts
/// it, and the only reason it is harmless here is that the priority always has
/// a valid value.
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
                  child: IuxTextField(
                    input: _referenceInput,
                    controller: _reference,
                    focusNode: _referenceNode,
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
                  child: IuxTextField(
                    input: _siteInput,
                    controller: _site,
                    focusNode: _siteNode,
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
                  child: IuxTextField(
                    input: _notesInput,
                    controller: _notes,
                    focusNode: _notesNode,
                    content: IuxTextContent.multiline,
                    onChanged: (String _) {},
                  ),
                ),
                IuxFormField(
                  input: _priorityInput,
                  focusNode: _priorityNode,
                  child: IuxRadioGroup<JobPriority>(
                    label: Strings.formPriority,
                    input: _priorityInput,
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
                  child: IuxSwitch(
                    label: Strings.formReminder,
                    input: _reminderInput,
                    focusNode: _reminderNode,
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
